$ErrorActionPreference = 'Stop'
# UTF-8 with BOM so PowerShell 5 parses non-ASCII correctly.
$dir = 'C:\Users\ELMYZ\dm-src\crates\ui-egui\src\i18n'
$translations = [ordered]@{
  'de.tsv'      = @('Lagune (Hell)', 'Lagune')
  'fr.tsv'      = @('Lagon (clair)', 'Lagon')
  'es.tsv'      = @('Lagoon (claro)', 'Lagoon')
  'ja.tsv'      = @([char]0x30E9 + [char]0x30B0 + [char]0x30FC + [char]0x30F3 + [char]0xFF08 + [char]0x30E9 + [char]0x30A4 + [char]0x30C8 + [char]0xFF09, [char]0x30E9 + [char]0x30B0 + [char]0x30FC + [char]0x30F3)
  'zh-hans.tsv' = @(([char]0x6CF4) + ([char]0x6E56) + ([char]0xFF08) + ([char]0x6D45) + ([char]0x8272) + ([char]0xFF09), ([char]0x6CF4) + ([char]0x6E56))
  'zh-hant.tsv' = @(([char]0x6F5F) + ([char]0x6E56) + ([char]0xFF08) + ([char]0x6DFA) + ([char]0x8272) + ([char]0xFF09), ([char]0x6F5F) + ([char]0x6E56))
  'ru.tsv'      = @(([char]0x041B) + ([char]0x0430) + ([char]0x0433) + ([char]0x0443) + ([char]0x043D) + ([char]0x0430) + ' (' + ([char]0x0441) + ([char]0x0432) + ([char]0x0435) + ([char]0x0442) + ([char]0x043B) + ([char]0x0430) + ([char]0x044F) + ')', ([char]0x041B) + ([char]0x0430) + ([char]0x0433) + ([char]0x0443) + ([char]0x043D) + ([char]0x0430))
  'pt-br.tsv'   = @('Lagoon (claro)', 'Lagoon')
  'bg.tsv'      = @(([char]0x041B) + ([char]0x0430) + ([char]0x0433) + ([char]0x0443) + ([char]0x043D) + ([char]0x0430) + ' (' + ([char]0x0441) + ([char]0x0432) + ([char]0x0435) + ([char]0x0442) + ([char]0x043B) + ([char]0x0430) + ')', ([char]0x041B) + ([char]0x0430) + ([char]0x0433) + ([char]0x0443) + ([char]0x043D) + ([char]0x0430))
  'cs.tsv'      = @('Laguna (sv' + [char]0x011B + 'tl' + [char]0x00E1 + ')', 'Laguna')
  'te.tsv'      = @(
    ([char]0x0C32)+([char]0x0C17)+([char]0x0C42)+([char]0x0C28)+([char]0x0C4D)+' ('+([char]0x0C32)+([char]0x0C48)+([char]0x0C1F)+([char]0x0C4D)+')',
    ([char]0x0C32)+([char]0x0C17)+([char]0x0C42)+([char]0x0C28)+([char]0x0C4D)
  )
}
foreach ($name in $translations.Keys) {
  $path = Join-Path $dir $name
  $pair = $translations[$name]
  $full = $pair[0]; $bare = $pair[1]
  $text = [System.IO.File]::ReadAllText($path)
  if ($text -match [regex]::Escape("`tLagoon (Light)`t") -or $text -match '(?m)^Lagoon \(Light\)\t') {
    Write-Output "already $name"; continue
  }
  $nl = if ($text -match "`r`n") { "`r`n" } else { "`n" }
  $lines = $text -split "`r?`n", -1
  $out = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  foreach ($line in $lines) {
    $out.Add($line)
    if (-not $inserted -and $line -match "`tLight gray`t") {
      $prefix = if ($line.StartsWith("`t")) { "`t" } else { '' }
      $out.Add("${prefix}Lagoon (Light)`t$full")
      $out.Add("${prefix}Lagoon`t$bare")
      $inserted = $true
    }
  }
  if (-not $inserted) { Write-Output "FAIL $name"; continue }
  $enc = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($path, (($out -join $nl)), $enc)
  Write-Output "ok $name"
}
