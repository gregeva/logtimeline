# wt-window.ps1: dot-sourced by wt-bg-check.ps1, wt-notice-check.ps1 and
# wt-show-runs.ps1.
#
# A window of cmd at the repository's root, opened as an analyst opens one:
# a new Windows Terminal window in a colour scheme (wt --colorScheme, the
# settings file untouched) or a classic console host window (conhost.exe),
# at the screen's top left corner. Keys are typed into that window only:
# it is brought to the front and checked to be there before every key, and
# nothing is typed otherwise. A capture is the window's frame as DWM draws
# it, from the screen at the display's own scale, as an 8-bit RGB PNG.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win749 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
}
'@
[Win749]::SetProcessDPIAware() | Out-Null
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# A window titled $title: Windows Terminal in $scheme, <cols> by <rows>, or
# with no scheme the classic console host at its own size.
function Open-Window([string] $title, [string] $scheme, [int] $cols = 120, [int] $rows = 50) {
    if ($scheme) {
        Start-Process wt.exe -ArgumentList ("-w new --size $cols,$rows --pos 0,0 --title $title --suppressApplicationTitle " +
            "--colorScheme `"$scheme`" cmd /k cd /d `"$Root`"") | Out-Null
        $class = 'CASCADIA_HOSTING_WINDOW_CLASS'
    } else {
        Start-Process conhost.exe -ArgumentList "cmd /k title $title& cd /d `"$Root`"" | Out-Null
        $class = 'ConsoleWindowClass'
    }
    $h = [IntPtr]::Zero
    for ($i = 0; $i -lt 100 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 100; $h = [Win749]::FindWindow($class, $title) }
    if ($h -eq [IntPtr]::Zero) { throw "no window titled $title appeared" }
    Start-Sleep -Seconds 2
    return $h
}
function Send-Keys([IntPtr] $h, [string] $keys) {
    for ($i = 0; $i -lt 30 -and [Win749]::GetForegroundWindow() -ne $h; $i++) {
        [Win749]::SetForegroundWindow($h) | Out-Null
        Start-Sleep -Milliseconds 100
    }
    if ([Win749]::GetForegroundWindow() -ne $h) { throw 'the window is not in front: no key sent' }
    [System.Windows.Forms.SendKeys]::SendWait($keys)
}
function Save-Window([IntPtr] $h, [string] $file) {
    $r = New-Object Win749+RECT
    if ([Win749]::DwmGetWindowAttribute($h, 9, [ref] $r, 16) -ne 0) { throw 'DwmGetWindowAttribute failed' }
    $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T), ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
    $g.Dispose(); $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
function Wait-File([string] $f, [int] $seconds = 60) {
    for ($i = 0; $i -lt $seconds * 10 -and -not (Test-Path -LiteralPath $f); $i++) { Start-Sleep -Milliseconds 100 }
    if (-not (Test-Path -LiteralPath $f)) { throw "no $f after $seconds seconds" }
    Start-Sleep -Milliseconds 300
}
function Close-Window([IntPtr] $h) {
    Send-Keys $h 'exit{ENTER}'
    for ($i = 0; $i -lt 50 -and [Win749]::IsWindow($h); $i++) { Start-Sleep -Milliseconds 100 }
}
