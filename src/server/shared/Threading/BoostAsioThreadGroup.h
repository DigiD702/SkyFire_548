/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_BOOST_ASIO_THREAD_GROUP_H
#define SF_BOOST_ASIO_THREAD_GROUP_H

#include "Threading/BoostAsioThread.h"

#include <atomic>
#include <cstddef>
#include <functional>
#include <memory>
#include <utility>
#include <vector>

namespace Skyfire
{
namespace Asio
{
    class IoContextThreadGroup
    {
    public:
        typedef std::function<void()> Hook;

        IoContextThreadGroup() : _executor(), _running(false) { }

        ~IoContextThreadGroup()
        {
            StopAndJoin();
        }

        IoContextExecutor& GetExecutor() { return _executor; }
        boost::asio::io_context& GetIoContext() { return _executor.GetIoContext(); }
        bool IsRunning() const { return _running; }

        int Start(std::size_t threadCount, Hook preRun = Hook(), Hook postRun = Hook())
        {
            if (threadCount == 0)
                return -1;

            bool expected = false;
            if (!_running.compare_exchange_strong(expected, true))
                return -1;

            _executor.Restart();
            _executor.KeepAlive();
            _preRun = std::move(preRun);
            _postRun = std::move(postRun);

            try
            {
                for (std::size_t i = 0; i < threadCount; ++i)
                {
                    std::unique_ptr<IoContextThread> thread(new IoContextThread);
                    if (thread->Start(_executor, _preRun, _postRun) == -1)
                    {
                        StopAndJoin();
                        return -1;
                    }

                    _threads.push_back(std::move(thread));
                }
            }
            catch (...)
            {
                StopAndJoin();
                return -1;
            }

            return 0;
        }

        void Drain()
        {
            _executor.ResetWork();
        }

        void Stop()
        {
            _executor.Stop();
            _executor.ResetWork();
        }

        void Join()
        {
            for (std::unique_ptr<IoContextThread>& thread : _threads)
                thread->Join();

            _threads.clear();
            _preRun = Hook();
            _postRun = Hook();
            _running = false;
        }

        void DrainAndJoin()
        {
            Drain();
            Join();
        }

        void StopAndJoin()
        {
            Stop();
            Join();
        }

    private:
        IoContextExecutor _executor;
        std::vector<std::unique_ptr<IoContextThread> > _threads;
        Hook _preRun;
        Hook _postRun;
        std::atomic<bool> _running;
    };
}
}

#endif
