$ErrorActionPreference = 'Stop'
$notes = 'C:\Users\ELMYZ\OneDrive - Bayer\Documents\AI_temp\New folder (2)\renderroulette'
$exe = Join-Path $env:LOCALAPPDATA 'Programs\RenderRoulette\renderroulette.exe'
Add-Type -ReferencedAssemblies System.Drawing @'
using System; using System.Drawing; using System.Runtime.InteropServices;
public class CapRR {
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  struct RECT { public int L, T, R, B; }
  public static Bitmap Grab(IntPtr h) {
    RECT r; GetWindowRect(h, out r);
    var b = new Bitmap(Math.Max(1, r.R - r.L), Math.Max(1, r.B - r.T));
    using (var g = Graphics.FromImage(b)) {
      IntPtr dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc);
    }
    return b;
  }
}
'@
[void][CapRR]::SetProcessDPIAware()
Get-Process renderroulette -ErrorAction SilentlyContinue | ForEach-Object { $_.CloseMainWindow() | Out-Null; $_.WaitForExit(10000) | Out-Null }
$psi = New-Object System.Diagnostics.ProcessStartInfo $exe
$psi.UseShellExecute = $false
$psi.WorkingDirectory = (Split-Path $exe)
$psi.EnvironmentVariables.Remove('WGPU_BACKEND')
$p = [System.Diagnostics.Process]::Start($psi)
for ($w = 0; $w -lt 60 -and $p.MainWindowHandle -eq 0 -and -not $p.HasExited; $w++) { Start-Sleep -Seconds 1; $p.Refresh() }; Start-Sleep -Seconds 4
$p.Refresh()
if ($p.HasExited) { throw "installed app exited early: $($p.ExitCode)" }
Write-Output "title=$($p.MainWindowTitle) pid=$($p.Id)"
$shot = Join-Path $notes 'installed-app.png'
([CapRR]::Grab($p.MainWindowHandle)).Save($shot)
Write-Output "shot=$shot"
[void]$p.CloseMainWindow()
if (-not $p.WaitForExit(20000)) { $p.Kill(); $p.WaitForExit() }
Write-Output "exit=$($p.ExitCode)"
