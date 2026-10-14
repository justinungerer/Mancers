param([string] $Exe, [int] $Seconds = 60)
Add-Type @'
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public class WinProbe {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  public struct RECT { public int L, T, R, B; }
  public static List<string> List(uint pid) {
    var res = new List<string>();
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); if (p == pid) { var t = new StringBuilder(256); GetWindowText(h, t, 256); var c = new StringBuilder(256); GetClassName(h, c, 256); RECT r; GetWindowRect(h, out r); res.Add(String.Format("{0} vis={1} class={2} title='{3}' rect={4}x{5}", h, IsWindowVisible(h), c, t, r.R - r.L, r.B - r.T)); } return true; }, IntPtr.Zero);
    return res;
  }
}
'@
$psi = New-Object System.Diagnostics.ProcessStartInfo $Exe
$psi.UseShellExecute = $false
$psi.WorkingDirectory = Split-Path $Exe
$psi.EnvironmentVariables.Remove('WGPU_BACKEND')
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
$err = $p.StandardError.ReadToEndAsync()
for ($i = 0; $i -lt $Seconds; $i += 5) {
  Start-Sleep -Seconds 5
  $p.Refresh()
  if ($p.HasExited) { "t=$($i+5)s exited $($p.ExitCode)"; break }
  "t=$($i+5)s cpu=$([int]$p.TotalProcessorTime.TotalSeconds)s ws=$([int]($p.WorkingSet64/1MB))MB main=$($p.MainWindowHandle) title='$($p.MainWindowTitle)'"
  [WinProbe]::List([uint32]$p.Id) | Select-Object -First 6 | ForEach-Object { "   $_" }
}
if (-not $p.HasExited) { [void]$p.CloseMainWindow(); if (-not $p.WaitForExit(10000)) { $p.Kill(); 'killed' } }
'--- stderr (first 40 lines) ---'
($err.Result -split "`n") | Select-Object -First 40
