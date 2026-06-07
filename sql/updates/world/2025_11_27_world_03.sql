-- Fear No Evil (28810): spellclick must target the clicked infantry, not the player.
-- cast_flags 3 (caster+target=clicker) prevented GetExplTargetUnit from returning entry 50047,
-- so the spell script fell back to FindNearestCreature and could hit a different/already-revived soldier.
UPDATE `npc_spellclick_spells`
SET `cast_flags` = 1
WHERE `npc_entry` = 50047 AND `spell_id` = 93072;
