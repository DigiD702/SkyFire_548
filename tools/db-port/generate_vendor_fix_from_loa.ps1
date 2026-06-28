# Import missing npc_vendor rows from LOA as portable INSERT SQL (no loa DB required).
#
# Usage:
#   .\generate_vendor_fix_from_loa.ps1

param(
    [string]$Database = 'world',
    [string]$LoaDatabase = 'loa',
    [string]$OutputFile = '2026-06-27_world_02.sql'
)

. (Join-Path $PSScriptRoot 'config.ps1')
$cfg = $script:DbPortConfig
$env:MYSQL_PWD = $cfg.Password

$outPath = Join-Path $cfg.RepoRoot "sql\updates\world\$OutputFile"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$vendorFlagFilter = @"
(
    (ct.npcflag & 128) <> 0
    OR (ct.npcflag & 384) <> 0
    OR (ct.npcflag & 640) <> 0
    OR (ct.npcflag & 896) <> 0
    OR (ct.npcflag & 2176) <> 0
)
"@

$rowQuery = @"
SELECT l.entry, l.slot, l.item, l.maxcount, l.incrtime, l.ExtendedCost, l.type
FROM ``$LoaDatabase``.npc_vendor l
INNER JOIN creature_template ct ON ct.entry = l.entry
WHERE $vendorFlagFilter
  AND NOT EXISTS (
      SELECT 1 FROM npc_vendor w
      WHERE w.entry = l.entry AND w.item = l.item AND w.ExtendedCost = l.ExtendedCost
  )
ORDER BY l.entry, l.slot, l.item;
"@

Write-Host "Materializing vendor rows from $LoaDatabase..."

$lines = Invoke-DbPortQuery -Query $rowQuery -Database $Database
if (-not $lines) {
    Write-Host "No vendor rows to import."
    exit 0
}

$rows = foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 7) { continue }
    [pscustomobject]@{
        entry = $p[0]; slot = $p[1]; item = $p[2]; maxcount = $p[3]
        incrtime = $p[4]; ExtendedCost = $p[5]; type = $p[6]
    }
}

Write-Host "  $($rows.Count) vendor rows for $($rows.entry | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count) entries"

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- Import npc_vendor rows for vendor-flagged NPCs missing stock")
[void]$sb.AppendLine("-- Materialized from LOA. Regenerate: tools/db-port/generate_vendor_fix_from_loa.ps1")
[void]$sb.AppendLine("INSERT IGNORE INTO ``npc_vendor`` (``entry``, ``slot``, ``item``, ``maxcount``, ``incrtime``, ``ExtendedCost``, ``type``) VALUES")

for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    $suffix = if ($i -lt $rows.Count - 1) { ',' } else { ';' }
    [void]$sb.AppendLine(
        "    ($($r.entry), $($r.slot), $($r.item), $($r.maxcount), $($r.incrtime), $($r.ExtendedCost), $($r.type))$suffix"
    )
}

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)
Write-Host "Wrote $outPath"

$orphanQuery = @"
SELECT COUNT(DISTINCT ct.entry)
FROM creature_template ct
WHERE $vendorFlagFilter
  AND NOT EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
  AND NOT EXISTS (SELECT 1 FROM ``$LoaDatabase``.npc_vendor lv WHERE lv.entry = ct.entry)
  AND EXISTS (SELECT 1 FROM creature c WHERE c.id = ct.entry);
"@
$orphan = Invoke-DbPortQuery -Query $orphanQuery -Database $Database
Write-Host "  $orphan spawned vendors still need manual/Wowhead data (not in LOA)"
