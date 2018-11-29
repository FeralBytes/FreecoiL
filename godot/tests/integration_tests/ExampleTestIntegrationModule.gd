extends "res://tests/TheIntegrationTester.gd"

var tests = [
        "test_1_test",
        "test_2_test",
    ]
var resource1
var test_var

func setup():
    SceneManager.goto_scene("res://scenes/Lobbies/NetworkTeamLobby.tscn")
    while SceneManager.loading_state != "idle":
        # It is importnat to keep yielding, so that SceneManager can 
        # continue to load the new scene.
        yield(get_tree(), "idle_frame")
    resource1 = SceneManager.current_scene
    .setup()  # super

func teardown():
    pass
    # Do not do queue_free on the resource/scene because SceneManager.goto()
    # expects to be able to do this. It would error otherwise.
    #resource1.queue_free()
    .teardown()  # super

func tests(): 
     for test in tests:
        test_is_running = true  # set here or the while will = false.
        call_deferred(test)
        while test_is_running:
            yield(get_tree(), "idle_frame")
     .tests()  # super

func test_1_test():
    testcase("ExampleTestIntegrationModule: True is True test.")
    assert_equal(true, true, 
        "True is True test")
    endcase()

func test_2_test():
    testcase("SetConf: Session emits signal.")
    test_var = false
    SetConf.Session.teams = false
    SetConf.Session.connect("Session_teams_changed", self, "test_2_support")
    SetConf.Session.teams = true
    # It is a good idea to yield here during integration tests, because 
    # many signal type calls are being deferred and thus can take some 
    # time to propogate.
    yield(get_tree(), "idle_frame")
    assert_true(test_var, 
        "SetConf.Session emitted a signal on teams changed.")
    test_var = null
    endcase()

# Notice the use of the word support here to make it clear that it is not a test.
func test_2_support():
    test_var = true
