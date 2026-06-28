-- SmartAI cleanup for missing DBC spell references
DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` = 62386
  AND `id` = 1
  AND `event_type` = 8
  AND `event_param1` = 131053;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` = 70034
  AND `action_type` = 11
  AND `action_param1` = 215377;
