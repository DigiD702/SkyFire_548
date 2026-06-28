-- Schema comparison across SkyFire (world), LOA, Trinity world, and Trinity hotfixes.
-- Run: mysql ... < schema_diff.sql > output/schema_summary.tsv

SELECT 'TABLE_COUNTS' AS section, '' AS detail1, '' AS detail2, '' AS detail3;
SELECT 'world' AS db, COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'world' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'loa', COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'loa' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'trinitycore', COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'trinitycore' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 'trinitycore_hotfixes', COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'trinitycore_hotfixes' AND table_type = 'BASE TABLE';

SELECT 'TABLES_ONLY_IN_LOA' AS section, '' AS detail1, '' AS detail2, '' AS detail3;
SELECT l.table_name
FROM information_schema.tables l
LEFT JOIN information_schema.tables w
  ON w.table_schema = 'world' AND w.table_name = l.table_name
WHERE l.table_schema = 'loa'
  AND l.table_type = 'BASE TABLE'
  AND w.table_name IS NULL
ORDER BY l.table_name;

SELECT 'TABLES_ONLY_IN_WORLD' AS section, '' AS detail1, '' AS detail2, '' AS detail3;
SELECT w.table_name
FROM information_schema.tables w
LEFT JOIN information_schema.tables l
  ON l.table_schema = 'loa' AND l.table_name = w.table_name
WHERE w.table_schema = 'world'
  AND w.table_type = 'BASE TABLE'
  AND l.table_name IS NULL
ORDER BY w.table_name;

SELECT 'SHARED_WORLD_LOA_COLUMN_DIFFS' AS section, '' AS detail1, '' AS detail2, '' AS detail3;
SELECT
    w.table_name,
    w.column_name,
    w.column_type AS world_type,
    l.column_type AS loa_type
FROM information_schema.columns w
JOIN information_schema.columns l
  ON l.table_schema = 'loa'
 AND l.table_name = w.table_name
 AND l.column_name = w.column_name
WHERE w.table_schema = 'world'
  AND w.table_name IN (
    'creature_template', 'smart_scripts', 'quest_template', 'quest_objective',
    'creature_loot_template', 'gameobject_template', 'item_template', 'conditions'
  )
  AND (
    w.column_type <> l.column_type
    OR w.is_nullable <> l.is_nullable
    OR IFNULL(w.column_default, '') <> IFNULL(l.column_default, '')
  )
ORDER BY w.table_name, w.ordinal_position;

SELECT 'COLUMNS_ONLY_IN_LOA' AS section, '' AS detail1, '' AS detail2, '' AS detail3;
SELECT l.table_name, l.column_name, l.column_type
FROM information_schema.columns l
LEFT JOIN information_schema.columns w
  ON w.table_schema = 'world'
 AND w.table_name = l.table_name
 AND w.column_name = l.column_name
WHERE l.table_schema = 'loa'
  AND l.table_name IN (
    'creature_template', 'smart_scripts', 'quest_template', 'quest_objective',
    'creature_loot_template', 'gameobject_template', 'item_template', 'conditions'
  )
  AND w.column_name IS NULL
ORDER BY l.table_name, l.ordinal_position;

SELECT 'COLUMNS_ONLY_IN_WORLD' AS section, '' AS detail1, '' AS detail2, '' AS detail3;
SELECT w.table_name, w.column_name, w.column_type
FROM information_schema.columns w
LEFT JOIN information_schema.columns l
  ON l.table_schema = 'loa'
 AND l.table_name = w.table_name
 AND l.column_name = w.column_name
WHERE w.table_schema = 'world'
  AND w.table_name IN (
    'creature_template', 'smart_scripts', 'quest_template', 'quest_objective',
    'creature_loot_template', 'gameobject_template', 'item_template', 'conditions'
  )
  AND l.column_name IS NULL
ORDER BY w.table_name, w.ordinal_position;
