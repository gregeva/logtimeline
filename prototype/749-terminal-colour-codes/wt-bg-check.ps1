# wt-bg-check.ps1 -Out <dir> [-Runs 5] [-Terminals one-half-light,campbell,conhost]
#
# What settles the background in three Windows terminals, as an analyst
# meets it (features/749-terminal-colour-codes.md § 14, step 1): a new
# Windows Terminal window on One Half Light, one on Campbell, each 120 by
# 50, and a classic console host window at its own size, each with cmd at
# the repository's root (wt-window.ps1). In each, typed at the prompt,
# <Runs> times:
#
#   cls
#   perl ltl --disable-progress -V background -bs 1440 -oe -n 1 -osum tests\fixtures\http-status-families.txt & perl wt-console-text.pl <label>-<n>.txt
#   echo a line typed after run <n>
#   perl wt-console-text.pl <label>-<n>-typed.txt
#
# with no background option; in the Campbell window once more with -lbg and
# once with -dbg. wt-console-text.pl, run straight after ltl on the same
# command line, writes the console's modes and the screen's text (the -V
# background section among it); the typed line shows the prompt echoes and
# reads a line once ltl has ended, and the window is captured then
# (<label>-<n>.png). <label>-0.txt holds the modes before any run. The
# windows close at the end. Nothing else should cover the top left corner.
param([Parameter(Mandatory)] [string] $Out, [int] $Runs = 5,
      [string[]] $Terminals = @('one-half-light', 'campbell', 'conhost'))
. (Join-Path $PSScriptRoot 'wt-window.ps1')
$helper = Join-Path $PSScriptRoot 'wt-console-text.pl'
$Out    = [IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$ltl    = 'perl ltl --disable-progress -V background -bs 1440 -oe -n 1 -osum tests\fixtures\http-status-families.txt'

function Check([string] $label, [string] $scheme, [string[]] $options) {
    $h = Open-Window "ltl749-bg-$label" $scheme
    Send-Keys $h "perl `"$helper`" `"$Out\$label-0.txt`"{ENTER}"
    Wait-File "$Out\$label-0.txt"
    $n = 0
    foreach ($opt in $options) {
        $n++
        Send-Keys $h 'cls{ENTER}'
        Start-Sleep -Milliseconds 500
        Send-Keys $h ("$ltl$opt & perl `"$helper`" `"$Out\$label-$n.txt`"{ENTER}")
        Wait-File "$Out\$label-$n.txt"
        Send-Keys $h "echo a line typed after run $n{ENTER}"
        Start-Sleep -Milliseconds 800
        Save-Window $h "$Out\$label-$n.png"
        Send-Keys $h "perl `"$helper`" `"$Out\$label-$n-typed.txt`"{ENTER}"
        Wait-File "$Out\$label-$n-typed.txt"
        "{0} run {1}{2}: done" -f $label, $n, $opt
    }
    Close-Window $h
}

$plain = @('') * $Runs
if ($Terminals -contains 'one-half-light') { Check 'one-half-light' 'One Half Light' $plain }
if ($Terminals -contains 'campbell') { Check 'campbell' 'Campbell' ($plain + ' -lbg', ' -dbg') }
if ($Terminals -contains 'conhost') { Check 'conhost' '' $plain }
