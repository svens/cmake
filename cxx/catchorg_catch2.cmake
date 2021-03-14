include(FetchContent)
FetchContent_Declare(Catch2
    URL https://github.com/catchorg/Catch2/archive/v2.13.4.tar.gz
)
FetchContent_MakeAvailable(Catch2)
FetchContent_GetProperties(Catch2 SOURCE_DIR Catch2_SOURCE_DIR)
include(${Catch2_SOURCE_DIR}/contrib/Catch.cmake)
