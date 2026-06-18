/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "WorldShutdownLifecycle.h"

namespace Skyfire
{
namespace WorldShutdown
{
    namespace
    {
        int GetShutdownStepIndex(WorldShutdownStep step)
        {
            switch (step)
            {
                case WORLD_SHUTDOWN_START:
                    return 0;
                case WORLD_SHUTDOWN_SCRIPT_SHUTDOWN:
                    return 1;
                case WORLD_SHUTDOWN_KICK_PLAYERS:
                    return 2;
                case WORLD_SHUTDOWN_UPDATE_SESSIONS:
                    return 3;
                case WORLD_SHUTDOWN_DELETE_BATTLEGROUNDS:
                    return 4;
                case WORLD_SHUTDOWN_STOP_NETWORK:
                    return 5;
                case WORLD_SHUTDOWN_UNLOAD_MAPS:
                    return 6;
                case WORLD_SHUTDOWN_UNLOAD_OBJECT_ACCESSOR:
                    return 7;
                case WORLD_SHUTDOWN_UNLOAD_SCRIPTS:
                    return 8;
                case WORLD_SHUTDOWN_OUTDOOR_PVP_DIE:
                    return 9;
                case WORLD_SHUTDOWN_COMPLETE:
                    return 10;
                default:
                    return -1;
            }
        }
    }

    char const* GetShutdownStepName(WorldShutdownStep step)
    {
        switch (step)
        {
            case WORLD_SHUTDOWN_START:
                return "start";
            case WORLD_SHUTDOWN_SCRIPT_SHUTDOWN:
                return "script shutdown";
            case WORLD_SHUTDOWN_KICK_PLAYERS:
                return "kick players";
            case WORLD_SHUTDOWN_UPDATE_SESSIONS:
                return "update sessions";
            case WORLD_SHUTDOWN_DELETE_BATTLEGROUNDS:
                return "delete battlegrounds";
            case WORLD_SHUTDOWN_STOP_NETWORK:
                return "stop network";
            case WORLD_SHUTDOWN_UNLOAD_MAPS:
                return "unload maps";
            case WORLD_SHUTDOWN_UNLOAD_OBJECT_ACCESSOR:
                return "unload object accessor";
            case WORLD_SHUTDOWN_UNLOAD_SCRIPTS:
                return "unload scripts";
            case WORLD_SHUTDOWN_OUTDOOR_PVP_DIE:
                return "outdoor pvp cleanup";
            case WORLD_SHUTDOWN_COMPLETE:
                return "complete";
            default:
                return "unknown";
        }
    }

    bool IsExpectedShutdownTransition(WorldShutdownStep current, WorldShutdownStep next)
    {
        int const currentIndex = GetShutdownStepIndex(current);
        int const nextIndex = GetShutdownStepIndex(next);
        return currentIndex >= 0 && nextIndex == currentIndex + 1;
    }

    bool IsShutdownStepBefore(WorldShutdownStep first, WorldShutdownStep second)
    {
        int const firstIndex = GetShutdownStepIndex(first);
        int const secondIndex = GetShutdownStepIndex(second);
        return firstIndex >= 0 && secondIndex >= 0 && firstIndex < secondIndex;
    }
}
}
