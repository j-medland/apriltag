// Define Exported on MSVC/CYGWIN/GNU
#if defined _WIN32 || defined __CYGWIN__
  #ifdef APRILTAG_DLL_EXPORTS
    #ifdef __GNUC__
      #define APRILTAG_EXPORT __attribute__ ((dllexport))
    #else
      #define APRILTAG_EXPORT __declspec(dllexport) // Note: actually gcc seems to also supports this syntax.
    #endif
  #else
    #ifdef __GNUC__
      #define APRILTAG_EXPORT __attribute__ ((dllimport))
    #else
      #define APRILTAG_EXPORT __declspec(dllimport) // Note: actually gcc seems to also supports this syntax.
    #endif
  #endif
#else
  #if __GNUC__ >= 4
    #define APRILTAG_EXPORT __attribute__ ((visibility ("default")))
  #else
    #define APRILTAG_EXPORT
  #endif
#endif