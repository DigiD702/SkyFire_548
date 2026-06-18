/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "SpellCombatMetadata.h"
#include "DBCEnums.h"
#include "SharedDefines.h"

namespace Skyfire
{
namespace Spells
{
    namespace
    {
        struct GenericSchoolDamageRuleInfo
        {
            uint32 SpellId;
            GenericSchoolDamageRule Rule;
        };

        uint32 const SPELL_CONSUMPTION = 28865;
        uint32 const SPELL_THUNDERCRASH = 25599;
        uint32 const SPELL_ARCANE_CHARGE = 45072;
        uint32 const SPELL_GARGOYLE_STRIKE = 51963;
        uint32 const SPELL_VICTORY_RUSH = 34428;
        uint32 const SPELL_SHOCKWAVE = 46968;
        uint32 const SPELL_MANA_BURN = 8129;
        uint32 const SPELL_VESSEL_OF_THE_NAARU = 45064;
        uint32 const SPELL_VESSEL_OF_THE_NAARU_STACK_AURA = 45062;
        uint32 const SPELL_RUNIC_HEALING_INJECTOR = 67489;
        uint32 const SPELL_PRIMAL_WISDOM = 63375;
        uint32 const SPELL_RUNIC_MANA_INJECTOR = 67490;
        uint32 const SPELL_JAB = 100780;
        uint32 const SPELL_STANCE_OF_THE_FIERCE_TIGER = 103985;
        uint32 const SPELL_MAD_ALCHEMISTS_POTION = 45051;
        uint32 const SPELL_BLOOD_TAP = 45529;
        uint32 const SPELL_EMPOWER_RUNE_WEAPON = 47568;

        uint32 const DAMAGE_CONSUMPTION_NORMAL = 2750;
        uint32 const DAMAGE_CONSUMPTION_HEROIC = 4250;
        uint32 const DAMAGE_THUNDERCRASH_MINIMUM = 200;
        uint32 const ENGINEERING_HEALING_BONUS_PCT = 25;
        uint32 const JAB_BASE_CHI = 1;

        GenericSchoolDamageRuleInfo const GenericSchoolDamageRules[] =
        {
            { SPELL_CONSUMPTION, GENERIC_SCHOOL_DAMAGE_CONSUMPTION },
            { SPELL_THUNDERCRASH, GENERIC_SCHOOL_DAMAGE_THUNDERCRASH },
            { SPELL_ARCANE_CHARGE, GENERIC_SCHOOL_DAMAGE_ARCANE_CHARGE },
            { SPELL_GARGOYLE_STRIKE, GENERIC_SCHOOL_DAMAGE_GARGOYLE_STRIKE }
        };

        EnergizeLevelScalingRule const EnergizeLevelScalingRules[] =
        {
            {  9512, 40,  2 }, // Restore Energy
            { 24571, 60, 10 }, // Blood Fury
            { 24532, 60,  4 }  // Burst of Energy
        };
    }

    GenericSchoolDamageRule GetGenericSchoolDamageRule(uint32 spellId)
    {
        for (GenericSchoolDamageRuleInfo const& rule : GenericSchoolDamageRules)
            if (rule.SpellId == spellId)
                return rule.Rule;

        return GENERIC_SCHOOL_DAMAGE_NONE;
    }

    uint32 GetConsumptionDamage(uint32 difficulty)
    {
        return difficulty == DIFFICULTY_NONE ? DAMAGE_CONSUMPTION_NORMAL : DAMAGE_CONSUMPTION_HEROIC;
    }

    uint32 GetThundercrashMinimumDamage()
    {
        return DAMAGE_THUNDERCRASH_MINIMUM;
    }

    bool IsArcaneChargeAllowedCreatureType(uint32 creatureType)
    {
        return creatureType == CREATURE_TYPE_DEMON || creatureType == CREATURE_TYPE_UNDEAD;
    }

    int32 GetGargoyleStrikeDamageForLevel(uint32 level)
    {
        return (int32(level) - 60) * 4 + 60;
    }

    bool IsVictoryRushDamageSpell(uint32 spellId)
    {
        return spellId == SPELL_VICTORY_RUSH;
    }

    bool IsShockwaveDamageSpell(uint32 spellId)
    {
        return spellId == SPELL_SHOCKWAVE;
    }

    bool IsManaBurnSpell(uint32 spellId)
    {
        return spellId == SPELL_MANA_BURN;
    }

    bool IsVesselOfTheNaaruHealSpell(uint32 spellId)
    {
        return spellId == SPELL_VESSEL_OF_THE_NAARU;
    }

    uint32 GetVesselOfTheNaaruStackAuraSpellId()
    {
        return SPELL_VESSEL_OF_THE_NAARU_STACK_AURA;
    }

    bool IsRunicHealingInjectorSpell(uint32 spellId)
    {
        return spellId == SPELL_RUNIC_HEALING_INJECTOR;
    }

    uint32 GetEngineeringHealingBonusPct()
    {
        return ENGINEERING_HEALING_BONUS_PCT;
    }

    EnergizeLevelScalingRule const* GetEnergizeLevelScalingRule(uint32 spellId)
    {
        for (EnergizeLevelScalingRule const& rule : EnergizeLevelScalingRules)
            if (rule.SpellId == spellId)
                return &rule;

        return nullptr;
    }

    bool IsPrimalWisdomEnergizeSpell(uint32 spellId)
    {
        return spellId == SPELL_PRIMAL_WISDOM;
    }

    bool IsRunicManaInjectorSpell(uint32 spellId)
    {
        return spellId == SPELL_RUNIC_MANA_INJECTOR;
    }

    bool IsJabEnergizeSpell(uint32 spellId)
    {
        return spellId == SPELL_JAB;
    }

    uint32 GetJabBaseChi()
    {
        return JAB_BASE_CHI;
    }

    uint32 GetStanceOfTheFierceTigerAuraSpellId()
    {
        return SPELL_STANCE_OF_THE_FIERCE_TIGER;
    }

    bool IsMadAlchemistsPotionSpell(uint32 spellId)
    {
        return spellId == SPELL_MAD_ALCHEMISTS_POTION;
    }

    bool IsBloodTapRuneSpell(uint32 spellId)
    {
        return spellId == SPELL_BLOOD_TAP;
    }

    bool IsEmpowerRuneWeaponSpell(uint32 spellId)
    {
        return spellId == SPELL_EMPOWER_RUNE_WEAPON;
    }
}
}
