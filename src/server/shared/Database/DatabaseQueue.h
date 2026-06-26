/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef _DATABASEQUEUE_H
#define _DATABASEQUEUE_H

#include <memory>

class DatabaseWorker;
class MySQLConnection;
class SQLOperation;

namespace Skyfire
{
    namespace Asio
    {
        class IoContextExecutor;
    }

    class DatabaseQueue
    {
    public:
        DatabaseQueue();
        ~DatabaseQueue();

        void enqueue(SQLOperation* operation);
        int run(MySQLConnection* connection);
        void close();
        void wait();

    private:
        struct Impl;

        std::unique_ptr<Impl> _impl;

        Asio::IoContextExecutor& GetExecutor();
        void BindConnection(MySQLConnection* connection);
        void ClearConnection();

        friend class ::DatabaseWorker;

        DatabaseQueue(DatabaseQueue const& right) = delete;
        DatabaseQueue& operator=(DatabaseQueue const& right) = delete;
    };
}

#endif
