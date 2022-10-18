cmake_minimum_required(VERSION 3.4)
project(apriltag VERSION 3.3.0 LANGUAGES C CXX)

if (MSVC)
    add_compile_definitions("_CRT_SECURE_NO_WARNINGS")
endif()

if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif()
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

include(GNUInstallDirs)
include(GenerateExportHeader)

set(INCLUDE_DIR_RELATIVE include/apriltag)
set(INCLUDE_DIR_FULL ${CMAKE_SOURCE_DIR}/${INCLUDE_DIR_RELATIVE})

# Common Souce
# Build an OBJECT-library for the items shared between the core and util libs
add_library(${PROJECT_NAME}-common OBJECT)

set(HEADERS_COMMON
    debug_print.h
    image_types.h
    image_u8.h
    image_u8x3.h
    math_util.h
    pnm.h
    time_util.h
    zarray.h
)

list(TRANSFORM HEADERS_COMMON PREPEND ${INCLUDE_DIR_RELATIVE}/common/)

target_sources(${PROJECT_NAME}-common PRIVATE
    src/common/image_u8.c
    src/common/image_u8x3.c
    src/common/pnm.c
    src/common/time_util.c
    ${HEADERS_COMMON}
)

target_include_directories(${PROJECT_NAME}-common
    PUBLIC
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
    PRIVATE
    ${INCLUDE_DIR_FULL}/common
)

# Library (core functionality)
add_library(${PROJECT_NAME})

generate_export_header(${PROJECT_NAME})

set(HEADERS_CORE_LIB
    apriltag.h
    apriltag_pose.h
    common/g2d.h
    common/homography.h
    common/matd.h
    common/postscript_utils.h
    common/pthreads_cross.h
    common/svd22.h
    common/timeprofile.h
    common/unionfind.h
    common/workerpool.h
    common/zmaxheap.h
)

list(TRANSFORM HEADERS_CORE_LIB PREPEND ${INCLUDE_DIR_RELATIVE}/)

target_sources(${PROJECT_NAME} PRIVATE
    src/apriltag.c 
    src/apriltag_pose.c 
    src/apriltag_quad_thresh.c
    src/common/g2d.c
    src/common/homography.c
    src/common/matd.c
    src/common/svd22.c
    src/common/unionfind.c
    src/common/workerpool.c
    src/common/zmaxheap.c
    $<TARGET_OBJECTS:${PROJECT_NAME}-common>
    ${HEADERS_CORE_LIB}
)

# add yet-to-be generated export header to list so it will be installed with other headers
list(APPEND HEADERS_CORE_LIB $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/${PROJECT_NAME}_export.h>)

if (MSVC)
    # MSVC target options
else()
    find_package(Threads REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC Threads::Threads m)
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}-common)

set_target_properties(${PROJECT_NAME} PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")
set_target_properties(${PROJECT_NAME} PROPERTIES 
    CMAKE_C_VISIBILITY_PRESET hidden 
    CMAKE_CXX_VISIBILITY_PRESET hidden
    CMAKE_VISIBILITY_INLINES_HIDDEN ON
    CMAKE_POSITION_INDEPENDENT_CODE ON
    CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS OFF
)

target_include_directories(${PROJECT_NAME} 
   PUBLIC
   $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
   $<BUILD_INTERFACE:${INCLUDE_DIR_FULL}>
   # include cmake-generated apriltag_export.h
   $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
)

# Tag Library (Standard Tag Families)
add_library(${PROJECT_NAME}-tags)

set(HEADERS_TAGS 
    tag16h5.h
    tag25h9.h
    tag36h10.h
    tag36h11.h
    tagCircle21h7.h
    tagCircle49h12.h
    tagCustom48h12.h
    tagStandard41h12.h
    tagStandard52h13.h
)

list(TRANSFORM HEADERS_TAGS PREPEND ${INCLUDE_DIR_RELATIVE}/)

target_sources(${PROJECT_NAME}-tags PRIVATE
    src/tag16h5.c
    src/tag25h9.c
    src/tag36h10.c
    src/tag36h11.c
    src/tagCircle21h7.c
    src/tagCircle49h12.c
    src/tagCustom48h12.c
    src/tagStandard41h12.c
    src/tagStandard52h13.c
    ${HEADERS_TAGS}
)

set_target_properties(${PROJECT_NAME}-tags PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
set_target_properties(${PROJECT_NAME}-tags PROPERTIES DEBUG_POSTFIX "d")
set_target_properties(${PROJECT_NAME}-tags PROPERTIES 
    CMAKE_C_VISIBILITY_PRESET hidden 
    CMAKE_CXX_VISIBILITY_PRESET hidden
    CMAKE_VISIBILITY_INLINES_HIDDEN ON
    CMAKE_POSITION_INDEPENDENT_CODE ON
    CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS OFF
)

target_include_directories(${PROJECT_NAME}-tags
   PUBLIC
   $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
   $<BUILD_INTERFACE:${INCLUDE_DIR_FULL}>
   # include cmake-generated apriltag_export.h
   $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
)

file(GENERATE OUTPUT boo.txt CONTENT  $<BUILD_INTERFACE:${INCLUDE_DIR_FULL}>)

# install library header file hierarchy
foreach(HEADER ${HEADERS_CORE_LIB} ${HEADERS_COMMON} ${HEADERS_TAGS})
    string(REGEX MATCH "(.*)[/\\]" DIR ${HEADER})
    install(FILES ${HEADER} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/${DIR})
endforeach()

# export library
set(generated_dir ${CMAKE_CURRENT_BINARY_DIR}/generated)
set(version_config ${generated_dir}/${PROJECT_NAME}ConfigVersion.cmake)
set(project_config ${generated_dir}/${PROJECT_NAME}Config.cmake)
set(targets_export_name ${PROJECT_NAME}Targets)
set(config_install_dir share/${PROJECT_NAME}/cmake)

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
install(TARGETS ${PROJECT_NAME} ${PROJECT_NAME}-tags EXPORT ${targets_export_name}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(EXPORT ${targets_export_name}
    NAMESPACE apriltag::
    DESTINATION ${config_install_dir})

install(FILES ${project_config} ${version_config} DESTINATION ${config_install_dir})

export(TARGETS apriltag apriltag-tags
    NAMESPACE apriltag::
    FILE ${generated_dir}/${targets_export_name}.cmake
)

# install pkgconfig file
configure_file(${PROJECT_NAME}.pc.in ${PROJECT_NAME}.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)