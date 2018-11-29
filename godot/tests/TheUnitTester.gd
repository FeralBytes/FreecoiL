# Adapted from michealb for my purposes.

# NOTES: 

var ut_success = false
var ut_failures = 0
var ut_successes = 0
var ut_tests = 0
var ut_current_case = ""

func assert_true(a, message):
    if not a:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, 
            "' is false.") 
        print("    Assertion failed: ", message)
    else:
        ut_success = true

func assert_false(a, message):
    if a:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, 
            "' is true.")
        print("    Assertion failed: ", message)
    else:
        ut_success = true

func assert_greater_than(a, b, message):
    if not a > b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' is not > than '", b, 
            "'.")
        print("    Assertion failed: ", message)
    else:
        ut_success = true

func assert_less_than(a, b, message):
    if not a < b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' is not < than '", b, 
            "'.")
        print("    Assertion failed: ", message)
    else:
        ut_success = true

func assert_equal(a, b, message):
    if not a == b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' != '", b, 
            "'.")
        print("    Assertion failed: ", message)
    else:
        ut_success = true

func assert_not_equale(a, b, message):
    if not a != b:
        ut_success = false
        print("    [FAILED] ", ut_current_case, " '", a, "' == '", b, 
            "'.")
        print("    Assertion failed: ", message)
    else:
        ut_success = true

func assert_array_equal(a, b, message):
    if not a.size() == b.size():
        ut_success = false
        print("    [FAILED] ", ut_current_case, " array '", a, 
            "' has a different size than array '", b, "'.")
        print("    Assertion failed: ", message)
        return
    else:
        ut_success = true
    for i in range(a.size()):
        if not a[i] == b[i]:
            ut_success = false
            print("    [FAILED] ", ut_current_case, " array '", a, 
                "' has a different values than array '", b, "'.")
            print("    Assertion failed: ", message)
            return 
        else:
            ut_success = true

func assert_dict_equal(a, b, message):
    if not a.size() == b.size():
        ut_success = false
        print("    [FAILED] ", ut_current_case, " dict '", a, 
            "' has a different size than dict '", b, "'.")
        print("    Assertion failed: ", message)
        return 
    else:
        ut_success = true
    for key in a:
        if not b.has(key):
            ut_success = false
            print("    [FAILED] ", ut_current_case, " dict '", a, "' has a key ", 
                key, " that is not present in dict '", b, "'.")
            print("    Assertion failed: ", message)
            return 
        else:
            ut_success = true
        if not a[key] == b[key]:
            ut_success = false
            print("    [FAILED] ", ut_current_case, " dict '", a, 
                "' has a different values than dict '", b, "'.")
            print("    Assertion failed: ", message)
            return 
        else:
            ut_success = true
    for key in b:
        if not a.has(key):
            ut_success = false
            print("    [FAILED] ", ut_current_case, " second dict '", b, 
                "' has a key ", key, " that is not present in dict '", a, 
                "'.")
            print("    Assertion failed: ", message)
            return 
        else:
            ut_success = true

func testcase(name):
    # false because unit tests should assume failure until proven otherwise.
    ut_success = false 
    ut_tests += 1
    ut_current_case = name

func endcase():
    if not ut_success:
        #print("  --[FAILED] " + ut_current_case)
        ut_failures += 1
        return
    else:
        print("  --[PASSED] " + ut_current_case)
        ut_successes += 1
    ut_success = false

func setup():
    pass

func teardown():
    pass

func tests():
    pass

func run_test(path):
    var munged_path = path.replace("res://", "")
    print("-[TESTING MODULE] ", munged_path)
    setup()
    tests()
    teardown()
    if ut_failures == 0:
        print ("-[MODULE PASSED] ", munged_path, " - Passing Tests = ",
            ut_successes, "/", ut_tests)
        return [true, ut_tests, ut_successes]
    else:
        print ("-[MODULE FAILED] ", munged_path, " - Passing Tests = ",
            ut_successes, "/", ut_tests)
        return [false, ut_tests, ut_successes]

static func run(paths):
    var all_success = true
    var count_modules = 0
    var count_all_tests = 0
    var module_successes = 0
    var all_test_successes = 0
    var module_failures = 0
    var all_test_failures = 0
    for path in paths:
        count_modules += 1
        if path.match('res://*.gd'):
            pass # path is already good
        else:
            # Assume is a "." style
            path = "res://" + path.replace(".", "/") + ".gd"
        # Run module
        var results = load(path).new().run_test(path)
        print()
        if results[0]:
            module_successes += 1
            all_test_successes += results[2]
            count_all_tests += results[1]
        else:
            module_failures += 1
            all_test_successes += results[2]
            count_all_tests += results[1]
            all_test_failures += results[1] - results[2]
    if all_test_failures == 0:
        print("[ALL MODULES & TESTS PASSED - TOTAL TEST SUCCESSES] ", all_test_successes, "/", count_all_tests)
        OS.set_exit_code(0)  # OK Exit
    else:
        print("[SOME MODULES & TESTS FAILED - TOTAL FAILURES] ", all_test_failures, "/", count_all_tests)
        # 70 Internal Software Error being used as TEST FAILURE
        OS.set_exit_code(70)
    print()
