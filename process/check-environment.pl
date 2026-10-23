#!/usr/bin/env perl
# check-environment.pl: test whether this host's environment is set up for
# working on ltl, whatever configured it.
#
#   process/check-environment.pl [--condition N[,N...]] [--hook]
#
# One list of conditions, with a test per host where hosts differ. Every tool
# is tested by starting the one found on PATH, never by trusting the Perl this
# script runs under, so any Perl runs it, set up or not: core modules only, no
# syntax newer than Perl 5.30. Read-only: it installs, writes and changes
# nothing. It reports what it expected and what it found, and points each
# condition that does not pass at its entry in docs/development-environment.md
# § Troubleshooting a failed condition. Run by every setup script's
# --validate, at the end of a full setup, and at session start by the hook in
# .claude/settings.json, whose message to the developer names the likely
# scenario and the command to run.
use strict;
use warnings;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case no_auto_abbrev);
use JSON::PP;
use POSIX ();

my $repo_root = abs_path( File::Spec->catdir( dirname( abs_path(__FILE__) ), '..' ) );

use constant POINTER      => 'docs/development-environment.md § Troubleshooting a failed condition';
use constant TOOL_TIMEOUT => 20;    # seconds for any one tool this script starts

my %host_name = ( darwin => 'macOS', linux => 'Linux', msys => 'Windows', cygwin => 'Windows', MSWin32 => 'Windows' );
my $host = { darwin => 'macos', linux => 'linux', msys => 'windows', cygwin => 'windows', MSWin32 => 'windows' }->{$^O} // 'other';

sub usage {
    return <<'USAGE';
Usage: process/check-environment.pl [--condition N[,N...]] [--hook]

Tests whether this host's environment is set up for working on ltl, and
reports each condition by number: pass, FAIL, note or n/a.

  --condition N[,N...]  test only these conditions
  --hook                print the report as Claude Code SessionStart JSON
                        and exit 0 whatever the result
  -h, --help            this text

Exit status: 0 nothing failed, 1 a condition failed, 2 a usage error.
USAGE
}

# --- Helpers ----------------------------------------------------------------

# A native Windows Perl reads a file as executable by its extension alone; Git
# Bash also runs a script without one that starts with #!.
sub starts_with_shebang {
    my ($path) = @_;
    open my $fh, '<', $path or return 0;
    read $fh, my $head, 2;
    return ( $head // '' ) eq '#!';
}

# The first executable of this name on PATH, or undef.
sub find_on_path {
    my ($name) = @_;
    my @exts = $host eq 'windows' ? ( '', '.exe', '.bat', '.cmd' ) : ('');
    for my $dir ( split /\Q$Config{path_sep}\E/, $ENV{PATH} // '' ) {
        next if $dir eq '';
        for my $ext (@exts) {
            my $path = File::Spec->catfile( $dir, "$name$ext" );
            return $path if -f $path && ( -x _ || ( $^O eq 'MSWin32' && $ext eq '' && starts_with_shebang($path) ) );
        }
    }
    return undef;
}

# The path with every symbolic link resolved, so that a Homebrew link names
# the keg in its Cellar.
sub real {
    my ($path) = @_;
    return undef unless defined $path;
    return abs_path($path) // $path;
}

# Start a tool and capture its standard output; its standard input is empty
# and its standard error discarded. Returns the exit status (-1 when it could
# not start or ran past TOOL_TIMEOUT) and the output. The one place a tool is
# started. The tool runs in a session of its own, so a timeout kills its whole
# process group, and so it has no controlling terminal: an interactive shell
# started from a terminal in a process group of its own is stopped as soon as
# it touches that terminal, and would run into the timeout. A native Windows
# Perl (Strawberry Perl) has no fork, so there the tool is started by
# run_capture_windows.
sub run_capture {
    my (@cmd) = @_;
    return run_capture_windows(@cmd) if $^O eq 'MSWin32';
    my $pid = open( my $fh, '-|' );
    return ( -1, '' ) unless defined $pid;
    if ( !$pid ) {
        POSIX::setsid();
        open STDIN,  '<', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;
        exec { $cmd[0] } @cmd or POSIX::_exit(127);
    }
    my $out = '';
    my $timed_out = 0;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm TOOL_TIMEOUT;
        local $/;
        $out = <$fh> // '';
        alarm 0;
        1;
    } or do { $timed_out = 1; kill 'KILL', -$pid };
    close $fh;
    my $status = $? == -1 || $? & 127 ? -1 : $? >> 8;
    return ( $timed_out ? -1 : $status, $out );
}

# A native Windows Perl joins a list into one command line, wrapping an
# argument that holds a space or tab in double quotes, leaving one that holds
# a double quote as it is, and escaping nothing; the tool splits the line
# again by the C runtime's rules (Git Bash's tools by Cygwin's, which also
# expand an unquoted wildcard and read single quotes). An argument holding a
# quote or a wildcard is therefore quoted here, the others only made safe for
# the quotes Perl adds.
sub windows_argument {
    my ($arg) = @_;
    if ( $arg =~ /["'*?\[{]/ ) {
        $arg =~ s{(\\*)"}{$1$1\\"}g;
        $arg =~ s{(\\+)\z}{$1$1};
        return qq{"$arg"};
    }
    $arg =~ s{(\\+)\z}{$1$1} if $arg =~ /[ \t]/;
    return $arg;
}

# run_capture under a native Windows Perl. A script without an executable's
# extension (setup's python3 wrapper) is started by Git Bash's bash, as Git
# Bash starts it. The tool inherits the handles redirected around its start.
sub run_capture_windows {
    my (@cmd) = @_;
    if ( $cmd[0] !~ m{[/\\]} ) {
        my $found = tool( $cmd[0] ) or return ( -1, '' );
        $cmd[0] = $found->{path};
    }
    if ( $cmd[0] !~ /\.(?:exe|bat|cmd|com)\z/i ) {
        my $bash = tool('bash') or return ( -1, '' );
        unshift @cmd, $bash->{path};
    }
    open( my $saved_in,  '<&', \*STDIN )  or return ( -1, '' );
    open( my $saved_err, '>&', \*STDERR ) or return ( -1, '' );
    open( STDIN,  '<', File::Spec->devnull );
    open( STDERR, '>', File::Spec->devnull );
    my $pid = open( my $fh, '-|', map { windows_argument($_) } @cmd );
    open( STDIN,  '<&', $saved_in );
    open( STDERR, '>&', $saved_err );
    return ( -1, '' ) unless $pid;
    my $out = '';
    my $timed_out = 0;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm TOOL_TIMEOUT;
        local $/;
        $out = <$fh> // '';
        alarm 0;
        1;
    } or do { $timed_out = 1; kill 'KILL', $pid };
    close $fh;
    my $status = $? == -1 || $? & 127 ? -1 : $? >> 8;
    return ( $timed_out ? -1 : $status, $out );
}

my %tool_cache;

# The tool of this name on PATH: { path, real }, or undef when there is none.
sub tool {
    my ($name) = @_;
    return $tool_cache{$name} if exists $tool_cache{$name};
    my $path = find_on_path($name);
    return $tool_cache{$name} = defined $path ? { path => $path, real => real($path) } : undef;
}

sub describe {
    my ( $tool, $version ) = @_;
    my $text = $tool->{path};
    $text .= " -> $tool->{real}" if $tool->{real} ne $tool->{path};
    $text .= " ($version)" if defined $version && $version ne '';
    return $text;
}

sub perl_version {
    my ($perl) = @_;
    my ( $status, $out ) = run_capture( $perl->{path}, '-e', 'print $^V' );
    return $status == 0 ? $out : undef;
}

sub bash_version {
    my ($bash) = @_;
    my ( $status, $out ) = run_capture( $bash->{path}, '-c', 'echo "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"' );
    chomp $out;
    return $status == 0 && $out =~ /^(\d+)\.\d+$/ ? $out : undef;
}

# The modules a cpanfile requires: those of its develop block when $develop is
# true, the others when it is false.
sub cpanfile_modules {
    my ( $file, $develop ) = @_;
    open my $fh, '<', $file or return;
    my ( @modules, $in_develop );
    while ( my $line = <$fh> ) {
        $in_develop = 1 if $line =~ /^\s*on\s+'develop'/;
        $in_develop = 0 if $in_develop && $line =~ /^\s*\};/;
        push @modules, $1 if $line =~ /^\s*requires\s+'([^']+)'/ && ( $in_develop ? 1 : 0 ) == ( $develop ? 1 : 0 );
    }
    return @modules;
}

# Started with the perl on PATH for conditions 3 and 4, with the modules as its
# arguments. For each module, one tab-separated line: its name, whether it
# loads, the file it loaded from, whether that file lies outside the Perl's own
# @INC (the one it was built with, without what PERL5LIB or PERLLIB add), and
# every copy of it on @INC outside the core directories, joined by ";". The core
# directories are Config's privlib and archlib and any built-in one holding
# strict.pm (Debian splits its core into perl-base). A dual-life module
# upgraded over its core copy is one copy; a module from anywhere else, or two
# copies outside the core, did not come from the setup alone.
my $perl_modules = <<'END_PERL';
use Config; use Cwd ();
my @modules = @ARGV;
sub norm { my $p = Cwd::realpath( $_[0] ) // $_[0]; $p =~ tr{\\}{/}; $^O eq 'MSWin32' ? lc $p : $p }
sub under { my ( $file, @roots ) = @_; scalar grep { index( $file, "$_/" ) == 0 } @roots }
my %added = map { norm($_) => 1 } grep { length } map { split /\Q$Config{path_sep}\E/ } grep { defined } @ENV{qw(PERL5LIB PERLLIB)};
my @builtin = grep { !$added{$_} } map { norm($_) } grep { !ref && $_ ne '.' && -d } @INC;
my @core = ( ( map { norm($_) } grep { defined && length } @Config{qw(privlibexp archlibexp)} ), grep { -f "$_/strict.pm" } @builtin );
for my $m (@modules) {
    ( my $f = "$m.pm" ) =~ s{::}{/}g;
    my $loads = eval { require $f; 1 } ? 1 : 0;
    my $file  = $loads && defined $INC{$f} && !ref $INC{$f} ? norm( $INC{$f} ) : '';
    my %seen;
    my @copies = grep { !$seen{$_}++ && !under( $_, @core ) }
        map { norm("$_/$f") } grep { !ref && -f "$_/$f" } @INC;
    print join( "\t", $m, $loads, $file, ( $file ne '' && !under( $file, @builtin ) ? 1 : 0 ), join( ';', @copies ) ), "\n";
}
END_PERL

# Load each module in the Perl on PATH and judge where it loaded from: a hash
# per module in cpanfile order, or undef when that Perl could not be started.
sub modules_judged {
    my ( $perl, @modules ) = @_;
    # Loading the profiler starts it, and it writes nytprof.out into the
    # current directory; start=no loads it without profiling.
    local $ENV{NYTPROF} = 'start=no';
    my ( $status, $out ) = run_capture( $perl->{path}, '-e', $perl_modules, @modules );
    return undef if $status != 0;
    return [ map { my %m; @m{qw(name loads file outside copies)} = split /\t/, $_, -1; \%m } split /\n/, $out ];
}

# Where this host's setup puts each development tool: the test its resolved
# path passes, and how that reads in a report. A tool absent from a host's
# entry may be anywhere on that host. A python3 entry's modules test is passed
# each module's name and the resolved path of the file it loads from; without
# one, a module may load from anywhere. Its interpreter test is passed the
# resolved path of the Python that python3 starts, for a host where python3 is
# a wrapper rather than the interpreter (Windows: setup's ~/bin/python3).
my %place = (
    macos => {
        perl    => { test => sub { $_[0] =~ m{/Cellar/perl/} }, text => "Homebrew's, a path into its Cellar, not /usr/bin or /System" },
        bash    => { test => sub { $_[0] =~ m{/Cellar/} },      text => "Homebrew's, a path into its Cellar, not /bin" },
        python3 => {
            test    => sub { $_[0] =~ m{/Cellar/} },
            text    => "Homebrew's, a path into its Cellar, not /usr/bin; NumPy and SciPy each from its own formula's Cellar, not a pip install",
            modules => sub { my ( $module, $path ) = @_; $path =~ m{/Cellar/\Q$module\E/} },
        },
    },
    linux => {
        perl    => { test => sub { $_[0] =~ m{^/(usr/)?bin/} }, text => "the distribution's, in /usr/bin" },
        python3 => {
            test    => sub { $_[0] =~ m{^/(usr/)?bin/} },
            text    => "the distribution's, in /usr/bin; NumPy and SciPy from its packages, in /usr/lib/python3/dist-packages, not a pip install",
            modules => sub { my ( $module, $path ) = @_; $path =~ m{^/usr/lib/python3/dist-packages/} },
        },
    },
    windows => {
        perl    => { test => sub { $_[0] =~ /strawberry/i }, text => "Strawberry Perl's, not Git's own /usr/bin/perl" },
        python3 => {
            interpreter => sub { $_[0] =~ m{/AppData/Local/Programs/Python/Python3[^/]*/python\.exe\z}i },
            text        => "the WinGet Python, under the user's AppData\\Local\\Programs\\Python, started by setup's ~/bin/python3; NumPy and SciPy not from a pip install --user",
        },
    },
);

sub expectation {
    my ($name) = @_;
    my $what  = { perl => 'the development Perl', bash => 'bash 4 or later', python3 => 'a python3 that imports NumPy and SciPy' }->{$name};
    my $place = $place{$host}{$name};
    return $place ? "$what, $place->{text}" : $what;
}

my %measured;

# Started with python3 for condition 7: a first line, "python" and the resolved
# path of the interpreter running, then one tab-separated line per module, its
# name, the resolved file it loads from, whether that file is in the user's
# site-packages (where pip --user installs), and every installed copy of it
# Python can see on sys.path, as version@metadata-directory, joined by ";".
# On every host, a module from the user's site-packages or one installed more
# than once is a copy that did not come from the setup alone.
my $python_modules = join "\n",
    'import os, sys, site, importlib, importlib.metadata as md',
    'print("python\t" + os.path.realpath(sys.executable).replace(os.sep, "/"))',
    'user = os.path.normcase(os.path.realpath(site.getusersitepackages())) + os.sep',
    'for n in ("numpy", "scipy"):',
    '    f = os.path.normcase(os.path.realpath(importlib.import_module(n).__file__))',
    '    found = sorted({(d.version, os.path.realpath(str(getattr(d, "_path", "")))) for d in md.distributions() if (d.metadata["Name"] or "").lower() == n})',
    '    print("\t".join([n, f, str(f.startswith(user)), ";".join(v + "@" + p for v, p in found)]))';

# Whether a tool meets what this host's setup provides, what was found, and
# whether the tool is the setup's own (in its place).
# What is measured by starting the tool is remembered by its resolved path, so
# a tool reached twice is started once. A python3 outside its place is not
# started: on macOS /usr/bin/python3 is a stub that may offer to install the
# command line tools.
sub judge {
    my ( $name, $tool ) = @_;
    my $place    = $place{$host}{$name};
    my $in_place = !$place || !$place->{test} || $place->{test}->( $tool->{real} );
    my $measure  = sub { my ($code) = @_; $measured{"$name $tool->{real}"} //= [ $code->() ]; @{ $measured{"$name $tool->{real}"} } };
    if ( $name eq 'perl' ) {
        my ($version) = $measure->( sub { perl_version($tool) } );
        return ( $in_place, describe( $tool, $version ), $in_place );
    }
    if ( $name eq 'bash' ) {
        my ($version) = $measure->( sub { bash_version($tool) } );
        my $ok = $in_place && defined $version && ( split /\./, $version )[0] >= 4;
        return ( $ok, describe( $tool, $version // 'version not read' ), $in_place );
    }
    return ( 0, describe($tool), 0 ) unless $in_place;
    my ( $status, $out ) = $measure->( sub { run_capture( $tool->{path}, '-B', '-c', $python_modules ) } );
    $out =~ s/\r\n/\n/g;    # a Windows Python's line ends, kept by Git's own Perl
    return ( 0, describe($tool) . '; NumPy or SciPy does not import', $in_place ) if $status != 0;
    my $modules = $place && $place->{modules};
    my %label = ( numpy => 'NumPy', scipy => 'SciPy' );
    my ( @wrong, $interpreter );
    for ( split /\n/, $out ) {
        my ( $name, $file, $in_user_site, $installs ) = split /\t/, $_, -1;
        if ( $name eq 'python' ) { $interpreter = $file; next }
        my @installs = grep { length } split /;/, $installs // '';
        if ( $in_user_site eq 'True' ) {
            push @wrong, "$label{$name} loads from the user's site-packages, $file";
        }
        elsif ( $modules && !$modules->( $name, $file ) ) {
            push @wrong, "$label{$name} loads from $file";
        }
        if ( @installs > 1 ) {
            push @wrong, "$label{$name} is installed " . scalar(@installs) . ' times: ' . join( ', ', map { s/\@/ in /r } @installs );
        }
    }
    my $found = describe($tool);
    if ( $place && $place->{interpreter} ) {
        $found .= ', which starts ' . ( $interpreter // 'no Python it reports' );
        if ( !defined $interpreter || !$place->{interpreter}->($interpreter) ) {
            unshift @wrong, "not the setup's Python";
            $in_place = 0;
        }
    }
    return ( 1, "$found; NumPy and SciPy import", $in_place ) unless @wrong;
    return ( 0, "$found; " . join( '; ', @wrong ), $in_place );
}

# --- The conditions -----------------------------------------------------------
#
# Each test returns { result => pass|FAIL|note, expected, found, context }.
# A host absent from a condition's tests is not applicable there.

sub passed { return { result => 'pass', @_ } }

sub missing_tool {
    my ( $name, $severity, $expected ) = @_;
    return { result => $severity, expected => $expected, found => "no $name on PATH" };
}

sub test_perl_on_path {
    my $perl = tool('perl');
    return missing_tool( 'perl', 'FAIL', 'a perl on PATH' ) unless $perl;
    return passed( found => $perl->{path} );
}

# Condition 2, 6 or 7: the tool of this name on PATH meets what this host's
# setup provides.
sub test_tool {
    my ( $name, $severity ) = @_;
    my $expected = expectation($name);
    my $tool = tool($name) or return missing_tool( $name, $severity, $expected );
    my ( $ok, $found, $in_place ) = judge( $name, $tool );
    return $ok ? passed( found => $found ) : { result => $severity, expected => $expected, found => $found, in_place => $in_place };
}

sub test_modules {
    my ( $cpanfile, $develop, $severity ) = @_;
    my $file = File::Spec->catfile( $repo_root, 'build', $cpanfile );
    my @modules = cpanfile_modules( $file, $develop );
    my $expected = 'the perl on PATH loads every ' . ( $develop ? 'development-only' : 'runtime' ) . " module of build/$cpanfile";
    return { result => $severity, expected => $expected, found => "build/$cpanfile lists no " . ( $develop ? 'development-only ' : '' ) . 'modules, or cannot be read' }
        unless @modules;
    my $perl = tool('perl') or return missing_tool( 'perl', $severity, $expected );
    my $judged = modules_judged( $perl, @modules );
    return { result => $severity, expected => $expected, found => "$perl->{path} could not be started" }
        unless defined $judged;
    my @failed = map { $_->{name} } grep { !$_->{loads} } @$judged;
    my @wrong  = (
        ( map { "$_->{name} loads from $_->{file}, outside this Perl's own install" } grep { $_->{outside} } @$judged ),
        ( map { my @c = split /;/, $_->{copies}; @c > 1 ? "$_->{name} is installed " . scalar(@c) . ' times: ' . join( ', ', @c ) : () }
            @$judged ),
    );
    return passed( found => scalar(@modules) . ' modules load' ) unless @failed || @wrong;
    my $count = @failed;
    my @found;
    push @found, "$failed[0] does not load" . ( $count > 1 ? "; $count of " . scalar(@modules) . ' do not: ' . join( ', ', @failed ) : '' ) if @failed;
    push @found, @wrong;
    return { result => $severity, expected => "$expected, each from this Perl's own install, once", found => join( '; ', @found ) . " (perl: $perl->{path})" };
}

# What a shell started from a clean environment resolves for each tool, as
# { name => { path, real } or undef }. Only the variables a login shell needs
# to find its files are passed on.
# On Windows a user variable such as BASH_ENV is in every new process's
# environment, so the plain shell, which reads the file it names, is given it;
# a login shell is not, so that it shows what its own startup files do. A
# native Windows Perl is given each path in Windows form, and the shell HOME
# in Git Bash's.
sub resolved_in_clean_shell {
    my ( $shell, $mode ) = @_;
    my @pass = ( qw(HOME USER LOGNAME TERM ZDOTDIR), $host eq 'windows' && $mode eq '-c' ? 'BASH_ENV' : () );
    my %env = map { $_ => $ENV{$_} } grep { defined $ENV{$_} } @pass;
    my $path = '$(command -v "$t")';
    if ( $^O eq 'MSWin32' ) {
        if ( defined $env{HOME} ) {
            $env{HOME} =~ s{^([A-Za-z]):}{'/' . lc $1}e;
            $env{HOME} =~ tr{\\}{/};
        }
        $path  = '$(p=$(command -v "$t") && cygpath -m "$p")';
        $shell = ( tool('bash') // return {} )->{path};
    }
    my ( $status, $out ) = run_capture( 'env', '-i', ( map { "$_=$env{$_}" } sort keys %env ), $shell, $mode,
        "for t in perl bash python3; do printf \"%s=%s\\n\" \"\$t\" \"$path\"; done" );
    my %found;
    for my $line ( split /\n/, $out ) {
        $found{$1} = $2 eq '' ? undef : { path => $2, real => real($2) } if $line =~ /^(perl|bash|python3)=(.*)$/;
    }
    return \%found;
}

# Condition 8: a login shell started from a clean environment resolves tools
# that meet conditions 2, 6 and 7, whatever this check's own PATH holds. A new
# terminal tab and a plain shell are shown beside it, not judged.
sub test_clean_login_shell {
    my ( $shell, $file_hint ) = @_;
    my @names = qw(perl bash python3);
    my @modes = ( [ 'login (-lc)', '-lc' ], [ 'new terminal tab (-lic)', '-lic' ], [ 'plain, not a login (-c)', '-c' ] );
    my %resolved = map { $_->[0] => resolved_in_clean_shell( "/bin/$shell", $_->[1] ) } @modes;
    my ( @wrong, %login_ok );
    for my $name (@names) {
        my $tool = $resolved{'login (-lc)'}{$name};
        if ( !$tool ) { push @wrong, "no $name"; next }
        my ( $ok, $found ) = judge( $name, $tool );
        $login_ok{$name} = $ok;
        push @wrong, "$name $found" unless $ok;
    }
    my $show = sub { my ($t) = @_; $t ? $t->{real} : 'none' };
    my @context = ( sprintf '%-28s %s', 'on the PATH this check saw:', join '  ', map { "$_=" . $show->( tool($_) ) } @names );
    push @context, map { my $m = $_->[0]; sprintf '%-28s %s', "$m:", join '  ', map { "$_=" . $show->( $resolved{$m}{$_} ) } @names } @modes;
    my $expected = "a login $shell started from a clean environment resolves perl, bash and python3 as conditions 2, 6 and 7 expect ($file_hint)";
    return passed( context => \@context, login_ok => \%login_ok ) unless @wrong;
    return { result => 'FAIL', expected => $expected, found => 'the login shell resolves ' . join( '; ', @wrong ), context => \@context, login_ok => \%login_ok };
}

sub test_on_path {
    my ( $name, $why ) = @_;
    my $found = tool($name);
    return $found ? passed( found => $found->{path} ) : missing_tool( $name, 'note', "$name on PATH ($why)" );
}

sub test_swift_compiler {
    my $expected = 'swiftc on PATH, with the Xcode command line tools installed (the PNG screenshots)';
    my $swiftc = tool('swiftc') or return missing_tool( 'swiftc', 'note', $expected );
    # /usr/bin/swiftc is a stub when the command line tools are absent;
    # xcode-select -p answers without starting their installer.
    my ($status) = run_capture( 'xcode-select', '-p' );
    return $status == 0
        ? passed( found => $swiftc->{path} )
        : { result => 'note', expected => $expected, found => "$swiftc->{path}, but the Xcode command line tools are not installed" };
}

sub test_autocrlf {
    my ( $status, $out ) = run_capture( 'git', '-C', $repo_root, 'config', 'core.autocrlf' );
    chomp $out;
    my $found = $status == 0 ? "core.autocrlf=$out" : 'core.autocrlf is not set';
    return $out eq 'false' ? passed( found => $found ) : { result => 'FAIL', expected => 'core.autocrlf=false in this repository', found => $found };
}

my @conditions = (
    { n => 1, title => 'a perl is on PATH',
      tests => { macos => \&test_perl_on_path, linux => \&test_perl_on_path, windows => \&test_perl_on_path } },
    { n => 2, title => 'it is the development Perl, not another on the host',
      tests => { macos => sub { test_tool( 'perl', 'FAIL' ) }, linux => sub { test_tool( 'perl', 'FAIL' ) }, windows => sub { test_tool( 'perl', 'FAIL' ) } } },
    { n => 3, title => 'it loads every runtime module the cpanfile requires',
      tests => {
          macos   => sub { test_modules( 'cpanfile', 0, 'FAIL' ) },
          linux   => sub { test_modules( 'cpanfile', 0, 'FAIL' ) },
          windows => sub { test_modules( 'cpanfile.windows', 0, 'FAIL' ) },
      } },
    { n => 4, title => 'it loads the development-only modules (the profiler)',
      tests => {
          macos   => sub { test_modules( 'cpanfile', 1, 'note' ) },
          linux   => sub { test_modules( 'cpanfile', 1, 'note' ) },
          windows => sub { test_modules( 'cpanfile.windows', 1, 'note' ) },
      } },
    { n => 6, title => 'bash on PATH is 4 or later',
      tests => { macos => sub { test_tool( 'bash', 'FAIL' ) }, linux => sub { test_tool( 'bash', 'FAIL' ) }, windows => sub { test_tool( 'bash', 'FAIL' ) } } },
    { n => 7, title => 'python3 on PATH imports NumPy and SciPy',
      tests => { macos => sub { test_tool( 'python3', 'FAIL' ) }, linux => sub { test_tool( 'python3', 'FAIL' ) }, windows => sub { test_tool( 'python3', 'note' ) } } },
    { n => 8, title => 'a login shell from a clean environment resolves the same tools',
      tests => {
          macos   => sub { test_clean_login_shell( 'zsh', '~/.zprofile' ) },
          linux   => sub { test_clean_login_shell( 'bash', '~/.profile or ~/.bash_profile' ) },
          windows => sub { test_clean_login_shell( 'bash', '~/.bash_profile' ) },
      } },
    { n => 9, title => 'tmux is on PATH',
      tests => {
          macos => sub { test_on_path( 'tmux', 'the terminal-interface navigation tests' ) },
          linux => sub { test_on_path( 'tmux', 'the terminal-interface navigation tests' ) },
      } },
    { n => 10, title => 'the screenshot tools are present',
      tests => { macos => \&test_swift_compiler } },
    { n => 11, title => 'the repository checks files out with LF endings',
      tests => { windows => \&test_autocrlf } },
);

# --- The message shown to the user at session start ------------------------
#
# What is wrong, the likely scenario, and the command to run, read from the
# failed conditions. A wrong tool first on PATH (conditions 1, 2, and 6 or
# 7 outside the setup's place) is this session's PATH when a clean login shell
# finds the right ones (condition 8 passes), the shell configuration when it
# does not. Otherwise, the right tool with modules missing or from elsewhere
# (conditions 3, 6 and 7 in place) is the install. The troubleshooting
# pointers stay in the agent's context.

my %setup = (
    macos   => { full => './build/macos-setup.sh', repair => './build/macos-setup.sh --repair' },
    linux   => { full => './build/linux-setup.sh', repair => './build/linux-setup.sh --repair' },
    windows => {
        full   => 'powershell -NoProfile -ExecutionPolicy Bypass -File .\build\windows-setup.ps1',
        repair => 'powershell -NoProfile -ExecutionPolicy Bypass -File .\build\windows-setup.ps1 --repair',
    },
);

# Windows: Claude Code runs its hooks in a plain Git Bash shell, which puts
# Git's own directories, and its Perl, in front of the PATH it inherits and
# reads no startup file unless BASH_ENV names one. Setup's managed blocks in
# ~/.bashrc and ~/.bash_profile put Strawberry Perl first, and its BASH_ENV
# makes the plain shell read ~/.bashrc. Whatever the cause, the setup puts it
# right, and a new user variable reaches only processes started after it.
sub windows_path_scenario {
    my ( $result, $fails, $shell ) = @_;
    return 'Likely cause: Strawberry Perl is not installed, or Git Bash is missing and Claude Code runs its hooks in PowerShell.'
        if $fails->(1);
    return 'Likely cause: the shell configuration does not put the development tools first: the managed block in ~/.bashrc or ~/.bash_profile, '
        . "or setup's ~/bin/python3 wrapper, is missing, or a later line puts Git's directories back in front."
        if $shell || !$result->{8}{login_ok}{perl};
    return defined $ENV{BASH_ENV}
        ? "Likely cause: BASH_ENV is $ENV{BASH_ENV}, which does not put Strawberry Perl first in the plain Git Bash shell Claude Code runs its hooks in."
        : "Likely cause: BASH_ENV is not set, so the plain Git Bash shell Claude Code runs its hooks in never reads ~/.bashrc, and Git's own Perl comes first.";
}

sub user_message {
    my ($result) = @_;
    my $fails = sub { ( $result->{ $_[0] }{result} // '' ) eq 'FAIL' };
    my %tool  = ( 1 => 'perl', 2 => 'perl', 6 => 'bash', 7 => 'python3' );
    my @path    = grep { $fails->($_) && ( $_ == 1 || $_ == 2 || ( ( $_ == 6 || $_ == 7 ) && !$result->{$_}{in_place} ) ) } 1, 2, 6, 7;
    my @install = grep { $fails->($_) && ( $_ == 3 || ( ( $_ == 6 || $_ == 7 ) && $result->{$_}{in_place} ) ) } 3, 6, 7;
    my $full   = $setup{$host}{full};
    my $repair = $setup{$host}{repair} // $full;
    my $run    = sub { defined $_[0] ? "run $_[0]" : 'follow the install steps in README.md' };
    my @lines;
    # A login shell that starts the same tool shares its install fault, so
    # condition 8 names the shell configuration only beside a wrong tool, or
    # alone.
    my $shell = $fails->(8) && ( @path || !@install );
    if ( @path || $shell ) {
        my $what = @path
            ? 'this session finds ' . join( '; ', map { "$tool{$_} $result->{$_}{found}" } @path )
            : 'this session finds the right tools, but a new terminal does not';
        push @lines, "Environment check: $what.";
        if ( $host eq 'windows' ) {
            push @lines, windows_path_scenario( $result, $fails, $shell ),
                'Fix: ' . $run->( $fails->(1) ? $full : $repair ) . ', then quit Claude Code and every terminal window, and start it again.';
        }
        elsif ($shell) {
            push @lines, 'Likely cause: the shell configuration does not put the development tools first in a new terminal.',
                'Fix: ' . $run->($repair) . ', then start Claude Code from a new terminal.';
        }
        else {
            push @lines, "Likely cause: Claude Code was started with a PATH that differs from a new terminal's, which finds the right tools.",
                'Fix: quit Claude Code, open a new terminal, and start it there.';
        }
    }
    elsif (@install) {
        my @problems = map { ( my $f = $result->{$_}{found} ) =~ s/ \(perl: [^)]*\)$//; grep { !m{^/} } split /; /, $f } @install;
        my @missing  = grep { /does not (?:load|import)/ } @problems;
        my @another  = grep { !/does not (?:load|import)|^\d+ of \d+ do not/ } @problems;
        my $first    = ( @missing ? $missing[0] : $another[0] ) // $problems[0];
        my $more     = @problems > 1 ? ' (' . ( @problems - 1 ) . ' more in the full report: perl process/check-environment.pl)' : '';
        push @lines, "Environment check: $first$more.";
        if ( @missing && $host eq 'windows' ) {
            push @lines, 'Likely cause: the setup has not run on this host, Strawberry Perl was reinstalled, or build/cpanfile.windows is behind build/cpanfile.',
                'Fix: ' . $run->($full) . '.';
        }
        elsif (@missing) {
            push @lines, 'Likely cause: the setup has not run on this host, or modules were added or upgraded since it last ran.', 'Fix: ' . $run->($full) . '.';
        }
        elsif ( $host eq 'windows' ) {
            push @lines, 'Likely cause: a copy installed outside the setup is found first.',
                "Fix: remove that copy (a pip install, a cpanm copy beside Strawberry Perl's own, or the PERL5LIB entry that adds it), then start Claude Code again.";
        }
        else {
            push @lines, 'Likely cause: a copy installed outside the setup is found first.',
                'Fix: remove that copy (a pip install, or the PERL5LIB entry that adds it), then start Claude Code again.';
        }
    }
    if ( $fails->(11) ) {
        push @lines, 'Environment check: this clone checks files out with CRLF line endings.',
            'Fix: clone the repository again with git clone -c core.autocrlf=false.';
    }
    return join "\n", @lines;
}

# --- Main -------------------------------------------------------------------

my ( $hook, $only, $help );
my @args = @ARGV;
my $parsed = eval {
    local $SIG{__WARN__} = sub { die $_[0] };
    GetOptionsFromArray( \@args, 'hook' => \$hook, 'condition=s' => \$only, 'h|help' => \$help );
};
my %wanted;
if ( $parsed && !@args && defined $only ) {
    for my $n ( split /,/, $only ) {
        if ( $n !~ /^\d+$/ || !grep { $_->{n} == $n } @conditions ) { $parsed = 0; last }
        $wanted{$n} = 1;
    }
    $parsed = 0 unless %wanted;
}
if ( !$parsed || @args ) {
    print STDERR usage();
    exit 2;
}
if ($help) {
    print usage();
    exit 0;
}

# Some Perls give $^X as the bare name they were started by; the shell found
# that name on PATH, and so does this.
my $ran_under = File::Spec->file_name_is_absolute($^X) ? $^X : find_on_path($^X) // $^X;

my @lines = (
    'Environment check (process/check-environment.pl)',
    'host:   ' . ( $host_name{$^O} // $^O ),
    "perl:   ran under $ran_under ($^V)",
    'PATH:   ' . ( $ENV{PATH} // '' ),
    '',
);
my ( %count, @failed, %result );
for my $c (@conditions) {
    next if %wanted && !$wanted{ $c->{n} };
    my $test = $c->{tests}{$host};
    my $r = $test ? $test->() : { result => 'n/a' };
    $result{ $c->{n} } = $r;
    $count{ $r->{result} }++;
    push @lines, sprintf '%2d  %-4s  %s', $c->{n}, $r->{result}, $c->{title};
    if ( $r->{result} eq 'FAIL' || $r->{result} eq 'note' ) {
        push @lines, "            expected: $r->{expected}", "            found:    $r->{found}";
    }
    push @lines, map { "            $_" } @{ $r->{context} || [] };
    if ( $r->{result} eq 'FAIL' || $r->{result} eq 'note' ) {
        push @lines, '            see: ' . POINTER . ", condition $c->{n}";
        push @failed, "$c->{n} $c->{title}; see " . POINTER . ", condition $c->{n}" if $r->{result} eq 'FAIL';
    }
}
push @lines, '', join( ', ', map { ( $count{$_} // 0 ) . " $_" } qw(pass FAIL note n/a) );
my $report = join( "\n", @lines ) . "\n";

if ($hook) {
    my %out = ( hookSpecificOutput => { hookEventName => 'SessionStart', additionalContext => $report } );
    if (@failed) {
        $out{systemMessage} = user_message( \%result );
        $out{hookSpecificOutput}{additionalContext} =
            "Act on this in your first reply, before anything else: for each FAIL read the entry its pointer names, "
            . "work out the cause on this host, and tell the user the cause and the step that fixes it. "
            . "A failed check describes this host's environment: it is not a defect of the repository, "
            . "and is never related to an issue, branch or piece of work in progress. "
            . "The user was shown:\n$out{systemMessage}\n\n$report";
    }
    print JSON::PP->new->canonical->encode( \%out ), "\n";
    exit 0;
}
print $report;
exit( @failed ? 1 : 0 );
