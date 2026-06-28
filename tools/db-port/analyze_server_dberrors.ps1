# Summarize latest worldserver boot errors from DBErrors.log
# Usage: .\analyze_server_dberrors.ps1
#        .\analyze_server_dberrors.ps1 -LogFile C:\SkyFire_Files\Server\DBErrors.log

param(
    [string]$LogFile = 'C:\SkyFire_Files\Server\DBErrors.log'
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'config.ps1')

if (-not (Test-Path $LogFile)) {
    throw "DBErrors.log not found: $LogFile"
}

$logInfo = Get-Item $LogFile
$lines = Get-Content $LogFile

# DBErrors.log is rewritten each boot; if the classic marker is at line 1, the whole file is one boot.
$marker = '^Gameobject \(Entry: 181105'
$markerHits = @($lines | Select-String $marker)
$start = 0
if ($markerHits.Count -gt 1) {
    $start = $markerHits[-1].LineNumber - 1
}

$boot = $lines[$start..($lines.Count - 1)]
Write-Output "Log: $LogFile (modified $($logInfo.LastWriteTime))"
Write-Output "Boot slice: line $($start + 1)..$($lines.Count) ($($boot.Count) lines)"
Write-Output ''

function Get-BootCount([string]$Pattern) {
    return (@($boot | Select-String $Pattern)).Count
}

# Live DB sanity (optional; helps when log is stale vs fixes already applied)
try {
    $cfg = $script:DbPortConfig
    $env:MYSQL_PWD = $cfg.Password
    $mysql = $cfg.Mysql
    if (Test-Path $mysql) {
        $args = @('-h', $cfg.Host, '-P', $cfg.Port, '-u', $cfg.User, '-N', '-B', 'world')
        $s4096 = & $mysql @args '-e' 'SELECT COUNT(*) FROM creature WHERE map IN (999,1000,1050,1135) AND spawnMask=4096' 2>$null
        $s1 = & $mysql @args '-e' 'SELECT COUNT(*) FROM creature WHERE map IN (999,1000,1050,1135) AND spawnMask=1' 2>$null
        $sayge = & $mysql @args '-e' 'SELECT COUNT(*) FROM smart_scripts WHERE entryorguid=14822 AND id=14' 2>$null
        $w06 = & $mysql @args '-e' "SELECT COUNT(*) FROM skyfire_db_updates WHERE filename='2026-06-27_world_06.sql'" 2>$null
        Write-Output '=== DB state (world) ==='
        Write-Output "  world_06 applied: $w06"
        Write-Output "  Sayge smart_scripts row id=14: $sayge (want 0)"
        Write-Output "  Scenario spawns spawnMask=4096: $s4096"
        Write-Output "  Scenario spawns spawnMask=1: $s1 (want 0)"
        Write-Output ''
    }
} catch {
    Write-Output "=== DB state: skipped ($($_.Exception.Message)) ==="
    Write-Output ''
}

Write-Output '=== SmartAI ==='
$smart = @($boot | Select-String 'SmartAIMgr:')
$smartReal = @($smart | Where-Object { $_ -notmatch 'Kill Credit: There is|summon spell for creature entry' })
Write-Output "Total SmartAIMgr lines: $($smart.Count)"
Write-Output "  Kill-credit hints (informational): $(Get-BootCount 'Kill Credit: There is')"
Write-Output "  Summon-spell hints (informational): $(Get-BootCount 'summon spell for creature entry')"
Write-Output "  Real issues (skipped/broken): $($smartReal.Count)"
$smartReal | Select-Object -First 10 | ForEach-Object { Write-Output "    $($_.Line)" }

Write-Output ''
Write-Output '=== Creature table ==='
$creature = @($boot | Select-String 'Table ``creature``|Table `creature`')
Write-Output "Total creature table lines: $($creature.Count)"
$spawn4096 = Get-BootCount 'wrong spawn mask 4096'
$spawn1 = Get-BootCount 'wrong spawn mask 1'
$spawnOther = $creature.Count - $spawn4096 - $spawn1 - (Get-BootCount 'non existing creature entry') - (Get-BootCount 'CREATURE_FLAG_EXTRA_INSTANCE_BIND')
Write-Output "  Wrong spawnMask 4096 (needs rebuilt worldserver MapDifficulty): $spawn4096"
Write-Output "  Wrong spawnMask 1 on scenario maps: $spawn1"
Write-Output "  Other creature issues: $spawnOther"
$creature | Select-String 'wrong spawn mask' | ForEach-Object {
    if ($_.Line -match 'map \(Id: (\d+)\)') { $matches[1] }
} | Group-Object | Sort-Object Count -Descending | Select-Object -First 6 | ForEach-Object {
    Write-Output "    map $($_.Name): $($_.Count)"
}
Write-Output "  Missing template: $(Get-BootCount 'non existing creature entry')"
Write-Output "  flags_extra instance: $(Get-BootCount 'CREATURE_FLAG_EXTRA_INSTANCE_BIND')"

Write-Output ''
Write-Output '=== Other top categories ==='
Write-Output "  Scriptname spell missing: $(Get-BootCount 'Scriptname:.*spell.*does not exist')"
Write-Output "  CreatureTextMgr: $(Get-BootCount 'CreatureTextMgr:')"
Write-Output "  Gameobject table: $(Get-BootCount 'Table ``gameobject``|Table `gameobject`')"

if ($spawn4096 -gt 0 -or $spawn1 -gt 0) {
    Write-Output ''
    Write-Output 'Note: scenario spawnMask 4096 errors clear after rebuilding worldserver (DBCStores.cpp).'
}
