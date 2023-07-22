# https://docs.microsoft.com/en-us/cpp/preprocessor/compiler-warnings-that-are-off-by-default
set(cxx_max_warning_flags /W4 /WX /w34265 /w34777 /w34946 /w35038)

if(${CMAKE_MINIMUM_REQUIRED_VERSION} VERSION_LESS "3.15")
	# cmake >= 3.15 stopped adding /W3 option
	string(REGEX REPLACE "/W3" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
endif()
