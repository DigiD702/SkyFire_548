-- SmartAI cleanup for maps 860 and 870
DELETE s
FROM `smart_scripts` s
INNER JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (860, 870)
) z ON z.`entry` = s.`entryorguid`
WHERE s.`source_type` = 0
  AND (
      s.`action_type` >= 116
      OR s.`action_type` = 114
      OR s.`event_type` >= 75
  );

DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` = 62386
  AND `event_type` = 1
  AND `action_type` = 49
  AND `action_param1` = 131053;
