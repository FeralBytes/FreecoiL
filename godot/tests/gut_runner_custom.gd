extends SceneTree

var arguments = {}

var Gut = load('res://addons/gut/gut.gd')
var _tester = Gut.new()

func _init():
    OS.exit_code = 1
    for argument in OS.get_cmdline_args():
        # Parse valid command-line arguments into a dictionary
        if argument.find("=") > -1:
            var key_value = argument.split("=")
            arguments[key_value[0].lstrip("--")] = key_value[1]
    get_root().add_child(_tester)
    _tester.set_yield_between_tests(true)
    _tester.set_include_subdirectories(true)
    if arguments.has("type"):
        if arguments["type"] == "unit":
            if arguments.has("speed"):
                if arguments["speed"] == "fast":
                    _tester.add_directory('res://tests/unit/fast', 'test_', '.gd')
                elif arguments["speed"] == "slow":
                    _tester.add_directory('res://tests/unit/slow', 'test_', '.gd')
            else:
                _tester.add_directory('res://tests/unit', 'test_', '.gd')
        elif arguments["type"] == "integration":
            _tester.add_directory('res://tests/integration', 'test_', '.gd')
        elif arguments["type"] == "multiplayer_unit":
            if arguments["match"] == "LAN":
                if arguments["player"] == "1":
                    _tester.add_directory('res://tests/multiplayer/unit', 'test_LAN_1v1_P1', '.gd')
                elif arguments["player"] == "2":
                    _tester.add_directory('res://tests/multiplayer/unit', 'test_LAN_1v1_P2', '.gd')
            else:
                pass
        elif arguments["type"] == "multiplayer_integration":
            if arguments["match"] == "LAN":
                if arguments["player"] == "1":
                    _tester.add_directory('res://tests/multiplayer/integration', 'test_LAN_P1', '.gd')
                elif arguments["player"] == "2":
                    _tester.add_directory('res://tests/multiplayer/integration', 'test_LAN_P2', '.gd')
                elif arguments["player"] == "3":
                    _tester.add_directory('res://tests/multiplayer/integration', 'test_LAN_P3', '.gd')
            else:
                pass
    else:  # Multiplayer Tests are special and must be run with more than one App instance.
        _tester.add_directory('res://tests/unit', 'test_', '.gd')
        _tester.add_directory('res://tests/integration', 'test_', '.gd')
    _tester.connect('tests_finished', self, '_on_tests_finished')
    _tester.show()
    # apply any other options you want to the tester.  Check
    # func apply_options(opts): in gut_cmdln for examples

    _tester.test_scripts()

    
func _on_tests_finished():
    OS.exit_code = 0
    var totals = _tester.get_summary().get_totals()
    # verify some summary data.  summary has:
    #   passing = 0,
    #   pending = 0,
    #   failing = 0,
    #   tests = 0,
    #   scripts = 0
    #   asserts
    if(totals["passing"] + totals["failing"] == 0 or totals["scripts"] ==  0):
        OS.exit_code = 1

    if(totals["failing"] > 0):
        OS.exit_code = 1
        
    if totals["passing"] + totals["failing"] != totals["asserts"]:
        OS.exit_code = 1

    if arguments.has("type"):
        if arguments["type"] == "multiplayer":
            if arguments["player"] == "1":
                print("Server")
            else:
                print("Client")
    print("OS Exit Code = " + str(OS.exit_code))
    quit()
