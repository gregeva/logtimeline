# wt-notice-check.ps1 -Out <dir> [-Schemes 'One Half Light','Campbell']
#
# The notice surfaces as ltl draws them in Windows Terminal with no
# background option, so the terminal's answer settles the set
# (features/749-terminal-colour-codes.md § 14, step 3). In a new window per
# scheme and surface, with cmd at the repository's root (wt-window.ps1),
# typed at the prompt:
#
#   panel    120 by 50: --notice-fixture panel-categories, the deferred
#            panel; captured once the run has ended
#   ask      120 by 50: --notice-fixture ask-modal, the modal question;
#            captured while it asks, then Esc takes its default and the
#            window is captured again once the run has ended
#   browser  120 by 34: --notice-fixture browser-many, whose thirty notices
#            open the browser; keys Down, 7, Up, Up, Enter layer a notice's
#            options over it, captured then; Esc closes them (captured),
#            and q ends the run: while it has not five seconds after a q,
#            the window is captured (-q<n>) and q sent again, three at most
#
# each as perl ltl --disable-progress -bs 1440 -oe -n 1 --notice-fixture
# <set> tests\fixtures\format-detection\access-combined-duration.txt, with
# the timings of tests/validate-notices.sh's tmux scenarios. Captures are
# <scheme>-<surface>[-<moment>].png. Nothing else should cover the top left
# corner.
param([Parameter(Mandatory)] [string] $Out, [string[]] $Schemes = @('One Half Light', 'Campbell'))
. (Join-Path $PSScriptRoot 'wt-window.ps1')
$Out = [IO.Path]::GetFullPath($Out)
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$ltl = 'perl ltl --disable-progress -bs 1440 -oe -n 1 --notice-fixture {0} tests\fixtures\format-detection\access-combined-duration.txt'

foreach ($scheme in $Schemes) {
    $tag = $scheme -replace ' ', '-'

    $h = Open-Window "ltl749-notice-$tag-panel" $scheme
    Send-Keys $h ('cls{ENTER}')
    Send-Keys $h (($ltl -f 'panel-categories') + " & type nul > `"$Out\$tag-panel.done`"{ENTER}")
    Wait-File "$Out\$tag-panel.done"
    Save-Window $h "$Out\$tag-panel.png"
    Close-Window $h

    $h = Open-Window "ltl749-notice-$tag-ask" $scheme
    Send-Keys $h ('cls{ENTER}')
    Send-Keys $h (($ltl -f 'ask-modal') + " & type nul > `"$Out\$tag-ask.done`"{ENTER}")
    Start-Sleep -Seconds 2.5
    Save-Window $h "$Out\$tag-ask-asking.png"
    Send-Keys $h '{ESC}'
    Wait-File "$Out\$tag-ask.done"
    Save-Window $h "$Out\$tag-ask-ended.png"
    Close-Window $h

    $h = Open-Window "ltl749-notice-$tag-browser" $scheme 120 34
    Send-Keys $h ('cls{ENTER}')
    Send-Keys $h (($ltl -f 'browser-many') + " & type nul > `"$Out\$tag-browser.done`"{ENTER}")
    Start-Sleep -Seconds 3
    Save-Window $h "$Out\$tag-browser-open.png"
    foreach ($k in @(@('{DOWN}', 0.4), @('7', 0.4), @('{UP}', 0.3), @('{UP}', 0.4), @('{ENTER}', 0.8))) {
        Send-Keys $h $k[0]
        Start-Sleep -Seconds $k[1]
    }
    Save-Window $h "$Out\$tag-browser-layered.png"
    Send-Keys $h '{ESC}'
    Start-Sleep -Seconds 0.5
    Save-Window $h "$Out\$tag-browser-esc.png"
    # q ends the run; while it has not, the window is captured and q sent again
    $q = 0
    while (-not (Test-Path -LiteralPath "$Out\$tag-browser.done") -and $q -lt 3) {
        $q++
        Send-Keys $h 'q'
        for ($i = 0; $i -lt 50 -and -not (Test-Path -LiteralPath "$Out\$tag-browser.done"); $i++) { Start-Sleep -Milliseconds 100 }
        if (-not (Test-Path -LiteralPath "$Out\$tag-browser.done")) { Save-Window $h "$Out\$tag-browser-q$q.png" }
    }
    "$scheme`: browser ended after $q q"
    Wait-File "$Out\$tag-browser.done"
    Close-Window $h
    "$scheme`: panel, ask and browser captured"
}
