#-------------------------------------------------------------------------------
#						Search all libraries on the system
#-------------------------------------------------------------------------------
## Use cmake package to find module
find_package(ALSA)
find_package(BZip2)
find_package(Gettext) # translation tool
find_package(Git)
find_package(JPEG)
find_package(OpenGL)
# The requirement of wxWidgets is checked in SelectPcsx2Plugins module
# Does not require the module (allow to compile non-wx plugins)
# Force the unicode build (the variable is only supported on cmake 2.8.3 and above)
# Warning do not put any double-quote for the argument...
# set(wxWidgets_CONFIG_OPTIONS --unicode=yes --debug=yes) # In case someone want to debug inside wx
#
# Fedora uses an extra non-standard option ... Arch must be the first option.
# They do uname -m if missing so only fix for cross compilations.
# http://pkgs.fedoraproject.org/cgit/wxGTK.git/plain/wx-config
if(Fedora AND CMAKE_CROSSCOMPILING)
    set(wxWidgets_CONFIG_OPTIONS --arch ${PCSX2_TARGET_ARCHITECTURES} --unicode=yes)
else()
    set(wxWidgets_CONFIG_OPTIONS --unicode=yes)
endif()
find_package(wxWidgets COMPONENTS base core adv)
find_package(ZLIB)

## Use pcsx2 package to find module
include(FindCg)
include(FindGlew)
include(FindLibc)

## Use CheckLib package to find module
include(CheckLib)
if(Linux)
    check_lib(AIO aio libaio.h)
endif()
check_lib(EGL EGL EGL/egl.h)
check_lib(GLESV2 GLESv2 GLES3/gl3ext.h) # NOTE: looking for GLESv3, not GLESv2
check_lib(PORTAUDIO portaudio portaudio.h pa_linux_alsa.h)
check_lib(SOUNDTOUCH SoundTouch soundtouch/SoundTouch.h)

if(SDL2_API)
    check_lib(SDL2 SDL2 SDL.h PATH_SUFFIXES SDL2)
else()
    # Tell cmake that we use SDL as a library and not as an application
    set(SDL_BUILDING_LIBRARY TRUE)
    find_package(SDL)
endif()

if(UNIX)
    find_package(X11)
    # Most plugins (if not all) and PCSX2 core need gtk2, so set the required flags
    if (GTK3_API)
        if(CMAKE_CROSSCOMPILING)
            find_package(GTK3 REQUIRED gtk)
        else()
            check_lib(GTK3 gtk+-3.0 gtk/gtk.h)
        endif()
    else()
        find_package(GTK2 REQUIRED gtk)
    endif()
endif()

#----------------------------------------
#		    Use system include
#----------------------------------------
if(UNIX)
	if(GTK2_FOUND)
		include_directories(${GTK2_INCLUDE_DIRS})
    elseif(GTK3_FOUND)
		include_directories(${GTK3_INCLUDE_DIRS})
        # A lazy solution
        set(GTK2_LIBRARIES ${GTK3_LIBRARIES})
	endif()

	if(X11_FOUND)
		include_directories(${X11_INCLUDE_DIR})
	endif()
endif()

if(ALSA_FOUND)
	include_directories(${ALSA_INCLUDE_DIRS})
endif()

if(BZIP2_FOUND)
	include_directories(${BZIP2_INCLUDE_DIR})
endif()

if(CG_FOUND)
	include_directories(${CG_INCLUDE_DIRS})
endif()

if(JPEG_FOUND)
	include_directories(${JPEG_INCLUDE_DIR})
endif()

if(GLEW_FOUND)
    include_directories(${GLEW_INCLUDE_DIR})
endif()

if(OPENGL_FOUND)
	include_directories(${OPENGL_INCLUDE_DIR})
endif()

if(SDL_FOUND AND NOT SDL2_API)
	include_directories(${SDL_INCLUDE_DIR})
endif()

if(wxWidgets_FOUND)
    if(Linux)
		# Some people are trying to compile with wx 3.0 ...
		### 3.0
		# -I/usr/lib/i386-linux-gnu/wx/include/gtk2-unicode-3.0 -I/usr/include/wx-3.0 -D_FILE_OFFSET_BITS=64 -DWXUSINGDLL -D__WXGTK__ -pthread
		# -L/usr/lib/i386-linux-gnu -pthread   -lwx_gtk2u_xrc-3.0 -lwx_gtk2u_html-3.0 -lwx_gtk2u_qa-3.0 -lwx_gtk2u_adv-3.0 -lwx_gtk2u_core-3.0 -lwx_baseu_xml-3.0 -lwx_baseu_net-3.0 -lwx_baseu-3.0
		### 2.8
		# -I/usr/lib/i386-linux-gnu/wx/include/gtk2-unicode-release-2.8 -I/usr/include/wx-2.8 -D_FILE_OFFSET_BITS=64 -D_LARGE_FILES -D__WXGTK__ -pthread
		# -L/usr/lib/i386-linux-gnu -pthread -Wl,-z,relro  -L/usr/lib/i386-linux-gnu   -lwx_gtk2u_richtext-2.8 -lwx_gtk2u_aui-2.8 -lwx_gtk2u_xrc-2.8 -lwx_gtk2u_qa-2.8 -lwx_gtk2u_html-2.8 -lwx_gtk2u_adv-2.8 -lwx_gtk2u_core-2.8 -lwx_baseu_xml-2.8 -lwx_baseu_net-2.8 -lwx_baseu-2.8
        if ("${wxWidgets_INCLUDE_DIRS}" MATCHES "3.0" AND WX28_API)
			message(WARNING "\nWxwidget 3.0 is installed on your system whereas PCSX2 required 2.8 !!!\nPCSX2 will try to use 2.8 but if it would be better to fix your setup.\n")
			STRING(REGEX REPLACE "unicode" "unicode-release" wxWidgets_INCLUDE_DIRS "${wxWidgets_INCLUDE_DIRS}")
			STRING(REGEX REPLACE "3\\.0" "2.8" wxWidgets_INCLUDE_DIRS "${wxWidgets_INCLUDE_DIRS}")
			STRING(REGEX REPLACE "3\\.0" "2.8" wxWidgets_LIBRARIES "${wxWidgets_LIBRARIES}")
		endif()
    endif()

	include(${wxWidgets_USE_FILE})
endif()

if(ZLIB_FOUND)
	include_directories(${ZLIB_INCLUDE_DIRS})
endif()

#----------------------------------------
#  Use  project-wide include directories
#----------------------------------------
include_directories(${CMAKE_SOURCE_DIR}/common/include
					${CMAKE_SOURCE_DIR}/common/include/Utilities
					${CMAKE_SOURCE_DIR}/common/include/x86emitter
                    # File generated by Cmake
                    ${CMAKE_BINARY_DIR}/common/include
                    )
