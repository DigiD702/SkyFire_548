# Database connection settings for db-port audit tools.
# Override via environment variables if needed.

$script:DbPortConfig = @{
    Host     = if ($env:DB_PORT_HOST) { $env:DB_PORT_HOST } else { '127.0.0.1' }
    Port     = if ($env:DB_PORT_PORT) { [int]$env:DB_PORT_PORT } else { 3306 }
    User     = if ($env:DB_PORT_USER) { $env:DB_PORT_USER } else { 'root' }
    Password = if ($env:DB_PORT_PASSWORD) { $env:DB_PORT_PASSWORD } else { 'Dljtbvb629' }
    Mysql    = if ($env:MYSQL_BIN) { $env:MYSQL_BIN } else { 'C:\tools\mysql\current\bin\mysql.exe' }
    Mysqldump = if ($env:MYSQLDUMP_BIN) { $env:MYSQLDUMP_BIN } else { 'C:\tools\mysql\current\bin\mysqldump.exe' }

    SkyfireDb   = 'world'
    StagingDb   = 'world_staging'
    LoaDb       = 'loa'
    TrinityDb   = 'trinitycore'
    HotfixDb    = 'trinitycore_hotfixes'

    RepoRoot    = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    OutputDir   = (Join-Path $PSScriptRoot 'output')
    DbErrorsLog = 'C:\SkyFire_Files\Server\DBErrors.log'
    ServerLog   = 'C:\SkyFire_Files\Server\Server.log'
}

function Get-DbPortMysqlArgs {
    param(
        [string]$Database,
        [switch]$IncludePasswordArg
    )

    $cfg = $script:DbPortConfig
    $env:MYSQL_PWD = $cfg.Password

    $args = @(
        '-h', $cfg.Host,
        '-P', $cfg.Port,
        '-u', $cfg.User,
        '--default-character-set=utf8mb4',
        '-N',
        '-B'
    )

    if ($Database) {
        $args += $Database
    }

    return $args
}

function Invoke-DbPortQuery {
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        [string]$Database,
        [string]$OutFile
    )

    $cfg = $script:DbPortConfig
    if (-not (Test-Path $cfg.Mysql)) {
        throw "mysql client not found: $($cfg.Mysql)"
    }

    $mysqlArgs = Get-DbPortMysqlArgs -Database $Database
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $result = & $cfg.Mysql @mysqlArgs '-e' $Query 2>$null
    } finally {
        $ErrorActionPreference = $prevErrorAction
    }
    if ($LASTEXITCODE -ne 0) {
        throw "mysql query failed with exit code $LASTEXITCODE"
    }

    if ($OutFile) {
        $dir = Split-Path $OutFile -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $result | Out-File -FilePath $OutFile -Encoding utf8
    }

    return $result
}

function Invoke-DbPortSqlFile {
    param(
        [Parameter(Mandatory)]
        [string]$SqlFile,
        [string]$Database,
        [string]$OutFile
    )

    $cfg = $script:DbPortConfig
    if (-not (Test-Path $cfg.Mysql)) {
        throw "mysql client not found: $($cfg.Mysql)"
    }
    if (-not (Test-Path $SqlFile)) {
        throw "SQL file not found: $SqlFile"
    }

    $mysqlArgs = Get-DbPortMysqlArgs -Database $Database
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $result = Get-Content $SqlFile -Raw | & $cfg.Mysql @mysqlArgs 2>$null
    } finally {
        $ErrorActionPreference = $prevErrorAction
    }
    if ($LASTEXITCODE -ne 0) {
        throw "mysql script failed with exit code $LASTEXITCODE for $SqlFile"
    }

    if ($OutFile) {
        $dir = Split-Path $OutFile -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $result | Out-File -FilePath $OutFile -Encoding utf8
    }

    return $result
}
