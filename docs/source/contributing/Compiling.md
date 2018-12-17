# Compiling The Game:
Compiling the game is broken down into subsections to better help understand how you compile the game.
## Setting Up The Enviroment:
### Linux Mint, Ubuntu or Debian:
- Download and install [Android Studio](https://developer.android.com/studio/). Please install all tools and extras of the SDK Manager.
- Set the environment variable $ANDROID_HOME to point to the Android SDK.
```bash
export ANDROID_HOME=$HOME/path/to/android/sdk
```
- Set the environment variable $ANDROID_NDK_ROOT to point to the Android NDK.
```bash
export ANDROID_NDK_ROOT=$HOME/path/to/android/ndk
```
For example my enviroment variable paths look like the below code.
```bash
export ANDROID_HOME=$HOME/Android/Sdk/ && export ANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk-bundle
```
- Get the [Godot Game Engine Source Code](https://github.com/godotengine/godot)
```bash
git clone https://github.com/godotengine/godot.git
```
```eval_rst
.. warning:: The maintainer is has not tested the latest development branch of Godot so it is possible compiling FreecoiL with Godot Latest could fail.
```
```eval_rst
.. note:: The maintainer tested godot latest on 2018-11-15 and the builds failed.
```
```eval_rst
.. todo:: Update what git version and how to git to the correct tested version of Godot.
```
- Install the required dependencies.
```bash
sudo apt-get install build-essential scons pkg-config libx11-dev libxcursor-dev libxinerama-dev \
    libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libfreetype6-dev libssl-dev libudev-dev \
    libxi-dev libxrandr-dev yasm
```
- Change directory into the engine's source code.
```bash
cd godot
```
- From the FreecoiL repository copy the folder "godot_module/FreecoiL" as in specifically the Folder "FreecoiL inside the folder "godot_module"; and paste it into the Godot repository folder "modules".
- From the FreecoiL repository copy the contents of the "android_java/app/src/main/java/com/feralbytes/games/FreecoiL" folder; which is currently 3 files: BluetoothLeService.java, FreecoiL.java, and GattAttributes.java; paste these files into the Godot repository inside the "modules/FreecoiL/android/src" folder next to the "instructions.md" file.
- Ensure that your terminal is still at the Godot repository root which we changed to in step 6. 
- Run the scons command and gradle as instructed below. The "-j#" argument should have a number equal to the number of processor cores in your computer for optimal speed. The first time the engine is compiled will take a long while. Go enjoy a break.
```bash
scons -j4 platform=android target=debug && cd platform/android/java && ./gradlew build && cd - && scons -j4 platform=android target=release && cd platform/android/java && ./gradlew build && cd -
```
- A new folder will have been created in the Godot repository named "bin". In this folder is a file called "godot.x11.tools.64" make this file executable and run it. It is the Godot engine but now with support for FreecoiL. The files "android_debug.apk" and "android_release.apk" are the export apk's that godot will use to make FreecoiL apk's that can run on Android devices again with FreecoiL's android module baked in.
### Windows:
```eval_rst
.. todo:: I am not a windows user, so someone will have to follow the Godot engine docs to figure out how to do the same thing. Then please contribute back the correct documentation to build a bridge for those that follow.
```
