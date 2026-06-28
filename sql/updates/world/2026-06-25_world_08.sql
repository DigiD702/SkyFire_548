-- Remove orphan gameobject spawn 212922
DELETE FROM `gameobject` WHERE `id` = 212922 AND `guid` = 200011;
