# Generate portable DELETE SQL for LOA-only creature spawns that duplicate SFDB outdoor coverage.
# Compares live DB to world_sfdb baseline; keeps quest/service/SmartAI NPCs.
#
# Usage:
#   .\generate_loa_overflow_removal.ps1 -Maps 870 -DryRun
#   .\generate_loa_overflow_removal.ps1 -Maps 870 -OutputFile output\loa_overflow_map870.sql
#   .\generate_loa_overflow_removal.ps1 -AllOutdoorMoP -AllowRepoOutput -OutputFile sql\updates\world\2026-06-28_world_10.sql

param(
    [string]$Database = 'world',
    [string]$BaselineDatabase = 'world_sfdb',
    [int[]]$Maps = @(),
    [switch]$AllOutdoorMoP,
    [string]$OutputFile = 'output\loa_overflow_removal.sql',
    [switch]$AllowRepoOutput,
    [switch]$DryRun
)

if ($AllOutdoorMoP) {
    $Maps = @(860, 870, 859, 861, 1064)
}

if ($Maps.Count -eq 0) {
    throw 'Specify -Maps or -AllOutdoorMoP'
}

. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

$mapList = ($Maps | ForEach-Object { [string]$_ }) -join ','
$scopeLabel = "maps $mapList"

$isRepoUpdatePath = $OutputFile -match '(^|[\\/])sql[\\/]updates[\\/]world[\\/]'
if ($isRepoUpdatePath -and -not $AllowRepoOutput) {
    throw "Refusing to write repo update '$OutputFile'. Use output/ or pass -AllowRepoOutput."
}

$outPath = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile
} elseif ($isRepoUpdatePath) {
    Join-Path $cfg.RepoRoot ($OutputFile -replace '/', '\')
} else {
    Join-Path $cfg.OutputDir $OutputFile
}

$keepFilter = @"
AND NOT (
  (ct.npcflag & 3) <> 0
  OR ct.ScriptName <> ''
  OR ct.AIName = 'SmartAI'
  OR EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
  OR EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
  OR EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
  OR EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
  OR EXISTS (SELECT 1 FROM smart_scripts ss WHERE ss.entryorguid = ct.entry AND ss.source_type = 0)
)
"@

$query = @"
SELECT w.guid
FROM ``$Database``.creature w
LEFT JOIN ``$BaselineDatabase``.creature b ON b.guid = w.guid
INNER JOIN ``$Database``.creature_template ct ON ct.entry = w.id
WHERE w.map IN ($mapList)
  AND b.guid IS NULL
  $keepFilter
ORDER BY w.guid;
"@

Write-Host "Finding LOA-only redundant spawns ($scopeLabel)..."
$lines = Invoke-DbPortQuery -Query $query -Database $Database
$guids = @($lines | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int64]$_ })

Write-Host "  removable guids: $($guids.Count)"

if ($DryRun) {
    exit 0
}

if ($guids.Count -eq 0) {
    Write-Host 'Nothing to remove.'
    exit 0
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- Remove LOA-only redundant outdoor spawns ($scopeLabel).")
[void]$sb.AppendLine("-- SFDB baseline already had outdoor coverage; LOA materialize stacked ~2x spawns on map 870.")
[void]$sb.AppendLine("-- Keeps quest/service/vendor/trainer/SmartAI/ScriptName NPCs not in baseline.")
[void]$sb.AppendLine('')

$chunkSize = 500
for ($i = 0; $i -lt $guids.Count; $i += $chunkSize) {
    $chunk = $guids[$i..([Math]::Min($i + $chunkSize - 1, $guids.Count - 1))]
    $guidList = ($chunk | ForEach-Object { [string]$_ }) -join ','
    [void]$sb.AppendLine("DELETE FROM ``creature`` WHERE ``guid`` IN ($guidList);")
}

$outDir = Split-Path -Parent $outPath
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)
Write-Host "Wrote $outPath ($($guids.Count) guids)"
