<#
.SYNOPSIS
    Windows development environment setup for LogTimeLine (the counterpart of
    macos-setup.sh).

.DESCRIPTION
    Installs the toolchain with WinGet, installs the Perl and Python packages the
    tool and its test harnesses use, and configures Git and Git Bash so the
    harnesses run. Safe to run again: each step checks before it acts.

    Works on AMD64 and ARM64 Windows. WinGet selects the native installer for
    each package. Strawberry Perl publishes x64 only, so on ARM64 it runs under
    Windows' x64 emulation; the script reports this.

    Steps that write under Program Files (installing Strawberry Perl, removing
    a wrapper left at Git's /opt/homebrew/bin/perl) need administrator rights. Started without them, the script re-launches just
    those steps elevated and Windows asks once for approval.

    The options are read from the arguments, not bound as PowerShell
    parameters, so that they are spelled as on the other hosts' setup scripts;
    run it with -File and they arrive as written. '-Phase Machine' is internal:
    the script re-launching itself elevated.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\build\windows-setup.ps1 --repair
#>

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$StrawberryRoot = 'C:\Strawberry'
$GitRoot = 'C:\Program Files\Git'

$Usage = @'
Usage: build\windows-setup.ps1 [--dev-deps] [--package]
       build\windows-setup.ps1 --repair | --validate

Sets up a Windows host for working on ltl. Run it from PowerShell:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\build\windows-setup.ps1 [option]

  (no option)   full setup: install the tools with WinGet, Strawberry Perl and
                the project's Perl modules, Python with NumPy and SciPy, write
                the Git Bash configuration, run the environment check
  --dev-deps    full setup, plus the development-only modules (the profiler)
  --package     full setup, plus PAR::Packer, for building the static binary
  --repair      install nothing: add to the Git Bash configuration only what
                is missing, then run the environment check
  --validate    install and change nothing: run the environment check
  -h, --help    this text

--repair and --validate take no other option.
Exit status: the environment check's (0 nothing failed, 1 a condition
failed), 1 when a step fails, 2 on a usage error.
'@

$Mode = 'full'; $DevDeps = $false; $Package = $false; $Phase = 'User'; $Help = $false; $UsageError = $false
for ($i = 0; $i -lt $args.Count; $i++) {
    switch -CaseSensitive ($args[$i]) {
        '--dev-deps' { $DevDeps = $true }
        '--package' { $Package = $true }
        { $_ -in '--repair', '--validate' } { if ($Mode -eq 'full') { $Mode = $_.Substring(2) } else { $UsageError = $true } }
        { $_ -in '-h', '--help' } { $Help = $true }
        '-Phase' { $i++; if ($args[$i] -eq 'Machine') { $Phase = 'Machine' } else { $UsageError = $true } }
        default { $UsageError = $true }
    }
}
if ($Mode -ne 'full' -and ($DevDeps -or $Package)) { $UsageError = $true }
if ($UsageError) { [Console]::Error.WriteLine($Usage); exit 2 }
if ($Help) { $Usage; exit 0 }

function Write-Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Write-Info($m) { Write-Host "[info] $m" }
function Write-Warn2($m) { Write-Host "[warn] $m" -ForegroundColor Yellow }

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-HostArch {
    # The environment variables describe this process, not the machine: an
    # emulated x64 shell on an ARM64 host (a shell started by Git Bash, say)
    # reports AMD64. The processor record is the machine.
    $code = (Get-CimInstance Win32_Processor | Select-Object -First 1).Architecture
    switch ($code) { 12 { 'ARM64' } 9 { 'AMD64' } default { throw "Unsupported processor architecture code: $code" } }
}

function Update-SessionPath {
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$m;$u"
}

function Test-WingetPackage($id) {
    $null = winget list --id $id --exact --source winget --accept-source-agreements 2>$null
    $LASTEXITCODE -eq 0
}

function Install-WingetPackage($id, [string]$scope = '') {
    if (Test-WingetPackage $id) { Write-Info "$id already installed"; return }
    $a = @('install', '--id', $id, '--exact', '--source', 'winget', '--silent',
        '--accept-package-agreements', '--accept-source-agreements')
    if ($scope) { $a += @('--scope', $scope) }
    Write-Info "installing $id"
    & winget @a | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "winget install $id failed (exit $LASTEXITCODE)" }
}

# ltl starts through env perl, so nothing is placed at Git Bash's
# /opt/homebrew/bin/perl, a path Git Bash resolves under the Git install. A
# wrapper found there, which ran Strawberry Perl for a first line naming that
# path, is removed, with the directories holding nothing else.
$ShimFile = Join-Path $GitRoot 'opt\homebrew\bin\perl'
function Remove-Shim {
    if (-not (Test-Path $ShimFile)) { return }
    Remove-Item -LiteralPath $ShimFile -Force
    Write-Info "removed $ShimFile"
    $dir = Split-Path $ShimFile
    while ($dir -ne $GitRoot -and (Test-Path $dir) -and -not (Get-ChildItem -Force $dir)) {
        Remove-Item -LiteralPath $dir -Force
        $dir = Split-Path $dir
    }
}

function Test-ManagedBlock($path, $name) {
    (Test-Path $path) -and ([IO.File]::ReadAllText($path).Contains("# >>> ltl $name >>>"))
}

# Appends this script's block, between markers, to a file that does not hold
# it; the rest of the file is left as it is.
function Add-ManagedBlock($path, $name, $body) {
    $text = if (Test-Path $path) { [IO.File]::ReadAllText($path) } else { '' }
    if ($text -and -not $text.EndsWith("`n")) { $text += "`n" }
    if ($text) { $text += "`n" }
    # Bash reads these files: LF only, no BOM.
    $text += "# >>> ltl $name >>>`n$body`n# <<< ltl $name <<<`n"
    [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
}

# The Python WinGet installs. A fresh install is not on this session's PATH
# until the shell restarts.
function Find-Python {
    $py = Get-Command python -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1
    if ($py) { return $py.Source }
    $f = Get-ChildItem "$env:LOCALAPPDATA\Programs\Python\Python313*\python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($f) { return $f.FullName }
    return $null
}

# The environment check, run as Claude Code's session-start hook runs it: in a
# plain Git Bash shell, by Git's own Perl, judging the tools that shell finds.
# PowerShell 5.1 strips double quotes from a native program's arguments, so the
# command holds none.
$GitBash = Join-Path $GitRoot 'bin\bash.exe'
# Git Bash's home: HOME when it is set, the user's profile otherwise.
$BashHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$RepoPosix = $RepoRoot -replace '\\', '/'
function Invoke-Check([string]$options = '') {
    & $GitBash -c "/usr/bin/perl '$RepoPosix/process/check-environment.pl' $options" | Out-Host
    return $LASTEXITCODE
}

# The Git Bash configuration, for --repair and the full setup. Each piece is
# added only when it is missing (none is rewritten):
#   - BASH_ENV, a user variable naming ~/.bashrc: Claude Code runs its hooks in
#     a plain Git Bash shell, which puts Git's own directories, and its Perl,
#     first and reads no startup file unless BASH_ENV names one;
#   - ~/bin/python3: the WinGet install has only python.exe, so in Git Bash
#     python3 falls through to the Microsoft Store stub; a one-line wrapper in
#     ~/bin, which Git Bash puts ahead of the Windows PATH, runs the installed
#     Python;
#   - the blocks that put Strawberry Perl ahead of Git's own Perl in ~/.bashrc,
#     and make a login shell read ~/.bashrc, added when a login shell does not
#     find the tools (the check's condition 8) and this script's block is absent.
function Invoke-ShellStep {
    $bashEnv = [Environment]::GetEnvironmentVariable('BASH_ENV', 'User')
    $bashrc = "$BashHome\.bashrc"
    if (-not $bashEnv) {
        [Environment]::SetEnvironmentVariable('BASH_ENV', $bashrc, 'User')
        # The check below starts in this process's environment.
        $env:BASH_ENV = $bashrc
        Write-Info "BASH_ENV set to $bashrc; quit Claude Code and every terminal window for it to apply"
    } elseif ($bashEnv -eq $bashrc) {
        Write-Info "BASH_ENV is $bashrc"
    } else {
        Write-Warn2 "BASH_ENV is $bashEnv, left as it is: Claude Code's hooks find Strawberry Perl only if that file puts it first on PATH"
    }

    $wrapper = Join-Path $BashHome 'bin\python3'
    if (Test-Path $wrapper) {
        Write-Info '~/bin/python3 is present'
    } else {
        $pyExe = Find-Python
        if (-not $pyExe) { Write-Warn2 'no Python found for ~/bin/python3: run the full setup' }
        else {
            New-Item -ItemType Directory -Force (Split-Path $wrapper) | Out-Null
            $pyPosix = '/' + ($pyExe -replace '^([A-Za-z]):', '$1' -replace '\\', '/')
            $pyPosix = $pyPosix.Substring(0, 2).ToLower() + $pyPosix.Substring(2)
            [IO.File]::WriteAllText($wrapper, "#!/bin/sh`nexec `"$pyPosix`" `"`$@`"`n", (New-Object Text.UTF8Encoding $false))
            Write-Info "python3 wrapper written to ~/bin/python3 -> $pyPosix"
        }
    }

    Write-Info 'Does a login shell find the tools? (environment check, condition 8)'
    if ((Invoke-Check '--condition 8') -eq 0) { Write-Info 'Nothing to add to ~/.bashrc or ~/.bash_profile.'; return }
    $added = $false
    if (-not (Test-ManagedBlock $bashrc 'perl')) {
        Add-ManagedBlock $bashrc 'perl' 'export PATH="/c/Strawberry/perl/site/bin:/c/Strawberry/perl/bin:$PATH"'
        Write-Info 'Added to ~/.bashrc the line that puts Strawberry Perl first'
        $added = $true
    }
    $bashProfile = "$BashHome\.bash_profile"
    $readsBashrc = (Test-Path $bashProfile) -and ([IO.File]::ReadAllText($bashProfile) -match '\.bashrc')
    if (-not $readsBashrc) {
        Add-ManagedBlock $bashProfile 'bashrc' '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
        Write-Info 'Added to ~/.bash_profile the line that makes a login shell read ~/.bashrc'
        $added = $true
    }
    if (-not $added) {
        Write-Info 'Nothing added: ~/.bashrc holds this script''s block and ~/.bash_profile reads ~/.bashrc, so the cause lies in another line; the report above shows what a login shell resolves.'
    }
}

# ---------------------------------------------------------------- machine phase
if ($Phase -eq 'Machine') {
    Write-Step 'Machine-wide steps (administrator)'
    Install-WingetPackage 'StrawberryPerl.StrawberryPerl'
    Remove-Shim
    return
}

# ------------------------------------------------------------ check and repair
if ($Mode -eq 'validate') { exit (Invoke-Check) }
if ($Mode -eq 'repair') {
    Write-Step 'Git Bash configuration'
    Invoke-ShellStep
    Write-Host ''
    exit (Invoke-Check)
}

# ------------------------------------------------------------------ user phase
$arch = Get-HostArch
Write-Step "Host: Windows $arch"
if ($arch -eq 'ARM64') {
    Write-Info 'ARM64: Git, GitHub CLI, jq and Python install natively; Strawberry Perl is x64 and runs emulated.'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store, then re-run.'
}

Write-Step '[1/7] Installing tools with WinGet'
Install-WingetPackage 'Git.Git'
Install-WingetPackage 'GitHub.cli' 'user'
Install-WingetPackage 'jqlang.jq' 'user'
Install-WingetPackage 'Python.Python.3.13' 'user'
Update-SessionPath

Write-Step '[2/7] Strawberry Perl (needs administrator)'
if ((Test-Path "$StrawberryRoot\perl\bin\perl.exe") -and -not (Test-Path $ShimFile)) {
    Write-Info 'Strawberry Perl is present'
} elseif (Test-Admin) {
    & $PSCommandPath -Phase Machine
} else {
    Write-Info 'Windows will ask for approval to run the machine-wide steps'
    $shell = (Get-Process -Id $PID).Path
    $p = Start-Process $shell -Verb RunAs -Wait -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Phase', 'Machine')
    if ($p.ExitCode -ne 0) { throw "Elevated step failed (exit $($p.ExitCode))" }
}
Update-SessionPath
$env:Path = "$StrawberryRoot\perl\site\bin;$StrawberryRoot\perl\bin;$StrawberryRoot\c\bin;$env:Path"

Write-Step '[3/7] Python packages (the statistics harnesses compare against NumPy and SciPy)'
$pyExe = Find-Python
if (-not $pyExe) { throw 'Python 3.13 not found after install' }
& $pyExe -m pip install --quiet --only-binary=:all: numpy scipy
if ($LASTEXITCODE -ne 0) { throw 'pip install numpy scipy failed (no wheel for this architecture?)' }
& $pyExe -c "import platform,numpy,scipy;print('[info] python',platform.python_version(),platform.machine(),'numpy',numpy.__version__,'scipy',scipy.__version__)"

Write-Step '[4/7] Perl packages from build/cpanfile.windows'
# The cpanfile is generated from the modules ltl loads; generate it before reading it.
& $GitBash -lc "cd '$RepoPosix' && ./build/generate-cpanfile.sh ltl windows" | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'generate-cpanfile.sh failed' }
Push-Location (Join-Path $RepoRoot 'build')
try {
    $cpan = @('--notest', '--cpanfile', 'cpanfile.windows')
    if ($DevDeps) { $cpan += '--with-develop' }
    & cpanm @cpan --installdeps . | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'cpanm failed' }
    if ($Package) { & cpanm --notest PAR::Packer | Out-Host; if ($LASTEXITCODE -ne 0) { throw 'PAR::Packer failed' } }
} finally { Pop-Location }

Write-Step '[5/7] Git Bash configuration'
Invoke-ShellStep

Write-Step '[6/7] Git: line endings'
# Git for Windows defaults to core.autocrlf=true. Every script then has CR LF
# endings and 'bad interpreter' / syntax errors follow. The repository is LF.
Push-Location $RepoRoot
try {
    git config --local core.autocrlf false
    # Only a file committed with LF endings checks out again with LF.
    $bad = @(git ls-files --eol | Where-Object { $_ -match '^i/lf\s+w/crlf' -and $_ -notmatch 'attr/-text' })
    if ($bad.Count -gt 0) {
        $dirty = git status --porcelain
        if ($dirty) {
            Write-Warn2 "$($bad.Count) tracked files have CR LF endings but the tree has changes; commit or stash, then re-run."
        } else {
            Write-Info "re-checking out $($bad.Count) tracked files with LF endings"
            foreach ($l in $bad) { $f = ($l -split "`t", 2)[1]; Remove-Item -LiteralPath $f -Force }
            git checkout-index --all
            git add -u   # refreshes the index; stages nothing
        }
    } else { Write-Info 'working tree already LF' }
} finally { Pop-Location }

Write-Step '[7/7] Environment check'
cmd /c 'gh auth status >nul 2>&1'
if ($LASTEXITCODE -ne 0) { Write-Warn2 'GitHub CLI is not signed in: run  gh auth login' }
exit (Invoke-Check)
