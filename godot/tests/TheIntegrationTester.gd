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
var module_finished = false
var instance_finished = false
var is_runner = false
var test_is_running = false

func assert_true(a, message):
    if not a:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, 
            "' is false. Assertion failed: ", message)
    else:
        ut_success = true

func assert_false(a, message):
    if a:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, 
            "' is true. Assertion failed: ", message)
    else:
        ut_success = true

func assert_greater_than(a, b, message):
    if not a > b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' is not > than '", b, 
            "'. Assertion failed: ", message)
    else:
        ut_success = true

func assert_less_than(a, b, message):
    if not a < b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' is not < than '", b, 
            "'. Assertion failed: ", message)
    else:
        ut_success = true

func assert_equal(a, b, message):
    if not a == b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' != '", b, 
            "'. Assertion failed: ", message)
    else:
        ut_success = true

func assert_not_equale(a, b, message):
    if not a != b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' == '", b, 
            "'. Assertion failed: ", message)
    else:
        ut_success = true

func assert_array_equal(a, b, message):
    if not a.size() == b.size():
        ut_success = false
        print("    [FAILED] ", ut_current_case, " array '", a, 
            "' has a different size than array '", b, "'. Assertion failed: ",
            message)
        return
    else:
        ut_success = true
    for i in range(a.size()):
        if not a[i] == b[i]:
            ut_success = false
            print("    [FAILED] ", ut_current_case, " array '", a, 
                "' has a different values than array '", b, 
                "'. Assertion failed: ", message)
            return 
        else:
            ut_success = true

func assert_dict_equal(a, b, message):
    if not a.size() == b.size():
        ut_success = false
        print("    [FAILED] ", ut_current_case, " dict '", a, 
            "' has a different size than dict '", b, "'. Assertion failed: ", 
            message)
        return 
    else:
        ut_success = true
    for key in a:
        if not b.has(key):
            ut_success = false
            print("    [FAILED] ", ut_current_case, " dict '", a, "' has a key ", 
                key, " that is not present in dict '", b, 
                "'. Assertion failed: ", message)
            return 
        else:
            ut_success = true
        if not a[key] == b[key]:
            ut_success = false
            print("    [FAILED] ", ut_current_case, " dict '", a, 
                "' has a different values than dict '", b, 
                "'. Assertion failed: ", message)
            return 
        else:
            ut_success = true
    for key in b:
        if not a.has(key):
            ut_success = false
            print("    [FAILED] ", ut_current_case, " second dict '", b, 
                "' has a key ", key, " that is not present in dict '", a, 
                "'. Assertion failed: ", message)
            return 
        else:
            ut_success = true

func testcase(name):
    # false because unit tests should assume failure until proven otherwise.
    test_is_running = true
    ut_success = false 
    ut_tests += 1
    ut_current_case = name

func endcase():
    if not ut_success:
        #print("  --[FAILED] " + ut_current_case)
        ut_failures += 1
    else:
        print("  --[PASSED] " + ut_current_case)
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
        var module = load(current_module_path).new()
        yield(get_tree(), "idle_frame")
        add_child(module)
        yield(get_tree(), "idle_frame")
        module.run_module_tests(current_module_path)
        while module.module_finished == false:
            yield(get_tree(), "idle_frame")
        ut_failures = module.ut_failures
        ut_successes = module.ut_successes
        ut_tests = module.ut_tests
        module.queue_free()
        instance_finished = true
    