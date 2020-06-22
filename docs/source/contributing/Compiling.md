# Compiling The Game

Compiling the game is broken down into subsections to better help understand how you compile the game.

## Setting Up The Enviroment

### Linux Mint, Ubuntu or Debian

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
- Get the [Godot Game Engine Binary](https://downloads.tuxfamily.org/godotengine/3.2.2/beta4/)
- Download FreecoiL's Source Code, it now includes pre-compiled AAR files that are ready to be compiled by Godot.
- Set the Godot editor preferences to the correct locations for your Android SDK, and the jarsigner.
- In Godot with FreecoiL open choose "Project" > "Export", download the export templates for Godot.
- Then Export for Android as an APK to your choosen directory.
- Congratulations you compiled FreecoiL.

### Windows
```eval_rst
.. todo:: I am not a windows user, so someone will have to follow the Godot engine docs to figure out how to do the same thing. Then please contribute back the correct documentation to build a bridge for those that follow.
```
