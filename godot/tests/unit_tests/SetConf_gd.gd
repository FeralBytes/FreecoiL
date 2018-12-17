extends "res://tests/TheUnitTester.gd"

var test_var

func setup():
    pass

func teardown():
    pass

func tests():  
    test_1_test()
    test_2_test()
    test_3_test()

func test_1_test():
    testcase("SetConf: Session sets Saved after being set.")
    SetConf.Session.teams = false
    assert_equal(SetConf.Session.teams, SetConf.Saved.QuickStart.teams, 
        "SetConf.Session.teams did not equal SetConf.Saved.QuickStart.teams")
    endcase()

func test_2_test():
    testcase("SetConf: Session emits signal.")
    test_var = false
    SetConf.Session.teams = false
    SetConf.Session.connect("Session_teams_changed", self, "test_2_support")
    SetConf.Session.teams = true
    assert_true(test_var, 
        "SetConf.Session emitted a signal on teams changed.")
    test_var = null
    endcase()

func test_2_support():
    test_var = true

func test_3_test():
    testcase("SetConf: Null Test Pass.")
    assert_true(true,
        "SetConf Null true == true Test Better Pass.")
    endcase()