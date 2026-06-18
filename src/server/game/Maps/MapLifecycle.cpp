/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "MapLifecycle.h"

namespace Skyfire
{
namespace Maps
{
    MapMoveQueueAddAction GetMoveQueueAddAction(MapObjectCellMoveState state, bool queueLocked)
    {
        if (queueLocked)
            return MAP_MOVE_QUEUE_ADD_SKIPPED_LOCKED;

        return state == MapObjectCellMoveState::MAP_OBJECT_CELL_MOVE_NONE ?
            MAP_MOVE_QUEUE_ADD_APPEND : MAP_MOVE_QUEUE_ADD_REFRESH;
    }

    MapMoveQueueRemoveAction MarkMoveQueueEntryInactive(MapObjectCellMoveState& state, bool queueLocked)
    {
        if (queueLocked)
            return MAP_MOVE_QUEUE_REMOVE_SKIPPED_LOCKED;

        if (state != MapObjectCellMoveState::MAP_OBJECT_CELL_MOVE_ACTIVE)
            return MAP_MOVE_QUEUE_REMOVE_ALREADY_CLEAR;

        state = MapObjectCellMoveState::MAP_OBJECT_CELL_MOVE_INACTIVE;
        return MAP_MOVE_QUEUE_REMOVE_MARK_INACTIVE;
    }

    bool ConsumeMoveQueueEntry(MapObjectCellMoveState& state)
    {
        bool const shouldMove = state == MapObjectCellMoveState::MAP_OBJECT_CELL_MOVE_ACTIVE;
        state = MapObjectCellMoveState::MAP_OBJECT_CELL_MOVE_NONE;
        return shouldMove;
    }

    MapAddObjectAction GetAddObjectAction(bool alreadyInWorld, bool validCoordinates)
    {
        if (alreadyInWorld)
            return MAP_ADD_OBJECT_REFRESH_EXISTING;

        return validCoordinates ? MAP_ADD_OBJECT_ADD_TO_GRID : MAP_ADD_OBJECT_REJECT_INVALID_COORDS;
    }

    MapRemoveListAddAction GetRemoveListAddAction(bool alreadyQueued)
    {
        return alreadyQueued ? MAP_REMOVE_LIST_ADD_ALREADY_QUEUED : MAP_REMOVE_LIST_ADD_INSERT;
    }

    MapSwitchListAction GetSwitchListAction(bool supportedObjectType, bool alreadyQueued, bool queuedOn, bool requestedOn)
    {
        if (!supportedObjectType)
            return MAP_SWITCH_LIST_IGNORE_UNSUPPORTED_TYPE;

        if (!alreadyQueued)
            return MAP_SWITCH_LIST_INSERT;

        return queuedOn != requestedOn ? MAP_SWITCH_LIST_ERASE_OPPOSITE : MAP_SWITCH_LIST_REJECT_DUPLICATE;
    }
}
}
