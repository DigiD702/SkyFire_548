-- LOA zone port: creature_template AIName/ScriptName sync for map 1050.
-- Status: local-only (not pushed upstream)

UPDATE `creature_template` sf
JOIN (
    SELECT DISTINCT `id` AS `entry`
    FROM `creature`
    WHERE `map` IN (1050)
) z ON z.`entry` = sf.`entry`
JOIN `loa`.`creature_template` loa ON loa.`entry` = sf.`entry`
SET sf.`AIName` = loa.`AIName`,
    sf.`ScriptName` = CASE
        WHEN loa.`ScriptName` <> '' THEN loa.`ScriptName`
        ELSE sf.`ScriptName`
    END
WHERE loa.`AIName` <> sf.`AIName`
   OR (sf.`ScriptName` = '' AND loa.`ScriptName` <> '');
