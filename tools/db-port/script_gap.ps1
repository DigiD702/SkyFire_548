# Compare compiled C++ script registration names with database script name usage.

param(
    [string]$OutDir
)

. (Join-Path $PSScriptRoot 'config.ps1')

$cfg = $script:DbPortConfig
$OutDir = if ($OutDir) { $OutDir } else { $cfg.OutputDir }
$repo = $cfg.RepoRoot

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$scriptDirs = @(
    Join-Path $repo 'src\server\scripts'
)

$cppFiles = Get-ChildItem -Path $scriptDirs -Recurse -Include *.cpp -File -ErrorAction SilentlyContinue

# Script names are usually registered via RegisterCreatureAI, new factory, or scriptName literals.
$namePatterns = @(
    'RegisterCreatureAI\(\s*"([^"]+)"',
    'RegisterGameObjectAI\(\s*"([^"]+)"',
    'RegisterSpellScript\(\s*(\w+)',
    'RegisterAuraScript\(\s*(\w+)',
    'RegisterAreaTriggerAI\(\s*"([^"]+)"',
    'new (\w+Script)\(',
    'ScriptName\(\)\s+const\s+override\s*\{\s*return\s*"([^"]+)"'
)

$found = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($file in $cppFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    foreach ($pattern in $namePatterns) {
        [regex]::Matches($content, $pattern) | ForEach-Object {
            $value = $_.Groups[1].Value
            if ($value) { [void]$found.Add($value) }
        }
    }
}

# Pull script names referenced in DB.
$dbQuery = @"
SELECT DISTINCT script_name FROM (
    SELECT ScriptName AS script_name FROM world.creature_template WHERE ScriptName <> ''
    UNION SELECT ScriptName FROM world.gameobject_template WHERE ScriptName <> ''
    UNION SELECT script AS script_name FROM world.instance_template WHERE script <> ''
    UNION SELECT ScriptName FROM world.battleground_template WHERE ScriptName <> ''
    UNION SELECT ScriptName FROM world.spell_script_names
    UNION SELECT ScriptName FROM world.areatrigger_scripts
    UNION SELECT ScriptName FROM world.item_script_names
    UNION SELECT ScriptName FROM world.scene_template WHERE ScriptName IS NOT NULL AND ScriptName <> ''
) s
ORDER BY script_name;
"@

$dbNames = Invoke-DbPortQuery -Query $dbQuery -Database $cfg.SkyfireDb
$dbSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$dbNames, [StringComparer]::OrdinalIgnoreCase)

$missingInDb = $found | Where-Object { -not $dbSet.Contains($_) } | Sort-Object
$missingInSource = $dbSet | Where-Object { -not $found.Contains($_) } | Sort-Object

$csvPath = Join-Path $OutDir 'script_gap.csv'
$rows = @()
foreach ($name in $missingInDb) {
    $rows += [PSCustomObject]@{ direction = 'cpp_not_in_db'; script_name = $name }
}
foreach ($name in $missingInSource) {
    $rows += [PSCustomObject]@{ direction = 'db_not_in_cpp_scan'; script_name = $name }
}
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$mdPath = Join-Path $OutDir 'script_gap.md'
$md = @(
    '# Script Gap Analysis',
    '',
    "C++ names discovered (heuristic scan): $($found.Count)",
    "DB script names: $($dbSet.Count)",
    "C++ names missing DB assignment (heuristic): $($missingInDb.Count)",
    "DB names not matched by C++ scan: $($missingInSource.Count)",
    '',
    'Note: C++ discovery is heuristic. DBErrors.log unbound script list is authoritative for startup warnings.',
    ''
)
$md | Out-File -FilePath $mdPath -Encoding utf8

Write-Host "Wrote $csvPath"
Write-Host "Wrote $mdPath"
