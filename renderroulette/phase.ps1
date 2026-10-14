param([string]$Phase,[string]$Start,[string]$Result,[string]$Notes)
$end = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
function q($s){ if($s -match '[,"]'){ '"' + ($s -replace '"','""') + '"' } else { $s } }
$line = "RenderRoulette,$(q $Phase),$Start,$end,$Result,$(q $Notes)"
Add-Content -Path 'C:\Users\ELMYZ\OneDrive - Bayer\Documents\AI_temp\New folder (2)\stats\phases.csv' -Value $line -Encoding UTF8
$line