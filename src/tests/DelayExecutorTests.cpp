/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "DelayExecutor.h"

#include <condition_variable>
#include <chrono>
#include <iostream>
#include <memory>
#include <mutex>
#include <thread>

namespace
{
    class CountingTask : public DelayTask
    {
    public:
        CountingTask(int& count, std::mutex& countLock, std::condition_variable& countChanged)
            : _count(count), _countLock(countLock), _countChanged(countChanged)
        {
        }

        int call() override
        {
            {
                std::lock_guard<std::mutex> guard(_countLock);
                ++_count;
            }

            _countChanged.notify_all();
            return 0;
        }

    private:
        int& _count;
        std::mutex& _countLock;
        std::condition_variable& _countChanged;
    };

    std::unique_ptr<DelayTask> MakeCountingTask(int& count, std::mutex& countLock, std::condition_variable& countChanged)
    {
        return std::unique_ptr<DelayTask>(new CountingTask(count, countLock, countChanged));
    }

    bool WaitForCount(int& count, int expected, std::mutex& countLock, std::condition_variable& countChanged)
    {
        std::unique_lock<std::mutex> lock(countLock);
        return countChanged.wait_for(lock, std::chrono::seconds(2),
            [&count, expected]
            {
                return count >= expected;
            });
    }

    bool WaitForExecutorMetrics(DelayExecutor& executor, uint64 submitted, uint64 completed, uint32 backlog)
    {
        std::chrono::steady_clock::time_point const deadline = std::chrono::steady_clock::now() + std::chrono::seconds(2);
        while (std::chrono::steady_clock::now() < deadline)
        {
            DelayExecutorMetricsSnapshot snapshot = executor.GetMetricsSnapshot();
            if (snapshot.Submitted == submitted && snapshot.Completed == completed && snapshot.Backlog == backlog)
                return true;

            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }

        return false;
    }
}

int main()
{
    DelayExecutor executor;

    if (executor.deactivate() != 0)
    {
        std::cerr << "DelayExecutor::deactivate was not harmless before start\n";
        return 1;
    }

    int executed = 0;
    std::mutex executedLock;
    std::condition_variable executedChanged;

    if (executor.execute(MakeCountingTask(executed, executedLock, executedChanged)) != -1)
    {
        std::cerr << "DelayExecutor accepted work before start\n";
        return 1;
    }

    DelayExecutorMetricsSnapshot rejectedBeforeStart = executor.GetMetricsSnapshot();
    if (rejectedBeforeStart.Rejected != 1)
    {
        std::cerr << "DelayExecutor did not count rejected work before start\n";
        return 1;
    }

    int preHookCalls = 0;
    int postHookCalls = 0;
    std::mutex hookLock;
    std::condition_variable hookChanged;

    if (executor.start(1, MakeCountingTask(preHookCalls, hookLock, hookChanged),
        MakeCountingTask(postHookCalls, hookLock, hookChanged)) != 0)
    {
        std::cerr << "DelayExecutor did not start\n";
        return 1;
    }

    if (!executor.activated())
    {
        std::cerr << "DelayExecutor did not report active after start\n";
        return 1;
    }

    if (!WaitForCount(preHookCalls, 1, hookLock, hookChanged))
    {
        std::cerr << "DelayExecutor did not run the pre-service hook\n";
        return 1;
    }

    if (executor.execute(MakeCountingTask(executed, executedLock, executedChanged)) != 0)
    {
        std::cerr << "DelayExecutor rejected work after start\n";
        return 1;
    }

    DelayExecutorMetricsSnapshot submittedAfterStart = executor.GetMetricsSnapshot();
    if (submittedAfterStart.Submitted != 1 || submittedAfterStart.BacklogHighWater == 0 ||
        submittedAfterStart.BacklogHighWaterEvents != 1)
    {
        std::cerr << "DelayExecutor did not count submitted work or backlog after start\n";
        return 1;
    }

    if (!WaitForCount(executed, 1, executedLock, executedChanged))
    {
        std::cerr << "DelayExecutor did not execute queued work\n";
        return 1;
    }

    if (!WaitForExecutorMetrics(executor, 1, 1, 0))
    {
        std::cerr << "DelayExecutor did not finish executor-side metrics after queued work\n";
        return 1;
    }

    DelayExecutorMetricsSnapshot completedAfterRun = executor.GetMetricsSnapshot();
    if (completedAfterRun.Completed != 1 || completedAfterRun.Backlog != 0 || completedAfterRun.BacklogHighWater != 1)
    {
        std::cerr << "DelayExecutor did not count completed work and backlog drain\n";
        return 1;
    }

    executor.ResetMetrics();

    DelayExecutorMetricsSnapshot resetAfterRun = executor.GetMetricsSnapshot();
    if (resetAfterRun.Submitted != 0 || resetAfterRun.Completed != 0 || resetAfterRun.Rejected != 0 ||
        resetAfterRun.Backlog != 0 || resetAfterRun.BacklogHighWater != 0 || resetAfterRun.BacklogHighWaterEvents != 0)
    {
        std::cerr << "DelayExecutor did not reset metrics counters\n";
        return 1;
    }

    if (executor.deactivate() != 0)
    {
        std::cerr << "DelayExecutor did not deactivate\n";
        return 1;
    }

    if (!WaitForCount(postHookCalls, 1, hookLock, hookChanged))
    {
        std::cerr << "DelayExecutor did not run the post-service hook\n";
        return 1;
    }

    if (executor.activated())
    {
        std::cerr << "DelayExecutor still reported active after deactivate\n";
        return 1;
    }

    if (executor.deactivate() != 0)
    {
        std::cerr << "DelayExecutor::deactivate was not harmless after stop\n";
        return 1;
    }

    if (executor.execute(MakeCountingTask(executed, executedLock, executedChanged)) != -1)
    {
        std::cerr << "DelayExecutor accepted work after deactivate\n";
        return 1;
    }

    DelayExecutorMetricsSnapshot rejectedAfterStop = executor.GetMetricsSnapshot();
    if (rejectedAfterStop.Rejected != 1)
    {
        std::cerr << "DelayExecutor did not count rejected work after deactivate\n";
        return 1;
    }

    if (executor.start(1) != 0)
    {
        std::cerr << "DelayExecutor did not restart\n";
        return 1;
    }

    if (executor.execute(MakeCountingTask(executed, executedLock, executedChanged)) != 0)
    {
        std::cerr << "DelayExecutor rejected work after restart\n";
        return 1;
    }

    if (!WaitForCount(executed, 2, executedLock, executedChanged))
    {
        std::cerr << "DelayExecutor did not execute work after restart\n";
        return 1;
    }

    if (!WaitForExecutorMetrics(executor, 1, 1, 0))
    {
        std::cerr << "DelayExecutor did not finish executor-side metrics after restart\n";
        return 1;
    }

    DelayExecutorMetricsSnapshot completedAfterRestart = executor.GetMetricsSnapshot();
    if (completedAfterRestart.Submitted != 1 || completedAfterRestart.Completed != 1 || completedAfterRestart.Backlog != 0 ||
        completedAfterRestart.BacklogHighWaterEvents != 1)
    {
        std::cerr << "DelayExecutor did not keep cumulative counters after restart\n";
        return 1;
    }

    if (executor.deactivate() != 0)
    {
        std::cerr << "DelayExecutor did not deactivate after restart\n";
        return 1;
    }

    return 0;
}
