-- Instructor Chillheart phylactery: inactive script prop, not a persistent world hazard
DELETE FROM `creature` WHERE `map` = 1007 AND `id` = 58662;

UPDATE `creature_template` SET
    `modelid1` = 11686, `modelid2` = 0, `modelid3` = 0, `modelid4` = 0,
    `faction_A` = 35, `faction_H` = 35,
    `unit_flags` = 33555200, `flags_extra` = 128,
    `type` = 10, `type_flags` = 16778240,
    `mindmg` = 0, `maxdmg` = 0, `dmg_multiplier` = 0,
    `spell1` = 0, `spell2` = 0, `spell3` = 0, `spell4` = 0,
    `spell5` = 0, `spell6` = 0, `spell7` = 0, `spell8` = 0
WHERE `entry` = 58662;
