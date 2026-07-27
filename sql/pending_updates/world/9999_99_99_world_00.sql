-- Sync difficulty template unit_class and npcflag with the normal entry.
-- Clear difficulty-only SmartScript event flags on Wailing Caverns combat AI.

UPDATE `smart_scripts`
SET `event_flags` = `event_flags` & ~0x1E
WHERE `source_type` = 0
  AND `entryorguid` IN (5055, 5761, 3636, 5053, 5756, 5048, 5755, 3674, 5775)
  AND (`event_flags` & 0x1E) <> 0;

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 0
WHERE `entry` IN (
  22730, 33828, 33832, 38479
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 1
WHERE `entry` IN (
  20165, 22644, 34254, 38157
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 1048577
WHERE `entry` IN (
  22647, 32092
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 128
WHERE `entry` IN (
  37427, 37486
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 129
WHERE `entry` IN (
  30792, 30796, 30797, 30801
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 16777216
WHERE `entry` IN (
  31749, 35410, 35415, 35419, 35421, 35429, 48913, 51101
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 2
WHERE `entry` IN (
  21533, 21551, 21560, 21561, 21562, 21582, 21590, 21624, 31451, 31928, 31930, 31935, 31937, 31943, 31953, 31954, 31955, 31958, 31961, 31962,
  31973, 31980, 32003, 32044, 32093, 32109, 32137, 32138, 35560, 36087, 36088, 37240, 37281, 37313, 37336, 37345, 37367, 37370, 37372, 37374,
  37379, 37398, 37446, 37479, 37480, 37481, 37482, 37484, 38486, 38495, 38496, 38552, 38590, 39699, 39701, 39706, 48940, 48943, 48944, 49624,
  49648, 57481
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 3
WHERE `entry` IN (
  22567, 22575, 22577, 22735, 31366, 32032, 37401, 37607
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 3200
WHERE `entry` IN (
  22652, 22660
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 3714
WHERE `entry` IN (
  22648
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 3715
WHERE `entry` IN (
  22658
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 4224
WHERE `entry` IN (
  22682, 32112, 37315, 37318, 37320, 37349
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 4225
WHERE `entry` IN (
  30799
);

UPDATE `creature_template`
SET `unit_class` = 1, `npcflag` = 640
WHERE `entry` IN (
  22646, 22651, 22654, 22655
);

UPDATE `creature_template`
SET `unit_class` = 2, `npcflag` = 0
WHERE `entry` IN (
  22581, 22582, 22584, 22585, 22586, 22734, 32055, 33729, 33737, 33827, 35743, 37243, 37264, 37308, 37331, 37337, 37339, 37366, 37378, 37386,
  37389, 37404, 37431, 37445, 37456, 37470, 37477, 37478, 37564, 37605, 37615, 37617, 37619, 37621, 37654, 39983, 39991, 40018, 43876, 43879,
  48677, 48744, 48753, 48776, 48784, 48814, 48951, 49043, 49090, 49091, 49262, 49292, 49295, 49300, 49308, 49310, 49664, 49665, 49708, 49710,
  49711, 50277, 50285, 54162, 54525, 57292, 57294, 57409, 57462, 57463
);

UPDATE `creature_template`
SET `unit_class` = 2, `npcflag` = 1
WHERE `entry` IN (
  22541, 22938
);

UPDATE `creature_template`
SET `unit_class` = 2, `npcflag` = 2
WHERE `entry` IN (
  21537, 21558, 21581, 21601, 21626, 31457, 31469, 32060, 37363, 37371, 37448, 39680, 48936
);

UPDATE `creature_template`
SET `unit_class` = 2, `npcflag` = 3
WHERE `entry` IN (
  22527, 49072, 54679, 54850
);

UPDATE `creature_template`
SET `unit_class` = 2, `npcflag` = 32768
WHERE `entry` IN (
  37236, 37323
);

UPDATE `creature_template`
SET `unit_class` = 4, `npcflag` = 0
WHERE `entry` IN (
  33831, 35431, 35433, 38078, 38094, 48791, 48815, 49047, 49050, 49053, 49056, 53856, 54016, 54527, 57293
);

UPDATE `creature_template`
SET `unit_class` = 4, `npcflag` = 16777216
WHERE `entry` IN (
  35413, 35417, 35436, 36357, 36358, 48803, 48804
);

UPDATE `creature_template`
SET `unit_class` = 4, `npcflag` = 2
WHERE `entry` IN (
  48941
);

UPDATE `creature_template`
SET `unit_class` = 8, `npcflag` = 0
WHERE `entry` IN (
  37603, 38137, 48595, 48597, 48653, 48669, 48695, 48745, 48746, 48748, 48750, 48778, 48792, 48812, 48973, 49130, 49164, 49653, 49662, 50201,
  53777, 54965, 57296
);

UPDATE `creature_template`
SET `unit_class` = 8, `npcflag` = 1
WHERE `entry` IN (
  21602
);

