include(FetchContent)
FetchContent_Declare(Benchmark
    URL https://github.com/google/benchmark/archive/v1.5.2.tar.gz
)
set(BENCHMARK_ENABLE_TESTING OFF)
set(BENCHMARK_ENABLE_INSTALL OFF)
FetchContent_MakeAvailable(Benchmark)
