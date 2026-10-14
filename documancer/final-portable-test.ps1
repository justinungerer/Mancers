$ErrorActionPreference = 'Stop'
$zip = 'C:\Users\ELMYZ\pc-dist\documancer-0.4.0-windows-x64-portable.zip'
$root = 'C:\Users\ELMYZ\dm-portable'
$notes = 'C:\Users\ELMYZ\OneDrive - Bayer\Documents\AI_temp\New folder (2)\documancer'
$watched = @((Join-Path $env:APPDATA 'DocuMancer'), (Join-Path $env:APPDATA 'PdfCraft'), (Join-Path $env:APPDATA 'pdfcraft'))

Add-Type -ReferencedAssemblies System.Drawing @'
using System; using System.Drawing; using System.Runtime.InteropServices;
public class CapDM2 {
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
[void][CapDM2]::SetProcessDPIAware()

function Snapshot {
  foreach ($dir in $watched) {
    if (Test-Path $dir) { Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { "$($_.FullName)|$($_.Length)|$($_.LastWriteTimeUtc.Ticks)" } }
  }
}

function Run-Portable([string] $exeDir, [string] $label, [string] $shot) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo (Join-Path $exeDir 'documancer.exe')
  $psi.UseShellExecute = $false
  $psi.WorkingDirectory = $exeDir
  $psi.EnvironmentVariables.Remove('WGPU_BACKEND')
  $psi.EnvironmentVariables['PATH'] = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\Wbem"
  $p = [System.Diagnostics.Process]::Start($psi)
  for ($w = 0; $w -lt 60 -and $p.MainWindowHandle -eq 0 -and -not $p.HasExited; $w++) { Start-Sleep -Seconds 1; $p.Refresh() }; Start-Sleep -Seconds 4
  $p.Refresh()
  if ($p.HasExited) { throw "$label exited early with code $($p.ExitCode)" }
  Write-Output "$label running: pid $($p.Id), title '$($p.MainWindowTitle)', exe $($p.MainModule.FileName)"
  if ($shot) { ([CapDM2]::Grab($p.MainWindowHandle)).Save($shot); Write-Output "$label screenshot: $shot" }
  [void] $p.CloseMainWindow()
  if (-not $p.WaitForExit(20000)) { Write-Output "$label did not close in 20 s; stopping it"; $p.Kill(); $p.WaitForExit() }
  Write-Output "$label exited with code $($p.ExitCode)"
}

Get-Process documancer -ErrorAction SilentlyContinue | ForEach-Object { [void] $_.CloseMainWindow(); [void] $_.WaitForExit(20000) }
Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $root | Out-Null
Expand-Archive -Path $zip -DestinationPath (Join-Path $root 'run1')
$dir1 = Get-ChildItem (Join-Path $root 'run1') -Directory | Select-Object -First 1 -ExpandProperty FullName
if (-not $dir1) { $dir1 = Join-Path $root 'run1' }
Write-Output "extracted to $dir1"
Write-Output "zip contents: $((Get-ChildItem $dir1 | ForEach-Object Name) -join ', ')"

$before = @(Snapshot)
Run-Portable $dir1 'run 1' (Join-Path $notes 'final-portable.png')
$data1 = Join-Path $dir1 'DocuMancerData'
if (-not (Test-Path $data1)) { throw 'DocuMancerData was not created beside the exe' }
Write-Output "DocuMancerData after run 1: $((Get-ChildItem $data1 -Recurse -File | ForEach-Object { $_.FullName.Substring($data1.Length + 1) }) -join ', ')"

$dir2 = Join-Path $root 'moved\DocuMancer Portable Copy'
New-Item -ItemType Directory -Force (Split-Path $dir2) | Out-Null
Move-Item $dir1 $dir2
Run-Portable $dir2 'run 2 (moved, path with spaces)' $null
Write-Output "portable CLI: $(& (Join-Path $dir2 'documancer-cli.exe') --version)"

$after = @(Snapshot)
$diff = Compare-Object $before $after
if ($diff) { Write-Output 'APPDATA CHANGED:'; $diff | ForEach-Object { "  $($_.SideIndicator) $($_.InputObject)" } }
else { Write-Output "%APPDATA% DocuMancer/PdfCraft unchanged by both portable runs ($($before.Count) watched files)" }
