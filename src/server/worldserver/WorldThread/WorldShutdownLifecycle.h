/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SKYFIRE_WORLDSHUTDOWNLIFECYCLE_H
#define SKYFIRE_WORLDSHUTDOWNLIFECYCLE_H

namespace Skyfire
{
namespace WorldShutdown
{
    enum WorldShutdownStep
    {
        WORLD_SHUTDOWN_START,
        WORLD_SHUTDOWN_SCRIPT_SHUTDOWN,
        WORLD_SHUTDOWN_KICK_PLAYERS,
        WORLD_SHUTDOWN_UPDATE_SESSIONS,
        WORLD_SHUTDOWN_DELETE_BATTLEGROUNDS,
        WORLD_SHUTDOWN_STOP_NETWORK,
        WORLD_SHUTDOWN_UNLOAD_MAPS,
        WORLD_SHUTDOWN_UNLOAD_OBJECT_ACCESSOR,
        WORLD_SHUTDOWN_UNLOAD_SCRIPTS,
        WORLD_SHUTDOWN_OUTDOOR_PVP_DIE,
        WORLD_SHUTDOWN_COMPLETE
    };

    char const* GetShutdownStepName(WorldShutdownStep step);
    bool IsExpectedShutdownTransition(WorldShutdownStep current, WorldShutdownStep next);
    bool IsShutdownStepBefore(WorldShutdownStep first, WorldShutdownStep second);
}
}

#endif
