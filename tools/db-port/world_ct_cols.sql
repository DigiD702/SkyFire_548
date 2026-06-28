SELECT GROUP_CONCAT(column_name ORDER BY ordinal_position SEPARATOR ', ')
FROM information_schema.columns
WHERE table_schema = 'world' AND table_name = 'creature_template';
