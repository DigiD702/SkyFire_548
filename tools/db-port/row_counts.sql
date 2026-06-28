-- Row count matrix for priority tables across world and loa.
SELECT 'ROW_COUNTS' AS section, 'table' AS col1, 'world' AS col2, 'loa' AS col3, 'delta_loa_minus_world' AS col4;

SELECT t.table_name,
       IFNULL(w.cnt, 0) AS world_count,
       IFNULL(l.cnt, 0) AS loa_count,
       IFNULL(l.cnt, 0) - IFNULL(w.cnt, 0) AS delta
FROM (
    SELECT 'creature_template' AS table_name UNION ALL
    SELECT 'creature' UNION ALL
    SELECT 'creature_addon' UNION ALL
    SELECT 'creature_template_addon' UNION ALL
    SELECT 'gameobject_template' UNION ALL
    SELECT 'gameobject' UNION ALL
    SELECT 'quest_template' UNION ALL
    SELECT 'quest_objective' UNION ALL
    SELECT 'quest_objective_visual_effect' UNION ALL
    SELECT 'smart_scripts' UNION ALL
    SELECT 'waypoints' UNION ALL
    SELECT 'waypoint_data' UNION ALL
    SELECT 'conditions' UNION ALL
    SELECT 'creature_loot_template' UNION ALL
    SELECT 'gameobject_loot_template' UNION ALL
    SELECT 'reference_loot_template' UNION ALL
    SELECT 'gossip_menu' UNION ALL
    SELECT 'gossip_menu_option' UNION ALL
    SELECT 'npc_text' UNION ALL
    SELECT 'npc_vendor' UNION ALL
    SELECT 'npc_trainer' UNION ALL
    SELECT 'spell_script_names' UNION ALL
    SELECT 'spell_scripts' UNION ALL
    SELECT 'event_scripts' UNION ALL
    SELECT 'waypoint_scripts' UNION ALL
    SELECT 'instance_template' UNION ALL
    SELECT 'instance_encounters' UNION ALL
    SELECT 'creature_text' UNION ALL
    SELECT 'creature_queststarter' UNION ALL
    SELECT 'creature_questender' UNION ALL
    SELECT 'phase_area' UNION ALL
    SELECT 'terrain_phase_info' UNION ALL
    SELECT 'terrain_swap_defaults' UNION ALL
    SELECT 'terrain_worldmap' UNION ALL
    SELECT 'scene_template' UNION ALL
    SELECT 'spell_proc' UNION ALL
    SELECT 'hotfix_data' UNION ALL
    SELECT 'areatrigger_scripts' UNION ALL
    SELECT 'areatrigger_teleport' UNION ALL
    SELECT 'areatrigger_tavern' UNION ALL
    SELECT 'game_graveyard_zone' UNION ALL
    SELECT 'creature_formations' UNION ALL
    SELECT 'linked_respawn'
) t
LEFT JOIN (
    SELECT table_name, table_rows AS cnt
    FROM information_schema.tables
    WHERE table_schema = 'world'
) w ON w.table_name = t.table_name
LEFT JOIN (
    SELECT table_name, table_rows AS cnt
    FROM information_schema.tables
    WHERE table_schema = 'loa'
) l ON l.table_name = t.table_name
ORDER BY ABS(IFNULL(l.cnt, 0) - IFNULL(w.cnt, 0)) DESC, t.table_name;
