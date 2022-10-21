cmake_minimum_required(VERSION 3.16)
project(apriltag VERSION 3.3.0 LANGUAGES C CXX)

set(CMAKE_FIND_DEBUG_MODE 1)

add_executable(test hello.cpp)
find_package(apriltag 3.3)


target_link_libraries(test apriltag::detector apriltag::tagStandard41h12)

# get_cmake_property(_variableNames VARIABLES)
# list (SORT _variableNames)
# foreach (_variableName ${_variableNames})
#     message(STATUS "${_variableName}=${${_variableName}}")
# endforeach(