function(_cxx_test_cov name base_dir)
	message(CHECK_START "Coverage")

	if(NOT "${CMAKE_BUILD_TYPE};${CMAKE_CONFIGURATION_TYPES}" MATCHES ".*Coverage.*")
		message(CHECK_FAIL "not enabled")
		return()
	endif()

	if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU")
		message(CHECK_FAIL "unsupported compiler")
		return()
	endif()

	find_program(LCOV lcov)
	if(NOT LCOV)
		message(CHECK_FAIL "lcov not found")
		return()
	endif()

	if(DEFINED ENV{COV})
		find_program(COV $ENV{COV})
	else()
		find_program(COV gcov)
	endif()
	if(NOT COV)
		message(CHECK_FAIL "gcov not found")
		return()
	endif()

	find_program(GENHTML genhtml)
	if(NOT GENHTML)
		message(CHECK_FAIL "genhtml not found")
		return()
	endif()

	message(CHECK_PASS "enabled")

	set(LCOV_ARGS
		--quiet
		--base-directory ${base_dir}
		--exclude '${base_dir}/*test*'
		--exclude '${base_dir}/**/*test*'
		--exclude '${base_dir}/*bench*'
		--exclude '${base_dir}/**/*bench*'
		--exclude '**/_deps/*'
		--directory ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles
		--rc lcov_branch_coverage=1
		--gcov-tool ${COV}
	)
	add_custom_target(${name}-cov
		DEPENDS ${name}
		USES_TERMINAL
		COMMENT "Generate coverage information"

		COMMAND ${LCOV} ${LCOV_ARGS} --zerocounters
		COMMAND $<TARGET_FILE:${name}>
		COMMAND ${LCOV} ${LCOV_ARGS} --capture --no-external --output-file ${name}.info
		COMMAND ${LCOV} ${LCOV_ARGS} --list ${name}.info
	)
	add_custom_command(TARGET ${name}-cov POST_BUILD
		COMMENT "Generating ${CMAKE_BINARY_DIR}/cov/index.html"
		COMMAND ${GENHTML} --rc lcov_branch_coverage=1 -q --demangle-cpp --legend --output-directory cov ${name}.info
	)
endfunction()

macro(cxx_test name)
	cmake_parse_arguments(${name} "" "COVERAGE_BASE_DIR" "SOURCES;LIBRARIES" ${ARGN})

	message(CHECK_START "cxx_test(${name})")
	list(APPEND CMAKE_MESSAGE_INDENT "    ")

	enable_testing()

	message(VERBOSE "Fetch catchorg/catch2")
	include(FetchContent)
	FetchContent_Declare(Catch2
		GIT_REPOSITORY https://github.com/catchorg/Catch2.git
		GIT_TAG devel
		GIT_SHALLOW ON
	)
	FetchContent_MakeAvailable(Catch2)
	FetchContent_GetProperties(Catch2 SOURCE_DIR Catch2_SOURCE_DIR)
	list(APPEND CMAKE_MODULE_PATH ${Catch2_SOURCE_DIR}/extras)

	add_executable(${name} ${${name}_SOURCES})
	target_compile_options(${name} PRIVATE ${cxx_max_warning_flags})
	target_include_directories(${name} SYSTEM PRIVATE ${Catch2_SOURCE_DIR}/src)
	target_link_libraries(${name} Catch2::Catch2 ${${name}_LIBRARIES})

	message(VERBOSE "Discover tests")
	include(Catch)
	catch_discover_tests(${name}
		EXTRA_ARGS --skip-benchmarks
	)

	_cxx_test_cov(${name} ${${name}_COVERAGE_BASE_DIR})

	list(POP_BACK CMAKE_MESSAGE_INDENT)
	message(CHECK_PASS "done")
endmacro()
