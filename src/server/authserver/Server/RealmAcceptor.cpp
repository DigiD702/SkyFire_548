/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "AuthSocket.h"
#include "Log.h"
#include "Network/BoostAsioUtils.h"
#include "RealmAcceptor.h"
#include <boost/system/error_code.hpp>
#include <memory>

RealmAcceptor::RealmAcceptor() :
    _ioContext(),
    _acceptor(_ioContext)
{
}

RealmAcceptor::~RealmAcceptor()
{
    Close();
}

bool RealmAcceptor::Open(uint16 port, std::string const& bindIp)
{
    return Skyfire::Net::OpenTcpAcceptor(_ioContext, _acceptor, port, bindIp, "server.authserver", "auth");
}

void RealmAcceptor::Close()
{
    boost::system::error_code ignored;
    _acceptor.close(ignored);
}

void RealmAcceptor::Update()
{
    if (!_acceptor.is_open())
        return;

    while (true)
    {
        boost::system::error_code error;
        std::unique_ptr<RealmSocketHandle> clientSocket(new RealmSocketHandle(_ioContext));
        _acceptor.accept(*clientSocket, error);

        if (error)
        {
            if (!Skyfire::Net::IsWouldBlock(error))
                SF_LOG_ERROR("server.authserver", "Failed to accept auth socket, error %d", error.value());

            break;
        }

        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(error);
        std::string remoteAddress = error ? std::string("<unknown>") : remoteEndpoint.address().to_string();
        uint16 remotePort = error ? 0 : remoteEndpoint.port();

        std::unique_ptr<RealmSocket> socket(new RealmSocket(std::move(clientSocket), remoteAddress, remotePort));
        socket->set_session(new AuthSocket(*socket));
        socket->Start();
        socket.release();
    }
}
