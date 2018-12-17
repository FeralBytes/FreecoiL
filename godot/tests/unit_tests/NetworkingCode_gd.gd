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
    testcase("NetworkingCode: assign_player_number() check valid return values for team 1.")
    NetworkingCode.players_data[801] = {player_id = 0, player_number = 0, 
        player_team = 1, player_name = "P", server_unique_id = 801, my_peer_id = 12345678}
    assert_equal(NetworkingCode.assign_player_number(801), [1, 1], 
        "NetworkingCode.assign_player_number() did not equal 1")
    endcase()

func test_2_test():
    testcase("NetworkingCode: assign_player_number() check valid return values for team 2.")
    NetworkingCode.players_data[801] = {player_id = 0, player_number = 0, 
        player_team = 2, player_name = "P", server_unique_id = 801, my_peer_id = 12345678}
    NetworkingCode.players_data[800] = {player_id = 32, player_number = 1, 
        player_team = 2, player_name = "P", server_unique_id = 800, my_peer_id = 1}
    assert_equal(NetworkingCode.assign_player_number(801), [33, 2], 
        "NetworkingCode.assign_player_number() did not equal 1")
    endcase()

func test_3_test():
    testcase("NetworkingCode: assign_player_number() sets the servers player_id and player_number in SetConf.Session and NetworkingCode.players_data.")
    NetworkingCode.players_data[801] = {player_id = 32, player_number = 1, 
        player_team = 2, player_name = "Test1", server_unique_id = 801, my_peer_id = 1234567}
    NetworkingCode.players_data[800] = {player_id = 0, player_number = 0, 
        player_team = 2, player_name = "Test2", server_unique_id = 800, my_peer_id = 1}
    NetworkingCode.assign_player_number(800)
    assert_equal(NetworkingCode.players_data[800]["player_id"], 33, 
        "NetworkingCode.assign_player_number() did not set the servers player_id in NetworkingCode.players_data.")
    assert_equal(33, SetConf.Session.player_id, 
        "NetworkingCode.assign_player_number() did not set the servers player_id in SetConf.Session.")
    assert_equal(NetworkingCode.players_data[800]["player_number"], 2, 
        "NetworkingCode.assign_player_number() did not set the servers player_number in NetworkingCode.players_data.")
    assert_equal(2, SetConf.Session.player_number, 
        "NetworkingCode.assign_player_number() did not set the servers player_number in SetConf.Session.")
    endcase()

func test_4_test():
    testcase("NetworkingCode: ")
    endcase()