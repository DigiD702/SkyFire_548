# Optional audit: find LOA-port duplicate spawns vs SFDB on a dev database.
# LOA is a frozen snapshot — repo consumers use static 2026-06-27_world_05.sql instead.
#
# Usage:
#   .\generate_spawn_dedup_update.ps1 -AllMaps
#   .\generate_spawn_dedup_update.ps1 -AllMaps -SingletonOnly
#   .\generate_spawn_dedup_update.ps1 -AllMaps -OutputFile sql\updates\world\2026-06-27_world_05.sql -AllowRepoOutput
#
# After preview looks right, merge new guids into the static 2026-06-27_world_05.sql by hand (or -AllowRepoOutput once on a fresh DB).

param(
    [string]$Database = 'world',
    [string]$BaselineDatabase = 'world_sfdb',
    [int[]]$Maps = @(),
    [switch]$AllMaps,
    [double]$NearStackDistXY = 1.25,
    [double]$NearStackDistZ = 2.0,
    [string]$OutputFile = 'spawn_dedup_preview.sql',
    [switch]$IncludeSingleton = $true,
    [switch]$SingletonOnly,
    [switch]$DumpQueries,
    [switch]$AllowRepoOutput
)

if (-not $AllMaps -and $Maps.Count -eq 0) {
    $AllMaps = $true
}

. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

$mapFilterInner = if ($AllMaps) { '' } else { "AND c2.map IN ($($Maps -join ','))" }
$mapFilterOuter = if ($AllMaps) { '' } else { "AND c.map IN ($($Maps -join ','))" }
$mapFilterLo = if ($AllMaps) { '' } else { "AND lo.map IN ($($Maps -join ','))" }
$mapFilterC1 = if ($AllMaps) { '' } else { "AND c1.map IN ($($Maps -join ','))" }
$scopeLabel = if ($AllMaps) { 'all maps' } else { "maps $($Maps -join ',')" }

$outDir = Join-Path $PSScriptRoot 'output'
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$isRepoUpdatePath = $OutputFile -match '(^|[\\/])sql[\\/]updates[\\/]world[\\/]'
if ($isRepoUpdatePath -and -not $AllowRepoOutput) {
    throw "Refusing to write repo update '$OutputFile'. Use output/spawn_dedup_preview.sql (default) or pass -AllowRepoOutput on a fresh DB only."
}

$outPath = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile
} elseif ($isRepoUpdatePath) {
    Join-Path $cfg.RepoRoot ($OutputFile -replace '/', '\')
} else {
    Join-Path $outDir $OutputFile
}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$serviceFlagMask = '0x03FFFFFE'
$packCreatureTypes = '1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13'

$serviceNpcFilter = @"
(
    (ct.npcflag & $serviceFlagMask) <> 0
    OR EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
    OR EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
    OR EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
    OR EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
)
AND NOT (
    ct.type IN ($packCreatureTypes)
    AND (ct.npcflag & $serviceFlagMask) = 0
    AND NOT EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
    AND NOT EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
    AND NOT EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
    AND NOT EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
)
"@

# Unique NPCs: service roles OR civilian humanoids. Excludes wild creature types (pack mobs).
$uniqueNpcFilter = @"
(
    (ct.npcflag & $serviceFlagMask) <> 0
    OR EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
    OR EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
    OR EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
    OR EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
    OR (
        ct.type IN (7, 8)
        AND ct.npc_rank = 0
        AND NOT EXISTS (SELECT 1 FROM creature_loot_template clt WHERE clt.entry = ct.entry)
    )
)
AND ct.type NOT IN ($packCreatureTypes)
"@

$serviceNpcFilterCt2 = $serviceNpcFilter -replace 'ct\.', 'ct2.'
$uniqueNpcFilterCt2 = $uniqueNpcFilter -replace 'ct\.', 'ct2.'

$runService = -not $SingletonOnly
$runSingleton = $IncludeSingleton -or $SingletonOnly

$scopeDesc = if ($SingletonOnly) { 'singleton unique NPC dedup' } elseif ($runSingleton) { 'service + singleton spawn dedup' } else { 'service NPC spawn dedup' }
Write-Host "Generating $scopeDesc ($scopeLabel) -> $OutputFile"

# --- 1) LOA spawn when any SFDB spawn exists (same map/entry/phase, any distance) ---
$loaSfdbPairQuery = @"
SELECT DISTINCT lo.guid
FROM creature lo
INNER JOIN creature_template ct ON ct.entry = lo.id
WHERE lo.guid < 8000000
  $mapFilterLo
  AND $serviceNpcFilter
  AND EXISTS (
      SELECT 1
      FROM creature sf
      WHERE sf.map = lo.map
        AND sf.id = lo.id
        AND sf.phaseId = lo.phaseId
        AND sf.phaseGroup = lo.phaseGroup
        AND sf.guid >= 8000000
        AND sf.guid <> lo.guid
  );
"@

# --- 2) Same entry stacked at same position (phase-aware) ---
$clusterQuery = @"
SELECT c.guid
FROM creature c
INNER JOIN creature_template ct ON ct.entry = c.id
INNER JOIN (
    SELECT
        c2.map,
        c2.id,
        c2.phaseId,
        c2.phaseGroup,
        ROUND(c2.position_x, 1) AS bx,
        ROUND(c2.position_y, 1) AS pos_y,
        ROUND(c2.position_z, 1) AS bz,
        COALESCE(
            MIN(CASE WHEN c2.guid >= 8000000 THEN c2.guid END),
            MIN(CASE WHEN bs.guid IS NOT NULL THEN c2.guid END),
            MIN(CASE WHEN c2.MovementType = 0 AND c2.spawndist = 0 THEN c2.guid END),
            MIN(c2.guid)
        ) AS keep_guid
    FROM creature c2
    INNER JOIN creature_template ct2 ON ct2.entry = c2.id
    LEFT JOIN ``$BaselineDatabase``.creature bs ON bs.guid = c2.guid
    WHERE 1=1
      $mapFilterInner
      AND $serviceNpcFilterCt2
    GROUP BY c2.map, c2.id, c2.phaseId, c2.phaseGroup, bx, pos_y, bz
    HAVING COUNT(*) > 1
) k ON  k.map = c.map
   AND k.id = c.id
   AND c.phaseId = k.phaseId
   AND c.phaseGroup = k.phaseGroup
   AND ROUND(c.position_x, 1) = k.bx
   AND ROUND(c.position_y, 1) = k.pos_y
   AND ROUND(c.position_z, 1) = k.bz
   AND c.guid <> k.keep_guid
WHERE 1=1
  $mapFilterOuter
  AND $serviceNpcFilter;
"@

# --- 3) LOA guid near SFDB twin (same entry, same phase) ---
$nearStackQuery = @"
SELECT DISTINCT lo.guid
FROM creature lo
INNER JOIN creature sf
    ON  sf.map = lo.map
    AND sf.id = lo.id
    AND sf.phaseId = lo.phaseId
    AND sf.phaseGroup = lo.phaseGroup
    AND sf.guid >= 8000000
    AND lo.guid < 8000000
    AND sf.guid <> lo.guid
    AND SQRT(POW(lo.position_x - sf.position_x, 2) + POW(lo.position_y - sf.position_y, 2)) < $NearStackDistXY
    AND ABS(lo.position_z - sf.position_z) < $NearStackDistZ
INNER JOIN creature_template ct ON ct.entry = lo.id
WHERE 1=1
  $mapFilterLo
  AND $serviceNpcFilter;
"@

# --- 4) Cross-entry same-name vendor/quest mismatch ---
$crossEntryQuery = @"
SELECT c1.guid
FROM creature c1
INNER JOIN creature c2
    ON  c2.map = c1.map
    AND c2.id <> c1.id
    AND c2.phaseId = c1.phaseId
    AND c2.phaseGroup = c1.phaseGroup
    AND c2.guid > c1.guid
    AND ABS(c1.position_x - c2.position_x) < $NearStackDistXY
    AND ABS(c1.position_y - c2.position_y) < $NearStackDistXY
    AND ABS(c1.position_z - c2.position_z) < $NearStackDistZ
INNER JOIN creature_template ct1 ON ct1.entry = c1.id
INNER JOIN creature_template ct2 ON ct2.entry = c2.id AND ct2.name = ct1.name
LEFT JOIN (SELECT entry, COUNT(*) AS cnt FROM npc_vendor GROUP BY entry) v1 ON v1.entry = c1.id
LEFT JOIN (SELECT entry, COUNT(*) AS cnt FROM npc_vendor GROUP BY entry) v2 ON v2.entry = c2.id
WHERE c1.guid < 8000000
  $mapFilterC1
  AND (
      (COALESCE(v1.cnt, 0) = 0 AND COALESCE(v2.cnt, 0) > 0)
      OR ((ct1.npcflag & 2) = 0 AND (ct2.npcflag & 2) <> 0
          AND EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = c2.id))
      OR ((ct1.npcflag & 4096) = 0 AND (ct2.npcflag & 4096) <> 0)
  );
"@

# --- 5) Singleton: SFDB baseline has 1 spawn per map/phase, world has more ---
$singletonQuery = @"
SELECT c.guid
FROM creature c
INNER JOIN creature_template ct ON ct.entry = c.id
INNER JOIN (
    SELECT
        c2.map,
        c2.id,
        c2.phaseId,
        c2.phaseGroup,
        COALESCE(
            MIN(CASE WHEN c2.guid >= 8000000 THEN c2.guid END),
            MIN(CASE WHEN bs.guid IS NOT NULL THEN c2.guid END),
            MIN(CASE WHEN c2.MovementType = 0 AND c2.spawndist = 0 THEN c2.guid END),
            MIN(c2.guid)
        ) AS keep_guid
    FROM creature c2
    INNER JOIN creature_template ct2 ON ct2.entry = c2.id
    LEFT JOIN ``$BaselineDatabase``.creature bs ON bs.guid = c2.guid
    INNER JOIN (
        SELECT id, map, phaseId, phaseGroup
        FROM ``$BaselineDatabase``.creature
        GROUP BY id, map, phaseId, phaseGroup
        HAVING COUNT(*) = 1
    ) singleton ON singleton.id = c2.id
        AND singleton.map = c2.map
        AND singleton.phaseId = c2.phaseId
        AND singleton.phaseGroup = c2.phaseGroup
    WHERE 1=1
      $mapFilterInner
      AND $uniqueNpcFilterCt2
    GROUP BY c2.map, c2.id, c2.phaseId, c2.phaseGroup
    HAVING COUNT(*) > 1
) k ON  k.map = c.map
   AND k.id = c.id
   AND c.phaseId = k.phaseId
   AND c.phaseGroup = k.phaseGroup
   AND c.guid <> k.keep_guid
WHERE 1=1
  $mapFilterOuter
  AND $uniqueNpcFilter;
"@

function Get-GuidsFromQuery {
    param([string]$Query)
    $lines = Invoke-DbPortQuery -Query $Query -Database $Database
    if (-not $lines) { return @() }
    return @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

if ($DumpQueries) {
    $dumpDir = Join-Path $PSScriptRoot 'output'
    $utf8 = New-Object System.Text.UTF8Encoding $false
    if ($runService) {
        [System.IO.File]::WriteAllText((Join-Path $dumpDir 'dedup_loa_sfdb_pair.sql'), $loaSfdbPairQuery, $utf8)
        [System.IO.File]::WriteAllText((Join-Path $dumpDir 'dedup_cluster.sql'), $clusterQuery, $utf8)
        [System.IO.File]::WriteAllText((Join-Path $dumpDir 'dedup_nearstack.sql'), $nearStackQuery, $utf8)
        [System.IO.File]::WriteAllText((Join-Path $dumpDir 'dedup_crossentry.sql'), $crossEntryQuery, $utf8)
    }
    if ($runSingleton) {
        [System.IO.File]::WriteAllText((Join-Path $dumpDir 'dedup_singleton.sql'), $singletonQuery, $utf8)
    }
    Write-Host "Wrote query dumps to output/"
    exit 0
}

$pairGuids = @()
$clusterGuids = @()
$nearGuids = @()
$crossGuids = @()
$singletonGuids = @()

if ($runService) {
    $pairGuids = Get-GuidsFromQuery -Query $loaSfdbPairQuery
    $clusterGuids = Get-GuidsFromQuery -Query $clusterQuery
    $nearGuids = Get-GuidsFromQuery -Query $nearStackQuery
    $crossGuids = Get-GuidsFromQuery -Query $crossEntryQuery
}
if ($runSingleton) {
    $singletonGuids = Get-GuidsFromQuery -Query $singletonQuery
}

$allGuids = @{}
foreach ($g in ($pairGuids + $clusterGuids + $nearGuids + $crossGuids + $singletonGuids)) {
    $allGuids[[uint64]$g] = $true
}

$sorted = $allGuids.Keys | Sort-Object { [uint64]$_ }
if ($runService) {
    Write-Host "  LOA+SFDB pair deletes: $($pairGuids.Count)"
    Write-Host "  cluster deletes:       $($clusterGuids.Count)"
    Write-Host "  near-stack deletes:    $($nearGuids.Count)"
    Write-Host "  cross-entry deletes:   $($crossGuids.Count)"
}
if ($runSingleton) {
    Write-Host "  singleton deletes:     $($singletonGuids.Count)"
}
Write-Host "  unique guids total:    $($sorted.Count)"

if ($sorted.Count -eq 0) {
    Write-Warning 'No duplicate spawns found - not writing SQL (DB may already have dedup applied).'
    exit 0
}

$sb = New-Object System.Text.StringBuilder
if ($SingletonOnly) {
    [void]$sb.AppendLine("-- Preview: singleton unique NPC spawn dedup ($scopeLabel)")
    [void]$sb.AppendLine('-- SFDB baseline has 1 spawn per map/entry/phase: keep one, drop extras')
} else {
    [void]$sb.AppendLine("-- Preview: service + singleton spawn dedup ($scopeLabel)")
    [void]$sb.AppendLine('-- LOA duplicate service/singleton spawns vs SFDB baseline')
}
[void]$sb.AppendLine('DELETE FROM `creature` WHERE `guid` IN (')

for ($i = 0; $i -lt $sorted.Count; $i += 100) {
    $end = [Math]::Min($i + 99, $sorted.Count - 1)
    $chunk = $sorted[$i..$end]
    $suffix = if ($end -lt $sorted.Count - 1) { ',' } else { '' }
    [void]$sb.AppendLine('    ' + (($chunk | ForEach-Object { [string]$_ }) -join ', ') + $suffix)
}
[void]$sb.AppendLine(');')

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)
Write-Host "Wrote $outPath"

$checks = @(
    @{ Name = 'Sarya Teaflower LOA'; Guid = 534075; Expect = 'DELETE' },
    @{ Name = 'Taijing LOA'; Guid = 534057; Expect = 'DELETE' },
    @{ Name = 'Brewmaster Tsu LOA'; Guid = 534024; Expect = 'DELETE' },
    @{ Name = 'Collin Gooddreg LOA'; Guid = 534022; Expect = 'DELETE' },
    @{ Name = 'Bonni Chang SFDB'; Guid = 8155982; Expect = 'KEEP' },
    @{ Name = 'Advisor Kosa LOA'; Guid = 534049; Expect = 'DELETE'; RequireSingleton = $true },
    @{ Name = 'Advisor Kosa SFDB'; Guid = 8155975; Expect = 'KEEP'; RequireSingleton = $true }
)
foreach ($c in $checks) {
    if ($c.RequireSingleton -and -not $runSingleton) { continue }
    $hit = $sorted -contains [uint64]$c.Guid
    $status = if ($hit) { 'DELETE' } else { 'KEEP' }
    $ok = ($c.Expect -eq $status)
    $tag = if ($ok) { 'ok' } else { 'CHECK' }
    Write-Host ('  {0}: guid {1} -> {2} ({3})' -f $c.Name, $c.Guid, $status, $tag)
}
