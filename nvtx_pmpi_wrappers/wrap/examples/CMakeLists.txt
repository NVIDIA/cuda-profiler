project(wrap-examples)
cmake_minimum_required(VERSION 2.8)

find_package(MPI REQUIRED)
include_directories(${MPI_C_INCLUDE_PATH})

set(WRAP ${PROJECT_SOURCE_DIR}/../wrap.py)
include(${PROJECT_SOURCE_DIR}/../WrapConfig.cmake)

add_wrapped_file(world48.C world48.w)
add_library(world48 world48.C)
target_link_libraries(world48 ${MPI_C_LIBRARIES})


