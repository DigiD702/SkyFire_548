# Apply local port SQL updates to a staging database.

param(
    [string]$Database = 'world_staging',
    [string]$UpdatesDir,
    [string]$Filter = '2026-06-25_world_*.sql'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$UpdatesDir = if ($UpdatesDir) { $UpdatesDir } else { Join-Path $cfg.RepoRoot 'sql\updates\world' }

$files = Get-ChildItem $UpdatesDir -Filter $Filter | Sort-Object Name
if (-not $files) {
    Write-Host "No SQL files matching $Filter in $UpdatesDir"
    exit 0
}

$env:MYSQL_PWD = $cfg.Password
$mysqlArgs = @('-h', $cfg.Host, '-P', $cfg.Port, '-u', $cfg.User, $Database)

foreach ($file in $files) {
    Write-Host "Applying $($file.Name) to $Database..."
    Get-Content $file.FullName -Raw | & $cfg.Mysql @mysqlArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed applying $($file.Name)"
    }
}

Write-Host "Applied $($files.Count) files to $Database."
