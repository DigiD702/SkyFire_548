-- LOA port: remaining creature_model_info gaps from staging dberrors.
-- Models for entries 73672, 73677, 80651, 80674. Status: local-only (not pushed upstream)

INSERT INTO `creature_model_info` (
    `modelid`, `bounding_radius`, `combat_reach`, `gender`, `modelid_other_gender`
)
SELECT
    l.`modelid`, l.`bounding_radius`, l.`combat_reach`, l.`gender`, l.`modelid_other_gender`
FROM `loa`.`creature_model_info` l
LEFT JOIN `creature_model_info` w ON w.`modelid` = l.`modelid`
WHERE w.`modelid` IS NULL
  AND l.`modelid` IN (51479, 51481, 51482, 51483, 55896, 55907);
