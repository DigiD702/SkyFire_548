-- Client login crash (Error #132 stack_overflow): remove LOA hotfix row.
-- Baseline SFDB has empty hotfix_data; item 32549 (Tier 5 Paladin Test Gear) hotfix
-- triggers SMSG_HOTFIX_NOTIFY_BLOB on every login and can crash the 5.4.8 client.
DELETE FROM `hotfix_data` WHERE `entry` = 32549 AND `type` = 2442913102;
