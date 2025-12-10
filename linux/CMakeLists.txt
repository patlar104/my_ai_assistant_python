cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "my_ai_assistant")
set(APPLICATION_ID "com.example.my_ai_assistant")

file(GLOB_RECURSE SOURCES
  "flutter/ephemeral/.plugin_symlinks/*/linux/src/*.cpp"
  "flutter/ephemeral/.plugin_symlinks/*/linux/src/*.h"
  "flutter/ephemeral/.plugin_symlinks/*/linux/src/*.c"
  "*.cpp"
  "*.h"
  "*.c"
)

add_executable(${BINARY_NAME} ${SOURCES})

apply_standard_settings(${BINARY_NAME} "cpp")

target_compile_definitions(${BINARY_NAME} PRIVATE "APPLICATION_ID=\"${APPLICATION_ID}\"")

target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}/flutter"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
