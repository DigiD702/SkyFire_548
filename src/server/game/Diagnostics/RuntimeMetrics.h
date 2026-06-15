/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SKYFIRE_RUNTIME_METRICS_H
#define SKYFIRE_RUNTIME_METRICS_H

#include "Define.h"

#include <atomic>
#include <string>
#include <vector>

namespace Skyfire
{
namespace Diagnostics
{
    struct RuntimeSampleSnapshot
    {
        RuntimeSampleSnapshot();

        uint64 SampleCount;
        uint32 Last;
        uint32 Average;
        uint32 Maximum;
    };

    struct MapUpdaterMetricsSnapshot
    {
        MapUpdaterMetricsSnapshot();

        uint64 Scheduled;
        uint64 Completed;
        uint64 ScheduleFailures;
        uint32 Pending;
        uint32 PendingHighWater;
        RuntimeSampleSnapshot Wait;
    };

    struct WorldSessionMetricsSnapshot
    {
        WorldSessionMetricsSnapshot();

        uint64 PacketsQueued;
        uint64 PacketsProcessed;
        uint32 QueueDepth;
        uint32 QueueDepthHighWater;
    };

    struct RuntimeMetricsSnapshot
    {
        RuntimeMetricsSnapshot();

        RuntimeSampleSnapshot WorldUpdate;
        RuntimeSampleSnapshot MapUpdatePasses;
        MapUpdaterMetricsSnapshot MapUpdater;
        WorldSessionMetricsSnapshot WorldSession;
    };

    class RuntimeMetrics
    {
    public:
        RuntimeMetrics();

        void Reset();

        void RecordWorldUpdate(uint32 diffMs);
        void RecordMapUpdatePass(uint32 mapCount);
        void RecordMapUpdateScheduled(uint32 pendingRequests);
        void RecordMapUpdateCompleted(uint32 pendingRequests);
        void RecordMapUpdateScheduleFailed(uint32 pendingRequests);
        void RecordMapUpdateWait(uint32 waitMs);
        void RecordWorldSessionPacketQueued(uint32 queueDepth);
        void RecordWorldSessionPacketProcessed(uint32 queueDepth);

        RuntimeMetricsSnapshot Snapshot() const;

    private:
        class RuntimeSample
        {
        public:
            RuntimeSample();

            void Reset();
            void Record(uint32 value);
            RuntimeSampleSnapshot Snapshot() const;

        private:
            std::atomic<uint64> _sampleCount;
            std::atomic<uint64> _total;
            std::atomic<uint32> _last;
            std::atomic<uint32> _maximum;
        };

        RuntimeSample _worldUpdate;
        RuntimeSample _mapUpdatePasses;
        RuntimeSample _mapUpdateWait;
        std::atomic<uint64> _mapUpdateScheduled;
        std::atomic<uint64> _mapUpdateCompleted;
        std::atomic<uint64> _mapUpdateScheduleFailures;
        std::atomic<uint32> _mapUpdatePending;
        std::atomic<uint32> _mapUpdatePendingHighWater;
        std::atomic<uint64> _worldSessionPacketsQueued;
        std::atomic<uint64> _worldSessionPacketsProcessed;
        std::atomic<uint32> _worldSessionQueueDepth;
        std::atomic<uint32> _worldSessionQueueDepthHighWater;
    };

    RuntimeMetrics& GetRuntimeMetrics();
    std::vector<std::string> FormatRuntimeMetricLines(RuntimeMetricsSnapshot const& snapshot);
}
}

#endif
