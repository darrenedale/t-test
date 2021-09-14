cmake_minimum_required(VERSION 3.10)

project(TTest)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED True)

add_executable(
    TTest
    src/t-test.c
    src/util.c
    src/statistics/datafile.c
    src/statistics/ttest.c
    src/statistics/util.c
)

target_link_libraries(
    TTest
    m
)

set_target_properties(
    TTest
    PROPERTIES
    RUNTIME_OUTPUT_NAME t-test
)
