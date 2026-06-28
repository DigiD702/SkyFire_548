# Parses DBErrors.log into a prioritized backlog CSV and summary markdown.

param(
    [string]$LogFile,
    [string]$OutDir
)

. (Join-Path $PSScriptRoot 'config.ps1')

$cfg = $script:DbPortConfig
$LogFile = if ($LogFile) { $LogFile } else { $cfg.DbErrorsLog }
$OutDir = if ($OutDir) { $OutDir } else { $cfg.OutputDir }

if (-not (Test-Path $LogFile)) {
    throw "DBErrors.log not found: $LogFile"
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$rules = @(
    @{ Priority = 'P0'; Pattern = 'non existing creature entry'; Category = 'missing_creature_template'; LoaHint = 'loa.creature_template INSERT' }
    @{ Priority = 'P0'; Pattern = 'non existing gameobject entry'; Category = 'missing_gameobject_template'; LoaHint = 'loa.gameobject_template INSERT' }
    @{ Priority = 'P1'; Pattern = 'Table `creature` has creature'; Category = 'creature_spawn_issue'; LoaHint = 'Compare spawn vs loa.creature' }
    @{ Priority = 'P1'; Pattern = 'Table `gameobject` has gameobject'; Category = 'gameobject_spawn_issue'; LoaHint = 'Compare spawn vs loa.gameobject' }
    @{ Priority = 'P2'; Pattern = "does not have a script name assigned in database"; Category = 'unbound_cpp_script'; LoaHint = 'Match ScriptName in loa templates' }
    @{ Priority = 'P3'; Pattern = 'has different `npcflag` in difficulty'; Category = 'creature_difficulty_npcflag'; LoaHint = 'Diff creature_template heroic pairs in loa' }
    @{ Priority = 'P3'; Pattern = 'has different `unit_class` in difficulty'; Category = 'creature_difficulty_unit_class'; LoaHint = 'Diff creature_template heroic pairs in loa' }
    @{ Priority = 'P3'; Pattern = 'non-existing faction'; Category = 'creature_faction'; LoaHint = 'loa.creature_template faction columns' }
    @{ Priority = 'P4'; Pattern = 'but Spell (Entry'; Category = 'gameobject_missing_spell_dbc'; LoaHint = 'Often DBC-limited; verify Wowhead' }
    @{ Priority = 'P4'; Pattern = 'lock \(Id:'; Category = 'gameobject_missing_lock_dbc'; LoaHint = 'Often DBC-limited; verify Wowhead' }
    @{ Priority = 'P4'; Pattern = 'SpellFocus'; Category = 'gameobject_missing_spellfocus_dbc'; LoaHint = 'Often DBC-limited; verify Wowhead' }
    @{ Priority = 'P5'; Pattern = 'SmartAIMgr:'; Category = 'smartai_validation'; LoaHint = 'Compare loa.smart_scripts' }
    @{ Priority = 'P5'; Pattern = 'Table `creature_template`'; Category = 'creature_template_cleanup'; LoaHint = 'Template validation cleanup' }
    @{ Priority = 'P5'; Pattern = 'loot template'; Category = 'loot_template'; LoaHint = 'Compare loa loot tables' }
)

$lines = Get-Content $LogFile

# dberrors.log is appended across worldserver runs; analyze only the latest boot.
$bootMarkers = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^Gameobject \(Entry: 181105') {
        $bootMarkers += $i
    }
}
if ($bootMarkers.Count -gt 0) {
    $start = $bootMarkers[-1]
    $lines = $lines[$start..($lines.Count - 1)]
}

$records = New-Object System.Collections.Generic.List[object]
$summary = @{}

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    $matched = $false
    foreach ($rule in $rules) {
        if ($line -like "*$($rule.Pattern)*") {
            $key = "$($rule.Priority)|$($rule.Category)"
            if (-not $summary.ContainsKey($key)) {
                $summary[$key] = @{
                    Priority = $rule.Priority
                    Category = $rule.Category
                    LoaHint = $rule.LoaHint
                    Count = 0
                    Sample = $line
                }
            }
            $summary[$key].Count++
            $matched = $true
            break
        }
    }

    if (-not $matched) {
        $key = 'P5|uncategorized'
        if (-not $summary.ContainsKey($key)) {
            $summary[$key] = @{
                Priority = 'P5'
                Category = 'uncategorized'
                LoaHint = 'Manual triage'
                Count = 0
                Sample = $line
            }
        }
        $summary[$key].Count++
    }
}

$csvPath = Join-Path $OutDir 'dberrors_backlog.csv'
$summaryRows = $summary.GetEnumerator() | ForEach-Object { $_.Value } |
    Sort-Object Priority, @{ Expression = { $_.Count }; Descending = $true }, Category

$summaryRows | ForEach-Object {
    [PSCustomObject]@{
        priority = $_.Priority
        category = $_.Category
        count = $_.Count
        loa_hint = $_.LoaHint
        sample = $_.Sample
    }
} | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$mdPath = Join-Path $OutDir 'dberrors_backlog.md'
$md = @(
    '# DBErrors Backlog',
    '',
    "Source: ``$LogFile`` (latest boot, $($lines.Count) lines)",
    '',
    '| Priority | Category | Count | LOA hint | Sample |',
    '|----------|----------|------:|----------|--------|'
)

foreach ($row in $summaryRows) {
    $sample = ($row.Sample -replace '\|', '/')
    if ($sample.Length -gt 120) { $sample = $sample.Substring(0, 117) + '...' }
    $md += "| $($row.Priority) | $($row.Category) | $($row.Count) | $($row.LoaHint) | $sample |"
}

$md | Out-File -FilePath $mdPath -Encoding utf8

Write-Host "Wrote $csvPath"
Write-Host "Wrote $mdPath"
