extends "res://tests/The2PlayerIntegrationTester.gd"

var the_tests = [
        "test_1_test",
        "test_2_test",
        "test_3_test",
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
    for test in the_tests:
        test_is_running = true  # set here or the while will = false.
        call_deferred(test)
        while test_is_running:
            yield(get_tree(), "idle_frame")
    .tests()

func test_1_test():
    testcase("#1 NetworkTeamLobby-Server: TeamWidget value change sets SetConf.Session.player_team.")
    resource1.TeamWidget.set_val(1)
    yield(get_tree(), "idle_frame")  # yield to allow value to propogate to SetConf.
    assert_equal(resource1.TeamWidget.current_val, SetConf.Session.player_team, 
        "TeamWidget.current_val did not set and equal SetConf.Session.player_team.")
    resource1.TeamWidget.set_val(0)
    endcase()

func test_2_test():
    testcase("#2 NetworkTeamLobby-Server: TeamWidget value change sets NetworkingCode.my_data.")
    resource1.TeamWidget.set_val(2)
    SetConf.Session.player_name = "Server"
    yield(get_tree().create_timer(0.04), "timeout")  # yield to allow value to propogate to SetConf.
    var correct_dict = {"my_peer_id":1, "player_id":32, "player_name":"Server", "player_number":1, "player_team":2, "server_unique_id":800}
    assert_dict_equal(correct_dict, NetworkingCode._on_my_data_changed(), 
        "TeamWidget.current_val did not set NetworkingCode.my_data to the correct dictionary values.")
    endcase()

func test_3_test():
    testcase("#3 NetworkTeamLobby-RunOnClient: Start the client tests.")
    var these_tests = [
        "test_4_test",
        "test_5_test",
        "test_6_test"
    ]
    rpc("client_run_specific_tests", these_tests)
    assert_true(true, "It's true!")
    endcase()

func test_4_test():
    testcase("#4 NetworkTeamLobby-Client: TeamWidget value change sets NetworkingCode.my_data.")
    resource1.TeamWidget.set_val(2)
    SetConf.Session.player_name = "Computer"
    yield(get_tree().create_timer(0.1), "timeout")  # yield to allow value to propogate to SetConf.
    # Because the server has already taken the first player_number on team 2.
    assert_equal(SetConf.Session.player_number, 2, "Assertion #1. Client did not get it's player_number assigned by the server.")
    assert_equal(SetConf.Session.player_id, 33, "Assertion #2.Client did not get it's player_id assigned by the server.")
    # 2 is the team number. Subtract 1 is required.
    var corr_id = (2 - 1) * FreecoiLInterface.MAX_TEAMS + SetConf.Session.player_number
    var correct_dict = {"my_peer_id":NetworkingCode.my_peer_id, "player_id":corr_id, "player_name":"Computer", "player_number":SetConf.Session.player_number, "player_team":2, "server_unique_id":NetworkingCode.my_server_unique_id}
    assert_dict_equal(correct_dict, NetworkingCode._on_my_data_changed(), 
        "Assertion #3. TeamWidget.current_val did not set NetworkingCode.my_data to the correct dictionary values.")
    endcase()

func test_5_test():
    testcase("#5 NetworkingCode-Client: Given the results of test_4_test players_data is set correctly on the client for both the server (800) and the client (801).")
    assert_dict_contains_key(NetworkingCode.players_data, 800, "NetworkingCode.players_data did not contain 800.")
    assert_dict_contains_key(NetworkingCode.players_data, 801, "NetworkingCode.players_data did not contain 801.")
    var correct_dict = {800:{"my_peer_id":1, "player_id":32, "player_name":"Server", "player_number":1, "player_team":2, "server_unique_id":800}, 801:{"my_peer_id":NetworkingCode.my_peer_id, "player_id":33, "player_name":"Computer", "player_number":2, "player_team":2, "server_unique_id":801}}
    assert_dict_equal(correct_dict[800], NetworkingCode.players_data[800], "NetworkingCode.players_data[800] did not equal the correct values.")
    assert_dict_equal(correct_dict[801], NetworkingCode.players_data[801], "NetworkingCode.players_data[801] did not equal the correct values.")
    endcase()

func test_6_test():
    testcase("#6 NetworkingCode-Client: players_data is set back to dict of 0 size, on the MainMenu scene.")
    SceneManager.goto_scene("res://scenes/MainMenu/MainMenu2.tscn")
    while SceneManager.loading_state != "idle":
        yield(get_tree(), "idle_frame")
    resource1 = SceneManager.current_scene
    var correct_dict = {}
    assert_dict_equal(correct_dict, NetworkingCode.players_data, "NetworkingCode.players_data was not reset to 0 size dict like it should be.")
    endcase()