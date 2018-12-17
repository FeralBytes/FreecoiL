apt-get -qq update --yes
# For Godot and Android Build Support
apt-get -qq install --yes pkg-config unzip wget
if [ -f android-sdk.zip ];
  then
    echo "Dependecies Installed Already."
  else
    echo "All set."
fi
