-- Fix Creature Missing Faction errors
-- These creatures have invalid faction_H values (0) or invalid faction_A/faction_H values (22712)
-- 
-- Verified on Wowhead: All creatures show "React: A H" (hostile to both Alliance and Horde)
-- This means they should use faction 14 (Monster - hostile to both factions)
-- Entry 42940 is an invisible trigger NPC (Extinguishing Hope) - excluded here.
-- See 2025_11_27_world_01.sql for the correct 42940 setup.

-- All creatures: Verified on Wowhead as "React: A H" (hostile to both)
-- Setting all to faction 14 (Monster - hostile to both Alliance and Horde)
UPDATE `creature_template` SET `faction_A` = 14, `faction_H` = 14 WHERE `entry` IN (
69154, 71864, 71908, 71919, 72033, 72045, 72048, 72049, 72193, 72245, 72970,
73160, 73161, 73163, 73166, 73173, 73279, 73281, 73282, 73703, 73704
);
