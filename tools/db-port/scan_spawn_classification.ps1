# Report spawn classification: singleton unique NPC vs intentional pack vs service.
# Uses world_sfdb baseline spawn counts per (map, entry, phase).
#
# Usage:
#   .\scan_spawn_classification.ps1
#   .\scan_spawn_classification.ps1 -Maps 870 -DuplicatesOnly
#   .\scan_spawn_classification.ps1 -Entry 64172

param(
    [string]$Database = 'world',
    [string]$BaselineDatabase = 'world_sfdb',
    [int[]]$Maps = @(),
    [int]$Entry = 0,
    [switch]$DuplicatesOnly
)

. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

$mapFilter = if ($Maps.Count -gt 0) { "AND c.map IN ($($Maps -join ','))" } else { '' }
$entryFilter = if ($Entry -gt 0) { "AND c.id = $Entry" } else { '' }
$havingDup = if ($DuplicatesOnly) { 'HAVING world_cnt > sfdb_cnt' } else { '' }

$query = @"
SELECT
    c.id AS entry,
    ct.name,
    c.map,
    c.phaseId,
    c.phaseGroup,
    bs.cnt AS sfdb_cnt,
    COUNT(*) AS world_cnt,
    SUM(c.guid < 8000000) AS loa_cnt,
    SUM(c.guid >= 8000000) AS sfdb_guid_cnt,
    CASE
        WHEN bs.cnt IS NULL THEN 'loa_only'
        WHEN bs.cnt = 1 AND COUNT(*) > 1 THEN 'singleton_duplicate'
        WHEN bs.cnt > 1 AND COUNT(*) > bs.cnt THEN 'pack_overflow'
        WHEN bs.cnt > 1 THEN 'pack_ok'
        WHEN COUNT(*) = 1 THEN 'singleton_ok'
        ELSE 'unknown'
    END AS spawn_class,
    CASE
        WHEN (
            (ct.npcflag & 0x03FFFFFE) <> 0
            OR EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
            OR EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
            OR EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
            OR EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
        ) THEN 'service'
        WHEN ct.type IN (1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13) THEN 'creature_pack'
        WHEN ct.type IN (7, 8) AND ct.npc_rank = 0
             AND NOT EXISTS (SELECT 1 FROM creature_loot_template clt WHERE clt.entry = ct.entry)
            THEN 'civilian_unique'
        ELSE 'other'
    END AS npc_role
FROM creature c
INNER JOIN creature_template ct ON ct.entry = c.id
LEFT JOIN (
    SELECT id, map, phaseId, phaseGroup, COUNT(*) AS cnt
    FROM ``$BaselineDatabase``.creature
    GROUP BY id, map, phaseId, phaseGroup
) bs ON bs.id = c.id AND bs.map = c.map AND bs.phaseId = c.phaseId AND bs.phaseGroup = c.phaseGroup
WHERE 1=1
  $mapFilter
  $entryFilter
GROUP BY c.id, ct.name, c.map, c.phaseId, c.phaseGroup, bs.cnt, ct.type, ct.npc_rank, ct.npcflag
$havingDup
ORDER BY spawn_class, world_cnt - COALESCE(bs.cnt, 0) DESC, c.id
LIMIT 500;
"@

$outFile = Join-Path $cfg.OutputDir 'spawn_classification.tsv'
$lines = Invoke-DbPortQuery -Query $query -Database $Database
if (-not $lines) {
    Write-Host 'No rows.'
    exit 0
}

$header = "entry`tname`tmap`tphaseId`tphaseGroup`tsfdb_cnt`tworld_cnt`tloa_cnt`tsfdb_guid_cnt`tspawn_class`tnpc_role"
$all = @($header) + @($lines)
$all | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Wrote $($lines.Count) rows to $outFile"

$lines | Select-Object -First 25 | ForEach-Object { Write-Host $_ }
