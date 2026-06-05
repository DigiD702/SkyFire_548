#
# This file is part of Project SkyFire https://www.projectskyfire.org.
# See COPYRIGHT file for Copyright information
#

add_executable(database_queue_tests
  ${CMAKE_SOURCE_DIR}/src/server/shared/Database/DatabaseQueue.cpp
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
