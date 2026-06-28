-- ScriptName fixes for Wandering Island HOR pets and achievements
UPDATE `creature_template`
SET `ScriptName` = 'npc_master_shang_xi_wood_of_staves'
WHERE `entry` = 55672
  AND `ScriptName` <> 'npc_master_shang_xi_wood_of_staves';

UPDATE `creature_template`
SET `ScriptName` = 'npc_master_shang_xi_worthy_questgiver'
WHERE `entry` = 55586
  AND `ScriptName` <> 'npc_master_shang_xi_worthy_questgiver';

UPDATE `creature_template`
SET `ScriptName` = 'npc_aysa_battle_for_the_skies'
WHERE `entry` = 55595
  AND `ScriptName` <> 'npc_aysa_battle_for_the_skies';

UPDATE `creature_template`
SET `ScriptName` = 'npc_firework_launcher'
WHERE `entry` = 64507
  AND `ScriptName` <> 'npc_firework_launcher';

UPDATE `creature_template`
SET `ScriptName` = 'npc_defiant_troll'
WHERE `entry` = 34830
  AND (`ScriptName` IS NULL OR `ScriptName` = '');

INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`)
VALUES (5605, 'at_shadow_throne')
ON DUPLICATE KEY UPDATE `ScriptName` = VALUES(`ScriptName`);

-- Halls of Reflection escape sequence script bindings
UPDATE `creature_template`
SET `ScriptName` = 'npc_jaina_or_sylvanas_escape_hor'
WHERE `entry` IN (36955, 37554)
  AND `ScriptName` <> 'npc_jaina_or_sylvanas_escape_hor';

UPDATE `creature_template`
SET `ScriptName` = 'npc_raging_ghoul'
WHERE `entry` = 36940
  AND `ScriptName` <> 'npc_raging_ghoul';

UPDATE `creature_template`
SET `ScriptName` = 'npc_lumbering_abomination'
WHERE `entry` = 37069
  AND `ScriptName` <> 'npc_lumbering_abomination';

-- Ulduar achievement script bindings
INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`)
VALUES
    (10568, 11, 0, 0, 'achievement_he_feeds_on_your_tears'),
    (10570, 11, 0, 0, 'achievement_he_feeds_on_your_tears')
ON DUPLICATE KEY UPDATE `ScriptName` = VALUES(`ScriptName`);

-- Pet script renames
UPDATE `creature_template` SET `ScriptName` = 'npc_pet_dk_ebon_gargoyle' WHERE `ScriptName` = 'npc_ebon_gargoyle';
UPDATE `creature_template` SET `ScriptName` = 'npc_pet_hunter_snake_trap' WHERE `ScriptName` = 'npc_snake_trap_serpents';
UPDATE `creature_template` SET `ScriptName` = 'npc_pet_pri_lightwell' WHERE `ScriptName` = 'npc_lightwell';
UPDATE `creature_template` SET `ScriptName` = 'npc_pet_shaman_earth_elemental' WHERE `ScriptName` = 'npc_earth_elemental';
