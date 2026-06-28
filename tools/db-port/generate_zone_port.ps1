# Generate zone-scoped LOA ports for Wandering Island (860) and Jade Forest (870).

param(
    [int[]]$Maps = @(860, 870),
    [string]$PendingDir
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$PendingDir = if ($PendingDir) { $PendingDir } else { Join-Path $cfg.RepoRoot 'sql\updates\world' }
$stamp = Get-Date -Format 'yyyy-MM-dd'
$mapList = ($Maps | ForEach-Object { $_ }) -join ','

if (-not (Test-Path $PendingDir)) {
    New-Item -ItemType Directory -Path $PendingDir -Force | Out-Null
}

$env:MYSQL_PWD = $cfg.Password

# Creature spawns present in LOA but absent in world (explicit column mapping).
$spawnSql = @"
-- LOA zone port: creature spawns for maps $mapList
-- Column mapping from LOA schema to SkyFire schema.

INSERT INTO creature (
    guid, id, map, spawnMask, phaseId, phaseGroup, modelid, equipment_id,
    position_x, position_y, position_z, orientation, spawntimesecs, spawndist,
    currentwaypoint, curhealth, curmana, MovementType, npcflag, unit_flags, dynamicflags
)
SELECT
    l.guid, l.id, l.map, l.spawnMask, l.phaseId, l.phaseGroup, l.modelid, l.equipment_id,
    l.position_x, l.position_y, l.position_z, l.orientation, l.spawntimesecs, l.wander_distance,
    l.currentwaypoint, l.curhealth, l.curmana, l.movement_type, l.npcflag, l.unit_flags, l.dynamicflags
FROM loa.creature l
LEFT JOIN creature w ON w.guid = l.guid
WHERE w.guid IS NULL
  AND l.map IN ($mapList);
"@

$spawnPath = Join-Path $PendingDir "${stamp}_world_10_loa_zone_creature_spawns.sql"
$spawnSql | Out-File -FilePath $spawnPath -Encoding utf8

# SmartAI scripts for creatures that spawn on target maps and are missing in world DB.
$saiSql = @"
-- LOA zone port: smart_scripts for creatures on maps $mapList

INSERT INTO smart_scripts (
    entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags,
    event_param1, event_param2, event_param3, event_param4, event_param5,
    action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6,
    target_type, target_param1, target_param2, target_param3,
    target_x, target_y, target_z, target_o, comment
)
SELECT
    s.entryorguid, s.source_type, s.id, s.link, s.event_type, s.event_phase_mask, s.event_chance, s.event_flags,
    s.event_param1, s.event_param2, s.event_param3, s.event_param4, s.event_param5,
    s.action_type, s.action_param1, s.action_param2, s.action_param3, s.action_param4, s.action_param5, s.action_param6,
    s.target_type, s.target_param1, s.target_param2, s.target_param3,
    s.target_x, s.target_y, s.target_z, s.target_o, s.comment
FROM loa.smart_scripts s
JOIN (
    SELECT DISTINCT id AS entry
    FROM loa.creature
    WHERE map IN ($mapList)
) c ON c.entry = s.entryorguid
LEFT JOIN smart_scripts w
  ON w.entryorguid = s.entryorguid
 AND w.source_type = s.source_type
 AND w.id = s.id
 AND w.link = s.link
WHERE s.source_type = 0
  AND w.entryorguid IS NULL;
"@

$saiPath = Join-Path $PendingDir "${stamp}_world_11_loa_zone_smart_scripts.sql"
$saiSql | Out-File -FilePath $saiPath -Encoding utf8

# Creature template ScriptName / AIName alignment for zone creatures.
$templateSql = @"
-- LOA zone port: align creature_template script/AI fields for map $mapList creatures

UPDATE creature_template sf
JOIN (
    SELECT DISTINCT id AS entry
    FROM loa.creature
    WHERE map IN ($mapList)
) z ON z.entry = sf.entry
JOIN loa.creature_template loa ON loa.entry = sf.entry
SET sf.AIName = loa.AIName,
    sf.ScriptName = CASE
        WHEN loa.ScriptName <> '' THEN loa.ScriptName
        ELSE sf.ScriptName
    END
WHERE loa.AIName <> sf.AIName
   OR (sf.ScriptName = '' AND loa.ScriptName <> '');
"@

$templatePath = Join-Path $PendingDir "${stamp}_world_12_loa_zone_creature_template_sync.sql"
$templateSql | Out-File -FilePath $templatePath -Encoding utf8

Write-Host "Generated zone port SQL for maps: $mapList"
