# Generate pending SQL batches from LOA comparison.

param(
    [string]$PendingDir
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$PendingDir = if ($PendingDir) { $PendingDir } else { Join-Path $cfg.RepoRoot 'sql\updates\world' }

if (-not (Test-Path $PendingDir)) {
    New-Item -ItemType Directory -Path $PendingDir -Force | Out-Null
}

$stamp = Get-Date -Format 'yyyy-MM-dd'

function Export-LoaRows {
    param(
        [string]$Table,
        [string]$Where,
        [string]$OutFile
    )

    $header = @(
        "-- LOA export: $Table",
        "-- Source: $($cfg.LoaDb)",
        "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        ''
    )
    $header | Out-File -FilePath $OutFile -Encoding utf8

    $dumpArgs = @(
        '-h', $cfg.Host,
        '-P', $cfg.Port,
        '-u', $cfg.User,
        '--no-create-info',
        '--complete-insert',
        '--skip-extended-insert',
        '--compact',
        '--set-gtid-purged=OFF',
        $cfg.LoaDb,
        $Table,
        "--where=$Where"
    )

    $env:MYSQL_PWD = $cfg.Password
    & $cfg.Mysqldump @dumpArgs | Add-Content -Path $OutFile -Encoding utf8
}

# 1) Missing creature templates present in LOA
$creatureEntries = '68993,73422,74010,74012,74019'
Export-LoaRows -Table 'creature_template' -Where "entry IN ($creatureEntries)" -OutFile (Join-Path $PendingDir "${stamp}_world_00_loa_missing_creature_templates.sql")

# 2) Missing gameobject templates present in LOA
$goEntries = '215413,213074'
Export-LoaRows -Table 'gameobject_template' -Where "entry IN ($goEntries)" -OutFile (Join-Path $PendingDir "${stamp}_world_01_loa_missing_gameobject_templates.sql")

# 3) Remove orphan GO spawn without any reference source
$orphanGo = @(
    "-- Orphan gameobject spawn with no template in world or LOA",
    "DELETE FROM ``gameobject`` WHERE ``id`` = 212922 AND ``guid`` = 200011;",
    ''
)
$orphanGo | Out-File -FilePath (Join-Path $PendingDir "${stamp}_world_02_remove_orphan_gameobject_212922.sql") -Encoding utf8

# 4) ScriptName sync from LOA for shared templates with empty SkyFire script assignment
$scriptSync = @"
-- Sync ScriptName values from LOA where SkyFire template exists but has no script bound.
-- Scope: creatures and gameobjects that already exist in both databases.

UPDATE world.creature_template sf
JOIN loa.creature_template loa ON loa.entry = sf.entry
SET sf.ScriptName = loa.ScriptName
WHERE (sf.ScriptName IS NULL OR sf.ScriptName = '')
  AND loa.ScriptName IS NOT NULL
  AND loa.ScriptName <> '';

UPDATE world.gameobject_template sf
JOIN loa.gameobject_template loa ON loa.entry = sf.entry
SET sf.ScriptName = loa.ScriptName
WHERE (sf.ScriptName IS NULL OR sf.ScriptName = '')
  AND loa.ScriptName IS NOT NULL
  AND loa.ScriptName <> '';

UPDATE world.instance_template sf
JOIN loa.instance_template loa ON loa.map = sf.map
SET sf.script = loa.script
WHERE (sf.script IS NULL OR sf.script = '')
  AND loa.script IS NOT NULL
  AND loa.script <> '';
"@
$scriptSyncPath = Join-Path $PendingDir "${stamp}_world_03_loa_scriptname_sync.sql"
$scriptSync | Out-File -FilePath $scriptSyncPath -Encoding utf8

# 5) scene_template — disabled: bulk LOA scenes crash 5.4.8 client (Shrine DB2 OOM). Use world_loa/2026-06-25_world_10.sql only for reference.
# $missingScenes = Invoke-DbPortQuery -Query @"
# SELECT GROUP_CONCAT(SceneId)
# FROM loa.scene_template
# WHERE SceneId NOT IN (SELECT SceneId FROM world.scene_template);
# "@
# if ($missingScenes -and $missingScenes.Trim()) {
#     Export-LoaRows -Table 'scene_template' -Where "SceneId IN ($missingScenes)" -OutFile (Join-Path $PendingDir "${stamp}_world_04_loa_scene_template.sql")
# } else {
#     Write-Host 'No missing scene_template rows to export.'
# }
Write-Host 'Skipping scene_template export (disabled — see materialize_staging_delta.ps1).'

Write-Host "Generated pending SQL in $PendingDir"
