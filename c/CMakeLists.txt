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

add_executable(
    GenericArrayDemo
    src/array-demo.c
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

set_target_properties(
    GenericArrayDemo
    PROPERTIES
    RUNTIME_OUTPUT_NAME array-demo
)
