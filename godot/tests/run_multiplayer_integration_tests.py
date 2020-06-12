#!/usr/bin/env python3
import concurrent.futures
import getpass
import os
import pathlib
import subprocess
import sys

GODOT_VERSION = "3.2.2-beta4"

def player1(app_path, proj_path):
    returncode = subprocess.call([app_path, "--position", "10,10","-s", "--path", proj_path, "tests/gut_runner_custom.gd", "type=multiplayer_integration", "match=LAN", "player=1"])
    return returncode


def player2(app_path, proj_path):
    returncode = subprocess.call([app_path, "--position", "560,10", "-s", "--path", proj_path, "tests/gut_runner_custom.gd", "type=multiplayer_integration", "match=LAN", "player=2"])
    return returncode

def player3(app_path, proj_path):
    returncode = subprocess.call([app_path, "--position", "1120,10", "-s", "--path", proj_path, "tests/gut_runner_custom.gd", "type=multiplayer_integration", "match=LAN", "player=3"])
    return returncode

cwd = pathlib.Path.cwd()
if getpass.getuser() == "wolfrage":
    app_path = pathlib.Path("~/Apps/Godot/Godot_v" + GODOT_VERSION +"_x11.64").expanduser()
    proj_path = cwd.joinpath("..")
else:
    app_path = cwd.joinpath("godot")
    proj_path = cwd.joinpath("godot")

executor = concurrent.futures.ThreadPoolExecutor(max_workers=3)

returncode1 = executor.submit(player1, app_path, proj_path)
returncode2 = executor.submit(player2, app_path, proj_path)
returncode3 = executor.submit(player3, app_path, proj_path)
executor.shutdown(wait=True)
print("#############################################################################")
print("Player 1 App Instance (Server) returned an exit code of ", returncode1.result())
print("Player 2 App Instance (Client) returned an exit code of ", returncode2.result())
print("Player 3 App Instance (Client) returned an exit code of ", returncode3.result())
print("#############################################################################")

if returncode1.result() == 0 and returncode2.result() == 0 and returncode3.result() == 0:
    print("Returning 0 exit code from Python. Success!")
    sys.exit(0)
else:
    print("Returning 1 exit code from Python. Failure!")
    sys.exit(1)

