# Import fresh SFDB baseline and apply portable SQL manifest (no LOA required).

param(
    [string]$Database = 'world_validate',
    [string]$ManifestFile,
    [string]$BaselineSql,
    [string]$CompareWith = 'world_staging',
    [switch]$ImportFresh,
    [switch]$SkipImport,
    [string]$ResumeFrom,
    [switch]$CompareOnly
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig

$worldDir = Join-Path $cfg.RepoRoot 'sql\updates\world'
$ManifestFile = if ($ManifestFile) { $ManifestFile } else {
    Get-ChildItem $worldDir -Filter '*_MANIFEST.txt' | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
}
$BaselineSql = if ($BaselineSql) { $BaselineSql } else { Join-Path $cfg.RepoRoot 'sql\world.sql' }

if (-not $ManifestFile -or -not (Test-Path $ManifestFile)) {
    throw "Manifest not found: $ManifestFile"
}

$manifestFiles = Get-Content $ManifestFile | Where-Object {
    $_ -and $_ -notmatch '^\s*#' -and $_ -match '\.sql\s*$'
} | ForEach-Object { $_.Trim() }

$env:MYSQL_PWD = $cfg.Password
$mysqlBase = @('-h', $cfg.Host, '-P', $cfg.Port, '-u', $cfg.User, '--default-character-set=utf8mb4')

function Invoke-MysqlQuery {
    param([string]$Query, [string]$Db)
    $args = $mysqlBase + @('-N', '-B', '-e', $Query)
    if ($Db) { $args += $Db }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & $cfg.Mysql @args 2>&1
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($LASTEXITCODE -ne 0) {
        throw "mysql failed: $out"
    }
    return $out
}

function Invoke-MysqlFile {
    param([string]$SqlFile, [string]$Db)
    if (-not (Test-Path $SqlFile)) {
        throw "SQL file not found: $SqlFile"
    }
    $args = $mysqlBase + @($Db)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $err = Get-Content $SqlFile -Raw | & $cfg.Mysql @args 2>&1
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($LASTEXITCODE -ne 0) {
        $msg = ($err | Out-String).Trim()
        throw "Failed applying $(Split-Path $SqlFile -Leaf): $msg"
    }
}

if (-not $CompareOnly) {
    if ($ImportFresh -or -not $SkipImport) {
        if (-not (Test-Path $BaselineSql)) {
            throw "Baseline SQL not found: $BaselineSql"
        }
        Write-Host "Dropping and recreating database '$Database'..."
        Invoke-MysqlQuery -Query "DROP DATABASE IF EXISTS ``$Database``;" | Out-Null
        Invoke-MysqlQuery -Query "CREATE DATABASE ``$Database`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" | Out-Null

        $sizeMb = [math]::Round((Get-Item $BaselineSql).Length / 1MB, 1)
        Write-Host "Importing baseline from $BaselineSql ($sizeMb MB)..."
        $importStart = Get-Date
        Invoke-MysqlFile -SqlFile $BaselineSql -Db $Database
        $importSec = [math]::Round(((Get-Date) - $importStart).TotalSeconds, 1)
        Write-Host "Baseline import complete in ${importSec}s."
    }

    $applied = 0
    $resuming = [bool]$ResumeFrom
    foreach ($name in $manifestFiles) {
        if ($resuming) {
            if ($name -ne $ResumeFrom) { continue }
            $resuming = $false
        }
        $path = Join-Path $worldDir $name
        Write-Host "[$($applied + 1)/$($manifestFiles.Count)] $name"
        $fileStart = Get-Date
        Invoke-MysqlFile -SqlFile $path -Db $Database
        $sec = [math]::Round(((Get-Date) - $fileStart).TotalSeconds, 1)
        if ($sec -ge 5) {
            Write-Host "  done in ${sec}s"
        }
        $applied++
    }
    Write-Host "Applied $applied manifest files to '$Database'."
}

if ($CompareWith) {
    Write-Host ""
    Write-Host "Comparing '$Database' vs '$CompareWith' (key tables):"
    $tables = @(
        'creature',
        'creature_template',
        'smart_scripts',
        'spell_script_names',
        'creature_model_info',
        'waypoints',
        'scene_template',
        'hotfix_data'
    )
    $mismatches = 0
    foreach ($t in $tables) {
        $a = Invoke-MysqlQuery -Query "SELECT COUNT(*) FROM ``$t``;" -Db $Database
        $b = Invoke-MysqlQuery -Query "SELECT COUNT(*) FROM ``$t``;" -Db $CompareWith
        $match = if ($a -eq $b) { 'OK' } else { 'DIFF'; $mismatches++ }
        Write-Host ("  {0,-22} {1,10} vs {2,10}  {3}" -f $t, $a, $b, $match)
    }

    $maps = @(860, 870, 859, 861, 1064, 1050, 1098, 1135, 1004)
    Write-Host ""
    Write-Host "Outdoor MoP spawn counts by map:"
    foreach ($m in $maps) {
        $a = Invoke-MysqlQuery -Query "SELECT COUNT(*) FROM creature WHERE map=$m;" -Db $Database
        $b = Invoke-MysqlQuery -Query "SELECT COUNT(*) FROM creature WHERE map=$m;" -Db $CompareWith
        $match = if ($a -eq $b) { 'OK' } else { 'DIFF'; $mismatches++ }
        Write-Host ("  map {0,-5} {1,10} vs {2,10}  {3}" -f $m, $a, $b, $match)
    }

    if ($mismatches -eq 0) {
        Write-Host ""
        Write-Host "All compared counts match '$CompareWith'."
    } else {
        Write-Host ""
        Write-Host "WARNING: $mismatches count mismatches vs '$CompareWith'."
        exit 1
    }
}
