SELECT 'creature' AS tbl, COUNT(1) AS new_rows
FROM world_staging.creature s
LEFT JOIN world.creature w ON w.guid = s.guid
WHERE w.guid IS NULL
UNION ALL
SELECT 'creature_template', COUNT(1)
FROM world_staging.creature_template s
LEFT JOIN world.creature_template w ON w.entry = s.entry
WHERE w.entry IS NULL
UNION ALL
SELECT 'creature_model_info', COUNT(1)
FROM world_staging.creature_model_info s
LEFT JOIN world.creature_model_info w ON w.modelid = s.modelid
WHERE w.modelid IS NULL
UNION ALL
SELECT 'smart_scripts', COUNT(1)
FROM world_staging.smart_scripts s
LEFT JOIN world.smart_scripts w
  ON w.entryorguid = s.entryorguid AND w.source_type = s.source_type AND w.id = s.id AND w.link = s.link
WHERE w.entryorguid IS NULL
UNION ALL
SELECT 'spell_script_names', COUNT(1)
FROM world_staging.spell_script_names s
LEFT JOIN world.spell_script_names w ON w.spell_id = s.spell_id AND w.ScriptName = s.ScriptName
WHERE w.spell_id IS NULL
UNION ALL
SELECT 'waypoints', COUNT(1)
FROM world_staging.waypoints s
LEFT JOIN world.waypoints w ON w.entry = s.entry AND w.pointid = s.pointid
WHERE w.entry IS NULL
UNION ALL
SELECT 'scene_template', COUNT(1)
FROM world_staging.scene_template s
LEFT JOIN world.scene_template w ON w.SceneId = s.SceneId
WHERE w.SceneId IS NULL
UNION ALL
SELECT 'hotfix_data', COUNT(1)
FROM world_staging.hotfix_data s
LEFT JOIN world.hotfix_data w ON w.Id = s.Id
WHERE w.Id IS NULL;
