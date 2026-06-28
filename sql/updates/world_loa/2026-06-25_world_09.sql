-- Sync ScriptName/script fields from LOA where SkyFire has empty bindings.
-- Requires loa database on same MySQL host. Status: local-only (not pushed upstream)

UPDATE `creature_template` sf
JOIN `loa`.`creature_template` loa ON loa.entry = sf.entry
SET sf.ScriptName = loa.ScriptName
WHERE (sf.ScriptName IS NULL OR sf.ScriptName = '')
  AND loa.ScriptName IS NOT NULL
  AND loa.ScriptName <> '';

UPDATE `gameobject_template` sf
JOIN `loa`.`gameobject_template` loa ON loa.entry = sf.entry
SET sf.ScriptName = loa.ScriptName
WHERE (sf.ScriptName IS NULL OR sf.ScriptName = '')
  AND loa.ScriptName IS NOT NULL
  AND loa.ScriptName <> '';

UPDATE `instance_template` sf
JOIN `loa`.`instance_template` loa ON loa.map = sf.map
SET sf.script = loa.script
WHERE (sf.script IS NULL OR sf.script = '')
  AND loa.script IS NOT NULL
  AND loa.script <> '';
