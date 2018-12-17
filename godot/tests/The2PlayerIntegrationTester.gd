extends Node

# NOTES: Integration testing is harder. We have to play nice with Godot typical game loop 
# and we have to consider the loading of scenes and how yielding can cause portions of the
# test to get executed out of order. For instance if a function yields during it's execution
# it then allows any calling functions to continue on. So signals are the solution. 

signal setup_finished
signal tests_finished
signal teardown_finished

var ut_success = false
var ut_failures = 0
var ut_successes = 0
var ut_tests = 0
var ut_current_case = ""
var current_module_path
var connections_setup = false
var module
var module_finished = false
var instance_finished = false
var is_runner = false
var test_is_running = false
# Networking Vars
var num_clients_ready = 0
var test_log = ""

func assert_true(a, message):
    if not a:
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " '" + str(a) + 
            "' is false. Assertion failed: " + message)
    else:
        ut_success = true

func assert_false(a, message):
    if a:
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " '" + str(a) + 
            "' is true. Assertion failed: " + message)
    else:
        ut_success = true

func assert_greater_than(a, b, message):
    if not a > b:
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " '" + str(a) + "' is not > than '" + str(b) + 
            "'. Assertion failed: " + message)
    else:
        ut_success = true

func assert_less_than(a, b, message):
    if not a < b:
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " '" + str(a) + "' is not < than '" + str(b) + 
            "'. Assertion failed: " + message)
    else:
        ut_success = true

func assert_equal(a, b, message):
    if not a == b:
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " '" + str(a) + "' != '" + str(b) + 
            "'. Assertion failed: " + message)
    else:
        ut_success = true

func assert_not_equale(a, b, message):
    if not a != b:
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " '" + str(a) + "' == '" + str(b) + 
            "'. Assertion failed: " + message)
    else:
        ut_success = true

func assert_array_equal(a, b, message):
    if not a.size() == b.size():
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " array '" + str(a) + 
            "' has a different size than array '" + str(b) + "'. Assertion failed: " +
            message)
        return
    else:
        ut_success = true
    for i in range(a.size()):
        if not a[i] == b[i]:
            ut_success = false
            log_tests("    [FAILED] " + ut_current_case + " array '" + str(a) + 
                "' has a different values than array '" + str(b) + 
                "'. Assertion failed: " + message)
            return 
        else:
            ut_success = true

func assert_dict_contains_key(dict_a, value_b, message):
    ut_success = false
    for key in dict_a:
        if key == value_b:
            ut_success = true
    if ut_success == false:
        log_tests("    [FAILED] " + ut_current_case + " dict '" + str(dict_a) + 
            "' does not contain '" + str(value_b) + "' at 1 level deep. Assertion failed: " + 
            message)

func assert_dict_equal(a, b, message):
    if not a.size() == b.size():
        ut_success = false
        log_tests("    [FAILED] " + ut_current_case + " dict '" + str(a) + 
            "' has a different size than dict '" + str(b) + "'. Assertion failed: " + 
            message)
        return 
    else:
        ut_success = true
    for key in a:
        if not b.has(key):
            ut_success = false
            log_tests("    [FAILED] " + ut_current_case + " dict '" + str(a) + "' has a key " + 
                str(key) + " that is not present in dict '" + str(b) + 
                "'. Assertion failed: " + message)
            return 
        else:
            ut_success = true
        # WARNING: This comparison will fail on nested dicts. Because when godot compares 2 dicts for 
        # equality it does it by checking if their location in memory is identical. Which is rarely
        # the case when conducting testing.
        if not a[key] == b[key]:
            ut_success = false
            log_tests("    [FAILED] " + ut_current_case + " dict '" + str(a) + 
                "' has a different values than dict '" + str(b) + 
                "'. Assertion failed: " + message)
            return 
        else:
            ut_success = true
    for key in b:
        if not a.has(key):
            ut_success = false
            log_tests("    [FAILED] " + ut_current_case + " second dict '" + str(b) + 
                "' has a key " + str(key) + " that is not present in dict '" + str(a) + 
                "'. Assertion failed: " + message)
            return 
        else:
            ut_success = true


func log_tests(message):
    test_log += message + "\n"
    print(message)

func testcase(name):
    # false because unit tests should assume failure until proven otherwise.
    test_is_running = true
    ut_success = false 
    ut_tests += 1
    ut_current_case = name

func endcase():
    if not ut_success:
        log_tests("  --[FAILED] " + ut_current_case)
        ut_failures += 1
    else:
        log_tests("  --[PASSED] " + ut_current_case)
        ut_successes += 1
    ut_success = false
    test_is_running = false

func setup():
    emit_signal("setup_finished")

func teardown():
    emit_signal("teardown_finished")

func tests():
    emit_signal("tests_finished")

func gather_test_results():
    module_finished =true


func run_module_tests(path):
    current_module_path = path
    connect("setup_finished", self, "tests", [], 1)
    connect("tests_finished", self, "teardown", [], 1)
    connect("teardown_finished", self, "gather_test_results", [], 1)
    setup()

func _ready():
    if get_parent().is_runner:
        current_module_path = get_parent().current_module_path
        module = load(current_module_path).new()
        yield(get_tree(), "idle_frame")
        add_child(module)
        yield(get_tree(), "idle_frame")
        if get_parent().is_server:
            while num_clients_ready != NetworkingCode.players_data.size() - 1:
                yield(get_tree(), "idle_frame")
            num_clients_ready = 0
            call_deferred("instance_run_module_tests")
        else:
            rpc_id(1, "report_client_ready")


func instance_run_module_tests():
    module.run_module_tests(current_module_path)
    while module.module_finished == false:
        yield(get_tree(), "idle_frame")
    while num_clients_ready != NetworkingCode.players_data.size() - 1:
        yield(get_tree(), "idle_frame")
    num_clients_ready = 0
    ut_failures = module.ut_failures
    ut_successes = module.ut_successes
    ut_tests = module.ut_tests
    test_log += module.test_log
    module.queue_free()
    instance_finished = true

# Networking funcs
remote func report_client_ready():
    # At the Module and Class level
    num_clients_ready += 1

remote func client_unload_module():
    # at the Class level
    yield(get_tree(), "idle_frame")
    module.queue_free()
    instance_finished = true

remote func client_run_specific_tests(these_tests):
    # This is at the module level
    get_parent().client_instance_run_specific_tests(these_tests)

func client_instance_run_specific_tests(these_tests):
    # at the class/instance level
    call_deferred("deferred_client_instance_run_specific_tests", these_tests)

func deferred_client_instance_run_specific_tests(these_tests):
    # at the class level
    module.the_tests = these_tests
    module.run_module_tests(current_module_path)
    while module.module_finished == false:
        yield(get_tree(), "idle_frame")
    ut_failures = module.ut_failures
    ut_successes = module.ut_successes
    ut_tests = module.ut_tests
    test_log += module.test_log
    rpc_id(1, "server_rx_test_results", ut_failures, ut_successes, ut_tests, test_log)
    yield(get_tree(), "idle_frame")
    rpc_id(1, "report_client_ready")
    
remote func server_rx_test_results(failures, successes, num_of_tests, client_logs):
    # at the class level.
    module.ut_failures += failures
    module.ut_successes += successes
    module.ut_tests += num_of_tests
    module.test_log += client_logs
    rpc_id(get_tree().get_rpc_sender_id(), "client_unload_module")

func client_print(message):
    log_tests("\n      Client Prints: " + message+ "\n")
