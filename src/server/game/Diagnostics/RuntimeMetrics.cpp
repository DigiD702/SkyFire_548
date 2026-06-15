/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "RuntimeMetrics.h"

#include <sstream>

namespace
{
    void StoreMax(std::atomic<uint32>& target, uint32 value)
    {
        uint32 current = target.load(std::memory_order_relaxed);
        while (current < value &&
            !target.compare_exchange_weak(current, value, std::memory_order_relaxed, std::memory_order_relaxed))
        {
        }
    }
}

namespace Skyfire
{
namespace Diagnostics
{
    RuntimeSampleSnapshot::RuntimeSampleSnapshot()
        : SampleCount(0), Last(0), Average(0), Maximum(0) { }

    MapUpdaterMetricsSnapshot::MapUpdaterMetricsSnapshot()
        : Scheduled(0), Completed(0), ScheduleFailures(0), Pending(0), PendingHighWater(0), Wait() { }

    WorldSessionMetricsSnapshot::WorldSessionMetricsSnapshot()
        : PacketsQueued(0), PacketsProcessed(0), QueueDepth(0), QueueDepthHighWater(0) { }

    RuntimeMetricsSnapshot::RuntimeMetricsSnapshot()
        : WorldUpdate(), MapUpdatePasses(), MapUpdater(), WorldSession() { }

    RuntimeMetrics::RuntimeSample::RuntimeSample()
        : _sampleCount(0), _total(0), _last(0), _maximum(0) { }

    void RuntimeMetrics::RuntimeSample::Reset()
    {
        _sampleCount.store(0, std::memory_order_relaxed);
        _total.store(0, std::memory_order_relaxed);
        _last.store(0, std::memory_order_relaxed);
        _maximum.store(0, std::memory_order_relaxed);
    }

    void RuntimeMetrics::RuntimeSample::Record(uint32 value)
    {
        _sampleCount.fetch_add(1, std::memory_order_relaxed);
        _total.fetch_add(value, std::memory_order_relaxed);
        _last.store(value, std::memory_order_relaxed);
        StoreMax(_maximum, value);
    }

    RuntimeSampleSnapshot RuntimeMetrics::RuntimeSample::Snapshot() const
    {
        RuntimeSampleSnapshot snapshot;
        snapshot.SampleCount = _sampleCount.load(std::memory_order_relaxed);
        snapshot.Last = _last.load(std::memory_order_relaxed);
        snapshot.Maximum = _maximum.load(std::memory_order_relaxed);

        uint64 const total = _total.load(std::memory_order_relaxed);
        snapshot.Average = snapshot.SampleCount ? static_cast<uint32>(total / snapshot.SampleCount) : 0;

        return snapshot;
    }

    RuntimeMetrics::RuntimeMetrics()
        : _worldUpdate(),
          _mapUpdatePasses(),
          _mapUpdateWait(),
          _mapUpdateScheduled(0),
          _mapUpdateCompleted(0),
          _mapUpdateScheduleFailures(0),
          _mapUpdatePending(0),
          _mapUpdatePendingHighWater(0),
          _worldSessionPacketsQueued(0),
          _worldSessionPacketsProcessed(0),
          _worldSessionQueueDepth(0),
          _worldSessionQueueDepthHighWater(0) { }

    void RuntimeMetrics::Reset()
    {
        _worldUpdate.Reset();
        _mapUpdatePasses.Reset();
        _mapUpdateWait.Reset();
        _mapUpdateScheduled.store(0, std::memory_order_relaxed);
        _mapUpdateCompleted.store(0, std::memory_order_relaxed);
        _mapUpdateScheduleFailures.store(0, std::memory_order_relaxed);
        _mapUpdatePending.store(0, std::memory_order_relaxed);
        _mapUpdatePendingHighWater.store(0, std::memory_order_relaxed);
        _worldSessionPacketsQueued.store(0, std::memory_order_relaxed);
        _worldSessionPacketsProcessed.store(0, std::memory_order_relaxed);
        _worldSessionQueueDepth.store(0, std::memory_order_relaxed);
        _worldSessionQueueDepthHighWater.store(0, std::memory_order_relaxed);
    }

    void RuntimeMetrics::RecordWorldUpdate(uint32 diffMs)
    {
        _worldUpdate.Record(diffMs);
    }

    void RuntimeMetrics::RecordMapUpdatePass(uint32 mapCount)
    {
        _mapUpdatePasses.Record(mapCount);
    }

    void RuntimeMetrics::RecordMapUpdateScheduled(uint32 pendingRequests)
    {
        _mapUpdateScheduled.fetch_add(1, std::memory_order_relaxed);
        _mapUpdatePending.store(pendingRequests, std::memory_order_relaxed);
        StoreMax(_mapUpdatePendingHighWater, pendingRequests);
    }

    void RuntimeMetrics::RecordMapUpdateCompleted(uint32 pendingRequests)
    {
        _mapUpdateCompleted.fetch_add(1, std::memory_order_relaxed);
        _mapUpdatePending.store(pendingRequests, std::memory_order_relaxed);
    }

    void RuntimeMetrics::RecordMapUpdateScheduleFailed(uint32 pendingRequests)
    {
        _mapUpdateScheduleFailures.fetch_add(1, std::memory_order_relaxed);
        _mapUpdatePending.store(pendingRequests, std::memory_order_relaxed);
    }

    void RuntimeMetrics::RecordMapUpdateWait(uint32 waitMs)
    {
        _mapUpdateWait.Record(waitMs);
    }

    void RuntimeMetrics::RecordWorldSessionPacketQueued(uint32 queueDepth)
    {
        _worldSessionPacketsQueued.fetch_add(1, std::memory_order_relaxed);
        _worldSessionQueueDepth.store(queueDepth, std::memory_order_relaxed);
        StoreMax(_worldSessionQueueDepthHighWater, queueDepth);
    }

    void RuntimeMetrics::RecordWorldSessionPacketProcessed(uint32 queueDepth)
    {
        _worldSessionPacketsProcessed.fetch_add(1, std::memory_order_relaxed);
        _worldSessionQueueDepth.store(queueDepth, std::memory_order_relaxed);
    }

    RuntimeMetricsSnapshot RuntimeMetrics::Snapshot() const
    {
        RuntimeMetricsSnapshot snapshot;
        snapshot.WorldUpdate = _worldUpdate.Snapshot();
        snapshot.MapUpdatePasses = _mapUpdatePasses.Snapshot();
        snapshot.MapUpdater.Scheduled = _mapUpdateScheduled.load(std::memory_order_relaxed);
        snapshot.MapUpdater.Completed = _mapUpdateCompleted.load(std::memory_order_relaxed);
        snapshot.MapUpdater.ScheduleFailures = _mapUpdateScheduleFailures.load(std::memory_order_relaxed);
        snapshot.MapUpdater.Pending = _mapUpdatePending.load(std::memory_order_relaxed);
        snapshot.MapUpdater.PendingHighWater = _mapUpdatePendingHighWater.load(std::memory_order_relaxed);
        snapshot.MapUpdater.Wait = _mapUpdateWait.Snapshot();
        snapshot.WorldSession.PacketsQueued = _worldSessionPacketsQueued.load(std::memory_order_relaxed);
        snapshot.WorldSession.PacketsProcessed = _worldSessionPacketsProcessed.load(std::memory_order_relaxed);
        snapshot.WorldSession.QueueDepth = _worldSessionQueueDepth.load(std::memory_order_relaxed);
        snapshot.WorldSession.QueueDepthHighWater = _worldSessionQueueDepthHighWater.load(std::memory_order_relaxed);

        return snapshot;
    }

    RuntimeMetrics& GetRuntimeMetrics()
    {
        static RuntimeMetrics metrics;
        return metrics;
    }

    std::vector<std::string> FormatRuntimeMetricLines(RuntimeMetricsSnapshot const& snapshot)
    {
        std::vector<std::string> lines;
        lines.reserve(3);

        std::ostringstream worldLine;
        worldLine << "Runtime metrics - World update: samples " << snapshot.WorldUpdate.SampleCount
            << ", last " << snapshot.WorldUpdate.Last << " ms"
            << ", avg " << snapshot.WorldUpdate.Average << " ms"
            << ", max " << snapshot.WorldUpdate.Maximum << " ms";
        lines.push_back(worldLine.str());

        std::ostringstream mapLine;
        mapLine << "Runtime metrics - Map updater: scheduled " << snapshot.MapUpdater.Scheduled
            << ", completed " << snapshot.MapUpdater.Completed
            << ", pending " << snapshot.MapUpdater.Pending
            << ", high-water " << snapshot.MapUpdater.PendingHighWater
            << ", failures " << snapshot.MapUpdater.ScheduleFailures
            << ", waits " << snapshot.MapUpdater.Wait.SampleCount
            << ", wait avg " << snapshot.MapUpdater.Wait.Average << " ms"
            << ", wait max " << snapshot.MapUpdater.Wait.Maximum << " ms"
            << ", map pass avg " << snapshot.MapUpdatePasses.Average
            << ", map pass max " << snapshot.MapUpdatePasses.Maximum;
        lines.push_back(mapLine.str());

        std::ostringstream packetLine;
        packetLine << "Runtime metrics - Packet queue: queued " << snapshot.WorldSession.PacketsQueued
            << ", processed " << snapshot.WorldSession.PacketsProcessed
            << ", depth " << snapshot.WorldSession.QueueDepth
            << ", high-water " << snapshot.WorldSession.QueueDepthHighWater;
        lines.push_back(packetLine.str());

        return lines;
    }
}
}
