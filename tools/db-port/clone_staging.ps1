# Clone world database to world_staging for safe SQL testing.

param(
    [switch]$Force
)

. (Join-Path $PSScriptRoot 'config.ps1')

$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

if (-not (Test-Path $cfg.Mysqldump)) {
    throw "mysqldump not found: $($cfg.Mysqldump)"
}

$exists = Invoke-DbPortQuery -Query "SHOW DATABASES LIKE '$($cfg.StagingDb)';"
if ($exists -and -not $Force) {
    Write-Host "Staging database '$($cfg.StagingDb)' already exists. Use -Force to recreate."
    exit 0
}

if ($exists -and $Force) {
    Invoke-DbPortQuery -Query "DROP DATABASE ``$($cfg.StagingDb)``;" | Out-Null
}

Write-Host "Creating staging database $($cfg.StagingDb) from $($cfg.SkyfireDb)..."
Invoke-DbPortQuery -Query "CREATE DATABASE ``$($cfg.StagingDb)`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" | Out-Null

$dumpArgs = @(
    '-h', $cfg.Host,
    '-P', $cfg.Port,
    '-u', $cfg.User,
    '--single-transaction',
    '--set-gtid-purged=OFF',
    '--routines',
    '--events',
    $cfg.SkyfireDb
)

$mysqlArgs = Get-DbPortMysqlArgs -Database $cfg.StagingDb
$mysqlArgs = $mysqlArgs | Where-Object { $_ -ne '-N' -and $_ -ne '-B' }

& $cfg.Mysqldump @dumpArgs | & $cfg.Mysql @mysqlArgs
if ($LASTEXITCODE -ne 0) {
    throw "Staging clone failed."
}

Write-Host "Staging database ready: $($cfg.StagingDb)"
