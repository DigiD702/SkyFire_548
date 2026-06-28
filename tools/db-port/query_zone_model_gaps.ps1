. (Join-Path $PSScriptRoot 'config.ps1')

$modelMissing = Invoke-DbPortQuery -Database 'world_staging' -Query @'
SELECT DISTINCT m.modelid
FROM (
    SELECT l.modelid1 AS modelid
    FROM loa.creature_template l
    WHERE l.entry IN (
        SELECT DISTINCT c.id
        FROM creature c
        LEFT JOIN creature_template ct ON ct.entry = c.id
        WHERE c.map IN (860, 870) AND ct.entry IS NULL
    )
    UNION
    SELECT l.modelid2 FROM loa.creature_template l
    WHERE l.entry IN (
        SELECT DISTINCT c.id FROM creature c
        LEFT JOIN creature_template ct ON ct.entry = c.id
        WHERE c.map IN (860, 870) AND ct.entry IS NULL
    ) AND l.modelid2 > 0
    UNION
    SELECT l.modelid3 FROM loa.creature_template l
    WHERE l.entry IN (
        SELECT DISTINCT c.id FROM creature c
        LEFT JOIN creature_template ct ON ct.entry = c.id
        WHERE c.map IN (860, 870) AND ct.entry IS NULL
    ) AND l.modelid3 > 0
    UNION
    SELECT l.modelid4 FROM loa.creature_template l
    WHERE l.entry IN (
        SELECT DISTINCT c.id FROM creature c
        LEFT JOIN creature_template ct ON ct.entry = c.id
        WHERE c.map IN (860, 870) AND ct.entry IS NULL
    ) AND l.modelid4 > 0
) m
LEFT JOIN creature_model_info cmi ON cmi.modelid = m.modelid
WHERE cmi.modelid IS NULL AND m.modelid > 0
ORDER BY m.modelid;
'@

$models = @($modelMissing | Where-Object { $_ -match '^\d+$' })
Write-Output "Missing model info for zone templates: $($models.Count)"
$models -join ','
