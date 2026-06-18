#
# This file is part of Project SkyFire https://www.projectskyfire.org. 
# See COPYRIGHT file for Copyright information
#
set(SFMT_STAT_SRCS
  sfmt.cpp
)

add_library(SFMT STATIC ${SFMT_STAT_SRCS})

target_include_directories(SFMT PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch")
  target_include_directories(SFMT PUBLIC
    ${CMAKE_SOURCE_DIR}/dep/sse2neon
  )
endif()
