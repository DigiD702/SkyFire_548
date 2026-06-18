/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_SPELL_ITEM_METADATA_H
#define SF_SPELL_ITEM_METADATA_H

#include "Define.h"

namespace Skyfire
{
namespace Spells
{
    bool ShouldDeactivateOwnedTrapOnOpenLock(uint32 spellId, uint32 gameObjectType, bool hasOwner);
    uint32 GetTemporaryItemEnchantDurationSeconds(uint32 spellId, uint32 spellFamilyName, uint32 spellVisual);
}
}

#endif
