/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "DelayExecutor.h"
#include "Platform/Singleton.h"
#include "Threading/BoostAsioThreadGroup.h"

#include <atomic>
#include <mutex>
#include <utility>

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

struct DelayExecutor::Impl
{
    Impl()
        : activated(false),
          submitted(0),
          completed(0),
          rejected(0),
          backlog(0),
          backlogHighWater(0)
    {
    }

    Skyfire::Asio::IoContextThreadGroup threadGroup;
    std::unique_ptr<DelayTask> preSvcHook;
    std::unique_ptr<DelayTask> postSvcHook;
    std::mutex stateLock;
    bool activated;
    std::atomic<uint64> submitted;
    std::atomic<uint64> completed;
    std::atomic<uint64> rejected;
    std::atomic<uint32> backlog;
    std::atomic<uint32> backlogHighWater;
};

DelayExecutor* DelayExecutor::instance()
{
    return Skyfire::Singleton<DelayExecutor, Skyfire::Mutex>::instance();
}

DelayExecutor::DelayExecutor()
    : impl_(new Impl) { }

DelayExecutor::~DelayExecutor()
{
    deactivate();
}

int DelayExecutor::deactivate()
{
    {
        std::lock_guard<std::mutex> guard(impl_->stateLock);

        if (!impl_->activated)
            return 0;

        impl_->activated = false;
        impl_->threadGroup.Drain();
    }

    impl_->threadGroup.Join();
    impl_->preSvcHook.reset();
    impl_->postSvcHook.reset();

    return 0;
}

int DelayExecutor::svc()
{
    if (impl_->preSvcHook)
        impl_->preSvcHook->call();

    impl_->threadGroup.GetExecutor().Run();

    if (impl_->postSvcHook)
        impl_->postSvcHook->call();

    return 0;
}

int DelayExecutor::start(int num_threads, std::unique_ptr<DelayTask> pre_svc_hook, std::unique_ptr<DelayTask> post_svc_hook)
{
    if (activated())
        return -1;

    if (num_threads < 1)
        return -1;

    impl_->preSvcHook = std::move(pre_svc_hook);
    impl_->postSvcHook = std::move(post_svc_hook);

    int const started = impl_->threadGroup.Start(static_cast<size_t>(num_threads),
        [this]
        {
            if (impl_->preSvcHook)
                impl_->preSvcHook->call();
        },
        [this]
        {
            if (impl_->postSvcHook)
                impl_->postSvcHook->call();
        });

    if (started == -1)
    {
        impl_->preSvcHook.reset();
        impl_->postSvcHook.reset();
        return -1;
    }

    activated(true);

    return 0;
}

int DelayExecutor::execute(std::unique_ptr<DelayTask> new_req)
{
    auto reject = [this]
    {
        impl_->rejected.fetch_add(1, std::memory_order_relaxed);
        return -1;
    };

    if (!new_req)
        return reject();

    {
        std::lock_guard<std::mutex> guard(impl_->stateLock);

        if (!impl_->activated)
            return reject();
    }

    impl_->submitted.fetch_add(1, std::memory_order_relaxed);
    uint32 const backlog = impl_->backlog.fetch_add(1, std::memory_order_relaxed) + 1;
    StoreMax(impl_->backlogHighWater, backlog);

    impl_->threadGroup.GetExecutor().Post(
        [this, task = std::move(new_req)]() mutable
        {
            task->call();
            impl_->completed.fetch_add(1, std::memory_order_relaxed);
            impl_->backlog.fetch_sub(1, std::memory_order_relaxed);
        });

    return 0;
}

bool DelayExecutor::activated()
{
    std::lock_guard<std::mutex> guard(impl_->stateLock);
    return impl_->activated;
}

void DelayExecutor::activated(bool s)
{
    std::lock_guard<std::mutex> guard(impl_->stateLock);
    impl_->activated = s;
}

DelayExecutorMetricsSnapshot DelayExecutor::GetMetricsSnapshot() const
{
    DelayExecutorMetricsSnapshot snapshot;
    snapshot.Submitted = impl_->submitted.load(std::memory_order_relaxed);
    snapshot.Completed = impl_->completed.load(std::memory_order_relaxed);
    snapshot.Rejected = impl_->rejected.load(std::memory_order_relaxed);
    snapshot.Backlog = impl_->backlog.load(std::memory_order_relaxed);
    snapshot.BacklogHighWater = impl_->backlogHighWater.load(std::memory_order_relaxed);

    return snapshot;
}
