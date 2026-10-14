param([string]$Repo = 'C:\Users\ELMYZ\rr-src', [string]$Out = "$PSScriptRoot\remaining-effectcraft.txt")
Set-Location $Repo
$rules = @(
  @('Upstream links (GitHub repo/issues/raw/star-history, getartcraft.com page)', 'storytold(/|%2F)effectcraft|getartcraft\.com/apps/effectcraft'),
  @('ArtCraft brand terms (marks licensed only in the context of upstream EffectCraft)', 'docs[\\/]brand|context of|repository and EffectCraft|licensed to the upstream EffectCraft'),
  @('Copyright holders / authorship of upstream work ("EffectCraft contributors")', 'EffectCraft contributors'),
  @('Read-compatibility with files saved by upstream EffectCraft (preset tag, template format, XML root + tests)', 'effectcraftAnimationPreset|effectcraft-template|EffectCraftProject|upstream EffectCraft|UPSTREAM_'),
  @('Intentional references to the upstream project (NOTICE, naming rule, README notes, licence text)', 'modified version of|upstream|EffectCraft \(|Keep `EffectCraft`|EffectCraft page|\*\*EffectCraft\*\*|glyphs|\("the EffectCraft')
)
$lines = rg -n -i --no-heading 'effect.?craft' --hidden -g '!.git'
$groups = [ordered]@{}; foreach ($r in $rules) { $groups[$r[0]] = New-Object System.Collections.ArrayList }
$groups['Unclassified'] = New-Object System.Collections.ArrayList
$counts = @{}
foreach ($l in $lines) {
  $n = ([regex]::Matches($l.Substring($l.IndexOf(':', 2) + 1), '(?i)effect.?craft')).Count
  $g = 'Unclassified'
  foreach ($r in $rules) { if ($l -match $r[1]) { $g = $r[0]; break } }
  [void]$groups[$g].Add($l); $counts[$g] = [int]$counts[$g] + $n
}
$total = ($counts.Values | Measure-Object -Sum).Sum
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("Remaining 'effect.?craft' occurrences in EffectTool after the RenderRoulette rename")
[void]$sb.AppendLine("Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm') by remaining.ps1 (rg -i 'effect.?craft', text files).")
[void]$sb.AppendLine("Text total: $total occurrences on $($lines.Count) lines in $((rg -l -i 'effect.?craft' --hidden -g '!.git' | Measure-Object).Count) files.")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Binary / non-text (not counted above, kept on purpose):')
[void]$sb.AppendLine('  crates/model/tests/fixtures/quad.glb - glTF generator string "EffectCraft fixture script"; editing it would break the GLB chunk lengths.')
[void]$sb.AppendLine('  packaging/macos/dmg/dmg-layout.DS_Store - binary Finder layout (protected).')
[void]$sb.AppendLine('  packaging/macos/dmg/background.svg - the title is outlined glyph paths spelling "EffectCraft" (no text to replace; recoloured to coral).')
[void]$sb.AppendLine('  docs/images/renderroulette-*.png - upstream screenshots showing the old EffectCraft UI (renamed with their sidecars, not re-shot).')
[void]$sb.AppendLine('')
foreach ($k in $groups.Keys) {
  if ($groups[$k].Count -eq 0) { continue }
  [void]$sb.AppendLine("== $k : $($counts[$k]) occurrences, $($groups[$k].Count) lines")
  foreach ($l in $groups[$k]) { [void]$sb.AppendLine('  ' + $l) }
  [void]$sb.AppendLine('')
}
[IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object Text.UTF8Encoding $true))
foreach ($k in $groups.Keys) { "{0,5} occ {1,4} lines  {2}" -f [int]$counts[$k], $groups[$k].Count, $k }
"total $total"
