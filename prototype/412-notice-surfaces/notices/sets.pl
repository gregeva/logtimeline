# Fixed example notice sets for the stage 1 prototypes.
#
# Wording follows the shipped producer named on each entry (the planned ones
# name their issue), split into the parts a notice carries: what it says, the
# evidence behind it, and the remedy. The values filled in (counts, files,
# operands) are illustrative. Categories are the inventory's placements in
# features/412-notice-surfaces.md, not yet confirmed.

use utf8;

my %notice = (
    deprecation => {
        category  => 'your options',
        producer  => 'print_deprecation_notices()',
        statement => '-uuid/--mask-uuid is deprecated',
        remedy    => 'use -m uuid/--mask uuid, which also masks IP addresses with -m ip, ipv4 or ipv6',
    },
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
    approximate_percentiles => {
        category  => 'figure caveat',
        producer  => 'bin_consolidation_notice()',
        statement => '14 consolidated message rows combine durations counted in bins, so their percentiles are approximate',
        remedy    => 'use -mdm raw for exact percentiles',
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
    stall => {
        category  => 'guidance',
        producer  => 'planned: #664 stall detection',
        statement => 'requests were held from 01:05 to 01:12 and released together at 01:13: a stall',
        evidence  => ['412 requests released at 01:13, P50 duration 8.7 hours'],
        remedy    => 'look closer with -st 01:00 -et 01:20 -bs 1',
    },
);

return {
    minimal => [ $notice{deprecation} ],
    typical => [ @notice{qw(deprecation two_producers impossible_dates approximate_percentiles sort_fallback timestamp_precision stall)} ],
};
