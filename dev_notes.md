
# Notes on Dockerfile instructions

* gradlew downloads latest versions of android sdk, seems to install them, but they are not reported on the SDK manager. It could be that we don't need to have an install of android sdk beforehand?
* gradle can be kind of initialized by calling it from ./project folder
* the command line option sdkmanager --licenses is deprecated in later versions of sdkmanager, hence the way to accept licenses must be through copying licenses files as mentioned https://developer.android.com/studio/intro/update#download-with-gradle
* starting April 2020, sdk tools package is deprecated, and replaced by commandlinetools package; see # https://developer.android.com/studio/command-line/#tools-sdk and https://developer.android.com/studio#command-tools; version numbering is different; the past packages are captured from https://mirrors.cloud.tencent.com/AndroidSDK/
* the compiler armv7a-linux-androideabi16-clang++, used by simutrans, is only found on ndk (side-by-side) 19.2.5345600; it could be there is such expectation
* as of 15/08/21, the commit https://github.com/aburch/simutrans/commit/446284d85e8df07fffc73bfb200a23086d562388#diff-df72854a6bd7c93a0632db453e323a8cab4212fe5664607191b16252c62f905a introduces problems in compilation due to fluidsynth. This is SVN revision 9775.
* as of 15/08/21, --no-rosegment is requested during linking. However, NDK r19 does not provide this argument (see https://github.com/android/ndk/issues/1426 + ld --version).
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