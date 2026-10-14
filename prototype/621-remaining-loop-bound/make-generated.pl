#!/usr/bin/env perl
# #621: probes that generate the per-line loop at run time from the loop's own
# source, to price what a generated body costs (hypothesis-generator.md beside
# the results).
#
# Each probe is the base ltl with three mechanical changes, every one asserted:
#
#   1. Marker comment lines (markers.tsv) above the loop's gates. A marker is a
#      comment, so the inline loop compiles to the same code as the base's.
#   2. The generator subs, placed before read_and_process_logs: read the
#      program's own source once, take the loop's text, resolve every marker
#      for this run, and return the text of an anonymous sub holding the loop.
#   3. The call site, in one of two placements:
#        file  compiled inside the per-file loop, closing over the file's own
#              variables as declared there (nothing moves; one compile a file)
#        run   compiled once before the per-file loop; the 13 per-file
#              variables the loop reads are declared before it and reset at
#              the start of each file (one compile a run)
#      LTL_GENERATED_LOOP=0 runs the inline loop instead (the reference).
#
# The marker operations, applied to the line below the marker:
#   when EXPR    a block whose whole condition is EXPR: true keeps the arm
#                without its test and drops the other arms; false drops the
#                arm, keeping an else arm's body or turning an elsif into the
#                if. A statement: false drops it, true keeps it.
#   and TERM     the condition is TERM && rest (or rest && TERM): false as
#                when-false; true removes the term's text from the condition
#                (kept as written when the term and its && are not on one line).
#   unless EXPR  a statement carrying `unless EXPR`: true drops the statement,
#                false removes the modifier.
#   true EXPR    when EXPR holds the block's condition is always true: unwrap.
#   false EXPR   when EXPR holds the block's condition is always false: drop.
# A dropped line becomes an empty line, so the generated text keeps the
# source's line numbers and one #line directive maps it back to the source.
#
#   usage: make-generated.pl <base ltl> <markers.tsv> <output dir>
# Writes <output dir>/ltl-gen-file, ltl-gen-run, ltl-gen-file-noline (the
# per-file probe without the #line directive) and ltl-annotated (the base
# with the markers only).
use strict;
use warnings;

my ($base, $markers, $out) = @ARGV;
die "usage: make-generated.pl <base ltl> <markers.tsv> <output dir>\n" unless defined $out;
mkdir $out unless -d $out;
open my $fh, '<', $base or die "$base: $!";
my @src = <$fh>;
close $fh;

sub find_all {
    my ($p, $re, $from, $to) = @_;
    return grep { $p->[$_] =~ $re } $from .. $to;
}
sub find_one {
    my ($p, $re, $what, $from, $to) = @_;
    my @h = find_all($p, $re, $from // 0, $to // $#$p);
    die "make-generated: expected exactly one line matching $what, found " . @h . "\n" unless @h == 1;
    return $h[0];
}
sub loop_range {
    my ($p) = @_;
    my $sub  = find_one($p, qr/^sub read_and_process_logs \{/, 'sub read_and_process_logs');
    my ($next) = grep { $p->[$_] =~ /^sub / } $sub + 1 .. $#$p;
    my $loop  = find_one($p, qr/^\s*while \(1\) \{/, 'the per-line loop', $sub, $next);
    my $close = find_one($p, qr/^\s*close \$fh;/, 'close $fh after the loop', $loop, $next);
    my $end = $close - 1;
    $end-- while $p->[$end] =~ /^\s*$/;
    die "make-generated: the line before close \$fh is not the loop's closing brace\n" unless $p->[$end] =~ /^\s*\}\s*$/;
    return ($sub, $loop, $end, $next);
}

# --- 1. the markers ---------------------------------------------------------
my @p = @src;
my ($sub_ln, $loop_ln, $loop_end) = loop_range(\@p);
my %insert;   # line index -> marker lines to insert above it
open my $mf, '<', $markers or die "$markers: $!";
my $n_markers = 0;
while (<$mf>) {
    next if /^#/ || /^\s*$/;
    chomp;
    my ($op, $want, $snip, $expr) = split /\t/, $_, 4;
    my @h = $snip =~ /^re:(.*)$/
        ? find_all(\@p, qr/$1/, $loop_ln + 1, $loop_end - 1)
        : grep { index($p[$_], $snip) >= 0 } $loop_ln + 1 .. $loop_end - 1;
    die "make-generated: expected $want line(s) for [$snip], found " . @h . "\n" unless @h == $want;
    for my $i (@h) {
        my ($ind) = $p[$i] =~ /^(\s*)/;
        push @{ $insert{$i} }, "$ind#\@$op $expr\n";
        $n_markers++;
    }
}
for my $i (sort { $b <=> $a } keys %insert) {
    die "make-generated: two markers above line " . ($i + 1) . "\n" if @{ $insert{$i} } > 1;
    splice @p, $i, 0, @{ $insert{$i} };
}
my @annotated = @p;

# --- 2. the generator -------------------------------------------------------
my $generator = <<'GENERATOR';
## GENERATED READ LOOP (prototype, #621) ##
# The per-line loop for this run, written from the loop's own source text:
# every #@ marker's expression is evaluated once and its gate resolved, and a
# dropped line is left empty so the text keeps the source's line numbers.
my ($generated_loop_code, %generated_loop_stats);
sub generated_loop_flag {
    my ($expr) = @_;
    my $v = eval "($expr) ? 1 : 0";
    die "generated read loop: marker [$expr]: $@" if $@;
    return $v;
}
sub generated_loop_strip { (my $t = $_[0]) =~ s/(?:^|(?<=\s))#.*$//; return $t }
sub generated_loop_block {    # the line the block opens on at or after $i, and the line it closes on
    my ($t, $i) = @_;
    my $o = $i;
    $o++ until $o > $#$t || generated_loop_strip($t->[$o]) =~ /\{\s*$/;
    die "generated read loop: no block opens at or after offset $i\n" if $o > $#$t;
    my $depth = 1;
    for my $j ($o + 1 .. $#$t) {
        next unless $t->[$j] =~ /[{}]/;
        my $s = generated_loop_strip($t->[$j]);
        while ($s =~ /([{}])/g) {
            if ($1 eq '{') { $depth++ }
            elsif (--$depth == 0) { return ($o, $j) }
        }
    }
    die "generated read loop: no close for the block opened at offset $o\n";
}
sub generated_loop_target {   # ('stmt', first, last) or ('block', first, [arms])
    my ($t, $j) = @_;
    my $s = generated_loop_strip($t->[$j]);
    my $opens  = () = $s =~ /\{/g;
    my $closes = () = $s =~ /\}/g;
    return ('stmt', $j, $j) if $opens == $closes && $s =~ /[;}]\s*$/;
    for my $k ($j .. $#$t) {
        my $sk = generated_loop_strip($t->[$k]);
        last if $sk =~ /\{\s*$/;
        return ('stmt', $j, $k) if $sk =~ /;\s*$/;
    }
    my ($o, $c) = generated_loop_block($t, $j);
    my @arms = ([ 'if', $j, $o, $c ]);
    while ($t->[$c] =~ /^\s*\}\s*(else|elsif)\b/) {
        my $kind = $1;
        my ($o2, $c2) = generated_loop_block($t, $c);
        push @arms, [ $kind, $c, $o2, $c2 ];
        $c = $c2;
    }
    return ('block', $j, \@arms);
}
sub generated_loop_blank { my ($t, $a, $b) = @_; $t->[$_] = "\n" for $a .. $b }
sub generated_loop_resolve {  # a block's condition is known: 1 true, 0 false
    my ($t, $arms, $truth) = @_;
    my ($first, @rest) = @$arms;
    if ($truth) {
        # The arm keeps its own scope as `if (1) {`: Perl folds the constant
        # test away, the arm's declarations stay its own, and unlike a bare
        # block it is no loop, so next and last still mean the read loop.
        my ($ind) = $t->[ $first->[1] ] =~ /^(\s*)/;
        generated_loop_blank($t, $first->[1], $first->[2] - 1) if $first->[2] > $first->[1];
        $t->[ $first->[2] ] = "${ind}if (1) {\n";
        if (@rest) {
            $t->[ $first->[3] ] = "${ind}}\n";
            generated_loop_blank($t, $first->[3] + 1, $arms->[-1][3]);
        }
    } elsif (!@rest) {
        generated_loop_blank($t, $first->[1], $first->[3]);
    } elsif ($rest[0][0] eq 'else') {
        my ($ind) = $t->[ $first->[1] ] =~ /^(\s*)/;
        generated_loop_blank($t, $first->[1], $rest[0][2] - 1);
        $t->[ $rest[0][2] ] = "${ind}if (1) {\n";
    } else {
        generated_loop_blank($t, $first->[1], $rest[0][1] - 1);
        $t->[ $rest[0][1] ] =~ s/^(\s*)\}\s*elsif\s*\(/$1if (/ or die "generated read loop: elsif arm not rewritten\n";
    }
}
sub generated_loop_text {
    my ($t) = @_;    # the loop's lines; resolved in place
    my %count;
    for my $i (0 .. $#$t) {
        next unless $t->[$i] =~ /^\s*#\@(when|and|unless|true|false)\s+(.+?)\s*$/;
        my ($op, $expr) = ($1, $2);
        $expr =~ s/\s+#\s.*$//;
        $t->[$i] = "\n";
        my $j = $i + 1;
        my ($kind, $first, $span) = generated_loop_target($t, $j);
        my $last = $kind eq 'stmt' ? $span : $span->[0][2];   # the statement, or the condition through the opening line
        my $v = generated_loop_flag($expr);
        my $res;
        if ($op eq 'when' || ($op eq 'and' && !$v)) {
            if ($kind eq 'block') { generated_loop_resolve($t, $span, $v); $res = $v ? 'unwrapped' : 'dropped' }
            elsif (!$v)           { generated_loop_blank($t, $first, $span); $res = 'dropped' }
            else                  { $res = 'kept' }
        } elsif ($op eq 'and') {
            my $done = 0;
            for my $k ($first .. $last) {
                $done = 1, last if $t->[$k] =~ s/\Q$expr\E\s*&&\s*// || $t->[$k] =~ s/\s*&&\s*\Q$expr\E//;
            }
            $res = $done ? 'term-removed' : 'kept';
        } elsif ($op eq 'unless') {
            if ($v) { generated_loop_blank($t, $first, $span); $res = 'dropped' }
            else {
                my $done = 0;
                for my $k ($first .. $span) { $done = 1, last if $t->[$k] =~ s/\s*\bunless\s+\Q$expr\E// }
                die "generated read loop: no `unless $expr` to remove\n" unless $done;
                $res = 'modifier-removed';
            }
        } elsif ($op eq 'true') {
            if ($v) { die "generated read loop: true marker above a statement\n" unless $kind eq 'block'; generated_loop_resolve($t, $span, 1); $res = 'unwrapped' }
            else    { $res = 'kept' }
        } else {   # false
            if ($v) { die "generated read loop: false marker above a statement\n" unless $kind eq 'block'; generated_loop_resolve($t, $span, 0); $res = 'dropped' }
            else    { $res = 'kept' }
        }
        $count{$res}++;
    }
    return \%count;
}
sub generated_loop_code {
    return $generated_loop_code if defined $generated_loop_code;
    my $t0 = [gettimeofday];
    my $file = __FILE__;
    # In a PAR-packed binary __FILE__ names the archive member (script/ltl),
    # which is not on disk; PAR runs the script from an extracted copy named
    # in PAR_0, two lines longer at the top (`package main;` and a #line
    # directive), as PAR.pm _run_member writes it; verified in the packed binaries (#720).
    my ($read_from, $line_offset) = ($file, 0);
    if (!-e $file && defined $ENV{PAR_0} && -e $ENV{PAR_0}) { ($read_from, $line_offset) = ($ENV{PAR_0}, 2) }
    # The source is streamed and only the reading sub's lines are kept, from
    # its per-line loop to the next sub: the whole file is never held.
    open my $sfh, '<', $read_from or die "generated read loop: cannot read the source $read_from: $!";
    my ($in_sub, $line, @s) = (0, undef);
    while (my $l = <$sfh>) {
        if (!$in_sub) { $in_sub = 1 if $l =~ /^sub read_and_process_logs \{/; next }
        last if $l =~ /^sub /;
        if (!defined $line) {
            next unless $l =~ /^\s*while \(1\) \{/;
            $line = $. - $line_offset;
        }
        push @s, $l;
    }
    close $sfh;
    die "generated read loop: no per-line loop found in the source\n" unless defined $line;
    my (undef, $end) = generated_loop_block(\@s, 0);
    my @t = @s[ 0 .. $end ];
    @s = ();
    my $count = generated_loop_text(\@t);
    $generated_loop_code = "sub {\n"
        . (GENERATED_LOOP_LINE_DIRECTIVE ? "#line $line \"$file\"\n" : "")
        . join('', @t) . "}\n";
    $generated_loop_stats{text_s} = tv_interval($t0);
    $generated_loop_stats{"marker_$_"} = $count->{$_} for keys %$count;
    $generated_loop_stats{text_lines} = grep { /\S/ } @t;
    return $generated_loop_code;
}
END {
    if ($ENV{LTL_GEN_TIMING} && %generated_loop_stats) {
        printf STDERR "GENERATED\t%s\t%s\n", $_, $generated_loop_stats{$_} for sort keys %generated_loop_stats;
    }
    if ($ENV{LTL_GEN_DUMP} && defined $generated_loop_code) {
        open my $d, '>', $ENV{LTL_GEN_DUMP} or die "$ENV{LTL_GEN_DUMP}: $!";
        print {$d} $generated_loop_code;
        close $d;
    }
}

GENERATOR

sub with_generator {
    my ($p, $line_directive) = @_;
    my ($s) = loop_range($p);
    my @q = @$p;
    my $const = "use constant GENERATED_LOOP_LINE_DIRECTIVE => $line_directive;\n";
    splice @q, $s, 0, $const, $generator;
    return @q;
}

# The compile at the call site, string eval in the enclosing scope so the sub
# closes over the variables visible there.
my $compile = q{(LTL_GENERATED_LOOP_ON ? do { my $c = generated_loop_code(); my $t0 = [gettimeofday]; my $g = eval $c; die "generated read loop: $@" unless $g; $generated_loop_stats{compile_s} += tv_interval($t0); $generated_loop_stats{compiles}++; $g } : undef)};

sub wrap_inline {   # if ($generated_loop) { call } else { the inline loop }
    my ($q) = @_;
    my (undef, $loop, $end) = loop_range($q);
    my ($ind) = $q->[$loop] =~ /^(\s*)/;
    splice @$q, $end + 1, 0, "$ind}\n";
    splice @$q, $loop, 0, "${ind}if (\$generated_loop) { \$generated_loop->() } else {\n";
}

# --- 3a. per file -----------------------------------------------------------
sub write_probe {
    my ($name, $lines) = @_;
    my $path = "$out/ltl-$name";
    open my $o, '>', $path or die "$path: $!";
    print {$o} @$lines;
    close $o;
    chmod 0755, $path;
    print "wrote $path\n";
}
my $on = "use constant LTL_GENERATED_LOOP_ON => (\$ENV{LTL_GENERATED_LOOP} // 1) ? 1 : 0;\n";
for my $variant ([ 'gen-file', 1 ], [ 'gen-file-noline', 0 ]) {
    my @q = with_generator(\@annotated, $variant->[1]);
    my (undef, $loop) = loop_range(\@q);
    wrap_inline(\@q);
    my ($ind) = $q[$loop] =~ /^(\s*)/;
    splice @q, $loop, 0, "${ind}my \$generated_loop = $compile;\n";
    my ($s) = loop_range(\@q);
    splice @q, $s, 0, $on;
    write_probe($variant->[0], \@q);
}

# --- 3b. per run: the per-file variables declared before the per-file loop --
{
    my @q = with_generator(\@annotated, 1);
    my ($s, $loop) = loop_range(\@q);
    my $fe = find_one(\@q, qr/^\s*foreach my \$in_file \(\@in_files\) \{/, 'the per-file loop', $s, $loop);
    my @rewrites = (
        [ qr/^(\s*)foreach my \$in_file \(\@in_files\) \{/, sub { "$1foreach my \$in_file_each (\@in_files) {\n$1    \$in_file = \$in_file_each;" } ],
        [ qr/^(\s*)open my \$fh, /,                         sub { "$1open \$fh, " } ],
        [ qr/^(\s*)my \$line_number = 0;/,                  sub { "$1\$line_number = 0;" } ],
        [ qr/^(\s*)my \$progress_file_size = /,             sub { "$1\$progress_file_size = " } ],
        [ qr/^(\s*)my \$file_index = /,                     sub { "$1\$file_index = " } ],
        [ qr/^(\s*)my \$potential_csv_header;/,             sub { "$1undef \$potential_csv_header;" } ],
        [ qr/^(\s*)my \$csv_sample_lines;/,                 sub { "$1undef \$csv_sample_lines;" } ],
        [ qr/^(\s*)my \( \$file_scan_attempts, \$file_scan_failed \) = /, sub { "$1( \$file_scan_attempts, \$file_scan_failed ) = " } ],
        [ qr/^(\s*)my \( \$file_cls_sig, \$file_cls_entry \) = /,         sub { "$1( \$file_cls_sig, \$file_cls_entry ) = " } ],
        [ qr/^(\s*)my \@window_held;/,                      sub { "$1\@window_held = ();" } ],
        [ qr/^(\s*)my \$window_replay_started = 0;/,        sub { "$1\$window_replay_started = 0;" } ],
    );
    for my $rw (@rewrites) {
        my $i = find_one(\@q, $rw->[0], "a per-file declaration ($rw->[0])", $fe, $loop);
        $q[$i] =~ s/$rw->[0]/$rw->[1]->()/e or die "make-generated: rewrite failed\n";
    }
    my ($ind) = $q[$fe] =~ /^(\s*)/;
    splice @q, $fe, 0,
        "${ind}# The per-file variables the generated loop closes over, declared once (#621 prototype).\n",
        "${ind}my ( \$in_file, \$fh, \$line_number, \$progress_file_size, \$file_index, \$potential_csv_header, \$csv_sample_lines,\n",
        "${ind}     \$file_scan_attempts, \$file_scan_failed, \$file_cls_sig, \$file_cls_entry, \@window_held, \$window_replay_started );\n",
        "${ind}my \$generated_loop = $compile;\n";
    wrap_inline(\@q);
    ($s) = loop_range(\@q);
    splice @q, $s, 0, $on;
    write_probe('gen-run', \@q);
}
write_probe('annotated', \@annotated);
printf "markers placed: %d\n", $n_markers;
