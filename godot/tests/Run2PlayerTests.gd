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
var is_server = false
var exit_timer = Timer.new()
var setup_complete = false
var client_ready_to_test = false
var module_paths = [
    "res://tests/2player_tests/NetworkingCode_gd.gd",
]
var full_logs = ""

func _ready():
    # Just in case we crash set the status code in advance to a failure code.
    OS.set_exit_code(70)
    exit_timer.wait_time = 180
    add_child(exit_timer)
    exit_timer.connect("timeout", self, "exit_out_of_time")
    exit_timer.start()
    if OS.get_environment("FreecoiL_SERVER") == "true":
        call_deferred("start_tests_as_server")
    else:
        call_deferred("start_tests_as_a_client")

func exit_out_of_time():
    log_to_full_log("--[TESTS FAILED TIME EXCEEDED] Exiting because the test has exceeded the maximum allotted time.")
    rpc("clients_shutdown", 70)
    yield(get_tree(), "idle_frame")
    if all_test_failures < 1:
        all_test_failures += 1
    end_and_print_results()

func log_to_full_log(message):
    full_logs += message + "\n"
    print(message)

func start_tests_as_server():
    is_server = true
    print("Starting test as a server.")
    print()
    log_to_full_log("[STARTING ALL 2 PLAYER INTEGRATION TESTS]")
    call_deferred("do_server_setup")
    while setup_complete == false:
        yield(get_tree(), "idle_frame")
    while client_ready_to_test == false:
        yield(get_tree(), "idle_frame")
    for path in module_paths:
        current_module_path = path 
        log_to_full_log("--[TESTING MODULE] " + current_module_path.replace("res://", ""))
        the_tester = load("res://tests/The2PlayerIntegrationTester.gd").new()
        add_child(the_tester)
        rpc("load_tester", current_module_path)
        yield(get_tree(), "idle_frame")
        while the_tester.instance_finished == false:
            yield(get_tree(), "idle_frame")
        gather_the_results()
        the_tester.queue_free()
        rpc("unload_the_tester")
        yield(get_tree(), "idle_frame")
    end_and_print_results()

func do_server_setup():
    print("Doing Server Setup.")
    SetConf.Session.server_ip = "127.0.0.1"
    NetworkingCode.setup_as_host()
    yield(get_tree(), "idle_frame")
    setup_complete = true

func start_tests_as_a_client():
    # Run Mutiplayer Integration Test as Client
    # We need to wait for all of the clients to be started and for the 
    # server to get the lobby created.
    yield(get_tree().create_timer(5.0), "timeout")
    call_deferred("do_client_setup")

func do_client_setup():
    SetConf.Session.server_ip = "127.0.0.1"
    get_tree().connect("connected_to_server", self, "send_client_is_ready")
    NetworkingCode.setup_as_client()
    setup_complete = true

func gather_the_results():
    var munged_path = current_module_path.replace("res://", "")
    if the_tester.ut_successes == the_tester.ut_tests:
        module_successes += 1
        all_test_successes += the_tester.ut_successes
        count_all_tests += the_tester.ut_tests
        full_logs += the_tester.test_log
        log_to_full_log("--[MODULE PASSED] " + munged_path + " - Passing Tests = " +
            str(the_tester.ut_successes) + "/" + str(the_tester.ut_tests))
    else:
        module_failures += 1
        all_test_successes += the_tester.ut_successes
        count_all_tests += the_tester.ut_tests
        all_test_failures += the_tester.ut_tests - the_tester.ut_successes
        full_logs += the_tester.test_log
        log_to_full_log("--[MODULE FAILED] " + munged_path + " - Passing Tests = " +
            str(the_tester.ut_successes) + "/" + str(the_tester.ut_tests))

func send_results_to_the_server():
    pass

func end_and_print_results():
    if all_test_failures == 0:
        rpc("clients_shutdown", 0)
        yield(get_tree(), "idle_frame")
        log_to_full_log("[ALL 2 PLAYER INTEGRATION MODULES & TESTS PASSED - TOTAL TEST SUCCESSES] " + str(all_test_successes) + "/" + str(count_all_tests))
        OS.set_exit_code(0)  # OK Exit
    else:
        rpc("clients_shutdown", 70)
        yield(get_tree(), "idle_frame")
        log_to_full_log("[SOME 2 PLAYER INTEGRATION MODULES & TESTS FAILED - TOTAL TEST FAILURES] " + str(all_test_failures) + "/" + str(count_all_tests))
        # 70 Internal Software Error being used as TEST FAILURE
        OS.set_exit_code(70)
    print()
    print("Printing Full Logs Below:")
    print()
    print(full_logs)
    print()
    yield(get_tree(), "idle_frame")
    get_tree().quit()

func send_client_is_ready():
    rpc_id(1, "client_is_ready_to_test")

remote func client_is_ready_to_test():
    client_ready_to_test = true

remote func load_tester(path):
    current_module_path = path
    the_tester = load("res://tests/The2PlayerIntegrationTester.gd").new()
    add_child(the_tester)

remote func unload_the_tester():
    the_tester.queue_free()

remote func clients_shutdown(exit_code):
    OS.set_exit_code(exit_code)
    get_tree().quit()