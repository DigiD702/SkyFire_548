# Materialize world_staging changes vs baseline into portable INSERT/UPDATE SQL.
# No LOA database required to apply the output.
#
# Usage:
#   .\materialize_staging_delta.ps1 -DryRun
#   .\materialize_staging_delta.ps1
#   .\materialize_staging_delta.ps1 -Tables creature_template,spell_script_names
#   .\materialize_staging_delta.ps1 -SplitCreatureByMap

param(
    [string]$BaselineDb = 'world',
    [string]$BaselineSql,
    [string]$StagingDb = 'world_staging',
    [string]$OutDir,
    [string[]]$Tables,
    [int]$ChunkSize = 2000,
    [switch]$SplitCreatureByMap,
    [switch]$IncludeTemplateUpdates,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

$OutDir = if ($OutDir) { $OutDir } else { Join-Path $cfg.RepoRoot 'sql\updates\world' }
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$stamp = Get-Date -Format 'yyyy-MM-dd'
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function ConvertTo-SqlText {
    param($Chunk)
    if ($null -eq $Chunk) { return '' }
    $text = if ($Chunk -is [array]) { $Chunk -join "`n" } else { [string]$Chunk }
    if ($text) {
        $text = $text -replace '(?m)^INSERT INTO ', 'INSERT IGNORE INTO '
    }
    if ($text -and -not $text.EndsWith("`n")) { $text += "`n" }
    return $text
}

function Write-SqlUtf8NoBomLines {
    param(
        [string]$Path,
        [string[]]$Lines
    )
    $content = if ($Lines.Count -gt 0) { ($Lines -join "`n") + "`n" } else { '' }
    [System.IO.File]::WriteAllText($Path, $content, $script:Utf8NoBom)
}

function Append-SqlUtf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )
    if ([string]::IsNullOrEmpty($Content)) { return }
    [System.IO.File]::AppendAllText($Path, $Content, $script:Utf8NoBom)
}

# Table export definitions: join used to find rows only in staging.
$tableDefs = @{
    creature = @{
        Join     = 'w.guid = s.guid'
        NullCol  = 'w.guid'
        KeyCols  = @('guid')
        Chunked  = $true
    }
    creature_template = @{
        Join     = 'w.entry = s.entry'
        NullCol  = 'w.entry'
        KeyCols  = @('entry')
        Chunked  = $true
    }
    creature_model_info = @{
        Join     = 'w.modelid = s.modelid'
        NullCol  = 'w.modelid'
        KeyCols  = @('modelid')
        Chunked  = $true
    }
    smart_scripts = @{
        Join     = 'w.entryorguid = s.entryorguid AND w.source_type = s.source_type AND w.id = s.id AND w.link = s.link'
        NullCol  = 'w.entryorguid'
        KeyCols  = @('entryorguid', 'source_type', 'id', 'link')
        Chunked  = $true
    }
    spell_script_names = @{
        Join     = 'w.spell_id = s.spell_id AND w.ScriptName = s.ScriptName'
        NullCol  = 'w.spell_id'
        KeyCols  = @('spell_id', 'ScriptName')
        StringCols = @('ScriptName')
        Chunked  = $true
        ChunkSize = 100
    }
    waypoints = @{
        Join     = 'w.entry = s.entry AND w.pointid = s.pointid'
        NullCol  = 'w.entry'
        KeyCols  = @('entry', 'pointid')
        Chunked  = $true
    }
    # scene_template: omitted — bulk LOA import caused client DB2 OOM at Shrine (2026-06-28).
    # Port scenes zone-by-zone after ScriptPackageID validation; source remains in world_loa/.
    areatrigger_scripts = @{
        Join     = 'w.entry = s.entry'
        NullCol  = 'w.entry'
        KeyCols  = @('entry')
        Chunked  = $false
    }
    achievement_criteria_data = @{
        Join     = 'w.criteria_id = s.criteria_id AND w.type = s.type'
        NullCol  = 'w.criteria_id'
        KeyCols  = @('criteria_id', 'type')
        Chunked  = $true
    }
    hotfix_data = @{
        Join     = 'w.entry = s.entry AND w.type = s.type AND w.hotfixDate = s.hotfixDate'
        NullCol  = 'w.entry'
        KeyCols  = @('entry', 'type', 'hotfixDate')
        StringCols = @('hotfixDate')
        Chunked  = $false
    }
}

$exportTables = if ($Tables) { $Tables } else { @($tableDefs.Keys) }

function Get-KeyCols {
    param([hashtable]$Def)
    if ($null -ne $Def.KeyCols) {
        if ($Def.KeyCols -is [string]) {
            return ,@([string]$Def.KeyCols)
        }
        return ,[object[]]$Def.KeyCols
    }
    if ($Def.DumpKey) {
        return ,@([string]$Def.DumpKey)
    }
    throw 'Table definition missing KeyCols'
}

function Format-SqlValue {
    param([string]$Value, [switch]$IsString)
    if ($IsString) {
        return "'" + ($Value -replace "'", "''") + "'"
    }
    return $Value
}

function Build-WhereFromKeyRows {
    param(
        [hashtable]$Def,
        [string[]]$Rows
    )

    $keyCols = Get-KeyCols -Def $Def
    $stringCols = if ($Def.StringCols) { [System.Collections.Generic.HashSet[string]]::new([string[]]$Def.StringCols) } else { $null }

    if ($keyCols.Count -eq 1) {
        $col = $keyCols[0]
        $vals = foreach ($row in $Rows) {
            $v = ($row -split "`t")[0]
            if ($stringCols -and $stringCols.Contains($col)) { Format-SqlValue $v -IsString } else { $v }
        }
        return "$col IN ($($vals -join ','))"
    }

    $tuples = foreach ($row in $Rows) {
        $parts = $row -split "`t"
        if ($parts.Count -ne $keyCols.Count) { continue }
        $formatted = for ($i = 0; $i -lt $keyCols.Count; $i++) {
            if ($stringCols -and $stringCols.Contains($keyCols[$i])) {
                Format-SqlValue $parts[$i] -IsString
            } else {
                $parts[$i]
            }
        }
        '(' + ($formatted -join ',') + ')'
    }
    return "($($keyCols -join ',')) IN ($($tuples -join ','))"
}

function Get-DeltaKeySelect {
    param([hashtable]$Def)
    $keyCols = Get-KeyCols -Def $Def
    return ($keyCols | ForEach-Object { "s.$_" }) -join ', '
}

function Get-DeltaKeyOrder {
    param([hashtable]$Def)
    $keyCols = Get-KeyCols -Def $Def
    return ($keyCols | ForEach-Object { "s.$_" }) -join ', '
}

function Test-DeltaKeyRow {
    param([string]$Row, [int]$KeyCount)
    if (-not $Row) { return $false }
    $parts = $Row -split "`t"
    return $parts.Count -eq $KeyCount
}

function Get-ScalarInt {
    param([string]$Query)
    $r = Invoke-DbPortQuery -Query $Query -Database $StagingDb
    if ($null -eq $r) { return 0 }
    return [int](($r | Out-String).Trim())
}

function Get-NewRowCount {
    param([string]$Table, [hashtable]$Def)
    $q = @"
SELECT COUNT(1)
FROM ``$StagingDb``.$Table s
LEFT JOIN ``$BaselineDb``.$Table w ON $($Def.Join)
WHERE $($Def.NullCol) IS NULL
"@
    return Get-ScalarInt $q
}

function Split-RowsForWhere {
    param(
        [hashtable]$Def,
        [string[]]$Rows,
        [int]$MaxLen = 6000
    )

    $batches = [System.Collections.Generic.List[object]]::new()
    $batch = [System.Collections.Generic.List[string]]::new()
    foreach ($row in $Rows) {
        $try = @($batch.ToArray()) + @($row)
        $where = Build-WhereFromKeyRows -Def $Def -Rows $try
        if ($where.Length -gt $MaxLen -and $batch.Count -gt 0) {
            $batches.Add($batch.ToArray())
            $batch = [System.Collections.Generic.List[string]]::new()
            $batch.Add($row)
        } else {
            $batch.Add($row)
        }
    }
    if ($batch.Count -gt 0) {
        $batches.Add($batch.ToArray())
    }
    return $batches
}

function Export-KeyRows {
    param(
        [string]$Table,
        [hashtable]$Def,
        [string[]]$Rows,
        [string]$OutFile
    )

    foreach ($batch in (Split-RowsForWhere -Def $Def -Rows $Rows)) {
        $where = Build-WhereFromKeyRows -Def $Def -Rows $batch
        $chunk = Export-TableChunk -Table $Table -Where $where
        Append-SqlUtf8NoBom -Path $OutFile -Content (ConvertTo-SqlText $chunk)
    }
}

function Export-TableChunk {
    param(
        [string]$Table,
        [string]$Where
    )

    $dumpArgs = @(
        '-h', $cfg.Host,
        '-P', $cfg.Port,
        '-u', $cfg.User,
        '--no-create-info',
        '--complete-insert',
        '--skip-extended-insert',
        '--compact',
        '--set-gtid-purged=OFF',
        $StagingDb,
        $Table,
        "--where=$Where"
    )

    & $cfg.Mysqldump @dumpArgs
    if ($LASTEXITCODE -ne 0) {
        throw "mysqldump failed for $Table"
    }
}

function Export-TableDelta {
    param(
        [string]$Table,
        [hashtable]$Def,
        [string]$OutFile
    )

    $count = Get-NewRowCount -Table $Table -Def $Def
    Write-Host "$Table : $count new rows"

    if ($DryRun -or $count -eq 0) { return $count }

    $tableChunk = if ($Def.ChunkSize) { [int]$Def.ChunkSize } else { $ChunkSize }

    $header = @(
        "-- Portable delta: $Table",
        "-- Baseline: $BaselineDb -> Staging: $StagingDb",
        "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "-- Rows: $count",
        ''
    )
    Write-SqlUtf8NoBomLines -Path $OutFile -Lines $header

    if (-not $Def.Chunked -or $count -le $tableChunk) {
        $keySelect = Get-DeltaKeySelect -Def $Def
        $keyCount = (Get-KeyCols -Def $Def).Count
        $idsQ = @"
SELECT $keySelect
FROM ``$StagingDb``.$Table s
LEFT JOIN ``$BaselineDb``.$Table w ON $($Def.Join)
WHERE $($Def.NullCol) IS NULL
"@
        $ids = @(Invoke-DbPortQuery -Query $idsQ -Database $StagingDb | Where-Object { Test-DeltaKeyRow $_ $keyCount })
        if ($ids.Count -eq 0) { return $count }
        Export-KeyRows -Table $Table -Def $Def -Rows $ids -OutFile $OutFile
        return $count
    }

    $offset = 0
    $part = 1
    $keySelect = Get-DeltaKeySelect -Def $Def
    $keyOrder = Get-DeltaKeyOrder -Def $Def
    $keyCount = (Get-KeyCols -Def $Def).Count
    while ($true) {
        $idsQ = @"
SELECT $keySelect
FROM ``$StagingDb``.$Table s
LEFT JOIN ``$BaselineDb``.$Table w ON $($Def.Join)
WHERE $($Def.NullCol) IS NULL
ORDER BY $keyOrder
LIMIT $tableChunk OFFSET $offset
"@
        $ids = @(Invoke-DbPortQuery -Query $idsQ -Database $StagingDb | Where-Object { Test-DeltaKeyRow $_ $keyCount })
        if ($ids.Count -eq 0) { break }

        $partFile = $OutFile -replace '\.sql$', "_part$part.sql"
        $header = @(
            "-- Portable delta: $Table (part $part)",
            "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            ''
        )
        Write-SqlUtf8NoBomLines -Path $partFile -Lines $header

        Export-KeyRows -Table $Table -Def $Def -Rows $ids -OutFile $partFile
        Write-Host "  wrote part $part ($($ids.Count) rows)"

        $offset += $tableChunk
        $part++
    }

    return $count
}

function Export-CreatureByMap {
    $mapsQ = @"
SELECT DISTINCT s.map
FROM ``$StagingDb``.creature s
LEFT JOIN ``$BaselineDb``.creature w ON w.guid = s.guid
WHERE w.guid IS NULL
ORDER BY s.map
"@
    $maps = @(Invoke-DbPortQuery -Query $mapsQ -Database $StagingDb | Where-Object { $_ -match '^\d+$' })
    Write-Host "creature maps with new spawns: $($maps.Count)"

    if ($DryRun) { return }

    foreach ($map in $maps) {
        $outFile = Join-Path $OutDir "${stamp}_creature_map${map}.sql"
        Get-ChildItem $OutDir -Filter "${stamp}_creature_map${map}*.sql" -ErrorAction SilentlyContinue |
            Remove-Item -Force

        $countQ = @"
SELECT COUNT(1)
FROM ``$StagingDb``.creature s
LEFT JOIN ``$BaselineDb``.creature w ON w.guid = s.guid
WHERE w.guid IS NULL AND s.map = $map
"@
        $count = Get-ScalarInt $countQ
        if ($count -eq 0) { continue }

        $header = @(
            "-- Portable creature spawns: map $map",
            "-- Rows: $count",
            "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            ''
        )
        Write-SqlUtf8NoBomLines -Path $outFile -Lines $header

        $offset = 0
        $part = 1
        while ($true) {
            $idsQ = @"
SELECT s.guid
FROM ``$StagingDb``.creature s
LEFT JOIN ``$BaselineDb``.creature w ON w.guid = s.guid
WHERE w.guid IS NULL AND s.map = $map
ORDER BY s.guid
LIMIT $ChunkSize OFFSET $offset
"@
            $ids = @(Invoke-DbPortQuery -Query $idsQ -Database $StagingDb | Where-Object { $_ -match '^\d+$' })
            if ($ids.Count -eq 0) { break }

            $where = "guid IN ($($ids -join ','))"
            if ($part -eq 1 -and $ids.Count -eq $count) {
                Append-SqlUtf8NoBom -Path $outFile -Content (ConvertTo-SqlText (Export-TableChunk -Table 'creature' -Where $where))
                break
            }

            $partFile = $outFile -replace '\.sql$', "_part$part.sql"
            $partHeader = if ($part -eq 1) {
                $header
            } else {
                @(
                    "-- Portable creature spawns: map $map (part $part)",
                    "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                    ''
                )
            }
            Write-SqlUtf8NoBomLines -Path $partFile -Lines $partHeader
            Append-SqlUtf8NoBom -Path $partFile -Content (ConvertTo-SqlText (Export-TableChunk -Table 'creature' -Where $where))
            $offset += $ChunkSize
            $part++
        }
        Write-Host "  map $map : $count spawns -> $outFile"
    }
}

function Export-TemplateUpdates {
    $outFile = Join-Path $OutDir "${stamp}_creature_template_updates.sql"
    $countQ = @"
SELECT COUNT(1)
FROM ``$StagingDb``.creature_template s
INNER JOIN ``$BaselineDb``.creature_template w ON w.entry = s.entry
WHERE s.AIName <> w.AIName OR s.ScriptName <> w.ScriptName
"@
    $count = Get-ScalarInt $countQ
    Write-Host "creature_template updates: $count"

    if ($DryRun -or $count -eq 0) { return }

    $genQ = @"
SELECT CONCAT(
    'UPDATE `creature_template` SET `AIName` = ''',
    REPLACE(s.AIName, '''', ''''''),
    ''', `ScriptName` = ''',
    REPLACE(IFNULL(s.ScriptName, ''), '''', ''''''),
    ''' WHERE `entry` = ', s.entry, ';'
)
FROM ``$StagingDb``.creature_template s
INNER JOIN ``$BaselineDb``.creature_template w ON w.entry = s.entry
WHERE s.AIName <> w.AIName OR s.ScriptName <> w.ScriptName
ORDER BY s.entry
"@
    $lines = @(
        "-- Portable creature_template AIName/ScriptName updates",
        "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "-- Rows: $count",
        ''
    )
    $updates = @(Invoke-DbPortQuery -Query $genQ -Database $StagingDb)
    $lines += $updates
    Write-SqlUtf8NoBomLines -Path $outFile -Lines $lines
    Write-Host "  wrote $outFile"
}

Write-Host "Materializing delta: $BaselineDb -> $StagingDb"
Write-Host "Output: $OutDir"
if ($DryRun) { Write-Host 'DRY RUN (counts only)' }

if ($BaselineSql) {
    if (-not (Test-Path $BaselineSql)) {
        throw "BaselineSql not found: $BaselineSql"
    }
    Write-Host "Importing baseline SQL into '$BaselineDb' from $BaselineSql..."
    Invoke-DbPortQuery -Query "DROP DATABASE IF EXISTS ``$BaselineDb``;" | Out-Null
    Invoke-DbPortQuery -Query "CREATE DATABASE ``$BaselineDb`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" | Out-Null
    Invoke-DbPortSqlFile -SqlFile $BaselineSql -Database $BaselineDb
    Write-Host "Baseline '$BaselineDb' ready from SQL dump."
}

if ($SplitCreatureByMap) {
    Export-CreatureByMap
    $exportTables = $exportTables | Where-Object { $_ -ne 'creature' }
}

foreach ($table in $exportTables) {
    if (-not $tableDefs.ContainsKey($table)) {
        Write-Warning "Unknown table: $table"
        continue
    }
    $def = $tableDefs[$table]
    $outFile = Join-Path $OutDir "${stamp}_${table}.sql"
    Get-ChildItem $OutDir -Filter "${stamp}_${table}*.sql" -ErrorAction SilentlyContinue |
        Remove-Item -Force
    Export-TableDelta -Table $table -Def $def -OutFile $outFile | Out-Null
}

if ($IncludeTemplateUpdates) {
    Export-TemplateUpdates
}

# Copy already-portable maintenance scripts from world/ (no loa.* refs).
$portableOnly = Get-ChildItem (Join-Path $cfg.RepoRoot 'sql\updates\world') -Filter '2026-06-25_world_*.sql' |
    Where-Object {
        $c = Get-Content $_.FullName -Raw
        $c -notmatch '`loa`\.'
    }

$manifest = @(
    "# Portable SQL manifest",
    "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "# Apply order: numbered delta files, then standalone scripts below.",
    ''
)

Get-ChildItem $OutDir -Filter "${stamp}_*.sql" | Sort-Object Name | ForEach-Object {
    $manifest += $_.Name
}

if ($portableOnly) {
    $manifest += ''
    $manifest += '# Standalone scripts (already portable from sql/updates/world/)'
    $portableOnly | Sort-Object Name | ForEach-Object { $manifest += $_.Name }
}

$manifestPath = Join-Path $OutDir "${stamp}_MANIFEST.txt"
Write-SqlUtf8NoBomLines -Path $manifestPath -Lines $manifest

Write-Host "Done. See $manifestPath"
