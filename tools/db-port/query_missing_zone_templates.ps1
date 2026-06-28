. (Join-Path $PSScriptRoot 'config.ps1')

$missing = Invoke-DbPortQuery -Database 'world_staging' -Query @'
SELECT DISTINCT c.id
FROM creature c
LEFT JOIN creature_template ct ON ct.entry = c.id
WHERE c.map IN (860, 870) AND ct.entry IS NULL
ORDER BY c.id;
'@

$ids = @($missing | Where-Object { $_ -match '^\d+$' })
Write-Output "Missing entries: $($ids.Count)"
$ids -join ',' | Out-File (Join-Path $PSScriptRoot 'output\missing_zone_creature_entries.txt') -Encoding utf8 -NoNewline
$ids | Out-File (Join-Path $PSScriptRoot 'output\missing_zone_creature_entries_lines.txt') -Encoding utf8

$modelMissing = Invoke-DbPortQuery -Database 'world_staging' -Query @'
SELECT DISTINCT m.modelid
FROM (
    SELECT modelid1 AS modelid FROM creature_template WHERE entry IN (
        SELECT DISTINCT c.id FROM creature c WHERE c.map IN (860,870)
    )
    UNION SELECT modelid2 FROM creature_template WHERE entry IN (
        SELECT DISTINCT c.id FROM creature c WHERE c.map IN (860,870)
    ) AND modelid2 > 0
    UNION SELECT modelid3 FROM creature_template WHERE entry IN (
        SELECT DISTINCT c.id FROM creature c WHERE c.map IN (860,870)
    ) AND modelid3 > 0
    UNION SELECT modelid4 FROM creature_template WHERE entry IN (
        SELECT DISTINCT c.id FROM creature c WHERE c.map IN (860,870)
    ) AND modelid4 > 0
) m
LEFT JOIN creature_model_info cmi ON cmi.modelid = m.modelid
WHERE cmi.modelid IS NULL AND m.modelid > 0
ORDER BY m.modelid;
'@

$models = @($modelMissing | Where-Object { $_ -match '^\d+$' })
Write-Output "Missing model info: $($models.Count)"
$models -join ',' | Out-File (Join-Path $PSScriptRoot 'output\missing_creature_model_ids.txt') -Encoding utf8 -NoNewline
