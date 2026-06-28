-- LOA port: spell_script_names gap-fill (binds C++ spell scripts to spell IDs).
-- Status: local-only (not pushed upstream)

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
SELECT l.`spell_id`, l.`ScriptName`
FROM `loa`.`spell_script_names` l
LEFT JOIN `spell_script_names` w
  ON w.`spell_id` = l.`spell_id` AND w.`ScriptName` = l.`ScriptName`
WHERE w.`spell_id` IS NULL;
