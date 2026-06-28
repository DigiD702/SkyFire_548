-- LOA zone port: creature spawns for Timeless Isle (1135).
-- Column mapping from LOA schema to SkyFire schema. Status: local-only (not pushed upstream)

INSERT INTO `creature` (
    `guid`, `id`, `map`, `spawnMask`, `phaseId`, `phaseGroup`, `modelid`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawndist`,
    `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`
)
SELECT
    l.`guid`, l.`id`, l.`map`, l.`spawnMask`, l.`phaseId`, l.`phaseGroup`, l.`modelid`, l.`equipment_id`,
    l.`position_x`, l.`position_y`, l.`position_z`, l.`orientation`, l.`spawntimesecs`, l.`wander_distance`,
    l.`currentwaypoint`, l.`curhealth`, l.`curmana`, l.`movement_type`, l.`npcflag`, l.`unit_flags`, l.`dynamicflags`
FROM `loa`.`creature` l
LEFT JOIN `creature` w ON w.`guid` = l.`guid`
WHERE w.`guid` IS NULL
  AND l.`map` IN (1135);
