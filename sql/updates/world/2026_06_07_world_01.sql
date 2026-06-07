-- Fix Hogger Wanted Poster (entry 68) not interactable (#1080)
UPDATE `gameobject_template`
SET `flags` = `flags` & ~20
WHERE `entry` = 68;
