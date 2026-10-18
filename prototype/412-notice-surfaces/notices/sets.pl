# Fixed example notice sets for the stage 1 prototypes.
#
# Wording follows the shipped producer named on each entry (the planned ones
# name their issue), split into the parts a notice carries: what it says, the
# evidence behind it, and the remedy. The values filled in (counts, files,
# operands) are illustrative. Categories are the inventory's placements in
# features/412-notice-surfaces.md, not yet confirmed.

use utf8;

my %notice = (
    # --- known at option settlement, before the read -------------------------
    deprecation => {
        category  => 'your options',
        producer  => 'print_deprecation_notices()',
        statement => '-uuid/--mask-uuid is deprecated',
        remedy    => 'use -m uuid/--mask uuid, which also masks IP addresses with -m ip, ipv4 or ipv6',
    },
    udm_unit_is_function => {
        category  => 'your options',
        producer  => 'parse_udm_configs()',
        statement => "'max' in the unit slot of -udm 'heap:max' is a function, not a unit",
        remedy    => "did you mean 'heap::max'?",
    },
    pattern_file_missing => {
        category  => 'your options',
        producer  => 'read_pattern_file()',
        statement => 'pattern file not found: patterns/probes-extra',
        evidence  => ['given to -epf; nothing is excluded by it'],
    },
    min_over_max => {
        category  => 'your options',
        producer  => 'adapt_to_command_line_options()',
        statement => '-dmin 5s is greater than -dmax 2s - the range is unsatisfiable, so no entry can match',
    },
    discard_switches_off => {
        category  => 'your options',
        producer  => 'resolve_discard_names()',
        statement => '-d/--discard removes the key duration, which the duration metric reads: the metric is switched off',
    },
    top_zero => {
        category  => 'your options',
        producer  => 'adapt_to_command_line_options()',
        statement => '-n/--top-messages 0 retains no message, so -so/--sort-on and -m/--mask have no effect',
    },

    # --- raised during the read and after it ---------------------------------
    two_producers => {
        category  => 'data anomaly',
        producer  => 'defer_format_unit_notes()',
        statement => 'the detected log format (access_common_duration) is written by more than one producer, which differ in duration unit, and nothing in the file name or content decided which',
        evidence  => ['localhost_access_log.2025-05-07.txt'],
        remedy    => 'use -du us if the file comes from the other producer',
    },
    impossible_dates => {
        category  => 'data anomaly',
        producer  => 'defer_timestamp_impossible_notes()',
        statement => '312 of 48,201 lines of the iso8601_dmy format were not matched because their date cannot exist under its date layout',
        evidence  => ['first at line 1,204: 2025-13-05 08:14:22'],
        remedy    => 'use -lf iso8601_mdy if day and month are swapped',
    },
    rule_change => {
        category  => 'data anomaly',
        producer  => 'format_classification_rule_change()',
        statement => 'the classification rules changed because the detected log format changed from windchill_method_server to log4j_generic - lines before that point were classified under the previous rules',
        evidence  => ['MethodServer-log4j.log line 18,442'],
    },
    unknown_levels => {
        category  => 'data anomaly',
        producer  => 'read_and_process_logs()',
        statement => 'log4j_generic lines carried levels ltl does not recognise (NOTICE, AUDIT); those 1,906 lines were not counted',
    },
    unreadable_dirs => {
        category  => 'data anomaly',
        producer  => 'read_and_process_logs()',
        statement => '2 directories could not be read and were skipped in recursive selection',
        evidence  => [ 'logs/archive/2025-04', 'logs/archive/2025-03' ],
    },
    udm_not_numbers => {
        category  => 'data anomaly',
        producer  => 'emit_udm_skipped_capture_notices()',
        statement => "-udm 'heap': 37 captured values were not numbers and were skipped",
        evidence  => ["first: 'n/a' at line 2,210"],
    },
    unclassified => {
        category  => 'data anomaly',
        producer  => 'emit_classification_percentage_notices()',
        statement => "1,204 included lines (2.4%) matched neither the success nor the failure classification - the percentages exclude them",
        remedy    => "investigate the format's detection with --help formats",
    },
    approximate_percentiles => {
        category  => 'figure caveat',
        producer  => 'bin_consolidation_notice()',
        statement => '14 consolidated message rows combine durations counted in bins, so their percentiles are approximate',
        remedy    => 'use -mdm raw for exact percentiles',
    },
    numeric_filter_excluded => {
        category  => 'figure caveat',
        producer  => 'read_and_process_logs()',
        statement => '8,112 lines carried no duration and were excluded by -dmin',
    },
    not_a_ledger => {
        category  => 'figure caveat',
        producer  => 'emit_classification_percentage_notices()',
        statement => 'the success/failure percentages cover only operations the log records: a matched format is not an event ledger, so operations can be missing from the figure entirely',
        remedy    => 'see --help formats for what each format classifies',
    },
    filtered_subset => {
        category  => 'figure caveat',
        producer  => 'planned: #454 statistics describe a filtered subset',
        statement => 'the statistics describe the 31,880 lines -i kept, not the whole log',
    },
    sort_fallback => {
        category  => 'decision taken for you',
        producer  => 'sort_fallback_to_occurrences()',
        statement => 'the requested sort (-so/--sort-on cv) could not be produced from the duration values in this run - the messages table is ordered by occurrences',
    },
    timestamp_precision => {
        category  => 'decision taken for you',
        producer  => 'resolve_timestamp_precision()',
        statement => "timestamps are shown to the second: millisecond precision was asked for, and the log's timestamps carry seconds",
    },
    byte_notation => {
        category  => 'decision taken for you',
        producer  => 'resolve_byte_notation()',
        statement => "the log formats of this run declare different byte notations (SI and IEC); SI is used",
        remedy    => 'use -bn si or -bn iec to choose',
    },
    read_path_fallback => {
        category  => 'decision taken for you',
        producer  => 'read_path_fall_back()',
        statement => 'the faster read path could not be prepared, so large files are read with the standard path, which is slower',
    },
    skipped_final_pass => {
        category  => 'decision taken for you',
        producer  => 'report_skipped_final_pass()',
        statement => 'the final consolidation pass was skipped over 48,210 messages: grouping at 85% similarity absorbed almost none of this data as it was read',
        evidence  => ['this data clusters below 62% similarity'],
        remedy    => 'where the messages differ mainly by an identifier such as a UUID, mask it with --mask',
    },
    index_unreadable => {
        category  => 'runtime condition',
        producer  => 'read_index_file()',
        statement => 'ltl-index.csv exists but is unreadable; read-back skipped',
    },
    stall => {
        category  => 'guidance',
        producer  => 'planned: #664 stall detection',
        statement => 'requests were held from 01:05 to 01:12 and released together at 01:13: a stall',
        evidence  => ['412 requests released at 01:13, P50 duration 8.7 hours'],
        remedy    => 'look closer with -st 01:00 -et 01:20 -bs 1',
    },
    timeout_cluster => {
        category  => 'guidance',
        producer  => 'planned: #193 timeout clusters',
        statement => '1,180 failed requests cluster just above 60 s, a round timeout boundary',
        remedy    => 'see them with -i " 5[0-9][0-9] " -dmin 59s -hg',
    },
    bimodal => {
        category  => 'guidance',
        producer  => 'planned: a detected pattern (bimodality)',
        statement => 'POST .../QueryStreamEntriesWithData has two populations of durations (bimodality coefficient 0.71): about 1 s and about 5.5 s',
        remedy    => 'sort by it with -so bimodality_coef, or isolate it with -i QueryStreamEntries -hg',
    },
    gc_scenario => {
        category  => 'guidance',
        producer  => 'planned: #258 scenario knowledge set',
        statement => 'the input includes G1 GC logs: pause durations and heap after collection are read as metrics',
        remedy    => 'try -hg -hm bytes on the GC log alone',
    },
);

return {
    minimal => [ $notice{deprecation} ],
    typical => [ @notice{qw(deprecation two_producers impossible_dates approximate_percentiles sort_fallback timestamp_precision stall)} ],
    options => [ @notice{qw(deprecation udm_unit_is_function pattern_file_missing min_over_max)} ],
    heavy   => [ @notice{ grep { $_ ne 'top_zero' && $_ ne 'discard_switches_off' } sort keys %notice } ],
    notice  => \%notice,
};
