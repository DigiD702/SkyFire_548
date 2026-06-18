/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_WORLDSOCKETSESSIONSTATE_H
#define SF_WORLDSOCKETSESSIONSTATE_H

#include "Platform/Threading.h"

#include <utility>

class WorldSession;

class WorldSocketSessionState
{
public:
    WorldSocketSessionState() : _session(nullptr) { }

    bool Attach(WorldSession* session)
    {
        if (!session)
            return false;

        GuardType guard(_lock);
        if (_session)
            return false;

        _session = session;
        return true;
    }

    bool Detach(WorldSession* session)
    {
        if (!session)
            return false;

        GuardType guard(_lock);
        if (_session != session)
            return false;

        _session = nullptr;
        return true;
    }

    bool HasSession() const
    {
        GuardType guard(_lock);
        return _session != nullptr;
    }

    template<class Callback>
    auto WithSession(Callback&& callback) const -> decltype(callback(static_cast<WorldSession*>(nullptr)))
    {
        GuardType guard(_lock);
        return callback(_session);
    }

private:
    typedef Skyfire::Mutex LockType;
    typedef std::lock_guard<LockType> GuardType;

    mutable LockType _lock;
    WorldSession* _session;
};

#endif
