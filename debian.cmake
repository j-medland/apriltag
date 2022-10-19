cmake_minimum_required(VERSION 3.1)
project(apriltag VERSION 3.3.0 LANGUAGES C CXX)

if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif()
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(ASAN "Use AddressSanitizer for debug builds to detect memory issues" OFF)

if (ASAN)
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} \
        -fsanitize=address \
        -fsanitize=bool \
        -fsanitize=bounds \
        -fsanitize=enum \
        -fsanitize=float-cast-overflow \
        -fsanitize=float-divide-by-zero \
        -fsanitize=nonnull-attribute \
        -fsanitize=returns-nonnull-attribute \
        -fsanitize=signed-integer-overflow \
        -fsanitize=undefined \
        -fsanitize=vla-bound \
        -fno-sanitize=alignment \
        -fsanitize=leak \
        -fsanitize=object-size \
    ")
endif()

# Set a default build type if none was specified
set(default_build_type "Release")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
    set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE  STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS  "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()


include_directories(.)

# I build two libraries:
#
# - libapriltag.so: JUST the core apriltag functionality. Symbols are namespaced
#   for the most part. Symbols not exposed to the outside by default. Only a
#   whitelist is exposed. Most users want this library
#
# - libapriltag-utils.so: All the other stuff. The Apriltag sources provide
#   utility functions for common tasks such as option parsing and jpeg
#   reading/writing, and those are available here. Most notably, the demos need
#   this library. All the symbols are exposed to the outside.

# These sources are linked into BOTH libapriltag.so and libapriltag-utils.so,
# but the symbols are all hidden (available to the DSO itself only) in the
# former case. This was needed because I want the symbols exported by the core
# library (libapriltag.so) to be minimal, and to have clear naming
set(APRILTAG_SRCS_COMMON
  common/image_u8.c
  common/pnm.c
  common/time_util.c
  common/image_u8x3.c)

# Sources to link into libapriltag.so
set(APRILTAG_SRCS
  apriltag.c apriltag_pose.c apriltag_quad_thresh.c
  common/g2d.c
  common/homography.c
  common/matd.c
  common/svd22.c
  common/unionfind.c
  common/workerpool.c
  common/zmaxheap.c)

# Sources to link into libapriltag-utils.so
set(APRILTAG_UTILS_SRCS
  common/string_util.c
  common/pjpeg-idct.c
  common/pjpeg.c
  common/image_u8x4.c
  common/getopt.c
  common/pam.c
  common/zhash.c
  common/zarray.c)

file(GLOB TAG_FILES ${CMAKE_CURRENT_SOURCE_DIR}/tag*.c)


add_library(${PROJECT_NAME}-objects
  OBJECT ${APRILTAG_SRCS}       ${APRILTAG_SRCS_COMMON} ${TAG_FILES})
target_compile_options(${PROJECT_NAME}-objects        PRIVATE -fPIC -fvisibility=hidden)
add_library(${PROJECT_NAME}
  SHARED $<TARGET_OBJECTS:${PROJECT_NAME}-objects>)

add_library(${PROJECT_NAME}-utils-objects
  OBJECT ${APRILTAG_UTILS_SRCS} ${APRILTAG_SRCS_COMMON})
target_compile_options(${PROJECT_NAME}-utils-objects  PRIVATE -fPIC -fvisibility=default)
add_library(${PROJECT_NAME}-utils
  SHARED $<TARGET_OBJECTS:${PROJECT_NAME}-utils-objects>)

if (MSVC)
    add_compile_definitions("_CRT_SECURE_NO_WARNINGS")
else()
    find_package(Threads REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC Threads::Threads m)
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")

set_target_properties(${PROJECT_NAME}       PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
set_target_properties(${PROJECT_NAME}       PROPERTIES DEBUG_POSTFIX "d")
set_target_properties(${PROJECT_NAME}-utils PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
set_target_properties(${PROJECT_NAME}-utils PROPERTIES DEBUG_POSTFIX "d")
target_link_libraries(${PROJECT_NAME}-utils -lm)



include(GNUInstallDirs)
target_include_directories(${PROJECT_NAME} PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/apriltag")


# install header file hierarchy
file(GLOB HEADER_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.h common/*.h)
list(REMOVE_ITEM HEADER_FILES apriltag_detect.docstring.h apriltag_py_type.docstring.h)

foreach(HEADER ${HEADER_FILES})
    string(REGEX MATCH "(.*)[/\\]" DIR ${HEADER})
    install(FILES ${HEADER} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/${DIR})
endforeach()

# export library
set(generated_dir "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(version_config "${generated_dir}/${PROJECT_NAME}ConfigVersion.cmake")
set(project_config "${generated_dir}/${PROJECT_NAME}Config.cmake")
set(targets_export_name "${PROJECT_NAME}Targets")
set(config_install_dir "share/${PROJECT_NAME}/cmake")

# Include module with fuction 'write_basic_package_version_file'
include(CMakePackageConfigHelpers)

# Configure '<PROJECT-NAME>Config.cmake'
# Use variables:
#   * targets_export_name
#   * PROJECT_NAME
configure_package_config_file(
        "CMake/apriltagConfig.cmake.in"
        "${project_config}"
        INSTALL_DESTINATION "${config_install_dir}"
)

# Configure '<PROJECT-NAME>ConfigVersion.cmake'
# Note: PROJECT_VERSION is used as a VERSION
write_basic_package_version_file("${version_config}" COMPATIBILITY SameMajorVersion)


# install library
install(TARGETS ${PROJECT_NAME} ${PROJECT_NAME}-utils EXPORT ${targets_export_name}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )

install(EXPORT ${targets_export_name}
    NAMESPACE apriltag::
    DESTINATION ${config_install_dir})

install(FILES ${project_config} ${version_config} DESTINATION ${config_install_dir})

export(TARGETS apriltag
    NAMESPACE apriltag::
    FILE ${generated_dir}/${targets_export_name}.cmake)


# install pkgconfig related files
FILE(READ apriltag.pc.in PKGC)
STRING(REGEX REPLACE "^prefix=" "prefix=${CMAKE_INSTALL_PREFIX}" PKGC_CONF "${PKGC}" )
FILE(WRITE ${PROJECT_BINARY_DIR}/apriltag.pc ${PKGC_CONF})
install(FILES "${PROJECT_BINARY_DIR}/apriltag.pc" DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig/")


# Python wrapper
include(CMakeDependentOption)
cmake_dependent_option(BUILD_PYTHON_WRAPPER "Builds Python wrapper" ON BUILD_SHARED_LIBS OFF)

if(BUILD_PYTHON_WRAPPER)
    SET(Python_ADDITIONAL_VERSIONS 3)
    find_package(PythonLibs)
    execute_process(COMMAND which python3 OUTPUT_QUIET RESULT_VARIABLE Python3_NOT_FOUND)
    execute_process(COMMAND python3 -c "import numpy" RESULT_VARIABLE Numpy_NOT_FOUND)
endif(BUILD_PYTHON_WRAPPER)

if (NOT Python3_NOT_FOUND AND NOT Numpy_NOT_FOUND AND PYTHONLIBS_FOUND AND BUILD_PYTHON_WRAPPER)
    # TODO deal with both python2/3
    execute_process(COMMAND python3 ${CMAKE_CURRENT_SOURCE_DIR}/python_build_flags.py OUTPUT_VARIABLE PY_OUT)
    set(PY_VARS CFLAGS LDFLAGS LINKER EXT_SUFFIX)
    cmake_parse_arguments(PY "" "${PY_VARS}" "" ${PY_OUT})
    separate_arguments(PY_CFLAGS)
    list(REMOVE_ITEM PY_CFLAGS -flto)
    separate_arguments(PY_LDFLAGS)

    foreach(X detect py_type)
    add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/apriltag_${X}.docstring.h
        COMMAND < ${CMAKE_CURRENT_SOURCE_DIR}/apriltag_${X}.docstring sed 's/\"/\\\\\"/g\; s/^/\"/\; s/$$/\\\\n\"/\;' > apriltag_${X}.docstring.h
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
    endforeach()

    add_custom_command(OUTPUT apriltag_pywrap.o
        COMMAND ${CMAKE_C_COMPILER} ${PY_CFLAGS} -I${PROJECT_BINARY_DIR} -c -o apriltag_pywrap.o ${CMAKE_CURRENT_SOURCE_DIR}/apriltag_pywrap.c
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/apriltag_pywrap.c ${PROJECT_BINARY_DIR}/apriltag_detect.docstring.h ${PROJECT_BINARY_DIR}/apriltag_py_type.docstring.h)
    add_custom_command(OUTPUT apriltag${PY_EXT_SUFFIX}
        COMMAND ${PY_LINKER} ${PY_LDFLAGS} -Wl,-rpath,lib apriltag_pywrap.o $<TARGET_FILE:apriltag> -o apriltag${PY_EXT_SUFFIX}
        DEPENDS ${PROJECT_NAME} apriltag_pywrap.o)
    add_custom_target(apriltag_python ALL
        DEPENDS apriltag${PY_EXT_SUFFIX})

install(FILES ${PROJECT_BINARY_DIR}/apriltag${PY_EXT_SUFFIX} DESTINATION /usr/lib/python3/dist-packages/)
endif (NOT Python3_NOT_FOUND AND NOT Numpy_NOT_FOUND AND PYTHONLIBS_FOUND AND BUILD_PYTHON_WRAPPER)

# Examples
# apriltag_demo
add_executable(apriltag_demo example/apriltag_demo.c)
target_link_libraries(apriltag_demo apriltag apriltag-utils)

add_executable(simple_demo example/simple_demo.c)
target_link_libraries(simple_demo apriltag -lfreeimage)

# opencv_demo
# NB: contrib required for TickMeter in OpenCV 2.4. This is only required for 16.04 backwards compatibility and can be removed in the future.
find_package(OpenCV COMPONENTS core imgproc videoio highgui contrib QUIET)
if(OpenCV_FOUND)
    add_executable(opencv_demo example/opencv_demo.cc)
    target_link_libraries(opencv_demo apriltag apriltag-utils ${OpenCV_LIBRARIES})
    set_target_properties(opencv_demo PROPERTIES CXX_STANDARD 11)
    install(TARGETS opencv_demo RUNTIME DESTINATION bin)
else()
    message(WARNING "OpenCV not found: Not building demo")
endif(OpenCV_FOUND)

# install example programs
install(TARGETS apriltag_demo RUNTIME DESTINATION bin)
install(TARGETS simple_demo   RUNTIME DESTINATION bin)
