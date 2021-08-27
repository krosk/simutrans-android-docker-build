# Simutrans with libsdl-android

This is a repository for setting up a build environment for simutrans on Android. It relies on Docker.


# Requirements

* Building: host machine docker installation; for windows, known to work with Docker Desktop Community v2.1.0.5
* Installation: host machine ADB platforms-tools; for windows, known to work with https://dl.google.com/android/repository/platform-tools_r31.0.3-windows.zip; the folder where the platform-tools is installed will be referred as ```<platform-tools>``` thereafter

# Quickstart

On host machine:
 1. Clone this repository on a folder, referred as ```<root>``` thereafter. The folder tree structure should show ```<simutrans>/.git```.
 2. From ```<root>```, build the docker image ```docker build . -t <image_tag>```. Name ```<image_tag>``` the way you want, it will be used to refer to this build image.
 3. Clone the simutrans repository to another folder, referred as ```<simutrans>``` thereafter. The folder tree structure should show ```<simutrans>/.git```.
 4. From ```<simutrans>```, start the build environment docker container with (windows) ```docker run --rm -it -v %cd%:/android-sdl/project/jni/application/simutrans/simutrans <image-tag> bash```. 
 5. Make sure there is at least a simutrans pak installed in ```<simutrans>```; an example (Linux) is provided below that gat be run from the build environment docker container, but in any doubt, refer to simutrans official documentation
    ```
        wget https://downloads.sourceforge.net/project/simutrans/pak64/122-0/simupak64-122-0.zip
        unzip ./simupak64-122-0.zip -d <simutrans>
    ```

A shell prompt us opened at working directly ```/android-sdl```. From here, there are a few options.

# Quickstart - build only APK

 1. From the build environment docker container shell, run ```./build.sh simutrans```. It will generate an APK at ```/android-sdl/apk-release.apk```.

# Quickstart - build and install APK

On host console:
 1. Make sure target android device has USB debugging enabled
 2. Identify target android device IP on wifi network
 3. From the folder ```<platform-tools>```, run ```adb tcpip 5555```

On build environment docker container:
 1. Run ```adb connect <target-device-ip>```
 2. If done the first time, allow USB debugging on target android device from the new computer; if it may report failed to authenticate on container console, but as soon as the prompt is accepted on target android device, the connection will be established. Subsequent attempts should be automatic.
 3. Run ```./build.sh -i simutrans```. It will generate an APK at ```/android-sdl/apk-release.apk``` and attempt to install it on device.

# Link to source code for both pelya and simutrans repository

 1. From ```<simutrans>```, start the build environment docker container with (windows) ```docker run --rm -it -v <host_path_to_libsdl_repository>:/android-sdl -v %cd%:/android-sdl/project/jni/application/simutrans/simutrans <image-tag> bash```. 
 2. Run ```ln -s $ANDROID_HOME/licenses project/licenses``` once at docker container start
cp project/jni/all/arm64-v8a/libc++_shared.so /opt/android-sdk-linux/ndk/23.0.7599858/sources/cxx-stl/llvm-libc++/libs/arm64-v8a/libc++_shared.so

# Cleaning

Cleaning the APK generation, in particular if there is an error about unaligned resources:
 1. From ```<root>```, run ```cd project; ./gradlew clean; cd ..```

Cleaning the native C/C++ code embedded in the APK:
 2. Remove ```<root>/project/obj```

Cleaning the source build artifacts:
 3. Remove ```<root>/project/jni/application/simutrans/simutrans/build```

Cleaning the two above should ensure full rebuild.

# Logging

Add the following defines
```
#include <android/log.h>
#define  LOG_TAG    "SIMUTRANS"
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
```

Put a log message with
```
LOGD("text %s", message)
```

Capture most sources with errors with (on host)
```
> adb connect <device_ip>
> adb logcat -s com.simutrans libc DEBUG crashdump64 AndroidRuntime
```

Capture library load failing with
```
> adb connect <device_ip>
> adb logcat -s AndroidRuntime
```

Identify missing library with:
```objdump -x project/jni/all/arm64-v8a/*.so | grep <symbol>```