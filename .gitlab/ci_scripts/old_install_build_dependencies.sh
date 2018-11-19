apt-get -qq update --yes
# For Godot and Android Build Support
apt-get -qq install --yes build-essential cmake lib32stdc++6 lib32z1 libasound2-dev libcairo2 libfreetype6-dev libgl1-mesa-dev libglu-dev libpulse-dev libssl-dev libudev-dev libx11-dev libxcursor-dev libxi-dev libxinerama-dev libxrandr-dev pkg-config scons tar unzip wget yasm zip
if [ -f android-sdk.zip ];
  then
    echo "Dependecies Installed Already."
  else
    wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-$ANDROID_SDK_TOOLS.zip
    unzip -q -d android-sdk-linux android-sdk.zip
    echo y | android-sdk-linux/tools/bin/sdkmanager "platforms;android-$ANDROID_COMPILE_SDK" >/dev/null
    echo y | android-sdk-linux/tools/bin/sdkmanager "platform-tools" >/dev/null
    echo y | android-sdk-linux/tools/bin/sdkmanager "build-tools;$ANDROID_BUILD_TOOLS" >/dev/null
    wget --quiet --output-document=android-ndk.zip https://dl.google.com/android/repository/android-ndk-$ANDROID_NDK_TOOLS-linux-x86_64.zip
    unzip -q -d android-ndk-linux android-ndk.zip
    yes | android-sdk-linux/tools/bin/sdkmanager --licenses
    cd $DOCKER_HOME/godot_engine
    git clone --depth=1 https://github.com/godotengine/godot.git
    cd $DOCKER_HOME
    mkdir -p godot_engine/godot/modules/FreecoiL/android/src/
fi
