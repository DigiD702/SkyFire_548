-- LOA instance port: creature spawns for MoP dungeons and raids.
-- Maps: 959 Shado-Pan, 960 Jade Serpent, 961 Stormstout, 962 Gate of Setting Sun,
--       994 Mogu'shan Palace, 1011 Siege of Niuzao, 996 Terrace, 1008 MSV, 1009 HoF,
--       974/999/1000 raid wings, 1001 Scarlet Halls, 1007 Scholomance.
-- Status: local-only (not pushed upstream)

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
  AND l.`map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007);
