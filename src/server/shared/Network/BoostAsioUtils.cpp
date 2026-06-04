/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Network/BoostAsioUtils.h"
#include "Log.h"

#include <boost/asio/error.hpp>
#include <boost/asio/socket_base.hpp>

namespace Skyfire
{
namespace Net
{
    bool IsWouldBlock(boost::system::error_code const& error)
    {
        return error == boost::asio::error::would_block || error == boost::asio::error::try_again;
    }

    bool OpenTcpAcceptor(boost::asio::io_context& ioContext, boost::asio::ip::tcp::acceptor& acceptor,
        uint16 port, std::string const& bindAddress, char const* logFilter, char const* logName)
    {
        boost::system::error_code error;
        boost::asio::ip::tcp::resolver resolver(ioContext);
        boost::asio::ip::tcp::resolver::results_type endpoints = resolver.resolve(
            bindAddress, std::to_string(port), boost::asio::ip::resolver_base::passive, error);

        if (error)
        {
            SF_LOG_ERROR(logFilter, "Invalid %s bind address %s:%u, error %d",
                logName, bindAddress.c_str(), port, error.value());
            return false;
        }

        boost::system::error_code lastError;

        for (boost::asio::ip::tcp::endpoint const& endpoint : endpoints)
        {
            acceptor.open(endpoint.protocol(), error);
            if (error)
            {
                lastError = error;
                continue;
            }

            acceptor.set_option(boost::asio::socket_base::reuse_address(true), error);
            if (!error)
                acceptor.bind(endpoint, error);

            if (!error)
                acceptor.listen(boost::asio::socket_base::max_listen_connections, error);

            if (!error)
                acceptor.non_blocking(true, error);

            if (!error)
                return true;

            lastError = error;

            boost::system::error_code ignored;
            acceptor.close(ignored);
        }

        SF_LOG_ERROR(logFilter, "Failed to open %s listener on %s:%u, error %d",
            logName, bindAddress.c_str(), port, lastError.value());
        return false;
    }
}
}
