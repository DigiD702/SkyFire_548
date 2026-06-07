-- Fix Combat Potency (35541-35553) 100% proc rate (#965)
DELETE FROM `spell_proc_event` WHERE `entry` IN (35541, 35550, 35551, 35552, 35553);
INSERT INTO `spell_proc_event` (`entry`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `SpellFamilyMask3`, `procFlags`, `procEx`, `ppmRate`, `CustomChance`, `Cooldown`) VALUES
(35541, 0, 0, 0, 0, 0, 0, 8388608, 0, 0, 20, 0),
(35550, 0, 0, 0, 0, 0, 0, 8388608, 0, 0, 20, 0),
(35551, 0, 0, 0, 0, 0, 0, 8388608, 0, 0, 20, 0),
(35552, 0, 0, 0, 0, 0, 0, 8388608, 0, 0, 20, 0),
(35553, 0, 0, 0, 0, 0, 0, 8388608, 0, 0, 20, 0);
