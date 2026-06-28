-- Missing template entries referenced by spawns in world but present in LOA.

SELECT 'MISSING_CREATURE_TEMPLATES' AS section;
SELECT DISTINCT c.id AS missing_entry, COUNT(*) AS spawn_count
FROM world.creature c
LEFT JOIN world.creature_template ct ON ct.entry = c.id
WHERE ct.entry IS NULL
GROUP BY c.id
ORDER BY spawn_count DESC, c.id
LIMIT 200;

SELECT 'MISSING_GAMEOBJECT_TEMPLATES' AS section;
SELECT DISTINCT g.id AS missing_entry, COUNT(*) AS spawn_count
FROM world.gameobject g
LEFT JOIN world.gameobject_template gt ON gt.entry = g.id
WHERE gt.entry IS NULL
GROUP BY g.id
ORDER BY spawn_count DESC, g.id
LIMIT 200;

SELECT 'MISSING_CREATURE_IN_LOA' AS section;
SELECT DISTINCT c.id AS missing_entry, COUNT(*) AS spawn_count
FROM world.creature c
LEFT JOIN world.creature_template ct ON ct.entry = c.id
LEFT JOIN loa.creature_template lct ON lct.entry = c.id
WHERE ct.entry IS NULL
GROUP BY c.id, lct.entry
HAVING lct.entry IS NOT NULL
ORDER BY spawn_count DESC, c.id
LIMIT 200;

SELECT 'MISSING_GAMEOBJECT_IN_LOA' AS section;
SELECT DISTINCT g.id AS missing_entry, COUNT(*) AS spawn_count
FROM world.gameobject g
LEFT JOIN world.gameobject_template gt ON gt.entry = g.id
LEFT JOIN loa.gameobject_template lgt ON lgt.entry = g.id
WHERE gt.entry IS NULL
GROUP BY g.id, lgt.entry
HAVING lgt.entry IS NOT NULL
ORDER BY spawn_count DESC, g.id
LIMIT 200;
