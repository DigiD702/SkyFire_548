-- SmartAI cleanup for maps 859 and 861
DELETE s
FROM `smart_scripts` s
INNER JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (859, 861)
) z ON z.`entry` = s.`entryorguid`
WHERE s.`source_type` = 0
  AND (
      s.`action_type` >= 116
      OR s.`action_type` = 114
      OR s.`event_type` >= 75
  );
