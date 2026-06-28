-- SmartAI cleanup for MoP dungeon and raid maps
DELETE s
FROM `smart_scripts` s
INNER JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007)
) z ON z.`entry` = s.`entryorguid`
WHERE s.`source_type` = 0
  AND (
      s.`action_type` >= 116
      OR s.`action_type` = 114
      OR s.`event_type` >= 75
  );
