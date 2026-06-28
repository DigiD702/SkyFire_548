# Remove LOA-port spawns stacked on SFDB spawns (same entry, within 0.5yd).
# Catches non-vendor NPCs missed by vendor-only cluster dedup (e.g. Historian Leelee 62659).
#
# Usage:
#   .\scan_loa_nearstack_dupes.ps1 -Database world -Maps 870 -WriteWorldUpdate

param(
    [string]$Database = 'world',
    [int[]]$Maps = @(870),
    [double]$MaxDistXY = 0.5,
    [double]$MaxDistZ = 1.0,
    [uint64]$LoaGuidMax = 8000000,
    [switch]$WriteWorldUpdate,
    [string]$ApplyToDatabase
)

. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

$mapList = ($Maps | ForEach-Object { [string]$_ }) -join ','
$outDir = Join-Path $PSScriptRoot 'output'
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$query = @"
SELECT DISTINCT
    lo.map,
    ct.name,
    lo.guid,
    lo.id,
    ROUND(lo.position_x, 2),
    ROUND(lo.position_y, 2),
    ROUND(SQRT(POW(lo.position_x - sf.position_x, 2) + POW(lo.position_y - sf.position_y, 2)), 3) AS dist_xy
FROM creature lo
INNER JOIN creature sf
    ON  sf.map = lo.map
    AND sf.id = lo.id
    AND sf.guid >= $LoaGuidMax
    AND lo.guid < $LoaGuidMax
    AND SQRT(POW(lo.position_x - sf.position_x, 2) + POW(lo.position_y - sf.position_y, 2)) < $MaxDistXY
    AND ABS(lo.position_z - sf.position_z) < $MaxDistZ
INNER JOIN creature_template ct ON ct.entry = lo.id
WHERE lo.map IN ($mapList)
ORDER BY lo.map, ct.name, lo.guid;
"@

Write-Host "Scanning LOA near-stack dupes on maps $mapList (dist_xy < $MaxDistXY)..."

$lines = Invoke-DbPortQuery -Query $query -Database $Database
if (-not $lines) {
    Write-Host "No near-stack duplicates found."
    exit 0
}

$rows = foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 7) { continue }
    [pscustomobject]@{
        Map      = $p[0]
        Name     = $p[1]
        Guid     = $p[2]
        Entry    = $p[3]
        X        = $p[4]
        Y        = $p[5]
        DistXY   = $p[6]
    }
}

$csvPath = Join-Path $outDir 'duplicate_spawn_removals_loa_nearstack.csv'
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$guids = $rows | ForEach-Object { $_.Guid } | Sort-Object { [uint64]$_ }
Write-Host "Found $($guids.Count) LOA spawns to remove."

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("DELETE FROM ``creature`` WHERE ``guid`` IN (")

for ($i = 0; $i -lt $guids.Count; $i += 100) {
    $end = [Math]::Min($i + 99, $guids.Count - 1)
    $chunk = $guids[$i..$end]
    $suffix = if ($end -lt $guids.Count - 1) { ',' } else { '' }
    [void]$sb.AppendLine('    ' + (($chunk | ForEach-Object { [string]$_ }) -join ', ') + $suffix)
}
[void]$sb.AppendLine(');')

$sqlPath = Join-Path $outDir 'duplicate_spawn_removals_loa_nearstack.sql'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($sqlPath, $sb.ToString(), $utf8NoBom)

Write-Host "Wrote report: $csvPath"
Write-Host "Wrote SQL:    $sqlPath"

if ($WriteWorldUpdate) {
    Write-Warning "Use generate_spawn_dedup_update.ps1 -OutputFile YYYY-MM-DD_world_XX.sql for consolidated world updates."
}

if ($ApplyToDatabase) {
    Invoke-DbPortSqlFile -SqlFile $sqlPath -Database $ApplyToDatabase | Out-Null
    Write-Host "Applied to $ApplyToDatabase"
}

$rows | Group-Object Map | Sort-Object Name | ForEach-Object {
    Write-Host ("  map {0}: {1} removals" -f $_.Name, $_.Count)
}

# Spot-check
$lee = $rows | Where-Object { $_.Entry -eq '62659' }
if ($lee) {
    Write-Host "Includes Historian Leelee (62659): delete guid $($lee.Guid)"
}
