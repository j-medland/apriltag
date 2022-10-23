# apriltag_demo
add_executable(apriltag_demo apriltag_demo.c)
target_link_libraries(apriltag_demo PRIVATE apriltag::detector apriltag::utils apriltag::tags)

# opencv_demo
set(_OpenCV_REQUIRED_COMPONENTS core imgproc videoio highgui)
find_package(OpenCV COMPONENTS ${_OpenCV_REQUIRED_COMPONENTS} QUIET CONFIG)
if(OpenCV_FOUND)
    # NB: contrib required for TickMeter in OpenCV 2.4. This is only required for 16.04 backwards compatibility and can be removed in the future.
    #     If we add it to the find_package initially, the demo won't build for newer OpenCV versions
    if(OpenCV_VERSION VERSION_LESS "3.0.0")
        list(APPEND _OpenCV_REQUIRED_COMPONENTS contrib)
        find_package(OpenCV COMPONENTS ${_OpenCV_REQUIRED_COMPONENTS} CONFIG)
        set(OPENCV_CONTRIB_TGT opencv_contrib)
    endif()
    
    add_executable(opencv_demo opencv_demo.cc)
    target_link_libraries(opencv_demo 
        PRIVATE
            apriltag::detector
            apriltag::utils
            apriltag::tags
            opencv_core
            opencv_imgproc
            opencv_videoio
            opencv_highgui
            "$<$<IN_LIST:contrib,${_OpenCV_REQUIRED_COMPONENTS}>:opencv_contrib>"
        )
    set_target_properties(opencv_demo PROPERTIES CXX_STANDARD 11)
    install(TARGETS opencv_demo RUNTIME DESTINATION bin)
else()
    message(STATUS "OpenCV not found: Not building demo")
endif(OpenCV_FOUND)

# install example programs
install(TARGETS apriltag_demo RUNTIME DESTINATION bin)