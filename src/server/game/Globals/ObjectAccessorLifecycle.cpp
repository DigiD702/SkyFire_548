/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ObjectAccessorLifecycle.h"

namespace Skyfire
{
namespace ObjectAccess
{
    ObjectUpdateQueueAddAction GetUpdateObjectQueueAddAction(bool alreadyQueued)
    {
        return alreadyQueued ? OBJECT_UPDATE_QUEUE_ADD_ALREADY_PRESENT : OBJECT_UPDATE_QUEUE_ADD_INSERT;
    }

    ObjectUpdateQueueRemoveAction GetUpdateObjectQueueRemoveAction(bool queued)
    {
        return queued ? OBJECT_UPDATE_QUEUE_REMOVE_ERASE : OBJECT_UPDATE_QUEUE_REMOVE_MISSING;
    }

    ObjectUpdateQueueDrainAction GetUpdateObjectQueueDrainAction(bool empty)
    {
        return empty ? OBJECT_UPDATE_QUEUE_DRAIN_EMPTY : OBJECT_UPDATE_QUEUE_DRAIN_POP;
    }

    bool CanBuildUpdateForQueuedObject(bool hasObject, bool isInWorld)
    {
        return hasObject && isInWorld;
    }

    ObjectCorpseOwnerRemoveAction GetCorpseOwnerMappingRemoveAction(bool mapped)
    {
        return mapped ? OBJECT_CORPSE_OWNER_REMOVE_ERASE : OBJECT_CORPSE_OWNER_REMOVE_MISSING;
    }

    ObjectCorpseOwnerAddAction GetCorpseOwnerMappingAddAction(bool alreadyMapped)
    {
        return alreadyMapped ? OBJECT_CORPSE_OWNER_ADD_ALREADY_MAPPED : OBJECT_CORPSE_OWNER_ADD_INSERT;
    }

    ObjectCorpseStorageUnloadAction GetCorpseStorageUnloadAction(bool empty)
    {
        return empty ? OBJECT_CORPSE_STORAGE_UNLOAD_EMPTY : OBJECT_CORPSE_STORAGE_UNLOAD_DRAIN;
    }
}
}
