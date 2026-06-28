-- LOA zone port: smart_scripts for creatures on map 1098.
-- LOA has target_param4; SkyFire does not — explicit column mapping.
-- Status: local-only (not pushed upstream)

INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_x`, `target_y`, `target_z`, `target_o`, `comment`
)
SELECT
    s.`entryorguid`, s.`source_type`, s.`id`, s.`link`, s.`event_type`, s.`event_phase_mask`, s.`event_chance`, s.`event_flags`,
    s.`event_param1`, s.`event_param2`, s.`event_param3`, s.`event_param4`, s.`event_param5`,
    s.`action_type`, s.`action_param1`, s.`action_param2`, s.`action_param3`, s.`action_param4`, s.`action_param5`, s.`action_param6`,
    s.`target_type`, s.`target_param1`, s.`target_param2`, s.`target_param3`,
    s.`target_x`, s.`target_y`, s.`target_z`, s.`target_o`, s.`comment`
FROM `loa`.`smart_scripts` s
JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (1098)
) c ON c.`entry` = s.`entryorguid`
LEFT JOIN `smart_scripts` w
  ON w.`entryorguid` = s.`entryorguid`
 AND w.`source_type` = s.`source_type`
 AND w.`id` = s.`id`
 AND w.`link` = s.`link`
WHERE s.`source_type` = 0
  AND w.`entryorguid` IS NULL;
