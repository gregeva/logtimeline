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
# condition that does not pass at its entry in the troubleshooting section of
# the specification; it carries no remedies. Run by every setup script's
# --validate, at the end of a full setup, and at session start by the hook in
# .claude/settings.json. Specification: features/750-interpreter-resolution.md.
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

use constant POINTER      => 'features/750-interpreter-resolution.md § Troubleshooting a failed condition';
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

# The first executable of this name on PATH, or undef.
sub find_on_path {
    my ($name) = @_;
    my @exts = $host eq 'windows' ? ( '', '.exe', '.bat', '.cmd' ) : ('');
    for my $dir ( split /\Q$Config{path_sep}\E/, $ENV{PATH} // '' ) {
        next if $dir eq '';
        for my $ext (@exts) {
            my $path = File::Spec->catfile( $dir, "$name$ext" );
            return $path if -f $path && -x _;
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
# it touches that terminal, and would run into the timeout.
sub run_capture {
    my (@cmd) = @_;
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

# Started with the perl on PATH for conditions 3 and 4: its first argument is a
# directory the setup installs modules into beyond the Perl's own (empty for
# none), the rest the modules. For each module, one tab-separated line: its
# name, whether it loads, the file it loaded from, whether that file lies
# outside the Perl's own @INC (the one it was built with, without what
# PERL5LIB or PERLLIB add) and the setup's directory, and every copy of it on
# @INC outside the core directories, joined by ";". The core directories are
# Config's privlib and archlib and any built-in one holding strict.pm (Debian
# splits its core into perl-base). A dual-life module upgraded over its core
# copy is one copy; a module from anywhere else, or two copies outside the
# core, did not come from the setup alone.
my $perl_modules = <<'END_PERL';
use Config; use Cwd ();
my ( $extra, @modules ) = @ARGV;
sub norm { my $p = Cwd::realpath( $_[0] ) // $_[0]; $p =~ tr{\\}{/}; $^O eq 'MSWin32' ? lc $p : $p }
sub under { my ( $file, @roots ) = @_; scalar grep { index( $file, "$_/" ) == 0 } @roots }
my %added = map { norm($_) => 1 } grep { length } map { split /\Q$Config{path_sep}\E/ } grep { defined } @ENV{qw(PERL5LIB PERLLIB)};
my @builtin = grep { !$added{$_} } map { norm($_) } grep { !ref && $_ ne '.' && -d } @INC;
my @core = ( ( map { norm($_) } grep { defined && length } @Config{qw(privlibexp archlibexp)} ), grep { -f "$_/strict.pm" } @builtin );
my @own  = ( @builtin, length $extra ? norm($extra) : () );
for my $m (@modules) {
    ( my $f = "$m.pm" ) =~ s{::}{/}g;
    my $loads = eval { require $f; 1 } ? 1 : 0;
    my $file  = $loads && defined $INC{$f} && !ref $INC{$f} ? norm( $INC{$f} ) : '';
    my %seen;
    my @copies = grep { !$seen{$_}++ && !under( $_, @core ) }
        map { norm("$_/$f") } grep { !ref && -f "$_/$f" } @INC;
    print join( "\t", $m, $loads, $file, ( $file ne '' && !under( $file, @own ) ? 1 : 0 ), join( ';', @copies ) ), "\n";
}
END_PERL

# Load each module in the Perl on PATH and judge where it loaded from: a hash
# per module in cpanfile order, or undef when that Perl could not be started.
sub modules_judged {
    my ( $perl, @modules ) = @_;
    my $extra = $host eq 'linux' ? "$ENV{HOME}/perl5/lib/perl5" : '';
    # Loading the profiler starts it, and it writes nytprof.out into the
    # current directory; start=no loads it without profiling.
    local $ENV{NYTPROF} = 'start=no';
    my ( $status, $out ) = run_capture( $perl->{path}, '-e', $perl_modules, $extra, @modules );
    return undef if $status != 0;
    return [ map { my %m; @m{qw(name loads file outside copies)} = split /\t/, $_, -1; \%m } split /\n/, $out ];
}

# Where this host's setup puts each development tool: the test its resolved
# path passes, and how that reads in a report. A tool absent from a host's
# entry may be anywhere on that host. A python3 entry's modules test is passed
# each module's name and the resolved path of the file it loads from; without
# one, a module may load from anywhere.
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
        python3 => { test => sub { $_[0] =~ m{^/(usr/)?bin/} }, text => "the distribution's, in /usr/bin" },
    },
    windows => {
        perl => { test => sub { $_[0] =~ /strawberry/i }, text => "Strawberry Perl's, not Git's own /usr/bin/perl" },
    },
);

sub expectation {
    my ($name) = @_;
    my $what  = { perl => 'the development Perl', bash => 'bash 4 or later', python3 => 'a python3 that imports NumPy and SciPy' }->{$name};
    my $place = $place{$host}{$name};
    return $place ? "$what, $place->{text}" : $what;
}

my %measured;

# Started with python3 for condition 7: one tab-separated line per module, its
# name, the resolved file it loads from, whether that file is in the user's
# site-packages (where pip --user installs), and every installed copy of it
# Python can see on sys.path, as version@metadata-directory, joined by ";".
# On every host, a module from the user's site-packages or one installed more
# than once is a copy that did not come from the setup alone.
my $python_modules = join "\n",
    'import os, site, importlib, importlib.metadata as md',
    'user = os.path.normcase(os.path.realpath(site.getusersitepackages())) + os.sep',
    'for n in ("numpy", "scipy"):',
    '    f = os.path.normcase(os.path.realpath(importlib.import_module(n).__file__))',
    '    found = sorted({(d.version, os.path.realpath(str(getattr(d, "_path", "")))) for d in md.distributions() if (d.metadata["Name"] or "").lower() == n})',
    '    print("\t".join([n, f, str(f.startswith(user)), ";".join(v + "@" + p for v, p in found)]))';

# Whether a tool meets what this host's setup provides, and what was found.
# What is measured by starting the tool is remembered by its resolved path, so
# a tool reached twice is started once. A python3 outside its place is not
# started: on macOS /usr/bin/python3 is a stub that may offer to install the
# command line tools.
sub judge {
    my ( $name, $tool ) = @_;
    my $place    = $place{$host}{$name};
    my $in_place = !$place || $place->{test}->( $tool->{real} );
    my $measure  = sub { my ($code) = @_; $measured{"$name $tool->{real}"} //= [ $code->() ]; @{ $measured{"$name $tool->{real}"} } };
    if ( $name eq 'perl' ) {
        my ($version) = $measure->( sub { perl_version($tool) } );
        return ( $in_place, describe( $tool, $version ) );
    }
    if ( $name eq 'bash' ) {
        my ($version) = $measure->( sub { bash_version($tool) } );
        my $ok = $in_place && defined $version && ( split /\./, $version )[0] >= 4;
        return ( $ok, describe( $tool, $version // 'version not read' ) );
    }
    return ( 0, describe($tool) ) unless $in_place;
    my ( $status, $out ) = $measure->( sub { run_capture( $tool->{path}, '-B', '-c', $python_modules ) } );
    return ( 0, describe($tool) . '; NumPy or SciPy does not import' ) if $status != 0;
    my $modules = $place && $place->{modules};
    my %label = ( numpy => 'NumPy', scipy => 'SciPy' );
    my @wrong;
    for ( split /\n/, $out ) {
        my ( $name, $file, $in_user_site, $installs ) = split /\t/, $_, -1;
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
    return ( 1, describe($tool) . '; NumPy and SciPy import' ) unless @wrong;
    return ( 0, describe($tool) . '; ' . join( '; ', @wrong ) );
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
    my ( $ok, $found ) = judge( $name, $tool );
    return $ok ? passed( found => $found ) : { result => $severity, expected => $expected, found => $found };
}

sub test_modules {
    my ( $cpanfile, $develop, $severity ) = @_;
    my $file = File::Spec->catfile( $repo_root, 'build', $cpanfile );
    my @modules = cpanfile_modules( $file, $develop );
    my $expected = 'the perl on PATH loads every ' . ( $develop ? 'development-only' : 'runtime' ) . " module of build/$cpanfile";
    return { result => 'FAIL', expected => $expected, found => "build/$cpanfile lists no modules, or cannot be read" }
        unless @modules;
    my $perl = tool('perl') or return missing_tool( 'perl', $severity, $expected );
    my $judged = modules_judged( $perl, @modules );
    return { result => $severity, expected => $expected, found => "$perl->{path} could not be started" }
        unless defined $judged;
    my @failed = map { $_->{name} } grep { !$_->{loads} } @$judged;
    my @wrong  = (
        ( map { "$_->{name} loads from $_->{file}, outside this Perl's install and the setup's" } grep { $_->{outside} } @$judged ),
        ( map { my @c = split /;/, $_->{copies}; @c > 1 ? "$_->{name} is installed " . scalar(@c) . ' times: ' . join( ', ', @c ) : () }
            @$judged ),
    );
    return passed( found => scalar(@modules) . ' modules load' ) unless @failed || @wrong;
    my $count = @failed;
    my @found;
    push @found, "$failed[0] does not load" . ( $count > 1 ? "; $count of " . scalar(@modules) . ' do not: ' . join( ', ', @failed ) : '' ) if @failed;
    push @found, @wrong;
    return { result => $severity, expected => "$expected, each from this Perl's own install or the setup's, once", found => join( '; ', @found ) . " (perl: $perl->{path})" };
}

sub test_home_modules_visible {
    my $expected = "PERL5LIB carries $ENV{HOME}/perl5";
    my @entries  = split /\Q$Config{path_sep}\E/, $ENV{PERL5LIB} // '';
    return passed( found => "PERL5LIB=$ENV{PERL5LIB}" ) if grep { index( $_, "$ENV{HOME}/perl5" ) == 0 } @entries;
    return { result => 'FAIL', expected => $expected, found => defined $ENV{PERL5LIB} ? "PERL5LIB=$ENV{PERL5LIB}" : 'PERL5LIB is not set' };
}

# What a shell started from a clean environment resolves for each tool, as
# { name => { path, real } or undef }. Only the variables a login shell needs
# to find its files are passed on.
sub resolved_in_clean_shell {
    my ( $shell, $mode ) = @_;
    my @env = map { "$_=$ENV{$_}" } grep { defined $ENV{$_} } qw(HOME USER LOGNAME TERM ZDOTDIR);
    my ( $status, $out ) = run_capture( 'env', '-i', @env, $shell, $mode,
        'for t in perl bash python3; do printf "%s=%s\n" "$t" "$(command -v "$t")"; done' );
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
    my @wrong;
    for my $name (@names) {
        my $tool = $resolved{'login (-lc)'}{$name};
        if ( !$tool ) { push @wrong, "no $name"; next }
        my ( $ok, $found ) = judge( $name, $tool );
        push @wrong, "$name $found" unless $ok;
    }
    my $show = sub { my ($t) = @_; $t ? $t->{real} : 'none' };
    my @context = ( sprintf '%-28s %s', 'on the PATH this check saw:', join '  ', map { "$_=" . $show->( tool($_) ) } @names );
    push @context, map { my $m = $_->[0]; sprintf '%-28s %s', "$m:", join '  ', map { "$_=" . $show->( $resolved{$m}{$_} ) } @names } @modes;
    my $expected = "a login $shell started from a clean environment resolves perl, bash and python3 as conditions 2, 6 and 7 expect ($file_hint)";
    return passed( context => \@context ) unless @wrong;
    return { result => 'FAIL', expected => $expected, found => 'the login shell resolves ' . join( '; ', @wrong ), context => \@context };
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
    { n => 5, title => 'modules installed under the home are visible to it',
      tests => { linux => \&test_home_modules_visible } },
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
my ( %count, @failed );
for my $c (@conditions) {
    next if %wanted && !$wanted{ $c->{n} };
    my $test = $c->{tests}{$host};
    my $r = $test ? $test->() : { result => 'n/a' };
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
    $out{systemMessage} = 'Environment check: ' . scalar(@failed) . ' condition' . ( @failed == 1 ? '' : 's' )
        . " failed\n" . join( "\n", map {"  $_"} @failed )
        if @failed;
    print JSON::PP->new->canonical->encode( \%out ), "\n";
    exit 0;
}
print $report;
exit( @failed ? 1 : 0 );
