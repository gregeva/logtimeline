#!/usr/bin/env perl
# #616 drop 2: generate the probes for the per-line cost of the observation
# counts. Question: which form of keeping (or not keeping) the duration and
# bytes observation counts costs least per line, with the output unchanged?
#
# Every probe is the given ltl (drop 2 with the bytes demand gates and the
# cached entry references) with a mechanical edit; this script is the only
# author of a probe and asserts every landmark and substitution count, so a
# base that has moved fails loudly.
#
#   cached    the base, verbatim: one entry reference per duration block, the
#             count incremented through it
#   full      the count and the total reached by full-key lookups (the form
#             drop 2 first measured)
#   nocount   no count increments: a total is not pre-set to zero, so it
#             exists exactly when a line added to it and that is the
#             observation test; the bin model's running-mean update keeps its
#             own count; the bytes count is kept only under the bytes
#             aggregate demand, as before drop 2
#   oneref    cached, with every lookup of the message entry and of the bucket
#             entry in the read loop's message and bucket sections made
#             through one reference (changes lines that predate #616)
#
#   usage: make-probes.pl <ltl> <output dir>
use strict;
use warnings;

my ($base, $out) = @ARGV;
die "usage: make-probes.pl <ltl> <output dir>\n" unless defined $base && defined $out;
mkdir $out unless -d $out;
open my $fh, '<', $base or die "$base: $!";
my $src = do { local $/; <$fh> };
close $fh;

sub rep {
    my ($t, $from, $to, $want, $what) = @_;
    my $n = () = $$t =~ /\Q$from\E/g;
    die "make-probes: $what: expected $want of [" . substr($from, 0, 80) . "], found $n\n" unless $n == $want;
    $$t =~ s/\Q$from\E/$to/g;
}
sub write_probe {
    my ($name, $text) = @_;
    my $path = "$out/ltl-$name";
    open my $o, '>', $path or die "$path: $!";
    print {$o} $text;
    close $o;
    chmod 0755, $path;
    print "wrote $path\n";
}

write_probe('cached', $src);

# --- full ----------------------------------------------------------------------
{
    my $t = $src;
    rep(\$t, "                            my \$me = \$log_messages{\$category}{\$log_key};\n                            \$me->{total_duration} += \$duration;\n",
             "                            \$log_messages{\$category}{\$log_key}{total_duration} += \$duration;\n", 1, 'full: message total');
    rep(\$t, "                            \$me->{duration_count}++;\n",
             "                            \$log_messages{\$category}{\$log_key}{duration_count}++;\n", 1, 'full: message count');
    rep(\$t, "                        my \$be = \$log_analysis{\$bucket};\n                        \$be->{duration_sum} += \$duration;\n",
             "                        \$log_analysis{\$bucket}{duration_sum} += \$duration;\n", 1, 'full: bucket total');
    rep(\$t, "                        \$be->{duration_count}++;\n",
             "                        \$log_analysis{\$bucket}{duration_count}++;\n", 1, 'full: bucket count');
    write_probe('full', $t);
}

# --- nocount ---------------------------------------------------------------------
{
    my $t = $src;
    # totals not pre-set: the message entry (both models) and the bucket entry
    rep(\$t, "                            occurrences    => 0,\n                            total_duration => 0,\n",
             "                            occurrences    => 0,\n", 2, 'nocount: message constructors');
    rep(\$t, "                        occurrences => 0,\n                        duration_sum => 0,\n",
             "                        occurrences => 0,\n", 2, 'nocount: bucket constructors');
    rep(\$t, "                        duration_count => 0,\n                        durations => [],\n",
             "                        durations => [],\n", 1, 'nocount: raw bucket count');
    # no count increments; the bin model's update writes its own count again
    rep(\$t, "                            \$me->{duration_count}++;\n", "", 1, 'nocount: message count');
    rep(\$t, "                        \$be->{duration_count}++;\n", "", 1, 'nocount: bucket count');
    rep(\$t, "                                            \$entry->{m2_sum} += \$term1;\n                                        }\n                                    }\n                                }\n",
             "                                            \$entry->{m2_sum} += \$term1;\n                                        }\n                                    }\n                                    \$entry->{duration_count} = \$n;\n                                }\n", 1, 'nocount: message update writes its count');
    rep(\$t, "                                        \$entry->{m2_sum} += \$term1;\n                                    }\n                                }\n                            }\n",
             "                                        \$entry->{m2_sum} += \$term1;\n                                    }\n                                }\n                                \$entry->{duration_count} = \$n;\n                            }\n", 1, 'nocount: bucket update writes its count');
    # the bytes count only under the aggregate demand
    rep(\$t, "                            } else {\n                                \$e->{bytes_occurrences}++;\n                            }\n", "                            }\n", 1, 'nocount: message bytes count');
    rep(\$t, "                        } else {\n                            \$e->{bytes_occurrences}++;\n                        }\n", "                        }\n", 1, 'nocount: bucket bytes count');
    # the observation tests read the total's existence
    rep(\$t, "            ( \$log_analysis{\$bucket}{bytes_occurrences} ? (", "            ( defined \$log_analysis{\$bucket}{total_bytes} ? (", 1, 'nocount: projection bytes gate');
    rep(\$t, "            ( \$log_analysis{\$bucket}{duration_count} ? (", "            ( defined \$log_analysis{\$bucket}{duration_sum} ? (", 1, 'nocount: projection duration gate');
    rep(\$t, "        \$aggregated_data->{total_duration} += \$log_analysis{\$bucket}{duration_sum};",
             "        \$aggregated_data->{total_duration} += \$log_analysis{\$bucket}{duration_sum} // 0;", 1, 'nocount: bucket statistics pass');
    rep(\$t, "                my \$duration_observed = \$log_messages{\$category}{\$log_key}{duration_count};",
             "                my \$duration_observed = defined \$log_messages{\$category}{\$log_key}{total_duration};", 1, 'nocount: group calculation');
    rep(\$t, " if \$log_messages{\$category}{\$log_key}{bytes_occurrences};\n",
             " if defined \$log_messages{\$category}{\$log_key}{total_bytes};\n", 1, 'nocount: message bytes roll-up');
    rep(\$t, "    if (\$source->{duration_count}) {\n", "    if (defined \$source->{total_duration}) {\n", 1, 'nocount: merge duration gate');
    rep(\$t, "    if (\$source->{bytes_occurrences}) {\n", "    if (defined \$source->{total_bytes}) {\n", 1, 'nocount: merge bytes gate');
    rep(\$t, "        \$target->{bytes_occurrences} = (\$target->{bytes_occurrences} // 0) + \$source->{bytes_occurrences};",
             "        \$target->{bytes_occurrences} = (\$target->{bytes_occurrences} // 0) + (\$source->{bytes_occurrences} // 0) if defined \$source->{bytes_occurrences};", 1, 'nocount: merge bytes count');
    rep(\$t, "            if (\$cluster->{duration_count}) {\n", "            if (defined \$cluster->{total_duration}) {\n", 1, 'nocount: reinject duration gate');
    rep(\$t, "            if (\$cluster->{bytes_occurrences}) {\n", "            if (defined \$cluster->{total_bytes}) {\n", 1, 'nocount: reinject bytes gate');
    write_probe('nocount', $t);
}

# --- oneref ------------------------------------------------------------------------
{
    my @l = split /(?<=\n)/, $src;
    my ($ms) = grep { $l[$_] =~ /^\s*\$log_messages\{\$category\}\{\$log_key\} \/\/= \(/ } 0 .. $#l;
    my ($me_end) = grep { $l[$_] =~ /\{impact\} = log\( \$mean \*\* \$impact_time_exponent/ } 0 .. $#l;
    my ($bs) = grep { $l[$_] =~ /^\s*\$log_analysis\{\$bucket\} \/\/= \(/ } 0 .. $#l;
    my ($be_end) = grep { $l[$_] =~ /^\s*## HEATMAP RAW VALUE CAPTURE ##/ } 0 .. $#l;
    die "make-probes: oneref landmarks missing\n" unless defined $ms && defined $me_end && defined $bs && defined $be_end && $ms < $me_end && $me_end < $bs && $bs < $be_end;
    $l[$ms] =~ s/^(\s*)\$log_messages\{\$category\}\{\$log_key\} \/\/= /$1my \$mref = \$log_messages{\$category}{\$log_key} \/\/= / or die;
    $l[$bs] =~ s/^(\s*)\$log_analysis\{\$bucket\} \/\/= /$1my \$bref = \$log_analysis{\$bucket} \/\/= / or die;
    my ($nm, $nb) = (0, 0);
    for my $i ($ms + 1 .. $me_end) {
        next if $l[$i] =~ /^\s*#/;
        if ($l[$i] =~ /^\s*my \$me = \$log_messages\{\$category\}\{\$log_key\};\s*$/) { $l[$i] = ''; next }
        $nm += $l[$i] =~ s/\$me->/\$mref->/g;
        $nm += $l[$i] =~ s/\$log_messages\{\$category\}\{\$log_key\}\{/\$mref->{/g;
        $nm += $l[$i] =~ s/\@\{\$log_messages\{\$category\}\{\$log_key\}\{/\@{\$mref->{/g;
        $nm += $l[$i] =~ s/= \$log_messages\{\$category\}\{\$log_key\};/= \$mref;/g;
    }
    for my $i ($bs + 1 .. $be_end) {
        next if $l[$i] =~ /^\s*#/;
        if ($l[$i] =~ /^\s*my \$be = \$log_analysis\{\$bucket\};\s*$/) { $l[$i] = ''; next }
        $nb += $l[$i] =~ s/\$be->/\$bref->/g;
        $nb += $l[$i] =~ s/\$log_analysis\{\$bucket\}\{/\$bref->{/g;
        $nb += $l[$i] =~ s/\@\{\$log_analysis\{\$bucket\}\{/\@{\$bref->{/g;
        $nb += $l[$i] =~ s/= \$log_analysis\{\$bucket\};/= \$bref;/g;
    }
    print "oneref: $nm message lookups, $nb bucket lookups through one reference\n";
    write_probe('oneref', join '', @l);
}
