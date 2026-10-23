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

    Steps that write under Program Files (Strawberry Perl, the interpreter shim)
    need administrator rights. Started without them, the script re-launches just
    those steps elevated and Windows asks once for approval.

.PARAMETER DevDeps
    Also install the development-only Perl modules (the profiler).

.PARAMETER Package
    Also install PAR::Packer, for building the static binary.

.PARAMETER Phase
    Internal. 'User' (default) runs everything and elevates what it must;
    'Machine' runs only the steps that need administrator rights.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\build\windows-setup.ps1
#>
[CmdletBinding()]
param(
    [switch]$DevDeps,
    [switch]$Package,
    [ValidateSet('User', 'Machine')][string]$Phase = 'User'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$StrawberryRoot = 'C:\Strawberry'
$GitRoot = 'C:\Program Files\Git'

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

function Set-ManagedBlock($path, $name, $body) {
    $begin = "# >>> ltl $name >>>"; $end = "# <<< ltl $name <<<"
    $text = if (Test-Path $path) { [IO.File]::ReadAllText($path) } else { '' }
    $re = "(?s)\r?\n?" + [regex]::Escape($begin) + ".*?" + [regex]::Escape($end) + "\r?\n?"
    $text = [regex]::Replace($text, $re, '')
    $block = "`n$begin`n$body`n$end`n"
    # Bash reads these files: LF only, no BOM.
    $text = ($text.TrimEnd() + "`n" + $block) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
}

# ---------------------------------------------------------------- machine phase
if ($Phase -eq 'Machine') {
    Write-Step 'Machine-wide steps (administrator)'
    Install-WingetPackage 'StrawberryPerl.StrawberryPerl'

    # ltl's first line names /opt/homebrew/bin/perl (the macOS development
    # interpreter). Git Bash resolves /opt under the Git install; a one-line
    # wrapper there lets './ltl' run exactly as it does on macOS.
    $shimDir = Join-Path $GitRoot 'opt\homebrew\bin'
    New-Item -ItemType Directory -Force $shimDir | Out-Null
    $shim = "#!/bin/sh`nexec /c/Strawberry/perl/bin/perl.exe `"`$@`"`n"
    [IO.File]::WriteAllText((Join-Path $shimDir 'perl'), $shim, (New-Object Text.UTF8Encoding $false))
    Write-Info "interpreter shim written to $shimDir\perl"
    return
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

Write-Step '[2/7] Strawberry Perl and the interpreter shim (needs administrator)'
$shimFile = Join-Path $GitRoot 'opt\homebrew\bin\perl'
if ((Test-Path "$StrawberryRoot\perl\bin\perl.exe") -and (Test-Path $shimFile)) {
    Write-Info 'Strawberry Perl and the shim are present'
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
$py = Get-Command python -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1
$pyExe = $null
if ($py) { $pyExe = $py.Source }
else {
    # A fresh install is not on this session's PATH until the shell restarts.
    $f = Get-ChildItem "$env:LOCALAPPDATA\Programs\Python\Python313*\python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($f) { $pyExe = $f.FullName }
}
if (-not $pyExe) { throw 'Python 3.13 not found after install' }
& $pyExe -m pip install --quiet --only-binary=:all: numpy scipy
if ($LASTEXITCODE -ne 0) { throw 'pip install numpy scipy failed (no wheel for this architecture?)' }
& $pyExe -c "import platform,numpy,scipy;print('[info] python',platform.python_version(),platform.machine(),'numpy',numpy.__version__,'scipy',scipy.__version__)"

Write-Step '[4/7] Perl packages from build/cpanfile.windows'
$bash = Join-Path $GitRoot 'bin\bash.exe'
$repoPosix = $RepoRoot -replace '\\', '/'
# The cpanfile is generated from the modules ltl loads; generate it before reading it.
& $bash -lc "cd '$repoPosix' && ./build/generate-cpanfile.sh ltl windows" | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'generate-cpanfile.sh failed' }
Push-Location (Join-Path $RepoRoot 'build')
try {
    $cpan = @('--notest', '--cpanfile', 'cpanfile.windows')
    if ($DevDeps) { $cpan += '--with-develop' }
    & cpanm @cpan --installdeps . | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'cpanm failed' }
    if ($Package) { & cpanm --notest PAR::Packer | Out-Host; if ($LASTEXITCODE -ne 0) { throw 'PAR::Packer failed' } }
} finally { Pop-Location }

Write-Step '[5/7] Git Bash: Strawberry Perl ahead of Git''s own Perl'
# Git for Windows ships an MSYS Perl without the CPAN modules ltl needs; it comes
# first on Git Bash's PATH. Put Strawberry Perl in front, and make a login shell
# read .bashrc.
Set-ManagedBlock "$HOME\.bashrc" 'perl' 'export PATH="/c/Strawberry/perl/site/bin:/c/Strawberry/perl/bin:$PATH"'
Set-ManagedBlock "$HOME\.bash_profile" 'bashrc' '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
Write-Info 'wrote managed blocks to ~/.bashrc and ~/.bash_profile'
# Claude Code runs its hooks in a plain Git Bash shell, which puts Git's own
# directories first and reads no startup file unless BASH_ENV names one. A user
# variable reaches every process started after it is set.
$bashEnv = [Environment]::GetEnvironmentVariable('BASH_ENV', 'User')
$bashrc = "$HOME\.bashrc"
if (-not $bashEnv) {
    [Environment]::SetEnvironmentVariable('BASH_ENV', $bashrc, 'User')
    $env:BASH_ENV = $bashrc
    Write-Info "BASH_ENV set to $bashrc; quit Claude Code and every terminal window for it to apply"
} elseif ($bashEnv -eq $bashrc) {
    Write-Info "BASH_ENV is $bashrc"
} else {
    Write-Warn2 "BASH_ENV is $bashEnv, left as it is: Claude Code's hooks find Strawberry Perl only if that file puts it first on PATH"
}
# The harnesses call python3. The WinGet install has only python.exe, so in Git
# Bash python3 falls through to the Microsoft Store stub. A one-line wrapper in
# ~/bin, which Git Bash puts ahead of the Windows PATH, runs the installed Python.
$binDir = Join-Path $HOME 'bin'
New-Item -ItemType Directory -Force $binDir | Out-Null
$pyPosix = '/' + ($pyExe -replace '^([A-Za-z]):', '$1' -replace '\\', '/')
$pyPosix = $pyPosix.Substring(0, 2).ToLower() + $pyPosix.Substring(2)
[IO.File]::WriteAllText((Join-Path $binDir 'python3'), "#!/bin/sh`nexec `"$pyPosix`" `"`$@`"`n", (New-Object Text.UTF8Encoding $false))
Write-Info "python3 wrapper written to ~/bin/python3 -> $pyPosix"

Write-Step '[6/7] Git: line endings'
# Git for Windows defaults to core.autocrlf=true. Every script then has CR LF
# endings and 'bad interpreter' / syntax errors follow. The repository is LF.
Push-Location $RepoRoot
try {
    git config --local core.autocrlf false
    $bad = @(git ls-files --eol | Where-Object { $_ -match 'w/crlf' -and $_ -notmatch 'attr/-text' })
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

Write-Step '[7/7] Verification'
$rows = @(
    @('git', (git --version)),
    @('gh', ((gh --version) | Select-Object -First 1)),
    @('jq', (jq --version)),
    @('perl', ((perl -MConfig -e 'print $^V, q{ }, $Config{archname}'))),   # no inner double quotes: PowerShell 5.1 strips them from native arguments
    @('bash', ((& $bash -lc 'echo $BASH_VERSION'))),
    @('bash perl', ((& $bash -lc 'command -v perl'))),
    @('bash python3', ((& $bash -lc "python3 -c 'import platform, numpy, scipy; print(platform.python_version(), platform.machine(), numpy.__version__, scipy.__version__)' 2>&1"))),   # as the harnesses call it
    @('./ltl', ((& $bash -lc "cd '$repoPosix' && ./ltl --disable-progress -v 2>&1 | grep -ao 'log timeline \[[^]]*\]'")))
)
foreach ($r in $rows) { '{0,-12} {1}' -f $r[0], $r[1] }
cmd /c 'gh auth status >nul 2>&1'
if ($LASTEXITCODE -ne 0) { Write-Warn2 'GitHub CLI is not signed in: run  gh auth login' }
Write-Host "`nDone. Open a new terminal so the updated PATH applies." -ForegroundColor Green
