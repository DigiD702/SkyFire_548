-- LOA zone port: creature_template for spawns on map 1064 missing templates.
-- Follow-up to 2026-06-25_world_30.sql. Status: local-only (not pushed upstream)

INSERT INTO `creature_template` (
    `entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`,
    `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `exp_unk`,
    `faction_A`, `faction_H`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `npc_rank`,
    `mindmg`, `maxdmg`, `dmgschool`, `attackpower`, `dmg_multiplier`, `baseattacktime`, `rangeattacktime`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_class`, `trainer_race`,
    `minrangedmg`, `maxrangedmg`, `rangedattackpower`, `type`, `type_flags`, `type_flags2`,
    `lootid`, `pickpocketloot`, `skinloot`,
    `resistance1`, `resistance2`, `resistance3`, `resistance4`, `resistance5`, `resistance6`,
    `spell1`, `spell2`, `spell3`, `spell4`, `spell5`, `spell6`, `spell7`, `spell8`,
    `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`,
    `Health_mod`, `Mana_mod`, `Mana_mod_extra`, `Armor_mod`, `RacialLeader`,
    `questItem1`, `questItem2`, `questItem3`, `questItem4`, `questItem5`, `questItem6`,
    `movementId`, `RegenHealth`, `mechanic_immune_mask`, `flags_extra`, `ScriptName`, `ModLevel`
)
SELECT
    l.`entry`, l.`difficulty_entry_1`, l.`difficulty_entry_2`, l.`difficulty_entry_3`,
    l.`KillCredit1`, l.`KillCredit2`, l.`modelid1`, l.`modelid2`, l.`modelid3`, l.`modelid4`,
    l.`name`, l.`subname`, l.`IconName`, l.`gossip_menu_id`, l.`minlevel`, l.`maxlevel`, l.`exp`, l.`exp_unk`,
    l.`faction`, l.`faction`, l.`npcflag`, l.`speed_walk`, l.`speed_run`, l.`scale`, l.`rank`,
    l.`mindmg`, l.`maxdmg`, l.`dmgschool`, l.`attackpower`, l.`dmg_multiplier`, l.`baseattacktime`, l.`rangeattacktime`,
    l.`unit_class`, l.`unit_flags`, l.`unit_flags2`, l.`dynamicflags`, l.`family`, l.`trainer_type`, l.`trainer_class`, l.`trainer_race`,
    l.`minrangedmg`, l.`maxrangedmg`, l.`rangedattackpower`, l.`type`, l.`type_flags`, l.`type_flags2`,
    l.`lootid`, l.`pickpocketloot`, l.`skinloot`,
    l.`resistance1`, l.`resistance2`, l.`resistance3`, l.`resistance4`, l.`resistance5`, l.`resistance6`,
    l.`spell1`, l.`spell2`, l.`spell3`, l.`spell4`, l.`spell5`, l.`spell6`, l.`spell7`, l.`spell8`,
    l.`PetSpellDataId`, l.`VehicleId`, l.`mingold`, l.`maxgold`, l.`AIName`, l.`MovementType`, l.`InhabitType`, l.`HoverHeight`,
    l.`Health_mod`, l.`Mana_mod`, l.`Mana_mod_extra`, l.`Armor_mod`, l.`RacialLeader`,
    l.`questItem1`, l.`questItem2`, l.`questItem3`, l.`questItem4`, l.`questItem5`, l.`questItem6`,
    l.`movementId`, l.`RegenHealth`, l.`mechanic_immune_mask`, l.`flags_extra`, l.`ScriptName`, 0
FROM `loa`.`creature_template` l
LEFT JOIN `creature_template` w ON w.`entry` = l.`entry`
WHERE w.`entry` IS NULL
  AND l.`entry` IN (
      SELECT DISTINCT c.`id`
      FROM `creature` c
      LEFT JOIN `creature_template` ct ON ct.`entry` = c.`id`
      WHERE c.`map` IN (1064)
        AND ct.`entry` IS NULL
  );
