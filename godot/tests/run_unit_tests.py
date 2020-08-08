#!/usr/bin/env python3
import getpass
import os
import pathlib
import subprocess
import sys

GODOT_VERSION = "3.2.2-beta4"

cwd = pathlib.Path.cwd()

if getpass.getuser() == "wolfrage":
    app_path = pathlib.Path("~/Apps/Godot/Godot_v" + GODOT_VERSION + "_x11.64").expanduser()
    proj_path = cwd.joinpath("..")
else:
    app_path = cwd.joinpath("/usr/local/bin/godot")
    proj_path = cwd.joinpath("godot")

if len(sys.argv) == 2:
    if sys.argv[1] == "fast":
        returncode = subprocess.call([app_path, "-s", "--path", proj_path, "tests/gut_runner_custom.gd", "type=unit", "speed=fast"])
else:
    returncode = subprocess.call([app_path, "-s", "--path", proj_path, "tests/gut_runner_custom.gd", "type=unit"])
if returncode == 0:
    print("Returning 0 exit code from Python. Success!")
    sys.exit(0)
else:
    print("Returning 1 exit code from Python. Failure!")
    sys.exit(1)
