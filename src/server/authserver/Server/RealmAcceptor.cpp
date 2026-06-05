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
    _acceptor(_ioContext),
    _closed(true)
{
}

RealmAcceptor::~RealmAcceptor()
{
    Close();
}

bool RealmAcceptor::Open(uint16 port, std::string const& bindIp)
{
    if (!Skyfire::Net::OpenTcpAcceptor(_ioContext, _acceptor, port, bindIp, "server.authserver", "auth"))
        return false;

    _closed = false;
    AsyncAccept();

    try
    {
        _thread = std::thread([this] { _ioContext.run(); });
    }
    catch (...)
    {
        Close();
        return false;
    }

    return true;
}

void RealmAcceptor::Close()
{
    bool expected = false;
    if (!_closed.compare_exchange_strong(expected, true))
        return;

    Skyfire::Net::CloseTcpAcceptor(_acceptor);
    _ioContext.stop();

    if (_thread.joinable())
        _thread.join();
}

void RealmAcceptor::Update()
{
}

void RealmAcceptor::AsyncAccept()
{
    if (!_acceptor.is_open())
        return;

    std::shared_ptr<RealmSocketHandle> clientSocket(new RealmSocketHandle(_ioContext));
    _acceptor.async_accept(*clientSocket,
        [this, clientSocket](boost::system::error_code const& error)
        {
            HandleAccept(clientSocket, error);
        });
}

void RealmAcceptor::HandleAccept(std::shared_ptr<RealmSocketHandle> clientSocket, boost::system::error_code const& error)
{
    if (_closed)
        return;

    if (error)
    {
        if (error != boost::asio::error::operation_aborted)
            SF_LOG_ERROR("server.authserver", "Failed to accept auth socket, error %d", error.value());
    }
    else
    {
        boost::system::error_code endpointError;
        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(endpointError);
        std::string remoteAddress = endpointError ? std::string("<unknown>") : remoteEndpoint.address().to_string();
        uint16 remotePort = endpointError ? 0 : remoteEndpoint.port();

        std::unique_ptr<RealmSocketHandle> socketHandle(new RealmSocketHandle(std::move(*clientSocket)));
        std::shared_ptr<RealmSocket> socket(new RealmSocket(std::move(socketHandle), remoteAddress, remotePort));
        socket->set_session(std::unique_ptr<RealmSocket::Session>(new AuthSocket(*socket)));
        socket->Start();
    }

    AsyncAccept();
}
