-- LOA port: scene_template rows missing in world.
-- Requires loa database on same MySQL host. Status: local-only (not pushed upstream)

INSERT INTO `scene_template` (`SceneId`, `Flags`, `ScriptPackageID`, `ScriptName`)
SELECT l.`SceneId`, l.`Flags`, l.`ScriptPackageID`, l.`ScriptName`
FROM `loa`.`scene_template` l
LEFT JOIN `scene_template` w ON w.`SceneId` = l.`SceneId`
WHERE w.`SceneId` IS NULL;
