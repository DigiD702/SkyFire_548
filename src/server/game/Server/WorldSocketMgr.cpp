/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

/** \file WorldSocketMgr.cpp
*  \ingroup u2w
*  \author Derex <derex101@gmail.com>
*/

#include "WorldSocketMgr.h"

#include <atomic>
#include <chrono>
#include <set>
#include <thread>

#include "Common.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ScriptMgr.h"
#include "WorldSocket.h"
#include "WorldSocketAcceptor.h"
#include <boost/asio/socket_base.hpp>
#include <boost/asio/steady_timer.hpp>
#include <boost/system/error_code.hpp>

/**
* This is a helper class to WorldSocketMgr, that manages
* network threads, and assigning connections from acceptor thread
* to other network threads
*/
class ReactorRunnable
{
public:
    ReactorRunnable() :
        m_IoContext(),
        m_Timer(m_IoContext),
        m_Connections(0),
        m_Stopped(false)
    {
    }

    virtual ~ReactorRunnable()
    {
        Stop();
        Wait();
    }

    void Stop()
    {
        m_Stopped = true;
    }

    int Start()
    {
        if (m_Thread.joinable())
            return -1;

        try
        {
            m_Thread = std::thread(&ReactorRunnable::Run, this);
        }
        catch (...)
        {
            return -1;
        }

        return 0;
    }

    void Wait()
    {
        if (m_Thread.joinable())
            m_Thread.join();
    }

    long Connections()
    {
        return m_Connections.load();
    }

    int AddSocket(WorldSocket* sock)
    {
        std::lock_guard<std::mutex> guard(m_NewSockets_Lock);

        ++m_Connections;
        sock->AddReference();
        m_NewSockets.insert(sock);

        sScriptMgr->OnSocketOpen(sock);

        return 0;
    }

protected:
    void AddNewSockets()
    {
        std::lock_guard<std::mutex> guard(m_NewSockets_Lock);

        if (m_NewSockets.empty())
            return;

        for (SocketSet::const_iterator i = m_NewSockets.begin(); i != m_NewSockets.end(); ++i)
        {
            WorldSocket* sock = (*i);

            if (sock->IsClosed())
            {
                sScriptMgr->OnSocketClose(sock, true);

                sock->RemoveReference();
                --m_Connections;
            }
            else
                m_Sockets.insert(sock);
        }

        m_NewSockets.clear();
    }

    void Run()
    {
        SF_LOG_DEBUG("misc", "Network Thread Starting");

        SocketSet::iterator i, t;

        while (!m_Stopped)
        {
            AddNewSockets();

            boost::system::error_code ignored;
            m_Timer.expires_after(std::chrono::milliseconds(10));
            m_Timer.wait(ignored);

            for (i = m_Sockets.begin(); i != m_Sockets.end();)
            {
                int result = 0;
                WorldSocket* socket = *i;

                if (socket->IsClosed())
                    result = -1;
                else
                {
                    do
                        result = socket->Read();
                    while (result > 0);

                    if (result != -1 && socket->HasPendingOutput())
                        result = socket->Update();
                }

                if (result == -1)
                {
                    t = i;
                    ++i;

                    socket->CloseSocket();

                    sScriptMgr->OnSocketClose(socket, false);

                    socket->RemoveReference();
                    --m_Connections;
                    m_Sockets.erase(t);
                }
                else
                    ++i;
            }
        }

        SF_LOG_DEBUG("misc", "Network Thread exits");
    }

private:
    typedef std::atomic<long> AtomicInt;
    typedef std::set<WorldSocket*> SocketSet;

    boost::asio::io_context m_IoContext;
    boost::asio::steady_timer m_Timer;
    AtomicInt m_Connections;
    std::atomic<bool> m_Stopped;
    std::thread m_Thread;

    SocketSet m_Sockets;

    SocketSet m_NewSockets;
    std::mutex m_NewSockets_Lock;
};

WorldSocketMgr::WorldSocketMgr() :
    m_NetThreads(0),
    m_NetThreadsCount(0),
    m_SockOutKBuff(-1),
    m_SockOutUBuff(65536),
    m_UseNoDelay(true),
    m_Acceptor(0) { }

WorldSocketMgr::~WorldSocketMgr()
{
    delete[] m_NetThreads;
    delete m_Acceptor;
}

int
WorldSocketMgr::StartReactiveIO(uint16 port, const char* address)
{
    m_UseNoDelay = sConfigMgr->GetBoolDefault("Network.TcpNodelay", true);

    int num_threads = sConfigMgr->GetIntDefault("Network.Threads", 1);

    if (num_threads <= 0)
    {
        SF_LOG_ERROR("misc", "Network.Threads is wrong in your config file");
        return -1;
    }

    m_NetThreadsCount = static_cast<size_t> (num_threads);

    m_NetThreads = new ReactorRunnable[m_NetThreadsCount];

    // -1 means use default
    m_SockOutKBuff = sConfigMgr->GetIntDefault("Network.OutKBuff", -1);

    m_SockOutUBuff = sConfigMgr->GetIntDefault("Network.OutUBuff", 65536);

    if (m_SockOutUBuff <= 0)
    {
        SF_LOG_ERROR("misc", "Network.OutUBuff is wrong in your config file");
        return -1;
    }

    m_Acceptor = new WorldSocketAcceptor;

    if (!m_Acceptor->Open(port, address))
    {
        SF_LOG_ERROR("misc", "Failed to open acceptor, check if the port is free");
        return -1;
    }

    for (size_t i = 0; i < m_NetThreadsCount; ++i)
        m_NetThreads[i].Start();

    return 0;
}

int
WorldSocketMgr::StartNetwork(uint16 port, const char* address)
{
    if (StartReactiveIO(port, address) == -1)
        return -1;

    sScriptMgr->OnNetworkStart();

    return 0;
}

void
WorldSocketMgr::StopNetwork()
{
    if (m_Acceptor)
    {
        m_Acceptor->Close();
    }

    if (m_NetThreadsCount != 0)
    {
        for (size_t i = 0; i < m_NetThreadsCount; ++i)
            m_NetThreads[i].Stop();
    }

    Wait();

    sScriptMgr->OnNetworkStop();
}

void
WorldSocketMgr::Wait()
{
    if (m_NetThreadsCount != 0)
    {
        for (size_t i = 0; i < m_NetThreadsCount; ++i)
            m_NetThreads[i].Wait();
    }
}

int
WorldSocketMgr::OnSocketOpen(WorldSocket* sock)
{
    // set some options here
    if (m_SockOutKBuff >= 0)
    {
        boost::system::error_code error;
        sock->m_Socket->set_option(boost::asio::socket_base::send_buffer_size(m_SockOutKBuff), error);
        if (error)
        {
            SF_LOG_ERROR("misc", "WorldSocketMgr::OnSocketOpen set_option SO_SNDBUF error = %d", error.value());
            return -1;
        }
    }

    // Set TCP_NODELAY.
    if (m_UseNoDelay)
    {
        boost::system::error_code error;
        sock->m_Socket->set_option(boost::asio::ip::tcp::no_delay(true), error);
        if (error)
        {
            SF_LOG_ERROR("misc", "WorldSocketMgr::OnSocketOpen: set_option TCP_NODELAY error = %d", error.value());
            return -1;
        }
    }

    sock->m_OutBufferSize = static_cast<size_t> (m_SockOutUBuff);

    size_t min = 0;

    ASSERT(m_NetThreadsCount >= 1);

    for (size_t i = 1; i < m_NetThreadsCount; ++i)
        if (m_NetThreads[i].Connections() < m_NetThreads[min].Connections())
            min = i;

    if (sock->Initialize() == -1)
        return -1;

    return m_NetThreads[min].AddSocket(sock);
}
