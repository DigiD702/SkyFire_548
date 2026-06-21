/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

/** \file
    \ingroup Skyfired
*/

#ifdef _WIN32
#include <winsock2.h>
#endif
#include <mysql.h>
#include <csignal>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <memory>
#include <sstream>

#include "Common.h"
#include "Configuration/Config.h"
#include "Database/DatabaseEnv.h"
#include "Database/DatabaseSetup/DatabaseSetup.h"
#include "Database/DatabaseWorkerPool.h"
#include "SystemConfig.h"
#include "World.h"
#include "WorldRunnable.h"
#include "WorldSocket.h"
#include "WorldSocketMgr.h"

#include "AuthSocket.h"
#include "CliRunnable.h"
#include "Log.h"
#include "Master.h"
#include "Platform/TimeUtils.h"
#include "RARunnable.h"
#include "RealmList.h"
#include "SFSoap.h"
#include "Timer.h"
#include "Threading/BoostAsioTaskRunner.h"
#include "Util.h"

#include "BigNumber.h"

#ifdef _WIN32
#include "ServiceWin32.h"
extern int m_ServiceStatus;
#endif

#ifdef __linux__
#include <sched.h>
#include <sys/resource.h>
#define PROCESS_HIGH_PRIORITY -15 // [-20, 19], default is 0
#endif

namespace
{
    char const* DATABASE_UPDATE_TRACKING_TABLE = "skyfire_db_updates";

    Skyfire::Database::SetupOptions LoadCharacterDatabaseSetupOptions()
    {
        return Skyfire::Database::MakeCharacterDatabaseSetupOptions(
            sConfigMgr->GetBoolDefault("CharacterDatabase.AutoSetup", false),
            sConfigMgr->GetBoolDefault("CharacterDatabase.AutoCreate", false),
            sConfigMgr->GetBoolDefault("CharacterDatabase.AutoBaseline", false),
            sConfigMgr->GetStringDefault("CharacterDatabase.SqlPath", ""));
    }

    Skyfire::Database::SetupOptions LoadWorldDatabaseSetupOptions()
    {
        return Skyfire::Database::MakeWorldDatabaseSetupOptions(
            sConfigMgr->GetBoolDefault("WorldDatabase.AutoSetup", false),
            sConfigMgr->GetBoolDefault("WorldDatabase.AutoCreate", false),
            sConfigMgr->GetBoolDefault("WorldDatabase.AutoBaseline", false),
            sConfigMgr->GetStringDefault("WorldDatabase.SqlPath", ""),
            sConfigMgr->GetStringDefault("WorldDatabase.BaseSqlFile", ""));
    }

    std::filesystem::path GetDatabaseBaseSqlPath(Skyfire::Database::SetupOptions const& options)
    {
        std::filesystem::path path = std::filesystem::path(options.SqlPath) / "base" / options.BaseFileName;
        path.make_preferred();
        return path;
    }

    std::filesystem::path GetDatabaseBaseSqlPath(Skyfire::Database::SetupOptions const& options,
        std::string const& baseFileName)
    {
        std::filesystem::path path = std::filesystem::path(options.SqlPath) / "base" / baseFileName;
        path.make_preferred();
        return path;
    }

    bool ReadDatabaseSetupTextFile(std::filesystem::path const& path, std::string& contents)
    {
        std::ifstream file(path, std::ios::in | std::ios::binary);
        if (!file)
            return false;

        std::ostringstream stream;
        stream << file.rdbuf();
        contents = stream.str();
        return true;
    }

    std::string EscapeSqlIdentifier(std::string const& identifier)
    {
        std::string escaped;
        escaped.reserve(identifier.length());

        for (char c : identifier)
        {
            if (c == '`')
                escaped.push_back('`');

            escaped.push_back(c);
        }

        return escaped;
    }

    bool ConnectToMySQLServer(MySQLConnectionInfo const& connectionInfo, char const* databaseName, MYSQL*& handle)
    {
        MYSQL* mysqlInit = mysql_init(NULL);
        if (!mysqlInit)
        {
            SF_LOG_ERROR("server.worldserver", "Could not initialize MySQL setup connection.");
            return false;
        }

        mysql_options(mysqlInit, MYSQL_SET_CHARSET_NAME, "utf8");

        int port = 0;
        char const* unixSocket = NULL;
        std::string host = connectionInfo._host;

#ifdef _WIN32
        if (host == ".")
        {
            unsigned int protocol = MYSQL_PROTOCOL_PIPE;
            mysql_options(mysqlInit, MYSQL_OPT_PROTOCOL, reinterpret_cast<char const*>(&protocol));
        }
        else
            port = atoi(connectionInfo._port_or_socket.c_str());
#else
        if (host == ".")
        {
            unsigned int protocol = MYSQL_PROTOCOL_SOCKET;
            mysql_options(mysqlInit, MYSQL_OPT_PROTOCOL, reinterpret_cast<char const*>(&protocol));
            host = "localhost";
            unixSocket = connectionInfo._port_or_socket.c_str();
        }
        else
            port = atoi(connectionInfo._port_or_socket.c_str());
#endif

        handle = mysql_real_connect(mysqlInit, host.c_str(), connectionInfo._user.c_str(),
            connectionInfo._password.c_str(), databaseName, port, unixSocket, 0);

        if (!handle)
        {
            SF_LOG_ERROR("server.worldserver", "Could not connect to MySQL server for setup: %s",
                mysql_error(mysqlInit));
            mysql_close(mysqlInit);
            return false;
        }

        return true;
    }

    bool EnsureCharacterDatabaseExists(MySQLConnectionInfo const& connectionInfo,
        Skyfire::Database::SetupOptions const& options)
    {
        if (!options.AutoSetup || !options.AutoCreate)
            return true;

        if (connectionInfo._database.empty())
        {
            SF_LOG_ERROR("server.worldserver", "CharacterDatabase.AutoCreate requires a character database name.");
            return false;
        }

        MYSQL* setupConnection = NULL;
        if (!ConnectToMySQLServer(connectionInfo, NULL, setupConnection))
            return false;

        std::string sql = "CREATE DATABASE IF NOT EXISTS `" + EscapeSqlIdentifier(connectionInfo._database) +
            "` DEFAULT CHARACTER SET utf8";

        if (mysql_query(setupConnection, sql.c_str()))
        {
            SF_LOG_ERROR("server.worldserver", "Could not create character database `%s`: %s",
                connectionInfo._database.c_str(), mysql_error(setupConnection));
            mysql_close(setupConnection);
            return false;
        }

        SF_LOG_INFO("server.worldserver", "Character database `%s` exists or was created.",
            connectionInfo._database.c_str());
        mysql_close(setupConnection);
        return true;
    }

    bool ExecuteSetupQuery(MYSQL* setupConnection, std::string const& sql, char const* context)
    {
        if (mysql_query(setupConnection, sql.c_str()))
        {
            SF_LOG_ERROR("server.worldserver", "%s: %s", context, mysql_error(setupConnection));
            return false;
        }

        return true;
    }

    bool QuerySetupUInt32(MYSQL* setupConnection, char const* sql, uint32& value, char const* context)
    {
        if (mysql_query(setupConnection, sql))
        {
            SF_LOG_ERROR("server.worldserver", "%s: %s", context, mysql_error(setupConnection));
            return false;
        }

        MYSQL_RES* result = mysql_store_result(setupConnection);
        if (!result)
        {
            SF_LOG_ERROR("server.worldserver", "%s: %s", context, mysql_error(setupConnection));
            return false;
        }

        std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> resultGuard(result, mysql_free_result);
        MYSQL_ROW row = mysql_fetch_row(result);
        if (!row || !row[0])
        {
            SF_LOG_ERROR("server.worldserver", "%s returned no value.", context);
            return false;
        }

        value = uint32(std::strtoul(row[0], NULL, 10));
        return true;
    }

    bool EnsureDatabaseUpdateTrackingTable(MYSQL* setupConnection, char const* context)
    {
        std::string sql = "CREATE TABLE IF NOT EXISTS `" + std::string(DATABASE_UPDATE_TRACKING_TABLE) + "` ("
            "`domain` varchar(32) NOT NULL,"
            "`filename` varchar(255) NOT NULL,"
            "`hash` varchar(64) NOT NULL,"
            "`applied_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,"
            "PRIMARY KEY (`domain`,`filename`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb3";

        return ExecuteSetupQuery(setupConnection, sql, context);
    }

    bool EnsureDbUpdateAuditTable(MYSQL* setupConnection, char const* context)
    {
        return ExecuteSetupQuery(setupConnection, Skyfire::Database::BuildDbUpdateAuditTableSql(), context);
    }

    bool LoadCharacterDatabaseSetupState(MYSQL* setupConnection, Skyfire::Database::SetupState& state)
    {
        state.DatabaseExists = true;

        if (!QuerySetupUInt32(setupConnection,
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE()",
            state.SchemaTableCount,
            "Could not inspect character database table count"))
            return false;

        uint32 updateTrackingTableCount = 0;
        if (!QuerySetupUInt32(setupConnection,
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() "
            "AND table_name = 'skyfire_db_updates'",
            updateTrackingTableCount,
            "Could not inspect character database update tracking table"))
            return false;

        state.UpdateTrackingExists = updateTrackingTableCount != 0;
        if (!state.UpdateTrackingExists)
            return true;

        if (mysql_query(setupConnection, "SELECT `filename`, `hash` FROM `skyfire_db_updates` WHERE `domain` = 'characters'"))
        {
            SF_LOG_ERROR("server.worldserver", "Could not read character database applied updates: %s",
                mysql_error(setupConnection));
            return false;
        }

        MYSQL_RES* result = mysql_store_result(setupConnection);
        if (!result)
        {
            SF_LOG_ERROR("server.worldserver", "Could not read character database applied updates: %s",
                mysql_error(setupConnection));
            return false;
        }

        std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> resultGuard(result, mysql_free_result);
        while (MYSQL_ROW row = mysql_fetch_row(result))
        {
            if (row[0])
            {
                state.AppliedUpdates.insert(row[0]);
                if (row[1])
                    state.AppliedUpdateHashes[row[0]] = row[1];
            }
        }

        return true;
    }

    bool ExecuteSqlText(MYSQL* setupConnection, std::string const& sql, char const* context)
    {
        return Skyfire::Database::ExecuteSqlScript(sql, [setupConnection, context](std::string const& statement)
        {
            return ExecuteSetupQuery(setupConnection, statement, context);
        });
    }

    bool ExecuteSqlFile(MYSQL* setupConnection, std::filesystem::path const& path, std::string& contents,
        char const* context)
    {
        if (!ReadDatabaseSetupTextFile(path, contents))
        {
            SF_LOG_ERROR("server.worldserver", "Could not read SQL file %s.", path.string().c_str());
            return false;
        }

        if (!ExecuteSqlText(setupConnection, contents, context))
        {
            SF_LOG_ERROR("server.worldserver", "Failed while executing SQL file %s.", path.string().c_str());
            return false;
        }

        return true;
    }

    bool RecordCharacterUpdateMetadata(MYSQL* setupConnection, Skyfire::Database::SqlUpdateFile const& update,
        std::string const& hash)
    {
        if (hash.empty())
        {
            SF_LOG_ERROR("server.worldserver", "Character database update %s has no content hash.",
                update.Name.c_str());
            return false;
        }

        std::string filename = Skyfire::Database::EscapeSqlString(update.Name);
        std::string escapedHash = Skyfire::Database::EscapeSqlString(hash);

        std::string recordSql = "INSERT INTO `" + std::string(DATABASE_UPDATE_TRACKING_TABLE) +
            "` (`domain`, `filename`, `hash`, `applied_at`) VALUES ('characters', '" +
            filename + "', '" + escapedHash + "', NOW())";

        return ExecuteSetupQuery(setupConnection, recordSql, "Could not record character database update");
    }

    bool RecordAppliedCharacterUpdate(MYSQL* setupConnection, Skyfire::Database::SqlUpdateFile const& update,
        std::string const& sql)
    {
        if (!RecordCharacterUpdateMetadata(setupConnection, update, Skyfire::Database::CalculateStableSqlHash(sql)))
            return false;

        return ExecuteSetupQuery(setupConnection, Skyfire::Database::BuildDbUpdateAuditInsertSql(update.Name),
            "Could not record character database update audit row");
    }

    bool RunCharacterDatabaseSetup(MySQLConnectionInfo const& connectionInfo,
        Skyfire::Database::SetupOptions const& options)
    {
        if (!options.AutoSetup)
            return true;

        if (options.SqlPath.empty())
        {
            SF_LOG_ERROR("server.worldserver", "CharacterDatabase.AutoSetup requires CharacterDatabase.SqlPath.");
            return false;
        }

        if (connectionInfo._database.empty())
        {
            SF_LOG_ERROR("server.worldserver", "CharacterDatabase.AutoSetup requires a character database name.");
            return false;
        }

        if (!EnsureCharacterDatabaseExists(connectionInfo, options))
            return false;

        MYSQL* setupConnectionRaw = NULL;
        if (!ConnectToMySQLServer(connectionInfo, connectionInfo._database.c_str(), setupConnectionRaw))
            return false;

        std::unique_ptr<MYSQL, decltype(&mysql_close)> setupConnection(setupConnectionRaw, mysql_close);

        std::filesystem::path baseSqlPath = GetDatabaseBaseSqlPath(options);
        bool baseSqlExists = std::filesystem::exists(baseSqlPath);
        std::vector<Skyfire::Database::SqlUpdateFile> updates = Skyfire::Database::DiscoverSqlUpdates(options);

        Skyfire::Database::SetupState state;
        if (!LoadCharacterDatabaseSetupState(setupConnection.get(), state))
            return false;

        Skyfire::Database::SetupPlan plan =
            Skyfire::Database::BuildCharacterDatabaseSetupPlan(options, state, baseSqlExists, updates);
        if (!plan.IsValid())
        {
            SF_LOG_ERROR("server.worldserver", "%s", plan.Error.c_str());
            return false;
        }

        if (plan.ShouldInstallBase)
        {
            std::string baseSql;
            SF_LOG_INFO("server.worldserver", "Installing character database base SQL from %s.",
                baseSqlPath.string().c_str());
            if (!ExecuteSqlFile(setupConnection.get(), baseSqlPath, baseSql,
                "Failed while executing character setup SQL"))
                return false;
        }

        if (!EnsureDatabaseUpdateTrackingTable(setupConnection.get(),
            "Could not create character database update tracking table"))
        {
            SF_LOG_ERROR("server.worldserver", "Could not create character database update tracking table.");
            return false;
        }

        if (!EnsureDbUpdateAuditTable(setupConnection.get(), "Could not create character database update audit table"))
        {
            SF_LOG_ERROR("server.worldserver", "Could not create character database update audit table.");
            return false;
        }

        if (plan.ShouldBaselineUpdates)
        {
            SF_LOG_WARN("server.worldserver",
                "CharacterDatabase.AutoBaseline is enabled. Recording %u character updates as already applied without executing them.",
                uint32(plan.BaselineUpdates.size()));
            SF_LOG_WARN("server.worldserver",
                "Disable CharacterDatabase.AutoBaseline after this startup to keep future update checks strict.");

            for (Skyfire::Database::SqlUpdateFile const& update : plan.BaselineUpdates)
            {
                if (!RecordCharacterUpdateMetadata(setupConnection.get(), update, update.Hash))
                {
                    SF_LOG_ERROR("server.worldserver", "Could not baseline character database update %s.",
                        update.Name.c_str());
                    return false;
                }
            }
        }

        for (Skyfire::Database::SqlUpdateFile const& update : plan.PendingUpdates)
        {
            std::string updateSql;
            SF_LOG_INFO("server.worldserver", "Applying character database update %s.", update.Name.c_str());
            if (!ExecuteSqlFile(setupConnection.get(), update.Path, updateSql,
                "Failed while executing character setup SQL"))
                return false;

            if (!RecordAppliedCharacterUpdate(setupConnection.get(), update, updateSql))
            {
                SF_LOG_ERROR("server.worldserver", "Could not record character database update %s.",
                    update.Name.c_str());
                return false;
            }
        }

        SF_LOG_INFO("server.worldserver",
            "Character database setup complete. Base installed: %s, updates applied: %u, updates baselined: %u.",
            plan.ShouldInstallBase ? "yes" : "no", uint32(plan.PendingUpdates.size()),
            uint32(plan.BaselineUpdates.size()));
        return true;
    }

    bool EnsureWorldDatabaseExists(MySQLConnectionInfo const& connectionInfo,
        Skyfire::Database::SetupOptions const& options)
    {
        if (!options.AutoSetup || !options.AutoCreate)
            return true;

        if (connectionInfo._database.empty())
        {
            SF_LOG_ERROR("server.worldserver", "WorldDatabase.AutoCreate requires a world database name.");
            return false;
        }

        MYSQL* setupConnection = NULL;
        if (!ConnectToMySQLServer(connectionInfo, NULL, setupConnection))
            return false;

        std::string sql = "CREATE DATABASE IF NOT EXISTS `" + EscapeSqlIdentifier(connectionInfo._database) +
            "` DEFAULT CHARACTER SET utf8";

        if (mysql_query(setupConnection, sql.c_str()))
        {
            SF_LOG_ERROR("server.worldserver", "Could not create world database `%s`: %s",
                connectionInfo._database.c_str(), mysql_error(setupConnection));
            mysql_close(setupConnection);
            return false;
        }

        SF_LOG_INFO("server.worldserver", "World database `%s` exists or was created.",
            connectionInfo._database.c_str());
        mysql_close(setupConnection);
        return true;
    }

    bool LoadWorldDatabaseSetupState(MYSQL* setupConnection, Skyfire::Database::SetupState& state)
    {
        state.DatabaseExists = true;

        if (!QuerySetupUInt32(setupConnection,
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE()",
            state.SchemaTableCount,
            "Could not inspect world database table count"))
            return false;

        uint32 updateTrackingTableCount = 0;
        if (!QuerySetupUInt32(setupConnection,
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() "
            "AND table_name = 'skyfire_db_updates'",
            updateTrackingTableCount,
            "Could not inspect world database update tracking table"))
            return false;

        state.UpdateTrackingExists = updateTrackingTableCount != 0;
        if (!state.UpdateTrackingExists)
            return true;

        if (mysql_query(setupConnection, "SELECT `filename`, `hash` FROM `skyfire_db_updates` WHERE `domain` = 'world'"))
        {
            SF_LOG_ERROR("server.worldserver", "Could not read world database applied updates: %s",
                mysql_error(setupConnection));
            return false;
        }

        MYSQL_RES* result = mysql_store_result(setupConnection);
        if (!result)
        {
            SF_LOG_ERROR("server.worldserver", "Could not read world database applied updates: %s",
                mysql_error(setupConnection));
            return false;
        }

        std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> resultGuard(result, mysql_free_result);
        while (MYSQL_ROW row = mysql_fetch_row(result))
        {
            if (row[0])
            {
                state.AppliedUpdates.insert(row[0]);
                if (row[1])
                    state.AppliedUpdateHashes[row[0]] = row[1];
            }
        }

        return true;
    }

    bool RecordWorldUpdateMetadata(MYSQL* setupConnection, Skyfire::Database::SqlUpdateFile const& update,
        std::string const& hash)
    {
        if (hash.empty())
        {
            SF_LOG_ERROR("server.worldserver", "World database update %s has no content hash.",
                update.Name.c_str());
            return false;
        }

        std::string filename = Skyfire::Database::EscapeSqlString(update.Name);
        std::string escapedHash = Skyfire::Database::EscapeSqlString(hash);

        std::string recordSql = "INSERT INTO `" + std::string(DATABASE_UPDATE_TRACKING_TABLE) +
            "` (`domain`, `filename`, `hash`, `applied_at`) VALUES ('world', '" +
            filename + "', '" + escapedHash + "', NOW())";

        return ExecuteSetupQuery(setupConnection, recordSql, "Could not record world database update");
    }

    bool RecordAppliedWorldUpdate(MYSQL* setupConnection, Skyfire::Database::SqlUpdateFile const& update,
        std::string const& sql)
    {
        if (!RecordWorldUpdateMetadata(setupConnection, update, Skyfire::Database::CalculateStableSqlHash(sql)))
            return false;

        return ExecuteSetupQuery(setupConnection, Skyfire::Database::BuildDbUpdateAuditInsertSql(update.Name),
            "Could not record world database update audit row");
    }

    bool RunWorldDatabaseSetup(MySQLConnectionInfo const& connectionInfo,
        Skyfire::Database::SetupOptions const& options)
    {
        if (!options.AutoSetup)
            return true;

        if (options.SqlPath.empty())
        {
            SF_LOG_ERROR("server.worldserver", "WorldDatabase.AutoSetup requires WorldDatabase.SqlPath.");
            return false;
        }

        if (connectionInfo._database.empty())
        {
            SF_LOG_ERROR("server.worldserver", "WorldDatabase.AutoSetup requires a world database name.");
            return false;
        }

        if (!EnsureWorldDatabaseExists(connectionInfo, options))
            return false;

        MYSQL* setupConnectionRaw = NULL;
        if (!ConnectToMySQLServer(connectionInfo, connectionInfo._database.c_str(), setupConnectionRaw))
            return false;

        std::unique_ptr<MYSQL, decltype(&mysql_close)> setupConnection(setupConnectionRaw, mysql_close);

        std::filesystem::path externalBaseSqlPath = options.ExternalBaseFile;
        externalBaseSqlPath.make_preferred();
        bool externalBaseSqlExists = !options.ExternalBaseFile.empty() && std::filesystem::exists(externalBaseSqlPath);

        bool requiredBaseSqlExists = true;
        std::vector<std::filesystem::path> requiredBaseSqlPaths;
        for (std::string const& baseFileName : options.RequiredBaseFileNames)
        {
            std::filesystem::path requiredBaseSqlPath = GetDatabaseBaseSqlPath(options, baseFileName);
            requiredBaseSqlPaths.push_back(requiredBaseSqlPath);
            requiredBaseSqlExists = requiredBaseSqlExists && std::filesystem::exists(requiredBaseSqlPath);
        }

        std::vector<Skyfire::Database::SqlUpdateFile> updates = Skyfire::Database::DiscoverSqlUpdates(options);

        Skyfire::Database::SetupState state;
        if (!LoadWorldDatabaseSetupState(setupConnection.get(), state))
            return false;

        Skyfire::Database::SetupPlan plan = Skyfire::Database::BuildWorldDatabaseSetupPlan(options, state,
            externalBaseSqlExists, requiredBaseSqlExists, updates);
        if (!plan.IsValid())
        {
            SF_LOG_ERROR("server.worldserver", "%s", plan.Error.c_str());
            return false;
        }

        if (plan.ShouldInstallBase)
        {
            std::string baseSql;
            SF_LOG_INFO("server.worldserver", "Installing world database base SQL from %s.",
                externalBaseSqlPath.string().c_str());
            if (!ExecuteSqlFile(setupConnection.get(), externalBaseSqlPath, baseSql,
                "Failed while executing world setup SQL"))
                return false;
        }

        for (std::filesystem::path const& requiredBaseSqlPath : requiredBaseSqlPaths)
        {
            std::string requiredBaseSql;
            SF_LOG_INFO("server.worldserver", "Applying world database required SQL from %s.",
                requiredBaseSqlPath.string().c_str());
            if (!ExecuteSqlFile(setupConnection.get(), requiredBaseSqlPath, requiredBaseSql,
                "Failed while executing world setup SQL"))
                return false;
        }

        if (!EnsureDatabaseUpdateTrackingTable(setupConnection.get(),
            "Could not create world database update tracking table"))
        {
            SF_LOG_ERROR("server.worldserver", "Could not create world database update tracking table.");
            return false;
        }

        if (!EnsureDbUpdateAuditTable(setupConnection.get(), "Could not create world database update audit table"))
        {
            SF_LOG_ERROR("server.worldserver", "Could not create world database update audit table.");
            return false;
        }

        if (plan.ShouldBaselineUpdates)
        {
            SF_LOG_WARN("server.worldserver",
                "WorldDatabase.AutoBaseline is enabled. Recording %u world updates as already applied without executing them.",
                uint32(plan.BaselineUpdates.size()));
            SF_LOG_WARN("server.worldserver",
                "Disable WorldDatabase.AutoBaseline after this startup to keep future update checks strict.");

            for (Skyfire::Database::SqlUpdateFile const& update : plan.BaselineUpdates)
            {
                if (!RecordWorldUpdateMetadata(setupConnection.get(), update, update.Hash))
                {
                    SF_LOG_ERROR("server.worldserver", "Could not baseline world database update %s.",
                        update.Name.c_str());
                    return false;
                }
            }
        }

        for (Skyfire::Database::SqlUpdateFile const& update : plan.PendingUpdates)
        {
            std::string updateSql;
            SF_LOG_INFO("server.worldserver", "Applying world database update %s.", update.Name.c_str());
            if (!ExecuteSqlFile(setupConnection.get(), update.Path, updateSql,
                "Failed while executing world setup SQL"))
                return false;

            if (!RecordAppliedWorldUpdate(setupConnection.get(), update, updateSql))
            {
                SF_LOG_ERROR("server.worldserver", "Could not record world database update %s.",
                    update.Name.c_str());
                return false;
            }
        }

        SF_LOG_INFO("server.worldserver",
            "World database setup complete. Base installed: %s, updates applied: %u, updates baselined: %u.",
            plan.ShouldInstallBase ? "yes" : "no", uint32(plan.PendingUpdates.size()),
            uint32(plan.BaselineUpdates.size()));
        return true;
    }
}

void WorldServerSignalHandler(int sigNum)
{
    switch (sigNum)
    {
        case SIGINT:
            World::StopNow(RESTART_EXIT_CODE);
            break;
        case SIGTERM:
#ifdef _WIN32
        case SIGBREAK:
            if (m_ServiceStatus != 1)
#endif
                World::StopNow(SHUTDOWN_EXIT_CODE);
            break;
    }
}

class FreezeDetectorRunnable
{
private:
    uint32 _loops;
    uint32 _lastChange;
    uint32 _delaytime;
public:
    FreezeDetectorRunnable() : _loops(0), _lastChange(0), _delaytime(0) { }

    void SetDelayTime(uint32 t) { _delaytime = t; }

    void Run()
    {
        if (!_delaytime)
            return;

        SF_LOG_INFO("server.worldserver", "Starting up anti-freeze thread (%u seconds max stuck time)...", _delaytime / 1000);
        _loops = 0;
        _lastChange = 0;
        while (!World::IsStopped())
        {
            Skyfire::SleepForSeconds(1);
            uint32 curtime = getMSTime();
            // normal work
            uint32 worldLoopCounter = World::m_worldLoopCounter;
            if (_loops != worldLoopCounter)
            {
                _lastChange = curtime;
                _loops = worldLoopCounter;
            }
            // possible freeze
            else if (getMSTimeDiff(_lastChange, curtime) > _delaytime)
            {
                SF_LOG_ERROR("server.worldserver", "World Thread hangs, kicking out server!");
                ASSERT(false);
            }
        }
        SF_LOG_INFO("server.worldserver", "Anti-freeze thread exiting without problems.");
    }
};

/// Main function
int Master::Run()
{
    BigNumber seed1;
    seed1.SetRand(16 * 8);
    SF_LOG_INFO("server.worldserver", "worldserver-daemon. revision: % s", SKYFIRE_VER_PRODUCTVERSION_STR);
    SF_LOG_INFO("server.worldserver", "<Ctrl-C> to stop.\n");

    SF_LOG_INFO("server.worldserver", "   ______  __  __  __  __  ______ __  ______  ______ ");
    SF_LOG_INFO("server.worldserver", "  /\\  ___\\/\\ \\/ / /\\ \\_\\ \\/\\  ___/\\ \\/\\  == \\/\\  ___\\ ");
    SF_LOG_INFO("server.worldserver", "  \\ \\___  \\ \\  _'-\\ \\____ \\ \\  __\\ \\ \\ \\  __<\\ \\  __\\ ");
    SF_LOG_INFO("server.worldserver", "   \\/\\_____\\ \\_\\ \\_\\/\\_____\\ \\_\\  \\ \\_\\ \\_\\ \\_\\ \\_____\\ ");
    SF_LOG_INFO("server.worldserver", "    \\/_____/\\/_/\\/_/\\/_____/\\/_/   \\/_/\\/_/ /_/\\/_____/ ");
    SF_LOG_INFO("server.worldserver", "  %s Open-sourced Game Emulation", SKYFIRE_VER_LEGALCOPYRIGHT_STR);
    SF_LOG_INFO("server.worldserver", "           <http://www.projectskyfire.org/> \n");

    ///- Check the version of the configuration file
    uint32 confVersion = sConfigMgr->GetIntDefault("ConfVersion", 0);
    if (confVersion < SKYFIREWORLD_CONFIG_VERSION)
    {
        SF_LOG_INFO("server.worldserver", "*****************************************************************************");
        SF_LOG_INFO("server.worldserver", " WARNING: Your worldserver.conf version indicates your conf file is out of date!");
        SF_LOG_INFO("server.worldserver", "          Please check for updates, as your current default values may cause");
        SF_LOG_INFO("server.worldserver", "          strange behavior.");
        SF_LOG_INFO("server.worldserver", "*****************************************************************************");
    }

    /// worldserver PID file creation
    std::string pidFile = sConfigMgr->GetStringDefault("PidFile", "");
    if (!pidFile.empty())
    {
        if (uint32 pid = CreatePIDFile(pidFile))
            SF_LOG_INFO("server.worldserver", "Daemon PID: %u\n", pid);
        else
        {
            SF_LOG_ERROR("server.worldserver", "Cannot create PID file %s.\n", pidFile.c_str());
            return 1;
        }
    }

    ///- Start the databases
    if (!_StartDB())
        return 1;

    // set server offline (not connectable)
    for (std::map<uint32, std::string>::const_iterator itr = realmNameStore.begin(); itr != realmNameStore.end(); ++itr)
    {
        LoginDatabase.DirectPExecute("UPDATE realmlist SET flag = (flag & ~%u) | %u WHERE id = '%d'", REALM_FLAG_OFFLINE, REALM_FLAG_INVALID, itr->first);
    }

    ///- Initialize the World
    sWorld->SetInitialWorldSettings();

    ///- Register worldserver's signal handlers
    std::signal(SIGINT, WorldServerSignalHandler);
    std::signal(SIGTERM, WorldServerSignalHandler);
#ifdef _WIN32
    std::signal(SIGBREAK, WorldServerSignalHandler);
#endif

    ///- Launch WorldRunnable task
    Skyfire::Asio::IoContextTaskRunner worldRunner;
    if (worldRunner.Start([] { WorldRunnable().Run(); }) == -1)
    {
        SF_LOG_ERROR("server.worldserver", "Failed to start world task");
        _StopDB();
        return 1;
    }

    Skyfire::Asio::IoContextTaskRunner raRunner;
    if (raRunner.Start([] { RARunnable().Run(); }) == -1)
    {
        SF_LOG_ERROR("server.worldserver", "Failed to start RA task");
        World::StopNow(ERROR_EXIT_CODE);
        worldRunner.Join();
        _StopDB();
        return 1;
    }

    std::unique_ptr<Skyfire::Asio::IoContextTaskRunner> cliRunner;

#ifdef _WIN32
    if (sConfigMgr->GetBoolDefault("Console.Enable", true) && (m_ServiceStatus == -1)/* need disable console in service mode*/)
#else
    if (sConfigMgr->GetBoolDefault("Console.Enable", true))
#endif
    {
        ///- Launch CliRunnable task
        cliRunner.reset(new Skyfire::Asio::IoContextTaskRunner);
        if (cliRunner->Start([] { CliRunnable().Run(); }) == -1)
        {
            SF_LOG_ERROR("server.worldserver", "Failed to start CLI task");
            cliRunner.reset();
        }
    }

#if defined(_WIN32) || defined(__linux__)
    ///- Handle affinity for multiple processors and process priority
    uint32 affinity = sConfigMgr->GetIntDefault("UseProcessors", 0);
    bool highPriority = sConfigMgr->GetBoolDefault("ProcessPriority", false);

#ifdef _WIN32 // Windows

    HANDLE hProcess = GetCurrentProcess();

    if (affinity > 0)
    {
        ULONG_PTR appAff;
        ULONG_PTR sysAff;

        if (GetProcessAffinityMask(hProcess, &appAff, &sysAff))
        {
            ULONG_PTR currentAffinity = affinity & appAff;            // remove non accessible processors

            if (!currentAffinity)
                SF_LOG_ERROR("server.worldserver", "Processors marked in UseProcessors bitmask (hex) %x are not accessible for the worldserver. Accessible processors bitmask (hex): %x", affinity, appAff);
            else if (SetProcessAffinityMask(hProcess, currentAffinity))
                SF_LOG_INFO("server.worldserver", "Using processors (bitmask, hex): %x", currentAffinity);
            else
                SF_LOG_ERROR("server.worldserver", "Can't set used processors (hex): %x", currentAffinity);
        }
    }

    if (highPriority)
    {
        if (SetPriorityClass(hProcess, HIGH_PRIORITY_CLASS))
            SF_LOG_INFO("server.worldserver", "worldserver process priority class set to HIGH");
        else
            SF_LOG_ERROR("server.worldserver", "Can't set worldserver process priority class.");
    }
#else // Linux

    if (affinity > 0)
    {
        cpu_set_t mask;
        CPU_ZERO(&mask);

        for (unsigned int i = 0; i < sizeof(affinity) * 8; ++i)
            if (affinity & (1 << i))
                CPU_SET(i, &mask);

        if (sched_setaffinity(0, sizeof(mask), &mask))
            SF_LOG_ERROR("server.worldserver", "Can't set used processors (hex): %x, error: %s", affinity, strerror(errno));
        else
        {
            CPU_ZERO(&mask);
            sched_getaffinity(0, sizeof(mask), &mask);
            SF_LOG_INFO("server.worldserver", "Using processors (bitmask, hex): %lx", *(__cpu_mask*)(&mask));
        }
    }

    if (highPriority)
    {
        if (setpriority(PRIO_PROCESS, 0, PROCESS_HIGH_PRIORITY))
            SF_LOG_ERROR("server.worldserver", "Can't set worldserver process priority class, error: %s", strerror(errno));
        else
            SF_LOG_INFO("server.worldserver", "worldserver process priority class set to %i", getpriority(PRIO_PROCESS, 0));
    }

#endif
#endif

    //Start soap serving thread
    SFSoapService soapService;

    if (sConfigMgr->GetBoolDefault("SOAP.Enabled", false))
    {
        soapService.Start(sConfigMgr->GetStringDefault("SOAP.IP", "127.0.0.1"), uint16(sConfigMgr->GetIntDefault("SOAP.Port", 7878)));
    }

    ///- Start up freeze catcher thread
    Skyfire::Asio::IoContextTaskRunner freezeDetectorRunner;
    if (uint32 freezeDelay = sConfigMgr->GetIntDefault("MaxCoreStuckTime", 0))
    {
        FreezeDetectorRunnable fdr;
        fdr.SetDelayTime(freezeDelay * 1000);
        if (freezeDetectorRunner.Start([fdr]() mutable { fdr.Run(); }) == -1)
            SF_LOG_ERROR("server.worldserver", "Failed to start anti-freeze task");
    }

    ///- Launch the world listener socket
    uint16 worldPort = uint16(sWorld->getIntConfig(WorldIntConfigs::CONFIG_PORT_WORLD));
    std::string bindIp = sConfigMgr->GetStringDefault("BindIP", "0.0.0.0");

    if (sWorldSocketMgr->StartNetwork(worldPort, bindIp.c_str()) == -1)
    {
        SF_LOG_ERROR("server.worldserver", "Failed to start network");
        World::StopNow(ERROR_EXIT_CODE);
        // go down and shutdown the server
    }

    // set server online (allow connecting now)
    for (std::map<uint32, std::string>::const_iterator itr = realmNameStore.begin(); itr != realmNameStore.end(); ++itr)
    {
        LoginDatabase.DirectPExecute("UPDATE realmlist SET flag = flag & ~%u, population = 0 WHERE id = '%u'", REALM_FLAG_INVALID, itr->first);
    }

    SF_LOG_INFO("server.worldserver",  " % s (worldserver-daemon) ready...", SKYFIRE_VER_PRODUCTVERSION_STR);

    // when the main thread closes the singletons get unloaded
    // since worldrunnable uses them, it will crash if unloaded after master
    worldRunner.Join();

    raRunner.Join();

    freezeDetectorRunner.Join();

    soapService.Join();

    // set server offline
    for (std::map<uint32, std::string>::const_iterator itr = realmNameStore.begin(); itr != realmNameStore.end(); ++itr)
    {
        LoginDatabase.DirectPExecute("UPDATE realmlist SET flag = flag | %u WHERE id = '%d'", REALM_FLAG_OFFLINE, itr->first);
    }

    ///- Clean database before leaving
    ClearOnlineAccounts();

    _StopDB();

    SF_LOG_INFO("server.worldserver", "Halting process...");

    if (cliRunner)
    {
#ifdef _WIN32

        // this only way to terminate CLI thread exist at Win32 (alt. way exist only in Windows Vista API)
        //_exit(1);
        // send keyboard input to safely unblock the CLI thread
        INPUT_RECORD b[4];
        HANDLE hStdIn = GetStdHandle(STD_INPUT_HANDLE);
        b[0].EventType = KEY_EVENT;
        b[0].Event.KeyEvent.bKeyDown = TRUE;
        b[0].Event.KeyEvent.uChar.AsciiChar = 'X';
        b[0].Event.KeyEvent.wVirtualKeyCode = 'X';
        b[0].Event.KeyEvent.wRepeatCount = 1;

        b[1].EventType = KEY_EVENT;
        b[1].Event.KeyEvent.bKeyDown = FALSE;
        b[1].Event.KeyEvent.uChar.AsciiChar = 'X';
        b[1].Event.KeyEvent.wVirtualKeyCode = 'X';
        b[1].Event.KeyEvent.wRepeatCount = 1;

        b[2].EventType = KEY_EVENT;
        b[2].Event.KeyEvent.bKeyDown = TRUE;
        b[2].Event.KeyEvent.dwControlKeyState = 0;
        b[2].Event.KeyEvent.uChar.AsciiChar = '\r';
        b[2].Event.KeyEvent.wVirtualKeyCode = VK_RETURN;
        b[2].Event.KeyEvent.wRepeatCount = 1;
        b[2].Event.KeyEvent.wVirtualScanCode = 0x1c;

        b[3].EventType = KEY_EVENT;
        b[3].Event.KeyEvent.bKeyDown = FALSE;
        b[3].Event.KeyEvent.dwControlKeyState = 0;
        b[3].Event.KeyEvent.uChar.AsciiChar = '\r';
        b[3].Event.KeyEvent.wVirtualKeyCode = VK_RETURN;
        b[3].Event.KeyEvent.wVirtualScanCode = 0x1c;
        b[3].Event.KeyEvent.wRepeatCount = 1;
        DWORD numb;
        WriteConsoleInput(hStdIn, b, 4, &numb);

        cliRunner->Join();

#else

        cliRunner->Join();

#endif
    }

    // for some unknown reason, unloading scripts here and not in worldrunnable
    // fixes a memory leak related to detaching threads from the module
    //UnloadScriptingModule();

    // Exit the process with specified return value
    return World::GetExitCode();
}

/// Initialize connection to the databases
bool Master::_StartDB()
{
    MySQL::Library_Init();

    std::string dbString;
    uint8 asyncThreads, synchThreads;

    if (_noUseConfigDatabaseInfo == false)
    {
        dbString = sConfigMgr->GetStringDefault("WorldDatabaseInfo", "");
        if (dbString.empty())
        {
            SF_LOG_ERROR("server.worldserver", "World database not specified in configuration file");
            return false;
        }
    }

    asyncThreads = uint8(sConfigMgr->GetIntDefault("WorldDatabase.WorkerThreads", 1));
    if (asyncThreads < 1 || asyncThreads > 32)
    {
        SF_LOG_ERROR("server.worldserver", "World database: invalid number of worker threads specified. "
            "Please pick a value between 1 and 32.");
        return false;
    }

    synchThreads = uint8(sConfigMgr->GetIntDefault("WorldDatabase.SynchThreads", 1));

    Skyfire::Database::SetupOptions worldSetupOptions = LoadWorldDatabaseSetupOptions();
    MySQLConnectionInfo worldSetupConnectionInfo = _noUseConfigDatabaseInfo == false
        ? MySQLConnectionInfo(dbString)
        : MySQLConnectionInfo(_dbHost, _dbPort, _dbUser, _dbPassword, _worldDB);

    if (!RunWorldDatabaseSetup(worldSetupConnectionInfo, worldSetupOptions))
        return false;

    if (_noUseConfigDatabaseInfo == false)
    {

        ///- Initialize the world database
        if (!WorldDatabase.Open(dbString, asyncThreads, synchThreads))
        {
            SF_LOG_ERROR("server.worldserver", "Cannot connect to world database %s", dbString.c_str());
            return false;
        }
    }
    else
    {
        if (!WorldDatabase.Open(_dbHost, _dbPort, _dbUser, _dbPassword, _worldDB, asyncThreads, synchThreads))
        {
            SF_LOG_ERROR("server.worldserver", "Cannot connect to world database %s, %s, %s, %s, %s", _dbHost, _dbPort, _dbUser, _dbPassword, _worldDB);
            return false;
        }
    }

    if (_noUseConfigDatabaseInfo == false)
    {
        ///- Get character database info from configuration file
        dbString = sConfigMgr->GetStringDefault("CharacterDatabaseInfo", "");
        if (dbString.empty())
        {
            SF_LOG_ERROR("server.worldserver", "Character database not specified in configuration file");
            return false;
        }
    }

    asyncThreads = uint8(sConfigMgr->GetIntDefault("CharacterDatabase.WorkerThreads", 1));
    if (asyncThreads < 1 || asyncThreads > 32)
    {
        SF_LOG_ERROR("server.worldserver", "Character database: invalid number of worker threads specified. "
            "Please pick a value between 1 and 32.");
        return false;
    }

    synchThreads = uint8(sConfigMgr->GetIntDefault("CharacterDatabase.SynchThreads", 2));

    Skyfire::Database::SetupOptions characterSetupOptions = LoadCharacterDatabaseSetupOptions();
    MySQLConnectionInfo characterSetupConnectionInfo = _noUseConfigDatabaseInfo == false
        ? MySQLConnectionInfo(dbString)
        : MySQLConnectionInfo(_dbHost, _dbPort, _dbUser, _dbPassword, _charactersDB);

    if (!RunCharacterDatabaseSetup(characterSetupConnectionInfo, characterSetupOptions))
        return false;

    if (_noUseConfigDatabaseInfo == false)
    {
        ///- Initialize the Character database
        if (!CharacterDatabase.Open(dbString, asyncThreads, synchThreads))
        {
            SF_LOG_ERROR("server.worldserver", "Cannot connect to Character database%s, %s", dbString.c_str());
            return false;
        }
    }
    else
    {
        ///- Initialize the Character database
        if (!CharacterDatabase.Open(_dbHost, _dbPort, _dbUser, _dbPassword, _charactersDB, asyncThreads, synchThreads))
        {
            SF_LOG_ERROR("server.worldserver", "Cannot connect to Character database%s, %s, %s, %s, %s", _dbHost, _dbPort, _dbUser, _dbPassword, _charactersDB);
            return false;
        }
    }

    if (_noUseConfigDatabaseInfo == false)
    {
        ///- Get login database info from configuration file
        dbString = sConfigMgr->GetStringDefault("LoginDatabaseInfo", "");
        if (dbString.empty())
        {
            SF_LOG_ERROR("server.worldserver", "Login database not specified in configuration file");
            return false;
        }
    }

    asyncThreads = uint8(sConfigMgr->GetIntDefault("LoginDatabase.WorkerThreads", 1));
    if (asyncThreads < 1 || asyncThreads > 32)
    {
        SF_LOG_ERROR("server.worldserver", "Login database: invalid number of worker threads specified. "
            "Please pick a value between 1 and 32.");
        return false;
    }

    synchThreads = uint8(sConfigMgr->GetIntDefault("LoginDatabase.SynchThreads", 1));

    if (_noUseConfigDatabaseInfo == false)
    {
        ///- Initialise the login database
        if (!LoginDatabase.Open(dbString, asyncThreads, synchThreads))
        {
            SF_LOG_ERROR("server.worldserver", "Cannot connect to login database %s", dbString.c_str());
            return false;
        }
    }
    else
    {
        if (!LoginDatabase.Open(_dbHost, _dbPort, _dbUser, _dbPassword, _authDB, asyncThreads, synchThreads))
        {
            SF_LOG_ERROR("server.worldserver", "Cannot connect to database%s %s, %s, %s, %s", _dbHost, _dbPort, _dbUser, _dbPassword, _authDB);
            return false;
        }
    }

    // Load realm names into a store
    PreparedStatement* stmt = LoginDatabase.GetPreparedStatement(LOGIN_SEL_REALMLIST);
    stmt->setInt32(0, sConfigMgr->GetIntDefault("WorldServerPort", 8085));
    PreparedQueryResult result = LoginDatabase.Query(stmt);
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            realmNameStore[fields[0].GetUInt32()] = fields[1].GetString(); // Store the realm name into the store
        } while (result->NextRow());
    }
    for (std::map<uint32, std::string>::const_iterator itr = realmNameStore.begin(); itr != realmNameStore.end(); ++itr)
    {
        SF_LOG_INFO("server.worldserver", "World running as realm ID %d", itr->first);
    }

    ///- Clean the database before starting
    ClearOnlineAccounts();

    ///- Insert version info into DB
    WorldDatabase.PExecute("UPDATE version SET core_version = '%s', core_revision = '%s'", SKYFIRE_VER_PRODUCTVERSION_STR, _HASH);        // One-time query

    sWorld->LoadDBVersion();

    SF_LOG_INFO("server.worldserver", "Using World DB: %s", sWorld->GetDBVersion());
    return true;
}

void Master::_StopDB()
{
    CharacterDatabase.Close();
    WorldDatabase.Close();
    LoginDatabase.Close();

    MySQL::Library_End();
}

/// Clear 'online' status for all accounts with characters in this realm
void Master::ClearOnlineAccounts()
{
    // Reset online status for all accounts with characters on the current realm
    for (std::map<uint32, std::string>::const_iterator itr = realmNameStore.begin(); itr != realmNameStore.end(); ++itr)
    {
        LoginDatabase.DirectPExecute("UPDATE account SET online = 0 WHERE online > 0 AND id IN (SELECT acctid FROM realmcharacters WHERE realmid = %d)", itr->first);
    }

    // Reset online status for all characters
    CharacterDatabase.DirectExecute("UPDATE characters SET online = 0 WHERE online <> 0");

    // Battleground instance ids reset at server restart
    CharacterDatabase.DirectExecute("UPDATE character_battleground_data SET instanceId = 0");
}
