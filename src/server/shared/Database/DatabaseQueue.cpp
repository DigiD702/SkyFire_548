/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "DatabaseQueue.h"
#include "SQLOperation.h"
#include "Threading/BoostAsioExecutor.h"

#include <future>
#include <mutex>

namespace Skyfire
{
    namespace
    {
        thread_local MySQLConnection* CurrentDatabaseConnection = nullptr;
    }

    struct DatabaseQueue::Impl
    {
        Impl()
            : executor(), closed(false)
        {
            executor.KeepAlive();
        }

        Skyfire::Asio::IoContextExecutor executor;
        std::mutex stateLock;
        bool closed;
    };

    DatabaseQueue::DatabaseQueue()
        : _impl(new Impl)
    {
    }

    DatabaseQueue::~DatabaseQueue()
    {
        close();
    }

    void DatabaseQueue::enqueue(SQLOperation* operation)
    {
        if (!operation)
            return;

        std::lock_guard<std::mutex> guard(_impl->stateLock);
        if (_impl->closed)
            return;

        _impl->executor.Post(
            [operation]
            {
                operation->SetConnection(CurrentDatabaseConnection);
                operation->call();
                delete operation;
            });
    }

    int DatabaseQueue::run(MySQLConnection* connection)
    {
        if (!connection)
            return -1;

        BindConnection(connection);
        _impl->executor.Run();
        ClearConnection();
        return 0;
    }

    void DatabaseQueue::close()
    {
        std::lock_guard<std::mutex> guard(_impl->stateLock);
        if (_impl->closed)
            return;

        _impl->closed = true;
        _impl->executor.ResetWork();
    }

    void DatabaseQueue::wait()
    {
        std::shared_ptr<std::promise<void> > barrier(new std::promise<void>());
        std::future<void> ready = barrier->get_future();

        {
            std::lock_guard<std::mutex> guard(_impl->stateLock);
            if (_impl->closed)
                return;

            _impl->executor.Post(
                [barrier]
                {
                    barrier->set_value();
                });
        }

        ready.wait();
    }

    Asio::IoContextExecutor& DatabaseQueue::GetExecutor()
    {
        return _impl->executor;
    }

    void DatabaseQueue::BindConnection(MySQLConnection* connection)
    {
        CurrentDatabaseConnection = connection;
    }

    void DatabaseQueue::ClearConnection()
    {
        CurrentDatabaseConnection = nullptr;
    }
}
