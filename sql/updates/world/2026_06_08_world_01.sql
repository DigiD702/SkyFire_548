-- Disable unfinished Pandaria instances (#1213)
DELETE FROM `disables` WHERE `sourceType` = 2 AND `entry` IN (1008, 1009, 1098, 1011);
INSERT INTO `disables` (`sourceType`, `entry`, `flags`, `params_0`, `params_1`, `comment`) VALUES
(2, 1008, 63, '', '', 'Disabled Raid: Mogu''shan Vaults [ALL DIFFICULTIES] - WIP'),
(2, 1009, 63, '', '', 'Disabled Raid: Heart of Fear [ALL DIFFICULTIES] - WIP'),
(2, 1098, 63, '', '', 'Disabled Raid: Throne of Thunder [ALL DIFFICULTIES] - WIP'),
(2, 1011, 3, '', '', 'Disabled Dungeon: Siege of Niuzao Temple [ALL DIFFICULTIES] - WIP');

-- Jade Serpent Temple: drop players at the instance entrance instead of in the sky
UPDATE `game_tele` SET `position_x` = 964.450989, `position_y` = -2454.360107, `position_z` = 180.233551, `orientation` = 1.0 WHERE `id` = 1003;

-- Siege of Niuzao Temple: drop players at the hollow-tree entrance
UPDATE `game_tele` SET `position_x` = 1426.476929, `position_y` = 5083.146973, `position_z` = 131.158401, `orientation` = 0.698132 WHERE `id` = 1024;

-- Gate of the Setting Sun: align teleport with instance entrance
UPDATE `game_tele` SET `position_x` = 683.242, `position_y` = 2079.95, `position_z` = 371.711, `orientation` = 0.0201836 WHERE `id` = 1017;
