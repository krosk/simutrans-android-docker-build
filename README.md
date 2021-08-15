# Simutrans + libsdl android build

Repository for rebuilding simutrans on android. 2021.


# Requirements

* Building: host machine docker installation
* Installation: host machine ADB platforms-tools; for windows, latest version at date is https://dl.google.com/android/repository/platform-tools_r31.0.3-windows.zip


# Build environment

On host console:
 1. ```docker build . -t <image_tag>```


# Host machine configuration for installing apk after building on a (physical) target android device

On host console:
 1. Make sure target android device has USB debugging enabled
 2. Identify target android device IP on wifi network
 3. ```adb tcpip 5555```


# Build image (example for libsdl demo application, ballfield, for validation)

On host console:
 1. ```docker run --rm -it <image_tag> bash```

On container console, only if host machine configured to connect to device:
 2. ```adb connect <target_device_ip>```
 3. Allow USB debugging on target android device from the new computer; it may report failed to authenticate on container console, but as soon as the prompt is accepted on target android device, the connection will be established
 4. ```./build.sh -i ballfield```

On container console, else:
 5. ```./build.sh ballfield```



# Notes on Dockerfile instructions

* gradlew downloads latest versions of android sdk, seems to install them, but they are not reported on the SDK manager. It could be that we don't need to have an install of android sdk beforehand?
* gradle can be kind of initialized by calling it from ./project folder
* the command line option sdkmanager --licenses is deprecated in later versions of sdkmanager, hence the way to accept licenses must be through copying licenses files as mentioned https://developer.android.com/studio/intro/update#download-with-gradle
* starting April 2020, sdk tools package is deprecated, and replaced by commandlinetools package; see # https://developer.android.com/studio/command-line/#tools-sdk and https://developer.android.com/studio#command-tools; version numbering is different; the past packages are captured from https://mirrors.cloud.tencent.com/AndroidSDK/
* the compiler armv7a-linux-androideabi16-clang++, used by simutrans, is only found on ndk (side-by-side) 19.2.5345600; it could be there is such expectation
* as of 15/08/21, the commit https://github.com/aburch/simutrans/commit/446284d85e8df07fffc73bfb200a23086d562388#diff-df72854a6bd7c93a0632db453e323a8cab4212fe5664607191b16252c62f905a introduces problems in compilation due to fluidsynth. This is SVN revision 9775.
* as of 15/08/21, --no-rosegment is requested during linking. However, NDK r19 does not provide this argument (see https://github.com/android/ndk/issues/1426 + ld --version).

