#
# 453-classify-mini.pl — success/failure classification mechanism probe
# (#453 D21). This file is NOT run on its own: 453-run.sh concatenates the
# production slice (453-extract-slice.sh) in front of it so the generated
# source eval'd here writes the same file-scoped record lexicals `ltl`'s
# generated scan blocks write.
#
# Baseline arm per family: a one-entry scan sub in the production shape —
# whitespace dispatch, guard, literal-pattern condition, the entry's
# extraction body from format_entry_block_src() verbatim, entry-ref return.
# Candidate arms splice a classification snippet into that body after the
# transforms and before the timestamp memo (D16), setting $line_outcome
# (2 failure, 1 success, 0 unclassified). Every candidate is verified
# byte-identical in outcome to the interpreted reference evaluator on
# every line before it is timed.
#
# Usage (via 453-run.sh):
#   perl /tmp/453-proto.pl [--runs N] [--verify-only] [--budget US] [--arms a,b,c] <family> <fixture> [...]
#   family: access | scriptlog | gc  (--arms runs the baseline plus the named arms only)
# Results and the per-line verification log: prototype/453-results/.

use strict;
use warnings;
use Time::Local qw(timegm);
use Time::HiRes qw(gettimeofday tv_interval);

sub format_probe_signal { return 0 }   # cold-closure form: ENTRY_PLACEHOLDER => undef, signals inert

my $runs = 5;
my $verify_only = 0;
my %only_arms;   # --arms a,b,c: run baseline plus the named arms only
my $budget_us;   # per-line parse/read_files cost of the mapped benchmark case (from the before-baseline)
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $opt = shift @ARGV;
    if    ($opt eq '--runs')        { $runs = shift @ARGV; }
    elsif ($opt eq '--verify-only') { $verify_only = 1; }
    elsif ($opt eq '--budget')      { $budget_us = shift @ARGV; }
    elsif ($opt eq '--arms')        { %only_arms = map { $_ => 1 } split /,/, shift @ARGV; }
    else  { die "unknown option $opt\n"; }
}
my $family = shift @ARGV or die "usage: [--runs N] [--verify-only] [--budget US] <family> <fixture> [...]\n";
die "usage: ... <family> <fixture> [...]\n" unless @ARGV;

my %spec_by_name = map { $_->{name} => $_ } format_registry_specs();
my $opts = { include_query_string => 0, include_session => 0 };   # build_format_registry() default-configuration compile

# ---------------------------------------------------------------------------
# Per-line classification state shared by every arm (production: one lexical
# in read_and_process_logs()'s scope, written by the generated block).
my $line_outcome = 0;
# The entry the scan returned for this line, and the file's last classifying entry (D19 compare).
my ($line_entry, $file_cls_entry);
my ($line_cls_id, $file_cls_id) = (0, 0);   # D19 compare variants: integer id set by the block
use constant PROTO_FR_ID => 99;
# Build-time tables candidates may reference (production: populated by
# build_format_registry() from the resolved classification).
my %cls_fail_set;      # class 1 hash-set: literal => 1
my %cls_bucket_map;    # class 2 bucket-map: category_bucket => outcome
my $cls_closure;       # class 5: FR_CLASSIFY-style closure reading the lexicals
my @cls_interp;        # interpreted walk: [ [outcome, [ [field_ref, qr], ... ]], ... ] failure first
# Counting stores (class 6)
my (%bucket_outcomes, %bucket_failures, %bucket_successes, %bucket_outcomes_a, %msg_outcomes);
my ($total_failures, $total_successes) = (0, 0);
my $bucket;

my %field_ref = (
    status_code     => \$status_code,
    category_bucket => \$category_bucket,
    message         => \$message,
    thread          => \$thread,
    object          => \$object,
);

# ---------------------------------------------------------------------------
# Reference evaluator: interpreted walk of the resolved classification
# (hash of outcome => list of { field => pattern }), failure first (D4).
sub compile_reference {
    my ($cls) = @_;
    my @walk;
    for my $pair ([2, 'failure'], [1, 'success']) {
        my ($outcome, $key) = @$pair;
        for my $crit (@{ $cls->{$key} // [] }) {
            my @conds = map { [ $field_ref{$_} // die("no field $_"), qr/$crit->{$_}/ ] } sort keys %$crit;
            push @walk, [ $outcome, \@conds ];
        }
    }
    return \@walk;
}
sub reference_outcome {
    my ($walk) = @_;
    CRIT: for my $c (@$walk) {
        for my $cond (@{ $c->[1] }) {
            my $v = ${ $cond->[0] };
            next CRIT unless defined $v && $v =~ $cond->[1];
        }
        return $c->[0];
    }
    return 0;
}

# ---------------------------------------------------------------------------
# One-entry scan sub in the production shape (compile_format_scan_sub(),
# one block, position optimal so the return is the plain entry-ref return).
sub build_block_sub {
    my ($spec, $classify_src, $label) = @_;
    my ($aux_decl, $cond_src, $body_src, $aux) = format_entry_block_src($spec, {}, $opts);
    $body_src =~ s/ENTRY_PLACEHOLDER/undef/g;
    if (defined $classify_src && length $classify_src) {
        my $marker = 'if ($timestamp_str eq $format_last_ts_str)';
        my $at = index($body_src, $marker);
        die "timestamp memo marker not found in generated body" if $at < 0;
        substr($body_src, $at, 0) = "$classify_src\n";
    }
    my $guard_src = format_guard_cond_src($spec->{guard});
    my @entries = ($spec);
    my $src = "sub {\n$aux_decl"
        . "my \$head_ord = ord(\$_[0]);\nif (\$head_ord == 32) { return undef; }\n"
        . "if ( $guard_src$cond_src ) {\n$body_src\nreturn \$entries[0];\n}\nreturn undef;\n}";
    my $sub = eval $src;
    die "codegen failed for arm '$label': $@\n$src\n" if $@ || ref $sub ne 'CODE';
    return $sub;
}

# The timed loop, generated per arm so the per-line shape is the production
# one (one scan-sub call per line) plus the arm's after-scan snippet (class 6).
sub build_loop {
    my ($block_sub, $after_src, $label) = @_;
    $after_src //= '';
    my $src = "sub {\nmy (\$lines) = \@_;\nfor (\@\$lines) {\n\$line_entry = \$block_sub->(\$_);\n$after_src\n}\n}";
    my $loop = eval $src;
    die "loop codegen failed for arm '$label': $@\n$src\n" if $@ || ref $loop ne 'CODE';
    return $loop;
}

sub reset_run_state {
    ( $timestamp_str, $category_bucket, $object, $instance, $user, $session, $platform, $thread, $message ) = ("") x 9;
    ( $bytes, $duration ) = ( undef, undef );
    ( $status_code, $is_access_log ) = ( 0, 0 );
    ( $timestamp, $fractional_ms ) = ( undef, 0 );
    ( $format_last_ts_str, $format_last_ts_epoch ) = ( '', undef );
    timestamp_date_cache_clear();
    $line_outcome = 0;
    %bucket_outcomes = (); %bucket_failures = (); %bucket_successes = (); %bucket_outcomes_a = (); %msg_outcomes = ();
    ($total_failures, $total_successes) = (0, 0);
}

# ---------------------------------------------------------------------------
# Arm definitions per family. Each arm: { name, class, classify (block
# snippet), after (post-scan snippet), setup (build-time table population),
# cls (resolved classification for the reference, undef = declining) }.

my $CLS_ACCESS  = { success => [ { status_code => '^[123]\d\d$' } ], failure => [ { status_code => '^[45]\d\d$' } ] };
my $CLS_DEFAULT = { failure => [ { category_bucket => '^(?:ERROR|FATAL|CRITICAL)$' } ] };   # %classification_default (D15)
my $CLS_CONJ    = { failure => [ { category_bucket => '^(?:ERROR|FATAL|CRITICAL)$' },
                                 { category_bucket => '^WARN$', message => 'timed out' } ] };

my %families = (
    access => {
        spec => 'mt3', budget_case => 'single-day-access-log-standard',
        arms => [
            { name => 'baseline',          class => '-', cls => undef, classify => '' },
            # class 2: status family
            { name => 'c2-regex',          class => 2, cls => $CLS_ACCESS,
              classify => q{$line_outcome = $status_code =~ /^[45]\d\d$/ ? 2 : $status_code =~ /^[123]\d\d$/ ? 1 : 0;} },
            { name => 'c2-intcmp',         class => 2, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;} },
            { name => 'c2-firstchar',      class => 2, cls => $CLS_ACCESS,
              classify => q{my $h = ord($status_code); $line_outcome = ($h == 52 || $h == 53) ? 2 : ($h >= 49 && $h <= 51) ? 1 : 0;} },
            { name => 'c2-bucketmap',      class => 2, cls => $CLS_ACCESS,
              setup => sub { %cls_bucket_map = ( '4xx' => 2, '5xx' => 2, '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = $cls_bucket_map{$category_bucket} // 0;} },
            # class 4: evaluation order (success first — every 2xx line pays one test instead of two)
            { name => 'c4-regex-succfirst', class => 4, cls => $CLS_ACCESS,
              classify => q{$line_outcome = $status_code =~ /^[123]\d\d$/ ? 1 : $status_code =~ /^[45]\d\d$/ ? 2 : 0;} },
            { name => 'c4-intcmp-succfirst', class => 4, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 100 && $status_code <= 399) ? 1 : ($status_code >= 400 && $status_code <= 599) ? 2 : 0;} },
            # class 5: call shape — same intcmp logic behind a closure call (the CSV-path FR_CLASSIFY shape)
            { name => 'c5-closure',        class => 5, cls => $CLS_ACCESS,
              setup => sub { $cls_closure = sub { return ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0 } },
              classify => q{$line_outcome = $cls_closure->();} },
            { name => 'c5-interp',         class => 5, cls => $CLS_ACCESS,
              setup => sub { @cls_interp = @{ compile_reference($CLS_ACCESS) } },
              classify => q{$line_outcome = reference_outcome(\@cls_interp);} },
            # class 6: counting at the include point (intcmp classify + counting shape)
            { name => 'c6-none',           class => 6, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60;} },
            { name => 'c6-nested-hash',    class => 6, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; if ($line_outcome == 2) { $bucket_outcomes{$bucket}{failures}++; $total_failures++ } elsif ($line_outcome) { $bucket_outcomes{$bucket}{successes}++; $total_successes++ }} },
            { name => 'c6-two-flat',       class => 6, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; if ($line_outcome == 2) { $bucket_failures{$bucket}++; $total_failures++ } elsif ($line_outcome) { $bucket_successes{$bucket}++; $total_successes++ }} },
            { name => 'c6-array-idx',      class => 6, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++;} },
            { name => 'c6-array-idx+msg',  class => 6, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++; $msg_outcomes{$message}[$line_outcome]++;} },
            { name => 'c6-array-idx+entrycmp', class => 6, cls => $CLS_ACCESS,
              classify => q{$line_outcome = ($status_code >= 400 && $status_code <= 599) ? 2 : ($status_code >= 100 && $status_code <= 399) ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++; if ($line_entry != $file_cls_entry) { $file_cls_entry = $line_entry; }} },
            { name => 'c2-litset2',        class => 2, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0;} },
            { name => 'c6-array-idx-guarded', class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_bucket_map = ( '4xx' => 2, '5xx' => 2, '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = $cls_bucket_map{$category_bucket} // 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome;} },
            { name => 'c6-array-idx-guarded+msg', class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_bucket_map = ( '4xx' => 2, '5xx' => 2, '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = $cls_bucket_map{$category_bucket} // 0;},
              after => q{$bucket = int($timestamp / 60) * 60; if ($line_outcome) { $bucket_outcomes_a{$bucket}[$line_outcome]++; $msg_outcomes{$message}[$line_outcome]++ }} },
            { name => 'c6-msg-base',       class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; $msg_outcomes{$message}{occurrences}++;} },
            { name => 'c6-msg-relookup',   class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; $msg_outcomes{$message}{occurrences}++; $msg_outcomes{$message}{outcomes}[$line_outcome]++ if $line_outcome;} },
            { name => 'c6-msg-heldref',    class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; my $m = $msg_outcomes{$message} //= {}; $m->{occurrences}++; $m->{outcomes}[$line_outcome]++ if $line_outcome;} },
            { name => 'c6-entry-refcmp',   class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; if ($line_entry != $file_cls_entry) { $file_cls_entry = $line_entry; }} },
            { name => 'c6-entry-aelem-id', class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ); $spec_by_name{mt3}{99} = 7; $file_cls_id = 7 },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; if ($line_entry->{99} != $file_cls_id) { $file_cls_id = $line_entry->{99}; }} },
            { name => 'c6-entry-block-id', class => 6, cls => $CLS_ACCESS,
              setup => sub { %cls_fail_set = ( '4xx' => 1, '5xx' => 1 ); %cls_bucket_map = ( '1xx' => 1, '2xx' => 1, '3xx' => 1 ); $file_cls_id = 7 },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : exists $cls_bucket_map{$category_bucket} ? 1 : 0; $line_cls_id = 7;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; if ($line_cls_id != $file_cls_id) { $file_cls_id = $line_cls_id; }} },
        ],
    },
    scriptlog => {
        spec => 'mt1std', budget_case => 'multi-day-custom-logs-standard',
        arms => [
            { name => 'baseline',          class => '-', cls => undef, classify => '' },
            # class 1: literal alternation on category_bucket (the D15 default, paid by every diagnostics line)
            { name => 'c1-regex',          class => 1, cls => $CLS_DEFAULT,
              classify => q{$line_outcome = $category_bucket =~ /^(?:ERROR|FATAL|CRITICAL)$/ ? 2 : 0;} },
            { name => 'c1-hashset',        class => 1, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;} },
            { name => 'c1-eqchain',        class => 1, cls => $CLS_DEFAULT,
              classify => q{$line_outcome = ($category_bucket eq 'ERROR' || $category_bucket eq 'FATAL' || $category_bucket eq 'CRITICAL') ? 2 : 0;} },
            # class 3: message-text conjunction added to the default (WARN + 'timed out')
            { name => 'c3-regex-regex',    class => 3, cls => $CLS_CONJ,
              classify => q{$line_outcome = ($category_bucket =~ /^(?:ERROR|FATAL|CRITICAL)$/ || ($category_bucket =~ /^WARN$/ && $message =~ /timed out/)) ? 2 : 0;} },
            { name => 'c3-hash-index',     class => 3, cls => $CLS_CONJ,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = (exists $cls_fail_set{$category_bucket} || ($category_bucket eq 'WARN' && index($message, 'timed out') >= 0)) ? 2 : 0;} },
            { name => 'c3-hash-indexgate-regex', class => 3, cls => $CLS_CONJ,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = (exists $cls_fail_set{$category_bucket} || ($category_bucket eq 'WARN' && index($message, 'timed out') >= 0 && $message =~ /timed out/)) ? 2 : 0;} },
            # class 5 on the default rule
            { name => 'c5-closure',        class => 5, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL); $cls_closure = sub { return exists $cls_fail_set{$category_bucket} ? 2 : 0 } },
              classify => q{$line_outcome = $cls_closure->();} },
            { name => 'c5-interp',         class => 5, cls => $CLS_DEFAULT,
              setup => sub { @cls_interp = @{ compile_reference($CLS_DEFAULT) } },
              classify => q{$line_outcome = reference_outcome(\@cls_interp);} },
            # class 6 on the default rule: counting where nearly every line is unclassified
            { name => 'c6-none',           class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60;} },
            { name => 'c6-nested-hash',    class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; if ($line_outcome == 2) { $bucket_outcomes{$bucket}{failures}++; $total_failures++ } elsif ($line_outcome) { $bucket_outcomes{$bucket}{successes}++; $total_successes++ }} },
            { name => 'c6-array-idx',      class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++;} },
            { name => 'c6-array-idx-guarded', class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome;} },
            { name => 'c6-msg-base',       class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; $msg_outcomes{$message}{occurrences}++;} },
            { name => 'c6-msg-relookup',   class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; $msg_outcomes{$message}{occurrences}++; $msg_outcomes{$message}{outcomes}[$line_outcome]++ if $line_outcome;} },
            { name => 'c6-msg-heldref',    class => 6, cls => $CLS_DEFAULT,
              setup => sub { %cls_fail_set = map { $_ => 1 } qw(ERROR FATAL CRITICAL) },
              classify => q{$line_outcome = exists $cls_fail_set{$category_bucket} ? 2 : 0;},
              after => q{$bucket = int($timestamp / 60) * 60; $bucket_outcomes_a{$bucket}[$line_outcome]++ if $line_outcome; my $m = $msg_outcomes{$message} //= {}; $m->{occurrences}++; $m->{outcomes}[$line_outcome]++ if $line_outcome;} },
        ],
    },
    gc => {
        spec => 'mt6', budget_case => undef,
        arms => [
            { name => 'baseline',          class => '-', cls => undef, classify => '' },
            # class 0: the declining entry — what the zero-cost path costs
            { name => 'c0-emit-zero',      class => 0, cls => undef, classify => q{$line_outcome = 0;} },
            { name => 'c0-loop-reset',     class => 0, cls => undef, classify => '', loop_pre => q{$line_outcome = 0;} },
        ],
    },
);

my $fam = $families{$family} or die "unknown family '$family' (access|scriptlog|gc)\n";
my $spec = $spec_by_name{ $fam->{spec} } or die "spec $fam->{spec} not in registry";

($line_entry, $file_cls_entry) = ($spec, $spec);

# ---------------------------------------------------------------------------
sub median_min_max {
    my @s = sort { $a <=> $b } @_;
    my $n = @s;
    my $median = $n % 2 ? $s[$n >> 1] : ($s[$n / 2 - 1] + $s[$n / 2]) / 2;
    return ($median, $s[0], $s[-1]);
}

for my $fixture (@ARGV) {
    open my $fh, '<', $fixture or die "open $fixture: $!";
    my @lines;
    while (my $l = <$fh>) { chomp $l; push @lines, $l }
    close $fh;
    my $n = @lines;
    (my $fx = $fixture) =~ s{.*/}{};

    # Build every arm; verify each classifying arm against the reference on every line.
    my @built;
    for my $arm (@{ $fam->{arms} }) {
        next if %only_arms && $arm->{name} ne 'baseline' && !$only_arms{ $arm->{name} };
        $arm->{setup}->() if $arm->{setup};
        my $block = build_block_sub($spec, $arm->{classify}, $arm->{name});
        my $after = ($arm->{after} // '');
        my $loop_pre = ($arm->{loop_pre} // '');
        my $loop = build_loop($block, $after, $arm->{name});
        # verification: per line, block then reference on the fields the block left
        my ($mism, $matched, %hist) = (0, 0);
        my $walk = $arm->{cls} ? compile_reference($arm->{cls}) : undef;
        reset_run_state();
        for my $l (@lines) {
            $line_outcome = 0 if length $loop_pre;
            my $e = $block->($l);
            next unless $e;
            $matched++;
            my $want = $walk ? reference_outcome($walk) : 0;
            $hist{$line_outcome}++;
            $mism++ if $line_outcome != $want;
            $line_outcome = 0 if !$arm->{cls} && !length($arm->{classify});   # baseline: nothing sets it
        }
        printf STDERR "%-10s %-24s %-22s lines=%d matched=%d outcomes{0,1,2}=%d/%d/%d mismatches=%d\n",
            $family, $fx, $arm->{name}, $n, $matched, $hist{0} // 0, $hist{1} // 0, $hist{2} // 0, $mism;
        die "arm $arm->{name} is not outcome-identical to the reference ($mism mismatches)\n" if $mism;
        # the timed loop: loop_pre arms re-generate with the reset inside the loop
        if (length $loop_pre) {
            $loop = build_loop($block, $after, $arm->{name});
            my $src = "sub {\nmy (\$lines) = \@_;\nfor (\@\$lines) {\n$loop_pre\n\$line_entry = \$block->(\$_);\n$after\n}\n}";
            $loop = eval $src; die "loop codegen failed: $@" if $@;
        }
        push @built, [ $arm, $loop ];
    }
    next if $verify_only;

    my %median;
    print join("\t", qw(family fixture lines class arm median_s min_s max_s us_per_line delta_us_per_line pct_of_budget)), "\n" if !$ENV{TSV_HEADER_DONE}++;
    for my $b (@built) {
        my ($arm, $loop) = @$b;
        reset_run_state(); $loop->(\@lines);    # warmup
        my @secs;
        for (1 .. $runs) {
            reset_run_state();
            my $t0 = [gettimeofday];
            $loop->(\@lines);
            push @secs, tv_interval($t0);
        }
        my ($med, $min, $max) = median_min_max(@secs);
        $median{ $arm->{name} } = $med;
        my $base = $median{baseline} // $med;
        my $delta_us = ($med - $base) / $n * 1e6;
        my $pct = defined $budget_us ? sprintf('%.2f', $delta_us / $budget_us * 100) : 'n/a';
        printf "%s\t%s\t%d\t%s\t%s\t%.6f\t%.6f\t%.6f\t%.4f\t%+.4f\t%s\n",
            $family, $fx, $n, $arm->{class}, $arm->{name}, $med, $min, $max, $med / $n * 1e6, $delta_us, $pct;
    }
}
