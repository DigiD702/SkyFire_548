-- Northshire semi-stealth: wire existing Elwynn Forest spy/assassin scripts.
UPDATE `creature_template` SET `ScriptName` = 'npc_blackrock_spy' WHERE `entry` = 49874;
UPDATE `creature_template` SET `ScriptName` = 'npc_goblin_assassin' WHERE `entry` = 50039;
