macro(cxx_library name)
	cmake_parse_arguments(${name} "" "ALIAS" "SOURCES;LIBRARIES" ${ARGN})

	message(CHECK_START "cxx_library(${name})")
	list(APPEND CMAKE_MESSAGE_INDENT "    ")

	add_library(${name} ${${name}_SOURCES})

	if(${name}_ALIAS)
		add_library(${${name}_ALIAS} ALIAS ${name})
	endif()

	target_include_directories(${name}
		PUBLIC
			$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	)
	target_compile_options(${name} PRIVATE ${cxx_max_warning_flags})

	if(${name}_LIBRARIES)
		target_link_libraries(${name} ${${name}_LIBRARIES})
	endif()

	list(POP_BACK CMAKE_MESSAGE_INDENT)
	message(CHECK_PASS "done")
endmacro()
