#!/usr/bin/env perl
# 525-nanosecond-cost.pl — cost prototype for carrying a timestamp's nanoseconds
# exactly (features/525-timestamp-precision-option.md § 6.5 and § 9, D4).
#
# Question: how to carry the sub-second part exactly from the parse to the
# consumers that render it at nanosecond precision (the heading bounds, the
# export observation, the run index's first and last timestamps), and at what
# per-line cost when nanosecond is asked for. When it is not asked for, the
# generated scan block is today's (a compile-time choice, as for the capture
# gate of step 3d), so that arm is the baseline by construction.
#
# Arms, each run over the same timestamp strings:
#   A  baseline: today's per-line code, sliced verbatim out of ltl (the
#      variable-length strip and conversion, the epoch derivation, and the
#      first/last tracking of the run index's file and selection rows and of
#      the heading's bounds).
#   B  A, plus integer nanoseconds from the parse's digit string beside the
#      integer seconds; first and last kept exact as (seconds, nanoseconds)
#      pairs.
#   C  A, plus one 64-bit integer of nanoseconds (seconds * 1e9 + ns); first
#      and last kept exact as that integer.
#   D  A's floating-point first/last comparisons kept, the line's fraction
#      digits kept as a string; the exact (seconds, nanoseconds) is taken only
#      when a bound moves, and compared only on a floating-point tie. Rounding
#      to the nearest double never reverses the order of two instants, it can
#      only make them equal, so a tie is the one case the float cannot decide.
#   G  A with D's bound updates behind a run flag, switched off: the read loop
#      is hand-written, not generated, so a run that does not ask for
#      nanosecond pays one flag test at each of the three places the bounds
#      are updated (the file row's first/last, the selection row's, the
#      heading's). G against A is the cost of not asking.
#   H  A's six bound statements unchanged, plus two flag tests per line (one
#      before the filters, for the file row's bounds; one after, for the
#      selection row's and the heading's). With the flag on, a bound whose
#      value equals this line's epoch (it just moved here, or it ties) takes
#      this line's exact (seconds, digits) if they are better. H0 (flag off) is
#      the cost of not asking; H1 (flag on) the cost of asking.
#
# Usage: perl 525-nanosecond-cost.pl <path-to-ltl> [rounds]   (rounds 0: validation only)
# Prints a validation block (every line's nine digits reproduced) and a
# timing table: ns/line, median and range of the interleaved rounds.

use strict;
use warnings;
use Time::HiRes qw(time);
use Time::Local qw(timegm);

my $ltl    = shift // 'ltl';
my $rounds = shift // 3;

# --- Slice the production code out of ltl ------------------------------------
open my $lfh, '<', $ltl or die "cannot read $ltl: $!\n";
my $src = do { local $/; <$lfh> };
close $lfh;
my %piece;
# format_entry_block_src(): the variable-length (generic) fraction block, the
# capture-gate-open form.
($piece{strip}) = $src =~ /\$capture \? q\{(if \(\$timestamp_str =~ s\/\(:\\d\{2\}:\\d\{2\}\)\[\.,\]\(\\d\{1,6\}\)\/\$1\/\) \{ \$fractional_ms = .*?\} else \{ \$fractional_ms = 0; \})\}/;
# read_and_process_logs(): the epoch, the run index's file and selection
# first/last, and the heading's bounds (here unfolded, $bucket_epoch being
# $timestamp_epoch outside --profile).
($piece{epoch})      = $src =~ /^\s*(my \$timestamp_epoch = \$timestamp \+ \(\$fractional_ms \/ 1000\);)$/m;
($piece{first})      = $src =~ /^\s*(\$fd->\{first_timestamp\} = \$timestamp_epoch if [^\n]*;)$/m;
($piece{last})       = $src =~ /^\s*(\$fd->\{last_timestamp\}  = \$timestamp_epoch if [^\n]*;)$/m;
($piece{sel_first})  = $src =~ /^\s*(\$fd->\{sel_first_timestamp\} = \$timestamp_epoch if [^\n]*;)$/m;
($piece{sel_last})   = $src =~ /^\s*(\$fd->\{sel_last_timestamp\}  = \$timestamp_epoch if [^\n]*;)$/m;
($piece{out_min})    = $src =~ /^\s*(\$output_timestamp_min = \$bucket_epoch if [^\n]*;)$/m;
($piece{out_max})    = $src =~ /^\s*(\$output_timestamp_max = \$bucket_epoch if [^\n]*;)$/m;
for my $k (qw(strip epoch first last sel_first sel_last out_min out_max)) {
    die "production piece '$k' not found in $ltl\n" unless defined $piece{$k};
}

# --- The arms ----------------------------------------------------------------
# The record lexicals are file-scoped, as in ltl, and the arm subs close over
# them, as the generated scan sub does.
my ($timestamp_str, $timestamp, $fractional_ms, $fraction_ns, $fraction_digits);
my ($output_timestamp_min, $output_timestamp_max, $out_min_sec, $out_min_ns, $out_max_sec, $out_max_ns, $out_min_e, $out_max_e);
my %index_file_data;
my $midnight = timegm(0, 0, 0, 26, 0, 2026);

# The layout parse is the same in every arm: the date's cached midnight plus
# the time of day as arithmetic (compile_format_time_parser()'s shape).
my $parse = q{$timestamp = $midnight + substr($timestamp_str, 11, 2) * 3600 + substr($timestamp_str, 14, 2) * 60 + substr($timestamp_str, 17, 2);};

# B and C read up to nine digits and keep them as an integer as well.
(my $strip9 = $piece{strip}) =~ s/\\d\{1,6\}/\\d{1,9}/ or die "cannot widen the strip\n";
$strip9 =~ s/(\$fractional_ms = \$2 \* \(10 \*\* \(3 - length\(\$2\)\)\);)/$1 \$fraction_ns = substr(\$2 . '00000000', 0, 9) + 0;/ or die "cannot add the integer\n";
$strip9 =~ s/(else \{ \$fractional_ms = 0;)/$1 \$fraction_ns = 0;/ or die "cannot zero the integer\n";

my $pair_minmax = join "\n", map {
    my ($first, $sec, $ns) = @$_;
    my $cmp = $first ? '<' : '>';
    "if (!defined $sec || \$timestamp $cmp $sec || (\$timestamp == $sec && \$fraction_ns $cmp $ns)) { $sec = \$timestamp; $ns = \$fraction_ns; }"
} ( [1, '$fd->{first_sec}', '$fd->{first_ns}'], [0, '$fd->{last_sec}', '$fd->{last_ns}'],
    [1, '$fd->{sel_first_sec}', '$fd->{sel_first_ns}'], [0, '$fd->{sel_last_sec}', '$fd->{sel_last_ns}'],
    [1, '$out_min_sec', '$out_min_ns'], [0, '$out_max_sec', '$out_max_ns'] );

my $int_minmax = q{my $epoch_ns = $timestamp * 1_000_000_000 + $fraction_ns;} . "\n" . join "\n", map {
    my ($first, $var) = @$_;
    my $cmp = $first ? '<' : '>';
    "$var = \$epoch_ns if !defined $var || \$epoch_ns $cmp $var;"
} ( [1, '$fd->{first_e}'], [0, '$fd->{last_e}'], [1, '$fd->{sel_first_e}'], [0, '$fd->{sel_last_e}'],
    [1, '$out_min_e'], [0, '$out_max_e'] );

my $common = join "\n", $piece{epoch}, 'my $fd = $index_file_data{f};', $piece{first}, $piece{last},
                        $piece{sel_first}, $piece{sel_last}, 'my $bucket_epoch = $timestamp_epoch;',
                        $piece{out_min}, $piece{out_max};

# D keeps the digit string only.
(my $stripD = $piece{strip}) =~ s/\\d\{1,6\}/\\d{1,9}/ or die "cannot widen the strip (D)\n";
$stripD =~ s/(\$fractional_ms = \$2 \* \(10 \*\* \(3 - length\(\$2\)\)\);)/$1 \$fraction_digits = \$2;/ or die "cannot keep the digits\n";
$stripD =~ s/(else \{ \$fractional_ms = 0;)/$1 \$fraction_digits = '';/ or die "cannot clear the digits\n";
# The six bounds, as A tracks them, each taking the exact value when it moves
# or ties; the tie compares (seconds, nanoseconds).
my $ns_of = sub { "(substr($_[0] . '000000000', 0, 9) + 0)" };
my $tie_bounds = join "\n", map {
    my ($first, $e, $sec, $dig, $init) = @$_;
    my $cmp = $first ? '<' : '>';
    "if (!defined $sec || \$timestamp_epoch $cmp $e || (\$timestamp_epoch == $e && (\$timestamp $cmp $sec || (\$timestamp == $sec && " . $ns_of->('$fraction_digits') . " $cmp " . $ns_of->($dig) . ")))) { $e = \$timestamp_epoch; $sec = \$timestamp; $dig = \$fraction_digits; }"
} ( [1, '$fd->{first_timestamp}',     '$fd->{first_sec}',     '$fd->{first_dig}'],
    [0, '$fd->{last_timestamp}',      '$fd->{last_sec}',      '$fd->{last_dig}'],
    [1, '$fd->{sel_first_timestamp}', '$fd->{sel_first_sec}', '$fd->{sel_first_dig}'],
    [0, '$fd->{sel_last_timestamp}',  '$fd->{sel_last_sec}',  '$fd->{sel_last_dig}'],
    [1, '$output_timestamp_min',      '$out_min_sec',         '$out_min_ns'],
    [0, '$output_timestamp_max',      '$out_max_sec',         '$out_max_ns'] );
my $commonD = join "\n", $piece{epoch}, 'my $fd = $index_file_data{f};', 'my $bucket_epoch = $timestamp_epoch;', $tie_bounds;

# G: the three update sites, each choosing D's form or A's on a flag.
my $ns_flag = 0;
my $gated = join "\n", $piece{epoch}, 'my $fd = $index_file_data{f};',
    "if (\$ns_flag) { " . join(' ', (split /\n/, $tie_bounds)[0, 1]) . " } else { $piece{first} $piece{last} }",
    "if (\$ns_flag) { " . join(' ', (split /\n/, $tie_bounds)[2, 3]) . " } else { $piece{sel_first} $piece{sel_last} }",
    'my $bucket_epoch = $timestamp_epoch;',
    "if (\$ns_flag) { " . join(' ', (split /\n/, $tie_bounds)[4, 5]) . " } else { $piece{out_min} $piece{out_max} }";

# H: today's statements, then the exact follow-up behind one flag per site.
my $follow = sub {
    my ($first, $e, $sec, $dig) = @_;
    my $cmp = $first ? '<' : '>';
    "if (\$timestamp_epoch == $e && (!defined $sec || \$timestamp $cmp $sec || (\$timestamp == $sec && " . $ns_of->('$fraction_digits') . " $cmp " . $ns_of->($dig) . "))) { $sec = \$timestamp; $dig = \$fraction_digits; }"
};
my $site1 = join ' ', $follow->(1, '$fd->{first_timestamp}', '$fd->{first_sec}', '$fd->{first_dig}'),
                      $follow->(0, '$fd->{last_timestamp}',  '$fd->{last_sec}',  '$fd->{last_dig}');
my $site2 = join ' ', $follow->(1, '$fd->{sel_first_timestamp}', '$fd->{sel_first_sec}', '$fd->{sel_first_dig}'),
                      $follow->(0, '$fd->{sel_last_timestamp}',  '$fd->{sel_last_sec}',  '$fd->{sel_last_dig}'),
                      $follow->(1, '$output_timestamp_min', '$out_min_sec', '$out_min_ns'),
                      $follow->(0, '$output_timestamp_max', '$out_max_sec', '$out_max_ns');
my $hsrc = join "\n", $piece{epoch}, 'my $fd = $index_file_data{f};', $piece{first}, $piece{last},
    "if (\$ns_flag) { $site1 }",
    $piece{sel_first}, $piece{sel_last}, 'my $bucket_epoch = $timestamp_epoch;', $piece{out_min}, $piece{out_max},
    "if (\$ns_flag) { $site2 }";
my $ns_on = 1;
(my $hsrc_on = $hsrc) =~ s/\$ns_flag/\$ns_on/g;

my %arm_src = (
    A => join("\n", $piece{strip}, $parse, $common),
    B => join("\n", $strip9,       $parse, $common, $pair_minmax),
    C => join("\n", $strip9,       $parse, $common, $int_minmax),
    D => join("\n", $stripD,       $parse, $commonD),
    G => join("\n", $piece{strip}, $parse, $gated),
    H0 => join("\n", $piece{strip}, $parse, $hsrc),
    H1 => join("\n", $stripD,       $parse, $hsrc_on),
);
my %arm;
for my $name (sort keys %arm_src) {
    my $code = "sub { my (\$lines) = \@_; for my \$line (\@\$lines) { \$timestamp_str = \$line;\n$arm_src{$name}\n } }";
    $arm{$name} = eval $code or die "arm $name does not compile: $@\n$code\n";
}

sub reset_state {
    %index_file_data = ( f => {} );
    ($output_timestamp_min, $output_timestamp_max) = (0, 0);
    ($out_min_sec, $out_min_ns, $out_max_sec, $out_max_ns, $out_min_e, $out_max_e) = ();
}

# --- Fixtures: timestamp strings as the strip sees them -----------------------
sub fixture {
    my ($n, $digits, $seed) = @_;
    srand($seed);
    my @lines;
    my $t = 0;
    for (1 .. $n) {
        $t += int(rand(50));                               # dense: up to 50 ms apart
        my $sec  = 36000 + int($t / 1000);
        my $frac = join '', map { int(rand(10)) } 1 .. $digits;
        push @lines, sprintf("2026-01-26 %02d:%02d:%02d.%s", $sec / 3600, ($sec / 60) % 60, $sec % 60, $frac);
    }
    return \@lines;
}

# --- Validation: nine digits reproduced on every line, and the bounds --------
sub validate {
    my ($lines) = @_;
    my ($bad_b, $bad_c, $bad_float) = (0, 0, 0);
    for my $line (@$lines) {
        my ($want) = $line =~ /\.(\d+)$/;
        $want = substr($want . '00000000', 0, 9);
        $timestamp_str = $line;
        eval $strip9; die $@ if $@;
        eval $parse;  die $@ if $@;
        $bad_b++ unless sprintf('%09d', $fraction_ns) eq $want;
        my $epoch_ns = $timestamp * 1_000_000_000 + $fraction_ns;
        $bad_c++ unless sprintf('%09d', $epoch_ns % 1_000_000_000) eq $want;
        my $float = $timestamp + ($fractional_ms / 1000);
        $bad_float++ unless sprintf('%09d', int(($float - int($float)) * 1e9 + 0.5)) eq $want;
    }
    my @sorted = sort @$lines;
    my ($lo, $hi) = map { /\.(\d+)$/ ? substr($1 . '00000000', 0, 9) : '' } $sorted[0], $sorted[-1];
    for my $x (qw(B C)) { reset_state(); $arm{$x}->($lines) }
    my $fd = $index_file_data{f};
    my $c_lo = sprintf('%09d', $fd->{first_e} % 1_000_000_000);
    my $c_hi = sprintf('%09d', $fd->{last_e}  % 1_000_000_000);
    reset_state(); $arm{B}->($lines); $fd = $index_file_data{f};
    my ($b_lo, $b_hi) = map { sprintf('%09d', $_) } $fd->{first_ns}, $fd->{last_ns};
    reset_state(); $arm{H1}->($lines); my $hfd = $index_file_data{f};
    my $h_ok = join(',', map { substr(($_ // '') . '000000000', 0, 9) } @$hfd{qw(first_dig last_dig sel_first_dig sel_last_dig)}, $out_min_ns, $out_max_ns) eq join(',', $lo, $hi, $lo, $hi, $lo, $hi);
    reset_state(); $arm{D}->($lines); $fd = $index_file_data{f};
    my ($d_lo, $d_hi) = map { substr($_ . '000000000', 0, 9) } $fd->{first_dig}, $fd->{last_dig};
    my ($d_slo, $d_shi) = map { substr($_ . '000000000', 0, 9) } $fd->{sel_first_dig}, $fd->{sel_last_dig};
    my ($d_olo, $d_ohi) = map { substr($_ . '000000000', 0, 9) } $out_min_ns, $out_max_ns;
    my $d_ok = ($d_lo eq $lo && $d_hi eq $hi && $d_slo eq $lo && $d_shi eq $hi && $d_olo eq $lo && $d_ohi eq $hi);
    return { lines => scalar(@$lines), bad_b => $bad_b, bad_c => $bad_c, bad_float => $bad_float,
             bounds_h => $h_ok ? 'exact' : 'WRONG',
             bounds_d => $d_ok ? 'exact' : "WRONG (file $d_lo..$d_hi sel $d_slo..$d_shi out $d_olo..$d_ohi want $lo..$hi)",
             bounds_b => ($b_lo eq $lo && $b_hi eq $hi) ? 'exact' : "WRONG ($b_lo..$b_hi want $lo..$hi)",
             bounds_c => ($c_lo eq $lo && $c_hi eq $hi) ? 'exact' : "WRONG ($c_lo..$c_hi want $lo..$hi)" };
}

# --- Timing --------------------------------------------------------------------
sub median { my @s = sort { $a <=> $b } @_; return $s[ int($#s / 2) ] }

# Ties: lines nanoseconds apart that the floating-point epoch cannot tell
# apart, arriving out of order, and a .999999999 beside the next second's
# .000000000, which round to the same double.
{
    my @tie = map { "2026-01-26 10:00:$_" } qw(00.123456789 00.123456700 00.999999999 01.000000000 00.999999998 00.123456701);
    my $v = validate(\@tie);
    printf "# validation, crafted ties (%d lines): first/last: B %s, C %s, D %s, H1 %s\n", $v->{lines}, $v->{bounds_b}, $v->{bounds_c}, $v->{bounds_d}, $v->{bounds_h};
}

exit 0 unless $rounds;   # 0 rounds: the validation only

my %repeat = (1_000 => 200, 10_000 => 20, 100_000 => 2, 1_000_000 => 1);
printf "%-9s %-6s %-6s %8s %8s %8s   %s\n", 'fraction', 'lines', 'arm', 'median', 'min', 'max', 'ns/line, interleaved rounds';
for my $digits (3, 9) {
    for my $n (1_000, 10_000, 100_000, 1_000_000) {
        my $lines = fixture($n, $digits, 525 + $digits);
        if ($n == 1_000_000) {
            my $v = validate($lines);
            printf "# validation, %d-digit fractions, %d lines: every line's nine digits: B %s, C %s; the floating epoch misses %d lines; first/last: B %s, C %s, D %s, H1 %s\n",
                $digits, $v->{lines}, $v->{bad_b} ? "$v->{bad_b} WRONG" : 'exact', $v->{bad_c} ? "$v->{bad_c} WRONG" : 'exact',
                $v->{bad_float}, $v->{bounds_b}, $v->{bounds_c}, $v->{bounds_d}, $v->{bounds_h};
        }
        my %ns;
        for my $x (qw(A B C D G H0 H1)) { reset_state(); $arm{$x}->($lines) }   # warm-up, untimed
        for my $round (1 .. $rounds) {
            for my $x (qw(A B C D G H0 H1)) {
                reset_state();
                my $t0 = time;
                $arm{$x}->($lines) for 1 .. $repeat{$n};
                push @{ $ns{$x} }, (time - $t0) * 1e9 / ($n * $repeat{$n});
            }
        }
        for my $x (qw(A B C D G H0 H1)) {
            my @v = @{ $ns{$x} };
            my ($lo, $hi) = (sort { $a <=> $b } @v)[0, -1];
            printf "%-9s %-6s %-6s %8.0f %8.0f %8.0f   %s\n", "$digits-digit", $n, $x, median(@v), $lo, $hi,
                $x eq 'A' ? '' : sprintf('%+.0f ns vs A', median(@v) - median(@{ $ns{A} }));
        }
    }
}
