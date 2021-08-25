cmake_minimum_required(VERSION 3.10)

project(TTest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(
  TTest
  src/TTest.cpp
  src/t-test.cpp
  )

set_target_properties(
  TTest
  PROPERTIES
  RUNTIME_OUTPUT_NAME t-test
  )