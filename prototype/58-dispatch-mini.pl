#!/usr/bin/env perl
#
# 58-dispatch-mini.pl — extraction-dispatch candidate comparison (#58 axis 3/F8-4).
#
# Measures the per-line cost of *extraction dispatch* in isolation: every
# candidate tests only the winning format's pattern (steady-state MTF,
# entry at position 0) over lines pre-loaded in memory, so scan order and
# file I/O are excluded. Candidates:
#
#   inline           today's cascade branch code, verbatim (baseline)
#   closure-list     per-format closure compiled at load from a declarative
#                    spec (string-eval codegen from transform primitives),
#                    returning a fixed-order list into caller scalars
#   closure-hashref  the same generated closure returning a hashref record
#                    (quantifies the A5 record-shape risk)
#   capture-map      generic interpreter: field-map + transform list walked
#                    per line (the expected-loser honesty baseline)
#
# Formats covered: mt1 (ThingWorx standard: 9 captures + in-branch metric
# probes/masking) and mt3 (Tomcat access with %D: transform-heavy). The
# global count probe, threadpool derivation, and the bytes/junk-duration
# guards run identically in every candidate (common-mode post-steps).
#
# Parity: --verify compares every candidate's canonical record against
# inline on every line and dies on first divergence. Verification runs
# implicitly before timing on each fixture.
#
# Usage:
#   perl prototype/58-dispatch-mini.pl [--runs N] [--verify-only] <fixture> [...]
#
# Fixture -> format mapping is by filename (pure-access* -> mt3,
# *scriptlog* -> mt1). TSV on stdout (58-measure.pm shape); summary on stderr.

use strict;
use warnings;
use FindBin;
require "$FindBin::Bin/58-measure.pm";

my $runs = 5;
my $verify_only = 0;
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if    ($opt eq '--runs')        { $runs = shift @ARGV; }
    elsif ($opt eq '--verify-only') { $verify_only = 1; }
    else  { die "unknown option $opt\n"; }
}
die "usage: $0 [--runs N] [--verify-only] <fixture> [...]\n" unless @ARGV;

## Measured configuration (mirrors ltl GLOBALS defaults, as in the baseline)
my $include_query_string = 0;
my $include_session      = 0;
my $omit_count           = 0;

## Canonical record field order — the fixed-order list contract shared by
## every candidate; verification compares exactly these fields.
my @REC_FIELDS = qw(timestamp_str category_bucket object instance user session
                    platform thread message bytes duration status_code);

## ---------------------------------------------------------------------------
## Format specs — the registry-entry shape this mini-proto models: compiled
## pattern, capture->field map, and a list of named transform primitives.
## ---------------------------------------------------------------------------

my %SPECS = (
    mt1 => {
        name    => 'thingworx_standard',
        pattern => qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/,
        # capture ordinal (1-based) -> record field
        field_map => [ [1,'timestamp_str'], [2,'category_bucket'], [3,'object'], [4,'instance'],
                       [5,'user'], [6,'session'], [7,'platform'], [8,'thread'], [9,'message'] ],
        transforms => [ 'probe_mask_metrics' ],
    },
    mt3 => {
        name    => 'tomcat_access_with_duration',
        pattern => qr/^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/,
        field_map => [ [2,'timestamp_str'], [3,'message'], [4,'category_bucket'],
                       [5,'bytes'], [6,'duration'], [7,'thread'], [8,'session'] ],
        transforms => [ 'status_bucket', 'chop_tz', 'undef_bytes_dash',
                        'chop_http_proto', 'strip_query', 'session_prefix' ],
    },
);

## Transform primitives as code snippets (for codegen) and as generic subs
## over a record hash (for the interpreter). Both express the same operation;
## the codegen splices the snippet into the generated closure at load time,
## the interpreter dispatches per line.

my %XFORM_CODE = (    # operate on closure lexicals
    probe_mask_metrics => q{
        ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
        ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
        if (defined $bytes || defined $duration) {
            $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
        }
    },
    status_bucket    => q{ $status_code = $category_bucket; $category_bucket =~ s/(\d)\d{2}/$1xx/; },
    chop_tz          => q{ $timestamp_str =~ s/ \+\d{4}$//; },
    undef_bytes_dash => q{ undef $bytes if $bytes eq "-"; },
    chop_http_proto  => q{ $message =~ s/ HTTP\/\d\.\d$//; },
    strip_query      => q{ $message =~ s/\?.+$//; },      # include_query_string=0 baked at load
    session_prefix   => q{ },                             # include_session=0 baked at load: no-op
);

my %XFORM_SUB = (     # operate on a record hashref (interpreter path)
    probe_mask_metrics => sub {
        my ($r) = @_;
        ( $r->{bytes} ) = $r->{message} =~ / bytes\s*=\s*(\d+)/;
        ( $r->{duration} ) = $r->{message} =~ / durationM[sS]\s*=\s*(\d+)/;
        if (defined $r->{bytes} || defined $r->{duration}) {
            $r->{message} =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
        }
    },
    status_bucket    => sub { my ($r) = @_; $r->{status_code} = $r->{category_bucket}; $r->{category_bucket} =~ s/(\d)\d{2}/$1xx/; },
    chop_tz          => sub { my ($r) = @_; $r->{timestamp_str} =~ s/ \+\d{4}$//; },
    undef_bytes_dash => sub { my ($r) = @_; undef $r->{bytes} if $r->{bytes} eq "-"; },
    chop_http_proto  => sub { my ($r) = @_; $r->{message} =~ s/ HTTP\/\d\.\d$//; },
    strip_query      => sub { my ($r) = @_; $r->{message} =~ s/\?.+$//; },
    session_prefix   => sub { },
);

## ---------------------------------------------------------------------------
## Codegen: compile a spec into a closure at load time (candidate 2/3).
## ---------------------------------------------------------------------------

sub compile_closure {
    my ($spec, $shape) = @_;    # shape: 'list' | 'hashref'
    my $pattern = $spec->{pattern};

    # capture-assignment target list with undef for discarded ordinals
    my $max_ord = 0;
    $max_ord = $_->[0] > $max_ord ? $_->[0] : $max_ord for @{$spec->{field_map}};
    my %ord_to_field = map { $_->[0] => $_->[1] } @{$spec->{field_map}};
    my $targets = join(', ', map { defined $ord_to_field{$_} ? "\$$ord_to_field{$_}" : 'undef' } 1 .. $max_ord);

    my $decls = 'my (' . join(', ', map { "\$$_" } @REC_FIELDS) . ');';
    my $xform_code = join("\n", map { $XFORM_CODE{$_} // die "unknown transform $_" } @{$spec->{transforms}});

    my $return = $shape eq 'list'
        ? 'return (' . join(', ', map { "\$$_" } @REC_FIELDS) . ');'
        : 'return { ' . join(', ', map { "$_ => \$$_" } @REC_FIELDS) . ' };';

    my $src = qq{
        sub {
            $decls
            ( $targets ) = \$_[0] =~ \$pattern or return;
            $xform_code
            $return
        }
    };
    my $closure = eval $src;
    die "codegen failed for $spec->{name}/$shape: $@\nSOURCE:\n$src" if $@ || !$closure;
    return $closure;
}

## ---------------------------------------------------------------------------
## Interpreter: generic capture-map + transform walk (candidate 4).
## ---------------------------------------------------------------------------

sub interp_extract {
    my ($spec, $line) = @_;
    my @c = $line =~ $spec->{pattern} or return;
    my %rec = map { $_ => undef } @REC_FIELDS;
    for my $fm (@{$spec->{field_map}}) {
        $rec{$fm->[1]} = $c[$fm->[0] - 1];
    }
    for my $t (@{$spec->{transforms}}) {
        $XFORM_SUB{$t}->(\%rec);
    }
    return \%rec;
}

## ---------------------------------------------------------------------------
## Inline branch code, verbatim from the cascade (candidate 1 / parity oracle).
## Returns the canonical record as a list, or empty on no match.
## ---------------------------------------------------------------------------

sub inline_mt1 {
    my ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message, $bytes, $duration, $status_code );
    if ( ($timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message ) = $_[0] =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/) {
        ( $bytes ) = $message =~ / bytes\s*=\s*(\d+)/;
        ( $duration ) = $message =~ / durationM[sS]\s*=\s*(\d+)/;
        if (defined $bytes || defined $duration) {
            $message =~ s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g;
        }
        return ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message, $bytes, $duration, $status_code );
    }
    return;
}

sub inline_mt3 {
    my ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message, $bytes, $duration, $status_code );
    if ( (undef, $timestamp_str, $message, $category_bucket, $bytes, $duration, $thread, $session) = $_[0] =~ /^([^ ]+ ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)[ ]?([0-9.]+)?[ ]?(\S+)?[ ]?(\S+)?/ ) {
        $status_code = $category_bucket;
        $category_bucket =~ s/(\d)\d{2}/$1xx/;
        $timestamp_str =~ s/ \+\d{4}$//;
        undef $bytes if $bytes eq "-";

        $message =~ s/ HTTP\/\d\.\d$//;
        $message =~ s/\?.+$// unless $include_query_string;
        $message = "[$session] $message" if defined $session && $include_session;
        return ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message, $bytes, $duration, $status_code );
    }
    return;
}

my %INLINE = ( mt1 => \&inline_mt1, mt3 => \&inline_mt3 );

## ---------------------------------------------------------------------------
## Common-mode post-steps: count probe, threadpool, guards, accumulators.
## Two variants of the same steps, one over scalars, one over a record hash,
## so each candidate pays realistic downstream-access cost for its shape.
## ---------------------------------------------------------------------------

sub post_scalars {   # (\%acc, $message, $thread, $bytes, $duration) -> masked message
    my ($acc, $message, $thread, $bytes, $duration) = @_;
    my $count;
    if( !$omit_count && defined $message ) {
        ( $count ) = $message =~ / count\s*=\s*(\d+)/;
        if( defined $count ) {
            $message =~ s/ count\s*=\s*\d+/ count=?/g;
        }
    }
    my ($threadpool, $threadname);
    if( defined $thread && $thread ne "" ) {
        ( $threadpool ) = $thread =~ /(.*)-\d+$/;
        $threadname = defined $threadpool ? $threadpool : $thread;
    }
    $bytes = 0 if( defined( $bytes ) && $bytes < 0 );
    $duration = undef if defined $duration && $duration !~ /^[0-9]+(?:\.[0-9]+)?$/;

    $acc->{matched}++;
    $acc->{duration_sum} += $duration if defined $duration;
    $acc->{bytes_sum}    += $bytes    if defined $bytes;
    $acc->{count_sum}    += $count    if defined $count;
    return $message;
}

sub post_hashref {   # (\%acc, $rec) — same steps via hash fields
    my ($acc, $rec) = @_;
    my $count;
    if( !$omit_count && defined $rec->{message} ) {
        ( $count ) = $rec->{message} =~ / count\s*=\s*(\d+)/;
        if( defined $count ) {
            $rec->{message} =~ s/ count\s*=\s*\d+/ count=?/g;
        }
    }
    my ($threadpool, $threadname);
    if( defined $rec->{thread} && $rec->{thread} ne "" ) {
        ( $threadpool ) = $rec->{thread} =~ /(.*)-\d+$/;
        $threadname = defined $threadpool ? $threadpool : $rec->{thread};
    }
    $rec->{bytes} = 0 if( defined( $rec->{bytes} ) && $rec->{bytes} < 0 );
    $rec->{duration} = undef if defined $rec->{duration} && $rec->{duration} !~ /^[0-9]+(?:\.[0-9]+)?$/;

    $acc->{matched}++;
    $acc->{duration_sum} += $rec->{duration} if defined $rec->{duration};
    $acc->{bytes_sum}    += $rec->{bytes}    if defined $rec->{bytes};
    $acc->{count_sum}    += $count           if defined $count;
    return;
}

## ---------------------------------------------------------------------------
## Per-candidate full-file passes (the timed unit; lines pre-loaded).
## ---------------------------------------------------------------------------

sub run_inline {
    my ($lines, $fmt) = @_;
    my $inline = $INLINE{$fmt};
    my %acc = ( matched => 0, unmatched => 0, duration_sum => 0, bytes_sum => 0, count_sum => 0 );
    for my $line (@$lines) {
        my ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message, $bytes, $duration, $status_code ) = $inline->($line);
        if (defined $timestamp_str) {
            post_scalars(\%acc, $message, $thread, $bytes, $duration);
        } else {
            $acc{unmatched}++;
        }
    }
    return \%acc;
}

sub run_closure_list {
    my ($lines, $closure) = @_;
    my %acc = ( matched => 0, unmatched => 0, duration_sum => 0, bytes_sum => 0, count_sum => 0 );
    for my $line (@$lines) {
        my ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message, $bytes, $duration, $status_code ) = $closure->($line);
        if (defined $timestamp_str) {
            post_scalars(\%acc, $message, $thread, $bytes, $duration);
        } else {
            $acc{unmatched}++;
        }
    }
    return \%acc;
}

sub run_closure_hashref {
    my ($lines, $closure) = @_;
    my %acc = ( matched => 0, unmatched => 0, duration_sum => 0, bytes_sum => 0, count_sum => 0 );
    for my $line (@$lines) {
        my $rec = $closure->($line);
        if ($rec) {
            post_hashref(\%acc, $rec);
        } else {
            $acc{unmatched}++;
        }
    }
    return \%acc;
}

sub run_capture_map {
    my ($lines, $spec) = @_;
    my %acc = ( matched => 0, unmatched => 0, duration_sum => 0, bytes_sum => 0, count_sum => 0 );
    for my $line (@$lines) {
        my $rec = interp_extract($spec, $line);
        if ($rec) {
            post_hashref(\%acc, $rec);
        } else {
            $acc{unmatched}++;
        }
    }
    return \%acc;
}

## ---------------------------------------------------------------------------
## Parity verification: canonical record equality vs inline, line by line.
## ---------------------------------------------------------------------------

sub rec_str {
    my (@vals) = @_;
    return join("\x01", map { defined $_ ? $_ : "\x00undef" } @vals);
}

sub verify_fixture {
    my ($lines, $fmt, $spec, $cl_list, $cl_href) = @_;
    my $inline = $INLINE{$fmt};
    my $n = 0;
    for my $line (@$lines) {
        $n++;
        my @i  = $inline->($line);
        my @cl = $cl_list->($line);
        my $ch = $cl_href->($line);
        my $im = interp_extract($spec, $line);

        my $is = rec_str(@i);
        for my $cand (['closure-list',    rec_str(@cl)],
                      ['closure-hashref', $ch ? rec_str(map { $ch->{$_} } @REC_FIELDS) : rec_str()],
                      ['capture-map',     $im ? rec_str(map { $im->{$_} } @REC_FIELDS) : rec_str()]) {
            if ($cand->[1] ne $is) {
                die sprintf("PARITY FAILURE %s line %d (%s):\n  inline: %s\n  %s: %s\n",
                    $fmt, $n, $cand->[0], $is =~ s/\x01/ | /gr, $cand->[0], $cand->[1] =~ s/\x01/ | /gr);
            }
        }
    }
    return $n;
}

## ---------------------------------------------------------------------------
## Driver
## ---------------------------------------------------------------------------

Measure58::tsv_header(\*STDOUT) unless $verify_only;

foreach my $file (@ARGV) {
    (my $fixture = $file) =~ s{.*/}{};
    my $fmt = $fixture =~ /access/ ? 'mt3' : $fixture =~ /scriptlog/ ? 'mt1'
        : die "cannot map fixture '$fixture' to a format (expect *access* or *scriptlog*)\n";
    my $spec = $SPECS{$fmt};

    open my $fh, '<', $file or die "Cannot open file: $file";
    my @lines;
    while (<$fh>) { s/[\r\n]+$//; push @lines, $_; }
    close $fh;

    my $cl_list = compile_closure($spec, 'list');
    my $cl_href = compile_closure($spec, 'hashref');

    my $n = verify_fixture(\@lines, $fmt, $spec, $cl_list, $cl_href);
    printf STDERR "%s: parity OK (%s, %d lines, all candidates byte-identical to inline)\n", $fixture, $fmt, $n;
    next if $verify_only;

    my @cands = (
        [ 'dispatch-inline',          sub { run_inline(\@lines, $fmt) } ],
        [ 'dispatch-closure-list',    sub { run_closure_list(\@lines, $cl_list) } ],
        [ 'dispatch-closure-hashref', sub { run_closure_hashref(\@lines, $cl_href) } ],
        [ 'dispatch-capture-map',     sub { run_capture_map(\@lines, $spec) } ],
    );

    for my $cand (@cands) {
        my ($name, $runner) = @$cand;
        my $acc;
        my @secs = Measure58::time_runs($runs, sub { $acc = $runner->() });
        my ($med, $min, $max) = Measure58::median_min_max(@secs);
        Measure58::emit_tsv(\*STDOUT, $name, $fixture, scalar @lines, 'ns_per_line',
            map { $_ / @lines * 1e9 } $med, $min, $max);
        printf STDERR "  %-26s matched=%d unmatched=%d dur_sum=%s bytes_sum=%s count_sum=%s\n",
            $name, $acc->{matched}, $acc->{unmatched}, $acc->{duration_sum}, $acc->{bytes_sum}, $acc->{count_sum};
    }
}
