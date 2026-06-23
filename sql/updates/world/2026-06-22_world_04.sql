-- Pending world areatrigger_tavern test update.
--
-- Scope:
-- - Add tavern area triggers that are missing from the experimental world
--   database.
-- - Keep this in pending_updates while testing; the database updater does not
--   apply files from this directory.
--
-- Apply manually to a staging world database before promotion to sql/updates/world.

INSERT IGNORE INTO `areatrigger_tavern` (`id`, `name`) VALUES
(262, 'Razorfen Kraul'),
(2746, 'Stormwind City'),
(4502, 'Old Hillsbrad Foothills, behind Inn'),
(4529, 'Shadowmoon Valley, Wildhammer Stronghold, Inn bedroom'),
(4786, '4786'),
(4933, '4933'),
(4990, '4990'),
(5140, '5140'),
(5360, 'Grom''arsh Crash-Site'),
(5565, '5565'),
(5628, '5628');
