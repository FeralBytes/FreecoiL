extends Node

var unique_persistant_id = 1
var Server = null
var Client
var validate_ipv4 = RegEx.new()
var rng = RandomNumberGenerator.new()

var upnp = null
var pp_udp = null
var websocket_server = null
var websocket_client = null
var search_udp_broadcast = false
var host_udp_broadcast = false
var host_udp_broadcast_uid = null
var network_loops = []
var __udp_broadcast_tx_time_since = null
var __udp_broadcast_hosting_tx_time_since = null
var test_all_mups_were_ready = false
var udp_test = false
var udp_test_from_peer = 0
var udp_test_broadcast_rx_count = 0
var udp_test_broadcast_tx_count = 0
var websockets_client_init_comp = false
var websockets_test_server_connected = false
var websockets_test_client_connected = false
var websockets_test_server_client_id = null
var websockets_test_server_rx_data = false
var websockets_test_client_rx_data = false
var websockets_test_client_requested_closed = false
var websockets_test_server_disconnected = false
var websockets_test_client_disconnected = false
var testing = false
    
func invert_mups_to_peers(mups_to_peers):
    if get_tree().get_network_peer() == null:
        var peers_to_mups = {}
        for key in mups_to_peers:
            peers_to_mups[mups_to_peers[key]] = key
        # NOTE: For JSON Objects must have keys that are strings not Integers.
        # Invert players and do not store in JSON.
        Settings.Network.set_data("peers_to_mups", peers_to_mups)
    elif get_tree().is_network_server():
        var peers_to_mups = {}
        for key in mups_to_peers:
            peers_to_mups[mups_to_peers[key]] = key
        # NOTE: For JSON Objects must have keys that are strings not Integers.
        # Invert players and do not store in JSON.
        Settings.Network.set_data("peers_to_mups", peers_to_mups)

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("Network")
    testing = Settings.Testing.get_data("testing")
    # warning-ignore:return_value_discarded
    get_tree().connect("network_peer_connected", self, "_client_connected")
    # warning-ignore:return_value_discarded
    get_tree().connect("network_peer_disconnected", self, "_client_disconnected")
    # warning-ignore:return_value_discarded
    get_tree().connect("connected_to_server", self, "_connected_ok")
    # warning-ignore:return_value_discarded
    get_tree().connect("connection_failed", self, "_connection_failed")
    # warning-ignore:return_value_discarded
    get_tree().connect("server_disconnected", self, "_server_disconnected")
    validate_ipv4.compile("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
    Settings.Session.register_data("server_ip", "")
    Settings.Session.register_data("server_ignore_list", [])
    Settings.Session.register_data("mup_id", null)  # mup_id = my_unique_persistant_id
    Settings.Network.register_data("mups_to_peers", {"1": 1})
    invert_mups_to_peers(Settings.Network.get_data("mups_to_peers"))
    Settings.Network.register_data("mups_ready", {})
    Settings.Network.register_data("peers_minimum", Settings.MIN_PLAYERS)
    # peer_status can be one of ["connected", "disconnected", "connecting", "reconnecting", "reconnected", "identifying"]
    Settings.Network.register_data("mups_status", {"1": "connected"})
    #Settings.Session.connect(Settings.Session.monitor_data("server_possible_ips"), self, "setup_server_part2")
    Settings.Network.connect(Settings.Network.monitor_data("mups_to_peers"), self, "invert_mups_to_peers")
    Settings.Network.connect(Settings.Network.monitor_data("mups_ready"), self, "check_if_all_mups_ready")
    Settings.Network.set_data("websockets_init_comp", false)
    Settings.Network.set_data("websockets_client_connected", false)
    Settings.InGame.set_data("player_name_by_id", {})
    Settings.InGame.set_data("player_team_by_id", {})
    Settings.InGame.set_data("game_teams_by_team_num_by_id", [])
    rng.randomize()
    host_udp_broadcast_uid = rng.randi()
    Settings.Log("Network: UDP: UDP broadcast uid = " + str(host_udp_broadcast_uid))
    set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(__):
    for msg_loop in network_loops:
        call_deferred(msg_loop)

remote func sync_var(classname, var_name, var_val=null):   # class_name is a reserved word in GDScript
    Settings.Log("RPC: 'sync_var' sender_id = " + str(Settings.get_tree().get_rpc_sender_id()) +
                " classname=" + str(classname) + " var_name=" + str(var_name) + "  var_val=" + str(var_val), "info")
    match classname:
        "Network":
            Settings.Network.set_data(var_name, var_val, true)
        "InGame":
            Settings.InGame.set_data(var_name, var_val, true)

func reset_networking():
    if Server == null:
        if Client != null:
            #Client.queue_free()
            Client = null
    else:
        #Server.queue_free()
        Server.close_connection()
        yield(get_tree().create_timer(0.1), "timeout")
        Server = null
        if Client != null:
            #Client.queue_free()
            Client.close_connection()
            yield(get_tree().create_timer(0.1), "timeout")
            Client = null
    get_tree().set_network_peer(null)
    yield(get_tree(), "idle_frame")  # Yield at least one time to be a coroutine.

#### SCENETREE SERVER NETWORKING FUNCTIONS
func _client_connected(godot_peer_id):  # Client Equals Another Player
    Settings.Log("Network: Server: Peer Connected with peer id: " + str(godot_peer_id), "info")
    if get_tree().is_network_server():
        if godot_peer_id in Settings.Network.get_data("mups_to_peers").values():
            var peers_to_mups = Settings.Network.get_data("peers_to_mups")
            var mups_status = Settings.Network.get_data("mups_status")
            mups_status[peers_to_mups[godot_peer_id]] = "identifying"
            Settings.Network.set_data("mups_status", mups_status)
    
func _client_disconnected(godot_peer_id):  # Client Equals Another Player
    Settings.Log("Peer Disconnected with peer id: " + str(godot_peer_id))
    if get_tree().is_network_server():
        if godot_peer_id in Settings.Network.get_data("mups_to_peers").values():
            var peers_to_mups = Settings.Network.get_data("peers_to_mups")
            var mups_status = Settings.Network.get_data("mups_status")
            mups_status[peers_to_mups[godot_peer_id]] = "disconnected"
            Settings.Network.set_data("mups_status", mups_status)

func assign_unique_id():
    # Rationale: Although Godot does something like this, it misses our use case.
    # If a player disconnects and then reconnects thier peer_id will be new each time.
    # We want players to be able to drop out. But if they comeback to us with the
    # same unique_persistant_id, then they are the same player.
    unique_persistant_id += 1
    return str(unique_persistant_id)
    
remote func identify(pup_id, godot_peer_id):
    var real_rpc_id = get_tree().get_rpc_sender_id()
    if real_rpc_id != godot_peer_id:
        # Spoofing or Bad Client
        Settings.Log("Bad Remote Client is Spoofing. Real rpc_id: " + str(real_rpc_id) + " Spoofed rpc_id: " + str(godot_peer_id))
        Server.disconnect_peer(real_rpc_id, true)
        return
    else:
        if get_tree().is_network_server():
            var mups_status = Settings.Network.get_data("mups_status")
            var peers_to_mups = Settings.Network.get_data("peers_to_mups")
            var mups_to_peers = Settings.Network.get_data("mups_to_peers")
            if pup_id == null:
                var new_up_id = assign_unique_id()
                mups_to_peers[new_up_id] = godot_peer_id
                Settings.Network.set_data("mups_to_peers", mups_to_peers)
                rpc_id(godot_peer_id, "set_mup_id", new_up_id)
                mups_status[new_up_id] = "connected"
            else:
                if Settings.Network.get_data("mups_to_peers").has(pup_id):
                    if Settings.Network.get_data("mups_to_peers")[pup_id] == godot_peer_id:
                        Settings.Log("Player already identified with the same rpc_id.")
                        mups_status[peers_to_mups[godot_peer_id]] = "reconnected"
                    else:
                        mups_to_peers[pup_id] = godot_peer_id
                        Settings.Network.set_data("mups_to_peers", mups_to_peers)
                        mups_status[peers_to_mups[godot_peer_id]] = "reconnected"
                else:
                    Settings.Log("Error: player_unique_persistant_id, does not exist yet in peers dict. Bad Client?")
                    Server.disconnect_peer(real_rpc_id, true)
                    return
            Settings.Network.sync_peer(godot_peer_id)
            print("Player Name = " + str(Settings.InGame.get_data("player_name_by_id")))
            Settings.InGame.sync_peer(godot_peer_id)
            Settings.Network.set_data("mups_status", mups_status)

func setup_server_part1():
    reset_networking()
    Settings.Session.set_data("mup_id", "1")  # mup_id != peer id.
    if Settings.Session.get_data("server_ip") == "":
        var local_ips = IP.get_local_addresses()
        var valid_ipv4_matches = []
        for ip in local_ips:
            var a_match = validate_ipv4.search(ip)
            if a_match != null:
                valid_ipv4_matches.append(a_match.get_strings()[0])
        valid_ipv4_matches.erase("127.0.0.1")
        Settings.Session.set_data("server_possible_ips", valid_ipv4_matches)
        if valid_ipv4_matches.size() == 0:
            Settings.Log("Error: Not Implemented Yet!", "error")
            Settings.Log("    No valid IPv4 addresses.", "error")
            get_tree().call_group("Container", "next_menu", "-1,1")
        elif valid_ipv4_matches.size() == 1:
            Settings.Session.set_data("server_ip", valid_ipv4_matches[0])
            Settings.Log("Network: Server: Valid IP Address found of " + str(valid_ipv4_matches[0]) + ".")
            call_deferred("setup_server_part2")
        else:  # > 1 AKA multiple valid external IP Address to choose from.
            Settings.Log("Error: Not Implemented Yet!", "error")
            Settings.Log("    Too many valid IPv4 addresses.", "error")
            get_tree().call_group("Container", "next_menu", "-1,1")
            
    else:
        Settings.Log("Network: Server: Valid IP Address found of " + str(Settings.Session.get_data("server_ip")) + ".")
        call_deferred("setup_server_part2")
        
func setup_server_part2():
    Settings.Log("Network: Server: Setting up the Server now.")
    Settings.Session.set_data("server_port", Settings.NETWORK_LAN_PORT)
    Server = NetworkedMultiplayerENet.new()
    Server.set_bind_ip(Settings.Session.get_data("server_ip"))
    Server.create_server(Settings.Session.get_data("server_port"), Settings.MAX_PLAYERS + Settings.MAX_OBSERVERS)
    get_tree().set_network_peer(Server)
    Settings.Session.set_data("connection_status", "connected")
    host_udp_broadcast = true
    search_for_peers()
    Settings.InGame.set_data("player_name_by_id", {"1": Settings.Preferences.get_data("player_name")})
    Settings.InGame.set_data("player_team_by_id", {"1": 0})
    Settings.InGame.set_data("game_teams_by_team_num_by_id", [["1"]])
    Settings.Log("Network: Server: Removing UDP Peer Search from network loops.")
    network_loops.append("_hosting_so_toss_udp_broadcast")
    network_loops.append("_hosting_send_udp_broadcast")
    set_process(true)
    Settings.Log("Network: Server: Server created and sending out UDP invites with a UID of " + str(host_udp_broadcast_uid) + ".")

func check_if_all_mups_ready(mups_ready):
    if testing:
        test_all_mups_were_ready = true
    if get_tree().is_network_server():
        var all_ready = true
        if mups_ready.size() == Settings.Network.get_data("mups_to_peers").size() and mups_ready.size() >= Settings.MIN_PLAYERS:
            for mup in mups_ready:
                if mups_ready[mup] == false:
                    all_ready = false
        else:
            all_ready = false
        if all_ready:
            Settings.Session.set_data("all_ready", true)
            call_deferred("synchronize_start_game_data")
     
func synchronize_start_game_data():
    if get_tree().is_network_server():
        var mups_ready = Settings.Network.get_data("mups_ready")  # Reuse
        for mups in mups_ready:
            mups_ready[mups] = false
        Settings.Network.set_data("mups_ready", mups_ready)  # network peer id is not equal to mup_id
        Settings.InGame.set_data("game_type", ["LAN", "1v1", "Match"])
        Settings.InGame.set_data("default_tile_color", "b2b2b2")
        Settings.InGame.set_data("player_type_by_id", {"1":"network", "2":"network"})
        Settings.InGame.set_data("color_by_id", {"1":"253a9a", "2":"960e0e"})
        Settings.InGame.set_data("names_by_id", {"1":"Blue", "2":"Red"})
        Settings.InGame.set_data("scores_by_id", {"1":2, "2":2})
        Settings.InGame.set_data("current_players_turn", "1")
        get_tree().call_group("Container", "do_remote_goto_scene", "res://scenes/InGame/InGame.tscn")

#### SCENETREE CLIENT NETWORKING FUNCTIONS
func _connected_ok():
    Settings.Log("Network: Client: Connection Established, my peer id is: " + str(get_tree().get_network_unique_id()))
    rpc_id(1, "identify", Settings.Session.get_data("mup_id"), get_tree().get_network_unique_id())
    set_player_name()
    if Settings.Session.get_data("player_team") == null:
        Settings.Session.set_data("player_team", 0)
    set_player_team()
    
func _connection_failed():
    Settings.Log("Network: Client: Connection failed.")
    get_tree().set_network_peer(null)
    
func _server_disconnected():
    Settings.Log("Network: Client: Connection terminated by the server.")
    get_tree().set_network_peer(null)
    
func setup_as_client():
    Settings.Session.set_data("connection_status", "connecting")
    Settings.Log("Network: Client: Setting up as a client with server address of " + Settings.Session.get_data("server_ip") + ":" + str(Settings.Session.get_data("server_port")))
    Client = NetworkedMultiplayerENet.new()
    Client.create_client(Settings.Session.get_data("server_ip"), Settings.Session.get_data("server_port"))
    get_tree().set_network_peer(Client)
    
remote func set_mup_id(new_id):
    if not get_tree().is_network_server():
        Settings.Log("RPC: 'set_my_unique_persistant_id' to " + str(new_id) + ". sender_id = " + str(get_tree().get_rpc_sender_id()), "info")
        if get_tree().get_rpc_sender_id() == 1:
            Settings.Session.set_data("mup_id", new_id)

func set_player_name():
    if get_tree().is_network_server():
        set_player_name_remote(Settings.Preferences.get_data("player_name"))
    else:
        rpc_id(1, "set_player_name_remote", Settings.Preferences.get_data("player_name"))
            
remote func set_player_name_remote(new_name):
    if get_tree().is_network_server():
        Settings.Log("RPC: 'set_player_name()' to " + str(new_name) + " from sender_id = " + str(get_tree().get_rpc_sender_id()))
        var player_name_by_id = Settings.InGame.get_data("player_name_by_id")
        var mups = Settings.Network.get_data("peers_to_mups")[get_tree().get_rpc_sender_id()]
        player_name_by_id[mups] = new_name
        Settings.InGame.set_data("player_name_by_id", player_name_by_id)

func set_player_team():
    if get_tree().is_network_server():
        set_player_team_remote(Settings.Session.get_data("player_team"))
    else:
        rpc_id(1, "set_player_team_remote", Settings.Session.get_data("player_team"))

remote func set_player_team_remote(new_team):
    var rpc_sender_id = -1
    if get_tree().is_network_server():
        if get_tree().get_rpc_sender_id() == 0:
            rpc_sender_id = 1
        else:
            rpc_sender_id = get_tree().get_rpc_sender_id()
        Settings.Log("RPC: 'set_player_team()' to " + str(new_team) + " from sender_id = " + str(rpc_sender_id))
        var player_team_by_id = Settings.InGame.get_data("player_team_by_id")
        var mups = Settings.Network.get_data("peers_to_mups")[rpc_sender_id]
        var previous_team = -1
        if player_team_by_id.has(mups):
            previous_team = player_team_by_id[mups]
        player_team_by_id[mups] = new_team
        Settings.InGame.set_data("player_team_by_id", player_team_by_id)
        var game_teams_by_team_num_by_id = Settings.InGame.get_data("game_teams_by_team_num_by_id")
        # First make sure there is an Array for each possible team.
        if Settings.InGame.get_data("game_number_of_teams") != null:
            if len(game_teams_by_team_num_by_id) - 1 != Settings.InGame.get_data("game_number_of_teams"):
                for index in range(0, Settings.InGame.get_data("game_number_of_teams") + 1):
                    if len(game_teams_by_team_num_by_id) - 1 < index:
                        game_teams_by_team_num_by_id.append([])
        # Second remove them from the previous team.
        if previous_team != -1:
            if mups in game_teams_by_team_num_by_id[previous_team]:
                game_teams_by_team_num_by_id[previous_team].erase(mups)
        # Third add them to the new team.
        print("game_teams_by_team_num_by_id = " + str(game_teams_by_team_num_by_id))
        game_teams_by_team_num_by_id[new_team].append(mups)
        Settings.InGame.set_data("game_teams_by_team_num_by_id", game_teams_by_team_num_by_id)

#### UDP BroadCast For LAN
func search_for_peers():
    Settings.Log("Network: UDP: Search for Peers: Setting up new PacketPeerUDP.")
    pp_udp = PacketPeerUDP.new()
    pp_udp.set_broadcast_enabled(true)  # New with 3.2 must have this option enabled.
    pp_udp.set_dest_address("255.255.255.255", Settings.NETWORK_BROADCAST_LAN_PORT)
    pp_udp.listen(Settings.NETWORK_BROADCAST_LAN_PORT)
    Settings.Session.register_data("udp_peer_dict", {})
    search_udp_broadcast = true
    network_loops.append("_udp_broadcast_rxd")
    network_loops.append("_udp_broadcast_tx")
    set_process(true)
    Settings.Log("Network: UDP: Search for Peers: Setup completed.")
    
func _udp_broadcast_tx():
    if search_udp_broadcast:
        if __udp_broadcast_tx_time_since == null:
            __udp_broadcast_tx()
        elif OS.get_ticks_msec() - __udp_broadcast_tx_time_since > 500:
            __udp_broadcast_tx()
        else:
            pass
    else:
        network_loops.remove("_udp_broadcast_tx")

func __udp_broadcast_tx():
    udp_test_broadcast_tx_count += 1
    pp_udp.put_var([Settings.UDP_BROADCAST_GREETING, Settings.Session.get_data("server_ip"), Settings.Session.get_data("server_port"), host_udp_broadcast_uid])
    __udp_broadcast_tx_time_since = OS.get_ticks_msec()
    
func _udp_broadcast_rxd():
    while pp_udp.get_available_packet_count() > 0:
        var udp_peer_dict = Settings.Session.get_data("udp_peer_dict")
        var udp_var = pp_udp.get_var()
        var udp_peer_ip = pp_udp.get_packet_ip()
        if testing:
            udp_test = udp_var
            udp_test_broadcast_rx_count += 1
        if typeof(udp_var) == TYPE_ARRAY:
            if udp_var[3] == host_udp_broadcast_uid:
                #Settings.Log("Network: UDP: Got broadcast from self.")
                pass  # Throw it away.
            elif udp_var[0] == Settings.UDP_BROADCAST_GREETING:
                Settings.Log("Networking: UDP: Got UDP Peer Greeting broadcast from: " + udp_peer_ip +  " of " + str(udp_var))
                udp_peer_dict[udp_peer_ip] = OS.get_system_time_secs()
                if testing:
                    udp_test_from_peer = udp_var[3]
            elif udp_var[0] == Settings.UDP_BROADCAST_HOST:
                Settings.Log("Networking: UDP: Got UDP Server Greeting broadcast from: " + udp_peer_ip +  " of " + str(udp_var))
                if not Settings.Session.get_data("server_invite"):
                    if udp_var[1] in Settings.Session.get_data("server_ignore_list"):
                        pass
                    else:
                        Settings.Session.set_data("server_invite", true)
                        Settings.Log("Networking: UDP: Client found server's address = " + udp_var[1] + ":" + str(udp_var[2]))
                        Settings.Session.set_data("server_ip", udp_var[1])
                        Settings.Session.set_data("server_port", udp_var[2])
                        get_tree().call_group("Network", "stop_udp_peer_search")
                        get_tree().call_group("Network", "setup_as_client")
                        get_tree().call_group("Container", "load_lobby")              
        # Remove peers that have not broadcast lately. > 3 seconds.
        for udp_peer in udp_peer_dict:
            if OS.get_system_time_secs() - udp_peer_dict[udp_peer] > 3:
                udp_peer_dict.erase(udp_peer)
        Settings.Session.set_data("udp_peer_dict", udp_peer_dict)
            
func _hosting_so_toss_udp_broadcast():
    search_udp_broadcast = false
    network_loops.remove("_udp_broadcast_tx")
    if pp_udp != null:
        while pp_udp.get_available_packet_count() > 0:
            var udp_var = pp_udp.get_var()
            var udp_peer_ip = pp_udp.get_packet_ip()
            if udp_peer_ip in IP.get_local_addresses():
                pass  # Throw it away.
            else:
                if typeof(udp_var) == TYPE_ARRAY:
                    if udp_var[0] == Settings.UDP_BROADCAST_HOST:
                        Settings.Log("Network: UDP: Warning: Another server is hosting at " + udp_var[1] + ":" + str(udp_var[2]))
                        Settings.Log("        Verified IP Address is: " + udp_peer_ip)

func _hosting_send_udp_broadcast():
    if __udp_broadcast_hosting_tx_time_since == null:
        __hosting_send_udp_broadcast()
    elif OS.get_ticks_msec() - __udp_broadcast_hosting_tx_time_since > 500:
        __hosting_send_udp_broadcast()
    else:
        pass

func __hosting_send_udp_broadcast():
    pp_udp.put_var([Settings.UDP_BROADCAST_HOST, Settings.Session.get_data("server_ip"), Settings.Session.get_data("server_port"), host_udp_broadcast_uid])
    __udp_broadcast_hosting_tx_time_since = OS.get_ticks_msec()
    #Settings.Log("Network: UDP: Sent UDP Host Broadcast.")
 
func udp_peer_selected(peer_ip):
    Settings.Log("Network: UDP: UDP Peer Selected: " + str(peer_ip))
    stop_udp_peer_search()   
    Settings.Session.set_data("players_ip", peer_ip)
    setup_server_part1()  
    
func stop_udp_peer_search():
    Settings.Log("Network: UDP: Stopping UPD Peer Search.")
    search_udp_broadcast = false
    network_loops.remove("_udp_broadcast_rxd")
    network_loops.remove("_udp_broadcast_tx")

#### UPNP
func _init_upnp():
    upnp = UPNP.new()
    upnp.discover(2000, 2, "InternetGatewayDevice")
    upnp.add_port_mapping(Settings.NETWORK_LAN_PORT)
    upnp.delete_port_mapping(Settings.NETWORK_LAN_PORT)
    
#### Websocket Communication ####

func init_websocket_server():
    websocket_server = WebSocketServer.new()
    websocket_server.connect("client_connected", self, "websocket_server_connected")
    websocket_server.connect("client_disconnected", self, "websocket_server_disconnected")
    websocket_server.connect("client_close_request", self, "websocket_server_client_close_request")
    websocket_server.connect("data_received", self, "websocket_server_on_data")
    websocket_server.listen(58888)
    network_loops.append("websocket_server_poll")
    
func websocket_server_connected(id, _proto):
    Settings.Log("Network: Websockets: Websocket server new connection with " + str(id))
    if testing:
        websockets_test_server_connected = true
    
func websocket_server_disconnected(id, _was_clean=false):
    Settings.Log("Network: Websockets: Websocket server disconnected from id " + str(id))
    if testing:
        websockets_test_server_disconnected = true
    
func websocket_server_client_close_request(id, code, reason):
    Settings.Log("Network: Websockets: Websocket server, client close request from " + str(id)
        + " with code of " + str(code) + " reason of " + str(reason))
    if testing:
        websockets_test_client_requested_closed = true
    
func websocket_server_on_data(id):
    if testing:
        websockets_test_server_client_id = id
        websockets_test_server_rx_data = websocket_server.get_peer(id).get_packet()
    
func websocket_server_poll():
    websocket_server.poll()

func websocket_server_send_data(id, data):
    websocket_server.get_peer(id).put_packet(data)


func init_websocket_client():
    websocket_client = WebSocketClient.new()
    websocket_client.connect("connection_established", self, "websocket_client_established")
    websocket_client.connect("connection_error", self, "websocket_client_error")
    websocket_client.connect("connection_closed", self, "websocket_client_closed")
    websocket_client.connect("data_received", self, "websocket_client_on_data")
    network_loops.append("websocket_client_poll")
    set_process(true)
    Settings.Log("Network: Websockets: Websockets Initialization Completed.")
    Settings.Network.set_data("websockets_client_init_comp", true)

func websocket_client_established(_proto=""):
    Settings.Log("Network: Websockets: Websocket client connected.")
    Settings.Network.set_data("websockets_client_connected", true)
    if testing:
        websockets_test_client_connected = true

func websocket_client_error(_was_clean=false):
    Settings.Log("Network: Websockets: Encountered an error while attempting websocket client communication.")
    pass

func websocket_client_closed(was_clean=false):
    Settings.Log("Network: Websockets: Websocket client disconnected was clean = " + str(was_clean))
    if testing:
        websockets_test_client_disconnected = true
    
func websocket_client_on_data():
    var temp = websocket_client.get_peer(1).get_packet()
    Settings.Network.set_data("websocket_client_data", temp)
    Settings.Log("Network: Websockets: Data recieved = " + str(temp.get_string_from_utf8()))
    if testing:
        websockets_test_client_rx_data = websocket_client.get_peer(1).get_packet()

func websocket_client_poll():
    websocket_client.poll()

func websocket_client_connect_to_url(url, additional_headers):
    var err
    if additional_headers == null:
        err = websocket_client.connect_to_url(url, [], false)
    else:
        err = websocket_client.connect_to_url(url, [], false, additional_headers)
    if err != OK:
        Settings.Log("Network: Websockets: Unable to connect; error = " + str(err), "error")
    else:
        Settings.Log("Network: Websockets: Connection made.")

func websocket_client_send_data(data):
    websocket_client.get_peer(1).put_packet(data)

func websocket_client_disconnect():
    websocket_client.disconnect_from_host()

