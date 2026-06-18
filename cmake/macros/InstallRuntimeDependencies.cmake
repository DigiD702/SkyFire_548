#
# This file is part of Project SkyFire https://www.projectskyfire.org.
# See COPYRIGHT file for Copyright information
#

function(skyfire_get_windows_runtime_dependencies out_var)
  set(runtime_dependencies)

  foreach(runtime_dependency
      "${OPENSSL_CRYPTO_DLL}"
      "${OPENSSL_SSL_DLL}"
      "${OPENSSL_LEGACY_PROVIDER_DLL}"
      "${MYSQL_DLL}")
    if(runtime_dependency)
      list(APPEND runtime_dependencies "${runtime_dependency}")
    endif()
  endforeach()

  set(${out_var} ${runtime_dependencies} PARENT_SCOPE)
endfunction()

function(skyfire_copy_windows_runtime_dependencies target)
  if(NOT WIN32)
    return()
  endif()

  skyfire_get_windows_runtime_dependencies(runtime_dependencies)

  if(NOT runtime_dependencies)
    return()
  endif()

  add_custom_command(TARGET ${target}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${runtime_dependencies}
      "$<TARGET_FILE_DIR:${target}>/"
    COMMAND_EXPAND_LISTS
  )
endfunction()

function(skyfire_install_windows_runtime_dependencies)
  if(NOT WIN32)
    return()
  endif()

  skyfire_get_windows_runtime_dependencies(runtime_dependencies)

  if(runtime_dependencies)
    install(FILES ${runtime_dependencies} DESTINATION ".")
  endif()
endfunction()
