/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Threading/BoostAsioExecutor.h"
#include "Threading/BoostAsioThread.h"

#include <iostream>

int main()
{
    Skyfire::Asio::IoContextExecutor executor;
    Skyfire::Asio::IoContextThread thread;

    int preRunCount = 0;
    int postRunCount = 0;
    int workCount = 0;

    executor.KeepAlive();

    if (thread.Join() != 0)
    {
        std::cerr << "IoContextThread::Join was not harmless before start\n";
        return 1;
    }

    if (thread.Start(executor,
        [&preRunCount]
        {
            ++preRunCount;
        },
        [&postRunCount]
        {
            ++postRunCount;
        }) != 0)
    {
        std::cerr << "IoContextThread did not start\n";
        return 1;
    }

    if (thread.Start(executor) != -1)
    {
        std::cerr << "IoContextThread allowed double start\n";
        return 1;
    }

    executor.Post([&workCount] { ++workCount; });
    executor.Post([&workCount] { ++workCount; });
    executor.ResetWork();

    if (thread.Join() != 0)
    {
        std::cerr << "IoContextThread did not join\n";
        return 1;
    }

    if (preRunCount != 1 || postRunCount != 1 || workCount != 2)
    {
        std::cerr << "IoContextThread did not run hooks and queued work\n";
        return 1;
    }

    executor.Restart();
    executor.KeepAlive();

    if (thread.Start(executor) != 0)
    {
        std::cerr << "IoContextThread did not restart\n";
        return 1;
    }

    executor.Post([&workCount] { ++workCount; });
    executor.ResetWork();

    if (thread.Join() != 0)
    {
        std::cerr << "IoContextThread did not join after restart\n";
        return 1;
    }

    if (workCount != 3)
    {
        std::cerr << "IoContextThread did not run restarted work\n";
        return 1;
    }

    return 0;
}
