-- Fix Northshire Vineyards Fire Trigger (42940) for Extinguishing Hope
-- Reverts incorrect faction change from 2025_11_25_world_13.sql and wires C++ script
-- Original SFDB: faction 35, flags_extra 128 (CREATURE_FLAG_EXTRA_TRIGGER)

UPDATE `creature_template`
SET `faction_A` = 35,
    `faction_H` = 35,
    `flags_extra` = 128,
    `unit_flags` = 33555200,
    `AIName` = '',
    `ScriptName` = 'npc_northshire_vineyard_fire'
WHERE `entry` = 42940;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 42940 AND `source_type` = 0;
