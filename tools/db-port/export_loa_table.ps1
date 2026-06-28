# Export rows from LOA into SkyFire-compatible INSERT SQL.

param(
    [Parameter(Mandatory)]
    [string]$Table,
    [string]$Where,
    [string]$TargetDb = 'world_staging',
    [string]$OutFile
)

. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig

if (-not $OutFile) {
    $stamp = Get-Date -Format 'yyyy-MM-dd'
    $OutFile = Join-Path $cfg.RepoRoot "sql\updates\world\${stamp}_loa_export_${Table}.sql"
}

$dir = Split-Path $OutFile -Parent
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$whereClause = if ($Where) { "WHERE $Where" } else { '' }
$query = "SELECT * FROM ``$($cfg.LoaDb)``.``$Table`` $whereClause;"

# Use mysqldump for reliable INSERT generation.
$dumpArgs = @(
    '-h', $cfg.Host,
    '-P', $cfg.Port,
    '-u', $cfg.User,
    '--no-create-info',
    '--complete-insert',
    '--skip-extended-insert',
    '--compact',
    $cfg.LoaDb,
    $Table
)

if ($Where) {
  # mysqldump --where must be passed separately
  $dumpArgs += "--where=$Where"
}

$header = @(
    "-- LOA export: $Table",
    "-- Source: $($cfg.LoaDb)",
    "-- Target: $TargetDb",
    "-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    ''
)

$header | Out-File -FilePath $OutFile -Encoding utf8
& $cfg.Mysqldump @dumpArgs | Add-Content -Path $OutFile -Encoding utf8

Write-Host "Wrote $OutFile"
