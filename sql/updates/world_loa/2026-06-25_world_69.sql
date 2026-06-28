-- LOA instance port: creature_template AIName/ScriptName sync for dungeon/raid maps.
-- Status: local-only (not pushed upstream)

UPDATE `creature_template` sf
JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (959, 960, 961, 962, 994, 1011, 996, 1008, 1009, 974, 999, 1000, 1001, 1007)
) z ON z.`entry` = sf.`entry`
JOIN `loa`.`creature_template` loa ON loa.`entry` = sf.`entry`
SET sf.`AIName` = loa.`AIName`,
    sf.`ScriptName` = CASE
        WHEN loa.`ScriptName` <> '' THEN loa.`ScriptName`
        ELSE sf.`ScriptName`
    END
WHERE loa.`AIName` <> sf.`AIName`
   OR (sf.`ScriptName` = '' AND loa.`ScriptName` <> '');
