SELECT 'world_creature_cols' AS section, GROUP_CONCAT(column_name ORDER BY ordinal_position) AS cols
FROM information_schema.columns
WHERE table_schema='world' AND table_name='creature';

SELECT 'loa_creature_cols' AS section, GROUP_CONCAT(column_name ORDER BY ordinal_position) AS cols
FROM information_schema.columns
WHERE table_schema='loa' AND table_name='creature';
