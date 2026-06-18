-- Fear No Evil (28810): fix injured Stormwind infantry spellclick reliability
-- 50047 had GOSSIP set with no gossip menu, which can steal right-click from spellclick.
UPDATE `creature_template`
SET `npcflag` = 16777216
WHERE `entry` = 50047 AND (`npcflag` & 16777216) = 16777216;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 50047 AND `source_type` = 0 AND `id` IN (4, 5, 6);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(50047, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 80, 5004700, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Injured Stormwind Infantry - On Spellhit - Start timed event'),
(50047, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 18, 33554432, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Injured Stormwind Infantry - On Spellhit - Set unit_flag not selectable'),
(50047, 0, 6, 0, 58, 0, 100, 0, 9, 50047, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Injured Stormwind Infantry - On WP end - Despawn');
