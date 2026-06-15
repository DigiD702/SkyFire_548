/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "DatabaseEnv.h"
#include "DelayExecutor.h"
#include "Log.h"
#include "Map.h"
#include "MapUpdater.h"
#include "RuntimeMetrics.h"
#include "Util.h"

class WDBThreadStartReq1 : public DelayTask
{
public:
    WDBThreadStartReq1() { }

    virtual int call() { return 0; }
};

class WDBThreadEndReq1 : public DelayTask
{
public:
    WDBThreadEndReq1() { }

    virtual int call() { return 0; }
};

class MapUpdateRequest : public DelayTask
{
private:
    Map& m_map;
    MapUpdater& m_updater;
    uint32 m_diff;

public:
    MapUpdateRequest(Map& m, MapUpdater& u, uint32 d)
        : m_map(m), m_updater(u), m_diff(d) { }

    virtual int call()
    {
        m_map.Update(m_diff);
        m_updater.update_finished();
        return 0;
    }
};

MapUpdater::MapUpdater() :
    m_executor(), pending_requests(0) { }

MapUpdater::~MapUpdater()
{
    deactivate();
}

int MapUpdater::activate(size_t num_threads)
{
    return m_executor.start((int)num_threads, std::unique_ptr<DelayTask>(new WDBThreadStartReq1), std::unique_ptr<DelayTask>(new WDBThreadEndReq1));
}

int MapUpdater::deactivate()
{
    wait();
    return m_executor.deactivate();
}

int MapUpdater::wait()
{
    uint32 const waitStart = getMSTime();
    bool waited = false;
    std::unique_lock<std::mutex> ulock(Lock);

    while (pending_requests > 0)
    {
        waited = true;
        condition.wait(ulock);
    }

    ulock.unlock();

    if (waited)
        Skyfire::Diagnostics::GetRuntimeMetrics().RecordMapUpdateWait(getMSTimeDiff(waitStart, getMSTime()));

    return 0;
}

int MapUpdater::schedule_update(Map& map, uint32 diff)
{
    std::lock_guard<std::mutex> guard(Lock);

    ++pending_requests;
    Skyfire::Diagnostics::GetRuntimeMetrics().RecordMapUpdateScheduled(static_cast<uint32>(pending_requests));

    if (m_executor.execute(std::unique_ptr<DelayTask>(new MapUpdateRequest(map, *this, diff))) == -1)
    {
        SF_LOG_ERROR("misc", "Failed to schedule Map Update");

        --pending_requests;
        Skyfire::Diagnostics::GetRuntimeMetrics().RecordMapUpdateScheduleFailed(static_cast<uint32>(pending_requests));
        return -1;
    }

    return 0;
}

bool MapUpdater::activated()
{
    return m_executor.activated();
}

void MapUpdater::update_finished()
{
    std::lock_guard<std::mutex> guard(Lock);

    if (pending_requests == 0)
    {
        SF_LOG_ERROR("misc", "MapUpdater::update_finished BUG, report to devs");
        return;
    }

    --pending_requests;
    Skyfire::Diagnostics::GetRuntimeMetrics().RecordMapUpdateCompleted(static_cast<uint32>(pending_requests));

    condition.notify_all();
}
