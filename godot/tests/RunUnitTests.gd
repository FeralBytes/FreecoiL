extends SceneTree

var the_tester = load("res://tests/TheUnitTester.gd")

func _init():
    if Engine.has_singleton("SetConf"):
        pass
    else:
        # Run Unit Tests
        # ~/Apps/Godot/Godot_v3.1-alpha2_linux_headless.64 -s ~/0.Projects/FreecoiL/src/godot/tests/RunUnitTests.gd --path ~/0.Projects/FreecoiL/src/godot/
        print()
        print("[STARTING ALL UNIT TESTS]")
        # Just in case we crash set the status code in advance to a failure code.
        OS.set_exit_code(70)
        the_tester.run([
            "res://tests/unit_tests/SetConf_gd.gd",
            "res://tests/unit_tests/NetworkingCode_gd.gd",
        ])
        quit()