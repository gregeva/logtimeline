# wt-capture.ps1 -Scheme <name> -File <ansi-file> -Out <out.png> [-Cols N] [-Rows N] [-Fullscreen]
#
# The Windows counterpart of open-capture.sh: opens a new Windows Terminal
# window in the colour scheme <name> (wt --colorScheme, the settings file
# untouched) at <Cols> by <Rows>, or full screen where a window of that many
# rows would not fit on the display, in which wt-show.sh sets the UTF-8 code
# page and prints <ansi-file> with cat and nothing after it. Then brings the
# window to the front, captures it from the screen at the display's own
# scale (the window's frame as DWM draws it, no invisible border) into an
# 8-bit RGB PNG, and closes it. Prints the window's pixel size and <out.png>.
#
# Run from Git Bash:
#   powershell -NoProfile -ExecutionPolicy Bypass -File wt-capture.ps1 -Scheme Campbell -File <f> -Out <png>
# The window is on screen for about three seconds; nothing is typed into it.
param(
    [Parameter(Mandatory)] [string] $Scheme,
    [Parameter(Mandatory)] [string] $File,
    [Parameter(Mandatory)] [string] $Out,
    [int] $Cols = 110,
    [int] $Rows = 40,
    [double] $Settle = 1.5,
    [switch] $Fullscreen
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Wt749 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
}
'@
[Wt749]::SetProcessDPIAware() | Out-Null

$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$bash  = Join-Path $env:ProgramFiles 'Git\usr\bin\bash.exe'
$title = 'ltl749-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$done  = Join-Path ([IO.Path]::GetTempPath()) "$title.done"
function Fwd([string] $p) { (Resolve-Path -LiteralPath $p).Path -replace '\\', '/' }
$show  = Fwd (Join-Path $here 'wt-show.sh')
$file  = Fwd $File
$doneF = $done -replace '\\', '/'

$place  = if ($Fullscreen) { '--fullscreen' } else { "--size $Cols,$Rows" }
$wtArgs = "-w new $place --title $title --suppressApplicationTitle " +
          "--colorScheme `"$Scheme`" `"$bash`" `"$show`" `"$file`" `"$doneF`""
Start-Process -FilePath 'wt.exe' -ArgumentList $wtArgs | Out-Null

$h = [IntPtr]::Zero
for ($i = 0; $i -lt 100 -and $h -eq [IntPtr]::Zero; $i++) {
    Start-Sleep -Milliseconds 100
    $h = [Wt749]::FindWindow('CASCADIA_HOSTING_WINDOW_CLASS', $title)
}
if ($h -eq [IntPtr]::Zero) { throw "no Windows Terminal window titled $title appeared" }
[Wt749]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Seconds $Settle

$r = New-Object Wt749+RECT
if ([Wt749]::DwmGetWindowAttribute($h, 9, [ref] $r, 16) -ne 0) { throw 'DwmGetWindowAttribute failed' }
$w = $r.R - $r.L; $ht = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $ht, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size $w, $ht))
$g.Dispose()
$outFull = [IO.Path]::GetFullPath($Out)
$bmp.Save($outFull, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

New-Item -ItemType File -Path $done -Force | Out-Null
for ($i = 0; $i -lt 30 -and [Wt749]::IsWindow($h); $i++) { Start-Sleep -Milliseconds 100 }
if ([Wt749]::IsWindow($h)) { [Wt749]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null }
Remove-Item -LiteralPath $done -ErrorAction SilentlyContinue
"{0}x{1} {2}" -f $w, $ht, $outFull
