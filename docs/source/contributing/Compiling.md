# Compiling The Game

Compiling the game is broken down into subsections to better help understand how you compile the game.

## Setting Up The Enviroment for Linux Mint, Ubuntu or Debian

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
-Take the file at godot/android/build.gradle and replace godot/android/build/build.gradle. The path is relative to the FreecoiL repository.
- To Fix min SDK issue, replace godot/android/build/config.gradle with the one at godot/android/config.gradle.
- In Godot with FreecoiL open choose "Project" > "Export", download the export templates for Godot.
- Then Export for Android as an APK to your choosen directory.
- Congratulations you compiled FreecoiL.

## Setting up Godot to export for Android on Windows machines

The following steps detail what is needed to set up the SDK and the engine.  

Download the [Android SDK](https://developer.android.com/studio/)

**You need to run it once to complete the SDK setup.**

Install [OpenJDK 8](https://adoptopenjdk.net/index.html?variant=openjdk8&jvmVariant=hotspot)  

**Note: newer versions do not work.**

### Create a debug.keystore

Android needs a debug keystore file to install to devices and distribute non-release APKs. If you have used the SDK before and have built projects, ant or eclipse probably generated one for you (on Windows, you can find it in the users/.android directory).  

If you can't find it or need to generate one, the keytool command from the JDK can be used for this purpose. Open a CMD window and run the following command line.  This will create a debug.keystore file in your current directory. You should move it to a memorable location such as %USERPROFILE%\.android\, because you will need its location in a later step.   
>keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12

### Make sure you have adb
Android Debug Bridge (adb) is the command line tool used to communicate with Android devices. It's installed with the SDK, but you may need to install one (any) of the Android API levels for it to be installed in the SDK directory.  

### Setting Android SDK up in Godot

Enter the Editor Settings screen. This screen contains the editor settings for the user account in the computer (it's independent of the project). Click the "Editor" menu option then choose "Editor Settings".

Scroll down to the section where the Android settings are located. In that screen, the path to 3 files needs to be set:  

- The adb executable (adb.exe on Windows) - It can usually be found at %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe.  

- The jarsigner executable. In Windows, OpenJDK installs to a dir like %PROGRAMFILES%\ojdkbuild\java-1.8.0-openjdk-1.8.0.232-2\bin. The exact path may vary depending on the OpenJDK update you've installed and your machine's operating system.  

- The debug .keystore file - It can be found in the folder where you put the debug.keystore file you created above.
Once that is configured, everything is ready to export to Android!

## Ready to export!
Once you are ready to export to an APK, select Project > Export > Android (Runnable).
Under the options tab to the right, scroll down until you get to the Keystore heading.  Change the location of the Debug field to the location of your Debug.keystore.
Hit Export Project below and select where you’d like to save the APK.  

---

## Possible Errors:
```
C:\FreecoiL-master\godot\android\build\AndroidManifest.xml Error: uses-sdk:minSdkVersion 18 cannot be smaller than version 21 declared in library [FreecoiL.debug.aar]
C:\caches\transforms-2\files-2.1\4b0138dab5b5d121e4c349d1eb16e7bd\FreecoiL.debug\AndroidManifest.xml as the library might be using APIs not available in 18 Suggestion: use a compatible library with a minSdk of at most 18, or increase this project's minSdk version to at least 21, or use tools:overrideLibrary="com.feralbytes.games.freecoilkotlin" to force usage (may lead to runtime failures)


Execution failed for task ':processDebugManifest'.
Manifest merger failed : uses-sdk:minSdkVersion 18 cannot be smaller than version 21 declared in library [FreecoiL.debug.aar] C:\...\caches\transforms-2\files-2.1\4b0138dab5b5d121e4c349d1eb16e7bd\FreecoiL.debug\AndroidManifest.xml as the library might be using APIs not available in 18 


Suggestion: use a compatible library with a minSdk of at most 18, or increase this project's minSdk version to at least 21, or use tools:overrideLibrary="com.feralbytes.games.freecoilkotlin" to force usage (may lead to runtime failures)  
```

## Solutions:
The paths below are relative to the FreecoiL repository.
* Take the file at godot/android/build.gradle and replace godot/android/build/build.gradle. 
* To Fix min SDK issue, replace godot/android/build/config.gradle with the one at godot/android/config.gradle.
