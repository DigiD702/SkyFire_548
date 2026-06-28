-- LOA instance port: creature_model_info for dungeon/raid maps.
-- Status: local-only (not pushed upstream)

INSERT INTO `creature_model_info` (
    `modelid`, `bounding_radius`, `combat_reach`, `gender`, `modelid_other_gender`
)
SELECT
    l.`modelid`, l.`bounding_radius`, l.`combat_reach`, l.`gender`, l.`modelid_other_gender`
FROM `loa`.`creature_model_info` l
LEFT JOIN `creature_model_info` w ON w.`modelid` = l.`modelid`
WHERE w.`modelid` IS NULL
  AND l.`modelid` IN (
      SELECT DISTINCT m.`modelid`
      FROM (
          SELECT l2.`modelid1` AS `modelid`
          FROM `loa`.`creature_template` l2
          WHERE l2.`entry` IN (
              SELECT DISTINCT c.`id` FROM `creature` c
              WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007)
          )
          UNION
          SELECT l2.`modelid2` FROM `loa`.`creature_template` l2
          WHERE l2.`entry` IN (
              SELECT DISTINCT c.`id` FROM `creature` c
              WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007)
          ) AND l2.`modelid2` > 0
          UNION
          SELECT l2.`modelid3` FROM `loa`.`creature_template` l2
          WHERE l2.`entry` IN (
              SELECT DISTINCT c.`id` FROM `creature` c
              WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007)
          ) AND l2.`modelid3` > 0
          UNION
          SELECT l2.`modelid4` FROM `loa`.`creature_template` l2
          WHERE l2.`entry` IN (
              SELECT DISTINCT c.`id` FROM `creature` c
              WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007)
          ) AND l2.`modelid4` > 0
          UNION
          SELECT ct.`modelid1` FROM `creature` c
          JOIN `creature_template` ct ON ct.`entry` = c.`id`
          WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007) AND ct.`modelid1` > 0
          UNION
          SELECT ct.`modelid2` FROM `creature` c
          JOIN `creature_template` ct ON ct.`entry` = c.`id`
          WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007) AND ct.`modelid2` > 0
          UNION
          SELECT ct.`modelid3` FROM `creature` c
          JOIN `creature_template` ct ON ct.`entry` = c.`id`
          WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007) AND ct.`modelid3` > 0
          UNION
          SELECT ct.`modelid4` FROM `creature` c
          JOIN `creature_template` ct ON ct.`entry` = c.`id`
          WHERE c.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007) AND ct.`modelid4` > 0
      ) m
      WHERE m.`modelid` > 0
  );
