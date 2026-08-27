#!/usr/bin/env perl
# Issue #459: the two candidate combination designs, on the real corpus.
#
# Members are the actual per-message duration streams behind each consolidated
# row, grouped exactly as `ltl -g` grouped them (extract-real-groups.py), not
# generated. Reference is the exact percentile of the pooled raw durations.
#
# Arms:
#   DEFERRED  what is on the #459 branch: every member kept in its own geometry,
#             one union collapse at the end. Production subs, verbatim.
#   CANONICAL a combined-row histogram addressed on a canonical grid
#             (bucket j = [10^(j/B), 10^((j+1)/B))) with a fixed bucket budget,
#             absorbing members as they arrive and folding when the OCCUPIED
#             span exceeds the budget. Bounds are never fixed -- only the
#             bucket edges are; the occupied span grows with the data.
#
# Reported per log: agreement across arrival orders and batch boundaries,
# accuracy against the raw durations, peak memory, and absorb cost.
use strict;
use warnings;
use POSIX ();
use Time::HiRes qw(time);

use constant { COUNTER_BYTES_PER_PARTITION => 48, COUNTER_BYTES_PER_BIN_SLOT => 8 };
our $percentile_seed_decades = 5;
our $message_stats_member_bytes = 0;
do '/tmp/459-subs.pl'; die "load: $@" if $@;

my $seed = 20260827;
sub nextval { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }

# ---- canonical-grid target -------------------------------------------------
sub target_new { my ($B) = @_; return { B => $B, counts => {}, lo => undef, hi => undef } }
sub target_note { my ($t,$j)=@_; $t->{lo}=$j if !defined $t->{lo} || $j<$t->{lo};
                                 $t->{hi}=$j if !defined $t->{hi} || $j>$t->{hi}; }
sub target_fold {
    my ($t) = @_;
    my %new;
    while (my ($j, $c) = each %{ $t->{counts} }) { $new{ POSIX::floor($j / 2) } += $c }
    $t->{B} /= 2;
    $t->{counts} = \%new;
    $t->{lo} = POSIX::floor($t->{lo} / 2);
    $t->{hi} = POSIX::floor($t->{hi} / 2);
}
sub target_fit {
    my ($t, $budget) = @_;
    while (defined $t->{lo} && ($t->{hi} - $t->{lo} + 1) > $budget && $t->{B} > 1) {
        target_fold($t);
    }
}
sub target_absorb_entry {
    my ($t, $entry, $budget) = @_;
    my $p = $entry->{partition};
    for my $i (0 .. $p->{bin_count} - 1) {
        my $c = $entry->{bins}[$i];
        next unless $c;
        my $mid = sqrt(bin_boundary($p, $i) * bin_boundary($p, $i + 1));
        my $j = POSIX::floor(log($mid) / log(10) * $t->{B});
        $t->{counts}{$j} += $c;
        target_note($t, $j);
    }
    target_fit($t, $budget);
}
sub target_entry {
    my ($t) = @_;
    my ($lo, $hi) = ($t->{lo}, $t->{hi});
    my $min = 10 ** ($lo / $t->{B});
    my $max = 10 ** (($hi + 1) / $t->{B});
    my $bc  = $hi - $lo + 1;
    return { partition => { min => $min, max => $max, bpd => $t->{B},
                            decades => log($max / $min) / log(10),
                            bin_count => $bc, log_ratio => log($max / $min) },
             bins => [ map { $t->{counts}{ $lo + $_ } // 0 } 0 .. $bc - 1 ],
             overflow => 0, underflow => 0 };
}
sub target_sig {
    my ($t) = @_;
    return join(",", $t->{B}, map { "$_:$t->{counts}{$_}" } sort { $a <=> $b } keys %{ $t->{counts} });
}
sub target_bytes {
    my ($t) = @_;
    return COUNTER_BYTES_PER_PARTITION + COUNTER_BYTES_PER_BIN_SLOT * ($t->{hi} - $t->{lo} + 1);
}

sub clone_entry {
    my ($e) = @_;
    return { partition => { %{ $e->{partition} } }, bins => [ @{ $e->{bins} } ],
             overflow => $e->{overflow}, underflow => $e->{underflow},
             rebin_growth => $e->{rebin_growth}, rebin_merge => $e->{rebin_merge},
             members => $e->{members} };
}
sub entry_bytes {
    my ($e) = @_;
    return COUNTER_BYTES_PER_PARTITION + COUNTER_BYTES_PER_BIN_SLOT * scalar @{ $e->{bins} };
}

my @quantiles = (0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99);
my $member_bpd = 53;
my $bw = 10 ** (1 / $member_bpd) - 1;
my $budget = shift(@ARGV) // 512;

printf("members at %d buckets/decade; canonical target starts at 616, bucket budget %d\n\n",
       $member_bpd, $budget);

for my $file (@ARGV) {
    my (%raw, %order);
    open my $fh, '<', $file or die "$file: $!";
    my $n = 0;
    while (<$fh>) {
        chomp;
        my ($cid, $key, $vals) = split /\t/, $_, 3;
        next unless defined $vals && length $vals;
        push @{ $raw{$cid} }, [ $key, [ split / /, $vals ] ];
        $n++;
    }
    close $fh;

    my ($mismatch_def, $mismatch_can) = (0, 0);
    my (@err_def, @err_can);
    my ($bytes_def, $bytes_can) = (0, 0);
    my ($t_def, $t_can, $absorbed) = (0, 0, 0);
    my ($fold_min_bpd, $rows) = (616, 0);

    for my $cid (sort { $a <=> $b } keys %raw) {
        my @keys = @{ $raw{$cid} };
        next unless @keys >= 2;

        # Build each member's own histogram once, exactly as ltl streams it.
        my @members;
        my @pooled;
        for my $k (@keys) {
            my $entry;
            for my $v (@{ $k->[1] }) {
                next unless $v > 0;          # the bin producer is gated on duration > 0
                push @pooled, $v;
                $entry //= counter_entry_new($v, $member_bpd);
                        counter_entry_observe($entry, $v);
            }
            push @members, $entry if $entry;
        }
        next unless @members >= 2;
        $rows++;
        my @sorted = sort { $a <=> $b } @pooled;
        my @exact = map { $sorted[ POSIX::ceil($_ * scalar @sorted) - 1 ] } @quantiles;

        my ($sig_def, $sig_can);
        my ($peak_def, $peak_can) = (0, 0);
        for my $trial (0 .. 5) {
            my @idx = 0 .. $#members;
            if ($trial == 1) { @idx = reverse @idx }
            elsif ($trial > 1) {
                for (my $i = $#idx; $i > 0; $i--) {
                    my $j = int(nextval() * ($i + 1));
                    @idx[$i, $j] = @idx[$j, $i];
                }
            }
            my $batch = (8, 64, 1e9)[$trial % 3];

            # --- DEFERRED: hold everything, collapse once ---
            my $t0 = time;
            my $tgt = { partition => undef, bins => [], overflow => 0, underflow => 0 };
            my $held = 0;
            for my $i (@idx) {
                merge_bin_counter_entries($tgt, clone_entry($members[$i]));
                $held += entry_bytes($members[$i]);
            }
            $peak_def = $held if $held > $peak_def;
            collapse_bin_counter_entry($tgt);
            $t_def += time - $t0;
            my $s = join(",", map { $_ // 0 } @{ $tgt->{bins} });
            if (defined $sig_def) { $mismatch_def++ if $s ne $sig_def } else { $sig_def = $s }

            # --- CANONICAL: absorb on arrival, fold to budget ---
            $t0 = time;
            my $ct = target_new(616);
            my @pending;
            for my $i (@idx) {
                push @pending, $members[$i];
                if (@pending >= $batch) {
                    target_absorb_entry($ct, $_, $budget) for @pending;
                    @pending = ();
                }
            }
            target_absorb_entry($ct, $_, $budget) for @pending;
            $t_can += time - $t0;
            $absorbed += scalar @members;
            my $cs = target_sig($ct);
            if (defined $sig_can) { $mismatch_can++ if $cs ne $sig_can } else { $sig_can = $cs }
            $peak_can = target_bytes($ct) if target_bytes($ct) > $peak_can;
            $fold_min_bpd = $ct->{B} if $ct->{B} < $fold_min_bpd;

            next if $trial;   # accuracy measured once per row
            for my $q (0 .. $#quantiles) {
                push @err_def, abs((percentile($tgt, $quantiles[$q]))[0] - $exact[$q]) / $exact[$q] / $bw;
                push @err_can, abs((percentile(target_entry($ct), $quantiles[$q]))[0] - $exact[$q]) / $exact[$q] / $bw;
            }
        }
        $bytes_def += $peak_def;
        $bytes_can += $peak_can;
    }

    my @sd = sort { $a <=> $b } @err_def;
    my @sc = sort { $a <=> $b } @err_can;
    my $base = $file; $base =~ s{.*/groups-}{}; $base =~ s/\.tsv$//;
    printf("%s: %d grouped rows, %d message keys\n", $base, $rows, $n);
    printf("  agreement across 6 orders x batch 8/64/all: deferred %s, canonical %s\n",
           $mismatch_def ? "$mismatch_def MISMATCHES" : "identical",
           $mismatch_can ? "$mismatch_can MISMATCHES" : "identical");
    my $over_d = grep { $_ > 1 } @sd;
    my $over_c = grep { $_ > 1 } @sc;
    printf("  error vs raw durations (member bucket widths)  deferred p50 %.3f p95 %.3f max %.3f, over one bucket %d/%d (%.2f%%)\n",
           $sd[int(@sd*0.5)], $sd[int(@sd*0.95)], $sd[-1], $over_d, scalar @sd, $over_d/@sd*100);
    printf("                                                 canonical p50 %.3f p95 %.3f max %.3f, over one bucket %d/%d (%.2f%%)\n",
           $sc[int(@sc*0.5)], $sc[int(@sc*0.95)], $sc[-1], $over_c, scalar @sc, $over_c/@sc*100);
    printf("  peak memory across grouped rows: deferred %.0f KB, canonical %.0f KB (%.1fx less)\n",
           $bytes_def/1024, $bytes_can/1024, $bytes_def/($bytes_can||1));
    printf("  cost per absorbed member: deferred %.1f us, canonical %.1f us; coarsest resolution reached %g\n\n",
           $t_def/$absorbed*1e6, $t_can/$absorbed*1e6, $fold_min_bpd);
}
