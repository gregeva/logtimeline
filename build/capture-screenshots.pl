#!/usr/bin/env perl
# capture-screenshots.pl: run ltl and write SVG screenshots of its output.
#
#   build/capture-screenshots.pl --name BASE [--background dark|light]
#       [--width N] [--height N] [--pad T[,R[,B[,L]]]] [--out-dir DIR] [--trace]
#       [--crop 'sections=A[,B] start=+-N end=+-N cols=L,R label=LABEL'] ...
#       -- <ltl options and input files>
#   build/capture-screenshots.pl --manifest FILE [--only NAME]
#       [--width N] [--height N] [--pad T[,R[,B[,L]]]] [--out-dir DIR] [--trace]
#
# ltl runs twice in the repository root: a probe run with -V section-layout for
# the rows each section printed, then the capture run whose output is drawn.
# Each crop is one image, BASE[-sections][-label].svg. A manifest lists one
# recipe per entry, in the same words. Specification and guidance:
# features/598-screenshot-capture.md, docs/process/screenshots.md.
use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case no_auto_abbrev);
use Text::ParseWords qw(shellwords);

my $repo_root = abs_path( File::Spec->catdir( dirname( abs_path(__FILE__) ), '..' ) );
my $ltl       = File::Spec->catfile( $repo_root, 'ltl' );

# Default terminal size (D11), padding (D18), manifest output (D10) and image
# cell geometry.
use constant DEFAULT_WIDTH  => 211;
use constant DEFAULT_HEIGHT => 53;
use constant DEFAULT_PAD    => '1,2';
use constant MANIFEST_OUT   => 'images/screenshots';
use constant CELL_WIDTH     => 7.2;
use constant CELL_HEIGHT    => 15;
use constant FONT_SIZE      => 12;
use constant BASELINE       => 0.76;    # of the cell height
use constant FONT_FAMILY    => "ui-monospace, 'SF Mono', SFMono-Regular, Menlo, Consolas, 'DejaVu Sans Mono', monospace";

# Options the tool sets on ltl, refused on the passed command line, and why.
my %refused = (
    'terminal-width'   => 'the tool sets the terminal size (--width)',
    'tw'               => 'the tool sets the terminal size (--width)',
    'terminal-height'  => 'the tool sets the terminal size (--height)',
    'th'               => 'the tool sets the terminal size (--height)',
    'light-background' => 'the tool sets the background (--background)',
    'lbg'              => 'the tool sets the background (--background)',
    'dark-background'  => 'the tool sets the background (--background)',
    'dbg'              => 'the tool sets the background (--background)',
    'verbose'          => 'diagnostic output does not belong in a screenshot',
    'V'                => 'diagnostic output does not belong in a screenshot',
    'pause'            => 'it waits for a key',
    'p'                => 'it waits for a key',
);

# Sections whose rows can carry message text or file names (D9).
my @sensitive = qw( messages messages-highlighted messages-overall summary-files );

# ---- Colour table ----------------------------------------------------------
# Per background: the 16 ANSI colours, text, bold and background colours, from
# the Terminal.app profiles "Clear Dark" and "Clear Light" (NSRGB components;
# the profiles' backgrounds are translucent and are drawn opaque). Different
# image backgrounds are changed here.
my %profiles = (
    dark => {
        ansi => [
            [0.208221729, 0.2588729473, 0.2961375701], [0.7050900829, 0.3357157301, 0.2811490643],
            [0.4241566305, 0.6672818346, 0.4415227165], [0.768627451, 0.6745098039, 0.3843137255],
            [0.4274509804, 0.5882352941, 0.7058823529], [0.7411764706, 0.4823529412, 0.8039215686],
            [0.4847151205, 0.7950070909, 0.805706814],  [0.8687835755, 0.8995435314, 0.9221739477],
            [0.2763328949, 0.3625957779, 0.4260602691], [0.8761320153, 0.424238529, 0.352688727],
            [0.4742048482, 0.7433320203, 0.4923891166], [0.8980392157, 0.7843137255, 0.4470588235],
            [0.4039215686, 0.7098039216, 0.9294117647], [0.8274509804, 0.537254902, 0.8980392157],
            [0.5177743662, 0.8677316158, 0.8797991071], [0.8995791401, 0.9354739751, 0.9618821747],
        ],
        text       => [0.8776108099, 0.8776108099, 0.8776108099],
        bold       => [0.9285714286, 0.9285714286, 0.9285714286],
        background => [0.09838771145, 0.1138777476, 0.152602838],
    },
    light => {
        ansi => [
            [0.1764705882, 0.2196078431, 0.2509803922], [0.7050900829, 0.3357157301, 0.2811490643],
            [0.4241566305, 0.6672818346, 0.4415227165], [0.768627451, 0.6745098039, 0.3843137255],
            [0.337254902, 0.5215686275, 0.6588235294],  [0.6784313725, 0.3921568627, 0.7450980392],
            [0.4117647059, 0.7764705882, 0.7882352941], [0.7568627451, 0.7843137255, 0.8],
            [0.3137254902, 0.3960784314, 0.4509803922], [0.8761320153, 0.424238529, 0.352688727],
            [0.4742048482, 0.7433320203, 0.4923891166], [0.8980392157, 0.7843137255, 0.4470588235],
            [0.2862745098, 0.6352941176, 0.8823529412], [0.8274509804, 0.537254902, 0.8980392157],
            [0.4666666667, 0.8823529412, 0.8980392157], [0.8470588235, 0.8823529412, 0.9058823529],
        ],
        text       => [0.1752953329, 0.2185359088, 0.2494220344],
        bold       => [0.1438920459, 0.1793862877, 0.2047393176],
        background => [1, 1, 1],
    },
);


my %opt;

# Errors are raised with die and reported once: per manifest entry, or for the
# whole ad hoc run.
sub fail { die "$_[0]\n" }

sub usage {
    return <<'END';
usage: build/capture-screenshots.pl --name BASE [--background dark|light]
           [--width N] [--height N] [--pad T[,R[,B[,L]]]] [--out-dir DIR] [--trace]
           [--crop 'sections=A[,B] start=+-N end=+-N cols=L,R label=LABEL'] ...
           -- <ltl options and input files>
       build/capture-screenshots.pl --manifest FILE [--only NAME]
           [--width N] [--height N] [--pad T[,R[,B[,L]]]] [--out-dir DIR] [--trace]

Runs ltl in the repository root and writes one SVG per crop, named
BASE[-sections][-label].svg: to DIR (default: the current directory), or for a
manifest to images/screenshots/. Without --crop, or for a crop without
sections, the image is the whole output. Input paths are relative to the
repository root. --pad sets the blank margin around every image, as CSS does:
rows top and bottom, cells left and right (default 1,2). A manifest lists one
run per entry: name, ltl, and optionally background, width, height, pad and
crops. Guidance: docs/process/screenshots.md.
END
}

# ---- Values ----------------------------------------------------------------

sub check_name {
    my ( $what, $value ) = @_;
    fail("$what '$value': letters, digits, '.', '_' and '-' only") unless $value =~ /^[A-Za-z0-9._-]+$/;
    return $value;
}

sub check_size {
    my ( $what, $value ) = @_;
    fail("$what '$value' is not a positive whole number") unless defined $value && $value =~ /^\d+$/ && $value > 0;
    return 0 + $value;
}

# Padding in CSS's shorthand (D18): top, right, bottom, left.
sub parse_pad {
    my ($value) = @_;
    fail("pad '$value': one to four whole numbers, 0 or more, separated by commas") unless $value =~ /^\d+(?:,\d+){0,3}$/;
    my @p = split /,/, $value;
    return @p == 1 ? [ @p[ 0, 0, 0, 0 ] ]
         : @p == 2 ? [ @p[ 0, 1, 0, 1 ] ]
         : @p == 3 ? [ @p[ 0, 1, 2, 1 ] ]
         :           [@p];
}

# A crop from its fields, given as key=value words on the command line or as
# the keys of a manifest crop: sections (D2), start and end (D2), cols (D3),
# label. Its image is BASE[-sections][-label].svg.
my @crop_keys = qw( sections start end cols label );
sub make_crop {
    my ( $base, %field ) = @_;
    $field{sections} = join ',', @{ $field{sections} } if ref $field{sections} eq 'ARRAY';    # a YAML list of sections
    my $spec = join ' ', map { "$_=$field{$_}" } grep { defined $field{$_} } @crop_keys;
    my %crop = ( spec => $spec, sections => [], start => 0, end => 0, left => 0, right => 0 );
    for my $key ( sort keys %field ) {
        my $value = $field{$key};
        $value = join ',', @$value if $key eq 'sections' && ref $value eq 'ARRAY';
        fail("crop '$spec': unknown key '$key' (" . join( ', ', @crop_keys ) . ')') unless grep { $_ eq $key } @crop_keys;
        fail("crop '$spec': $key has no value") unless defined $value && length $value;
        if ( $key eq 'sections' ) {
            $crop{sections} = [ split /,/, $value ];
        } elsif ( $key eq 'start' || $key eq 'end' ) {
            fail("crop '$spec': $key is a whole number of rows, not '$value'") unless $value =~ /^[+-]?\d+$/;
            $crop{$key} = 0 + $value;
        } elsif ( $key eq 'cols' ) {
            my ( $l, $r ) = $value =~ /^([+-]?\d+),([+-]?\d+)$/ or fail("crop '$spec': cols is L,R, not '$value'");
            @crop{qw(left right)} = ( 0 + $l, 0 + $r );
        } else {
            $crop{label} = check_name( "crop '$spec': label", $value );
        }
    }
    $crop{file} = join( '-', $base, ( @{ $crop{sections} } ? join( '+', @{ $crop{sections} } ) : () ),
        ( defined $crop{label} ? $crop{label} : () ) ) . '.svg';
    return \%crop;
}

sub crop_from_words {
    my ( $base, $words ) = @_;
    my %field;
    for my $pair ( split ' ', $words ) {
        my ( $key, $value ) = $pair =~ /^(\w+)=(.*)$/ or fail("crop '$words': '$pair' is not key=value");
        fail("crop '$words': $key is given twice") if exists $field{$key};
        $field{$key} = $value;
    }
    return make_crop( $base, %field );
}

# ---- Running ltl -----------------------------------------------------------

# Run ltl in the repository root with standard output and standard error each
# redirected to a file. Returns standard output; stops on a non-zero exit or a
# Perl warning on standard error. Files -o wrote are removed (D16).
sub run_ltl {
    my ( $scratch, $label, @argv ) = @_;
    my ( $out_file, $err_file ) = map { File::Spec->catfile( $scratch, "$label.$_" ) } qw(out err);
    local %ENV = %ENV;
    delete @ENV{qw( LTL_CONFIG FORCE_COLOR NO_COLOR )};
    my $cwd = getcwd();
    chdir $repo_root or fail("cannot enter $repo_root: $!");
    open my $saved_out, '>&', \*STDOUT or fail("cannot save standard output: $!");
    open my $saved_err, '>&', \*STDERR or fail("cannot save standard error: $!");
    open STDOUT, '>', $out_file or die "cannot write $out_file: $!\n";
    open STDERR, '>', $err_file or die "cannot write $err_file: $!\n";
    my $status = system { $^X } $^X, $ltl, @argv;
    open STDOUT, '>&', $saved_out or die "cannot restore standard output: $!\n";
    open STDERR, '>&', $saved_err or die "cannot restore standard error: $!\n";
    remove_output_files();
    chdir $cwd or fail("cannot return to $cwd: $!");
    my $err = slurp($err_file);
    print STDERR $err if length $err;
    fail( "ltl ($label run) exited with status " . ( $status >> 8 ) ) if $status != 0;
    fail("ltl ($label run) printed a Perl warning on standard error") if $err =~ / at \S+ line \d+/;
    return slurp($out_file);
}

# The files -o writes, named as ltl names them, at the top of the repository
# root (D16). Nothing else is deleted; the index file is ignored by git.
sub remove_output_files {
    opendir my $dh, $repo_root or fail("cannot read $repo_root: $!");
    for my $entry ( readdir $dh ) {
        next unless $entry =~ /LTL-.*(?:STATS.*|MESSAGES.*)\.csv$/ || $entry =~ /LTL-.*AGGREGATE\.yaml$/;
        my $path = File::Spec->catfile( $repo_root, $entry );
        unlink $path or fail("cannot remove $path: $!") if -f $path;
    }
    closedir $dh;
}

sub slurp {
    open my $fh, '<:raw', $_[0] or fail("cannot read $_[0]: $!");
    local $/;
    my $text = <$fh>;
    return $text // '';
}

# ---- One recipe ------------------------------------------------------------

# A recipe: name, background, width, height, pad (top, right, bottom, left),
# out_dir, ltl (argument list), crops. Runs ltl twice, resolves every crop,
# then writes every image; any error before the first image writes none.
sub run_recipe {
    my ($r) = @_;
    for my $arg ( @{ $r->{ltl} } ) {
        next unless $arg =~ /^--?([A-Za-z][\w-]*)(?:=.*)?$/;
        fail("'$arg' is not accepted on the ltl command line: $refused{$1}") if exists $refused{$1};
    }
    my %by_file;
    for my $crop ( @{ $r->{crops} } ) {
        fail("crops '$by_file{ $crop->{file} }{spec}' and '$crop->{spec}' both write $crop->{file}; a label tells them apart")
            if $by_file{ $crop->{file} };
        $by_file{ $crop->{file} } = $crop;
    }

    my $scratch = tempdir( CLEANUP => 1 );
    my @common  = ( '--terminal-width', $r->{width}, '--terminal-height', $r->{height},
                    ( $r->{background} eq 'light' ? '-lbg' : '-dbg' ), '--disable-progress' );
    my @probe_args   = ( @common, '-V', 'section-layout', @{ $r->{ltl} } );
    my @capture_args = ( @common, @{ $r->{ltl} } );
    print "ltl @capture_args\n";
    my $probe   = run_ltl( $scratch, 'probe', @probe_args );
    my $capture = run_ltl( $scratch, 'capture', @capture_args );
    if ( $opt{trace} ) {
        print "trace: probe run: ltl @probe_args\n";
        print "trace: capture run: ltl @capture_args\n";
        print "trace: ltl runs: 2\n";
    }

    # Section positions from the probe run's -V section-layout report.
    my ( @report_order, %section );
    my ($block) = $probe =~ /^=== section-layout ===\n(.*?)^=== END section-layout ===$/ms
        or fail('the probe run printed no section-layout report');
    my @lines = split /\n/, $block;
    shift @lines;    # header: name state start rows
    for my $line (@lines) {
        my ( $name, $state, $start, $rows ) = split /\t/, $line, -1;
        push @report_order, $name;
        $section{$name} = { state => $state, start => $start, rows => $rows, order => $#report_order };
    }

    # The probe run's rows with every -V range removed, as the capture run prints them.
    my ( $probe_rows, $depth ) = ( 0, 0 );
    for my $line ( split /\n/, $probe ) {
        if ( $line =~ /^=== (END )?.+ ===$/ ) { $depth += $1 ? -1 : 1; next }
        $probe_rows++ unless $depth;
    }
    my @capture_lines = split /\n/, $capture, -1;
    pop @capture_lines if @capture_lines && $capture_lines[-1] eq '';
    fail( sprintf 'the capture run printed %d rows and the probe run %d: the probe\'s positions do not apply',
        scalar @capture_lines, $probe_rows ) if @capture_lines != $probe_rows;
    my $total_rows = @capture_lines;

    resolve_crop( $_, \%section, \@report_order, $total_rows, $r->{width} ) for @{ $r->{crops} };

    my $palette = palette_for( $r->{background} );
    my $grid    = build_grid( $capture, $palette, $r->{width} );
    for my $crop ( @{ $r->{crops} } ) {
        my $path = File::Spec->catfile( $r->{out_dir}, $crop->{file} );
        my $svg  = render_svg( $crop, $grid, $palette, $r->{pad}, "crop '$crop->{spec}' of: ltl @capture_args" );
        open my $fh, '>:encoding(UTF-8)', $path or fail("cannot write $path: $!");
        print {$fh} $svg;
        close $fh or fail("cannot write $path: $!");
        my $sections = @{ $crop->{sections} } ? join( ',', @{ $crop->{sections} } ) : 'whole output';
        my $line = sprintf '%s  rows %d-%d (%s)  cols %d-%d', $path, $crop->{first}, $crop->{last}, $sections, $crop->{col_first}, $crop->{col_stop} - 1;
        $line .= '  check for sensitive content before committing: shows ' . join( ', ', @{ $crop->{sensitive} } ) if @{ $crop->{sensitive} };
        print "$line\n";
        print "trace: crop '$crop->{spec}': rows $crop->{first}-$crop->{last} cols $crop->{col_first}-" . ( $crop->{col_stop} - 1 ) . "\n" if $opt{trace};
    }
    return;
}

# ---- Resolving a crop ------------------------------------------------------

sub resolve_crop {
    my ( $crop, $section, $report_order, $total_rows, $width ) = @_;
    my $what  = "crop '$crop->{spec}'";
    my @names = @{ $crop->{sections} };
    if (@names) {
        my $previous = -1;
        for my $name (@names) {
            my $s = $section->{$name} or fail( "$what: unknown section '$name' (" . join( ', ', @$report_order ) . ')' );
            fail("$what: section '$name' is $s->{state}, not rendered") unless $s->{state} eq 'rendered';
            fail("$what: sections are named in print order; '$name' prints before the section named ahead of it") if $s->{order} <= $previous;
            $previous = $s->{order};
        }
        my $last = 0;
        for my $name (@names) {
            my $end = $section->{$name}{start} + $section->{$name}{rows} - 1;
            $last = $end if $end > $last;
        }
        $crop->{first} = $section->{ $names[0] }{start} + $crop->{start};
        $crop->{last}  = $last + $crop->{end};
    } else {
        ( $crop->{first}, $crop->{last} ) = ( 1 + $crop->{start}, $total_rows + $crop->{end} );
    }
    fail("$what: rows $crop->{first} to $crop->{last} are empty") if $crop->{last} < $crop->{first};
    fail("$what: rows $crop->{first} to $crop->{last} fall outside the output's rows 1 to $total_rows")
        if $crop->{first} < 1 || $crop->{last} > $total_rows;

    my ( $left, $right ) = @{$crop}{qw(left right)};
    fail("$what: left column $left is negative") if $left < 0;
    fail("$what: left column $left is beyond the terminal width $width") if $left > $width;
    my $stop = $right > 0 ? $left + $right : $width + $right;
    fail("$what: $right columns from column $left reach past the right edge at $width") if $right > 0 && $stop > $width;
    fail("$what: the right position $right ends at column $stop, at or before the left position $left") if $stop <= $left;
    ( $crop->{col_first}, $crop->{col_stop} ) = ( $left, $stop );

    $crop->{sensitive} = [ grep {
        my $s = $section->{$_};
        $s && $s->{state} eq 'rendered' && $s->{start} <= $crop->{last} && $s->{start} + $s->{rows} - 1 >= $crop->{first}
    } @sensitive ];
    return;
}

# ---- Rendering -------------------------------------------------------------

sub hex_of { return sprintf '#%02x%02x%02x', map { int( $_ * 255 + 0.5 ) } @{ $_[0] } }

# The 256-colour table for a background: 0-15 from its profile, 16-231 the
# xterm cube, 232-255 greys; plus its text, bold and background colours.
sub palette_for {
    my ($background) = @_;
    my $profile = $profiles{$background};
    my @colours = map { hex_of($_) } @{ $profile->{ansi} };
    my @level = ( 0, 95, 135, 175, 215, 255 );
    for my $i ( 16 .. 231 ) {
        my $n = $i - 16;
        push @colours, sprintf '#%02x%02x%02x', $level[ int( $n / 36 ) ], $level[ int( $n / 6 ) % 6 ], $level[ $n % 6 ];
    }
    push @colours, sprintf '#%02x%02x%02x', ( 8 + 10 * $_ ) x 3 for 0 .. 23;
    return { colours => \@colours, map { $_ => hex_of( $profile->{$_} ) } qw(text bold background) };
}

# The capture run's output as a grid of cells: character, colours, attributes.
# Rows are clipped at the terminal width, never wrapped.
sub build_grid {
    my ( $capture, $palette, $width ) = @_;
    my @colours = @{ $palette->{colours} };
    my ( @grid, %sgr );
    my $reset = sub { %sgr = ( fg => undef, bg => undef, bold => 0, underline => 0, reverse => 0 ) };
    $reset->();
    my $apply = sub {
        my @p = map { $_ eq '' ? 0 : $_ } split /;/, $_[0], -1;
        @p = (0) unless @p;
        while (@p) {
            my $c = shift @p;
            if    ( $c == 0 )  { $reset->() }
            elsif ( $c == 1 )  { $sgr{bold} = 1 }
            elsif ( $c == 22 ) { $sgr{bold} = 0 }
            elsif ( $c == 4 )  { $sgr{underline} = 1 }
            elsif ( $c == 24 ) { $sgr{underline} = 0 }
            elsif ( $c == 7 )  { $sgr{reverse} = 1 }
            elsif ( $c == 27 ) { $sgr{reverse} = 0 }
            elsif ( $c >= 30 && $c <= 37 )   { $sgr{fg} = $colours[ $c - 30 ] }
            elsif ( $c >= 90 && $c <= 97 )   { $sgr{fg} = $colours[ $c - 90 + 8 ] }
            elsif ( $c >= 40 && $c <= 47 )   { $sgr{bg} = $colours[ $c - 40 ] }
            elsif ( $c >= 100 && $c <= 107 ) { $sgr{bg} = $colours[ $c - 100 + 8 ] }
            elsif ( $c == 39 ) { $sgr{fg} = undef }
            elsif ( $c == 49 ) { $sgr{bg} = undef }
            elsif ( ( $c == 38 || $c == 48 ) && @p ) {
                my $key  = $c == 38 ? 'fg' : 'bg';
                my $mode = shift @p;
                if    ( $mode == 5 && @p )      { $sgr{$key} = $colours[ shift(@p) % 256 ] }
                elsif ( $mode == 2 && @p >= 3 ) { $sgr{$key} = sprintf '#%02x%02x%02x', splice @p, 0, 3 }
            }
            # Other codes, such as the non-standard 109 ltl prints, are ignored,
            # as terminals ignore them.
        }
    };
    utf8::decode($capture) or fail('the capture run\'s output is not UTF-8');
    my ( $row, $col ) = ( 0, 0 );
    while ( $capture =~ /\G(?:\e\[([0-9;]*)m|(\e[^\n]{0,8})|(\n)|([\x00-\x1f\x7f])|(.))/gcs ) {
        if    ( defined $1 ) { $apply->($1) }
        elsif ( defined $2 ) { fail( sprintf 'the capture run printed an escape sequence other than a colour code on row %d: %s', $row + 1, join ' ', map { sprintf '%02x', ord } split //, $2 ) }
        elsif ( defined $3 ) { $row++; $col = 0 }
        elsif ( defined $4 ) { fail( sprintf 'the capture run printed control character 0x%02x on row %d', ord $4, $row + 1 ) }
        else {
            if ( $col < $width ) {
                my ( $fg, $bg ) = ( $sgr{fg} // ( $sgr{bold} ? $palette->{bold} : $palette->{text} ), $sgr{bg} // $palette->{background} );
                ( $fg, $bg ) = ( $bg, $fg ) if $sgr{reverse};
                $grid[$row][$col] = { ch => $5, fg => $fg, bg => $bg, bold => $sgr{bold}, underline => $sgr{underline} };
            }
            $col++;
        }
    }
    return \@grid;
}

sub n { my $v = sprintf '%.2f', $_[0]; $v =~ s/\.?0+$//; return $v }
sub rect { return sprintf '<rect x="%s" y="%s" width="%s" height="%s" fill="%s" shape-rendering="crispEdges"/>', map( { n($_) } @_[ 0 .. 3 ] ), $_[4] }
sub xml  { my $s = shift; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/"/&quot;/g; return $s }

# One crop as SVG (D14): every character is font text, backgrounds are
# full-cell rectangles, underlines are lines; the padding surrounds the cells.
sub render_svg {
    my ( $crop, $grid, $palette, $pad, $desc ) = @_;
    my ( $cw, $ch ) = ( CELL_WIDTH, CELL_HEIGHT );
    my ( $pad_top, $pad_right, $pad_bottom, $pad_left ) = @$pad;
    my $default_bg = $palette->{background};
    my $cols = $crop->{col_stop} - $crop->{col_first};
    my @rows = map { my $cells = $grid->[ $_ - 1 ] || []; [ map { $cells->[$_] } $crop->{col_first} .. $crop->{col_stop} - 1 ] } $crop->{first} .. $crop->{last};
    my ( $ox, $oy ) = ( $pad_left * $cw, $pad_top * $ch );
    my ( $W, $H ) = ( ( $pad_left + $cols + $pad_right ) * $cw, ( $pad_top + @rows + $pad_bottom ) * $ch );
    my $blank = sub { !$_[0] || $_[0]{ch} eq ' ' };

    my @out;
    push @out, sprintf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">', n($W), n($H), n($W), n($H);
    push @out, sprintf '<desc>%s</desc>', xml($desc);
    push @out, sprintf '<rect width="100%%" height="100%%" fill="%s"/>', $default_bg;
    push @out, sprintf '<g font-family="%s" font-size="%s">', FONT_FAMILY, n(FONT_SIZE);

    # Backgrounds: one full-cell rectangle per run of cells sharing a colour.
    for my $r ( 0 .. $#rows ) {
        my $cells = $rows[$r];
        my $c = 0;
        while ( $c < @$cells ) {
            my $bg = $cells->[$c] ? $cells->[$c]{bg} : $default_bg;
            my $start = $c;
            $c++ while $c < @$cells && ( $cells->[$c] ? $cells->[$c]{bg} : $default_bg ) eq $bg;
            push @out, rect( $ox + $start * $cw, $oy + $r * $ch, ( $c - $start ) * $cw, $ch, $bg ) unless $bg eq $default_bg;
        }
    }

    # Underlines: one line per run of underlined cells in one colour, blanks included.
    for my $r ( 0 .. $#rows ) {
        my $cells = $rows[$r];
        my $c = 0;
        while ( $c < @$cells ) {
            my $cell = $cells->[$c];
            unless ( $cell && $cell->{underline} ) { $c++; next }
            my $start = $c;
            $c++ while $c < @$cells && $cells->[$c] && $cells->[$c]{underline} && $cells->[$c]{fg} eq $cell->{fg};
            push @out, rect( $ox + $start * $cw, $oy + $r * $ch + $ch * BASELINE + 1.5, ( $c - $start ) * $cw, 1, $cell->{fg} );
        }
    }

    # Text: one run per stretch of non-blank cells sharing colour and weight,
    # started at its first cell and held to its cells' width by letter spacing.
    # Runs of full blocks are drawn after the rest: a line glyph beside a block
    # (a grid line meeting a histogram bar) is drawn a little wider than its
    # cell, and drawn last the block covers the overhang.
    my $full_block = "\x{2588}";
    my @block_runs;
    for my $r ( 0 .. $#rows ) {
        my $cells = $rows[$r];
        my $c = 0;
        while ( $c < @$cells ) {
            my $cell = $cells->[$c];
            if ( $blank->($cell) ) { $c++; next }
            my $is_block = $cell->{ch} eq $full_block;
            my ( $start, $s ) = ( $c, '' );
            while ( $c < @$cells ) {
                my $k = $cells->[$c];
                last if $blank->($k) || $k->{fg} ne $cell->{fg} || $k->{bold} != $cell->{bold} || ( $k->{ch} eq $full_block ) != $is_block;
                $s .= $k->{ch};
                $c++;
            }
            my $attrs = $cell->{bold} ? ' font-weight="bold"' : '';
            $attrs .= sprintf ' textLength="%s" lengthAdjust="spacing"', n( ( $c - $start ) * $cw ) if $c - $start > 1;
            my $text = sprintf '<text x="%s" y="%s" fill="%s"%s>%s</text>', n( $ox + $start * $cw ), n( $oy + $r * $ch + $ch * BASELINE ), $cell->{fg}, $attrs, xml($s);
            if ($is_block) { push @block_runs, $text } else { push @out, $text }
        }
    }
    push @out, @block_runs, '</g>', '</svg>';
    return join( "\n", @out ) . "\n";
}

# ---- Command line ----------------------------------------------------------

sub main {
    my @args = @ARGV;
    my ($separator) = grep { $args[$_] eq '--' } 0 .. $#args;
    my @tool_args = defined $separator ? @args[ 0 .. $separator - 1 ] : @args;
    my @ltl_args  = defined $separator ? @args[ $separator + 1 .. $#args ] : ();
    my @crop_words;
    GetOptionsFromArray( \@tool_args, \%opt, 'name=s', 'background=s', 'width=s', 'height=s', 'pad=s',
        'out-dir=s', 'trace', 'crop=s' => \@crop_words, 'manifest=s', 'only=s', 'help' => sub { print usage(); exit 0 } )
        or fail( "invalid options\n" . usage() );
    fail("unexpected argument: @tool_args") if @tool_args;
    check_size( '--width', $opt{width} )   if defined $opt{width};
    check_size( '--height', $opt{height} ) if defined $opt{height};
    parse_pad( $opt{pad} )                 if defined $opt{pad};
    my $out_dir;
    if ( defined $opt{'out-dir'} ) {
        $out_dir = File::Spec->rel2abs( $opt{'out-dir'} );
        fail("--out-dir '$opt{'out-dir'}' is not a directory") unless -d $out_dir;
    }
    return run_manifest( $out_dir, \@crop_words, \@ltl_args ) if defined $opt{manifest};

    fail( "the ltl command line follows '--'\n" . usage() ) unless defined $separator;
    fail("no ltl command line after '--'") unless @ltl_args;
    fail( "--only is for --manifest" ) if defined $opt{only};
    fail( "--name is required\n" . usage() ) unless defined $opt{name};
    my $base = check_name( '--name', $opt{name} );
    my $background = $opt{background} // 'dark';
    fail("--background is dark or light, not '$background'") unless $background =~ /^(dark|light)$/;
    run_recipe( {
        name       => $base,
        background => $background,
        width      => $opt{width} // DEFAULT_WIDTH,
        height     => $opt{height} // DEFAULT_HEIGHT,
        pad        => parse_pad( $opt{pad} // DEFAULT_PAD ),
        out_dir    => $out_dir // getcwd(),
        ltl        => \@ltl_args,
        crops      => [ map { crop_from_words( $base, $_ ) } ( @crop_words ? @crop_words : ('') ) ],
    } );
    return 0;
}

# ---- Manifest (D19) --------------------------------------------------------

my @entry_keys = qw( name ltl background width height pad crops );

sub run_manifest {
    my ( $out_dir, $crop_words, $ltl_args ) = @_;
    for my $flag (qw( name background )) {
        fail("--$flag is set in the manifest entry, not on the command line") if defined $opt{$flag};
    }
    fail('--crop is set in the manifest entry, not on the command line') if @$crop_words;
    fail('the ltl command line is set in the manifest entry, not after --') if @$ltl_args;
    require YAML::PP;
    my $file = $opt{manifest};
    my $doc = eval { YAML::PP->new->load_file($file) } or fail( "cannot read the manifest $file: " . ( $@ =~ /^(.*?)(?: at \S+ line \d+.*)?$/m )[0] );
    fail("$file: a mapping with a 'screenshots' list is expected") unless ref $doc eq 'HASH' && ref $doc->{screenshots} eq 'ARRAY';

    # Every entry is checked before any runs.
    my ( @recipes, %seen );
    my $i = 0;
    for my $entry ( @{ $doc->{screenshots} } ) {
        $i++;
        my $where = "$file entry $i";
        fail("$where: a mapping is expected") unless ref $entry eq 'HASH';
        my $name = $entry->{name};
        fail("$where: 'name' is required") unless defined $name;
        $where = "$file entry '$name'";
        check_name( "$where: name", $name );
        fail("$where: the name is used by an earlier entry") if $seen{$name}++;
        for my $key ( sort keys %$entry ) {
            fail("$where: unknown key '$key' (" . join( ', ', @entry_keys ) . ')') unless grep { $_ eq $key } @entry_keys;
        }
        fail("$where: 'ltl' is required, as one command-line string") unless defined $entry->{ltl} && !ref $entry->{ltl} && $entry->{ltl} =~ /\S/;
        my $background = $entry->{background} // 'dark';
        fail("$where: background is dark or light, not '$background'") unless $background =~ /^(dark|light)$/;
        my $crops = $entry->{crops} // [];
        fail("$where: 'crops' is a list") unless ref $crops eq 'ARRAY';
        my @crops = eval {
            map {
                fail('a crop is a mapping of sections, start, end, cols, label') unless ref $_ eq 'HASH';
                make_crop( $name, %$_ )
            } @$crops ? @$crops : ( {} );
        };
        fail("$where: $@") if $@;
        my @ltl = shellwords( $entry->{ltl} );
        fail("$where: the ltl string has an unbalanced quote") unless @ltl;
        push @recipes, {
            name       => $name,
            background => $background,
            width      => check_size( "$where: width", $opt{width} // $entry->{width} // DEFAULT_WIDTH ),
            height     => check_size( "$where: height", $opt{height} // $entry->{height} // DEFAULT_HEIGHT ),
            pad        => eval { parse_pad( $opt{pad} // $entry->{pad} // DEFAULT_PAD ) } // fail("$where: $@"),
            ltl        => \@ltl,
            crops      => \@crops,
        };
    }
    if ( defined $opt{only} ) {
        @recipes = grep { $_->{name} eq $opt{only} } @recipes;
        fail("$file has no entry named '$opt{only}'") unless @recipes;
    }
    unless ( defined $out_dir ) {
        $out_dir = File::Spec->catdir( $repo_root, MANIFEST_OUT );
        mkdir $out_dir or fail("cannot create $out_dir: $!") unless -d $out_dir;
    }

    my @failed;
    for my $recipe (@recipes) {
        $recipe->{out_dir} = $out_dir;
        print "== $recipe->{name}\n";
        next if eval { run_recipe($recipe); 1 };
        print STDERR "capture-screenshots: entry '$recipe->{name}': $@";
        push @failed, $recipe->{name};
    }
    printf "%d of %d entries written%s\n", @recipes - @failed, scalar @recipes,
        @failed ? '; failed: ' . join( ', ', @failed ) : '';
    return @failed ? 1 : 0;
}

my $status = eval { main() };
unless ( defined $status ) {
    print STDERR "capture-screenshots: $@";
    exit 1;
}
exit $status;
