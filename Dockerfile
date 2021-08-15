FROM ubuntu:18.04

# Inspired from https://github.com/docker-android-sdk/android-21
ENV DEBIAN_FRONTEND=noninteractive

ENV ANDROID_HOME      /opt/android-sdk-linux
ENV ANDROID_SDK_HOME  ${ANDROID_HOME}
ENV ANDROID_SDK_ROOT  ${ANDROID_HOME}
ENV ANDROID_SDK       ${ANDROID_HOME}

RUN dpkg --add-architecture i386 && \
    apt-get update -yqq && \
    apt-get install -y curl expect git libc6:i386 libgcc1:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 openjdk-8-jdk wget unzip vim && \
    apt-get clean

RUN groupadd android && useradd -d /opt/android-sdk-linux -g android android

WORKDIR /opt/android-sdk-linux


# Install cmdline-tools (sdkmanager), set PATH for sdkmanager

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip && unzip commandlinetools-linux-7583922_latest.zip && rm commandlinetools-linux-7583922_latest.zip
# Fix required due to https://stackoverflow.com/questions/65262340/cmdline-tools-could-not-determine-sdk-root
RUN mv cmdline-tools latest && mkdir cmdline-tools && mv latest cmdline-tools/latest
ENV PATH "${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"


# Copy licenses before installing packages via sdkmanager; provided license file covers SDK and NDK, but some additional may be required

COPY licenses /opt/android-sdk-linux/licenses


# Install ndk, set PATH for ndk-build

RUN yes | sdkmanager --install "ndk;16.1.4479499"
ENV PATH "${PATH}:${ANDROID_HOME}/ndk/16.1.4479499"


# Install build-tools (platform-tools is a dependency), set PATH for adb, zipalign and apksigner, required by build.sh

RUN yes | sdkmanager --install "platform-tools"
ENV PATH "${PATH}:${ANDROID_HOME}/platform-tools"

RUN yes | sdkmanager --install "build-tools;30.0.3"
ENV PATH "${PATH}:${ANDROID_HOME}/build-tools/30.0.3"


# Clone android sdl source from specific commit

WORKDIR /android-sdl
RUN git init && git remote add origin https://github.com/pelya/commandergenius.git && git fetch origin c470f348c4d7afdbdffce4cfebe5265bd798f699 && git reset --hard FETCH_HEAD


# Link to existing licenses; to prepare Gradle for installation of another, version-appropriate SDK (ANDROID_HOME could become /android-sdl/project, but paths are project dependant and defined only after Gradle)

RUN ln -s $ANDROID_HOME/licenses project/licenses


# Add default keystore, required by build.sh

RUN mkdir /root/.android/
RUN keytool -genkey -v -keystore /root/.android/debug.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -keypass android -storepass android -dname "cn=example.com,ou=exampleou,dc=example,dc=com"