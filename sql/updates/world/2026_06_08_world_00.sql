-- Teldrassil starter quest fixes (#683)
-- Fel Moss Corruption, A Favor for Melithar, Demonic Thieves, class sigils,
-- Moonfire, Etched Sigil, A Woodsman's Training, Forbidden Sigil, Frost Nova

UPDATE `quest_template` SET `Flags` = 8388608 WHERE `Id` = 28714;
UPDATE `quest_template` SET `Flags` = 8650752, `OfferRewardText` = 'Ilthalaine sent you? He was wise to do so. I am indeed in need of help.' WHERE `Id` = 28734;
UPDATE `quest_template` SET `Flags` = 0 WHERE `Id` = 28715;
UPDATE `quest_template` SET `Flags` = 0 WHERE `Id` = 3120;
UPDATE `quest_template` SET `Flags` = 2097152, `Title` = 'Moonfire', `Objectives` = 'Reach level 3 to learn [Moonfire]. Use it on a training dummy in Aldrassil.', `Details` = 'Druids play an important role in our society, but all too often we are seen as passive dreamers in a world that is changing around us.$B$BThe truth is, though, we must actively practice and go out onto the world to develop our connection to nature. So go, get some more experience. You will begin to feel your connection deepen, learning new skills. Demonstrate the first you learn for me.' WHERE `Id` = 26948;
UPDATE `quest_template` SET `Flags` = 8650752, `PrevQuestId` = 28714, `NextQuestId` = 26947, `ExclusiveGroup` = 3120, `NextQuestIdChain` = 26947 WHERE `Id` = 3117;
UPDATE `quest_template` SET `OfferRewardText` = 'I will be your mentor and guide for now. It is my duty to teach you the arcane arts and how you might best fit in among our people.$B$BAs you learn and grow in power, you will learn an immense variety of spells that should allow you to deal with nearly any situation. But until then, return to me as often as you like and I will teach you what I can in the ways of our kind.', `RequestItemsText` = 'I''m glad that you''ve come, $n.' WHERE `Id` = 26841;
UPDATE `quest_template` SET `Title` = 'Frost Nova', `OfferRewardText` = 'I knew you would master this lesson quickly. You are a credit to the highborn and to all our kin. Remember, as you grow in power, return to me and will instruct you further.', `RequestItemsText` = 'This is just the first of many techniques you will learn. Master them all, $n, and you will have an impressive array of skills at your command.' WHERE `Id` = 26940;

DELETE FROM `quest_poi` WHERE `questId` = 26947;
DELETE FROM `quest_poi_points` WHERE `questId` = 26947;
INSERT INTO `quest_poi` (`questId`, `id`, `objIndex`, `mapid`, `WorldMapAreaId`, `FloorId`, `unk3`, `unk4`) VALUES
(26947, 0, -1, 1, 41, 0, 0, 1),
(26947, 1, 0, 1, 41, 0, 0, 1),
(26947, 2, 1, 1, 41, 0, 0, 1);
INSERT INTO `quest_poi_points` (`questId`, `id`, `idx`, `x`, `y`) VALUES
(26947, 0, 0, 10480, 825),
(26947, 1, 0, 10476, 720),
(26947, 1, 1, 10519, 732),
(26947, 1, 2, 10538, 745),
(26947, 1, 3, 10569, 775),
(26947, 1, 4, 10581, 812),
(26947, 1, 5, 10551, 862),
(26947, 1, 6, 10500, 892),
(26947, 1, 7, 10464, 893),
(26947, 1, 8, 10427, 868),
(26947, 1, 9, 10414, 812),
(26947, 1, 10, 10420, 775),
(26947, 1, 11, 10451, 738),
(26947, 2, 0, 10470, 707),
(26947, 2, 1, 10525, 714),
(26947, 2, 2, 10569, 738),
(26947, 2, 3, 10581, 782),
(26947, 2, 4, 10575, 812),
(26947, 2, 5, 10544, 868),
(26947, 2, 6, 10513, 880),
(26947, 2, 7, 10470, 887),
(26947, 2, 8, 10427, 880),
(26947, 2, 9, 10402, 850),
(26947, 2, 10, 10408, 794),
(26947, 2, 11, 10439, 732);

DELETE FROM `quest_poi` WHERE `questId` = 26841;
DELETE FROM `quest_poi_points` WHERE `questId` = 26841;
INSERT INTO `quest_poi` (`questId`, `id`, `objIndex`, `mapid`, `WorldMapAreaId`, `FloorId`, `unk3`, `unk4`) VALUES
(26841, 0, -1, 1, 41, 0, 0, 1);
INSERT INTO `quest_poi_points` (`questId`, `id`, `idx`, `x`, `y`) VALUES
(26841, 0, 0, 10456, 805);

DELETE FROM `quest_poi` WHERE `questId` = 26940;
DELETE FROM `quest_poi_points` WHERE `questId` = 26940;
INSERT INTO `quest_poi` (`questId`, `id`, `objIndex`, `mapid`, `WorldMapAreaId`, `FloorId`, `unk3`, `unk4`) VALUES
(26940, 0, -1, 1, 41, 0, 0, 1),
(26940, 1, 0, 1, 41, 0, 0, 1),
(26940, 2, 1, 1, 41, 0, 0, 1);
INSERT INTO `quest_poi_points` (`questId`, `id`, `idx`, `x`, `y`) VALUES
(26940, 0, 0, 10480, 825),
(26940, 1, 0, 10476, 720),
(26940, 1, 1, 10519, 732),
(26940, 1, 2, 10538, 745),
(26940, 1, 3, 10569, 775),
(26940, 1, 4, 10581, 812),
(26940, 1, 5, 10551, 862),
(26940, 1, 6, 10500, 892),
(26940, 1, 7, 10464, 893),
(26940, 1, 8, 10427, 868),
(26940, 1, 9, 10414, 812),
(26940, 1, 10, 10420, 775),
(26940, 1, 11, 10451, 738),
(26940, 2, 0, 10470, 707),
(26940, 2, 1, 10525, 714),
(26940, 2, 2, 10569, 738),
(26940, 2, 3, 10581, 782),
(26940, 2, 4, 10575, 812),
(26940, 2, 5, 10544, 868),
(26940, 2, 6, 10513, 880),
(26940, 2, 7, 10470, 887),
(26940, 2, 8, 10427, 880),
(26940, 2, 9, 10402, 850),
(26940, 2, 10, 10408, 794),
(26940, 2, 11, 10439, 732);

UPDATE `creature_queststarter` SET `id` = 43006 WHERE `quest` = 26940;
UPDATE `quest_objective` SET `objectId` = 122, `description` = 'Reach level 3 to learn Frost Nova' WHERE `questId` = 26940 AND `index` = 255;
UPDATE `quest_objective` SET `objectId` = 44175, `description` = 'Practice using Frost Nova' WHERE `questId` = 26940 AND `index` = 0;

UPDATE `creature` SET `spawndist` = 10, `MovementType` = 1 WHERE `id` IN (1988, 1989, 1984, 883, 721);
UPDATE `creature_classlevelstats` SET `OldContentBaseHP` = 55, `CurrentContentBaseHP` = 55 WHERE `level` = 2 AND `class` = 1;
UPDATE `creature_classlevelstats` SET `OldContentBaseHP` = 71, `CurrentContentBaseHP` = 71 WHERE `level` = 3 AND `class` = 1;
UPDATE `creature_classlevelstats` SET `OldContentBaseHP` = 86, `CurrentContentBaseHP` = 86 WHERE `level` = 4 AND `class` = 1;
UPDATE `creature_template` SET `mindmg` = 2, `maxdmg` = 3, `Health_mod` = 1 WHERE `entry` = 2031;
UPDATE `creature_template` SET `mindmg` = 2, `maxdmg` = 2, `Health_mod` = 1 WHERE `entry` = 1984;
UPDATE `creature_template` SET `mindmg` = 2, `maxdmg` = 3, `Health_mod` = 1 WHERE `entry` = 1988;
UPDATE `creature_template` SET `mindmg` = 2, `maxdmg` = 3, `Health_mod` = 1 WHERE `entry` = 1989;
UPDATE `creature_template` SET `KillCredit1` = 44175 WHERE `entry` = 44614;

UPDATE `gameobject_loot_template` SET `ChanceOrQuestChance` = -100 WHERE `entry` = 27260 AND `item` = 46700;
