SELECT COUNT(*) AS world_cols FROM information_schema.columns WHERE table_schema='world' AND table_name='smart_scripts';
SELECT COUNT(*) AS loa_cols FROM information_schema.columns WHERE table_schema='loa' AND table_name='smart_scripts';

SELECT l.column_name
FROM information_schema.columns l
WHERE l.table_schema = 'loa' AND l.table_name = 'smart_scripts'
  AND l.column_name NOT IN (
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'world' AND table_name = 'smart_scripts'
  )
ORDER BY l.column_name;

SELECT w.column_name
FROM information_schema.columns w
WHERE w.table_schema = 'world' AND w.table_name = 'smart_scripts'
  AND w.column_name NOT IN (
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'loa' AND table_name = 'smart_scripts'
  )
ORDER BY w.column_name;
