/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_SPELL_SUMMON_METADATA_H
#define SF_SPELL_SUMMON_METADATA_H

#include "Define.h"

namespace Skyfire
{
namespace Spells
{
    bool ShouldUseDamageAsSummonCount(uint32 summonPropertyId);
    uint32 GetSummonCountForProperty(uint32 summonPropertyId, int32 damage);
    uint32 GetTotemSummonHealthPct(uint32 spellId);
}
}

#endif
