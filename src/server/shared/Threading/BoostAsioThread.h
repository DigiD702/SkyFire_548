/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_BOOST_ASIO_THREAD_H
#define SF_BOOST_ASIO_THREAD_H

#include "Threading/BoostAsioExecutor.h"

#include <atomic>
#include <functional>
#include <thread>
#include <utility>

namespace Skyfire
{
namespace Asio
{
    class IoContextThread
    {
    public:
        typedef std::function<void()> Hook;

        IoContextThread() : _running(false) { }

        ~IoContextThread()
        {
            Join();
        }

        bool IsRunning() const { return _running; }

        int Start(IoContextExecutor& executor, Hook preRun = Hook(), Hook postRun = Hook())
        {
            bool expected = false;
            if (!_running.compare_exchange_strong(expected, true))
                return -1;

            _preRun = std::move(preRun);
            _postRun = std::move(postRun);

            try
            {
                _thread = std::thread(&IoContextThread::Run, this, &executor);
            }
            catch (...)
            {
                _preRun = Hook();
                _postRun = Hook();
                _running = false;
                return -1;
            }

            return 0;
        }

        int Join()
        {
            if (_thread.joinable())
                _thread.join();

            _preRun = Hook();
            _postRun = Hook();
            _running = false;
            return 0;
        }

    private:
        void Run(IoContextExecutor* executor)
        {
            if (_preRun)
                _preRun();

            executor->Run();

            if (_postRun)
                _postRun();
        }

        std::thread _thread;
        Hook _preRun;
        Hook _postRun;
        std::atomic<bool> _running;
    };
}
}

#endif
