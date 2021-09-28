# Possible projects

* proper logging - DONE
* embed font - DONE
* have prebuilt openssl (ssl crypto curl prebuilt) - DONE
* have prebuilt sdl2
* remove the custom keyboard button
* zoom pinch bound command: mouse wheel? + and -? - DONE
* double tap to back button to (truly) exit
* having a functional linux development process (docker compatible)
* having a functional windows development process
* unifying pakset download across OS: Linux, windows, macOS as main targets

# Notes on prebuilt libs

* Fluidsynth 2.2.2
	flac fluidsynth glib-2.0 gobject-2.0 gthread-2.0 instpatch-1.0 oboe ogg opus sndfile vorbis vorbisenc
* libzip 1.2.0
* openssl 1.1.1j (crypto + ssl)

# Notes on Dockerfile instructions

* gradlew downloads latest versions of android sdk, seems to install them, but they are not reported on the SDK manager. It could be that we don't need to have an install of android sdk beforehand?
* gradle can be kind of initialized by calling it from ./project folder
* the command line option sdkmanager --licenses is deprecated in later versions of sdkmanager, hence the way to accept licenses must be through copying licenses files as mentioned https://developer.android.com/studio/intro/update#download-with-gradle
* starting April 2020, sdk tools package is deprecated, and replaced by commandlinetools package; see # https://developer.android.com/studio/command-line/#tools-sdk and https://developer.android.com/studio#command-tools; version numbering is different; the past packages are captured from https://mirrors.cloud.tencent.com/AndroidSDK/
* the compiler armv7a-linux-androideabi16-clang++, used by simutrans, is only found on ndk (side-by-side) 19.2.5345600; it could be there is such expectation
* as of 15/08/21, the commit https://github.com/aburch/simutrans/commit/446284d85e8df07fffc73bfb200a23086d562388#diff-df72854a6bd7c93a0632db453e323a8cab4212fe5664607191b16252c62f905a introduces problems in compilation due to fluidsynth. This is SVN revision 9775.
* as of 15/08/21, --no-rosegment is requested during linking. However, NDK r19 does not provide this argument (see https://github.com/android/ndk/issues/1426 + ld --version).
* build scripts requires objdump; llvm-objdump is found for ndk21+; a platform specific one can be found on ndk20 and below.
* there is a discrepancy between svn revision rX and the @ from git svn trunk; so the versions a built are slightly different.
* symlink to simutrans folder do not play well with the build scripts as they tend to cd into the simutrans folder then refer to objects far in parents. Mounting directly a source folder to a subdirectory looks like it is the only safe solution to link source.
* certificates seem to change over each build iteration, making 'overwrite install' impossible and requiring to uninstall then reinstall.
* There is sometimes complain about resource not aligned ```Failed parse during installPackageLI: Targeting R+ (version 30 and above) requires the resources.arsc of installed APKs to be stored uncompressed and aligned on a 4-byte boundary```. Performing ```cd project; ./gradlew clean``` seems to do the trick.
* dual compatibility git/svn is a bit of a headache. version refers officially to svn number, but when adding a commit by ourselves via git, there is no svn number. So I choose to fallback to the last known head revision.

# Version exploration
```
  Version     SVN   GIT     GIT SHA-1     Link for downloading
              9774  @10002                                                                            video glitch    
  122.0       9274  @9510   dcb52e12      https://forum.simutrans.com/index.php/topic,20389.0.html    video glitch    
  121.0       8588  @8819   593b1119      https://forum.simutrans.com/index.php/topic,19573.0.html    not working when starting new game
  120.3       8504  @8734   ea8b52fb      https://forum.simutrans.com/index.php/topic,18295.0.html    can start a new game
              8400  @8630   471f3b09                                                                  first release to compile with clang
  120.2.2     8163  @8389   9e7c8f81      https://forum.simutrans.com/index.php/topic,16909.0.html    does not compile
  112.3       6520  @6742   aba4ebb2      https://forum.simutrans.com/index.php/topic,11920.0.html    does not compile
  111.3.1     5843                        https://forum.simutrans.com/index.php/topic,10292.0.html
```

# Manual fix on top of pelya code

On file ```project/jni/application/simutrans/AndroidAppSettings.cfg```, change ```SdlVideoResize=n``` to ```SdlVideoResize=y```.


# For SDL 2, although it should not be required for Linux/Android which continue to support SDL1.2

* vim project/jni/application/simutrans/AndroidAppSettings.cfg , change version number
* vim project/jni/application/simutrans/AndroidBuild.sh , change backend to sdl2
* svn log ./project/jni/application/simutrans/simutrans/ | less
* SDL2 compile requires to change the simutrans config BACKEND, as well as several locations where the include is SDL2/SDL.h; pelya provide it without SDL2 folder; there is also a flag that is supposedly existing only on SDL 2.0.1, and features supposedly only existing on SDL 2.0.4, which are not found
    ```
    ./project/jni/application/simutrans/simutrans/sys/clipboard_s2.cc
    ./project/jni/application/simutrans/simutrans/sys/simsys_s2.cc
    ./project/jni/application/simutrans/simutrans/sound/sdl2_sound.cc
    ```
* SDL2 does not include some resources in vim project/javaSDL2/translations/values/strings.xml

SDL2 source is a bit outdated and can be updated.
It contains a SDLActivity.java, which supposedly must extend MainActivity.java.
It links to libhidapi.so, which can be also modified to be linked statically to avoid the problems on having a separate directory.
It links to both libGLESv1_CM.so and libGLESv2.so, which are definitively available on the NDK build, but not necessarily on the phone.


# Proper cleaning

* ```android-sdl/project/obj/local``` contains build objects; it must be cleaned for libraries to rebuild/redownload.

# Fluidsynth investigation

* Version embedded by pelya, identified to be 1.1.3, from https://github.com/FluidSynth/fluidsynth, with some custom changes, likely due to Clang compiler not being compatible out of the box. But not managed to replace the version because there are too many source code changes.
* Fluidsynth has provided android pre-built libraries. Adding pre-built libraries is possible via gradle by making an Android.mk file that adds prebuilt libs; this require extensive modification of pelya repository. 
* Fluidsynth android pre-built does not expose logging functions, so we cannot use fluid_set_log_function(). The workaround is fluidsynth by default output to stderr, so it is possible to duplicate the output of stderr to logcat https://codelab.wordpress.com/2014/11/03/how-to-use-standard-output-streams-for-logging-in-android-apps/; the snippet in this link requires ```#include <unistd.h>```, but it is not functional.
* Fluidsynth android pre-built is linked against libc++_shared from ndk r21, which exposes the symbol lttf2. This symbol is not exposed on ndk r23, so a manual copy of the .so from fluidsynth pre-built has been copied into the SDK at that location /opt/android-sdk-linux/ndk/23.0.7599858/sources/cxx-stl/llvm-libc++/libs/

Successful music! The action items are:
* make a clone of pelya repository
* add the prebuilt libraries + Android.mk build scripts; should we auto download them? from which package? https://github.com/FluidSynth/fluidsynth/releases/download/v2.2.2/fluidsynth-2.2.2-android.zip contains libraries that have some of their dependencies statically linked, so it reduces cross dependence; it is a better target than the fluidsynth pipeline on circleci.
* refer to the clone of pelya repository on android build pipeline instead of the original
* make a hard copy of c++shared upon build

The location of the sf2 file is ideally found in music, as expected from simutrans. A way to do it is to download it to include in the data.zip as part of the source code, a bit the same way it is done for pak.

# pak download investigation

* simutrans has an embedded pak download functionality, but it is using systemwide shell commands and will rely on external applications to do it (wget, curl).
* the most perenne way to do it is to embed the downloading functionality within the game.
* This poses the issue of libcurl availability
* pelya source does propose a curl library to build ourselves; I have not found prebuilt libraries like fluidsynth.
* A nice project could be to provide a fork of libcurl, with prebuilt libraries ready to use, built by github actions, the same way fluidsynth does
* The number of paksets is 17; the prompt window is auto resizing, cutting the list in two.

* list selection works following the rules:
  * select only focused item if multiselection disabled OR no key modifier pressed
  * toggle additional item if multiselection is enabled AND CTRL pressed
* A modern touch based interface would consider it as a togglable list (aka checkboxes, not radio button).

* the various commands used in get_pak.sh have return codes, which according to According to https://stackoverflow.com/questions/5638321/why-child-process-returns-exit-status-32512-in-unix are
08-27 23:52:54.335  9799  9833 I com.simutrans: Message: action_triggered       shell 1 25
08-27 23:52:54.368  9799  9833 I com.simutrans: Message: action_triggered       wget 32512 0 0x7F00
08-27 23:52:54.403  9799  9833 I com.simutrans: Message: action_triggered       curl 512 0 0x0200
08-27 23:52:54.441  9799  9833 I com.simutrans: Message: action_triggered       tar 256 0 0x0100
08-27 23:52:54.473  9799  9833 I com.simutrans: Message: action_triggered       unzip 256 0 0x0100
08-27 23:52:54.498  9799  9833 I com.simutrans: Message: action_triggered       pushd 32512 0 0x7F00
08-27 23:52:54.523  9799  9833 I com.simutrans: Message: action_triggered       popd 32512 0 0x7F00
08-27 23:52:54.548  9799  9833 I com.simutrans: Message: action_triggered       ./get_pak 32512 0 0x7F00

Exit code is on mask 0xFF00.

via adb shell:
wget => 127|wget: inaccessible or not found
curl => 2|curl: try 'curl --help' or 'curl --manual' for more information
tar => 1|tar: Needs -txc (see "tar --help")
unzip => 1|unzip: missing archive filename
pushd => 127|pushd: inaccessible or not found


# curl

curl as provided by pelya relies on two repositories: ssl and crypto. 

The flow is understood as:
* project/jni/application/Android.mk or project/jni/application/AndroidAppSettings.cfg request the package ssl and crypto.
* project/jni/application/pkg-config maps openssl|ssl|libssl (they are synonyms) to libssl.so.sdl.1.so and crypto|libcrypto to libcrypto.so.sdl.1.so; meaning the name with special version becomes compilation target
* project/jni/Makefile.prebuilt has a specific target rule for these compilation target, upon which project/jni/openssl/compile.sh is run, to compile the libs
ssl and crypto are symbolic links created and stored inside the repository. 
It is a mark that ssl and crypto package must be provided explicitly in simutrans AndroidAppSettings.cfg, prior the inclusion of curl?

ssl is a symbolic link towards openssl. It generates a libssl.so.sdl.1.so.
crypto is also a symoblic link towards folder openssl. It generates a libcrypto.so.sdl.1.so.
Supposedly, the default names clashes with preincluded system libraries in older Android phones, hence the suffix.

crypto is a dependency of ssl. However, compilation of the library will generate both libssl and libcrypto at the same time. pelya build script will configure openssl to append a version number (sdl.1.so), so libssl knows the name of libcrypto.

It could be an option to regroup all fluidsynth libs into a single folder, and make symbolic links instead, in particular for all libs related to fluidsynth. However Android.mk is different for each lib (LOCAL_SHARED_MODULES point to different targets according to the lib). So maybe differentiating each .so into its own folder is an OK solution.

curl has a rather easy mechanism for downloading files
https://curl.se/libcurl/c/libcurl-tutorial.html

There seems to be some options to enable, but the first obstacle is SSL not being.
https://stackoverflow.com/questions/66321383/libcurl-returns-error-code-77-when-the-curlopt-ssl-verifypeer-is-not-disabled

SSL is disabled for the time being.
Admittedly, https://curl.se/libcurl/c/CURLOPT_CAINFO.html is required to provide the path to certificate authority bundle. What is this path?
https://developer.android.com/training/articles/security-ssl
https://stackoverflow.com/questions/15375577/how-to-point-openssl-to-the-root-certificates-on-an-android-device
https://curl.se/docs/sslcerts.html
cacert.pem can be downloaded from there.
https://curl.se/docs/caextract.html
And this can be linked via curl_easy_setopt(curl, CURLOPT_CAINFO, cabundle_path); It works out of the box.
The question is now where do we put the cacert.pem? It will make sense to put it in com.simutrans which belongs to the data, kind of hidden from the user, but this mostly applies to Android only.

For the time being, cacert.pem is included by build scripts into the data dir, so that it is readable by ssl lib.

Downloading file to memory done with
https://curl.se/libcurl/c/getinmemory.html


# unzip

Targetting libzip library; zziplib exists, but unsure of how to use it, its maintenance status, and its license.

# resolution

Right now, resolution is predefined in the command line arguments sent by sdl. Not providing the screensize argument, SDL will automatically retrieve the native resolution. However, for some reason, the native resolution is not an accepted video mode by SDL; root cause is a piece of code that raises the resolution above the native resolution. The main takeaway however is the program is able to infer phone screen resolution, and there is no need of hardcoding an input resolution.

However, in the case of all smartphones, the dpi is very high, so the text and buttons are very small if displayed with native resolution. A scale up is required.

Libsdl android has a specific rendereing layer that is able to upscale the SDL window to fit screen. Meaning that if we choose to render a smaller window, we achieve a scaling up effect. This is good enoough.

I saw SDL_SoftStretch, which could be a way to 'stretch a scaling window'


# compilers NDK version

```objdump -s --section .comment project/obj/local/x86/libapplication.so```
to show which compiler has been used to compile. 

* ndk;23.0.7599858 => Android 7284624, based on r416183b, clang 12.0.5
* ndk;21.4.7075529 => Android 7019983, based on r365631c3, clang 9.0.9 => incompatible simutrans, expects --no-rosegment argument in ```project/jni/application/setEnvironment-xxx.sh```, not available in ndk
* ndk;20.1.5948944 => Android 5220042, based on r346389c, clang 8.0.7 => incompatible simutrans, expects --no-rosegment argument in ```project/jni/application/setEnvironment-xxx.sh```, not available in ndk


pelya updated the scripts in commit 7a548f6259 to be used with NDK 22, and added --no-rosegment from this point onwards. This flag does not seem to be necessary, and patching it out enables earlier versions of the compiler, down to.

libcurl is targetting ndk-bundle which is ndk22. ndk-bundle is subject to compiler change, so let's keep it at targetting a side by side ndk for the time being, which has a fixed version.

There is no reason to downgrade compiler as of now.

Fluidsynth and its dependencies has used Android 7019983, based on clang 9.0.9; this targets androidabi24, but not much more information.


29/08 a new issue has appeared while compiling curl; environment architecture scripts such as ```project/jni/openssl/setCrossEnvironment-arm64-v8a.sh``` have previously used ```AR="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/$GCCPREFIX-ar"```. For application, this script has been updated somewhere along the line to ```AR="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/llvm-ar"```.
Indeed, on ndk r22, $GCCPREFIX-ar and llvm-ar both exist, but on ndk r23, only llvm-ar exists.
Only llvm-ranlib is introduced starting from ndk r22 (or ndk r21, not confirmed).



# api target

16 for 32 bit systems (arm7 or x86)
21 for 64 bit systems (arm8 or x64)


# Multi objs in library

Fluidsynth makes use of several libraries which are all included in the fluidsynth zip package.
oboe glib-2.0 gthread-2.0 gobject-2.0 sndfile instpatch-1.0

glib-2.0 gthread-2.0 gobject-2.0 are typically part of the same library. 
So how can we make a single package that exports multiple libs? It is impossible to define modules with multiple shared libraries.
Therefore a single Android.mk file for multiple shared libraries = multiple modules. Meaning fluidsynth still has to refer to multiple modules.
Do you even need to find the folder of a module? compilation will manage to correctly find the include sources, but only if we refer to Android.mk libraries.
In the case of custom build script, there is no such tools to connect to includes folders form other modules, so finding back the includes and others is difficult.
COMPILED_LIBRARIES


One of the problem is the copy of the libraries back to project/objs.

# Dependency strategy

pelya repository has developpe a layer on top of SDL 1.2, which interfaces with its own configuration files. The layer is feature complete:

SDL2 has its own layer too, although it is unclear how feature complete it is.

Staying as close as possible from the SDL2 layer has its advantage, as it is maintained by a community. pelya has limited reach and limited support.
However, feature wise it is also limited.

# assets

The pelya solution is unknown, files put in AndroidData are somehow found in the APK, but no idea how it has been done.
According to https://stackoverflow.com/questions/18302603/where-to-place-the-assets-folder-in-android-studio/18302624
There is an project/app/src/main/assets folder.
Accessing the content of this folder is done through AssetManager, returned by the function getAssets().


The alternative is:
Assets can be delivered via PAD, Play Assets Delivery. There is a methodology described at developer.android.com/guide/playcore/asset-delivery/integrate-java

The thing is build.gradle needs to hold a reference to the assets folder
The build script makes a copy of the build-template.gradle, and cleans the line of the assetpack.
Then simutrans adds a zip in the assets folder, which is too late as the build gradle is now missing the reference to the assetpack.
There is a cross dependency happening. ./changeAppSetting.sh is required to run AndroidPrebuilt.sh which is required to have an assetpack. 
But it is not easy to find...


# build.sh

```
block 43-60: changesymbolic links
block 62-72: first time running, runs changeAppSettings.sh ; makes also Settings.mk
	Switching build target to simutrans
	Patching ../src/Accelerometer.java
	Patching ../src/Advertisement.java
	Patching ../src/Audio.java
	Patching ../src/Clipboard.java
	Patching ../src/CloudSave.java
	Patching ../src/DataDownloader.java
	Patching ../src/DummyService.java
	Patching ../src/GLSurfaceView_SDL.java
	Patching ../src/Globals.java
	Patching ../src/Keycodes.java
	Patching ../src/MainActivity.java
	Patching ../src/RestartMainActivity.java
	Patching ../src/Settings.java
	Patching ../src/SettingsMenu.java
	Patching ../src/SettingsMenuKeyboard.java
	Patching ../src/SettingsMenuMisc.java
	Patching ../src/SettingsMenuMouse.java
	Patching ../src/Video.java
	Patching ../src/XZInputStream.java
	Patching project/AndroidManifest.xml
	Patching project/src/Globals.java
	Patching project/jni/Settings.mk
	Patching strings.xml
	grep: project/local.properties: No such file or directory # OK
	Cleaning up dependencies
	Install ImageMagick to auto-resize Ouya icon from icon.png
	Copying app data files from project/jni/application/src/AndroidData to project/assets
	Compiling prebuilt libraries # May need some changes for prebuilding other prebuilt libs
	make: Entering directory '/android-sdl/project/jni'
	make: *** No rule to make target 'openssl/compile.sh', needed by 'openssl/lib-armeabi-v7a/libcrypto.so.sdl.1.so'.  Stop.
	make: Leaving directory '/android-sdl/project/jni'
	Done
block 93-97: launch prebuild of application
block 99-100: It will compile most first items; it is a ndk based build, defining CUSTOM_BUILD_SCRIPT_FIRST_PASS;
[x86_64] Install        : libsdl-1.2.so => libs/x86_64/libsdl-1.2.so
[x86_64] Install        : libsdl_native_helpers.so => libs/x86_64/libsdl_native_helpers.so
[x86_64] Install        : libogg.so => libs/x86_64/libogg.so
[x86_64] Install        : libFLAC.so => libs/x86_64/libFLAC.so
[x86_64] Install        : libvorbis.so => libs/x86_64/libvorbis.so
[x86_64] Install        : libbzip2.so => libs/x86_64/libbzip2.so
[x86_64] Install        : libssl.so.sdl.1.so => libs/x86_64/libssl.so.sdl.1.so
[x86_64] Install        : libcrypto.so.sdl.1.so => libs/x86_64/libcrypto.so.sdl.1.so
[x86_64] Install        : libcurl-sdl.so => libs/x86_64/libcurl-sdl.so
[x86_64] Install        : libzip.so => libs/x86_64/libzip.so
[x86_64] Install        : libfluidsynth.so => libs/x86_64/libfluidsynth.so
[x86_64] Install        : liboboe.so => libs/x86_64/liboboe.so
[x86_64] Install        : libglib-2.0.so => libs/x86_64/libglib-2.0.so
[x86_64] Install        : libgthread-2.0.so => libs/x86_64/libgthread-2.0.so
[x86_64] Install        : libgobject-2.0.so => libs/x86_64/libgobject-2.0.so
[x86_64] Install        : libc++_shared.so => libs/x86_64/libc++_shared.so
[x86_64] Install        : libsndfile.so => libs/x86_64/libsndfile.so
[x86_64] Install        : libinstpatch-1.0.so => libs/x86_64/libinstpatch-1.0.so
[x86_64] Install        : libvorbisenc.so => libs/x86_64/libvorbisenc.so
[x86_64] Install        : libopus.so => libs/x86_64/libopus.so
block 101: builds the paplication, build one step using /android-sdl/project/jni/application/CustomBuildScript.mk that includes as well ../Settings.mk, with classic make
	build (with cd simutrans && ./AndroidBuild.sh armeabi-v7a arm-linux-androideabi) and link
	simutrans Makefile is using some kind of SDL configuration script (sdl-config) with sdl-1.2, but this is only the case for linux. it is
		SDL_CFLAGS is -I/android-sdl/project/jni/application/../sdl-1.2/include -D_GNU_SOURCE=1 -D_REENTRANT
		SDL_LDFLAGS is -lsdl-1.2
	the classic sdl2 is using pkg-config sdl2, but it does not seem to be defined??
	on linux ubuntu, pkg-config sdl2 is returning correct things!
		SDL_CFLAGS is -D_REENTRANT -I/usr/include/SDL2
		SDL_LDFLAGS is -lSDL2 -Wl,--no-undefined -lm -ldl -lasound -lm -ldl -lpthread -lpulse-simple -lpulse -lX11 -lXext -lXcursor -lXinerama -lXi -lXrandr -lXss -lXxf86vm -lwayland-egl -lwayland-client -lwayland-cursor -lxkbcommon -lpthread -lrt
	So what we see is there is no SDL2main linked
	===> LD  build/x86_64/sim
/opt/android-sdk-linux/ndk/23.0.7599858/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang++  build/x86_64/sys/clipboard_internal.o  build/x86_64/music/fluidsynth.o  build/x86_64/gui/loadsoundfont_frame.o  build/x86_64/bauer/brueckenbauer.o  build/x86_64/bauer/fabrikbauer.o  build/x86_64/bauer/goods_manager.o  build/x86_64/bauer/hausbauer.o  build/x86_64/bauer/tunnelbauer.o  build/x86_64/bauer/tree_builder.o  build/x86_64/bauer/vehikelbauer.o  build/x86_64/bauer/wegbauer.o  build/x86_64/boden/boden.o  build/x86_64/boden/brueckenboden.o  build/x86_64/boden/fundament.o  build/x86_64/boden/grund.o  build/x86_64/boden/monorailboden.o  build/x86_64/boden/tunnelboden.o  build/x86_64/boden/wasser.o  build/x86_64/boden/wege/kanal.o  build/x86_64/boden/wege/maglev.o  build/x86_64/boden/wege/monorail.o  build/x86_64/boden/wege/narrowgauge.o  build/x86_64/boden/wege/runway.o  build/x86_64/boden/wege/schiene.o  build/x86_64/boden/wege/strasse.o  build/x86_64/boden/wege/weg.o  build/x86_64/dataobj/crossing_logic.o  build/x86_64/dataobj/environment.o  build/x86_64/dataobj/freelist.o  build/x86_64/dataobj/gameinfo.o  build/x86_64/dataobj/height_map_loader.o  build/x86_64/dataobj/koord.o  build/x86_64/dataobj/koord3d.o  build/x86_64/dataobj/loadsave.o  build/x86_64/dataobj/marker.o  build/x86_64/dataobj/objlist.o  build/x86_64/dataobj/powernet.o  build/x86_64/dataobj/records.o  build/x86_64/dataobj/rect.o  build/x86_64/dataobj/ribi.o  build/x86_64/dataobj/route.o  build/x86_64/dataobj/scenario.o  build/x86_64/dataobj/schedule.o  build/x86_64/dataobj/settings.o  build/x86_64/dataobj/tabfile.o  build/x86_64/dataobj/translator.o  build/x86_64/descriptor/bridge_desc.o  build/x86_64/descriptor/building_desc.o  build/x86_64/descriptor/factory_desc.o  build/x86_64/descriptor/goods_desc.o  build/x86_64/descriptor/ground_desc.o  build/x86_64/descriptor/image.o  build/x86_64/descriptor/obj_base_desc.o  build/x86_64/descriptor/reader/bridge_reader.o  build/x86_64/descriptor/reader/building_reader.o  build/x86_64/descriptor/reader/citycar_reader.o  build/x86_64/descriptor/reader/crossing_reader.o  build/x86_64/descriptor/reader/factory_reader.o  build/x86_64/descriptor/reader/good_reader.o  build/x86_64/descriptor/reader/ground_reader.o  build/x86_64/descriptor/reader/groundobj_reader.o  build/x86_64/descriptor/reader/image_reader.o  build/x86_64/descriptor/reader/imagelist2d_reader.o  build/x86_64/descriptor/reader/imagelist_reader.o  build/x86_64/descriptor/reader/obj_reader.o  build/x86_64/descriptor/reader/pedestrian_reader.o  build/x86_64/descriptor/reader/roadsign_reader.o  build/x86_64/descriptor/reader/root_reader.o  build/x86_64/descriptor/reader/sim_reader.o  build/x86_64/descriptor/reader/skin_reader.o  build/x86_64/descriptor/reader/sound_reader.o  build/x86_64/descriptor/reader/text_reader.o  build/x86_64/descriptor/reader/tree_reader.o  build/x86_64/descriptor/reader/tunnel_reader.o  build/x86_64/descriptor/reader/vehicle_reader.o  build/x86_64/descriptor/reader/way_obj_reader.o  build/x86_64/descriptor/reader/way_reader.o  build/x86_64/descriptor/reader/xref_reader.o  build/x86_64/descriptor/sound_desc.o  build/x86_64/descriptor/tunnel_desc.o  build/x86_64/descriptor/vehicle_desc.o  build/x86_64/descriptor/way_desc.o  build/x86_64/display/font.o  build/x86_64/display/simgraph16.o  build/x86_64/display/simview.o  build/x86_64/display/viewport.o  build/x86_64/finder/placefinder.o  build/x86_64/freight_list_sorter.o  build/x86_64/gui/ai_option_t.o  build/x86_64/gui/ai_selector.o  build/x86_64/gui/banner.o  build/x86_64/gui/base_info.o  build/x86_64/gui/baum_edit.o  build/x86_64/gui/city_info.o  build/x86_64/gui/citybuilding_edit.o  build/x86_64/gui/citylist_frame_t.o  build/x86_64/gui/citylist_stats_t.o  build/x86_64/gui/climates.o  build/x86_64/gui/components/gui_aligned_container.o  build/x86_64/gui/components/gui_building.o  build/x86_64/gui/components/gui_button.o  build/x86_64/gui/components/gui_button_to_chart.o  build/x86_64/gui/components/gui_chart.o  build/x86_64/gui/components/gui_colorbox.o  build/x86_64/gui/components/gui_combobox.o  build/x86_64/gui/components/gui_container.o  build/x86_64/gui/components/gui_convoiinfo.o  build/x86_64/gui/components/gui_divider.o  build/x86_64/gui/components/gui_fixedwidth_textarea.o  build/x86_64/gui/components/gui_flowtext.o  build/x86_64/gui/components/gui_image.o  build/x86_64/gui/components/gui_image_list.o  build/x86_64/gui/components/gui_component.o  build/x86_64/gui/components/gui_label.o  build/x86_64/gui/components/gui_map_preview.o  build/x86_64/gui/components/gui_numberinput.o  build/x86_64/gui/components/gui_obj_view_t.o  build/x86_64/gui/components/gui_schedule.o  build/x86_64/gui/components/gui_scrollbar.o  build/x86_64/gui/components/gui_scrolled_list.o  build/x86_64/gui/components/gui_scrollpane.o  build/x86_64/gui/components/gui_speedbar.o  build/x86_64/gui/components/gui_tab_panel.o  build/x86_64/gui/components/gui_textarea.o  build/x86_64/gui/components/gui_textinput.o  build/x86_64/gui/components/gui_timeinput.o  build/x86_64/gui/components/gui_waytype_tab_panel.o  build/x86_64/gui/components/gui_world_view_t.o  build/x86_64/gui/convoi_detail_t.o  build/x86_64/gui/convoi_filter_frame.o  build/x86_64/gui/convoi_frame.o  build/x86_64/gui/convoi_info_t.o  build/x86_64/gui/convoy_item.o  build/x86_64/gui/curiosity_edit.o  build/x86_64/gui/curiositylist_frame_t.o  build/x86_64/gui/curiositylist_stats_t.o  build/x86_64/gui/depot_frame.o  build/x86_64/gui/depotlist_frame.o  build/x86_64/gui/display_settings.o  build/x86_64/gui/enlarge_map_frame_t.o  build/x86_64/gui/extend_edit.o  build/x86_64/gui/fabrik_info.o  build/x86_64/gui/factory_chart.o  build/x86_64/gui/factory_edit.o  build/x86_64/gui/factorylist_frame_t.o  build/x86_64/gui/factorylist_stats_t.o  build/x86_64/gui/goods_frame_t.o  build/x86_64/gui/goods_stats_t.o  build/x86_64/gui/ground_info.o  build/x86_64/gui/groundobj_edit.o  build/x86_64/gui/gui_frame.o  build/x86_64/gui/gui_theme.o  build/x86_64/gui/halt_info.o  build/x86_64/gui/halt_list_filter_frame.o  build/x86_64/gui/halt_list_frame.o  build/x86_64/gui/halt_list_stats.o  build/x86_64/gui/headquarter_info.o  build/x86_64/gui/help_frame.o  build/x86_64/gui/jump_frame.o  build/x86_64/gui/minimap.o  build/x86_64/gui/kennfarbe.o  build/x86_64/gui/label_info.o  build/x86_64/gui/labellist_frame_t.o  build/x86_64/gui/labellist_stats_t.o  build/x86_64/gui/line_item.o  build/x86_64/gui/line_management_gui.o  build/x86_64/gui/load_relief_frame.o  build/x86_64/gui/loadfont_frame.o  build/x86_64/gui/loadsave_frame.o  build/x86_64/gui/map_frame.o  build/x86_64/gui/message_frame_t.o  build/x86_64/gui/message_option_t.o  build/x86_64/gui/message_stats_t.o  build/x86_64/gui/messagebox.o  build/x86_64/gui/money_frame.o  build/x86_64/gui/obj_info.o  build/x86_64/gui/optionen.o  build/x86_64/gui/pakselector.o  build/x86_64/gui/pakinstaller.o  build/x86_64/gui/password_frame.o  build/x86_64/gui/player_frame_t.o  build/x86_64/gui/privatesign_info.o  build/x86_64/gui/savegame_frame.o  build/x86_64/gui/scenario_frame.o  build/x86_64/gui/scenario_info.o  build/x86_64/gui/schedule_list.o  build/x86_64/gui/script_tool_frame.o  build/x86_64/gui/server_frame.o  build/x86_64/gui/settings_frame.o  build/x86_64/gui/settings_stats.o  build/x86_64/gui/signal_spacing.o  build/x86_64/gui/simwin.o  build/x86_64/gui/sound_frame.o  build/x86_64/gui/sprachen.o  build/x86_64/gui/station_building_select.o  build/x86_64/gui/themeselector.o  build/x86_64/gui/tool_selector.o  build/x86_64/gui/trafficlight_info.o  build/x86_64/gui/vehiclelist_frame.o  build/x86_64/gui/welt.o  build/x86_64/io/classify_file.o  build/x86_64/io/raw_image.o  build/x86_64/io/raw_image_bmp.o  build/x86_64/io/raw_image_png.o  build/x86_64/io/raw_image_ppm.o  build/x86_64/io/rdwr/bzip2_file_rdwr_stream.o  build/x86_64/io/rdwr/raw_file_rdwr_stream.o  build/x86_64/io/rdwr/rdwr_stream.o  build/x86_64/io/rdwr/zlib_file_rdwr_stream.o  build/x86_64/network/checksum.o  build/x86_64/network/memory_rw.o  build/x86_64/network/network.o  build/x86_64/network/network_address.o  build/x86_64/network/network_cmd.o  build/x86_64/network/network_cmd_ingame.o  build/x86_64/network/network_cmd_scenario.o  build/x86_64/network/network_cmp_pakset.o  build/x86_64/network/network_file_transfer.o  build/x86_64/network/network_packet.o  build/x86_64/network/network_socket_list.o  build/x86_64/network/pakset_info.o  build/x86_64/obj/baum.o  build/x86_64/obj/bruecke.o  build/x86_64/obj/crossing.o  build/x86_64/obj/field.o  build/x86_64/obj/gebaeude.o  build/x86_64/obj/groundobj.o  build/x86_64/obj/label.o  build/x86_64/obj/leitung2.o  build/x86_64/obj/pillar.o  build/x86_64/obj/roadsign.o  build/x86_64/obj/signal.o  build/x86_64/obj/simobj.o  build/x86_64/obj/tunnel.o  build/x86_64/obj/wayobj.o  build/x86_64/obj/wolke.o  build/x86_64/obj/zeiger.o  build/x86_64/old_blockmanager.o  build/x86_64/player/ai.o  build/x86_64/player/ai_goods.o  build/x86_64/player/ai_passenger.o  build/x86_64/player/ai_scripted.o  build/x86_64/player/finance.o  build/x86_64/player/simplay.o  build/x86_64/script/api/api_city.o  build/x86_64/script/api/api_command.o  build/x86_64/script/api/api_const.o  build/x86_64/script/api/api_control.o  build/x86_64/script/api/api_convoy.o  build/x86_64/script/api/api_factory.o  build/x86_64/script/api/api_gui.o  build/x86_64/script/api/api_halt.o  build/x86_64/script/api/api_include.o  build/x86_64/script/api/api_line.o  build/x86_64/script/api/api_map_objects.o  build/x86_64/script/api/api_obj_desc.o  build/x86_64/script/api/api_obj_desc_base.o  build/x86_64/script/api/api_pathfinding.o  build/x86_64/script/api/api_player.o  build/x86_64/script/api/api_scenario.o  build/x86_64/script/api/api_schedule.o  build/x86_64/script/api/api_settings.o  build/x86_64/script/api/api_simple.o  build/x86_64/script/api/api_tiles.o  build/x86_64/script/api/api_world.o  build/x86_64/script/api/export_desc.o  build/x86_64/script/api/get_next.o  build/x86_64/script/api_class.o  build/x86_64/script/api_function.o  build/x86_64/script/api_param.o  build/x86_64/script/dynamic_string.o  build/x86_64/script/export_objs.o  build/x86_64/script/script.o  build/x86_64/script/script_loader.o  build/x86_64/script/script_tool_manager.o  build/x86_64/simcity.o  build/x86_64/simconvoi.o  build/x86_64/simdebug.o  build/x86_64/simdepot.o  build/x86_64/simevent.o  build/x86_64/simfab.o  build/x86_64/simhalt.o  build/x86_64/siminteraction.o  build/x86_64/simintr.o  build/x86_64/simio.o  build/x86_64/simline.o  build/x86_64/simlinemgmt.o  build/x86_64/simloadingscreen.o  build/x86_64/simmain.o  build/x86_64/simmem.o  build/x86_64/simmenu.o  build/x86_64/simmesg.o  build/x86_64/simplan.o  build/x86_64/simskin.o  build/x86_64/simsound.o  build/x86_64/simticker.o  build/x86_64/simtool.o  build/x86_64/simtool-scripted.o  build/x86_64/simware.o  build/x86_64/simworld.o  build/x86_64/squirrel/sq_extensions.o  build/x86_64/squirrel/sqstdlib/sqstdaux.o  build/x86_64/squirrel/sqstdlib/sqstdblob.o  build/x86_64/squirrel/sqstdlib/sqstdio.o  build/x86_64/squirrel/sqstdlib/sqstdmath.o  build/x86_64/squirrel/sqstdlib/sqstdrex.o  build/x86_64/squirrel/sqstdlib/sqstdstream.o  build/x86_64/squirrel/sqstdlib/sqstdstring.o  build/x86_64/squirrel/sqstdlib/sqstdsystem.o  build/x86_64/squirrel/squirrel/sqapi.o  build/x86_64/squirrel/squirrel/sqbaselib.o  build/x86_64/squirrel/squirrel/sqclass.o  build/x86_64/squirrel/squirrel/sqcompiler.o  build/x86_64/squirrel/squirrel/sqdebug.o  build/x86_64/squirrel/squirrel/sqfuncstate.o  build/x86_64/squirrel/squirrel/sqlexer.o  build/x86_64/squirrel/squirrel/sqmem.o  build/x86_64/squirrel/squirrel/sqobject.o  build/x86_64/squirrel/squirrel/sqstate.o  build/x86_64/squirrel/squirrel/sqtable.o  build/x86_64/squirrel/squirrel/sqvm.o  build/x86_64/sys/simsys.o  build/x86_64/unicode.o  build/x86_64/utils/cbuffer_t.o  build/x86_64/utils/checklist.o  build/x86_64/utils/csv.o  build/x86_64/utils/log.o  build/x86_64/utils/searchfolder.o  build/x86_64/utils/sha1.o  build/x86_64/utils/sha1_hash.o  build/x86_64/utils/simrandom.o  build/x86_64/utils/simstring.o  build/x86_64/utils/simthread.o  build/x86_64/vehicle/air_vehicle.o  build/x86_64/vehicle/movingobj.o  build/x86_64/vehicle/pedestrian.o  build/x86_64/vehicle/rail_vehicle.o  build/x86_64/vehicle/road_vehicle.o  build/x86_64/vehicle/simroadtraffic.o  build/x86_64/vehicle/vehicle.o  build/x86_64/vehicle/vehicle_base.o  build/x86_64/vehicle/water_vehicle.o  build/x86_64/sys/simsys_s.o  build/x86_64/sound/sdl_sound.o -fPIC -g -ffunction-sections -fdata-sections -Wl,--gc-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -Wformat -Werror=format-security -Oz -DNDEBUG -Wl,--build-id -Wl,--warn-shared-textrel -Wl,--fatal-warnings -Wl,--no-undefined -Wl,-z,noexecstack -Qunused-arguments -Wl,-z,relro -Wl,-z,now -Wl,--no-rosegment -shared -Wl,-soname,libapplication.so /android-sdl/project/jni/application/../../obj/local/x86_64/libsdl-1.2.so /android-sdl/project/jni/application/../../obj/local/x86_64/libbzip2.so /android-sdl/project/jni/application/../../obj/local/x86_64/libssl.so.sdl.1.so /android-sdl/project/jni/application/../../obj/local/x86_64/libcrypto.so.sdl.1.so /android-sdl/project/jni/application/../../obj/local/x86_64/libcurl-sdl.so /android-sdl/project/jni/application/../../obj/local/x86_64/libzip.so /android-sdl/project/jni/application/../../obj/local/x86_64/libfluidsynth.so -landroid -llog -latomic -lm -L/android-sdl/project/jni/application/simutrans/simutrans/../../../../obj/local/x86_64  -lfreetype -lfluidsynth  -lbz2 -lz -lpng -lsdl-1.2 -o build/x86_64/sim

```

```

build.sh
exit 0 line 103

pkg-config
+  sdl2)
+    PKG=SDL2
+    ;;

```

# Run flow

Observing the log of SDL2 gives

```
09-21 22:10:26.939 16827 16827 V SDL     : Device size: 1080x2400
09-21 22:10:26.952 16827 16854 V SDL     : Running main function SDL_main from library /data/app/~~bFvXm_am5rogUGbyQhtaJg==/com.simutrans-gGytS6L7SQ6TS3y_6GQHMQ==/lib/arm64/libapplication.so
09-21 22:10:26.952 16827 16854 V SDL     : nativeRunMain()
09-21 22:10:26.953 16827 16854 V SDL     : nativeRunMain(): Going into SDL_main, 1.
09-21 22:10:26.971 16827 16854 V SDL     : setOrientation() requestedOrientation=10 width=704 height=560 resizable=true hint=
09-21 22:10:26.995 16827 16854 V SDL     : nativeRunMain(): Exiting SDL_main, 1
09-21 22:10:26.995 16827 16854 F libc    : Pointer tag for 0x78613d5080 was truncated.
09-21 22:10:26.997 16827 16854 F libc    : Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 16854 (SDLThread), pid 16827 (SDLActivity)

Or

-21 23:02:17.806  2014  2014 V SDL     : Device size: 1080x2400
09-21 23:02:17.821  2014  2043 V SDL     : Running main function SDL_main from library /data/app/~~pPgEMsDIctnm1Fh8zFT7rw==/com.simutrans-yopxwusQa-AvbtRP4lrJ7w==/lib/arm64/libapplication.so
09-21 23:02:17.821  2014  2043 V SDL     : nativeRunMain()
09-21 23:02:17.831  2014  2043 V SDL     : nativeRunMain(): Going into SDL_main, 1.
09-21 23:02:17.837  2014  2043 W com.simutrans: Debug: loadsave_t::rd_open      File 'settings.xml' does not exist or is not accessible
09-21 23:02:17.848  2014  2043 I com.simutrans: Message: dr_os_init(SDL2)       SDL Driver: Android
09-21 23:02:17.848  2014  2043 I com.simutrans: Message: dr_os_open(SDL2)       Arguments width=704, height=560, fullscreen=0
09-21 23:02:17.853  2014  2043 V SDL     : setOrientation() requestedOrientation=10 width=704 height=560 resizable=true hint=
09-21 23:02:17.868  2014  2043 E com.simutrans: ERROR: font_t::load_from_file   Cannot open 'font/prop.fnt'
09-21 23:02:17.868  2014  2043 E com.simutrans: ERROR: font_t::load_from_file   Cannot open 'font/prop.fnt'
09-21 23:02:17.868  2014  2043 E com.simutrans: ERROR: dr_fatal_notify  No fonts found!
09-21 23:02:17.868  2014  2043 E com.simutrans: ERROR: simu_main()      Failed to initialize graphics system.
09-21 23:02:17.868  2014  2043 V SDL     : nativeRunMain(): Exiting SDL_main, 1
09-21 23:02:17.869  2014  2043 F libc    : Pointer tag for 0x7a343fa050 was truncated.
09-21 23:02:17.870  2014  2043 F libc    : Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 2043 (SDLThread), pid 2014 (SDLActivity)
09-21 23:02:17.958  2014  2014 V SDL     : onWindowFocusChanged(): true
09-21 23:02:17.958  2014  2014 V SDL     : nativeFocusChanged()
```


```
From SDLActivity.java
-> SDLActivity.nativeRunMain
goes to
SDL_android.c
-> JNIEXPORT int JNICALL SDL_JAVA_INTERFACE(nativeRunMain)(JNIEnv *env, jclass cls, jstring library, jstring function, jobject array)


simsys_s2.cc
->dr_os_open()

project/jni/SDL2/src/video/SDL_video.c
->1556 SDL_CreateWindow
->1701 SDL_RecreateWindow
project/jni/SDL2/src/video/android/SDL_androidvideo.c
->device->CreateSDLWindow from Android_CreateDevice
->_this->CreateSDLWindow(
project/jni/SDL2/src/video/android/SDL_androidwindow.c
->Android_CreateWindow
project/jni/SDL2/src/core/android/SDL_android.c
-> Android_JNI_SetOrientation
project/javaSDL2/SDLActivity.java
-> setOrientation
project/javaSDL2/SDLActivity.java
-> setOrientationBis
```


```
09-22 19:54:51.029  1325  1325 E com.simutrans: Not starting debugger since process cannot load the jdwp agent.
09-22 19:54:51.186  1361  1361 I libc    : SetHeapTaggingLevel: tag level set to 0
09-22 19:54:51.188  1325  1325 V SDL     : Device: surya
09-22 19:54:51.188  1325  1325 V SDL     : Model: M2007J20CG
09-22 19:54:51.188  1325  1325 V SDL     : onCreate()
09-22 19:54:51.226  1325  1325 V SDL     : nativeSetupJNI()
09-22 19:54:51.227  1325  1325 V SDL     : AUDIO nativeSetupJNI()
09-22 19:54:51.227  1325  1325 V SDL     : CONTROLLER nativeSetupJNI()
09-22 19:54:51.265  1325  1325 V SDL     : onStart()
09-22 19:54:51.266  1325  1325 V SDL     : onResume()
09-22 19:54:51.322  1325  1325 V SDL     : surfaceCreated()
09-22 19:54:51.322  1325  1325 V SDL     : surfaceChanged()
09-22 19:54:51.322  1325  1325 V SDL     : pixel format RGB_565
09-22 19:54:51.322  1325  1325 V SDL     : Window size: 1080x2179
09-22 19:54:51.323  1325  1325 V SDL     : Device size: 1080x2400
09-22 19:54:51.331  1325  1390 V SDL     : Running main function SDL_main from library /data/app/~~AXSG2E1hRAASPX0UGuybsg==/com.simutrans-M5otSkQE0PB7Mi5nAu_M2w==/lib/arm64/libapplication.so
09-22 19:54:51.331  1325  1390 V SDL     : Argument simutrans
09-22 19:54:51.331  1325  1390 V SDL     : Argument -use_workdir
09-22 19:54:51.331  1325  1390 V SDL     : Argument -autodpi
09-22 19:54:51.331  1325  1390 V SDL     : Argument -fullscreen
09-22 19:54:51.331  1325  1390 V SDL     : Argument -debug
09-22 19:54:51.331  1325  1390 V SDL     : Argument 5
09-22 19:54:51.331  1325  1390 V SDL     : nativeRunMain()
09-22 19:54:51.334  1325  1390 W com.simutrans: Debug: loadsave_t::rd_open      File 'settings.xml' does not exist or is not accessible
09-22 19:54:51.358  1325  1390 I com.simutrans: Message: dr_os_init(SDL2)       SDL Driver: Android
09-22 19:54:51.359  1325  1390 I com.simutrans: Message: dr_os_open(SDL2)       Arguments width=1080, height=2400, fullscreen=1
09-22 19:54:51.363  1325  1390 V SDL     : setOrientation() requestedOrientation=7 width=1080 height=2400 resizable=false hint=
09-22 19:54:51.446  1325  1325 V SDL     : surfaceChanged()
09-22 19:54:51.447  1325  1325 V SDL     : pixel format RGB_565
09-22 19:54:51.447  1325  1325 V SDL     : Window size: 1080x2309
09-22 19:54:51.447  1325  1325 V SDL     : Device size: 1080x2400
09-22 19:54:51.455  1325  1390 I com.simutrans: Message: font_t::load_from_file Opening 'font/prop.fnt'
09-22 19:54:51.455  1325  1390 E com.simutrans: ERROR: font_t::load_from_file   Cannot open 'font/prop.fnt'
09-22 19:54:51.455  1325  1390 I com.simutrans: Message: font_t::load_from_file Opening 'font/prop.fnt'
09-22 19:54:51.455  1325  1390 E com.simutrans: ERROR: font_t::load_from_file   Cannot open 'font/prop.fnt'
09-22 19:54:51.455  1325  1390 E com.simutrans: ERROR: dr_fatal_notify  No fonts found!
09-22 19:54:51.455  1325  1390 E com.simutrans: ERROR: simu_main()      Failed to initialize graphics system.
09-22 19:54:51.455  1325  1390 F libc    : Pointer tag for 0x6f7a2c9010 was truncated.
09-22 19:54:51.455  1325  1390 F libc    : Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 1390 (SDLThread), pid 1325 (SDLActivity)
09-22 19:54:51.497  1325  1325 V SDL     : onWindowFocusChanged(): true
09-22 19:54:51.497  1325  1325 V SDL     : nativeFocusChanged()
```


Below is the logs of SDL-1.2 for reference
```
09-22 20:25:18.241  6575  6575 E com.simutrans: Not starting debugger since process cannot load the jdwp agent.
09-22 20:25:18.326  6575  6575 I SDL     : libSDL: Settings.LoadConfig(): loaded settings successfully
09-22 20:25:18.326  6575  6575 I SDL     : libSDL: Creating startup screen
09-22 20:25:18.351  6575  6575 V SDL     : SD card permission 1: com.simutrans perms [Ljava.lang.String;@fdad4b9 name com.simutrans ver 121.0
09-22 20:25:18.473  6575  6575 I SDL     : libSDL: onWindowFocusChanged: true - sending onPause/onResume
09-22 20:25:18.551  6575  6598 I SDL     : libSDL: Loading libraries
09-22 20:25:18.552  6575  6598 I SDL     : libSDL: loaded lib sdl_native_helpers from System.loadLibrary(l)
09-22 20:25:18.554  6575  6598 I SDL     : libSDL: loaded lib sdl-1.2 from System.loadLibrary(l)
09-22 20:25:18.555  6575  6598 I SDL     : libSDL: loaded lib bzip2 from System.loadLibrary(l)
09-22 20:25:18.557  6575  6598 I SDL     : libSDL: loaded lib ssl.so.sdl.1 from System.loadLibrary(l)
09-22 20:25:18.558  6575  6598 I SDL     : libSDL: loaded lib crypto.so.sdl.1 from System.loadLibrary(l)
09-22 20:25:18.560  6575  6598 I SDL     : libSDL: loaded lib curl-sdl from System.loadLibrary(l)
09-22 20:25:18.562  6575  6598 I SDL     : libSDL: loaded lib zip from System.loadLibrary(l)
09-22 20:25:18.566  6575  6598 I SDL     : libSDL: loaded lib fluidsynth from System.loadLibrary(l)
09-22 20:25:18.571  6575  6598 I SDL     : libSDL: loaded lib c++_shared from System.loadLibrary(l)
09-22 20:25:18.572  6575  6598 I SDL     : libSDL: Loading settings
09-22 20:25:18.572  6575  6575 I SDL     : libSDL: Settings.ProcessConfig(): enter
09-22 20:25:18.632  6575  6575 I SDL     : android.os.Build.MODEL: M2007J20CG
09-22 20:25:18.633  6575  6575 I SDL     : libSDL: Settings.LoadConfig(): loaded settings successfully
09-22 20:25:18.633  6575  6575 I SDL     : libSDL: Settings.ProcessConfig(): loaded settings successfully
09-22 20:25:18.633  6575  6575 I SDL     : libSDL: old app version 1210, new app version 1210
09-22 20:25:18.778  6575  6598 I SDL     : libSDL: loading library application
09-22 20:25:18.806  6575  6598 I SDL     : libSDL: loaded library application
09-22 20:25:18.807  6575  6598 I SDL     : libSDL: loading library sdl_main
09-22 20:25:18.809  6575  6598 I SDL     : libSDL: loaded library sdl_main
09-22 20:25:18.809  6575  6598 V SDL     : libSDL: loaded all libraries
09-22 20:25:18.810  6575  6598 I SDL     : libSDL: 3000-msec timeout in startup screen
09-22 20:25:19.693  6575  6575 I SDL     : libSDL: User clicked change phone config button
09-22 20:25:19.796  6575  6575 I SDL     : libSDL: onWindowFocusChanged: false - sending onPause/onResume
09-22 20:25:21.412  6575  6575 I SDL     : libSDL: onWindowFocusChanged: false - sending onPause/onResume
09-22 20:25:29.947  6575  6575 I SDL     : libSDL: onWindowFocusChanged: false - sending onPause/onResume
09-22 20:25:33.252 16518 16955 E libc    : Access denied finding property "tas.smartpa.debug.disable"
09-22 20:25:33.301 16518 16955 E libc    : Access denied finding property "tas.smartpa.debug.txdevice"
09-22 20:25:33.301 16518 16955 E libc    : Access denied finding property "tas.smartpa.debug.txformat24"
09-22 20:25:34.444  6575  6575 I SDL     : libSDL: Starting data downloader
09-22 20:25:34.444  6575  6575 I SDL     : libSDL: Starting downloader
09-22 20:25:34.782  6575  6575 I SDL     : libSDL: Initializing video and SDL application
09-22 20:25:34.796  6575  6575 I SDL     : Device: surya
09-22 20:25:34.796  6575  6575 I SDL     : Device name: RKQ1.200826.002 test-keys
09-22 20:25:34.796  6575  6575 I SDL     : Device model: M2007J20CG
09-22 20:25:34.796  6575  6575 I SDL     : Device board: surya
09-22 20:25:34.806  6575  6575 I SDL     : libSDL: onWindowFocusChanged: true - sending onPause/onResume
09-22 20:25:34.807  6575  6575 I SDL     : libSDL: DemoGLSurfaceView.onResume(): mRenderer.mGlSurfaceCreated false mRenderer.mPaused false - not doing anything
09-22 20:25:34.833  6575  6575 V SDL     : Main window visible region changed: 0:0:2309:1080 -> 0:0:2309:1080
09-22 20:25:34.833  6575  6575 V SDL     : videoLayout: 0:0:2309:1080 videoLayout.getRootView() 0:0:2309:1080
09-22 20:25:34.844  6575  6575 V SDL     : GLSurfaceView_SDL::onWindowResize(): 2309x1080
09-22 20:25:34.845  6575  6575 D SDL     : libSDL: DemoRenderer.onWindowResize(): 2309x1080
09-22 20:25:34.846  6575  6700 V SDL     : GLSurfaceView_SDL::EglHelper::start(): creating GL context
09-22 20:25:34.846  6575  6700 V SDL     : Desired GL config: R5G6B5A0 depth 0 stencil 0 type GLES
09-22 20:25:34.847  6575  6700 V SDL     : GL config 0: R5G6B5A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 0 (0,0,0,0,0)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 1: R5G5B5A1 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 2 (1,2,2,2,2)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 2: R4G4B4A4 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 5 (4,5,5,5,5)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 3: R5G6B5A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 1 (0,0,0,1,1)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 4: R5G5B5A1 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 3 (1,2,2,3,3)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 5: R4G4B4A4 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 6 (4,5,5,6,6)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 6: R5G6B5A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 1 (0,0,1,1,1)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 7: R5G5B5A1 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 3 (1,2,3,3,3)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 8: R4G4B4A4 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 6 (4,5,6,6,6)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 9: R5G6B5A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 2 (0,0,1,2,2)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 10: R5G5B5A1 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 4 (1,2,3,4,4)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 11: R4G4B4A4 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 7 (4,5,6,7,7)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 12: R5G6B5A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 0 (0,0,0,0,0)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 13: R5G6B5A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 1 (0,0,0,1,1)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 14: R5G6B5A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 1 (0,0,1,1,1)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 15: R5G6B5A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 2 (0,0,1,2,2)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 16: R5G6B5A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 0 (0,0,0,0,0)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 17: R5G6B5A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 1 (0,0,0,1,1)
09-22 20:25:34.847  6575  6700 V SDL     : GL config 18: R5G6B5A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 1 (0,0,1,1,1)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 19: R5G6B5A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 2 (0,0,1,2,2)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 20: R8G8B8A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 8 (8,8,8,8,8)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 21: R8G8B8A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 8 (8,8,8,8,8)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 22: R8G8B8A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,8,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 23: R8G8B8A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,8,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 24: R8G8B8A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 25: R8G8B8A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 26: R8G8B8A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,8,9,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 27: R8G8B8A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,8,9,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 28: R8G8B8A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 8 (8,8,8,8,8)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 29: R8G8B8A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,8,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 30: R8G8B8A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 31: R8G8B8A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,8,9,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 32: R8G8B8A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 8 (8,8,8,8,8)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 33: R8G8B8A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,8,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 34: R8G8B8A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,8,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 35: R8G8B8A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,8,9,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 36: R8G8B8A8 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,9,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 37: R8G8B8A8 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,9,9,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 38: R8G8B8A8 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,9,10,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 39: R8G8B8A8 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 11 (8,9,10,11,11)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 40: R8G8B8A8 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,9,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 41: R8G8B8A8 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,9,9,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 42: R8G8B8A8 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,9,10,10,10)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 43: R8G8B8A8 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 11 (8,9,10,11,11)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 44: R8G8B8A8 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 9 (8,9,9,9,9)
09-22 20:25:34.848  6575  6700 V SDL     : GL config 45: R8G8B8A8 depth 0 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,9,9,10,10)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 46: R8G8B8A8 depth 16 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 10 (8,9,10,10,10)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 47: R8G8B8A8 depth 24 stencil 8 type 69 (GLES GLES2) caveat none nr 1 pos 11 (8,9,10,11,11)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 48: R10G10B10A2 depth 0 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 16 (14,15,15,15,15)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 49: R10G10B10A2 depth 0 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 17 (14,15,15,16,16)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 50: R10G10B10A2 depth 16 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 17 (14,15,16,16,16)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 51: R10G10B10A2 depth 24 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (14,15,16,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 52: R0G0B0A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 17 (16,16,16,16,16)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 53: R0G0B0A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 17 (16,16,16,16,16)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 54: R0G0B0A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 17 (16,16,16,16,16)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 55: R0G0B0A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (16,16,16,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 56: R0G0B0A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (16,16,16,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 57: R0G0B0A0 depth 0 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (16,16,16,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 58: R0G0B0A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (16,16,17,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 59: R0G0B0A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (16,16,17,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 60: R0G0B0A0 depth 16 stencil 0 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 18 (16,16,17,17,17)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 61: R0G0B0A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 19 (16,16,17,18,18)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 62: R0G0B0A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 19 (16,16,17,18,18)
09-22 20:25:34.849  6575  6700 V SDL     : GL config 63: R0G0B0A0 depth 24 stencil 8 type 69 (GLES GLES2) caveat non-conformant nr 1 pos 19 (16,16,17,18,18)
09-22 20:25:34.849  6575  6700 V SDL     : GLSurfaceView_SDL::EGLConfigChooser::chooseConfig(): selected 0: R5G6B5A0 depth 0 stencil 0 type 69 (GLES GLES2) caveat none nr 1 pos 0 (0,0,0,0,0)
09-22 20:25:34.855  6575  6700 V SDL     : GLSurfaceView_SDL::EglHelper::createSurface(): creating GL context
09-22 20:25:34.857  6575  6575 V SDL     : Main window visible region changed: 0:0:2309:1080 -> 0:0:2309:1080
09-22 20:25:34.857  6575  6575 V SDL     : videoLayout: 0:0:2309:1080 videoLayout.getRootView() 0:0:2309:1080
09-22 20:25:34.860  6575  6700 I SDL     : libSDL: DemoRenderer.onSurfaceCreated(): paused false mFirstTimeStart true
09-22 20:25:34.860  6575  6700 I SDL     : libSDL: DemoRenderer.onSurfaceChanged(): paused false mFirstTimeStart false w 2309 h 1080
09-22 20:25:34.860  6575  6700 I libSDL  : Physical screen resolution is 2308x1080 43Ratio 0
09-22 20:25:34.862  6575  6575 V SDL     : captureMouse::requestPointerCapture() delayed
09-22 20:25:34.864  6575  6575 V SDL     : DemoGLSurfaceView::onPointerCaptureChange(): true
09-22 20:25:34.876  6575  6700 I SDL     : libSDL: setting envvar LANGUAGE to 'en_US'
09-22 20:25:34.895  6575  6700 D SDL     : libSDL: Is running on OUYA: false
09-22 20:25:34.934  6575  6700 I libSDL  : Changing curdir to "/storage/emulated/0/Android/data/com.simutrans/files"
09-22 20:25:34.934  6575  6700 I libSDL  : Calling SDL_main("simutrans -use_workdir -autodpi -fullscreen -debug 5")
09-22 20:25:34.934  6575  6700 I libSDL  : param 0 = "simutrans"
09-22 20:25:34.934  6575  6700 I libSDL  : param 1 = "-use_workdir"
09-22 20:25:34.934  6575  6700 I libSDL  : param 2 = "-autodpi"
09-22 20:25:34.934  6575  6700 I libSDL  : param 3 = "-fullscreen"
09-22 20:25:34.934  6575  6700 I libSDL  : param 4 = "-debug"
09-22 20:25:34.934  6575  6700 I libSDL  : param 5 = "5"
09-22 20:25:34.935  6575  6700 W com.simutrans: Debug: loadsave_t::rd_open      File 'settings.xml' does not exist or is not accessible
09-22 20:25:34.935  6575  6700 I com.simutrans: Message: simu_main()    Parsing /storage/emulated/0/Android/data/com.simutrans/files/config/simuconf.tab
09-22 20:25:34.936  6575  6700 V libSDL  : calling SDL_SetVideoMode(1119, 523, 16, -2147483648)
09-22 20:25:34.936  6575  6700 I libSDL  : SDL_SetVideoMode(): application requested mode 1119x523 OpenGL 0 HW 0 BPP 16
09-22 20:25:34.936  6575  6700 E libSDL  : ERROR: Setting the swap interval is not supported
09-22 20:25:34.936  6575  6700 E libSDL  : ERROR: Getting the swap interval is not supported
09-22 20:25:34.936  6575  6700 E libSDL  : ERROR: GL_GetAttribute not supported
09-22 20:25:34.936  6575  6700 V libSDL  : SDL_SetVideoMode(): Requested mode: 1119x523x16, obtained mode 1119x523x16
09-22 20:25:34.936  6575  6700 V libSDL  : SDL_SetVideoMode(): returning surface 0xb400006fd3ccaf20
09-22 20:25:34.936  6575  6700 D com.simutrans: Debug: dr_os_open(SDL)  SDL_driver=android, hw_available=1, video_mem=131072, blit_sw=0, bpp=16, bytes=2
09-22 20:25:34.936  6575  6700 D com.simutrans: Debug: dr_os_open(SDL)  Screen Flags: requested=80000000, actual=c0000020
09-22 20:25:34.936  6575  6700 D com.simutrans: Debug: dr_os_open(SDL)  SDL realized screen size width=1119, height=523 (requested w=1119, h=523)
09-22 20:25:34.937  6575  6700 I com.simutrans: Message: font_t::load_from_file Opening 'font/prop.fnt'
09-22 20:25:34.937  6575  6700 I com.simutrans: Message: font_t::load_from_fnt  Loading font 'font/prop.fnt'
09-22 20:25:34.937  6575  6700 I com.simutrans: Message: font_t::load_from_fnt  font/prop.fnt successfully loaded as old format prop font!
09-22 20:25:34.937  6575  6700 I com.simutrans: Message: simu_main()    Loading colours from /storage/emulated/0/Android/data/com.simutrans/files/config/simuconf.tab
09-22 20:25:34.938  6575  6700 W com.simutrans: Debug: gui_aligned_container_t::set_size        new size (200,100) smaller than min size (334,109)
09-22 20:25:36.270  6575  6575 I SDL     : libSDL: DemoGLSurfaceView.onPause(): mRenderer.mGlSurfaceCreated true mRenderer.mPaused false
09-22 20:25:36.270  6575  6575 V SDL     : GLSurfaceView_SDL::onPause()
09-22 20:25:36.270  6575  6575 I libSDL  : OpenGL context lost - sending SDL_ACTIVEEVENT
09-22 20:25:36.270  6575  6575 I SDL     : libSDL: stopping accelerometer/gyroscope/orientation
09-22 20:25:36.288  6575  6700 I SDL     : libSDL: DemoRenderer.onSurfaceDestroyed(): paused true mFirstTimeStart false
09-22 20:25:36.288  6575  6700 I libSDL  : OpenGL context lost, waiting for new OpenGL context
09-22 20:25:36.288  6575  6700 V SDL     : GLSurfaceView_SDL::EglHelper::finish(): destroying GL context
09-22 20:25:36.303  6575  6575 V SDL     : DemoGLSurfaceView::onPointerCaptureChange(): false
09-22 20:25:36.303  6575  6575 I SDL     : libSDL: onWindowFocusChanged: false - sending onPause/onResume
09-22 20:25:36.303  6575  6575 I SDL     : libSDL: DemoGLSurfaceView.onPause(): mRenderer.mGlSurfaceCreated false mRenderer.mPaused true - not doing anything
09-22 20:25:37.784 16518 16761 E libc    : Access denied finding property "tas.smartpa.debug.disable"
```

fonts do not manage to load, because the working directory does not start at the correct location on SDL 2. 
It actually starts at ```/```. 
On SDL 1.2, the chdir is actually set on sdl_main, which is not reached on SDL 2.
The function we want to launch is 
```
project/jni/sdl_main/sdl_main.c
extern C_LINKAGE void
JAVA_EXPORT_NAME(DemoRenderer_nativeInit) ( JNIEnv*  env, jobject thiz, jstring jcurdir, jstring cmdline, jint multiThreadedVideo, jint unused )
```

Checking objdump of libsdl_main, we actually see Java_com_simutrans_DemoRenderer_nativeInit alongside Java_org_libsdl_app_SDLActivity_nativeInit
```
Called from
project/java/Video.java
-> class DemoRenderer extends GLSurfaceView_SDL.Renderer
public void onDrawFrame(GL10 gl)
```
This function is not explicitly called, but it is part of super classes.

class DemoGLSurfaceView extends GLSurfaceView_SDL, which then creates a DemoRenderer, and is attached to DemoGLSurfaceView, setRenderer.
Calling back this DemoGLSurfaceView seems to get in conflict 




On SDL2, the function project/javaSDL2/SDLAcivity.java:nativeRunMain:1659 is the java entry point, to below:
(Native SDL source) SDL_main is called from:
/android-sdl/project/jni/SDL2/src/core/android/SDL_android.c 
JNIEXPORT int JNICALL SDL_JAVA_INTERFACE(nativeRunMain)(JNIEnv *env, jclass cls, jstring library, jstring function, jobject array)


Custom SDL_main source on SDL 1.2:
/android-sdl/project/jni/sdl_main/sdl_main.c
extern C_LINKAGE void JAVA_EXPORT_NAME(DemoRenderer_nativeInit) ( JNIEnv*  env, jobject thiz, jstring jcurdir, jstring cmdline, jint multiThreadedVideo, jint unused )


The problem is the above functions are necessarily called from Java. The former is called with SDLActivity.nativeRunMain, and its implementation is accessible. 
The getMainFunction can not change.

If we define a public native function on MainActivity.java, its definition must live in the SDL.


Question is whether we can shortcut project/jni/SDL2/src/core/android/SDL_android.c: nativeRunMain call to SDL_main. Supposedly, it is calling 

The later lives on sdl_main lib, and it is not loaded early enough to be callable.


SDL does provide plenty of nice functions at project/jni/SDL2/include/SDL_system.h
