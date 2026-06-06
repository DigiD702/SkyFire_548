/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "DatabaseQueue.h"
#include "DatabaseWorker.h"
#include "SQLOperation.h"

#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

namespace
{
    class RecordingOperation : public SQLOperation
    {
    public:
        RecordingOperation(std::vector<int>& completed, std::mutex& completedLock, int value, MySQLConnection* expectedConnection)
            : _completed(completed), _completedLock(completedLock), _value(value), _expectedConnection(expectedConnection)
        {
        }

        bool Execute() override
        {
            if (m_conn != _expectedConnection)
                return false;

            std::lock_guard<std::mutex> guard(_completedLock);
            _completed.push_back(_value);
            return true;
        }

    private:
        std::vector<int>& _completed;
        std::mutex& _completedLock;
        int _value;
        MySQLConnection* _expectedConnection;
    };
}

bool TestQueueRunDrainsQueuedOperations()
{
    Skyfire::DatabaseQueue queue;

    std::vector<int> completed;
    std::mutex completedLock;
    MySQLConnection* connection = reinterpret_cast<MySQLConnection*>(0x1);
    int runResult = -1;

    std::thread worker([&queue, connection, &runResult]
    {
        runResult = queue.run(connection);
    });

    queue.enqueue(new RecordingOperation(completed, completedLock, 1, connection));
    queue.enqueue(new RecordingOperation(completed, completedLock, 2, connection));
    queue.close();
    worker.join();

    if (runResult != 0)
    {
        std::cerr << "DatabaseQueue::run returned " << runResult << '\n';
        return false;
    }

    if (completed != std::vector<int>{ 1, 2 })
    {
        std::cerr << "DatabaseQueue did not drain queued operations before closing\n";
        return false;
    }

    return true;
}

bool TestDatabaseWorkerRunsQueueWithConnection()
{
    Skyfire::DatabaseQueue queue;

    std::vector<int> completed;
    std::mutex completedLock;
    MySQLConnection* connection = reinterpret_cast<MySQLConnection*>(0x2);

    DatabaseWorker worker(&queue, connection);

    queue.enqueue(new RecordingOperation(completed, completedLock, 3, connection));
    queue.enqueue(new RecordingOperation(completed, completedLock, 4, connection));
    queue.close();

    if (worker.wait() != 0)
    {
        std::cerr << "DatabaseWorker did not join cleanly\n";
        return false;
    }

    if (completed != std::vector<int>{ 3, 4 })
    {
        std::cerr << "DatabaseWorker did not drain queued operations with its connection\n";
        return false;
    }

    return true;
}

int main()
{
    if (!TestQueueRunDrainsQueuedOperations())
        return 1;

    if (!TestDatabaseWorkerRunsQueueWithConnection())
        return 1;

    return 0;
}
