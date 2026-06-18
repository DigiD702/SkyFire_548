/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SKYFIRE_OBJECTACCESSORLIFECYCLE_H
#define SKYFIRE_OBJECTACCESSORLIFECYCLE_H

namespace Skyfire
{
namespace ObjectAccess
{
    enum ObjectUpdateQueueAddAction
    {
        OBJECT_UPDATE_QUEUE_ADD_INSERT,
        OBJECT_UPDATE_QUEUE_ADD_ALREADY_PRESENT
    };

    enum ObjectUpdateQueueRemoveAction
    {
        OBJECT_UPDATE_QUEUE_REMOVE_ERASE,
        OBJECT_UPDATE_QUEUE_REMOVE_MISSING
    };

    enum ObjectUpdateQueueDrainAction
    {
        OBJECT_UPDATE_QUEUE_DRAIN_POP,
        OBJECT_UPDATE_QUEUE_DRAIN_EMPTY
    };

    enum ObjectCorpseOwnerRemoveAction
    {
        OBJECT_CORPSE_OWNER_REMOVE_ERASE,
        OBJECT_CORPSE_OWNER_REMOVE_MISSING
    };

    enum ObjectCorpseOwnerAddAction
    {
        OBJECT_CORPSE_OWNER_ADD_INSERT,
        OBJECT_CORPSE_OWNER_ADD_ALREADY_MAPPED
    };

    enum ObjectCorpseStorageUnloadAction
    {
        OBJECT_CORPSE_STORAGE_UNLOAD_DRAIN,
        OBJECT_CORPSE_STORAGE_UNLOAD_EMPTY
    };

    ObjectUpdateQueueAddAction GetUpdateObjectQueueAddAction(bool alreadyQueued);
    ObjectUpdateQueueRemoveAction GetUpdateObjectQueueRemoveAction(bool queued);
    ObjectUpdateQueueDrainAction GetUpdateObjectQueueDrainAction(bool empty);
    bool CanBuildUpdateForQueuedObject(bool hasObject, bool isInWorld);
    ObjectCorpseOwnerRemoveAction GetCorpseOwnerMappingRemoveAction(bool mapped);
    ObjectCorpseOwnerAddAction GetCorpseOwnerMappingAddAction(bool alreadyMapped);
    ObjectCorpseStorageUnloadAction GetCorpseStorageUnloadAction(bool empty);
}
}

#endif
