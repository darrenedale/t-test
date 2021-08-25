cmake_minimum_required(VERSION 3.10)

set(CMAKE_D_COMPILER /usr/bin/dmd)

project(TTest LANGUAGES D)

add_executable(
  TTest
  Statistics/DataFile.d
  Statistics/TTest.d
  t-test.d
  )

set_target_properties(
  TTest
  PROPERTIES
  RUNTIME_OUTPUT_NAME t-test
  )
  