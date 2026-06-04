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

    boost::system::error_code ignored;
    m_Acceptor.close(ignored);
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

    std::shared_ptr<WorldSocketHandle> clientSocket(new WorldSocketHandle(m_IoContext));
    m_Acceptor.async_accept(*clientSocket,
        [this, clientSocket](boost::system::error_code const& error)
        {
            HandleAccept(clientSocket, error);
        });
}

void WorldSocketAcceptor::HandleAccept(std::shared_ptr<WorldSocketHandle> clientSocket, boost::system::error_code const& error)
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
        boost::system::error_code endpointError;
        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(endpointError);
        std::string remoteAddress = endpointError ? std::string("<unknown>") : remoteEndpoint.address().to_string();

        clientSocket->non_blocking(true, endpointError);
        if (endpointError)
        {
            SF_LOG_ERROR("network", "Failed to set world client nonblocking, error %d", endpointError.value());
        }
        else
        {
            std::unique_ptr<WorldSocketHandle> socketHandle(new WorldSocketHandle(std::move(*clientSocket)));
            std::unique_ptr<WorldSocket> socket(new WorldSocket(std::move(socketHandle), remoteAddress));
            if (sWorldSocketMgr->OnSocketOpen(socket.get()) == -1)
                socket->CloseSocket();
            else
                socket.release();

        }
    }

    AsyncAccept();
}
