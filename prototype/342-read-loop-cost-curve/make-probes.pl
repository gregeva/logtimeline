#!/usr/bin/env perl
# #342 item 8: generate the probe binaries for the per-line loop's cost curve.
#
# Question: what does one more run-constant test on the every-included-line
# path of read_and_process_logs() cost, does the form of the test matter, and
# what does hoisting the existing string compares recover?
#
# Every probe is the base ltl with a mechanical, behaviour-neutral edit; this
# script is the only author of a probe, and it asserts every substitution
# count so a base that has moved fails loudly instead of producing a probe that
# measures something else. See tests/profile/results/342-read-loop-cost-curve/
# hypothesis.md for the design.
#
#   usage: make-probes.pl <base ltl> <output dir>
#
# Writes <output dir>/ltl-base (a copy) and ltl-{gate,str,hash}-{10,20,40},
# ltl-hoist; every file is executable.
use strict;
use warnings;

my ($base, $out) = @ARGV;
die "usage: make-probes.pl <base ltl> <output dir>\n" unless defined $base && defined $out;
mkdir $out unless -d $out;

open my $fh, '<', $base or die "$base: $!";
my @src = <$fh>;
close $fh;

# --- landmarks, each asserted to occur exactly once where it must ---------
sub find_one {
    my ($re, $what, $from, $to) = @_;
    $from //= 0; $to //= $#src;
    my @hits = grep { $src[$_] =~ $re } $from .. $to;
    die "make-probes: expected exactly one line matching $what, found " . scalar(@hits) . "\n" unless @hits == 1;
    return $hits[0];
}
my $version_ln  = find_one(qr/^my \$version_number = /, 'the version stamp');
my $sub_ln      = find_one(qr/^sub read_and_process_logs \{/, 'sub read_and_process_logs');
my $next_sub_ln = (grep { $src[$_] =~ /^sub / } $sub_ln + 1 .. $#src)[0];
my $loop_ln     = find_one(qr/^\s*while \(1\) \{/, 'the per-line loop', $sub_ln, $next_sub_ln);
my $close_ln    = find_one(qr/^\s*close \$fh;/, 'close \$fh after the loop', $loop_ln, $next_sub_ln);
my $loop_end    = $close_ln - 1;   # the loop's closing brace is the last non-blank line before close $fh
$loop_end-- while $loop_end > $loop_ln && $src[$loop_end] =~ /^\s*$/;
die "make-probes: the last line before close \$fh is not the loop's closing brace\n" unless $src[$loop_end] =~ /^\s*\}\s*$/;
my $insert_ln   = find_one(qr/^\s*\$total_lines_included\+\+;/, 'the every-included-line point', $loop_ln, $loop_end);
my $modes_ln    = find_one(qr/^\s*\$bucket_stats_capture_mode\s*=\s*choose_data_model\('bucket-stats'\)/, 'the capture-mode settlement', $sub_ln, $loop_ln);
my ($indent)    = $src[$insert_ln] =~ /^(\s*)/;

sub write_probe {
    my ($name, $lines) = @_;
    my $path = "$out/ltl-$name";
    open my $o, '>', $path or die "$path: $!";
    print {$o} @$lines;
    close $o;
    chmod 0755, $path;
    print "wrote $path\n";
}

# --- base: a verbatim copy ------------------------------------------------
write_probe('base', [@src]);

# --- the three series: N tests at the fixed point --------------------------
my %form = (
    gate => 'if ($probe_false) { $probe_sink++; }',
    str  => "if (\$probe_mode eq 'bin') { \$probe_sink++; }",
    hash => 'if ($probe_hash{x}) { $probe_sink++; }',
);
my $globals = "my (\$probe_false, \$probe_sink) = (0, 0);\nmy \$probe_mode = 'raw';\nmy \%probe_hash = ( x => 0 );\n";
for my $f (sort keys %form) {
    for my $n (10, 20, 40) {
        my @p = @src;
        splice @p, $insert_ln + 1, 0, map { "$indent$form{$f}\n" } 1 .. $n;
        splice @p, $version_ln + 1, 0, $globals;
        write_probe("$f-$n", \@p);
    }
}

# --- the hoist probe --------------------------------------------------------
my @p = @src;
my %subst = (
    q{$message_stats_capture_mode eq 'bin'} => [ '$message_stats_is_bin', 5 ],
    q{$bucket_stats_capture_mode eq 'bin'}  => [ '$bucket_stats_is_bin',  3 ],
    q{$heatmap_capture_mode eq 'raw'}       => [ '$heatmap_is_raw',       1 ],
    q{$histogram_capture_mode eq 'raw'}     => [ '$histogram_is_raw',     1 ],
    q{$group_similar_sensitivity ne "none"} => [ '$grouping_on',          5 ],
);
for my $from (sort keys %subst) {
    my ($to, $want) = @{ $subst{$from} };
    my $n = 0;
    for my $i ($loop_ln .. $loop_end) {
        my $c = () = $p[$i] =~ /\Q$from\E/g;
        next unless $c;
        $p[$i] =~ s/\Q$from\E/$to/g;
        $n += $c;
    }
    die "make-probes: hoist expected $want substitutions of [$from] in the loop, made $n\n" unless $n == $want;
}
# The three foreach loops over @udm_configs: wrap each in if (@udm_configs) { ... }.
# The loop's closing brace is the next line that is only a brace at the same indentation.
my @loops = grep { $p[$_] =~ /^\s*foreach my \$config \(\@udm_configs\) \{\s*$/ } $loop_ln .. $loop_end;
die "make-probes: hoist expected 3 foreach loops over \@udm_configs in the loop, found " . scalar(@loops) . "\n" unless @loops == 3;
for my $i (reverse @loops) {
    my ($ind) = $p[$i] =~ /^(\s*)/;
    my $end;
    for my $j ($i + 1 .. $loop_end) {
        if ($p[$j] =~ /^\Q$ind\E\}\s*$/) { $end = $j; last }
    }
    die "make-probes: no closing brace found for the foreach at line " . ($i + 1) . "\n" unless defined $end;
    splice @p, $end + 1, 0, "$ind}\n";
    splice @p, $i, 0, "${ind}if (\@udm_configs) {\n";
}
my $hoist_decl = "    my \$message_stats_is_bin = \$message_stats_capture_mode eq 'bin' ? 1 : 0;\n"
               . "    my \$bucket_stats_is_bin  = \$bucket_stats_capture_mode  eq 'bin' ? 1 : 0;\n"
               . "    my \$heatmap_is_raw       = \$heatmap_capture_mode       eq 'raw' ? 1 : 0;\n"
               . "    my \$histogram_is_raw     = \$histogram_capture_mode     eq 'raw' ? 1 : 0;\n"
               . "    my \$grouping_on          = \$group_similar_sensitivity ne \"none\" ? 1 : 0;\n";
splice @p, $modes_ln + 1, 0, $hoist_decl;
write_probe('hoist', \@p);
print "done: 11 binaries\n";
