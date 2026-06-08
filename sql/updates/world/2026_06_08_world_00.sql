-- Instructor Chillheart: Wrack Soul jump mechanic (#704)
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = -111631;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(-111631, 111637, 0, 'Wrack Soul - On Remove - Cast Wrack Soul AoE Dummy');

DELETE FROM `spell_scripts` WHERE `id` = 114658;
INSERT INTO `spell_scripts` (`id`, `effIndex`, `delay`, `command`, `datalong`, `datalong2`, `dataint`, `x`, `y`, `z`, `o`) VALUES
(114658, 0, 0, 15, 111631, 1, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_chillheart_wrack_soul';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(111637, 'spell_gen_chillheart_wrack_soul');
