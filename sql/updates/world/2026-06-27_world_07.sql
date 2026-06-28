-- DBErrors P1-P3: gameobject templates, spawntimesecs, creature_text sound, equip templates, instance_bind flag

-- P1: missing gameobject_template (ported from LOA snapshot; portable, no loa DB required)
INSERT IGNORE INTO `gameobject_template` (
    `entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
    `faction`, `flags`, `size`, `questItem1`, `questItem2`, `questItem3`, `questItem4`, `questItem5`, `questItem6`,
    `data0`, `data1`, `data2`, `data3`, `data4`, `data5`, `data6`, `data7`, `data8`, `data9`,
    `data10`, `data11`, `data12`, `data13`, `data14`, `data15`, `data16`, `data17`, `data18`, `data19`,
    `data20`, `data21`, `data22`, `data23`, `data24`, `data25`, `data26`, `data27`, `data28`, `data29`,
    `data30`, `data31`, `unkInt32`, `AIName`, `ScriptName`, `WDBVerified`
) VALUES
(213074,3,10316,'Box of Fancy Stuff','','','',0,0,2.5,0,0,0,0,0,0,1634,43571,0,1,0,0,0,0,0,0,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'','',1),
(215413,3,11314,'Ghost Iron Deposit','','','',0,0,0.8,0,0,0,0,0,0,38,40258,0,1,1,1,0,215404,0,0,0,0,0,0,0,0,0,0,85,1,0,0,0,550,600,0,0,0,0,0,0,0,0,'','',1);

-- P1: despawnable GO spawns need non-zero respawn (LOA port used 0)
UPDATE `gameobject`
SET `spawntimesecs` = 120
WHERE `id` IN (209354, 215413) AND `spawntimesecs` = 0;

-- P2: Pathaleon the Calculator — sound 11198 not in 5.4.8 DBC
UPDATE `creature_text`
SET `sound` = 0
WHERE `entry` = 19220 AND `groupid` = 1 AND `id` = 1;

-- P3: Luo Luo (68869) outdoor spawn — clear instance bind flag
UPDATE `creature_template`
SET `flags_extra` = `flags_extra` & ~1
WHERE `entry` = 68869;

-- Creature: missing equipment templates for MoP port spawns (LOA snapshot)
INSERT IGNORE INTO `creature_equip_template` (`entry`, `id`, `itemEntry1`, `itemEntry2`, `itemEntry3`) VALUES
(64004, 1, 84660, 0, 0),
(64191, 1, 768, 0, 0),
(64272, 1, 86199, 0, 0),
(68609, 1, 2177, 12869, 0),
(69768, 1, 94118, 0, 0),
(69769, 1, 94106, 0, 0),
(69841, 1, 94106, 0, 0),
(70324, 1, 82347, 0, 0);
