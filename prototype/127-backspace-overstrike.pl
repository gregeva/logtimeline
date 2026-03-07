#!/usr/bin/env perl
# Prototype: Backspace-overstrike text decoration for help output
#
# Backspace overstrike is the traditional Unix approach used by man pages:
#   Underline: _\bX  (underscore, backspace, character)
#   Bold:      X\bX  (character, backspace, character)
#
# These sequences are natively understood by:
#   - less (default behavior, no flags needed)
#   - more (most implementations)
#   - Terminal emulators (render as underline/bold)
#   - Piped to cat/file (backspaces are stripped or ignored gracefully)
#
# This avoids ANSI escape sequences entirely, so no TTY detection is needed.
#
# Auto-pager: the help output is piped through a pager automatically,
# so the user sees paginated, decorated text. Pager search order:
#   1. $PAGER environment variable (user preference)
#   2. 'more' (available on all platforms: Unix, Windows cmd, PowerShell)
#
# If the pager fails to launch, output falls back to plain stdout.

use strict;
use warnings;

# Apply underline via backspace overstrike: _\bX for each visible character
sub bs_underline {
    my ($text) = @_;
    return join('', map { "_\b$_" } split(//, $text));
}

# Apply bold via backspace overstrike: X\bX for each visible character
sub bs_bold {
    my ($text) = @_;
    return join('', map { "$_\b$_" } split(//, $text));
}

# --- Demo output ---

my $wrap_width = 80;
my $opt_col    = 4;
my $desc_col   = 47;

# Section heading: underlined, uppercase (matches ltl's $heading->)
my $heading = sub {
    my ($text) = @_;
    return "\n" . bs_underline($text) . "\n\n";
};

# Subsection heading: underlined (matches ltl's $subheading->)
my $subheading = sub {
    my ($text) = @_;
    return "\n  " . bs_underline($text) . "\n\n";
};

# Option formatter (simplified from ltl)
my $short_col = 7;
my $opt = sub {
    my ($flags, $desc) = @_;
    my $formatted;
    if ($flags =~ /^(\S+,)\s+(.+)$/) {
        my ($short, $long) = ($1, $2);
        my $short_pad = $short_col - length($short);
        $short_pad = 1 if $short_pad < 1;
        $formatted = $short . " " x $short_pad . $long;
    } elsif ($flags =~ /^\s+(--\S.*)$/) {
        $formatted = " " x $short_col . $1;
    } else {
        $formatted = $flags;
    }
    my $padding = $desc_col - $opt_col - length($formatted);
    $padding = 2 if $padding < 2;
    return " " x $opt_col . $formatted . " " x $padding . $desc . "\n";
};

# Example section header with bold column names
my $ex_desc_col = 68;
my $ex_heading = sub {
    my $cmd_header  = bs_underline("Command");
    my $desc_header = bs_underline("Description");
    my $header_pad  = $ex_desc_col - $opt_col - 7;  # 7 = visible length of "Command"
    $header_pad = 2 if $header_pad < 2;
    return " " x $opt_col . $cmd_header . " " x $header_pad . $desc_header . "\n";
};

my $ex = sub {
    my ($cmd, $desc) = @_;
    my $padding = $ex_desc_col - $opt_col - length($cmd);
    $padding = 2 if $padding < 2;
    return " " x $opt_col . $cmd . " " x $padding . $desc . "\n";
};

# --- Print sample help output ---

my $out = "";

$out .= "LogTimeLine -- a command-line log analysis tool.\n";

$out .= $heading->("USAGE");
$out .= "    ltl [options] <logfile> [logfile2 ...]\n";

$out .= $heading->("OPTIONS");

$out .= $subheading->("Time & Buckets");
$out .= $opt->("-bs,  --bucket-size <N>",       "Set the width of each time bucket");
$out .= $opt->("-s,   --seconds",               "Interpret bucket size as seconds");
$out .= $opt->("-ms,  --milliseconds",          "Enable sub-second timestamp parsing");

$out .= $subheading->("Filtering");
$out .= $opt->("-i,   --include <regex>",       "Only process lines matching this pattern");
$out .= $opt->("-e,   --exclude <regex>",       "Discard lines matching this pattern");
$out .= $opt->("-h,   --highlight <regex>",     "Show matching lines as a separate colored bar");

$out .= $heading->("EXAMPLES");
$out .= $ex_heading->();
$out .= "\n";
$out .= $ex->("ltl access.log",                                  "Basic analysis");
$out .= $ex->("ltl -bs 5 access.log",                            "5-minute time buckets");
$out .= $ex->("ltl -i \"POST\" -e healthcheck access.log",       "Include POST, exclude health checks");
$out .= "\n";

$out .= $heading->("BONUS: BOLD DEMO");
$out .= "    This is normal text.\n";
$out .= "    This is " . bs_bold("bold text") . " in a sentence.\n";
$out .= "    This is " . bs_underline("underlined text") . " in a sentence.\n";
$out .= "\n";

# Auto-pipe through a pager
my $pager = $ENV{PAGER} || 'more';
if (open(my $pager_fh, '|-', $pager)) {
    print $pager_fh $out;
    close $pager_fh;
} else {
    # Pager unavailable — fall back to direct output (no decoration visible)
    print $out;
}
