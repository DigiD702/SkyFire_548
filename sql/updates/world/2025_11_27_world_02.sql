-- Fix Blackrock Invader (42937) loot for Blackrock Invasion (26389)
-- MoP Classic: 100% Blackrock Orc Weapon (58361) while the quest is active.
-- Negative ChanceOrQuestChance marks this as quest-only loot (see 2025_11_26_world_04.sql).

DELETE FROM `creature_loot_template` WHERE `entry` = 42937 AND `item` = 58361;

INSERT INTO `creature_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES
(42937, 58361, -100, 1, 0, 1, 1);

-- Legacy fallback used by some loot checks when objective data is unavailable
UPDATE `quest_template`
SET `RequiredSourceItemId1` = 58361,
    `RequiredSourceItemCount1` = 8
WHERE `Id` = 26389;

-- Wire existing C++ script (combat yells) from zone_elwynn_forest.cpp
UPDATE `creature_template`
SET `ScriptName` = 'npc_blackrock_invader'
WHERE `entry` = 42937;
