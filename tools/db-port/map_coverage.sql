-- Spawn coverage by map tier for world vs loa.

SELECT 'CREATURE_MAP_COVERAGE' AS section;
SELECT
    CASE
        WHEN map IN (860, 870, 1064, 1050, 1004, 1135, 1098, 1191, 1209, 1228, 1298, 1330, 1358, 1374, 1409, 1448, 1458, 1464, 1488, 1514, 1570, 1579) THEN 'MoP'
        WHEN map >= 646 AND map <= 974 THEN 'Cata'
        WHEN map < 571 THEN 'Classic_TBC_Wrath'
        WHEN map = 571 THEN 'Wrath_Northrend'
        ELSE 'Other'
    END AS tier,
    COUNT(*) AS world_spawns
FROM world.creature
GROUP BY tier
ORDER BY world_spawns DESC;

SELECT 'CREATURE_MAP_DELTA_SAMPLE' AS section;
SELECT w.map, COUNT(*) AS world_only_spawn_guids
FROM world.creature w
LEFT JOIN loa.creature l
  ON l.guid = w.guid AND l.map = w.map AND l.id = w.id
WHERE l.guid IS NULL
GROUP BY w.map
ORDER BY world_only_spawn_guids DESC
LIMIT 30;

SELECT 'MOP_MAP_CREATURE_COUNTS' AS section;
SELECT map, COUNT(*) AS world_count
FROM world.creature
WHERE map IN (860, 870)
GROUP BY map
ORDER BY map;

SELECT 'MOP_MAP_CREATURE_LOA_COUNTS' AS section;
SELECT map, COUNT(*) AS loa_count
FROM loa.creature
WHERE map IN (860, 870)
GROUP BY map
ORDER BY map;

SELECT 'SMARTAI_GAP' AS section;
SELECT COUNT(*) AS smartai_creature_templates_without_scripts
FROM world.creature_template ct
LEFT JOIN (
    SELECT DISTINCT entryorguid AS entry
    FROM world.smart_scripts
    WHERE source_type = 0
) s ON s.entry = ct.entry
WHERE ct.AIName = 'SmartAI'
  AND s.entry IS NULL;
