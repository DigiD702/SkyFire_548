SELECT l.column_name
FROM information_schema.columns l
WHERE l.table_schema = 'loa' AND l.table_name = 'gameobject_template'
  AND l.column_name NOT IN (
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'world' AND table_name = 'gameobject_template'
  )
ORDER BY l.column_name;

SELECT w.column_name
FROM information_schema.columns w
WHERE w.table_schema = 'world' AND w.table_name = 'gameobject_template'
  AND w.column_name NOT IN (
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'loa' AND table_name = 'gameobject_template'
  )
ORDER BY w.column_name;
