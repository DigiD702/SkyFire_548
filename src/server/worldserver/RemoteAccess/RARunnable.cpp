/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

/** \file
    \ingroup Skyfired
 */

#include "Common.h"
#include "Config.h"
#include "Log.h"
#include "Network/BoostAsioUtils.h"
#include "RARunnable.h"
#include "World.h"

#include "RASocket.h"

#include <boost/asio/io_context.hpp>
#include <boost/system/error_code.hpp>
#include <chrono>
#include <memory>
#include <thread>
#include <utility>

void RARunnable::Run()
{
    if (!sConfigMgr->GetBoolDefault("Ra.Enable", false))
        return;

    uint16 raPort = uint16(sConfigMgr->GetIntDefault("Ra.Port", 3443));
    std::string stringIp = sConfigMgr->GetStringDefault("Ra.IP", "0.0.0.0");

    std::shared_ptr<boost::asio::io_context> ioContext(new boost::asio::io_context);
    boost::asio::ip::tcp::acceptor acceptor(*ioContext);
    if (!Skyfire::Net::OpenTcpAcceptor(*ioContext, acceptor, raPort, stringIp, "server.worldserver", "Skyfire RA"))
        return;

    SF_LOG_INFO("server.worldserver", "Starting Skyfire RA on port %d on %s", raPort, stringIp.c_str());

    boost::system::error_code error;
    while (!World::IsStopped())
    {
        error.clear();
        std::unique_ptr<RASocketHandle> clientSocket(new RASocketHandle(*ioContext));
        acceptor.accept(*clientSocket, error);

        if (error)
        {
            if (!Skyfire::Net::IsWouldBlock(error))
                SF_LOG_ERROR("commands.ra", "Skyfire RA failed to accept socket, error %d", error.value());

            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }

        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(error);
        std::string remote = error ? std::string("<unknown>") : remoteEndpoint.address().to_string();

        SF_LOG_INFO("commands.ra", "Incoming connection from %s", remote.c_str());

        (new RASocket(ioContext, std::move(clientSocket), remote))->start();
    }

    boost::system::error_code ignored;
    acceptor.close(ignored);

    SF_LOG_DEBUG("server.worldserver", "Skyfire RA thread exiting");
}
