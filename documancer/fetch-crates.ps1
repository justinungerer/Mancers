param([string] $Lock, [string] $Cache, [int] $Parallel = 16)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$text = Get-Content $Lock -Raw
$items = @()
foreach ($m in [regex]::Matches($text, '(?s)\[\[package\]\]\s*name = "([^"]+)"\s*version = "([^"]+)"\s*source = "registry\+[^"]+"\s*checksum = "([0-9a-f]+)"')) {
  $n = $m.Groups[1].Value; $v = $m.Groups[2].Value
  $out = Join-Path $Cache "$n-$v.crate"
  if (-not (Test-Path $out)) { $items += [pscustomobject]@{ Name = $n; Version = $v; Sum = $m.Groups[3].Value; Out = $out } }
}
Write-Output "missing: $($items.Count)"
$handler = New-Object System.Net.Http.HttpClientHandler
$handler.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$handler.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$handler.UseProxy = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromMinutes(5)
$client.DefaultRequestHeaders.UserAgent.ParseAdd('DocuMancer-dev')
$sha = [System.Security.Cryptography.SHA256]::Create()
$fail = 0
for ($i = 0; $i -lt $items.Count; $i += $Parallel) {
  $batch = $items[$i..([math]::Min($i + $Parallel, $items.Count) - 1)]
  $tasks = @($batch | ForEach-Object { $client.GetByteArrayAsync("https://static.crates.io/crates/$($_.Name)/$($_.Name)-$($_.Version).crate") })
  for ($k = 0; $k -lt $batch.Count; $k++) {
    $it = $batch[$k]
    try {
      $bytes = $tasks[$k].GetAwaiter().GetResult()
      $hex = -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
      if ($hex -ne $it.Sum) { Write-Output "checksum mismatch $($it.Name) $($it.Version)"; $fail++; continue }
      [System.IO.File]::WriteAllBytes($it.Out, $bytes)
    } catch { Write-Output "failed $($it.Name) $($it.Version): $($_.Exception.Message)"; $fail++ }
  }
  Write-Output "done $([math]::Min($i + $Parallel, $items.Count))/$($items.Count)"
}
Write-Output "failures: $fail"

