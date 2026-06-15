/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SKYFIRE_MAPLIFECYCLE_H
#define SKYFIRE_MAPLIFECYCLE_H

#include "MapObjectCellMoveState.h"

namespace Skyfire
{
namespace Maps
{
    enum MapMoveQueueAddAction
    {
        MAP_MOVE_QUEUE_ADD_APPEND,
        MAP_MOVE_QUEUE_ADD_REFRESH,
        MAP_MOVE_QUEUE_ADD_SKIPPED_LOCKED
    };

    enum MapMoveQueueRemoveAction
    {
        MAP_MOVE_QUEUE_REMOVE_MARK_INACTIVE,
        MAP_MOVE_QUEUE_REMOVE_ALREADY_CLEAR,
        MAP_MOVE_QUEUE_REMOVE_SKIPPED_LOCKED
    };

    enum MapAddObjectAction
    {
        MAP_ADD_OBJECT_REFRESH_EXISTING,
        MAP_ADD_OBJECT_ADD_TO_GRID,
        MAP_ADD_OBJECT_REJECT_INVALID_COORDS
    };

    enum MapRemoveListAddAction
    {
        MAP_REMOVE_LIST_ADD_INSERT,
        MAP_REMOVE_LIST_ADD_ALREADY_QUEUED
    };

    enum MapSwitchListAction
    {
        MAP_SWITCH_LIST_IGNORE_UNSUPPORTED_TYPE,
        MAP_SWITCH_LIST_INSERT,
        MAP_SWITCH_LIST_ERASE_OPPOSITE,
        MAP_SWITCH_LIST_REJECT_DUPLICATE
    };

    MapMoveQueueAddAction GetMoveQueueAddAction(MapObjectCellMoveState state, bool queueLocked);
    MapMoveQueueRemoveAction MarkMoveQueueEntryInactive(MapObjectCellMoveState& state, bool queueLocked);
    bool ConsumeMoveQueueEntry(MapObjectCellMoveState& state);
    MapAddObjectAction GetAddObjectAction(bool alreadyInWorld, bool validCoordinates);
    MapRemoveListAddAction GetRemoveListAddAction(bool alreadyQueued);
    MapSwitchListAction GetSwitchListAction(bool supportedObjectType, bool alreadyQueued, bool queuedOn, bool requestedOn);
}
}

#endif
