#
# This file is part of Project SkyFire https://www.projectskyfire.org.
# See COPYRIGHT file for Copyright information
#

add_executable(database_queue_tests
  ${CMAKE_SOURCE_DIR}/src/server/shared/Database/DatabaseQueue.cpp
  ${CMAKE_SOURCE_DIR}/src/server/shared/Database/DatabaseWorker.cpp
  DatabaseQueueTests.cpp
)

target_include_directories(database_queue_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Configuration
  ${CMAKE_SOURCE_DIR}/src/server/shared/Database
  ${CMAKE_SOURCE_DIR}/src/server/shared/DataStores
  ${CMAKE_SOURCE_DIR}/src/server/shared/Debugging
  ${CMAKE_SOURCE_DIR}/src/server/shared/Dynamic
  ${CMAKE_SOURCE_DIR}/src/server/shared/Logging
  ${CMAKE_SOURCE_DIR}/src/server/shared/Network
  ${CMAKE_SOURCE_DIR}/src/server/shared/Packets
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities
  ${Boost_INCLUDE_DIRS}
  ${MYSQL_INCLUDE_DIR}
)

if(TARGET Boost::headers)
  target_link_libraries(database_queue_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(database_queue_tests Boost::boost)
endif()

target_link_libraries(database_queue_tests Threads::Threads)

add_test(NAME database_queue_tests COMMAND database_queue_tests)

add_executable(realm_socket_tests
  ${CMAKE_SOURCE_DIR}/src/server/authserver/Server/RealmSocket.cpp
  RealmSocketLogStub.cpp
  RealmSocketTests.cpp
)

target_include_directories(realm_socket_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Configuration
  ${CMAKE_SOURCE_DIR}/src/server/shared/Database
  ${CMAKE_SOURCE_DIR}/src/server/shared/DataStores
  ${CMAKE_SOURCE_DIR}/src/server/shared/Debugging
  ${CMAKE_SOURCE_DIR}/src/server/shared/Dynamic
  ${CMAKE_SOURCE_DIR}/src/server/shared/Logging
  ${CMAKE_SOURCE_DIR}/src/server/shared/Network
  ${CMAKE_SOURCE_DIR}/src/server/shared/Packets
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities
  ${CMAKE_SOURCE_DIR}/src/server/authserver/Server
  ${Boost_INCLUDE_DIRS}
  ${MYSQL_INCLUDE_DIR}
  ${OPENSSL_INCLUDE_DIR}
)

if(TARGET Boost::headers)
  target_link_libraries(realm_socket_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(realm_socket_tests Boost::boost)
endif()

target_link_libraries(realm_socket_tests
  Threads::Threads
)

add_test(NAME realm_socket_tests COMMAND realm_socket_tests)

add_executable(auth_patch_transfer_tests
  AuthPatchTransferTests.cpp
)

target_include_directories(auth_patch_transfer_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/authserver/Server
)

add_test(NAME auth_patch_transfer_tests COMMAND auth_patch_transfer_tests)

add_executable(network_address_tests
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities/NetworkAddress.cpp
  NetworkAddressTests.cpp
)

target_include_directories(network_address_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(network_address_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(network_address_tests Boost::boost)
endif()

add_test(NAME network_address_tests COMMAND network_address_tests)

add_executable(memory_usage_tests
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities/MemoryUsage.cpp
  MemoryUsageTests.cpp
)

target_include_directories(memory_usage_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities
)

add_test(NAME memory_usage_tests COMMAND memory_usage_tests)

add_executable(boost_asio_utils_tests
  BoostAsioUtilsTests.cpp
)

target_include_directories(boost_asio_utils_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Network
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_utils_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_utils_tests Boost::boost)
endif()

add_test(NAME boost_asio_utils_tests COMMAND boost_asio_utils_tests)

add_executable(boost_asio_work_tests
  BoostAsioWorkTests.cpp
)

target_include_directories(boost_asio_work_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_work_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_work_tests Boost::boost)
endif()

add_test(NAME boost_asio_work_tests COMMAND boost_asio_work_tests)

add_executable(boost_asio_write_queue_tests
  BoostAsioWriteQueueTests.cpp
)

target_include_directories(boost_asio_write_queue_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Network
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_write_queue_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_write_queue_tests Boost::boost)
endif()

add_test(NAME boost_asio_write_queue_tests COMMAND boost_asio_write_queue_tests)

add_executable(boost_asio_executor_tests
  BoostAsioExecutorTests.cpp
)

target_include_directories(boost_asio_executor_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_executor_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_executor_tests Boost::boost)
endif()

add_test(NAME boost_asio_executor_tests COMMAND boost_asio_executor_tests)

add_executable(boost_asio_thread_group_tests
  BoostAsioThreadGroupTests.cpp
)

target_include_directories(boost_asio_thread_group_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_thread_group_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_thread_group_tests Boost::boost)
endif()

target_link_libraries(boost_asio_thread_group_tests Threads::Threads)

add_test(NAME boost_asio_thread_group_tests COMMAND boost_asio_thread_group_tests)

add_executable(boost_asio_thread_tests
  BoostAsioThreadTests.cpp
)

target_include_directories(boost_asio_thread_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_thread_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_thread_tests Boost::boost)
endif()

target_link_libraries(boost_asio_thread_tests Threads::Threads)

add_test(NAME boost_asio_thread_tests COMMAND boost_asio_thread_tests)

add_executable(boost_asio_task_runner_tests
  BoostAsioTaskRunnerTests.cpp
)

target_include_directories(boost_asio_task_runner_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(boost_asio_task_runner_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(boost_asio_task_runner_tests Boost::boost)
endif()

target_link_libraries(boost_asio_task_runner_tests Threads::Threads)

add_test(NAME boost_asio_task_runner_tests COMMAND boost_asio_task_runner_tests)

add_executable(delay_executor_tests
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading/DelayExecutor.cpp
  DelayExecutorTests.cpp
)

target_include_directories(delay_executor_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(delay_executor_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(delay_executor_tests Boost::boost)
endif()

target_link_libraries(delay_executor_tests Threads::Threads)

add_test(NAME delay_executor_tests COMMAND delay_executor_tests)

add_executable(time_utils_tests
  TimeUtilsTests.cpp
)

target_include_directories(time_utils_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
)

add_test(NAME time_utils_tests COMMAND time_utils_tests)

add_executable(sfsoap_service_tests
  SFSoapServiceTests.cpp
)

target_include_directories(sfsoap_service_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Threading
  ${CMAKE_SOURCE_DIR}/src/server/worldserver/SFSoap
  ${Boost_INCLUDE_DIRS}
)

if(TARGET Boost::headers)
  target_link_libraries(sfsoap_service_tests Boost::headers)
elseif(TARGET Boost::boost)
  target_link_libraries(sfsoap_service_tests Boost::boost)
endif()

target_link_libraries(sfsoap_service_tests Threads::Threads)

add_test(NAME sfsoap_service_tests COMMAND sfsoap_service_tests)

add_executable(world_socket_session_state_tests
  WorldSocketSessionStateTests.cpp
)

target_include_directories(world_socket_session_state_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/game/Server
)

add_test(NAME world_socket_session_state_tests COMMAND world_socket_session_state_tests)

add_executable(game_domain_tests
  ${CMAKE_SOURCE_DIR}/src/server/game/Spells/SpellTargeting.cpp
  GameDomainTestSupport.cpp
  GameDomainTests.cpp
)

target_include_directories(game_domain_tests PRIVATE
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/dep/recastnavigation/Detour
  ${CMAKE_SOURCE_DIR}/src/server/shared
  ${CMAKE_SOURCE_DIR}/src/server/shared/Configuration
  ${CMAKE_SOURCE_DIR}/src/server/shared/Cryptography
  ${CMAKE_SOURCE_DIR}/src/server/shared/DataStores
  ${CMAKE_SOURCE_DIR}/src/server/shared/Debugging
  ${CMAKE_SOURCE_DIR}/src/server/shared/Dynamic
  ${CMAKE_SOURCE_DIR}/src/server/shared/Dynamic/LinkedReference
  ${CMAKE_SOURCE_DIR}/src/server/shared/Logging
  ${CMAKE_SOURCE_DIR}/src/server/shared/Packets
  ${CMAKE_SOURCE_DIR}/src/server/shared/Platform
  ${CMAKE_SOURCE_DIR}/src/server/shared/Utilities
  ${CMAKE_SOURCE_DIR}/src/server/game
  ${CMAKE_SOURCE_DIR}/src/server/game/Achievements
  ${CMAKE_SOURCE_DIR}/src/server/game/AI
  ${CMAKE_SOURCE_DIR}/src/server/game/AI/CoreAI
  ${CMAKE_SOURCE_DIR}/src/server/game/AI/ScriptedAI
  ${CMAKE_SOURCE_DIR}/src/server/game/AI/SmartScripts
  ${CMAKE_SOURCE_DIR}/src/server/game/BattlePet
  ${CMAKE_SOURCE_DIR}/src/server/game/Chat
  ${CMAKE_SOURCE_DIR}/src/server/game/Combat
  ${CMAKE_SOURCE_DIR}/src/server/game/Conditions
  ${CMAKE_SOURCE_DIR}/src/server/game/DataStores
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Creature
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/GameObject
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Item
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Item/Container
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Object
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Object/Updates
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Pet
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Player
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Transport
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Unit
  ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Vehicle
  ${CMAKE_SOURCE_DIR}/src/server/game/Globals
  ${CMAKE_SOURCE_DIR}/src/server/game/Grids
  ${CMAKE_SOURCE_DIR}/src/server/game/Grids/Cells
  ${CMAKE_SOURCE_DIR}/src/server/game/Grids/Notifiers
  ${CMAKE_SOURCE_DIR}/src/server/game/Groups
  ${CMAKE_SOURCE_DIR}/src/server/game/Guilds
  ${CMAKE_SOURCE_DIR}/src/server/game/Handlers
  ${CMAKE_SOURCE_DIR}/src/server/game/Instances
  ${CMAKE_SOURCE_DIR}/src/server/game/Maps
  ${CMAKE_SOURCE_DIR}/src/server/game/Miscellaneous
  ${CMAKE_SOURCE_DIR}/src/server/game/Movement
  ${CMAKE_SOURCE_DIR}/src/server/game/Movement/MovementGenerators
  ${CMAKE_SOURCE_DIR}/src/server/game/Movement/Spline
  ${CMAKE_SOURCE_DIR}/src/server/game/Movement/Waypoints
  ${CMAKE_SOURCE_DIR}/src/server/game/Quests
  ${CMAKE_SOURCE_DIR}/src/server/game/Scripting
  ${CMAKE_SOURCE_DIR}/src/server/game/Server
  ${CMAKE_SOURCE_DIR}/src/server/game/Server/Protocol
  ${CMAKE_SOURCE_DIR}/src/server/game/Spells
  ${CMAKE_SOURCE_DIR}/src/server/game/Spells/Auras
  ${CMAKE_SOURCE_DIR}/src/server/game/Tools
  ${CMAKE_SOURCE_DIR}/src/server/game/World
  ${Boost_INCLUDE_DIRS}
)

add_test(NAME game_domain_tests COMMAND game_domain_tests)
