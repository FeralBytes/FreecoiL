extends Node

var the_tester
var count_modules = 0
var count_all_tests = 0
var module_successes = 0
var all_test_successes = 0
var module_failures = 0
var all_test_failures = 0
var current_module_path
var is_runner = true
var exit_timer = Timer.new()
var module_paths = [
    # These are all currently bad integration tests, but would be good for 
    # the Multiplayer Integration tests, since networking is setup there.
    #"res://tests/integration_tests/ExampleTestIntegrationModule.gd",
    "res://tests/integration_tests/InGameNetwork.gd",
    #"res://tests/integration_tests/NetworkTeamLobby.gd",
]

func _ready():
    # Just in case we crash set the status code in advance to a failure code.
    OS.set_exit_code(70)
    exit_timer.wait_time = 180
    add_child(exit_timer)
    exit_timer.connect("timeout", self, "exit_out_of_time")
    exit_timer.start()
    call_deferred("run_tests")

func exit_out_of_time():
    print("Exiting because the test has exceeded the maximum allotted time.")
    get_tree().quit()

func run_tests():
    # Run Integration Tests
    # export FreecoiL_TEST=true
    # ~/Apps/Godot/Godot_v3.1-alpha2_linux_headless.64 --path ~/0.Projects/FreecoiL/src/godot/
    print()
    print("[STARTING ALL INTEGRATION TESTS]")
    for path in module_paths:
        current_module_path = path
        print("--[TESTING MODULE] ", current_module_path.replace("res://", ""))
        the_tester = load("res://tests/TheIntegrationTester.gd").new()
        add_child(the_tester)
        yield(get_tree(), "idle_frame")
        while the_tester.instance_finished == false:
            yield(get_tree(), "idle_frame")
        gather_the_results()
        the_tester.queue_free()
        yield(get_tree(), "idle_frame")
    end_and_print_results()
    
func gather_the_results():
    var munged_path = current_module_path.replace("res://", "")
    if the_tester.ut_successes == the_tester.ut_tests:
        module_successes += 1
        all_test_successes += the_tester.ut_successes
        count_all_tests += the_tester.ut_tests
        print ("--[MODULE PASSED] ", munged_path, " - Passing Tests = ",
            the_tester.ut_successes, "/", the_tester.ut_tests)
    else:
        module_failures += 1
        all_test_successes += the_tester.ut_successes
        count_all_tests += the_tester.ut_tests
        all_test_failures += the_tester.ut_tests - the_tester.ut_successes
        print ("--[MODULE FAILED] ", munged_path, " - Passing Tests = ",
            the_tester.ut_successes, "/", the_tester.ut_tests)

func end_and_print_results():
    if all_test_failures == 0:
        print("[ALL INTEGRATION MODULES & TESTS PASSED - TOTAL TEST SUCCESSES] ", all_test_successes, "/", count_all_tests)
        OS.set_exit_code(0)  # OK Exit
    else:
        print("[SOME INTEGRATION MODULES & TESTS FAILED - TOTAL TEST FAILURES] ", all_test_failures, "/", count_all_tests)
        # 70 Internal Software Error being used as TEST FAILURE
        OS.set_exit_code(70)
    print()
    get_tree().quit()

