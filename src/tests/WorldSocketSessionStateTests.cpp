/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "WorldSocketSessionState.h"

#include <cstdint>
#include <iostream>

namespace
{
    WorldSession* FakeSession(uintptr_t value)
    {
        return reinterpret_cast<WorldSession*>(value);
    }
}

int main()
{
    WorldSocketSessionState state;
    WorldSession* first = FakeSession(0x1);
    WorldSession* second = FakeSession(0x2);

    if (state.HasSession())
    {
        std::cerr << "New socket session state started with an attached session\n";
        return 1;
    }

    if (!state.Attach(first))
    {
        std::cerr << "Initial session attach failed\n";
        return 1;
    }

    if (!state.HasSession())
    {
        std::cerr << "Attached session was not visible\n";
        return 1;
    }

    if (state.Attach(second))
    {
        std::cerr << "Second session attach replaced an active session\n";
        return 1;
    }

    bool sawFirst = false;
    state.WithSession([&sawFirst, first](WorldSession* session)
    {
        sawFirst = session == first;
    });

    if (!sawFirst)
    {
        std::cerr << "Session callback did not receive the attached session\n";
        return 1;
    }

    if (state.Detach(second))
    {
        std::cerr << "Detach accepted a non-owning session pointer\n";
        return 1;
    }

    if (!state.HasSession())
    {
        std::cerr << "Failed detach cleared the active session\n";
        return 1;
    }

    if (!state.Detach(first))
    {
        std::cerr << "Detach rejected the owning session pointer\n";
        return 1;
    }

    if (state.HasSession())
    {
        std::cerr << "Detached session remained visible\n";
        return 1;
    }

    return 0;
}
