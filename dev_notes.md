
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


# For SDL 2, although it should not be required for Linux/Android which continue to support SDL1.2 (SDL2 was used only for Steam?)

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

Right now, resolution is predefined in the command line arguments sent by sdl. Not providing the screensize argument, SDL will automatically retrieve the native resolution. However, for some reason, the native resolution is not an accepted video mode by SDL. Anything smaller is though.


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