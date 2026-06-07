/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ByteBuffer.h"
#include "Errors.h"

#include <cstdlib>
#include <iostream>
#include <sstream>

ByteBufferPositionException::ByteBufferPositionException(bool add, size_t pos, size_t size, size_t valueSize)
{
    std::ostringstream ss;
    ss << "Attempted to " << (add ? "put" : "get") << " value with size: "
        << valueSize << " in ByteBuffer (pos: " << pos << " size: " << size << ")";

    message().assign(ss.str());
}

ByteBufferSourceException::ByteBufferSourceException(size_t pos, size_t size, size_t valueSize)
{
    std::ostringstream ss;
    ss << "Attempted to put a "
        << (valueSize > 0 ? "NULL-pointer" : "zero-sized value")
        << " in ByteBuffer (pos: " << pos << " size: " << size << ")";

    message().assign(ss.str());
}

namespace Skyfire
{
    void Assert(char const* file, int line, char const* function, char const* message)
    {
        std::cerr << file << ':' << line << " in " << function << " ASSERTION FAILED: " << message << '\n';
        std::abort();
    }
}
