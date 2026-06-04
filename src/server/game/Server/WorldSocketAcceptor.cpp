/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Log.h"
#include "Network/BoostAsioUtils.h"
#include "WorldSocketAcceptor.h"
#include "WorldSocketMgr.h"
#include <boost/system/error_code.hpp>
#include <memory>

WorldSocketAcceptor::WorldSocketAcceptor() :
    m_IoContext(),
    m_Acceptor(m_IoContext)
{
}

WorldSocketAcceptor::~WorldSocketAcceptor()
{
    Close();
}

bool WorldSocketAcceptor::Open(uint16 port, const char* address)
{
    return Skyfire::Net::OpenTcpAcceptor(m_IoContext, m_Acceptor, port, address, "network", "world");
}

void WorldSocketAcceptor::Close()
{
    boost::system::error_code ignored;
    m_Acceptor.close(ignored);
}

void WorldSocketAcceptor::Update()
{
    if (!m_Acceptor.is_open())
        return;

    while (true)
    {
        boost::system::error_code error;
        std::unique_ptr<WorldSocketHandle> clientSocket(new WorldSocketHandle(m_IoContext));
        m_Acceptor.accept(*clientSocket, error);

        if (error)
        {
            if (!Skyfire::Net::IsWouldBlock(error))
                SF_LOG_ERROR("network", "Failed to accept world socket, error %d", error.value());

            break;
        }

        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(error);
        std::string remoteAddress = error ? std::string("<unknown>") : remoteEndpoint.address().to_string();

        clientSocket->non_blocking(true, error);
        if (error)
        {
            SF_LOG_ERROR("network", "Failed to set world client nonblocking, error %d", error.value());
            continue;
        }

        std::unique_ptr<WorldSocket> socket(new WorldSocket(std::move(clientSocket), remoteAddress));
        if (sWorldSocketMgr->OnSocketOpen(socket.get()) == -1)
        {
            socket->CloseSocket();
            continue;
        }

        socket.release();
    }
}
