FROM androidsdk/android-21

WORKDIR /android-sdl

# Retrieve from a specific SHA
# https://stackoverflow.com/questions/3489173/how-to-clone-git-repository-with-specific-revision-changeset

# make a new blank repository in the current directory
RUN git init

# add a remote
RUN git remote add origin https://github.com/pelya/commandergenius.git

# fetch a commit (or branch or tag) of interest
# Note: the full history up to this commit will be retrieved unless 
#       you limit it with '--depth=...' or '--shallow-since=...'
RUN git fetch origin c470f348c4d7afdbdffce4cfebe5265bd798f699

# reset this repository's master branch to the commit of interest
RUN git reset --hard FETCH_HEAD

RUN ln -s simutrans/ project/jni/application/src

RUN sdkmanager --install "ndk;21.4.7075529"

ENV PATH "${PATH}:${ANDROID_HOME}/ndk/21.4.7075529"

RUN apt-get install make

RUN git submodule update --init project/jni/iconv

RUN ln -s $ANDROID_HOME/licenses project

RUN mkdir /root/.android/

RUN keytool -genkey -v -keystore /root/.android/debug.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -keypass android -storepass android -dname "cn=example.com,ou=exampleou,dc=example,dc=com"