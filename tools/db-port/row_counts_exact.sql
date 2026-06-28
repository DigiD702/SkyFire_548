-- Exact row counts (slower but accurate). Run sections individually if needed.

SELECT 'EXACT_ROW_COUNTS' AS section;
SELECT 'creature_template' AS table_name, (SELECT COUNT(*) FROM world.creature_template) AS world_count, (SELECT COUNT(*) FROM loa.creature_template) AS loa_count;
SELECT 'creature', (SELECT COUNT(*) FROM world.creature), (SELECT COUNT(*) FROM loa.creature);
SELECT 'gameobject_template', (SELECT COUNT(*) FROM world.gameobject_template), (SELECT COUNT(*) FROM loa.gameobject_template);
SELECT 'gameobject', (SELECT COUNT(*) FROM world.gameobject), (SELECT COUNT(*) FROM loa.gameobject);
SELECT 'quest_template', (SELECT COUNT(*) FROM world.quest_template), (SELECT COUNT(*) FROM loa.quest_template);
SELECT 'quest_objective', (SELECT COUNT(*) FROM world.quest_objective), (SELECT COUNT(*) FROM loa.quest_objective);
SELECT 'smart_scripts', (SELECT COUNT(*) FROM world.smart_scripts), (SELECT COUNT(*) FROM loa.smart_scripts);
SELECT 'conditions', (SELECT COUNT(*) FROM world.conditions), (SELECT COUNT(*) FROM loa.conditions);
SELECT 'creature_text', (SELECT COUNT(*) FROM world.creature_text), (SELECT COUNT(*) FROM loa.creature_text);
SELECT 'spell_script_names', (SELECT COUNT(*) FROM world.spell_script_names), (SELECT COUNT(*) FROM loa.spell_script_names);
SELECT 'scene_template', (SELECT COUNT(*) FROM world.scene_template), (SELECT COUNT(*) FROM loa.scene_template);
SELECT 'terrain_phase_info', (SELECT COUNT(*) FROM world.terrain_phase_info), (SELECT COUNT(*) FROM loa.terrain_phase_info);
SELECT 'spell_proc', (SELECT COUNT(*) FROM world.spell_proc), (SELECT COUNT(*) FROM loa.spell_proc);
SELECT 'hotfix_data', (SELECT COUNT(*) FROM world.hotfix_data), (SELECT COUNT(*) FROM loa.hotfix_data);
SELECT 'waypoints', (SELECT COUNT(*) FROM world.waypoints), (SELECT COUNT(*) FROM loa.waypoints);
