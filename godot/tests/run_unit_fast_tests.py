#!/usr/bin/env python3
import getpass
import os
import pathlib
import subprocess
import sys

if getpass.getuser() == "wolfrage":
    app_path = pathlib.Path("~/Apps/Godot/Godot_v3.2.2-beta3_x11.64").expanduser()
else:
    app_path = pathlib.Path("~/godot_editor/Godot_v3.2.1-stable_linux_headless.64").expanduser()
cwd = pathlib.Path.cwd()
proj_path = cwd.joinpath("..")
returncode = subprocess.call([app_path, "-s", "--path", proj_path, "tests/gut_runner_custom.gd", "type=unit", "speed=fast"])
if returncode == 0:
    print("Returning 0 exit code from Python. Success!")
    sys.exit(0)
else:
    print("Returning 1 exit code from Python. Failure!")
    sys.exit(1)