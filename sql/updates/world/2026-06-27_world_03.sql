-- Shrine of Seven Stars Hearthstone easter-egg NPCs (map 870)
-- SmartAI OOC talk scripts (2026-06-26_smart_scripts_part2.sql) reference group 0
-- Post-5.4 gossip from Warcraft Wiki (no SFDB/LOA creature_text source)
INSERT IGNORE INTO `creature_text` (`entry`, `groupid`, `id`, `text`, `type`, `language`, `probability`, `emote`, `duration`, `sound`, `comment`) VALUES
    (64071, 0, 0, 'Please, partake in the buffet laid out by the Golden Lotus as a thanks to your people for their aid in protecting the Vale of Eternal Blossoms.', 12, 0, 100, 0, 0, 0, 'Zhen Zhen Wang'),
    (64072, 0, 0, 'See this card here? This one\'s going to really knock the dwarf off his chair!', 12, 0, 100, 0, 0, 0, 'Omar Gonzalez'),
    (64072, 0, 1, 'Yeah, yeah, I\'ll come join you on your adventure. Just let me play one more game first.', 12, 0, 100, 0, 0, 0, 'Omar Gonzalez'),
    (64072, 0, 2, 'This is the best I\'ve felt in years!', 12, 0, 100, 0, 0, 0, 'Omar Gonzalez'),
    (64115, 0, 0, 'I can beat him, I swear!', 12, 0, 100, 0, 0, 0, 'Scott Smith');
