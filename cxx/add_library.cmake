macro(cmake_cxx_add_library name)
    cmake_parse_arguments(${name} "WITH_TEST;WITH_COV;WITH_DOC" "LIST_FILE" "WITH_LIBS" ${ARGN})

    message(CHECK_START "cmake_cxx_add_library(${name})")
    list(APPEND CMAKE_MESSAGE_INDENT "    ")

    # library {{{1
    if(${name}_LIST_FILE)
        include(${${name}_LIST_FILE})
    else()
        include(${name}/list.cmake)
    endif()
    add_library(${name} ${${name}_sources})
    add_library(${name}::${name} ALIAS ${name})
    target_include_directories(${name}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
    target_compile_options(${name} PRIVATE ${cc_cxx_max_warning_flags})

    # test {{{1
    message(CHECK_START "test")
    if(${name}_WITH_TEST)
        if(${name}_test_sources)
            list(APPEND CMAKE_MESSAGE_INDENT "    ")
            enable_testing()
            include(cmake/cxx/catchorg_catch2.cmake)
            add_executable(${name}_test ${${name}_test_sources})
            target_compile_options(${name}_test PRIVATE ${cc_cxx_max_warning_flags})
            target_link_libraries(${name}_test ${name}::${name} Catch2::Catch2 ${${name}_WITH_LIBS})
            catch_discover_tests(${name}_test)
            list(POP_BACK CMAKE_MESSAGE_INDENT)
            message(CHECK_PASS "found")
        else()
            message(CHECK_FAIL "not found")
        endif()
    else()
        message(CHECK_FAIL "not enabled")
    endif()

    message(CHECK_START "coverage")
    if(${name}_WITH_COV)
        if(NOT ${name}_WITH_TEST)
            message(CHECK_FAIL "no tests")
            set(${name}_WITH_COV OFF)
        endif()
    else()
        message(CHECK_FAIL "not enabled")
    endif()
    if(${name}_WITH_COV)
        if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU")
            message(CHECK_FAIL "unsupported compiler")
            set(${name}_WITH_COV OFF)
        endif()
    endif()
    if(${name}_WITH_COV)
        find_program(LCOV lcov)
        if(NOT LCOV)
            message(CHECK_FAIL "lcov not found")
            set(${name}_WITH_COV OFF)
        endif()
    endif()
    if(${name}_WITH_COV)
        if(DEFINED ENV{COV})
            find_program(COV $ENV{COV})
        else()
            find_program(COV gcov)
        endif()
        if(NOT COV)
            message(CHECK_FAIL "gcov not found")
            set(${name}_WITH_COV OFF)
        endif()
    endif()
    if(${name}_WITH_COV)
        find_program(GENHTML genhtml)
        if(NOT GENHTML)
            message(CHECK_FAIL "genhtml not found")
            set(${name}_WITH_COV OFF)
        endif()
    endif()
    if(${name}_WITH_COV)
        message(CHECK_PASS "enabled")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -coverage")
        set(LCOV_ARGS
            --quiet
            --base-directory ${CMAKE_SOURCE_DIR}/${name}
            --directory ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles
            --exclude '**/_deps/*'
            --rc lcov_branch_coverage=1
            --gcov-tool ${COV}
        )
        add_custom_target(${name}-cov
            DEPENDS ${name}_test
            USES_TERMINAL
            COMMENT "Generage coverage information"

            # Initialize
            COMMAND ${LCOV} ${LCOV_ARGS} --zerocounters
            COMMAND ${LCOV} ${LCOV_ARGS} --initial --capture --no-external --output-file ${name}-base.info

            # Run and extract
            COMMAND $<TARGET_FILE:${name}_test>
            COMMAND ${LCOV} ${LCOV_ARGS} --capture --no-external --output-file ${name}-tests.info
            COMMAND ${LCOV} ${LCOV_ARGS} --add-tracefile ${name}-base.info --add-tracefile ${name}-tests.info --output-file ${name}.info
            COMMAND ${LCOV} ${LCOV_ARGS} --remove ${name}.info '**/${name}/*test*' --output-file ${name}.info
            COMMAND ${LCOV} ${LCOV_ARGS} --list ${name}.info
            COMMAND ${LCOV} ${LCOV_ARGS} --summary ${name}.info
        )
        add_custom_command(TARGET ${name}-cov POST_BUILD
            COMMENT "Open ${CMAKE_BINARY_DIR}/cov/index.html in your browser"
            COMMAND ${GENHTML} --rc lcov_branch_coverage=1 -q --demangle-cpp --legend --output-directory cov ${name}.info
        )
    endif()

    # doc {{{1
    message(CHECK_START "documentation")
    if(${name}_WITH_DOC)
        list(APPEND CMAKE_MESSAGE_INDENT "    ")
        find_package(Doxygen)
        list(POP_BACK CMAKE_MESSAGE_INDENT)
        if(DOXYGEN_FOUND)
            configure_file(
                ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Doxyfile.in
                ${CMAKE_BINARY_DIR}/Doxyfile
            )
            add_custom_target(${name}-doc
                COMMENT "Generate documentation"
                COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_BINARY_DIR}/Doxyfile
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            )
            message(CHECK_PASS "enabled")
        else()
            message(CHECK_FAIL "doxygen not found")
        endif()
    else()
        message(CHECK_FAIL "not enabled")
    endif()

    # }}}1

    list(POP_BACK CMAKE_MESSAGE_INDENT)
    message(CHECK_PASS "done")
endmacro()
