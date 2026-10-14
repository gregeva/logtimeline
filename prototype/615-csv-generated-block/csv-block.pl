#!/usr/bin/env perl
#
# csv-block.pl - drop 1 prototype for features/615-csv-registry-entry.md § 8:
# today's inline CSV arms (A) against a block generated per header shape (B)
# through the scanned formats' emitter, with the memo, and B without the memo
# (B-no-memo, attribution only).
#
# Loads ltl's source up to its `## MAIN ##` marker and evals it together with
# the driver below (the 384-variant-selection-mini.pl pattern), so the driver
# shares ltl's file-scoped lexicals and drives the production subs.
#
# Arm A is the production code verbatim: the read loop's per-line
# declarations, the steady CSV arm, the shared metric capture and the
# timestamp arms are sliced out of read_and_process_logs() by anchor lines
# and compiled into one loop. Arm B's loop is the same slices with the steady
# arm replaced by a call to the generated block and the capture's CSV branch
# reading the value the block extracted. B's timestamp text is sliced out of
# format_entry_block_src(): the timestamp part of the emitter, as the
# proposed split (§ 5.3) would call it; the epoch layout is prototype text.
#
# Usage (one configuration per process, ltl options after --):
#   perl csv-block.pl --mode parity  --file F [--hand iso|epoch|dayfirst] -- -udm latency_ms -tp ms
#   perl csv-block.pl --mode timing  --file F --rounds 5 -- -udm latency_ms
#   perl csv-block.pl --mode perfile --file F --rounds 21 -- -udm cpu_total
#   perl csv-block.pl --mode src     --file F -- -udm cpu_total     (print B's source)
#
# Output: TSV rows on stdout, narrative on stderr.

use strict;
use warnings;
use FindBin;

my $ltl_path = "$FindBin::Bin/../../ltl";
my $ltl_src = do { open my $fh, '<', $ltl_path or die "open $ltl_path: $!"; local $/; <$fh> };
$ltl_src =~ s/^## MAIN ##.*\z//ms or die "no ## MAIN ## marker in $ltl_path";
our $LTL_SRC = $ltl_src;
my $driver = do { local $/; <DATA> };
our @PROTO_ARGV = @ARGV;
@ARGV = ();
eval "#line 1 \"$ltl_path\"\n$ltl_src\n;\n#line 1 \"615-driver\"\n$driver";
die $@ if $@;
exit 0;

__DATA__
# ---------------------------------------------------------------------------
# Driver: runs inside ltl's file scope.
# ---------------------------------------------------------------------------
use Time::HiRes qw(gettimeofday tv_interval);
use Getopt::Long qw(GetOptionsFromArray);

my ($P_MODE, $P_FILE, $P_ROUNDS, $P_HAND, $P_MINROWS) = ('parity', undef, 5, '', 200_000);
{
    my @args = @main::PROTO_ARGV;
    my @ltl_args;
    if (my ($dd) = grep { $args[$_] eq '--' } 0 .. $#args) { @ltl_args = splice(@args, $dd); shift @ltl_args; }
    GetOptionsFromArray(\@args, 'mode=s' => \$P_MODE, 'file=s' => \$P_FILE, 'rounds=i' => \$P_ROUNDS,
        'hand=s' => \$P_HAND, 'minrows=i' => \$P_MINROWS) or die "bad options\n";
    die "--file is required\n" unless defined $P_FILE;
    @ARGV = (@ltl_args, '-ni', '--disable-progress', $P_FILE);
    @main::PROTO_LTL_ARGS = @ltl_args;
}

sub p_note { print STDERR "# @_\n" }
sub p_row  { print join("\t", @_), "\n" }
sub p_stats { my @s = sort { $a <=> $b } @_; my $n = @s; return (0,0,0) unless $n;
    return (($n % 2 ? $s[($n-1)/2] : ($s[$n/2-1] + $s[$n/2]) / 2), $s[0], $s[-1]); }

# --- the run's own option processing, terminal settings and registry --------
{
    open my $saved_out, '>&', \*STDOUT or die;
    open STDOUT, '>', '/dev/null' or die;      # the title and any banner
    adapt_to_command_line_options( title => 0 );
    adapt_to_terminal_settings();
    build_format_registry();
    open STDOUT, '>&', $saved_out or die;
}
my $csv_entry = $format_registry_entry{csv} or die "no csv entry\n";
my $csv_spec  = $format_registry_spec{csv};
format_seat_declared_levels($csv_entry);     # what the first matched line does
p_note("gate: capture_fraction=$timestamp_capture_fraction capture_ns=$timestamp_capture_ns precision=$timestamp_precision"
     . " du=" . ($duration_unit_override // '-') . " udm=" . join(',', map { $_->{base_name} } @udm_configs));

# --- the fixture, in memory ------------------------------------------------
my @LINES = do { open my $fh, '<', $P_FILE or die "$P_FILE: $!"; my @l = <$fh>; s/[\r\n]+$// for @l; @l };
my $HEADER = shift @LINES;
my $ROWS = @LINES;
my $in_file = $P_FILE;

# --- slices of the production read loop -------------------------------------
sub p_slice {   # text from the line holding $from to the line holding $to
    my ($from, $to, %o) = @_;
    my $i = index($main::LTL_SRC, $from); die "anchor not found: $from\n" if $i < 0;
    die "anchor not unique: $from\n" if index($main::LTL_SRC, $from, $i + 1) >= 0 && !$o{first};
    $i = rindex($main::LTL_SRC, "\n", $i) + 1;
    my $j = index($main::LTL_SRC, $to, $i); die "anchor not found: $to\n" if $j < 0;
    $j = $o{exclusive} ? rindex($main::LTL_SRC, "\n", $j) + 1 : index($main::LTL_SRC, "\n", $j) + 1;
    return substr($main::LTL_SRC, $i, $j - $i);
}
my $SL_LOCALS  = p_slice('my ( $log_level, $category, $threadpool ) = ("") x 3;', 'my @csv_fields;');
my $SL_STEADY  = p_slice('## CSV data line (only after CSV confirmed via two-line validation) ##', '## Registry scan (#58)', exclusive => 1) . "}\n";
my $SL_CAPTURE = p_slice('my %udm_values;', '$metrics_observed = 1 if %udm_values;');
my $SL_TSARMS  = p_slice('if ($csv_epoch_timestamp) {', 'my $timestamp_epoch = $timestamp + ($fractional_ms / 1000);', first => 1);
die "timestamp arms slice does not start at the epoch arm\n" unless $SL_TSARMS =~ /\A\s*if \(\$csv_epoch_timestamp\) \{/;
my $SL_GATE    = p_slice('unless (exists $log_level_set{$category_bucket}) {', '} elsif (!$csv_epoch_timestamp && $match_type == 13) {', exclusive => 1, first => 1) . "}\n";
($SL_GATE) = $SL_GATE =~ /(\s*unless \(exists \$log_level_set\{\$category_bucket\}\) \{.*)\z/s or die "gate slice\n";

# B's capture: the CSV branch reads the value the block extracted, by the
# metric's position in the -udm list (D10), with no column-map lookup.
my $SL_CAPTURE_B = $SL_CAPTURE;
my $n_sub = $SL_CAPTURE_B =~ s{# CSV: extract by column index\n.*?\n(\s*)\} else \{\n(\s*)# Regex}
                              {# CSV: the block's extracted value\n$1    \$matched_value = \$csv_udm_values[\$config_idx];\n$1\} else \{\n$2# Regex}s;
die "capture CSV branch not replaced ($n_sub)\n" unless $n_sub == 1;

# The emitter's timestamp part, sliced out of format_entry_block_src(): the
# proposed split (§ 5.3). The day-first CSV layout takes the day-first
# offsets as iso_ms_ddmm does, and keeps the csv miss branch (D7).
my $SL_EMIT = p_slice(q{my $frac = $spec->{time}{frac} // 'generic';}, q{return ($aux_decl, $cond_src, join("\n", @body), \@aux);}, exclusive => 1);
$SL_EMIT =~ s/\$layout eq 'iso_ms_ddmm' \? \(5, 8\)/(\$layout eq 'iso_ms_ddmm' || \$layout eq 'csv_ddmm') ? (5, 8)/ == 1 or die "date-order choice not found\n";
my $emit_timestamp = eval "sub { my (\$spec, \$opts) = \@_; my \@body;\n$SL_EMIT\nreturn join(\"\\n\", \@body); }" or die "emitter slice: $@";

my @csv_udm_values;      # the values the B block extracted, by -udm position

# --- arm loops -----------------------------------------------------------------
# One compiled loop per arm over the in-memory rows. $record pushes the
# per-row result for the parity battery; the timing build pushes nothing.
sub p_record_src {
    # $fraction_digits is read only under nanosecond (the index bounds), so
    # it is compared only there.
    my $fd = $timestamp_capture_ns ? q{$fraction_digits // ''} : q{'-'};
    return qq{push \@\$out, join('|', \$timestamp, \$fractional_ms, $fd, join(',', map { "\$_=\$udm_values{\$_}" } sort keys %udm_values), \$message, \$category_bucket, \$line_outcome);};
}
sub build_loop {
    my ($arm, $record, $block) = @_;
    my $head = $arm eq 'A' ? $SL_STEADY : q{
            unless ($block->($_)) { note_unmatched_line($in_file); push @$out, 'UNMATCHED' if $record_on; next; }
            $is_line_match = 1; $match_type = 13; $line_entry = $format_registry_entry{csv};
};
    my $capture = $arm eq 'A' ? $SL_CAPTURE : $SL_CAPTURE_B;
    my $ts = $arm eq 'A' ? $SL_TSARMS : $SL_GATE . "my \$timestamp_epoch = \$timestamp + (\$fractional_ms / 1000);\n";
    my $rec = $record ? p_record_src() : '';
    my $unm = $arm eq 'A' && $record ? q{push @$out, 'UNMATCHED' if $record_on;} : '';
    $head =~ s/(note_unmatched_line\(\$in_file\);)/$1 $unm/g if $unm;
    my $src = qq{sub {
    my (\$rows, \$out, \$record_on) = \@_;
    my \$line_number = 1;
    for (\@\$rows) {
        \$line_number++;
$SL_LOCALS
$head
$capture
$ts
        $rec
    }
    return;
}};
    my $sub = eval $src;
    die "loop $arm codegen: $@\n$src\n" if $@ || ref $sub ne 'CODE';
    return ($sub, $src);
}

# --- the B block --------------------------------------------------------------
# The header shape (D10): separator, timestamp column and kind, each -udm
# metric's column (-1 when the header does not carry it), the -ucm columns.
sub header_shape {
    my ($kind) = @_;
    return { sep => $csv_separator, ts => $csv_timestamp_col, kind => $kind,
             metrics => [ @csv_udm_col_indices ], msg => [ @csv_message_col_indices ] };
}
sub epoch_timestamp_src {      # prototype text: the epoch layout under the read gate (§ 5.3, proposed)
    my ($opts, $memo) = @_;
    if (defined $duration_unit_override) {
        my $step = $time_unit_step{$duration_unit_override};
        my $scale = $step->{ms} >= 1000 ? '* ' . sprintf('%.17g', $step->{ms} / 1000)
                                        : '/ ' . sprintf('%.17g', ($step->{per_ms} // 1) * 1000);
        my $frac = $opts->{capture_fraction} ? q{my $frac = $v - $timestamp; $fractional_ms = $frac > 0 ? $frac * 1000 : 0;} : q{$fractional_ms = 0;};
        my $nsd  = $opts->{capture_ns} ? q{ $fraction_digits = '';} : '';
        return qq{{ my \$v = \$timestamp_str $scale; \$timestamp = int(\$v); $frac$nsd }};
    }
    my $frac = $opts->{capture_ns}
        ? q{if ($timestamp_str =~ s/\.(\d{1,9})\d*$//) { $fractional_ms = $1 * (10 ** (3 - length($1))); $fraction_digits = $1; } else { $fractional_ms = 0; $fraction_digits = ''; }}
        : $opts->{capture_fraction}
        ? q{{ my $frac = $timestamp_str - int($timestamp_str); $fractional_ms = $frac > 0 ? $frac * 1000 : 0; $timestamp_str =~ s/\.\d+$//; }}
        : q{$timestamp_str =~ s/\.\d+$//; $fractional_ms = 0;};
    my $parse = $memo
        ? q{if ($timestamp_str eq $format_last_ts_str) { $timestamp = $format_last_ts_epoch; }
else { $timestamp = $format_last_ts_epoch = $timestamp_str + 0; $format_last_ts_str = $timestamp_str; }}
        : q{$timestamp = $timestamp_str + 0;};
    return "$frac\n$parse";
}
sub csv_block_src {
    my ($shape, $layout, %o) = @_;
    my $memo = $o{memo} // 1;
    my $sep = quotemeta $shape->{sep};
    my @s;
    push @s, "my \@f = split(/$sep/, \$_[0], -1);";
    push @s, "\$timestamp_str = \$f[$shape->{ts}];";
    push @s, q{$timestamp_str =~ s/^\s+|\s+$//g if defined $timestamp_str;};
    push @s, $shape->{kind} eq 'epoch'
        ? q{return 0 unless defined $timestamp_str && $timestamp_str =~ /^\d+(?:\.\d+)?$/;}
        : q{return 0 unless defined $timestamp_str && $timestamp_str =~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/;};
    my @m = @{ $shape->{metrics} };
    for my $i (0 .. $#m) {
        push @s, $m[$i] < 0 ? "\$csv_udm_values[$i] = undef;"
                            : "if (defined \$f[$m[$i]]) { \$f[$m[$i]] =~ s/^\\s+|\\s+\$//g; \$csv_udm_values[$i] = \$f[$m[$i]] ne '' ? \$f[$m[$i]] : undef; } else { \$csv_udm_values[$i] = undef; }";
    }
    my @mc = @{ $shape->{msg} };
    push @s, @mc > 1  ? '$message = join(\' \', map { (defined $_ ? $_ : \'\') =~ s/^\s+|\s+$//gr } @f[' . join(',', @mc) . ']);'
           : @mc == 1 ? "\$message = (defined \$f[$mc[0]] ? \$f[$mc[0]] : '') =~ s/^\\s+|\\s+\$//gr;"
           :            '$message = "CSV data";';
    push @s, q{$category_bucket = "DATA"; $metrics_observed = 1;};
    push @s, q{( $object, $instance, $user, $session, $platform, $thread ) = ("") x 6; ( $bytes, $duration ) = ( undef, undef ); $status_code = 0;};
    push @s, $csv_spec->{_cls_src};
    my $opts = { capture_fraction => $timestamp_capture_fraction, capture_ns => $timestamp_capture_ns };
    my $ts = $shape->{kind} eq 'epoch'
        ? epoch_timestamp_src($opts, $memo)
        : $emit_timestamp->({ name => 'csv', time => { layout => $layout, frac => 'generic' } }, $opts);
    $ts =~ s/if \(\$timestamp_str eq \$format_last_ts_str\) \{ \$timestamp = \$format_last_ts_epoch; \}\nelse \{\n(.*)\n\}\z/$1/s
        or die "memo not found in the emitted text\n" if !$memo && $shape->{kind} ne 'epoch';
    push @s, $ts, 'return 1;';
    return "sub {\n" . join("\n", @s) . "\n}";
}
sub compile_block { my ($src) = @_; my $b = eval $src; die "block codegen: $@\n$src\n" if $@ || ref $b ne 'CODE'; return $b; }

# --- validation on the file's sampled rows (§ 5.6, proposed) ------------------
# Each sampled data row: the block's extracted values equal the header's
# column map's, and an ISO row of the file's kind gives a real date under
# the block's order. Runs under the snapshot and restore of a mid-run compile.
sub validate_block {
    my ($block, $sample_rows) = @_;
    my @saved = ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message,
                  $bytes, $duration, $status_code, $metrics_observed, $timestamp, $fractional_ms, $fraction_digits,
                  $line_outcome, $line_cls_sig, $format_last_ts_str, $format_last_ts_epoch );
    my $saved_cache = timestamp_date_cache_snapshot();
    my ($ok, $why) = (1, '');
    for my $row (@$sample_rows) {
        my $placed = eval { $block->($row) };
        if (!defined $placed) { ($ok, $why) = (0, 'date'); last; }
        next unless $placed;
        my @f = split(/\Q$csv_separator\E/, $row, -1);
        for my $i (0 .. $#csv_udm_col_indices) {
            my $c = $csv_udm_col_indices[$i];
            my $want = $c >= 0 && $c < @f ? ($f[$c] =~ s/^\s+|\s+$//gr) : undef;
            $want = undef if defined $want && $want eq '';
            if ((defined $want) != (defined $csv_udm_values[$i]) || (defined $want && $want ne $csv_udm_values[$i])) {
                ($ok, $why) = (0, 'wiring'); last;
            }
        }
        last unless $ok;
    }
    ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message,
      $bytes, $duration, $status_code, $metrics_observed, $timestamp, $fractional_ms, $fraction_digits,
      $line_outcome, $line_cls_sig, $format_last_ts_str, $format_last_ts_epoch ) = @saved;
    timestamp_date_cache_restore($saved_cache);
    return ($ok, $why);
}
sub sample_rows {
    my $sample = sample_file_for_detection($P_FILE) or die "no detection sample\n";
    return [ grep { $_ ne '' && $_ ne $HEADER } map { s/[\r\n]+$//r } @{ $sample->{lines} } ];
}
# The instantiation: generate month first, validate, on a date failure
# generate day first and validate, and fall back to month first when both
# fail (§ 5.6, proposed). Returns the block, its layout and the compile count.
sub instantiate {
    my ($shape, $rows, %o) = @_;
    my $compiles = 0;
    if ($shape->{kind} eq 'epoch') {   # no date order to settle; the wiring is still proven
        my $e = compile_block(csv_block_src($shape, 'epoch', %o));
        my ($ok, $why) = validate_block($e, $rows);
        return ($e, 'epoch', 1, $ok ? 'epoch ok' : "$why failure");
    }
    my $b = compile_block(csv_block_src($shape, 'csv', %o)); $compiles++;
    my ($ok, $why) = validate_block($b, $rows);
    return ($b, 'csv', $compiles, "month-first ok") if $ok;
    return ($b, 'csv', $compiles, "wiring failure") if $why eq 'wiring';
    undef $b;                                                   # evicted (D11)
    my $d = compile_block(csv_block_src($shape, 'csv_ddmm', %o)); $compiles++;
    ($ok, $why) = validate_block($d, $rows);
    return ($d, 'csv_ddmm', $compiles, "day-first ok") if $ok;
    undef $d;
    $b = compile_block(csv_block_src($shape, 'csv', %o)); $compiles++;
    return ($b, 'csv', $compiles, "both failed: month first");
}

# --- state reset between passes -------------------------------------------------
sub reset_state {
    timestamp_date_cache_clear();
    ( $format_last_ts_str, $format_last_ts_epoch ) = ( '', undef );
    %udm_last_value = ();
    $csv_epoch_timestamp = 0;
    $fraction_digits = '';
    die "header not CSV\n" unless detect_and_parse_csv_header($HEADER);
}
reset_state();
my $KIND = $LINES[0] =~ /^\s*\d+(?:\.\d+)?\s*(?:\Q$csv_separator\E|$)/ ? 'epoch' : 'iso';
{   # the first data row decides the kind, as the confirm arm does
    my $first = (split(/\Q$csv_separator\E/, $LINES[0], -1))[$csv_timestamp_col] // '';
    $first =~ s/^\s+|\s+$//g;
    $KIND = $first =~ /^\d+(\.\d+)?$/ ? 'epoch' : 'iso';
}

sub run_arm {    # one pass; returns (seconds, results, died-at)
    my ($loop, $record, $reps) = @_;
    my @out;
    my $t0 = [gettimeofday];
    my $ok = eval { for (1 .. ($reps // 1)) { reset_state() if $_ > 1; $loop->(\@LINES, \@out, $record); } 1 };
    my $dt = tv_interval($t0);
    my $died = $ok ? '' : ($@ =~ s/\s+\z//r);
    return ($dt, \@out, $died);
}

# --- hand-derived values from the fixture text ------------------------------
sub days_from_civil { my ($y, $m, $d) = @_; $y -= $m <= 2 ? 1 : 0; my $era = int(($y >= 0 ? $y : $y - 399) / 400);
    my $yoe = $y - $era * 400; my $doy = int((153 * ($m + ($m > 2 ? -3 : 9)) + 2) / 5) + $d - 1;
    my $doe = $yoe * 365 + int($yoe/4) - int($yoe/100) + $doy; return $era * 146097 + $doe - 719468; }
sub hand_value {   # (epoch seconds, fractional ms, digits) from the timestamp text alone
    my ($text, $dayfirst) = @_;
    my ($cap, $ns) = ($timestamp_capture_fraction, $timestamp_capture_ns);
    if ($text =~ /^(\d+)(?:\.(\d+))?$/ && defined $duration_unit_override) {
        # -du: the value in that unit, to seconds; no text digits to keep
        my %per_second = ( s => 1, ms => 1e3, us => 1e6, ns => 1e9 );
        my $v = $text / $per_second{$duration_unit_override}; my $int = int($v); my $f = $v - $int;
        return ($int, $cap && $f > 0 ? $f * 1000 : 0, '');
    }
    if ($text =~ /^(\d+)(?:\.(\d+))?$/) {
        my ($int, $dig) = ($1, $2 // '');
        return ($int + 0, 0, '') unless $cap;
        if ($ns) { my $d9 = substr($dig, 0, 9); return ($int + 0, $d9 eq '' ? 0 : $d9 / 10**(length($d9) - 3), $d9); }
        my $v = $text + 0; my $f = $v - int($v); return ($int + 0, $f > 0 ? $f * 1000 : 0, '');
    }
    my ($y, $a, $b, $h, $mi, $s, $dig) = $text =~ /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})(?:[.,](\d+))?/ or return;
    my ($mo, $d) = $dayfirst ? ($b, $a) : ($a, $b);
    my $epoch = days_from_civil($y, $mo, $d) * 86400 + $h * 3600 + $mi * 60 + $s;
    $dig //= '';
    my $d9 = substr($dig, 0, 9);
    return ($epoch, 0, '') unless $cap;
    return ($epoch, $d9 eq '' ? 0 : $d9 / 10**(length($d9) - 3), $ns ? $d9 : '');
}

# ===========================================================================
if ($P_MODE eq 'src') {
    my $shape = header_shape($KIND);
    print csv_block_src($shape, $KIND eq 'epoch' ? 'epoch' : 'csv'), "\n";
    exit 0;
}

if ($P_MODE eq 'parity') {
    my $shape = header_shape($KIND);
    my $rows = sample_rows();
    my ($block, $layout, $compiles, $how) = instantiate($shape, $rows);
    p_note("kind=$KIND layout=$layout compiles=$compiles validation: $how; sampled rows=" . scalar(@$rows));
    my %r;
    for my $arm (qw(A B Bnm)) {
        reset_state();
        my $blk = $arm eq 'A' ? undef : $arm eq 'B' ? $block : compile_block(csv_block_src($shape, $layout, memo => 0));
        my ($loop) = build_loop($arm eq 'A' ? 'A' : 'B', 1, $blk);
        my ($dt, $out, $died) = run_arm($loop, 1);
        $r{$arm} = { out => $out, died => $died };
    }
    my $dayfirst = $layout eq 'csv_ddmm';
    my @keys = ('rows', 'A=B', 'A=B ex-frac', 'B=Bnm', 'unmatched_A', 'unmatched_B', map { ("$_ placed", "$_ ts=hand", "$_ frac=hand", "$_ digits=hand") } qw(A B));
    my %cnt = map { $_ => 0 } @keys;
    my @first_diff;
    for my $i (0 .. $ROWS - 1) {
        my ($ra, $rb, $rn) = map { $r{$_}{out}[$i] } qw(A B Bnm);
        last unless defined $ra || defined $rb;
        $cnt{rows}++;
        $cnt{'A=B'}++   if defined $ra && defined $rb && $ra eq $rb;
        # the same, with the fraction and its digits left out: what a closed
        # read gate no longer reads
        $cnt{'A=B ex-frac'}++ if defined $ra && defined $rb && (join '|', map { $_ // '' } (split /\|/, $ra, -1)[0, 3 .. 6]) eq (join '|', map { $_ // '' } (split /\|/, $rb, -1)[0, 3 .. 6]);
        $cnt{'B=Bnm'}++ if defined $rb && defined $rn && $rb eq $rn;
        push @first_diff, "row " . ($i + 2) . ":\n  A=" . ($ra // 'none') . "\n  B=" . ($rb // 'none') if (($ra // '') ne ($rb // '')) && @first_diff < 3;
        # per field, against the values derived by hand from the text
        my $text = (split(/\Q$csv_separator\E/, $LINES[$i], -1))[$csv_timestamp_col] // '';
        $text =~ s/^\s+|\s+$//g;
        my @h = hand_value($text, $dayfirst);
        for my $arm (qw(A B)) {
            my $o = $r{$arm}{out}[$i] // next;
            next if $o eq 'UNMATCHED';
            my ($ts, $fms, $fd) = split /\|/, $o, -1;
            next unless @h;
            $cnt{"$arm ts=hand"}++  if $ts == $h[0];
            $cnt{"$arm frac=hand"}++ if abs($fms - $h[1]) < 1e-6;
            $cnt{"$arm digits=hand"}++ if $timestamp_capture_ns && $fd eq $h[2];
            $cnt{"$arm placed"}++;
        }
        $cnt{unmatched_A}++ if ($ra // '') eq 'UNMATCHED';
        $cnt{unmatched_B}++ if ($rb // '') eq 'UNMATCHED';
    }
    p_row('fixture', 'options', 'kind', 'layout', 'compiles', 'validation', 'gate', @keys, 'died_A', 'died_B') if $ENV{PROTO_HEADER};
    p_row($P_FILE =~ s{.*/}{}r, join(' ', grep { $_ ne '-ni' && $_ ne '--disable-progress' && $_ ne $P_FILE } @main::PROTO_LTL_ARGS),
          $KIND, $layout, $compiles, $how, "cap=$timestamp_capture_fraction ns=$timestamp_capture_ns tp=$timestamp_precision",
          (map { $cnt{$_} } @keys), $r{A}{died} || '-', $r{B}{died} || '-');
    print STDERR "$_\n" for @first_diff;
    exit 0;
}

if ($P_MODE eq 'timing') {
    my $shape = header_shape($KIND);
    my $rows = sample_rows();
    my ($block, $layout) = instantiate($shape, $rows);
    my $nomemo = compile_block(csv_block_src($shape, $layout, memo => 0));
    my %loop = ( A => (build_loop('A', 0, undef))[0], B => (build_loop('B', 0, $block))[0], Bnm => (build_loop('B', 0, $nomemo))[0] );
    my $reps = $ROWS >= $P_MINROWS ? 1 : int($P_MINROWS / $ROWS + 0.5);
    my @arms = qw(A B Bnm);
    my %t;
    for my $round (0 .. $P_ROUNDS - 1) {
        my @order = (@arms[$round % 3 .. $#arms], @arms[0 .. $round % 3 - 1]);
        for my $arm (@order) {
            reset_state();
            my ($dt, undef, $died) = run_arm($loop{$arm}, 0, $reps);
            die "arm $arm died: $died\n" if $died;
            push @{ $t{$arm} }, $dt / ($ROWS * $reps) * 1e9;   # ns per row
        }
    }
    for my $arm (@arms) {
        my ($med, $min, $max) = p_stats(@{ $t{$arm} });
        p_row($P_FILE =~ s{.*/}{}r, scalar(@udm_configs), "cap=$timestamp_capture_fraction", $arm, $ROWS, $reps, $P_ROUNDS,
              sprintf('%.0f', $med), sprintf('%.0f', $min), sprintf('%.0f', $max));
    }
    exit 0;
}

if ($P_MODE eq 'perfile') {
    my $shape = header_shape($KIND);
    my $rows = sample_rows();
    my (@gen, @all, $how, $compiles);
    for (1 .. $P_ROUNDS) {
        my $t0 = [gettimeofday];
        my $src = csv_block_src($shape, $KIND eq 'epoch' ? 'epoch' : 'csv');
        my $b = compile_block($src);
        push @gen, tv_interval($t0) * 1e6;
        $t0 = [gettimeofday];
        (undef, undef, $compiles, $how) = instantiate($shape, $rows);
        push @all, tv_interval($t0) * 1e6;
    }
    my @g = p_stats(@gen); my @a = p_stats(@all);
    p_row($P_FILE =~ s{.*/}{}r, scalar(@udm_configs), scalar(@$rows), $how, $compiles,
          map { sprintf('%.0f', $_) } @g, @a);
    exit 0;
}
die "unknown mode $P_MODE\n";
