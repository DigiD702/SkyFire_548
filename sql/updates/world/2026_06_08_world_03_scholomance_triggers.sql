-- MoP Scholomance trigger visibility and pre-pull mechanic fixes
-- Mirrors Extinguishing Hope fire trigger (42940): flags_extra 128 + unit_flags 33555200

-- Invisible script targets / bunnies (map 1007)
UPDATE `creature_template` SET
    `modelid1` = 11686, `modelid2` = 0, `modelid3` = 0, `modelid4` = 0,
    `faction_A` = 35, `faction_H` = 35,
    `unit_flags` = 33555200, `flags_extra` = 128,
    `type_flags` = 16778240
WHERE `entry` IN (58917, 59167, 59375, 59394, 45979, 54020, 30298, 59481, 59316, 59304);

-- Chillheart mechanic triggers: keep invisible, disable until boss script spawns them
UPDATE `creature_template` SET
    `modelid1` = 11686, `modelid2` = 0, `modelid3` = 0, `modelid4` = 0,
    `faction_A` = 35, `faction_H` = 35,
    `unit_flags` = 33555200, `flags_extra` = 128,
    `type_flags` = 16778240,
    `spell1` = 0, `spell2` = 0, `spell3` = 0, `spell4` = 0,
    `spell5` = 0, `spell6` = 0, `spell7` = 0, `spell8` = 0
WHERE `entry` IN (59929, 62731);

-- Ice Steps / Ice Wall must not be active before Instructor Chillheart pull
DELETE FROM `creature` WHERE `map` = 1007 AND `id` IN (59929, 62731);

-- Force invisible model on existing Scholomance trigger spawns
UPDATE `creature` SET `modelid` = 11686
WHERE `map` = 1007 AND `id` IN (58917, 59167, 59375, 59394, 45979, 54020, 30298, 59481, 59316);
