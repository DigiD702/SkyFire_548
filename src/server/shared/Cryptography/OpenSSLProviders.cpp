/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "OpenSSLProviders.h"

#include "Define.h"
#include "Log.h"

#include <openssl/provider.h>

#if PLATFORM == PLATFORM_WINDOWS
#include <windows.h>

#include <cstring>
#include <string>
#endif

namespace
{
    bool IsProviderAvailable(OSSL_PROVIDER* provider, char const* providerName)
    {
        return provider != NULL && OSSL_PROVIDER_available(NULL, providerName);
    }

#if PLATFORM == PLATFORM_WINDOWS
    std::string GetExecutableDirectory()
    {
        char path[SKYFIRE_PATH_MAX];
        DWORD length = GetModuleFileNameA(NULL, path, SKYFIRE_PATH_MAX);

        if (length == 0 || length >= SKYFIRE_PATH_MAX)
            return std::string();

        char* lastSlash = strrchr(path, '\\');
        if (lastSlash == NULL)
            return std::string();

        *lastSlash = '\0';
        return path;
    }

    bool SetProviderSearchPathToExecutableDirectory(char const* logFilter)
    {
        std::string const executableDirectory = GetExecutableDirectory();
        if (executableDirectory.empty())
            return false;

        if (OSSL_PROVIDER_set_default_search_path(NULL, executableDirectory.c_str()) != 1)
            return false;

        SF_LOG_INFO(logFilter, "OpenSSL provider search path set to %s.", executableDirectory.c_str());
        return true;
    }
#endif
}

bool Skyfire::LoadOpenSSLProviders(char const* logFilter)
{
    OSSL_PROVIDER* defaultProvider = OSSL_PROVIDER_try_load(NULL, "default", 1);
    OSSL_PROVIDER* legacyProvider = OSSL_PROVIDER_try_load(NULL, "legacy", 1);

#if PLATFORM == PLATFORM_WINDOWS
    if (!IsProviderAvailable(legacyProvider, "legacy"))
    {
        SF_LOG_INFO(logFilter, "Failed loading legacy provider. Trying executable directory as OpenSSL provider path.");

        if (legacyProvider != NULL)
        {
            OSSL_PROVIDER_unload(legacyProvider);
            legacyProvider = NULL;
        }

        if (SetProviderSearchPathToExecutableDirectory(logFilter))
            legacyProvider = OSSL_PROVIDER_try_load(NULL, "legacy", 1);
    }
#endif

    SF_LOG_INFO(logFilter, "Loading default provider: (%s)",
        IsProviderAvailable(defaultProvider, "default") ? "succeeded" : "failed");
    SF_LOG_INFO(logFilter, "Loading legacy provider: (%s)",
        IsProviderAvailable(legacyProvider, "legacy") ? "succeeded" : "failed");

    bool const loadedRequiredProvider = IsProviderAvailable(legacyProvider, "legacy");

    if (legacyProvider != NULL)
        OSSL_PROVIDER_unload(legacyProvider);

    return loadedRequiredProvider;
}
