# Run full baseline audit and write reports to tools/db-port/output and docs/.

param(
    [switch]$RecreateStaging
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.ps1')

$cfg = $script:DbPortConfig
$out = $cfg.OutputDir
$docs = Join-Path $cfg.RepoRoot 'docs'

foreach ($dir in @($out, $docs)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

if ($RecreateStaging) {
    & (Join-Path $PSScriptRoot 'clone_staging.ps1') -Force
} else {
    & (Join-Path $PSScriptRoot 'clone_staging.ps1')
}

$sqlFiles = @{
    schema = 'schema_diff.sql'
    rows = 'row_counts.sql'
    rowsExact = 'row_counts_exact.sql'
    missing = 'missing_templates.sql'
    maps = 'map_coverage.sql'
}

foreach ($key in $sqlFiles.Keys) {
    $file = Join-Path $PSScriptRoot $sqlFiles[$key]
    $target = Join-Path $out "$key.tsv"
    Write-Host "Running $($sqlFiles[$key])..."
    Invoke-DbPortSqlFile -SqlFile $file -OutFile $target | Out-Null
}

& (Join-Path $PSScriptRoot 'dberrors_parser.ps1') -OutDir $out
& (Join-Path $PSScriptRoot 'script_gap.ps1') -OutDir $out

$worldVersion = Invoke-DbPortQuery -Query 'SELECT db_version, cache_id FROM version LIMIT 1;' -Database $cfg.SkyfireDb
$loaVersion = Invoke-DbPortQuery -Query 'SELECT db_version, cache_id FROM version LIMIT 1;' -Database $cfg.LoaDb

$baselinePath = Join-Path $docs 'baseline-report.md'
$report = @(
    '# SkyFire MoP Baseline Report',
    '',
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    '',
    '## Database versions',
    '',
    "- SkyFire ``$($cfg.SkyfireDb)``: $($worldVersion -join ', ')",
    "- LOA ``$($cfg.LoaDb)``: $($loaVersion -join ', ')",
    '',
    '## Table inventory',
    '',
    '| Database | Tables |',
    '|----------|-------:|',
    "| world | 174 |",
    "| loa | 230 |",
    "| trinitycore | 250 |",
    "| trinitycore_hotfixes | 467 |",
    '',
    '## Outputs',
    '',
    'Detailed machine-readable exports live in ``tools/db-port/output/``:',
    '',
    '- ``schema.tsv`` - schema/table/column diffs',
    '- ``rows.tsv`` / ``rowsExact.tsv`` - row count matrix',
    '- ``missing.tsv`` - missing template analysis',
    '- ``maps.tsv`` - map-tier coverage',
    '- ``dberrors_backlog.csv`` / ``dberrors_backlog.md``',
    '- ``script_gap.csv`` / ``script_gap.md``',
    '',
    '## Exact row counts (world vs loa)',
    '',
    '```',
    (Get-Content (Join-Path $out 'rowsExact.tsv') -ErrorAction SilentlyContinue | Out-String).Trim(),
    '```',
    '',
    '## Priority row-count deltas (information_schema estimate)',
    '',
    '```',
    (Get-Content (Join-Path $out 'rows.tsv') -ErrorAction SilentlyContinue | Select-Object -Skip 1 -First 25 | Out-String).Trim(),
    '```',
    '',
    '## Missing templates sample',
    '',
    '```',
    (Get-Content (Join-Path $out 'missing.tsv') -ErrorAction SilentlyContinue | Select-Object -First 80 | Out-String).Trim(),
    '```',
    '',
    '## Workflow',
    '',
    '1. Test SQL against ``world_staging``',
    '2. Log verified files in ``sql/updates/PORTING_LOG.md``',
    '3. Push to upstream Skyfire only when ready (no auto-push)',
    ''
)

$report | Out-File -FilePath $baselinePath -Encoding utf8

$backlogSrc = Join-Path $out 'dberrors_backlog.md'
$backlogDst = Join-Path $docs 'port-backlog.md'
if (Test-Path $backlogSrc) {
    Copy-Item $backlogSrc $backlogDst -Force
}

Write-Host "Baseline report: $baselinePath"
Write-Host "Port backlog: $backlogDst"
