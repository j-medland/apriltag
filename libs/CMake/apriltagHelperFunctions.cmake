# Helper Functions
function(set_apriltag_lib_property_defaults target_name)
    set_target_properties(${target_name} PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
    set_target_properties(${target_name} PROPERTIES DEBUG_POSTFIX "d")
    set_target_properties(${target_name} PROPERTIES POSITION_INDEPENDENT_CODE ON)
endfunction()

function(set_apriltag_named_exports_only target_name)
    set_target_properties(${target_name} PROPERTIES 
        CMAKE_C_VISIBILITY_PRESET hidden 
        CMAKE_CXX_VISIBILITY_PRESET hidden
        CMAKE_VISIBILITY_INLINES_HIDDEN ON
        CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS OFF
    )
endfunction()

function(set_apriltag_export_all target_name)
    set_target_properties(${target_name} PROPERTIES 
    CMAKE_C_VISIBILITY_PRESET default 
    CMAKE_CXX_VISIBILITY_PRESET default
    CMAKE_VISIBILITY_INLINES_HIDDEN OFF
    CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON
)
endfunction()