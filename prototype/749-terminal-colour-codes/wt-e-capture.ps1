# wt-e-capture.ps1 -Scheme <name> -File <ansi-file> -Signal <prefix> -OutDir <dir> -Cols N -Rows N
#
# The Windows counterpart of e-measure.sh's window, opened as wt-capture.ps1
# opens one: a new Windows Terminal window in the colour scheme <name>
# (wt --colorScheme, the settings file untouched), <Cols> by <Rows>, at the
# screen's top left corner, in which wt-e-show.sh prints <ansi-file> a page
# of <Rows> lines at a time. After each page, when <prefix>.page-<k>
# appears, the window is brought to the front and captured from the screen
# at the display's own scale (the window's frame as DWM draws it, no
# invisible border) into <OutDir>/page-<k>.png, an 8-bit RGB PNG, and
# <prefix>.page-<k>.taken tells the window to go on. When <prefix>.end
# appears the window has printed everything and closes itself. Prints the
# window's pixel size and the number of pages.
#
# Run from Git Bash:
#   powershell -NoProfile -ExecutionPolicy Bypass -File wt-e-capture.ps1 -Scheme Campbell -File <f> -Signal <prefix> -OutDir <dir> -Cols 190 -Rows 51
# Nothing is typed into the window; it is on screen for about a second per page.
param(
    [Parameter(Mandatory)] [string] $Scheme,
    [Parameter(Mandatory)] [string] $File,
    [Parameter(Mandatory)] [string] $Signal,
    [Parameter(Mandatory)] [string] $OutDir,
    [Parameter(Mandatory)] [int] $Cols,
    [Parameter(Mandatory)] [int] $Rows,
    [double] $Settle = 1.0,
    [double] $PageSettle = 0.4
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WtE749 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
}
'@
[WtE749]::SetProcessDPIAware() | Out-Null

$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$bash  = Join-Path $env:ProgramFiles 'Git\usr\bin\bash.exe'
$title = 'ltl749-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
function Fwd([string] $p) { (Resolve-Path -LiteralPath $p).Path -replace '\\', '/' }
$show  = Fwd (Join-Path $here 'wt-e-show.sh')
$file  = Fwd $File
$sig   = $Signal -replace '\\', '/'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$wtArgs = "-w new --size $Cols,$Rows --pos 0,0 --title $title --suppressApplicationTitle " +
          "--colorScheme `"$Scheme`" `"$bash`" `"$show`" `"$file`" $Rows `"$sig`""
Start-Process -FilePath 'wt.exe' -ArgumentList $wtArgs | Out-Null

$h = [IntPtr]::Zero
for ($i = 0; $i -lt 100 -and $h -eq [IntPtr]::Zero; $i++) {
    Start-Sleep -Milliseconds 100
    $h = [WtE749]::FindWindow('CASCADIA_HOSTING_WINDOW_CLASS', $title)
}
if ($h -eq [IntPtr]::Zero) { throw "no Windows Terminal window titled $title appeared" }

$k = 0; $w = 0; $ht = 0
while ($true) {
    $page = "$Signal.page-$k"; $end = "$Signal.end"
    for ($i = 0; $i -lt 400 -and -not (Test-Path -LiteralPath $page) -and -not (Test-Path -LiteralPath $end); $i++) {
        Start-Sleep -Milliseconds 50
    }
    if (-not (Test-Path -LiteralPath $page)) { break }
    [WtE749]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Seconds $(if ($k -eq 0) { $Settle } else { $PageSettle })
    $r = New-Object WtE749+RECT
    if ([WtE749]::DwmGetWindowAttribute($h, 9, [ref] $r, 16) -ne 0) { throw 'DwmGetWindowAttribute failed' }
    $w = $r.R - $r.L; $ht = $r.B - $r.T
    $bmp = New-Object System.Drawing.Bitmap $w, $ht, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size $w, $ht))
    $g.Dispose()
    $bmp.Save([IO.Path]::GetFullPath((Join-Path $OutDir "page-$k.png")), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    New-Item -ItemType File -Path "$page.taken" -Force | Out-Null
    $k++
}
if (-not (Test-Path -LiteralPath "$Signal.end")) { throw "$title did not finish: no page $k and no end signal" }
for ($i = 0; $i -lt 30 -and [WtE749]::IsWindow($h); $i++) { Start-Sleep -Milliseconds 100 }
if ([WtE749]::IsWindow($h)) { [WtE749]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null }
"{0}x{1} {2} pages" -f $w, $ht, $k
