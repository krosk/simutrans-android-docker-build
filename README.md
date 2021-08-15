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

* gradlew always tries to update to last version?