-- Remove leftover LOA scene_template rows (SFDB baseline has none).
-- Bulk LOA import caused Shrine client DB2 OOM; these 4 rows remained in world.
DELETE FROM `scene_template` WHERE `SceneId` IN (249, 250, 251, 252);
