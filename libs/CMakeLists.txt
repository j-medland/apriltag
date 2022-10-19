cmake_minimum_required(VERSION 3.4)
project(apriltag VERSION 3.3.69 LANGUAGES C CXX)

if (MSVC)
    add_compile_definitions("_CRT_SECURE_NO_WARNINGS")
endif()

if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif()

include(GNUInstallDirs)
include(GenerateExportHeader)
include(${CMAKE_SOURCE_DIR}/CMake/apriltagHelperFunctions.cmake)

# Common Souce
add_library(common OBJECT)

set_target_properties(common PROPERTIES POSITION_INDEPENDENT_CODE ON)

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

list(TRANSFORM HEADERS_COMMON PREPEND ${CMAKE_SOURCE_DIR}/include/common/)

target_sources(common PRIVATE
    src/common/image_u8.c
    src/common/image_u8x3.c
    src/common/pnm.c
    src/common/time_util.c
    ${HEADERS_COMMON}
)

target_include_directories(common
    PUBLIC
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
    PRIVATE
    include/common
)

# Detector Library
add_library(detector-object OBJECT)

set_target_properties(detector-object PROPERTIES POSITION_INDEPENDENT_CODE ON)

generate_export_header(detector-object BASE_NAME apriltag)

set(HEADERS_DETECTOR
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

list(TRANSFORM HEADERS_DETECTOR PREPEND ${CMAKE_SOURCE_DIR}/include/)

target_sources(detector-object PRIVATE
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
    $<TARGET_OBJECTS:common>
    ${HEADERS_DETECTOR}
)

if (MSVC)
    # MSVC target options
else()
    find_package(Threads REQUIRED)
    target_link_libraries(detector-object PUBLIC Threads::Threads m)
endif()

target_link_libraries(detector-object PRIVATE $<TARGET_OBJECTS:common>)

target_include_directories(detector-object 
   PUBLIC
   $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
   $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
   # include cmake-generated apriltag_export.h
   $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
)

add_library(${PROJECT_NAME}-detector $<TARGET_OBJECTS:detector-object>)

set_apriltag_lib_property_defaults(${PROJECT_NAME}-detector)

set_apriltag_named_exports_only(${PROJECT_NAME}-detector)

set_property(TARGET ${PROJECT_NAME}-detector PROPERTY EXPORT_NAME detector)

# Tag Family Libraries
set(TAG_FAMILIES
    tag16h5
    tag25h9
    tag36h10
    tag36h11
    tagCircle21h7
    tagCircle49h12
    tagCustom48h12
    tagStandard41h12
    tagStandard52h13
)

set(TARGETS_TAGS "")
set(OBJECT_LIBS_TAGS "")
set(HEADERS_TAGS "")

foreach(TAG_FAMILY ${TAG_FAMILIES})
    # for each tag family
    set(TAG_TARGET_OBJECT ${TAG_FAMILY}-object)
    LIST(APPEND OBJECT_LIBS_TAGS $<TARGET_OBJECTS:${TAG_TARGET_OBJECT}>)

    # create Tag-Family object target
    add_library(${TAG_TARGET_OBJECT} OBJECT)

    set_target_properties(${TAG_TARGET_OBJECT} PROPERTIES POSITION_INDEPENDENT_CODE ON)

    set(TAG_FAMILY_HEADER include/${TAG_FAMILY}.h)

    target_sources(${TAG_TARGET_OBJECT} PRIVATE src/${TAG_FAMILY}.c ${TAG_FAMILY_HEADER})

    # Add include directories manually as OBJECT libs don't pass their target_include_dirs
    # to their users so linking to detector-object wouldn't help
    target_include_directories(${TAG_TARGET_OBJECT} 
        PUBLIC
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        # include cmake-generated apriltag_export.h
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
    )

    # Create standalone library for object
    set(TAG_TARGET ${PROJECT_NAME}-${TAG_FAMILY})
    LIST(APPEND TARGETS_TAGS ${TAG_TARGET})

    add_library(${TAG_TARGET} $<TARGET_OBJECTS:${TAG_TARGET_OBJECT}>)

    set_property(TARGET ${TAG_TARGET} PROPERTY EXPORT_NAME ${TAG_FAMILY})
    set_apriltag_lib_property_defaults(${TAG_TARGET})
    set_apriltag_named_exports_only(${TAG_TARGET})

    LIST(APPEND HEADERS_TAGS ${TAG_FAMILY_HEADER})
endforeach()

# all tags library
add_library(${PROJECT_NAME}-tags ${OBJECT_LIBS_TAGS})
target_sources(${PROJECT_NAME}-tags PUBLIC ${OBJECT_LIBS_TAGS})
target_link_directories(${PROJECT_NAME}-tags PUBLIC ${OBJECT_LIBS_TAGS})
set_property(TARGET ${PROJECT_NAME}-tags PROPERTY EXPORT_NAME tags)
set_apriltag_lib_property_defaults(${PROJECT_NAME}-tags)
set_apriltag_named_exports_only(${PROJECT_NAME}-tags)

# Utils Library
add_library(utils-object OBJECT)

set_target_properties(utils-object PROPERTIES POSITION_INDEPENDENT_CODE ON)

    set(HEADERS_UTIL
        getopt.h
        image_u8x4.h
        pam.h
        pjpeg.h
        string_util.h
        zhash.h
    )

    list(TRANSFORM HEADERS_UTIL PREPEND ${CMAKE_SOURCE_DIR}/include/common/)
    
    target_sources(utils-object PRIVATE
        src/common/string_util.c
        src/common/pjpeg-idct.c
        src/common/pjpeg.c
        src/common/image_u8x4.c
        src/common/getopt.c
        src/common/pam.c
        src/common/zhash.c
        src/common/zarray.c
        $<TARGET_OBJECTS:common>
        ${HEADERS_UTIL}
    )

    if (MSVC)
        add_compile_definitions("_CRT_SECURE_NO_WARNINGS")
    else()
        target_link_libraries(utils-object PUBLIC m)
    endif()

    target_include_directories(utils-object 
        PUBLIC
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>/${PROJECT_NAME}
        PRIVATE
        include/common
    )

    add_library(${PROJECT_NAME}-utils $<TARGET_OBJECTS:utils-object>)

    set_property(TARGET ${PROJECT_NAME}-utils PROPERTY EXPORT_NAME utils)
    set_apriltag_lib_property_defaults(${PROJECT_NAME}-utils)
    set_apriltag_export_all(${PROJECT_NAME}-utils)


# install library header file hierarchy
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})

#install apriltag_exports.h
install(FILES $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/apriltag_export.h> DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/)

# Combined Apriltag Library to support legacy builds
add_library(${PROJECT_NAME})
target_sources(${PROJECT_NAME}
    PUBLIC
    $<TARGET_OBJECTS:detector-object> 
    ${OBJECT_LIBS_TAGS}
    $<TARGET_OBJECTS:utils-object>
    $<TARGET_OBJECTS:common> 
)

set_apriltag_lib_property_defaults(${PROJECT_NAME})
set_apriltag_export_all(${PROJECT_NAME})

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


set(APRILTAG_INSTALL_TARGETS
    apriltag
    apriltag-detector
    apriltag-tags
    ${TARGETS_TAGS}
    apriltag-utils
)

# install library
install(TARGETS ${APRILTAG_INSTALL_TARGETS} EXPORT ${targets_export_name}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(EXPORT ${targets_export_name}
    NAMESPACE apriltag::
    DESTINATION ${config_install_dir})

install(FILES ${project_config} ${version_config} DESTINATION ${config_install_dir})

export(TARGETS ${APRILTAG_INSTALL_TARGETS}
    NAMESPACE apriltag::
    FILE ${generated_dir}/${targets_export_name}.cmake
)

# install pkgconfig file
configure_file(${PROJECT_NAME}.pc.in ${PROJECT_NAME}.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)