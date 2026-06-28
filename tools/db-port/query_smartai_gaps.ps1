. (Join-Path $PSScriptRoot 'config.ps1')

# Waypoint paths referenced by SAI WP_START on zone 860/870 creatures but missing in world_staging.
$missing = Invoke-DbPortQuery -Database 'world_staging' -Query @'
SELECT DISTINCT s.action_param2 AS pathId
FROM smart_scripts s
WHERE s.source_type = 0
  AND s.action_type = 53
  AND s.action_param2 > 0
  AND s.entryorguid IN (SELECT DISTINCT id FROM creature WHERE map IN (860, 870))
  AND s.action_param2 NOT IN (SELECT DISTINCT entry FROM waypoints)
ORDER BY pathId;
'@

$paths = @($missing | Where-Object { $_ -match '^\d+$' })
Write-Output "Missing waypoint paths (zone 860/870 SAI): $($paths.Count)"
if ($paths.Count -gt 0) {
    $paths -join ',' | Out-File (Join-Path $PSScriptRoot 'output\missing_zone_waypoint_paths.txt') -Encoding utf8 -NoNewline
    $paths | Select-Object -First 20
}

# Categorize SmartAI errors from staging log
$cfg = $script:DbPortConfig
$log = $cfg.DbErrorsLog
if (Test-Path $log) {
    $lines = Get-Content $log
    $cats = @{
        waypoint = ($lines | Select-String 'non-existent WaypointPath').Count
        invalid_action = ($lines | Select-String 'invalid action type').Count
        invalid_event = ($lines | Select-String 'invalid event type').Count
        not_handled = ($lines | Select-String 'Not handled action_type').Count
        missing_spell = ($lines | Select-String 'non-existent Spell entry').Count
        missing_creature = ($lines | Select-String 'Creature entry .* does not exist').Count
        killcredit_warn = ($lines | Select-String 'Kill Credit: There is a killcredit spell').Count
        summon_warn = ($lines | Select-String 'creature summon: There is a summon spell').Count
    }
    Write-Output '--- SmartAI log categories ---'
    $cats.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Output ("{0}: {1}" -f $_.Key, $_.Value) }
}
