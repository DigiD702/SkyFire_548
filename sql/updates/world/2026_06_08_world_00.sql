-- Fix Jade Serpent Temple entrance and interior doors being interactable (#1204)
UPDATE `gameobject_template`
SET `flags` = `flags` | 36
WHERE `entry` IN (
213268, 213269, 213270, 213271,
213544, 213545, 213547, 213548, 213549, 213550, 213903
);
