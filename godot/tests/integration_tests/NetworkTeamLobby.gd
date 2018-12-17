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
        yield(get_tree(), "idle_frame")
    resource1 = SceneManager.current_scene
    .setup()

func teardown():
    .teardown()

func tests():
    for test in tests:
        test_is_running = true  # set here or the while will = false.
        call_deferred(test)
        while test_is_running:
            yield(get_tree(), "idle_frame")
    .tests()

func test_1_test():
    testcase("NetworkTeamLobby: TeamWidget value change sets SetConf.Session.player_team.")
    resource1.TeamWidget.set_val(1)
    yield(get_tree(), "idle_frame")  # yield to allow value to propogate to SetConf.
    assert_equal(resource1.TeamWidget.current_val, SetConf.Session.player_team, 
        "TeamWidget.current_val did not set and equal SetConf.Session.player_team")
    resource1.TeamWidget.set_val(0)
    endcase()

func test_2_test():
    testcase("NetworkTeamLobby: TeamWidget value change sets NetworkingCode.my_data.")
    resource1.TeamWidget.set_val(2)
    yield(get_tree().create_timer(0.04), "timeout")  # yield to allow value to propogate to SetConf.
    SetConf.Session.player_name = "Computer"
    var correct_dict = {"my_peer_id":null, "player_id":0, "player_name":"Computer", "player_number":0, "player_team":2, "server_unique_id":null}
    assert_dict_equal(correct_dict, NetworkingCode._on_my_data_changed(), 
        "TeamWidget.current_val did not set and equal NetworkingCode.my_data")
    endcase()
