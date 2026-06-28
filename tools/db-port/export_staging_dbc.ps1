# Export staging DBC files via WDBX Editor for porting lookups.
# Usage:
#   .\export_staging_dbc.ps1 Spell.dbc
#   .\export_staging_dbc.ps1 Spell.dbc -Format json -OutDir tools\db-port\output\dbc
#   .\export_staging_dbc.ps1 Map.dbc,AreaTable.dbc -Format csv

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$DbcFiles,

    [ValidateSet('csv', 'json', 'sql')]
    [string]$Format = 'csv',

    [string]$OutDir,

    [int]$Build = 18414,

    [string]$DbcDir = 'C:\SkyFire_Files\Server_staging\dbc',

    [string]$WdbxExe = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\WDBX Editor')).Path 'WDBX Editor.exe')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $WdbxExe)) {
    throw "WDBX Editor not found: $WdbxExe"
}

if (-not (Test-Path $DbcDir)) {
    throw "DBC directory not found: $DbcDir"
}

$OutDir = if ($OutDir) { $OutDir } else { Join-Path $PSScriptRoot 'output\dbc' }
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

foreach ($dbc in $DbcFiles) {
    $dbcPath = Join-Path $DbcDir $dbc
    if (-not (Test-Path $dbcPath)) {
        Write-Warning "Skipping missing DBC: $dbcPath"
        continue
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($dbc)
    $outFile = Join-Path $OutDir ("{0}.{1}" -f $baseName, $Format)

    $args = @(
        '-export',
        '-f', $dbcPath,
        '-b', $Build,
        '-o', $outFile
    )

    Write-Host "Exporting $dbc -> $outFile"
    & $WdbxExe @args
    if ($LASTEXITCODE -ne 0) {
        throw "WDBX export failed for $dbc (exit $LASTEXITCODE)"
    }
}

Write-Host "Done. Output: $OutDir"
