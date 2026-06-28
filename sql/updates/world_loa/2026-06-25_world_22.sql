-- Fix C++ script name mismatches and missing DB bindings (staging dberrors unbound scripts).
-- Status: local-only (not pushed upstream)

UPDATE `creature_template`
SET `ScriptName` = 'npc_Spirit_of_Master_Shang_Xi'
WHERE `entry` = 56013
  AND `ScriptName` <> 'npc_Spirit_of_Master_Shang_Xi';

UPDATE `creature_template`
SET `ScriptName` = 'boss_pit_lord_argaloth'
WHERE `entry` = 47120
  AND `ScriptName` IN ('', 'boss_argaloth');

UPDATE `creature_template`
SET `ScriptName` = 'npc_eyestalk'
WHERE `entry` = 52369
  AND `ScriptName` IN ('', 'npc_occuthar_eyestalk');

UPDATE `gameobject_template`
SET `ScriptName` = 'go_blackhoof_cage'
WHERE `entry` = 186287
  AND (`ScriptName` IS NULL OR `ScriptName` = '');

INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`)
SELECT l.`criteria_id`, l.`type`, l.`value1`, l.`value2`, l.`ScriptName`
FROM `loa`.`achievement_criteria_data` l
LEFT JOIN `achievement_criteria_data` w
  ON w.`criteria_id` = l.`criteria_id` AND w.`type` = l.`type`
WHERE w.`criteria_id` IS NULL
  AND l.`ScriptName` = 'achievement_killed_exp_or_honor_target';
