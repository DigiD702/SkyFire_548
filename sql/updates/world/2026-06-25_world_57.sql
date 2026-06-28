-- SmartAI cleanup for map 1135
DELETE s
FROM `smart_scripts` s
INNER JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (1135)
) z ON z.`entry` = s.`entryorguid`
WHERE s.`source_type` = 0
  AND (
      s.`action_type` >= 116
      OR s.`action_type` = 114
      OR s.`event_type` >= 75
  );
