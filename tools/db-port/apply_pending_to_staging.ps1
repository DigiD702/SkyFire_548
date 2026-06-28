# Apply all pending port SQL files to world_staging in order.

param(
    [string]$Database = 'world_staging',
    [string]$PendingDir
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$PendingDir = if ($PendingDir) { $PendingDir } else { Join-Path $cfg.RepoRoot 'sql\pending_updates\world' }

$files = Get-ChildItem $PendingDir -Filter '*.sql' | Sort-Object Name
if (-not $files) {
    Write-Host "No pending SQL files in $PendingDir"
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
