param([string] $Root, [switch] $DryRun)
$ErrorActionPreference = 'Stop'
Set-Location $Root

# Spans kept byte-for-byte: real upstream links, websites, corpus repo name/clone dir.
$protect = @(
  '(?i)(?:https?://|git@)(?:www\.)?(?:github\.com[/:]storytold/|raw\.githubusercontent\.com/storytold/|codeload\.github\.com/storytold/|getartcraft\.com/apps/|api\.star-history\.com/|star-history\.com/)[^\s)\]>"''`<,]*',
  'storytold/pdfcraft(?:-corpus)?',
  'pdfcraft-corpus'
)
$open = [string][char]1
$close = [string][char]2

function Convert-Text([string] $s) {
  $kept = New-Object System.Collections.Generic.List[string]
  foreach ($p in $protect) {
    $sb = New-Object System.Text.StringBuilder
    $last = 0
    foreach ($m in [regex]::Matches($s, $p)) {
      [void] $sb.Append($s, $last, $m.Index - $last)
      [void] $sb.Append($open + $kept.Count + $close)
      $kept.Add($m.Value)
      $last = $m.Index + $m.Length
    }
    [void] $sb.Append($s, $last, $s.Length - $last)
    $s = $sb.ToString()
  }
  # Mixed / spaced forms first
  $s = $s.Replace('PDF Craft', 'DocuMancer')
  $s = $s.Replace('PDFCraft', 'DocuMancer')
  $s = $s.Replace('pdf-craft', 'documancer')
  $s = $s.Replace('CARGO_BIN_EXE_pdfcraft', 'CARGO_BIN_EXE_documancer')
  $s = $s.Replace('PDFCRAFT', 'DOCUMANCER')
  # PdfCraft / Pdfcraft before bare Pdf
  $s = [regex]::Replace($s, 'PdfCraft(?=[A-Za-z0-9_]|\.[A-Za-z])', 'DocuMancer')
  $s = $s.Replace('PdfCraft', 'DocuMancer')
  $s = [regex]::Replace($s, 'Pdfcraft(?=[A-Za-z0-9_]|\.[A-Za-z]|[\\/"`-])', 'DocuMancer')
  $s = $s.Replace('Pdfcraft', 'DocuMancer')
  # lowercase: snake / path / rust module
  $s = [regex]::Replace($s, '(?<=_)pdfcraft|pdfcraft(?=_|::)', 'documancer')
  $s = [regex]::Replace($s, 'pdfcraft(?=[A-Z])', 'documancer')
  $s = $s.Replace('pdfcraft', 'documancer')
  $sb = New-Object System.Text.StringBuilder
  $last = 0
  foreach ($m in [regex]::Matches($s, [regex]::Escape($open) + '(\d+)' + [regex]::Escape($close))) {
    [void] $sb.Append($s, $last, $m.Index - $last)
    [void] $sb.Append($kept[[int] $m.Groups[1].Value])
    $last = $m.Index + $m.Length
  }
  [void] $sb.Append($s, $last, $s.Length - $last)
  return $sb.ToString()
}

$files = @(rg -l -i 'pdf.?craft' --hidden -g '!.git' -g '!contributors/contributors.json' -g '!**/restyle-*')
$files = @($files | Where-Object { $_ -and (Test-Path $_) } | Sort-Object -Unique)
$changed = 0
foreach ($f in $files) {
  $path = (Resolve-Path $f).Path
  # skip binaries
  $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
  if ($ext -in '.png','.ico','.icns','.pdf','.wasm','.icc','.ttf','.otf','.woff','.woff2','.DS_Store') { continue }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
  $skip = if ($bom) { 3 } else { 0 }
  # skip if NUL bytes (binary)
  $hasNul = $false
  for ($i = $skip; $i -lt [Math]::Min($bytes.Length, 8000); $i++) { if ($bytes[$i] -eq 0) { $hasNul = $true; break } }
  if ($hasNul) { continue }
  $text = [System.Text.Encoding]::UTF8.GetString($bytes, $skip, $bytes.Length - $skip)
  $new = Convert-Text $text
  if ($new -ne $text) {
    $changed++
    if (-not $DryRun) { [System.IO.File]::WriteAllText($path, $new, (New-Object System.Text.UTF8Encoding($bom))) }
  }
}
Write-Output "files changed: $changed of $($files.Count)"
