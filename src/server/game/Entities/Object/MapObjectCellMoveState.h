/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SKYFIRE_MAPOBJECTCELLMOVESTATE_H
#define SKYFIRE_MAPOBJECTCELLMOVESTATE_H

enum class MapObjectCellMoveState
{
    MAP_OBJECT_CELL_MOVE_NONE,     // not in move list
    MAP_OBJECT_CELL_MOVE_ACTIVE,   // in move list
    MAP_OBJECT_CELL_MOVE_INACTIVE  // in move list but should not move
};

#endif
