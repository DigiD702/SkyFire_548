/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_SPELL_COMBAT_METADATA_H
#define SF_SPELL_COMBAT_METADATA_H

#include "Define.h"

namespace Skyfire
{
namespace Spells
{
    enum GenericSchoolDamageRule
    {
        GENERIC_SCHOOL_DAMAGE_NONE,
        GENERIC_SCHOOL_DAMAGE_CONSUMPTION,
        GENERIC_SCHOOL_DAMAGE_THUNDERCRASH,
        GENERIC_SCHOOL_DAMAGE_ARCANE_CHARGE,
        GENERIC_SCHOOL_DAMAGE_GARGOYLE_STRIKE
    };

    struct EnergizeLevelScalingRule
    {
        uint32 SpellId;
        int32 BaseLevel;
        int32 LevelMultiplier;
    };

    GenericSchoolDamageRule GetGenericSchoolDamageRule(uint32 spellId);
    uint32 GetConsumptionDamage(uint32 difficulty);
    uint32 GetThundercrashMinimumDamage();
    bool IsArcaneChargeAllowedCreatureType(uint32 creatureType);
    int32 GetGargoyleStrikeDamageForLevel(uint32 level);
    bool IsVictoryRushDamageSpell(uint32 spellId);
    bool IsShockwaveDamageSpell(uint32 spellId);
    bool IsManaBurnSpell(uint32 spellId);
    bool IsVesselOfTheNaaruHealSpell(uint32 spellId);
    uint32 GetVesselOfTheNaaruStackAuraSpellId();
    bool IsRunicHealingInjectorSpell(uint32 spellId);
    uint32 GetEngineeringHealingBonusPct();
    EnergizeLevelScalingRule const* GetEnergizeLevelScalingRule(uint32 spellId);
    bool IsPrimalWisdomEnergizeSpell(uint32 spellId);
    bool IsRunicManaInjectorSpell(uint32 spellId);
    bool IsJabEnergizeSpell(uint32 spellId);
    uint32 GetJabBaseChi();
    uint32 GetStanceOfTheFierceTigerAuraSpellId();
    bool IsMadAlchemistsPotionSpell(uint32 spellId);
    bool IsBloodTapRuneSpell(uint32 spellId);
    bool IsEmpowerRuneWeaponSpell(uint32 spellId);
}
}

#endif
