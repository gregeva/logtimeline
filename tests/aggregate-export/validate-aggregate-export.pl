#!/usr/bin/env perl
#
# Aggregate-export validator (Issue #503): the YAML file -o writes, read back
# under a strict parser and checked against the key rules
# (tests/aggregate-export/rules/keys.tsv), the sample-size gate, and the
# identities the file must satisfy. A key the rules do not name is a failure.
#
# Modes:
#   check   --rules <keys.tsv> --yaml <file>            structural validation; exit 1 on any FAIL
#   get     --yaml <file> --path <dotted.path>          print one value (list items by index: series.buckets.0.timestamp)
#   compare --yaml <file> --csv <stats.csv>             every per-bucket value the file and the STATS CSV both carry, equal
#
# Values compared numerically use a relative tolerance of 1e-12: both
# surfaces print Perl's default rendering of the same double.

use strict;
use warnings;
use YAML::PP;
use Getopt::Long;
use Text::CSV;

my %opt;
GetOptions('rules=s' => \$opt{rules}, 'yaml=s' => \$opt{yaml}, 'path=s' => \$opt{path}, 'csv=s' => \$opt{csv}) or die "bad args\n";
my $mode = shift @ARGV // 'check';
die "missing --yaml\n" unless defined $opt{yaml};

my $yp  = YAML::PP->new(boolean => 'JSON::PP');
my $doc = eval { $yp->load_file($opt{yaml}) };
if (!$doc) { print "FAIL: the file does not parse as YAML: $@\n"; exit 1 }

my ($pass, $fail) = (0, 0);
sub ok   { my ($label) = @_; $pass++; print "  PASS  $label\n" }
sub nok  { my ($label, $why) = @_; $fail++; print "  FAIL  $label\n        $why\n" }

sub is_bool   { my $v = shift; ref $v && ref($v) =~ /Boolean/ }
sub is_number { my $v = shift; defined $v && !ref $v && $v =~ /^-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?$/ }
sub is_int    { my $v = shift; defined $v && !ref $v && $v =~ /^-?\d+$/ }
sub near      { my ($a, $b) = @_; return 1 if $a == $b; my $m = abs($a) > abs($b) ? abs($a) : abs($b); return abs($a - $b) <= 1e-12 * $m }

my %quantile = (p1 => .01, p5 => .05, p10 => .10, p25 => .25, p50 => .50, p75 => .75, p90 => .90, p95 => .95, p99 => .99, p999 => .999, p9999 => .9999, p99999 => .99999);

# Walk the document; yield (rule path, value, parent hash) per leaf.
sub walk {
    my ($node, $path, $cb, $parent) = @_;
    if (ref $node eq 'HASH') {
        for my $k (sort keys %$node) { walk($node->{$k}, [@$path, $k], $cb, $node) }
    } elsif (ref $node eq 'ARRAY') {
        for my $i (0 .. $#$node) { walk($node->[$i], [@$path, "[$i]"], $cb, $node) }
        $cb->($path, undef, $parent, 1) if !@$node;
    } else {
        $cb->($path, $node, $parent);
    }
}

sub get_path {
    my ($node, $path) = @_;
    for my $seg (split /\./, $path) {
        return undef unless defined $node;
        if (ref $node eq 'ARRAY') { $node = $node->[$seg] } else { $node = $node->{$seg} }
    }
    return $node;
}

if ($mode eq 'get') {
    my $v = get_path($doc, $opt{path});
    if (!defined $v) { print "\n"; exit 3 }
    print( (is_bool($v) ? ($v ? 'true' : 'false') : $v) . "\n");
    exit 0;
}

if ($mode eq 'check') {
    die "missing --rules\n" unless defined $opt{rules};
    my (%rule, @rule_order);
    open my $rf, '<', $opt{rules} or die "cannot read $opt{rules}: $!\n";
    my $header = <$rf>;
    while (my $line = <$rf>) {
        chomp $line; next if $line eq '';
        my ($key, $type, $presence, $gate) = split /\t/, $line, -1;
        $rule{$key} = { type => $type, presence => $presence, gate => $gate // '' };
        push @rule_order, $key;
    }
    close $rf;

    # Match a concrete path to a rule: list indices become [], and a segment
    # with no literal rule at its position matches a * rule.
    sub rule_for {
        my ($rule, $segs) = @_;
        my @cands = ('');
        for my $seg (@$segs) {
            my @next;
            for my $c (@cands) {
                if ($seg =~ /^\[\d+\]$/) { push @next, ($c eq '' ? '[]' : "$c\[]") ; next }
                my $lit  = $c eq '' ? $seg : "$c.$seg";
                my $wild = $c eq '' ? '*'  : "$c.*";
                push @next, $lit, $wild;
            }
            @cands = @next;
        }
        for my $c (@cands) { return ($c, $rule->{$c}) if exists $rule->{$c} }
        # a list-item path like population.formats[].name: the [] attaches to the parent segment
        for my $c (@cands) { (my $d = $c) =~ s/\.\[\]/[]/g; return ($d, $rule->{$d}) if exists $rule->{$d} }
        return (undef, undef);
    }

    my %seen;
    walk($doc, [], sub {
        my ($path, $value, $parent, $empty_list) = @_;
        my $concrete = join('.', @$path);
        my ($rule_key, $r) = rule_for(\%rule, $path);
        if (!$r) { nok("key $concrete", "not named by the rules: an unknown key is a failure"); return }
        $seen{$rule_key}++;
        return if $empty_list;
        my $t = $r->{type};
        my $type_ok = $t eq 'int' ? is_int($value) : $t eq 'number' ? is_number($value) : $t eq 'bool' ? is_bool($value) : (defined $value && !ref $value);
        if (!$type_ok) { nok("type of $concrete", "expected $t, got " . (defined $value ? "'$value'" : 'undef')); return }
        if ($r->{gate} =~ /^count:(\w+)$/) {
            my $count = $parent->{$1};
            my $slug = $path->[-1];
            my $need = 10 / (1 - $quantile{$slug});
            if (!defined $count || $count < $need) { nok("gate of $concrete", "present with occurrences=" . ($count // 'undef') . " below the $slug threshold $need") }
        }
    });
    ok("every key present is named by the rules (" . scalar(keys %seen) . " rule keys seen)") unless grep { /^key / } ();

    # Required keys present.
    for my $key (@rule_order) {
        next unless $rule{$key}{presence} eq 'yes';
        next if $key =~ /\*/;
        if ($key =~ /\[\]/) {
            # required within every list item that exists
            (my $list_path = $key) =~ s/\[\].*$//;
            my $list = get_path($doc, $list_path) // [];
            my $tail = ($key =~ /\[\]\.(.*)$/) ? $1 : undef;
            next unless defined $tail;
            for my $i (0 .. $#$list) {
                nok("required key $key", "absent from item $i") unless defined get_path($list->[$i], $tail);
            }
        } else {
            nok("required key $key", "absent") unless defined get_path($doc, $key);
        }
    }
    ok("every required key is present");

    # Gated percentiles: present exactly when the block's count supports them,
    # on every block that carries a count and at least one ladder value or a stats family.
    my $gate_checks = 0;
    walk($doc, [], sub {
        my ($path, $value, $parent) = @_;
        return unless $path->[-1] eq 'occurrences' && ref $parent eq 'HASH';
        my $has_ladder = grep { exists $parent->{$_} } keys %quantile;
        my $is_stats_block = $has_ladder || exists $parent->{min};
        return unless $is_stats_block;
        # a bucket's bytes/count family carries no percentiles; only blocks that
        # hold any ladder key or are histogram/heatmap/duration blocks are gated
        return unless $has_ladder || $path->[-2] =~ /^(?:duration|heatmap|highlighted)$/ || $path->[-3] eq 'histogram';
        for my $slug (sort keys %quantile) {
            my $need = 10 / (1 - $quantile{$slug});
            $gate_checks++;
            if ($value >= $need && !exists $parent->{$slug}) {
                nok("gate " . join('.', @$path[0 .. $#$path - 1]) . ".$slug", "occurrences=$value supports it but it is absent");
            }
        }
    });
    ok("percentiles present exactly where the count supports them ($gate_checks gate checks)");

    # Identities.
    my $m = $doc->{measurements};
    $m->{classified} == $m->{successes} + $m->{failures} ? ok("classified = successes + failures") : nok("classified = successes + failures", "$m->{classified} != $m->{successes} + $m->{failures}");
    $m->{lines_included} == $m->{classified} + $m->{unclassified} ? ok("lines_included = classified + unclassified") : nok("lines_included = classified + unclassified", "mismatch");
    my $l = $doc->{population}{lines};
    my $excluded = 0; $excluded += $_ for values %{ $l->{excluded} // {} };
    $l->{read} == $l->{unmatched} + $excluded + $l->{included} ? ok("lines.read = unmatched + excluded + included") : nok("lines.read = unmatched + excluded + included", "$l->{read} != $l->{unmatched} + $excluded + $l->{included}");
    $l->{included} == $m->{lines_included} ? ok("lines.included = measurements.lines_included") : nok("lines.included = measurements.lines_included", "mismatch");
    my $s = $doc->{series};
    $s->{bucket_count} == scalar @{ $s->{buckets} } ? ok("bucket_count = buckets written") : nok("bucket_count = buckets written", "$s->{bucket_count} != " . scalar @{ $s->{buckets} });
    my $src = $doc->{population}{sources};
    $src->{directories} == scalar @{ $src->{directory_list} } ? ok("directories = directory_list length") : nok("directories = directory_list length", "mismatch");
    my $sum_occ = 0; my $bucket_fail = 0;
    for my $b (@{ $s->{buckets} }) {
        $sum_occ += $b->{occurrences};
        $bucket_fail++ if $b->{successes} + $b->{failures} > $b->{occurrences};
        my $cat_sum = 0; $cat_sum += $_ for values %{ $b->{categories} // {} };
        $bucket_fail++ if $b->{occurrences} != $cat_sum;
        if (exists $b->{success_pct}) { $bucket_fail++ unless $b->{successes} + $b->{failures} > 0 }
    }
    $bucket_fail ? nok("per-bucket identities", "$bucket_fail bucket(s) violate successes+failures <= occurrences = sum(categories), pct only with classified lines") : ok("per-bucket identities on " . scalar(@{ $s->{buckets} }) . " buckets");
    $sum_occ == $l->{included} ? ok("sum of bucket occurrences = lines.included") : nok("sum of bucket occurrences = lines.included", "$sum_occ != $l->{included}");
    my $cat_total = 0; $cat_total += $_ for values %{ $m->{categories} };
    $cat_total == $l->{included} ? ok("sum of category totals = lines.included") : nok("sum of category totals = lines.included", "$cat_total != $l->{included}");
    $m->{pct_eligible} == (exists $m->{success_pct} ? 1 : 0) ? ok("success_pct present exactly when pct_eligible") : nok("success_pct present exactly when pct_eligible", "mismatch");
}

if ($mode eq 'compare') {
    die "missing --csv\n" unless defined $opt{csv};
    my $csv = Text::CSV->new({ binary => 1 });
    open my $fh, '<', $opt{csv} or die "cannot read $opt{csv}: $!\n";
    my $header = $csv->getline($fh);
    my %col; @col{@$header} = (0 .. $#$header);
    my %row_by_ts;
    while (my $row = $csv->getline($fh)) { $row_by_ts{ $row->[0] } = $row }
    close $fh;
    my $compared = 0;
    my @map = (
        [occurrences => 'occurrences'], [successes => 'successes'], [failures => 'failures'],
        [sessions => 'sessions'],
        (map { my $s = $_; ["duration.$s" => "duration_$s"] } qw(min mean max std_dev p1 p5 p10 p25 p50 p75 iqr p90 p95 p99 p999 p9999 p99999 cv skewness kurtosis bimodality_coef)),
        ['duration.sum' => 'duration'],
        (map { ["bytes.$_" => "bytes_$_"] } qw(occurrences min mean max)), ['bytes.sum' => 'bytes'],
        (map { ["count.$_" => "count_$_"] } qw(occurrences min mean max sum)),
    );
    for my $b (@{ $doc->{series}{buckets} }) {
        my $row = $row_by_ts{ $b->{timestamp} };
        if (!$row) { nok("bucket $b->{timestamp}", "no STATS CSV row with that timestamp"); next }
        for my $cat (keys %{ $b->{categories} // {} }) {
            next unless exists $col{$cat};
            near($b->{categories}{$cat}, $row->[ $col{$cat} ]) ? $compared++ : nok("bucket $b->{timestamp} category $cat", "file $b->{categories}{$cat} vs csv $row->[$col{$cat}]");
        }
        for my $pair (@map) {
            my ($fp, $cc) = @$pair;
            next unless exists $col{$cc};
            my $fv = get_path($b, $fp);
            my $cv = $row->[ $col{$cc} ];
            next if !defined $fv && (!defined $cv || $cv eq '');
            if (!defined $fv) {
                # absent in the file: allowed only for a gated percentile the count does not support
                my $slug = (split /\./, $fp)[-1];
                if (exists $quantile{$slug} && defined $b->{duration}{occurrences} && $b->{duration}{occurrences} < 10 / (1 - $quantile{$slug})) { $compared++; next }
                nok("bucket $b->{timestamp} $fp", "absent in the file but the CSV carries $cc=$cv"); next;
            }
            if (!defined $cv || $cv eq '') { nok("bucket $b->{timestamp} $fp", "file carries $fv but the CSV column $cc is empty"); next }
            near($fv, $cv) ? $compared++ : nok("bucket $b->{timestamp} $fp", "file $fv vs csv $cc=$cv");
        }
    }
    ok("$compared per-bucket values equal between the file and the STATS CSV") if $compared;
    nok("comparison", "no value compared") unless $compared;
}

print "validate-aggregate-export.pl: $pass pass, $fail fail\n";
exit($fail ? 1 : 0);
