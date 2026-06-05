/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Log.h"
#include "Network/BoostAsioUtils.h"
#include "WorldSocketAcceptor.h"
#include "WorldSocketMgr.h"
#include <boost/asio/error.hpp>
#include <boost/system/error_code.hpp>
#include <memory>
#include <utility>

WorldSocketAcceptor::WorldSocketAcceptor() :
    m_IoContext(),
    m_Acceptor(m_IoContext),
    m_Closed(true)
{
}

WorldSocketAcceptor::~WorldSocketAcceptor()
{
    Close();
}

bool WorldSocketAcceptor::Open(uint16 port, const char* address)
{
    if (!Skyfire::Net::OpenTcpAcceptor(m_IoContext, m_Acceptor, port, address, "network", "world"))
        return false;

    m_Closed = false;
    AsyncAccept();

    try
    {
        m_Thread = std::thread([this] { m_IoContext.run(); });
    }
    catch (...)
    {
        Close();
        return false;
    }

    return true;
}

void WorldSocketAcceptor::Close()
{
    bool expected = false;
    if (!m_Closed.compare_exchange_strong(expected, true))
        return;

    Skyfire::Net::CloseTcpAcceptor(m_Acceptor);
    m_IoContext.stop();

    if (m_Thread.joinable())
        m_Thread.join();
}

void WorldSocketAcceptor::Update()
{
}

void WorldSocketAcceptor::AsyncAccept()
{
    if (!m_Acceptor.is_open())
        return;

    ReactorRunnable* reactor = sWorldSocketMgr->SelectNetworkThread();
    std::shared_ptr<boost::asio::ip::tcp::endpoint> remoteEndpoint(new boost::asio::ip::tcp::endpoint);

    m_Acceptor.async_accept(sWorldSocketMgr->GetNetworkIoContext(reactor), *remoteEndpoint,
        [this, reactor, remoteEndpoint](boost::system::error_code const& error, auto socket) mutable
        {
            HandleAccept(reactor, std::move(socket), *remoteEndpoint, error);
        });
}

void WorldSocketAcceptor::HandleAccept(ReactorRunnable* reactor, WorldSocketHandle socket, boost::asio::ip::tcp::endpoint const& remoteEndpoint,
    boost::system::error_code const& error)
{
    if (m_Closed)
        return;

    if (error)
    {
        if (error != boost::asio::error::operation_aborted)
            SF_LOG_ERROR("network", "Failed to accept world socket, error %d", error.value());
    }
    else
    {
        std::string remoteAddress = remoteEndpoint.address().to_string();

        std::unique_ptr<WorldSocketHandle> socketHandle(new WorldSocketHandle(std::move(socket)));
        std::unique_ptr<WorldSocket> worldSocket(new WorldSocket(std::move(socketHandle), remoteAddress));
        if (sWorldSocketMgr->OnSocketOpen(worldSocket.get(), reactor) == -1)
            worldSocket->CloseSocket();
        else
            worldSocket.release();
    }

    AsyncAccept();
}
