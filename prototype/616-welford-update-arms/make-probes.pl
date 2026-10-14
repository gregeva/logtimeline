#!/usr/bin/env perl
# #616 D12: generate the probe binaries for the one running-mean update.
#
# Question: which arm of the one update sub lands, given its per-line cost at
# the bin model? Every probe is the base ltl with a mechanical edit; this script
# is the only author of a probe, and it asserts every landmark and substitution
# count, so a base that has moved fails loudly instead of producing a probe that
# measures something else. The arithmetic of each arm is sliced out of the base,
# never restated: the parallel combine from merge_bin_state, the
# one-observation update from the per-message loop site.
#
#   base      today's code, verbatim
#   b         one sub, the parallel combine; the loop sites call it with a
#             one-observation source (n_b = 1, mean_b = the value, moment sums 0)
#   c         one sub, the parallel combine, whose one-observation case
#             (n_b == 1) evaluates today's loop arithmetic
#   hoist     base with the two capture-mode string compares of the read loop
#             resolved to booleans once before the loop
#   b-hoist   b with the hoist
#   c-hoist   c with the hoist
#
# In b and c, merge_bin_state calls the same sub with the source's state.
#
#   usage: make-probes.pl <base ltl> <output dir>
use strict;
use warnings;

my ($base, $out) = @ARGV;
die "usage: make-probes.pl <base ltl> <output dir>\n" unless defined $base && defined $out;
mkdir $out unless -d $out;

open my $fh, '<', $base or die "$base: $!";
my @src = <$fh>;
close $fh;

sub find_all {
    my ($lines, $re, $from, $to) = @_;
    $from //= 0; $to //= $#$lines;
    return grep { $lines->[$_] =~ $re } $from .. $to;
}
sub find_one {
    my ($lines, $re, $what, $from, $to) = @_;
    my @hits = find_all($lines, $re, $from, $to);
    die "make-probes: expected exactly one line matching $what, found " . scalar(@hits) . "\n" unless @hits == 1;
    return $hits[0];
}
sub sub_range {
    my ($lines, $name) = @_;
    my $s = find_one($lines, qr/^sub \Q$name\E \{/, "sub $name");
    my ($e) = grep { $lines->[$_] =~ /^\}\s*$/ } $s + 1 .. $#$lines;
    return ($s, $e);
}
# The closing brace matching the block opened on line $i: the next line that
# is only a brace at the same indentation.
sub block_end {
    my ($lines, $i) = @_;
    my ($ind) = $lines->[$i] =~ /^(\s*)/;
    for my $j ($i + 1 .. $#$lines) {
        return $j if $lines->[$j] =~ /^\Q$ind\E\}\s*$/;
    }
    die "make-probes: no closing brace for the block opened at line " . ($i + 1) . "\n";
}
sub subst_count {
    my ($text_ref, $from, $to, $want, $what) = @_;
    my $n = () = $$text_ref =~ /\Q$from\E/g;
    die "make-probes: $what expected $want of [$from], found $n\n" unless $n == $want;
    $$text_ref =~ s/\Q$from\E/$to/g;
}

# --- slice the arithmetic out of the base ------------------------------------

# The parallel combine: merge_bin_state's else branch, from $n_ab to the mean.
my ($mb_s, $mb_e) = sub_range(\@src, 'merge_bin_state');
my $comb_s = find_one(\@src, qr/^\s*my \$n_ab\s+= \$n_a \+ \$n_b;/, 'the combine\'s first line', $mb_s, $mb_e);
my $comb_e = find_one(\@src, qr/^\s*\$target->\{_running_mean\}\s+= \$mean_ab;/, 'the combine\'s last line', $mb_s, $mb_e);
# The source's four reads become the sub's arguments of the same names.
my @combine = @src[$comb_s .. $comb_e];
my $dropped = grep { /^\s*my \$(?:mean_b|M[234]_b)\s+= \$source->/ } @combine;
die "make-probes: expected 4 source reads in the combine, found $dropped\n" unless $dropped == 4;
my $combine = join '', grep { !/^\s*my \$(?:mean_b|M[234]_b)\s+= \$source->/ } @combine;
subst_count(\$combine, '$target->',                  '$t->',    9, 'combine');
subst_count(\$combine, '$message_stats_demand_shape', '$shape', 1, 'combine');
die "make-probes: combine still reads \$source\n" if $combine =~ /\$source/;

# The one-observation update: the per-message loop site's else branch body.
my ($rp_s, $rp_e) = sub_range(\@src, 'read_and_process_logs');
my @nold = find_all(\@src, qr/^\s*my \$n_old = \$entry->\{duration_count\};/, $rp_s, $rp_e);
die "make-probes: expected 2 loop update sites, found " . scalar(@nold) . "\n" unless @nold == 2;
my $one_if   = find_one(\@src, qr/^\s*if \(\$n_old == 0\) \{/, 'the message site\'s first-observation test', $nold[0], $nold[0] + 3);
my $one_else = find_one(\@src, qr/^\s*\} else \{/, 'the message site\'s else', $one_if, $one_if + 3);
my $one_end  = block_end(\@src, $one_if);   # the else's closing brace shares the if's indentation
my $one = join '', @src[$one_else + 1 .. $one_end - 1];
subst_count(\$one, '$entry->',                    '$t->',    8, 'one-observation update');
subst_count(\$one, '$duration',                   '$mean_b', 1, 'one-observation update');
subst_count(\$one, '$message_stats_demand_shape', '$shape',  1, 'one-observation update');

# --- the two subs ----------------------------------------------------------------

my $head = <<'EOF';
# #616 D12 probe: the one running-mean update. Source state: count, mean and
# the three moment sums; $shape says whether the moment sums are kept.
sub welford_update {
    my ($t, $n_b, $mean_b, $M2_b, $M3_b, $M4_b, $shape) = @_;
    my $n_a = $t->{duration_count} // 0;
    if ($n_a == 0) {
        $t->{duration_count} = $n_b;
        $t->{_running_mean}  = $mean_b;
        if ($shape) {
            $t->{m2_sum} = $M2_b;
            $t->{m3_sum} = $M3_b;
            $t->{m4_sum} = $M4_b;
        }
        return;
    }
EOF
my $one_case = "    if (\$n_b == 1) {\n        my \$n_old = \$n_a;\n        my \$n     = \$n_old + 1;\n"
             . $one . "        \$t->{duration_count} = \$n;\n        return;\n    }\n";
my %sub_text = (
    b => $head . $combine . "}\n\n",
    c => $head . $one_case . $combine . "}\n\n",
);

# --- edits -----------------------------------------------------------------------

sub apply_sub_arm {
    my ($p, $arm) = @_;
    my ($rs, $re) = sub_range($p, 'read_and_process_logs');
    my @sites = find_all($p, qr/^\s*my \$n_old = \$entry->\{duration_count\};/, $rs, $re);
    die "make-probes: expected 2 loop update sites, found " . scalar(@sites) . "\n" unless @sites == 2;
    my @shape = ('$message_stats_demand_shape', '$bucket_stats_demand_shape');
    # Replace the later site first so the earlier one's line numbers hold.
    for my $k (1, 0) {
        my $s = $sites[$k];
        my $e = find_one($p, qr/^\s*\$entry->\{duration_count\} = \$n;/, "site ${k}'s count write", $s, $s + 40);
        my $blk = join '', @$p[$s .. $e];
        my $want_shape = $shape[$k];
        die "make-probes: site $k does not read $want_shape\n" unless $blk =~ /\Q$want_shape\E/;
        my ($ind) = $p->[$s] =~ /^(\s*)/;
        splice @$p, $s, $e - $s + 1, "${ind}welford_update(\$entry, 1, \$duration, 0, 0, 0, $want_shape);\n";
    }
    # merge_bin_state: the whole first-observation / combine block becomes one call.
    my ($ms, $me) = sub_range($p, 'merge_bin_state');
    my $if = find_one($p, qr/^\s*if \(\$n_a == 0\) \{/, 'merge_bin_state\'s adoption test', $ms, $me);
    my $else = find_one($p, qr/^\s*\} else \{/, 'merge_bin_state\'s else', $if, $me);
    my $end = block_end($p, $if);
    die "make-probes: merge_bin_state's block does not end after its else\n" unless $end > $else;
    my ($ind) = $p->[$if] =~ /^(\s*)/;
    splice @$p, $if, $end - $if + 1,
        "${ind}welford_update(\$target, \$n_b, \$source->{_running_mean}, \$source->{m2_sum} // 0, \$source->{m3_sum} // 0, \$source->{m4_sum} // 0, \$message_stats_demand_shape);\n";
    # The sub itself, just before merge_bin_state.
    my ($ms2) = sub_range($p, 'merge_bin_state');
    splice @$p, $ms2, 0, $sub_text{$arm};
}

sub apply_hoist {
    my ($p) = @_;
    my ($rs, $re) = sub_range($p, 'read_and_process_logs');
    my $loop  = find_one($p, qr/^\s*while \(1\) \{/, 'the per-line loop', $rs, $re);
    my $close = find_one($p, qr/^\s*close \$fh;/, 'close $fh after the loop', $loop, $re);
    my $modes = find_one($p, qr/^\s*\$bucket_stats_capture_mode\s*=\s*choose_data_model\('bucket-stats'\)/, 'the capture-mode settlement', $rs, $loop);
    my %subst = (
        q{$message_stats_capture_mode eq 'bin'} => [ '$message_stats_is_bin', 5 ],
        q{$bucket_stats_capture_mode eq 'bin'}  => [ '$bucket_stats_is_bin',  3 ],
    );
    for my $from (sort keys %subst) {
        my ($to, $want) = @{ $subst{$from} };
        my $n = 0;
        for my $i ($loop .. $close) {
            my $c = () = $p->[$i] =~ /\Q$from\E/g;
            next unless $c;
            $p->[$i] =~ s/\Q$from\E/$to/g;
            $n += $c;
        }
        die "make-probes: hoist expected $want substitutions of [$from] in the loop, made $n\n" unless $n == $want;
    }
    splice @$p, $modes + 1, 0,
        "    my \$message_stats_is_bin = \$message_stats_capture_mode eq 'bin' ? 1 : 0;\n",
        "    my \$bucket_stats_is_bin  = \$bucket_stats_capture_mode  eq 'bin' ? 1 : 0;\n";
}

sub write_probe {
    my ($name, $lines) = @_;
    my $path = "$out/ltl-$name";
    open my $o, '>', $path or die "$path: $!";
    print {$o} @$lines;
    close $o;
    chmod 0755, $path;
    print "wrote $path\n";
}

for my $arm (qw(base b c)) {
    for my $hoist (0, 1) {
        my @p = @src;
        apply_sub_arm(\@p, $arm) unless $arm eq 'base';
        apply_hoist(\@p) if $hoist;
        my $name = $arm eq 'base' ? ($hoist ? 'hoist' : 'base') : ($hoist ? "$arm-hoist" : $arm);
        write_probe($name, \@p);
    }
}
print "done: 6 binaries\n";
