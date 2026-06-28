-- LOA zone port: align creature_template AIName/ScriptName for maps 860 and 870.
-- Status: local-only (not pushed upstream)

UPDATE `creature_template` sf
JOIN (
    SELECT DISTINCT id AS entry
    FROM `loa`.`creature`
    WHERE map IN (860, 870)
) z ON z.entry = sf.entry
JOIN `loa`.`creature_template` loa ON loa.entry = sf.entry
SET sf.AIName = loa.AIName,
    sf.ScriptName = CASE
        WHEN loa.ScriptName <> '' THEN loa.ScriptName
        ELSE sf.ScriptName
    END
WHERE loa.AIName <> sf.AIName
   OR (sf.ScriptName = '' AND loa.ScriptName <> '');
