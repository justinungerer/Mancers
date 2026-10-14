$ErrorActionPreference = 'Stop'
$dir = 'C:\Users\ELMYZ\dm-src\crates\ui-egui\src\i18n'
function J([int[]]$codes) { -join ($codes | ForEach-Object { [char]$_ }) }

$map = [ordered]@{
  'de.tsv'      = @('Lagune (Hell)', 'Lagune')
  'fr.tsv'      = @('Lagon (clair)', 'Lagon')
  'es.tsv'      = @('Lagoon (claro)', 'Lagoon')
  'pt-br.tsv'   = @('Lagoon (claro)', 'Lagoon')
  'cs.tsv'      = @('Laguna (sv' + [char]0x011B + 'tl' + [char]0x00E1 + ')', 'Laguna')
  'ja.tsv'      = @((J 0x30E9,0x30B0,0x30FC,0x30F3,0xFF08,0x30E9,0x30A4,0x30C8,0xFF09), (J 0x30E9,0x30B0,0x30FC,0x30F3))
  'zh-hans.tsv' = @((J 0x6CF4,0x6E56,0xFF08,0x6D45,0x8272,0xFF09), (J 0x6CF4,0x6E56))
  'zh-hant.tsv' = @((J 0x6F5F,0x6E56,0xFF08,0x6DFA,0x8272,0xFF09), (J 0x6F5F,0x6E56))
  'ru.tsv'      = @((J 0x041B,0x0430,0x0433,0x0443,0x043D,0x0430) + ' (' + (J 0x0441,0x0432,0x0435,0x0442,0x043B,0x0430,0x044F) + ')', (J 0x041B,0x0430,0x0433,0x0443,0x043D,0x0430))
  'bg.tsv'      = @((J 0x041B,0x0430,0x0433,0x0443,0x043D,0x0430) + ' (' + (J 0x0441,0x0432,0x0435,0x0442,0x043B,0x0430) + ')', (J 0x041B,0x0430,0x0433,0x0443,0x043D,0x0430))
  'te.tsv'      = @((J 0x0C32,0x0C17,0x0C42,0x0C28,0x0C4D) + ' (' + (J 0x0C32,0x0C48,0x0C1F,0x0C4D) + ')', (J 0x0C32,0x0C17,0x0C42,0x0C28,0x0C4D))
}

foreach ($name in $map.Keys) {
  $path = Join-Path $dir $name
  $full = [string]$map[$name][0]
  $bare = [string]$map[$name][1]
  $text = [System.IO.File]::ReadAllText($path)
  $nl = if ($text -match "`r`n") { "`r`n" } else { "`n" }
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.AddRange([string[]]($text -split "`r?`n", -1))
  # Drop any prior mangled Lagoon lines.
  for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match '^\t?Lagoon(\s|\t|\(|$)') { $lines.RemoveAt($i) }
  }
  $out = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  foreach ($line in $lines) {
    $out.Add($line)
    if (-not $inserted -and $line -match "`tLight gray`t") {
      $prefix = if ($line.StartsWith("`t")) { "`t" } else { '' }
      $out.Add(($prefix + 'Lagoon (Light)' + "`t" + $full))
      $out.Add(($prefix + 'Lagoon' + "`t" + $bare))
      $inserted = $true
    }
  }
  if (-not $inserted) {
    # pt-br / cs may put Light gray differently; try without leading tab or after Dark gray theme
    for ($i = 0; $i -lt $out.Count; $i++) {
      if ($out[$i] -match 'Light gray') {
        $prefix = if ($out[$i].StartsWith("`t")) { "`t" } else { '' }
        $out.Insert($i + 1, ($prefix + 'Lagoon (Light)' + "`t" + $full))
        $out.Insert($i + 2, ($prefix + 'Lagoon' + "`t" + $bare))
        $inserted = $true
        break
      }
    }
  }
  if (-not $inserted) { Write-Output "FAIL $name"; continue }
  $enc = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($path, (($out -join $nl)), $enc)
  Write-Output "ok $name :: $full / $bare"
}
