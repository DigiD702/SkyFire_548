-- LOA zone port: SmartAI waypoints for maps 859 and 861.
-- Status: local-only (not pushed upstream)

INSERT INTO `waypoints` (
    `entry`, `pointid`, `position_x`, `position_y`, `position_z`, `point_comment`
)
SELECT
    l.`entry`, l.`pointid`, l.`position_x`, l.`position_y`, l.`position_z`, l.`point_comment`
FROM `loa`.`waypoints` l
LEFT JOIN `waypoints` w ON w.`entry` = l.`entry` AND w.`pointid` = l.`pointid`
WHERE w.`entry` IS NULL
  AND l.`entry` IN (
      SELECT DISTINCT s.`action_param2`
      FROM `smart_scripts` s
      WHERE s.`source_type` = 0
        AND s.`action_type` = 53
        AND s.`action_param2` > 0
        AND s.`entryorguid` IN (
            SELECT DISTINCT `id`
            FROM `creature`
            WHERE `map` IN (859, 861)
        )
  );
