# wt-show-runs.ps1 -Synth <synth-metrics.log> [-Schemes 'One Half Light','Campbell'] [-Runs <run>,...]
#
# Shows the architect what ltl draws itself on Windows: one maximized
# Windows Terminal window per scheme (wt --colorScheme, the settings file
# untouched), a tab per run, titled "<scheme>: <run>". In each tab, before
# ltl runs, the font is made smaller (Ctrl+minus) by the steps the run needs
# for all of its output to show in the window without scrolling, measured
# on this display (1920 by 1080 at 100%): a maximized window holds 50 rows
# at the default font, 64 two steps smaller, 81 four. Then, typed at the
# cmd prompt, `cls` and wt-run.sh run it with no background option, so the
# terminal's answer selects the set. The windows stay open, each tab at the
# prompt under its run; Ctrl+Tab moves between tabs. Keys go to a tab only
# once its window is checked to be in front (wt-window.ps1).
#
# -SaveTo <dir> also captures each tab once drawn, as
# <dir>/<scheme>-<nn>-<run>.png, and closes the windows at the end.
param([Parameter(Mandatory)] [string] $Synth,
      [string] $SaveTo,
      [string[]] $Schemes = @('One Half Light', 'Campbell'),
      [string[]] $Runs = @('heat-blue', 'heat-magenta', 'heat-red', 'heat-orange', 'heat-pink', 'heat-teal', 'heat-purple',
                           'heat-yellow', 'heat-green', 'heat-cyan', 'fills', 'access-heatmap', 'access-latency', 'levels',
                           'udm', 'notices', 'explain', 'error'))
. (Join-Path $PSScriptRoot 'wt-window.ps1')
$bash = Join-Path $env:ProgramFiles 'Git\usr\bin\bash.exe'
$run  = Join-Path $PSScriptRoot 'wt-run.sh'
$Synth = [IO.Path]::GetFullPath($Synth)
# font steps smaller each run needs: its output's rows, and the prompt, within the window
$steps = @{ 'access-heatmap' = 4; 'access-latency' = 2; 'levels' = 2; 'udm' = 2; 'explain' = 2 }
$done = Join-Path ([IO.Path]::GetTempPath()) 'ltl749-show'
New-Item -ItemType Directory -Force -Path $done | Out-Null

foreach ($scheme in $Schemes) {
    $window = 'ltl749-' + ($scheme -replace ' ', '-')
    $first = $true
    foreach ($r in $Runs) {
        $title = "${scheme}: $r"
        $tab = "new-tab --title `"$title`" --suppressApplicationTitle --colorScheme `"$scheme`" cmd /k cd /d `"$Root`""
        Start-Process wt.exe -ArgumentList ("-w $window " + $(if ($first) { '--maximized ' } else { '' }) + $tab) | Out-Null
        $first = $false
        $h = [IntPtr]::Zero
        for ($i = 0; $i -lt 100 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 100; $h = [Win749]::FindWindow('CASCADIA_HOSTING_WINDOW_CLASS', $title) }
        if ($h -eq [IntPtr]::Zero) { throw "no tab titled $title appeared" }
        Start-Sleep -Seconds 1.5
        for ($s = 0; $s -lt $(if ($steps.ContainsKey($r)) { $steps[$r] } else { 0 }); $s++) { Send-Keys $h '^-'; Start-Sleep -Milliseconds 400 }
        $flag = Join-Path $done "$window-$r.done"
        Remove-Item -Force -ErrorAction SilentlyContinue $flag
        Send-Keys $h "cls & `"$bash`" `"$run`" $r `"$Synth`" & type nul > `"$flag`"{ENTER}"
        Wait-File $flag 180
        if ($SaveTo) {
            New-Item -ItemType Directory -Force -Path $SaveTo | Out-Null
            Save-Window $h (Join-Path ([IO.Path]::GetFullPath($SaveTo)) ("{0}-{1:d2}-{2}.png" -f ($scheme -replace ' ', '-'), ([array]::IndexOf($Runs, $r) + 1), $r))
        }
        "$title`: drawn"
    }
    # each tab's cmd exits in turn; the window closes with its last tab
    for ($i = 0; $SaveTo -and $i -le $Runs.Count -and [Win749]::IsWindow($h); $i++) {
        Send-Keys $h 'exit{ENTER}'
        Start-Sleep -Milliseconds 700
    }
}
