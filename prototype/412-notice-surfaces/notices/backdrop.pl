# What the terminal shows before a surface is drawn over it: the tail of a
# previous run's summary, the prompt, ltl's title banner (read from the ltl
# source) and the rows a run prints before and after its progress line. Fixed
# content, so that a dimmed copy of the run has text to dim (architect,
# 2026-10-19: a backdrop of two rows leaves the screen black).

use utf8;

my $green = "\e[92m";
my $dim   = "\e[2m";
my $reset = "\e[0m";

return {
    # the previous run's tail, as the analyst's terminal would hold it
    before_prompt => [
        '  ─────────────────────────────────────────   ',
        '  Category                            Total      These file(s) were processed with analysis including results between',
        '  ─────────────────────────────────────────      2025-05-04 00:00 and 2025-05-04 23:59',
        '  2xx Success                1,312,884 (92%)   ',
        '  4xx Client error              88,102  (6%)      [√] access_log.2025-05-04.txt                                   [1]',
        '  5xx Server error              29,641  (2%)   ',
        '  ─────────────────────────────────────────      Log Formats',
        '  LINES READ                      1,430,627   ',
        '  LINES INCLUDED                  1,430,627      1 access_combined_duration',
        '  TOTAL TIME                     21.4 sec    ',
        '  MAXIMUM MEMORY USED             1.9 GB    ',
        '  ─────────────────────────────────────────   ',
        '',
    ],
    prompt => sub { my ($cmd) = @_; return ( "$dim\$ $cmd$reset", '' ) },
    # the rows before the progress line
    scanning => [
        "${dim}1 file, 2.1 GB: access_log.2025-05-05.txt$reset",
        "${dim}format detected from 3 samples: access_combined_duration$reset",
        '',
    ],
    # the progress line's text at a percentage
    progress => sub {
        my ($pct) = @_;
        my $line = int( 14306.78 * $pct );
        1 while $line =~ s/^(\d+)(\d{3})/$1,$2/;
        return "Processing $pct% line $line, 856.2k lines/sec: access_log.2025-05-05.txt";
    },
    completed => [ "${green}Processing completed.$reset", "${green}Calculating statistics completed.$reset" ],
};
