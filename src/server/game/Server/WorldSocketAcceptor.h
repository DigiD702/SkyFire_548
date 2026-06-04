/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

/** \addtogroup u2w User to World Communication
 *  @{
 *  \file WorldSocketMgr.h
 */

#ifndef SF_WORLDSOCKETACCEPTOR_H
#define SF_WORLDSOCKETACCEPTOR_H

#include "Common.h"
#include "WorldSocket.h"
#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <atomic>
#include <memory>
#include <thread>

class WorldSocketAcceptor
{
public:
    WorldSocketAcceptor();
    ~WorldSocketAcceptor();

    bool Open(uint16 port, const char* address);
    void Close();
    void Update();

private:
    void AsyncAccept();
    void HandleAccept(std::shared_ptr<WorldSocketHandle> clientSocket, boost::system::error_code const& error);

    boost::asio::io_context m_IoContext;
    boost::asio::ip::tcp::acceptor m_Acceptor;
    std::thread m_Thread;
    std::atomic<bool> m_Closed;
};

#endif /* __WORLDSOCKETACCEPTOR_H_ */
/// @}
