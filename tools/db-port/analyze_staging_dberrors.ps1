param(
    [string]$LogFile = 'C:\SkyFire_Files\Server_staging\dberrors.log',
    [int]$BootIndex = -1
)

$lines = Get-Content $LogFile
$markers = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^Gameobject \(Entry: 181105') {
        $markers += $i
    }
}

Write-Output "Boot markers at lines: $($markers -join ', ') (1-based: $($markers | ForEach-Object { $_ + 1 }))"
Write-Output "Total lines: $($lines.Count)"

$start = if ($BootIndex -ge 0 -and $BootIndex -lt $markers.Count) { $markers[$BootIndex] }
         elseif ($BootIndex -lt 0) { $markers[-1] }
         else { throw "Invalid boot index" }

$boot = if ($start -eq $markers[-1]) { $lines[$start..($lines.Count - 1)] }
        else {
            $next = ($markers | Where-Object { $_ -gt $start } | Select-Object -First 1)
            $lines[$start..($next - 1)]
        }

Write-Output "--- Latest boot only ($($boot.Count) lines) ---"
Write-Output "non existing creature: $(@($boot | Select-String 'non existing creature entry').Count)"
Write-Output "non existing gameobject: $(@($boot | Select-String 'non existing gameobject entry').Count)"
Write-Output "unbound script: $(@($boot | Select-String 'does not have a script name').Count)"
Write-Output "SmartAI: $(@($boot | Select-String 'SmartAIMgr:').Count)"
Write-Output "No model data: $(@($boot | Select-String 'No model data exist').Count)"

$mc = @($boot | Select-String 'non existing creature entry (\d+)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value })
Write-Output "Unique missing creature entries: $(@($mc | Sort-Object -Unique).Count)"
$mc | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Output "  $($_.Name): $($_.Count)"
}

$mg = @($boot | Select-String 'non existing gameobject entry (\d+)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value })
if ($mg.Count -gt 0) {
    Write-Output "Missing gameobject entries:"
    $mg | Group-Object | Sort-Object Count -Descending | ForEach-Object {
        Write-Output "  $($_.Name): $($_.Count)"
    }
}
