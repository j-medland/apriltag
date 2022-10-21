# Helper Functions
function(set_apriltag_lib_property_defaults target_name)
    set_target_properties(${target_name} PROPERTIES SOVERSION 3 VERSION ${PROJECT_VERSION})
    set_target_properties(${target_name} PROPERTIES DEBUG_POSTFIX "d")
    set_target_properties(${target_name} PROPERTIES POSITION_INDEPENDENT_CODE ON)
endfunction()

function(set_apriltag_named_exports_only target_name)
    set_target_properties(${target_name} PROPERTIES 
        C_VISIBILITY_PRESET hidden 
        CXX_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN ON
        WINDOWS_EXPORT_ALL_SYMBOLS OFF
    )
endfunction()

function(set_apriltag_export_all target_name)
    set_target_properties(${target_name} PROPERTIES 
        C_VISIBILITY_PRESET default 
        CXX_VISIBILITY_PRESET default
        VISIBILITY_INLINES_HIDDEN OFF
        WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endfunction()