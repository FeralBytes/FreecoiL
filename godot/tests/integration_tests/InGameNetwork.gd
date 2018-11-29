extends "res://tests/TheIntegrationTester.gd"

var resource1

func setup():
    .setup()

func teardown():
    .teardown()

func tests(): 
    test_1_test()
    .tests()

func test_1_test():
    testcase("InGameNetwork: Null test.")
    assert_equal(true, true, 
        "null test")
    endcase()