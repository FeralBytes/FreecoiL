extends Node

signal my_data_changed
var my_data = {} setget set_my_data, get_my_data

var my_peer_id
var my_server_unique_id
var possible_server_ips
var Network
var players_data = {}  # Players data, associate ID to data
var players_ready = []
var server_unique_player_id = 800 # increments by 1 on use.
var validate_ip = RegEx.new()
var state_lobby_type_set = false
var state_scenario_data_set = false
var state_scenario_player_options_data_set = false
var state_in_game_loading = false
var state_playing_game = false
# Vars for tracking game history.
var device_unpassed_history = []
var device_passed_history = []
var game_history = []
var server_unsorted_history = []
var server_unpassed_game_history = []
var net_time = Timer.new()
var players_at_end_game = 0
var game_history_act_count = -1

func set_my_data(new_val):
    pass
    
func get_my_data():
    my_data = {player_id = SetConf.Session.player_id, player_number = SetConf.Session.player_number, 
        player_team = SetConf.Session.player_team, player_name = SetConf.Session.player_name,
        server_unique_id = my_server_unique_id, my_peer_id = my_peer_id}
    return my_data
    
func _on_my_data_changed():
    if not get_tree().is_network_server():
        rpc_id(1, "update_server_player_data", get_my_data())
    else:  # We are the server.
        players_data[800] = get_my_data()
        if players_data[800]["player_team"] >= 0:
            if players_data[800]["player_number"] >= -1:
                assign_player_number(800)
        rpc("update_player_data", 800, players_data[800])
        get_tree().call_group("lobby", "lobby_update_team_grid")
    return get_my_data()

remote func change_my_player_id(new_id):
    SetConf.Session.player_id = new_id 

remote func change_my_player_number(new_number):
    SetConf.Session.player_number = new_number

remote func change_my_player_team(new_team):
    SetConf.Session.player_team = new_team

func _ready():
    add_to_group("networking")
    var unused
    unused = get_tree().connect("network_peer_connected", self, "_player_connected")
    unused = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    unused = get_tree().connect("connected_to_server", self, "_connected_ok")
    unused = get_tree().connect("connection_failed", self, "_connection_fail")
    unused = get_tree().connect("server_disconnected", self, "_server_disconnected")
    SetConf.Session.player_id = 0
    SetConf.Session.player_team = 0
    SetConf.Session.player_number = 0
    unused = SetConf.Session.connect("Session_player_team_changed", self, "_on_my_data_changed")
    unused = null
    # Below is IPv4 Address Regex.
    validate_ip.compile("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
    net_time.wait_time = 259200  # 3 Days
    add_child(net_time)
    
# func _process(): is defined down much lower.
        

func get_server_unique_id():
    # Rationale: Although Godot does something like this, it misses our use case.
    # If a player disconnects and then reconnects thier peer_id will be new each time.
    # We want players to be able to drop out. But if they comeback to us with the
    # same server_unique_id, then they are the same player.
    server_unique_player_id += 1
    return server_unique_player_id - 1

remote func set_my_server_unique_id(unique_id):
    my_server_unique_id = unique_id

func setup_as_host(): 
    my_server_unique_id = get_server_unique_id()
    if SetConf.Session.server_ip == "127.0.0.1":
        if not SetConf.Session.testing_active:
            var ip_list = IP.get_local_addresses()
            var matches = []
            for ip in ip_list:
                var a_match = validate_ip.search(ip)
                if a_match != null:
                    matches.append(a_match.get_strings()[0])
            matches.erase("127.0.0.1")
            if matches.size() == 0:
                get_tree().call_group("networking", "nw_no_inet_facing_addresses")
            if matches.size() == 1:
                SetConf.Session.server_ip = matches[0]
                get_tree().call_group("networking", "nw_inet_bound_address")
                call_deferred("finish_host_setup")
            elif matches.size() > 1:
                possible_server_ips = matches
                get_tree().call_group("networking", "nw_too_many_inet_facing_addresses", matches)
        else:
            call_deferred("finish_host_setup")
    else:
        get_tree().call_group("networking", "nw_inet_bound_address")
        call_deferred("finish_host_setup")
        
func finish_host_setup():
    Network = NetworkedMultiplayerENet.new()
    Network.set_bind_ip(SetConf.Session.server_ip)
    # Below Max Players + Dedicated Server
    Network.create_server(SetConf.Session.server_port, LazerInterface.MAX_PLAYERS + 1)
    get_tree().set_network_peer(Network)
    my_peer_id = 1
    players_data[800] = get_my_data()
    SetConf.Session.connected_to_host_status = "Connected"
    
func setup_as_client():
    SetConf.Session.connected_to_host_status = "Connecting"
    Network = NetworkedMultiplayerENet.new()
    Network.create_client(SetConf.Session.server_ip, SetConf.Session.server_port)
    get_tree().set_network_peer(Network)

func _player_connected(peer_id):
    pass
    #print("Player Connected: " + str(peer_id))

func _player_disconnected(peer_id):
    pass
    #print("Player Disconnected: " + str(peer_id))
    #player_data.erase(id) # Erase player from data

func _connected_ok():
    # Only called on clients, not server. Send my ID and data to all the other peers
    my_peer_id = get_tree().get_network_unique_id()
    #print("Connection Completed: my_peer_id = " + str(my_peer_id))
    rpc_id(1, "register_player", get_my_data())
    get_tree().call_group("networking", "nw_set_host_ip", SetConf.Session.server_ip)
    if SetConf.Session.connected_to_host_status == "Reconnecting":
        SetConf.Session.connected_to_host_status = "Reconnected"
    else:
        SetConf.Session.connected_to_host_status = "Connected"

func _server_disconnected():
    SetConf.Session.connected_to_host_status = "Disconnected"
    #print("Disconnected from the server.") # The server has disappeared.

func _connection_fail():
    SetConf.Session.connected_to_host_status = "Disconnected"
    print("Failed to connect to the server.") # Could not even connect to server, abort
    
func assign_player_number(unique_id):
    var team_num = players_data[unique_id]["player_team"]
    var players_on_team = 0
    for player in players_data:
        if players_data[player]["server_unique_id"] != unique_id:
            if players_data[player]["player_team"] == team_num:
                players_on_team += 1
    players_on_team += 1
    players_data[unique_id]["player_number"] = players_on_team
    players_data[unique_id]["player_id"] = ((players_data[unique_id]["player_team"] - 1) * LazerInterface.players_per_team) + players_data[unique_id]["player_number"]
    if players_data[unique_id]["player_id"] < 0:
        players_data[unique_id]["player_id"] = 0
    if players_data[unique_id]["my_peer_id"] != 1:
        rpc_id(players_data[unique_id]["my_peer_id"], "change_my_player_id", players_data[unique_id]["player_id"])
        rpc_id(players_data[unique_id]["my_peer_id"], "change_my_player_number", players_data[unique_id]["player_number"])
    else:
        SetConf.Session.player_id =players_data[unique_id]["player_id"]
        SetConf.Session.player_number = players_data[unique_id]["player_number"]
    return [players_data[unique_id]["player_id"], players_data[unique_id]["player_number"]]

remote func register_player(data):
    if data["my_peer_id"] != get_tree().get_rpc_sender_id():
        pass  # Spoofing? or Bad Client
        print("WARNING: data['my_peer_id'] = ", data["my_peer_id"], "  did not match get_rpc_sender_id() = ",
                get_tree().get_rpc_sender_id())
    else:
        if get_tree().is_network_server():
            #Network.get_peer_address(get_tree().get_rpc_sender_id())
            #Network.get_peer_port(get_tree().get_rpc_sender_id())
            if data["server_unique_id"] != null:
                var triggered = false
                for server_unique_id in players_data:
                    if players_data[server_unique_id] == data["server_unique_id"]:
                        print("Old Player Network Unique Peer Id was = ", players_data[server_unique_id]["my_peer_id"],
                            "  New Player Network Unique Peer Id is = ", data["my_peer_id"])
                        triggered = true
                if not triggered:
                    print("New Player Network Unique Peer Id is = ", data["my_peer_id"], "  It is not in the players_data dict!")
            else:
                data["server_unique_id"] = get_server_unique_id()
                rpc_id(get_tree().get_rpc_sender_id(), "set_my_server_unique_id", data["server_unique_id"])
                players_data[data["server_unique_id"]] = data
                # send other players the new players data.
                for server_unique_id in players_data:
                    if players_data[server_unique_id]["my_peer_id"] != 1:
                        rpc_id(players_data[server_unique_id]["my_peer_id"], "update_player_data", 
                            data["server_unique_id"], players_data[data["server_unique_id"]])
            # Send the data of existing players
            for server_unique_id in players_data:
                rpc_id(get_tree().get_rpc_sender_id(), "update_player_data", server_unique_id, 
                    players_data[server_unique_id])
            if state_lobby_type_set:  # Move the new player to the right lobby
                set_lobby_team_or_ffa_as_server(get_tree().get_rpc_sender_id())
            if state_scenario_data_set:
                set_scenario_as_server(get_tree().get_rpc_sender_id())
            if state_scenario_player_options_data_set:
                set_scenario_player_options_as_server(get_tree().get_rpc_sender_id())

remote func update_player_data(unique_id, new_data):
    unique_id = null
    if get_tree().get_rpc_sender_id() == 1:
        players_data[new_data["server_unique_id"]] = new_data
        get_tree().call_group("lobby", "lobby_update_team_grid")
    
remote func update_server_player_data(new_data):
    if get_tree().is_network_server():
        if get_tree().get_rpc_sender_id() == new_data["my_peer_id"]:
            players_data[new_data["server_unique_id"]] = new_data
            if players_data[new_data["server_unique_id"]]["player_team"] >= 0:
                if players_data[new_data["server_unique_id"]]["player_number"] >= -1:
                    assign_player_number(new_data["server_unique_id"])
            rpc("update_player_data", new_data["server_unique_id"], players_data[new_data["server_unique_id"]])
            get_tree().call_group("lobby", "lobby_update_team_grid")

func set_lobby_team_or_ffa_as_server(peer_id):
    if SetConf.Session.teams:
        if peer_id == null:  # Because this gets called by outside code to push all current players to the right lobby type.
            rpc("set_num_of_teams", SetConf.Session.num_of_teams)
            rpc("set_team_colors", SetConf.Session.team_colors)
            rpc("change_to_team_lobby")
        else:
            rpc_id(peer_id, "set_num_of_teams", SetConf.Session.num_of_teams)
            rpc_id(peer_id, "set_team_colors", SetConf.Session.team_colors)
            rpc_id(peer_id, "change_to_team_lobby")
    state_lobby_type_set = true

remote func change_to_team_lobby():
    SceneManager.goto_scene("res://scenes/Lobbies/NetworkTeamLobby.tscn")
    print("change_to_team_lobby, going to scene")
    
remote func change_to_ffa_lobby():
    SceneManager.goto_scene("res://scenes/Lobbies/NetworkFfaLobby.tscn")

remote func set_team_colors(team_colors):
    SetConf.Session.team_colors = team_colors
    # TODO: update the lobby.
    
remote func set_num_of_teams(num_of_teams):
    SetConf.Session.num_of_teams = num_of_teams

func set_scenario_as_server(peer_id):
    var scenario_data = [SetConf.Session.end_game, SetConf.Session.end_game_death_limit,
        SetConf.Session.end_game_time_limit, SetConf.Session.indoor_outdoor_mode,
        SetConf.Session.start_delay, SetConf.Session.respawn_delay]
    if peer_id == null:  # Because this gets called by outside code to push all current players to the right lobby type.
        rpc("set_scenario", scenario_data)
    else:
        rpc_id(peer_id, "set_scenario", scenario_data)
    state_scenario_data_set = true

remote func set_scenario(scenario_data):
    SetConf.Session.end_game = scenario_data[0]
    SetConf.Session.end_game_death_limit = scenario_data[1]
    SetConf.Session.end_game_time_limit = scenario_data[2]
    SetConf.Session.indoor_outdoor_mode = scenario_data[3]
    SetConf.Session.start_delay = scenario_data[4]
    SetConf.Session.respawn_delay = scenario_data[5]

func set_scenario_player_options_as_server(peer_id):
    var scenario_player_data = [SetConf.Session.semi_auto_allowed, SetConf.Session.burst_3_allowed,
        SetConf.Session.full_auto_allowed, SetConf.Session.magazine]
    if peer_id == null:  # Because this gets called by outside code to push all current players to the right lobby type.
        rpc("set_scenario_player_options", scenario_player_data)
    else:
        rpc_id(peer_id, "set_scenario_player_options", scenario_player_data)
    state_scenario_player_options_data_set = true

remote func set_scenario_player_options(scenario_player_data):
    SetConf.Session.semi_auto_allowed = scenario_player_data[0]
    SetConf.Session.burst_3_allowed = scenario_player_data[1]
    SetConf.Session.full_auto_allowed = scenario_player_data[2]
    SetConf.Session.magazine = scenario_player_data[3]
    
func tell_server_i_am_ready():
    if get_tree().is_network_server():
        server_recieve_i_am_ready()
    else:
        rpc_id(1, "server_recieve_i_am_ready")
    
remote func server_recieve_i_am_ready():
    if get_tree().is_network_server():
        if get_tree().get_rpc_sender_id() == 0:
            if not 1 in players_ready:
                players_ready.append(1)
        else:
            if not get_tree().get_rpc_sender_id() in players_ready:
                players_ready.append(get_tree().get_rpc_sender_id())
        check_if_all_are_ready()
        
func check_if_all_are_ready():
    if players_ready.size() == players_data.size():
        if not state_in_game_loading:
            rpc("change_to_team_in_game")
        else:
            rpc("start_the_game_players_ready")
        players_ready = []  # Empty the list for the next use.

sync func change_to_team_in_game():
    SceneManager.goto_scene("res://scenes/InGame/InGameNetwork.tscn")
    state_in_game_loading = true
    
sync func start_the_game_players_ready():
    net_time.start()
    state_playing_game = true
    get_tree().call_group("in_game", "ig_all_players_ready")
    
func record_game_event(event_type, parameters):
    device_unpassed_history.append([net_time.time_left, 
        get_my_data()["server_unique_id"], event_type, parameters])

func send_game_events_to_server():
    if device_unpassed_history.size() > 0:
        device_passed_history.append(device_unpassed_history.pop_front())
        if get_tree().is_network_server():
            server_rx_game_event(device_passed_history[device_passed_history.size() - 1])
        else:
            rpc_id(1, "server_rx_game_event", 
                device_passed_history[device_passed_history.size() - 1])
        
remote func server_rx_game_event(event):
    server_unsorted_history.append(event)
    if get_tree().get_rpc_sender_id() == 0:
        client_rx_ack_game_event()
    else:
        rpc_id(get_tree().get_rpc_sender_id(), "client_rx_ack_game_event")

remote func client_rx_ack_game_event():
    device_passed_history.pop_front()
    
func server_process_history():
    var largest = 0
    if server_unsorted_history.size() > 0:
        for hist in range(server_unsorted_history.size()):
            if server_unsorted_history[hist][0] > largest: # time
                # largest time is actually the most recent because timers count down.
                largest = hist
        if game_history.size() == 0:
            game_history.append(server_unsorted_history[largest])
            server_unpassed_game_history.append([server_unsorted_history[largest], null])
            server_unsorted_history.remove(largest)
        elif server_unsorted_history[largest][0] < game_history[-1][0]:
            game_history.append(server_unsorted_history[largest])
            server_unpassed_game_history.append([server_unsorted_history[largest], null])
            server_unsorted_history.remove(largest)
        else:
            var index = 0
            for i in range(game_history.size(), 0):  # Work backwards
                if server_unsorted_history[largest][0] < game_history[i][0]:
                    index = i + 1
                    break
            game_history.insert(index, server_unsorted_history[largest])
            server_unpassed_game_history.append([server_unsorted_history[largest], index])
            server_unsorted_history.remove(largest)

func server_send_game_history():
    if server_unpassed_game_history.size() > 0:
        var piece = server_unpassed_game_history[0][0]
        var at_pos = server_unpassed_game_history.pop_front()[1]
        rpc("client_rx_game_hitory", piece, at_pos)
    
remote func client_rx_game_history(piece, at_pos):
    if at_pos == null:
        game_history.append(piece)
    else:
        game_history.insert(at_pos, piece)
    
func _process(delta):  # This is executed during idle time.
    delta = null
    if state_playing_game:
        if SetConf.Session.connected_to_host_status == "Connected":
            send_game_events_to_server()
            if get_tree().is_network_server():
                server_process_history()
                server_send_game_history()
        elif SetConf.Session.connected_to_host_status == "Disconnected":
            get_tree().set_network_peer(Network)
            SetConf.Session.connected_to_host_status = "Reconnecting"
        elif SetConf.Session.connected_to_host_status == "Reconnecting":  # connecting
            pass

func act_on_last_game_history_piece():
    # net_time.time_left, get_my_data()["server_unique_id"], event_type, parameters
    if game_history_act_count != game_history.size() - 1:
        game_history_act_count += 1
        if game_history[game_history_act_count][2] == "end_game":
            players_at_end_game += 1
            if players_data.size() == players_at_end_game:
                print(game_history)
##############################################
# "networking" group calls
##############################################

func host_ip_choosen(ip):
    SetConf.Session.server_ip = ip
