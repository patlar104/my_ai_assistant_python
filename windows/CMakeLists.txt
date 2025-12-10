cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

cmake_policy(SET CMP0063 NEW)

set(BINARY_NAME "my_ai_assistant")
set(APPLICATION_ID "com.example.my_ai_assistant")

file(GLOB_RECURSE SOURCES
  "flutter/ephemeral/.plugin_symlinks/*/windows/src/*.cpp"
  "flutter/ephemeral/.plugin_symlinks/*/windows/src/*.h"
  "flutter/ephemeral/.plugin_symlinks/*/windows/src/*.c"
  "*.cpp"
  "*.h"
  "*.c"
)

add_executable(${BINARY_NAME} WIN32 ${SOURCES})

apply_standard_settings(${BINARY_NAME} "cpp" "WIN32")

target_compile_definitions(${BINARY_NAME} PRIVATE "APPLICATION_ID=\"${APPLICATION_ID}\"")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}/flutter"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
