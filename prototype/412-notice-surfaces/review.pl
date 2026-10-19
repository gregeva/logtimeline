#!/usr/bin/env perl
# Review the stage 1 prototypes one option at a time: each option is
# introduced, run in this terminal, and followed by a prompt for feedback,
# which is saved with the option's id and the exact command that drew it.
#
#   perl review.pl                resume at the first option with no feedback
#   perl review.pl --list         the options and whether each has feedback
#   perl review.pl --from box-read  start at an option and go on from there
#   perl review.pl --only box-read  one option alone
#   perl review.pl --all          every option, from the first
#   perl review.pl --round 6      an earlier round's options (default: 7)
#   perl review.pl --round light  the light-background evaluation (light-review.pl runs this)
#   perl review.pl --round linux  the platform validation on Linux (feedback/stage1-linux.jsonl)
#   perl review.pl --round windows  the same in Windows Terminal (feedback/stage1-windows.jsonl)
#
# An option whose script is '-' runs nothing: it takes remarks alone (round
# 4's closing entry, for remarks against the contract).
#
# Feedback is appended to feedback/stage1.jsonl (round 1) or
# feedback/stage1-roundN.jsonl (round N), one JSON object per entry: the
# option's id, title, the command run, the time, and the text. An option
# reviewed again gets a second entry; nothing is overwritten.

use strict;
use warnings;
use utf8;
use FindBin;
use Getopt::Long;
use JSON::PP;
use POSIX qw(strftime);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
$| = 1;

my %opt;
$opt{round} = 7;
GetOptions( \%opt, 'list', 'from=s', 'only=s', 'all', 'round=s' ) or die "bad options\n";

my $dir  = $FindBin::Bin;
my $file = "$dir/feedback/stage1" . ( $opt{round} eq '1' ? '' : $opt{round} =~ /^\d+$/ ? "-round$opt{round}" : "-$opt{round}" ) . '.jsonl';
my $json = JSON::PP->new->canonical->utf8;

# id, prototype, arguments, what the option is, what to look at, what to do.
my %rounds;
$rounds{1} = [
    [ 'P1-a', 'p1-deferred-notices.pl', '--form lines --style ltl',     'Deferred notices as prefixed lines, ltl look',      'one notice to a line, led by glyph and category name; continuation aligned under the text' ],
    [ 'P1-b', 'p1-deferred-notices.pl', '--form lines --style new',     'Deferred notices as prefixed lines, new style',     'a coloured bar down the left of every row; bold category label' ],
    [ 'P1-c', 'p1-deferred-notices.pl', '--form boxes --style ltl',     'One box per category, ltl look',                    "grey light-rule frames from ltl's box set; category and how to read it set in the top edge" ],
    [ 'P1-d', 'p1-deferred-notices.pl', '--form boxes --style new',     'One box per category, new style',                   'rounded corners, frame in the category colour, bold heading' ],
    [ 'P1-e', 'p1-deferred-notices.pl', '--form sections --style ltl',  'Headed sections, ltl look',                         "upper-case heading and rule per category, bullets, as ltl's messages tables are headed" ],
    [ 'P1-f', 'p1-deferred-notices.pl', '--form sections --style new',  'Headed sections, new style',                        'coloured bar on the heading, a rail down the notices' ],
    [ 'P1-g', 'p1-deferred-notices.pl', '--form lines --set minimal',   'A single deprecation, the smallest surface',        'what one notice on its own looks like: two rows' ],
    [ 'P1-h', 'p1-deferred-notices.pl', '--form sections --glyphs emoji', 'Headed sections with emoji glyphs',               'emoji in place of the text symbols: recognition, and whether they sit in line in this terminal' ],
    [ 'P1-i', 'p1-deferred-notices.pl', '--form sections --glyphs ascii', 'Headed sections with ASCII marks',                'no symbols beyond ASCII' ],
    [ 'P1-j', 'p1-deferred-notices.pl', '--form boxes --bg light',      'One box per category on a light background',        'the colours chosen for a light background (best seen in a light terminal profile)' ],
    [ 'P2-a', 'p2-preread-choice.pl',   '--form boxes --style ltl',     'Option notices, then a timed question below them',  'the countdown row under the block: [Y/n] and the seconds left, redrawn each second; press y, n, Enter, or wait' ],
    [ 'P2-b', 'p2-preread-choice.pl',   '--form sections --style new',  'Option notices as a section, question below, new style', 'the same question under a lighter block' ],
    [ 'P2-c', 'p2-preread-choice.pl',   '--frame shared --style ltl',   'Notices and question in one frame, ltl look',       'the question inside the frame, under a divider; the frame closes once answered' ],
    [ 'P2-d', 'p2-preread-choice.pl',   '--frame shared --style new',   'Notices and question in one frame, new style',      'as P2-c in the new style' ],
    [ 'P3-a', 'p3-progress-choice.pl',  '--place above',                'Question over the progress line: notice above, stays', 'the progress row gives way to the notice and question; once answered they stay and progress resumes below' ],
    [ 'P3-b', 'p3-progress-choice.pl',  '--place inplace',              'Question in the progress row itself',               'one row replaces the progress line; once answered it is erased and the answer is recorded under the completion row' ],
    [ 'P3-c', 'p3-progress-choice.pl',  '--place box --style ltl',      'Boxed notice over the progress line, ltl look',     'a box and the question; once answered both collapse to one row' ],
    [ 'P3-d', 'p3-progress-choice.pl',  '--place box --style new',      'Boxed notice over the progress line, new style',    'as P3-c in the new style' ],
    [ 'P4-a', 'p4-pattern-choice.pl',   '--selector list --style ltl',  'Two-stage choice, vertical list, ltl look',         'press y within 5 s to reach stage two; arrows move the highlight, its effect shows beneath; Enter or Esc' ],
    [ 'P4-b', 'p4-pattern-choice.pl',   '--selector list --style new',  'Two-stage choice, vertical list, new style',        'as P4-a in the new style (press y within 5 s)' ],
    [ 'P4-c', 'p4-pattern-choice.pl',   '--selector keys --form lines', 'Two-stage choice, one row chosen by a digit',       'press y within 5 s; the views on one row, a single digit chooses' ],
    [ 'P4-d', 'p4-pattern-choice.pl',   '--selector list',              'Two-stage choice, declined at stage one',           'let the 5 s run out, or press n: what stays on screen when the analyst does not engage' ],
    [ 'P5-a', 'p5-notice-browser.pl',   '--mode inline --style ltl',    'Inline list of 25 notices with a detail pane, ltl look', 'a window below the cursor; arrows, PgUp/PgDn, 1-6 jump to a category; q leaves and it collapses to one row' ],
    [ 'P5-b', 'p5-notice-browser.pl',   '--mode inline --style new',    'Inline list with a detail pane, new style',         'as P5-a in the new style' ],
    [ 'P5-c', 'p5-notice-browser.pl',   '--mode fullscreen --style ltl', 'Full-screen list with category tabs, ltl look',    'the alternate screen: tabs (Tab, arrows), list and detail side by side from 120 columns; q gives the screen back' ],
    [ 'P5-d', 'p5-notice-browser.pl',   '--mode fullscreen --style new', 'Full-screen list with category tabs, new style',   'as P5-c in the new style' ],
    [ 'P6-a', 'p6-modal-choice.pl',     '--moment read --screen inline', 'Modal during the read, drawn below the cursor',    'a dialog with two buttons and a countdown over the progress moment; arrows or Tab, Enter, y/n' ],
    [ 'P6-b', 'p6-modal-choice.pl',     '--moment read --screen alt',   'Modal during the read, on the alternate screen',    'the dialog centred on a clear screen; the run reappears once answered' ],
    [ 'P6-c', 'p6-modal-choice.pl',     '--moment after --screen inline --style new', 'Modal once a pattern is found, below the cursor, new style', 'the pattern choice as a dialog rather than a question row' ],
    [ 'P6-d', 'p6-modal-choice.pl',     '--moment after --screen alt --style new',    'Modal once a pattern is found, alternate screen, new style', 'as P6-c, centred on a clear screen' ],

];
# Round 2 was reviewed from the scripts as they stood at commit 4d1218c; its
# commands are recorded with its feedback in feedback/stage1-round2.jsonl.
# Round 3: one surface for asking during the run (the modal, its compact box
# form), the panel and the browser, from round 2's feedback. Its scripts
# (surfaces/*.pl, notices/round2.pl) are at commit 4bef110; round 4 replaced
# them with show.pl and notices/inputs.pl.
$rounds{3} = [
    [ 'panel',          'surfaces/panel.pl', '',                                  'Panel: one box round all the notices',             'categories divided by a blank row; NOTICES in the dim of its count; each category headed once with how to read it' ],
    [ 'panel-one',      'surfaces/panel.pl', '--set minimal',                     'Panel with a single notice',                       'the box drawn for one notice too' ],
    [ 'modal-read',     'surfaces/ask.pl',   '--moment read',                     'Modal over the run, during the read (memory)',     'the lead surface: the dialog centred over the dimmed run; the top edge carries the category and how to read it; once answered it leaves no trace' ],
    [ 'modal-preread',  'surfaces/ask.pl',   '--moment preread',                  'The same modal before the read (four option notices)', 'the same call with other notices and buttons' ],
    [ 'modal-pattern',  'surfaces/ask.pl',   '--moment pattern',                  'The same modal once a pattern is found (views)',   'focus Look at the views (← or Tab) and Enter: the dialog grows to the views in three columns, what, options and why' ],
    [ 'modal-inline',   'surfaces/ask.pl',   '--moment read --screen inline',     'The modal below the cursor (the fallback)',        'the same dialog in the rows below the cursor, erased once answered' ],
    [ 'modal-record',   'surfaces/ask.pl',   '--moment read --record',            'The modal, the caller asking for a record',        'with record set, the notice and the answer stay as inline text in the ltl look where the dialog was' ],
    [ 'box-read',       'surfaces/ask.pl',   '--moment read --surface box',       'The compact form: a box below the cursor, during the read', 'the question on the last row inside the frame; the top edge with how to read the category' ],
    [ 'box-preread',    'surfaces/ask.pl',   '--moment preread --surface box',    'The compact form before the read (four notices)',  'the top edge: category, count, how to read it' ],
    [ 'box-pattern',    'surfaces/ask.pl',   '--moment pattern --surface box',    'The compact form once a pattern is found',         'press y: the box grows to the views, what, options and why; the why wraps in its column when the terminal is narrow' ],
    [ 'browser-alt',    'surfaces/browser.pl', '',                                'Notice browser over the dimmed run',               'rounded corners; every tab named (a second row when they do not fit); the detail heading in its colour, no block; 7 then Enter on the ◇ notice opens the views; q closes, leaving no trace' ],
    [ 'browser-inline', 'surfaces/browser.pl', '--screen inline',                 'Notice browser below the cursor (the fallback)',   'the same box drawn below the cursor' ],
];
# Round 4: the three components against the contract (features/412-notice-
# surfaces.md § Surface framework contract), each with named inputs; the size
# tiers, the bullet glyph, the tall detail and the layered modal to be seen.
$rounds{4} = [
    [ 'panel',          'show.pl', 'panel',                                    'Panel with the typical set (7 notices)',            'title `notices · 7` dim; a light dash bullet in dim; blank rows between categories; `command usage warnings` on your options' ],
    [ 'panel-one',      'show.pl', 'panel --input deprecation',                'Panel with a single notice',                        'the box drawn for one notice; lower-case `notices` beside the upper-case category' ],
    [ 'bullets',        'show.pl', 'bullets',                                  'The bullet glyph sheet',                            'ten candidates, each in the panel\'s own context under a category heading; name the number to take forward (panel --bullet N shows it in full)' ],
    [ 'modal-read',     'show.pl', 'ask --input memory',                       'Modal over the run, during the read (memory)',      'the dimmed run keeps every row where it was, the progress row included; the size tier chosen from the content; Tab and Shift-Tab, ←→; underlined choice letters s/c; Esc continues; q/x quits; any other key stops the countdown and nothing says so' ],
    [ 'modal-preread',  'show.pl', 'ask --input preread',                      'The same modal before the read (four option notices)', 'the same call with other notices and buttons; the key bar reads the same' ],
    [ 'modal-pattern',  'show.pl', 'ask --input pattern',                      'The same modal once a pattern is found, with its options list', 'press l (or Tab to Look at the options, Enter): the list in three columns headed What? How? Why?; the dialog was sized for both stages up front and does not change size; 1-3, ↑↓, Enter; Esc continues as planned' ],
    [ 'box-read',       'show.pl', 'ask --input memory --form box',            'The compact form: a box below the cursor, during the read', 'the choices on the question row with their letters underlined, the default bright with the countdown; the key bar is the letters only; quitting is off here by default' ],
    [ 'box-pattern',    'show.pl', 'ask --input pattern --form box',           'The compact form once a pattern is found',          'a blank row before the question; press l: the options list at full width' ],
    [ 'modal-inline',   'show.pl', 'ask --input memory --placement inline',    'The modal below the cursor (the fallback)',         'the same dialog drawn into rows below the cursor; erased once answered' ],
    [ 'browser',        'show.pl', 'browser',                                  'Notice browser over the dimmed run (25 notices)',   'sized before drawing for its tallest detail: move to the GUIDANCE notice on GetDateAndTime, its detail holds ltl\'s histogram with the percentile legend; Enter opens the options as a modal layered over the browser; Esc closes it and the browser is back as it was; a 15 s countdown to closing stops at the first key' ],
    [ 'browser-inline', 'show.pl', 'browser --placement inline',               'Notice browser below the cursor (the fallback)',     'the same browser below the cursor; the layered modal is drawn within its rows; closing erases it' ],
    [ 'contract',       '-',       '',                                         'Remarks against the contract',                      'anything that applies across views, against a line of features/412-notice-surfaces.md § Surface framework contract rather than a rendering' ],
];

# Round 5: round 4's corrections (padding, the bullet in the category colour,
# centred buttons, the growing column gap, the dense list in a wider tier, the
# bytes histogram) and the single-notice comparison.
$rounds{5} = [
    [ 'panel',          'show.pl', 'panel',                                    'Panel with the typical set (7 notices)',            'the chosen bullet in the category colour; two characters of padding inside the sides' ],
    [ 'panel-one',      'show.pl', 'panel --input deprecation',                'Panel with a single notice, headed inside',         'the standard form: the category heading on its own row inside the box' ],
    [ 'panel-one-edge', 'show.pl', 'panel --input deprecation --edge',         'Panel with a single notice, the category in the top edge', 'for comparison: glyph, category, count and how-to-read in the top edge, the notice alone inside, one row shorter' ],
    [ 'modal-read',     'show.pl', 'ask --input memory',                       'Modal over the run, during the read (memory)',      'padding inside the sides; no hanging indent; an empty row above and below the question; the buttons centred on their labels, the countdown beside the default outside the centring' ],
    [ 'modal-preread',  'show.pl', 'ask --input preread',                      'The same modal before the read (four option notices)', 'missed last round: press any key to stop the countdown first; the same call with other notices and buttons' ],
    [ 'modal-pattern',  'show.pl', 'ask --input pattern',                      'The same modal once a pattern is found, with its options list', 'press l: the list takes the wider tier for its dense content; the column gap grows with the width' ],
    [ 'box-read',       'show.pl', 'ask --input memory --form box',            'The compact form: a box below the cursor, during the read', 'padding inside the sides and an empty row above and below' ],
    [ 'box-pattern',    'show.pl', 'ask --input pattern --form box',           'The compact form once a pattern is found',          'press l: the list at full width with the column gap grown to the room' ],
    [ 'modal-inline',   'show.pl', 'ask --input memory --placement inline',    'The modal below the cursor (the fallback)',         'the same dialog drawn below the cursor' ],
    [ 'browser',        'show.pl', 'browser',                                  'Notice browser over the dimmed run (25 notices)',   'each pane padded: an empty row above and below, two characters at the sides; press 7 for GUIDANCE: the detail holds ltl\'s duration and bytes histograms side by side after an empty row; Enter opens the options list layered over the browser, padded the same' ],
    [ 'browser-inline', 'show.pl', 'browser --placement inline',               'Notice browser below the cursor (the fallback)',     'the same browser below the cursor' ],
    [ 'contract',       '-',       '',                                         'Remarks against the contract',                      'anything that applies across views, against a line of features/412-notice-surfaces.md § Surface framework contract rather than a rendering' ],
];

# Round 6: round 5's corrections, shown only where a change touched a view
# (the round procedure's fifth step). Validated views and mechanisms are not
# shown again.
$rounds{6} = [
    [ 'panel',          'show.pl', 'panel',                                    'Panel with the typical set (7 notices)',            'one cell of padding inside each side, no empty rows: the box that stays on screen' ],
    [ 'modal-pattern',  'show.pl', 'ask --input pattern',                      'Modal once a pattern is found, with its options list', 'two cells inside each side, counted; press l: the list pane with an empty row above and below its content' ],
    [ 'browser',        'show.pl', 'browser',                                  'Notice browser over the dimmed run (25 notices)',   'the tabs inside the list pane with an empty row above and below, no rule under them; counts in parentheses; press 7: ltl\'s histograms at their own size side by side (a terminal of 160 to 180 columns), an empty row before the options row; Enter and a choice: the empty row before `chosen:`' ],
    [ 'contract',       '-',       '',                                         'Remarks against the contract',                      'anything that applies across views, against a line of features/412-notice-surfaces.md § Surface framework contract rather than a rendering' ],
];

# Round 7: one view, the options list's pane rows (round 6's correction).
$rounds{7} = [
    [ 'modal-pattern',  'show.pl', 'ask --input pattern',                      'Modal once a pattern is found, with its options list', 'press l: the list pane with an empty row above and below its content, an empty row between the list and the highlighted option\'s effect, the body pane closed by an empty row before the rule' ],
    [ 'contract',       '-',       '',                                         'Remarks against the contract',                      'anything that applies across views' ],
];

# The light background: the validated framework once more, from a terminal
# with a light profile, every component in each of its forms once; the
# colours are the darkest step of each category colour's light gradient, the
# frame grey 244, the text black (NoticeProto::style_for). Feedback to
# feedback/stage1-light.jsonl.
$rounds{light} = [
    [ 'panel',          'show.pl', 'panel --bg light',                         'Panel with the typical set, light background',      'the category colours on light: are the six told apart, and readable, with the bullets in the same colours' ],
    [ 'panel-one',      'show.pl', 'panel --input deprecation --bg light',     'Panel with a single notice, light background',      'the edge form with the frame in the category colour' ],
    [ 'modal-read',     'show.pl', 'ask --input memory --bg light',            'Modal during the read, light background',           'the dimmed run under the dialog; the frame colour; the highlighted button in reverse video; the countdown dim' ],
    [ 'modal-pattern',  'show.pl', 'ask --input pattern --bg light',           'Modal with its options list, light background',     'press l: the headings, the highlighted option in reverse video, the dim why column against the selected one in colour' ],
    [ 'box-read',       'show.pl', 'ask --input memory --form box --bg light', 'The compact box, light background',                 'the question row with the default bright: on light that is bold black' ],
    [ 'browser',        'show.pl', 'browser --bg light',                       'Notice browser, light background',                  'tabs with the selected one as a coloured block; the list highlight; press 7 for the histograms, which keep ltl\'s own colours' ],
    [ 'contract',       '-',       '',                                         'Remarks against the light background',              'anything that applies across views: the category sheet\'s light colours are the contract\'s proposed line for it' ],
];

# The platform validation (feature doc § Prototyping): the validated framework
# once more in a Linux terminal and in Windows Terminal, every component in
# each of its forms once, with the keys and sequences that could differ by
# platform exercised in each view. The outcome is acceptance or a short list
# of adaptations, not a port. One list, two feedback files.
$rounds{platform} = [
    [ 'panel',          'show.pl', 'panel',                                    'Panel with the typical set',                        'the six category glyphs and the bullet: present, one cell wide, the colours as on macOS; rounded corners' ],
    [ 'panel-one',      'show.pl', 'panel --input deprecation',                'Panel with a single notice (edge form)',            'the glyph and text in the top edge; the frame in the category colour' ],
    [ 'modal-read',     'show.pl', 'ask --input memory',                       'Modal during the read',                             'the alternate screen: the dimmed run under the dialog, rows unmoved; try ← → Tab and Shift-Tab, then any key to stop the countdown, then Esc: the run is back as it was' ],
    [ 'modal-quit',     'show.pl', 'ask --input memory',                       'Modal, quitting',                                   'press x: the run stops cleanly with the terminal restored (no raw mode left behind, the cursor visible, typing echoes)' ],
    [ 'modal-pattern',  'show.pl', 'ask --input pattern',                      'Modal with its options list',                       'press l, then ↓ j k and a digit; Enter chooses; the two-stage height change' ],
    [ 'modal-inline',   'show.pl', 'ask --input memory --placement inline',    'Modal below the cursor (the fallback)',             'drawn under the cursor and erased on Esc, the rows above untouched' ],
    [ 'box-read',       'show.pl', 'ask --input memory --form box',            'The compact box',                                   'the choice letters, in either case; Esc takes the default' ],
    [ 'browser',        'show.pl', 'browser',                                  'Notice browser',                                    'tabs with ← → and digits; press 7 for the histograms at ltl\'s size (needs 160 columns or more); Enter on an item for the layered list, Esc back, Esc close' ],
    [ 'browser-inline', 'show.pl', 'browser --placement inline',               'Notice browser below the cursor',                   'the same, drawn under the cursor and erased on close' ],
    [ 'light',          'show.pl', 'panel --bg light',                         'Panel, light colours (switch to a light profile if you have one)', 'the light sheet on this platform; skip with a remark if no light profile is at hand' ],
    [ 'contract',       '-',       '',                                         'Remarks for this platform',                         'anything that applies across views: a key that did not decode, a sequence that did not take, a glyph missing or two cells wide, the terminal and font used' ],
];
$rounds{$_} = $rounds{platform} for qw(linux windows);

my @options = @{ $rounds{ $opt{round} } or die "no round $opt{round}\n" };
my %index = map { $options[$_][0] => $_ } 0 .. $#options;

my %reviewed;
if ( open my $fh, '<', $file ) {
    while (<$fh>) {
        my $e = eval { $json->decode($_) } or next;
        $reviewed{ $e->{option} }++;
    }
}

if ( $opt{list} ) {
    printf "%-15s %-9s %s\n", $_->[0], $reviewed{ $_->[0] } ? "reviewed" : '', $_->[3] for @options;
    exit 0;
}

my @queue;
if ( $opt{only} ) {
    defined $index{ $opt{only} } or die "no option '$opt{only}' (see --list)\n";
    @queue = ( $index{ $opt{only} } );
}
elsif ( $opt{from} ) {
    defined $index{ $opt{from} } or die "no option '$opt{from}' (see --list)\n";
    @queue = ( $index{ $opt{from} } .. $#options );
}
elsif ( $opt{all} ) {
    @queue = ( 0 .. $#options );
}
else {
    @queue = grep { !$reviewed{ $options[$_][0] } } 0 .. $#options;
    print "Every option has feedback. Use --all, --from or --only to review again.\n" and exit 0 unless @queue;
}

-t STDIN && -t STDOUT or die "review.pl runs in a terminal: it shows each option and waits for feedback\n";

my $pos = 0;
while ( $pos < @queue ) {
    my ( $id, $script, $args, $title, $look ) = @{ $options[ $queue[$pos] ] };
    my $cmd = $script eq '-' ? '(no command: remarks only)' : "perl $script $args";
    print "\e[H\e[2J";
    print "\e[1m$id  $title\e[0m   \e[2m(" . ( $queue[$pos] + 1 ) . ' of ' . scalar(@options) . ")\e[0m\n";
    print "\e[2m$cmd\e[0m\n";
    print "Look at: $look\n\n";
    print "\e[2mEnter runs it · s skips · b goes back · q quits\e[0m ";
    my $go = <STDIN> // exit 0;
    chomp $go;
    if ( $go eq 'q' ) { last }
    if ( $go eq 's' ) { $pos++; next }
    if ( $go eq 'b' ) { $pos-- if $pos > 0; next }

    if ( $script ne '-' ) {
        print "\e[H\e[2J";
        system( $^X, "$dir/$script", split( ' ', $args ) );
        system( 'stty', 'sane' );    # in case the prototype was stopped mid-prompt
    }

    while (1) {
        print "\n\e[1m── feedback for $id ($title) ──\e[0m\n";
        print "\e[2mtype your feedback; an empty line ends it.  r alone reruns · s alone skips without saving · q alone quits\e[0m\n";
        my @lines;
        while ( defined( my $l = <STDIN> ) ) {
            chomp $l;
            last if $l eq '';
            push @lines, $l;
        }
        if ( @lines == 1 && $lines[0] eq 'r' && $script ne '-' ) {
            print "\e[H\e[2J";
            system( $^X, "$dir/$script", split( ' ', $args ) );
            system( 'stty', 'sane' );
            next;
        }
        last if @lines == 1 && $lines[0] eq 's';
        if ( @lines == 1 && $lines[0] eq 'q' ) { $pos = @queue; last }
        if (@lines) {
            save( $id, $title, $cmd, join( "\n", @lines ) );
            print "\e[32msaved for $id\e[0m\n";
        }
        else {
            print "\e[2mnothing typed; nothing saved for $id\e[0m\n";
        }
        last;
    }
    $pos++;
    if ( $pos < @queue ) {
        print "\e[2mEnter goes on to the next option\e[0m ";
        my $x = <STDIN>;
    }
}
print "\nFeedback is in $file\n";

sub save {
    my ( $id, $title, $cmd, $text ) = @_;
    mkdir "$dir/feedback" unless -d "$dir/feedback";
    open my $fh, '>>', $file or die "cannot write $file: $!\n";
    print $fh $json->encode( {
        option   => $id,
        title    => $title,
        command  => $cmd,
        time     => strftime( '%Y-%m-%dT%H:%M:%S%z', localtime ),
        feedback => $text,
    } ), "\n";
    close $fh;
    $reviewed{$id}++;
}
