/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "SpellSummonMetadata.h"

namespace Skyfire
{
namespace Spells
{
    namespace
    {
        struct TotemHealthRule
        {
            uint32 SpellId;
            uint32 HealthPct;
        };

        uint32 const DamageBasedSummonProperties[] =
        {
            64,
            61,
            1101,
            66,
            648,
            2301,
            1061,
            1261,
            629,
            181,
            715,
            1562,
            833,
            1161
        };

        TotemHealthRule const TotemHealthRules[] =
        {
            { 115313, 30 },
            { 115315, 30 },
            { 126135, 30 },
            {  16190, 10 }
        };
    }

    bool ShouldUseDamageAsSummonCount(uint32 summonPropertyId)
    {
        for (uint32 propertyId : DamageBasedSummonProperties)
            if (propertyId == summonPropertyId)
                return true;

        return false;
    }

    uint32 GetSummonCountForProperty(uint32 summonPropertyId, int32 damage)
    {
        if (!ShouldUseDamageAsSummonCount(summonPropertyId))
            return 1;

        return damage > 0 ? uint32(damage) : 1;
    }

    uint32 GetTotemSummonHealthPct(uint32 spellId)
    {
        for (TotemHealthRule const& rule : TotemHealthRules)
            if (rule.SpellId == spellId)
                return rule.HealthPct;

        return 0;
    }
}
}
