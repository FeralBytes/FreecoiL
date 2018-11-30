#!/bin/bash
mkdir -p tmp
export SOURCE_DIR=$PWD
cd tmp
pwd
export DOCKER_HOME=$PWD
# Locale must be set or else it will cause additional errors for Godot most PCs have this set though.
#apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales
#sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
#dpkg-reconfigure --frontend=noninteractive locales
#update-locale LANG=en_US.UTF-8
#export LANG=en_US.UTF-8
mkdir -p ~/.config/godot/projects
mkdir -p ~/.godot
mkdir -p ~/.local/share/godot
mkdir -p ~/.config/godot
mkdir -p ~/.cache
# If someone has a glitch because of this line being commented out, please let the maintainer know.
#cp $DOCKER_HOME/.gitlab/ci_scripts/editor_settings-3.tres ~/.config/godot/editor_settings-3.tres
#stages:
#  automated_tests

#unit_tests:
#  stage: automated_tests
# Download Server version of Godot
wget --quiet --output-document=godot_3.1_server.zip https://downloads.tuxfamily.org/godotengine/3.1/alpha2/Godot_v3.1-alpha2_linux_server.64.zip
unzip -q -d godot_editor godot_3.1_server.zip
chmod +x $DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_server.64
$DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_server.64 -s $SOURCE_DIR/godot/tests/RunUnitTests.gd --path $SOURCE_DIR/godot/
if [ $? -ne 0 ]; then
    exit $?
else
    echo "The Unit Test was Successful, are you ready to continue to the next test?"
    OPTIONS="Yes No"
    select opt in $OPTIONS; do
    if [ "$opt" = "Yes" ]; then
        echo "Continuing."
    elif [ "$opt" = "No" ]; then
        echo "Ending Test Now."
        exit
    else
        clear
        echo "The Unit Test was Successful, are you ready to continue to the next test?"
        echo "Your input was invalid. The options are below:"
        echo "1) Yes"
        echo "2) No"
    fi
    done
fi
sleep 2
#integration_tests:
#  stage: automated_tests
# Download Headless version of Godot
wget --quiet --output-document=godot_3.1_linux_headless.zip https://downloads.tuxfamily.org/godotengine/3.1/alpha2/Godot_v3.1-alpha2_linux_headless.64.zip
unzip -q -d godot_editor godot_3.1_linux_headless.zip
chmod +x $DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_headless.64
export FreecoiL_TEST=true
$DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_headless.64 --path $SOURCE_DIR/godot/
unset FreecoiL_TEST
sleep 2

#2player_integration_tests:
#  stage: automated_tests
export FreecoiL_2PLAYER_TEST=true
$DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_headless.64 --path $SOURCE_DIR/godot/ &
    # We start the server last. The clients will wait. Server will print all details to stdout.
    # Since Godot's networking is Server Centric this makes the most sense.
export FreecoiL_SERVER=true
$DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_headless.64 --path $SOURCE_DIR/godot/ 
unset FreecoiL_SERVER
unset FreecoiL_2PLAYER_TEST
sleep 2

#multiplayer_integration_tests:
#  stage: automated_tests
export FreecoiL_MULTIPLAYER_TEST=true
$DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_headless.64 --path $SOURCE_DIR/godot/ &
# We start the server last. The clients will wait. Server will print all details to stdout.
# Since Godot's networking is Server Centric this makes the most sense.
export FreecoiL_SERVER=true
$DOCKER_HOME/godot_editor/Godot_v3.1-alpha2_linux_headless.64 --path $SOURCE_DIR/godot/ 
unset FreecoiL_MULTIPLAYER_TEST
unset FreecoiL_SERVER
sleep 2
cd $DOCKER_HOME
cd ..
killall Godot_v3.1-alpha2_linux_headless.64
killall Godot_v3.1-alpha2_linux_server.64
rm -rf $DOCKER_HOME
unset DOCKER_HOME
unset SOURCE_DIR
