#!/usr/bin/env perl
#
# patch-ltl.pl - writes a copy of ltl whose read loop serves CSV rows through
# arm B, for the whole-run comparisons of features/615-csv-registry-entry.md
# § 8 (the STATS CSV, -V filter-summary, -V format-detection, the index row,
# and TIMING parse/read_files). The copy is a measuring instrument, written to
# a scratch path and never committed; ltl itself is not changed.
#
# B's generator (header shape, block source, validation, instantiation) is
# taken from csv-block.pl by anchors, so both instruments run the same text.
#
# Usage: perl patch-ltl.pl OUT_PATH

use strict;
use warnings;
use FindBin;

my $out = shift @ARGV or die "usage: $0 OUT_PATH\n";
my $read = sub { my ($p) = @_; open my $fh, '<', $p or die "$p: $!"; local $/; <$fh> };
my $ltl = $read->("$FindBin::Bin/../../ltl");
my $drv = $read->("$FindBin::Bin/csv-block.pl");

sub between {   # text from the line holding $from up to the line holding $to (exclusive)
    my ($src, $from, $to) = @_;
    my $i = index($src, $from); die "anchor not found: $from\n" if $i < 0;
    $i = rindex($src, "\n", $i) + 1;
    my $j = index($src, $to, $i); die "anchor not found: $to\n" if $j < 0;
    $j = rindex($src, "\n", $j) + 1;
    return substr($src, $i, $j - $i);
}
sub replace_once {
    my ($src_ref, $from, $to_incl, $with, $label) = @_;
    my $i = index($$src_ref, $from); die "$label: anchor not found\n" if $i < 0;
    die "$label: anchor not unique\n" if index($$src_ref, $from, $i + 1) >= 0;
    $i = rindex($$src_ref, "\n", $i) + 1;
    my $j = index($$src_ref, $to_incl, $i); die "$label: end anchor not found\n" if $j < 0;
    $j += length $to_incl;
    $j = index($$src_ref, "\n", $j) + 1 unless substr($to_incl, -1) eq "\n";
    substr($$src_ref, $i, $j - $i) = $with;
}

# --- B's generator, from the driver -----------------------------------------
my $emit = between($ltl, q{my $frac = $spec->{time}{frac} // 'generic';}, q{return ($aux_decl, $cond_src, join("\n", @body), \@aux);});
my $gen  = between($drv, q{$SL_EMIT =~ s/\$layout eq 'iso_ms_ddmm'}, '# --- arm loops')
         . between($drv, '# --- the B block', 'sub sample_rows {')
         . between($drv, 'sub instantiate {', '# --- state reset between passes');
$gen =~ s/\$csv_spec->\{_cls_src\}/\$format_registry_spec{csv}{_cls_src}/g == 1 or die "classification source reference\n";
# the block and its extracted values are declared with the CSV globals, so
# the read loop, compiled before the generator, can name them
$gen =~ s/^my \@csv_udm_values;.*\n//m or die "csv_udm_values declaration\n";
$ltl =~ s/^(my \$csv_epoch_timestamp = 0;.*\n)/$1my \@csv_udm_values;   # prototype 615: the values the B block extracted\nmy \$csv_block;        # prototype 615: the live CSV block\n/m or die "CSV globals\n";
$gen = "# ---- prototype 615: arm B generator (from csv-block.pl) ----\nmy \$SL_EMIT = <<'__SL_EMIT__';\n${emit}__SL_EMIT__\n$gen"
     . "# ---- end prototype 615 ----\n\n";

# --- the read loop -----------------------------------------------------------
# The sample's lines are kept until line 2 decides whether the file is CSV.
replace_once(\$ltl, 'my $potential_csv_header;', 'my $potential_csv_header;',
    "        my \$potential_csv_header;\n        my \$csv_sample_lines;\n", 'sample lines declared');
replace_once(\$ltl, 'delete $sample->{lines};   # conclusions are retained', 'delete $sample->{lines};',
    "            \$csv_sample_lines = delete \$sample->{lines};\n", 'sample lines kept');

# The steady arm calls the block.
replace_once(\$ltl, '@csv_fields = split(/\Q$csv_separator\E/, $_, -1);', '$line_entry->[FR_CLASSIFY]->($_);',
    "                unless (\$csv_block->(\$_)) { note_unmatched_line(\$in_file); next; }\n"
  . "                \$is_line_match = 1; \$match_type = 13; \$line_entry = \$format_registry_entry{csv};\n", 'steady arm');

# The confirm arm instantiates the block for the header shape, validated on
# the sample's rows, then calls it on line 2.
replace_once(\$ltl, '# Confirmed CSV — process line 2 as data', '$line_entry->[FR_CLASSIFY]->($_);', <<'CONFIRM', 'confirm arm');
                            # Confirmed CSV: the block for this header shape, validated on the sample's rows
                            {
                                my $first = $data_fields[$csv_timestamp_col];
                                $first =~ s/^\s+|\s+$//g if defined $first;
                                $csv_epoch_timestamp = (defined $first && $first =~ /^\d+(\.\d+)?$/) ? 1 : 0;
                                my $rows = [ grep { $_ ne '' && $_ ne $potential_csv_header } map { s/[\r\n]+$//r } @{ $csv_sample_lines // [] } ];
                                ($csv_block) = instantiate(header_shape($csv_epoch_timestamp ? 'epoch' : 'iso'), $rows);
                                $csv_sample_lines = undef;
                                ( $format_last_ts_str, $format_last_ts_epoch ) = ( '', undef );
                                timestamp_date_cache_clear();
                            }
                            unless ($csv_block->($_)) { note_unmatched_line($in_file); next; }
                            $is_line_match = 1; $match_type = 13; $line_entry = $format_registry_entry{csv};
CONFIRM

# The capture's CSV branch reads the value the block extracted.
replace_once(\$ltl, '# CSV: extract by column index', '$matched_value = $val if $val ne \'\';',
    "                        \$matched_value = \$csv_udm_values[\$config_idx];\n", 'capture branch');
{   # the now-empty `if (...) {` closer of that branch stays: remove the stray brace line after it
    my $i = index($ltl, '$matched_value = $csv_udm_values[$config_idx];');
    my $j = index($ltl, "\n", $i) + 1;
    substr($ltl, $j, length("                        }\n")) eq "                        }\n" or die "capture branch closer\n";
    substr($ltl, $j, length("                        }\n")) = '';
}

# The two timestamp arms go: the epoch arm, and the ISO arm after the gate.
replace_once(\$ltl, 'if ($csv_epoch_timestamp) {', "\$fraction_digits = '';\n                }\n", '', 'epoch arm');
replace_once(\$ltl, '} elsif (!$csv_epoch_timestamp && $match_type == 13) {', '$timestamp = $line_entry->[FR_TIME_PARSE]->($timestamp_str);',
    "                }\n", 'ISO arm');
{   # and the ISO arm's own closing brace
    my $i = index($ltl, "                }\n                }\n\n                # Add fractional milliseconds to epoch");
    die "ISO arm closer\n" if $i < 0;
    substr($ltl, $i, length("                }\n")) = '';
}

$ltl =~ s/^(## MAIN ##)/$gen$1/m or die "no ## MAIN ##\n";
open my $fh, '>', $out or die "$out: $!";
print $fh $ltl;
close $fh;
chmod 0755, $out;
print STDERR "wrote $out\n";
