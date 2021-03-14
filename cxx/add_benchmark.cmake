macro(cmake_cxx_add_benchmark name)
    cmake_parse_arguments(${name} "" "LIST_FILE" "WITH_LIBS" ${ARGN})

    message(CHECK_START "cmake_cxx_add_benchmark(${name})")
    list(APPEND CMAKE_MESSAGE_INDENT "    ")

    include(cmake/cxx/google_benchmark.cmake)
    if(${name}_LIST_FILE)
        include(${${name}_LIST_FILE})
    else()
        include(${name}/list.cmake)
    endif()
    add_executable(${name}_bench ${${name}_bench_sources})
    target_link_libraries(${name}_bench ${${name}_WITH_LIBS} benchmark)

    list(POP_BACK CMAKE_MESSAGE_INDENT)
    message(CHECK_PASS "done")
endmacro()
