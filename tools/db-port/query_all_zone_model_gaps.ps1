. (Join-Path $PSScriptRoot 'config.ps1')

$result = Invoke-DbPortQuery -Database 'world_staging' -Query @'
SELECT COUNT(DISTINCT m.modelid)
FROM (
    SELECT ct.modelid1 AS modelid
    FROM creature c
    JOIN creature_template ct ON ct.entry = c.id
    WHERE c.map IN (860, 870) AND ct.modelid1 > 0
    UNION
    SELECT ct.modelid2 FROM creature c
    JOIN creature_template ct ON ct.entry = c.id
    WHERE c.map IN (860, 870) AND ct.modelid2 > 0
    UNION
    SELECT ct.modelid3 FROM creature c
    JOIN creature_template ct ON ct.entry = c.id
    WHERE c.map IN (860, 870) AND ct.modelid3 > 0
    UNION
    SELECT ct.modelid4 FROM creature c
    JOIN creature_template ct ON ct.entry = c.id
    WHERE c.map IN (860, 870) AND ct.modelid4 > 0
) m
LEFT JOIN creature_model_info cmi ON cmi.modelid = m.modelid
WHERE cmi.modelid IS NULL;
'@

Write-Output "Missing model info for all zone spawns with templates: $result"
