-- DBErrors: Sayge SmartAI uses spell 23770 (not in client DBC). Remove broken linked cast only.
-- Scenario spawnMask 4096 is correct for LOA ports; MapDifficulty core patch was reverted (client login crash).
UPDATE `smart_scripts`
SET `link` = 0
WHERE `entryorguid` = 14822 AND `source_type` = 0 AND `link` = 14;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 14822 AND `source_type` = 0 AND `id` = 14;
