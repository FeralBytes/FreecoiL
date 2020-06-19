extends Control

var game_over = false
var events_not_sent = []
var events_not_acknowledged = []
var game_history = []
var rxd_events = []
var peers_in_catch_up = []
var event_counter = 0
var event_template = {"client_time": null, "event_id": null, "type": null, "rec_by": null, "additional": {}}
var server_unackn_events_by_mup = {}
var catch_up_active = false
var last_connection_status = null

onready var ReloadSound = get_node("ReloadSound")
onready var EmptyShotSound = get_node("EmptyShotSound")
onready var GunShotSound = get_node("GunShotSound")
onready var TangoDownSound = get_node("TangoDownSound")
onready var NiceSound = get_node("NiceSound")
onready var HitIndicatorTimer = get_node("HitIndicatorTimer")
onready var TimeRemainingTimer = get_node("TimeRemainingTimer")
onready var RespawnTimer = get_node("RespawnDelayTimer")
onready var StartGameTimer = get_node("StartGamedelayTimer")
onready var ReloadTimer = get_node("ReloadTimer")
onready var TickTocTimer = get_node("TickTocTimer")
onready var EventRecordTimer = get_node("EventRecordTimer")
onready var EndReason = get_node("0,1-End of Game/CenterContainer/VBoxContainer/EndReason")


func invert_mups_to_lasers(mups_to_lasers):
    if get_tree().is_network_server():
        var lasers_to_mups = {}
        for key in mups_to_lasers:
            lasers_to_mups[mups_to_lasers[key]] = key
        # NOTE: For JSON Objects must have keys that are strings not Integers.
        # Invert players and do not store in JSON.
        Settings.InGame.set_data("player_id_by_laser", lasers_to_mups)

# Called when the node enters the scene tree for the first time.
func _ready():
    if get_tree().is_network_server():
        Settings.Session.connect(Settings.Session.monitor_data("all_ready"), self, "start_game_start_delay")
        Settings.Session.connect(Settings.Session.monitor_data("mups_reconnected"), self, "on_mup_reconnected")
        invert_mups_to_lasers(Settings.InGame.get_data("player_laser_by_id"))
    add_to_group("FreecoiL")
    get_tree().call_group("Container", "next_menu", "0,-1")
    FreecoiLInterface.set_laser_id(Settings.InGame.get_data("player_laser_by_id")[Settings.Session.get_data("mup_id")])
    # Make Connections
    Settings.Session.connect(Settings.Session.monitor_data("fi_trigger_btn_pushed"), self, "fi_trigger_btn_pushed")
    Settings.Session.connect(Settings.Session.monitor_data("connection_status"), self, "connection_status_event")
    set_player_start_game_vars()
    get_tree().call_group("Network", "tell_server_i_am_ready", true)


func set_player_start_game_vars():
    set_player_respawn_vars()
    setup_recording_vars()
    Settings.Session.set_data("game_player_alive", false)
    if Settings.InGame.get_data("game_teams"):
        var game_teams_by_team_num_by_id = Settings.InGame.get_data("game_teams_by_team_num_by_id")
        var game_team_status_by_num = {}
        for team_num in range(0, game_teams_by_team_num_by_id.size()):
            if team_num == 0:
                pass
            else:
                game_team_status_by_num[team_num] = "playing"
        Settings.InGame.set_data("game_team_status_by_num", game_team_status_by_num)
    Settings.Session.set_data("game_tick_toc_start_delay", Settings.InGame.get_data("game_start_delay"))
    if Settings.InGame.get_data("game_limit_mode") == "time":
        Settings.Session.set_data("game_tick_toc_time_remaining", Settings.InGame.get_data("game_time_limit"))
    Settings.Session.set_data("game_tick_toc_respawn", Settings.InGame.get_data("game_respawn_delay"))
    Settings.Session.set_data("game_tick_toc_time_elapsed", 0)
    Settings.Session.set_data("game_started", 0)  # Quad State: 0=Not Stated, 1=Started, 2=Paused, 3=Game Over
    Settings.Session.set_data("game_player_team", Settings.InGame.get_data("player_team_by_id")[Settings.Session.get_data("mup_id")])
    Settings.Session.set_data("game_player_teammates", 
        Settings.InGame.get_data("game_teams_by_team_num_by_id")[Settings.Session.get_data("game_player_team")])
    Settings.Session.set_data("game_player_last_killed_by", "")
    Settings.Session.set_data("game_player_deaths", 0)
    Settings.Session.set_data("game_player_kills", 0)
    Settings.Session.set_data("game_player_laser_id", Settings.InGame.get_data("player_laser_by_id")[Settings.Session.get_data("mup_id")])
    StartGameTimer.wait_time = Settings.InGame.get_data("game_start_delay")
    StartGameTimer.connect("timeout", self, "start_the_game")
    StartGameTimer.one_shot = true
    ReloadTimer.wait_time = Settings.Session.get_data("game_weapon_reload_speed")
    ReloadTimer.connect("timeout", self, "reload_finish")
    ReloadTimer.one_shot = true
    if Settings.InGame.get_data("game_limit_mode") == "time":
        TimeRemainingTimer.connect("timeout", self, "end_game", ["time"])
        TimeRemainingTimer.wait_time = Settings.InGame.get_data("game_time_limit")
        TimeRemainingTimer.one_shot = true
    HitIndicatorTimer.wait_time = Settings.Preferences.get_data("player_hit_indicator_duration")
    HitIndicatorTimer.one_shot = true
    HitIndicatorTimer.connect("timeout", self, "hit_indicator_stop")
    RespawnTimer.connect("timeout", self, "respawn_finish")
    RespawnTimer.wait_time = Settings.InGame.get_data("game_respawn_delay")
    RespawnTimer.one_shot = true
    
func set_player_respawn_vars():
    var weapon_type = Settings.InGame.get_data("game_start_weapon_type")
    Settings.Session.set_data("game_weapon_type", weapon_type)
    Settings.Session.set_data("game_weapon_damage", Settings.InGame.get_data("game_weapon_types")[weapon_type]["damage"])
    Settings.Session.set_data("game_weapon_shot_modes", Settings.InGame.get_data("game_weapon_types")[weapon_type]["shot_modes"])
    Settings.Session.set_data("game_weapon_shot_mode", Settings.Session.get_data("game_weapon_shot_modes")[0])
    Settings.Session.set_data("game_weapon_magazine_size", Settings.InGame.get_data("game_weapon_types")[weapon_type]["magazine_size"])
    Settings.Session.set_data("game_weapon_magazine_ammo", 0)
    Settings.Session.set_data("game_player_health", Settings.InGame.get_data("game_start_health"))
    Settings.Session.set_data("game_player_ammo", Settings.InGame.get_data("game_start_ammo"))
    Settings.Session.set_data("game_weapon_total_ammo", Settings.Session.get_data("game_player_ammo")[weapon_type])
    Settings.Session.set_data("game_weapon_reload_speed", Settings.InGame.get_data("game_weapon_types")[weapon_type]["reload_speed"])
    Settings.Session.set_data("game_weapon_rate_of_fire", Settings.InGame.get_data("game_weapon_types")[weapon_type]["rate_of_fire"])
    #Settings.Session.set_data("game_player_alive", true)
    
func start_game_start_delay(__):
    if get_tree().is_network_server():
        get_tree().call_group("Network", "unready_all_mups")
        yield(get_tree().create_timer(0.2), "timeout")  # Just to let the network settle out.
        rpc("remote_start_game_start_delay")
    
remotesync func remote_start_game_start_delay():
    EventRecordTimer.start()
    TickTocTimer.start()
    StartGameTimer.start()
    get_tree().call_group("Container", "next_menu", "-1,-1")
    if get_tree().is_network_server():
        record_game_event("start_game_delay")
    
func start_the_game():
    Settings.Session.set_data("game_started", 1)
    TimeRemainingTimer.start()
    get_tree().call_group("Container", "next_menu", "0,0")
    record_game_event("start_game")  # I want to see how much drift or lag we have already.
    respawn_finish()
    
func back_to_Playing():
    pass
    
func end_game(reason):
    Settings.Session.set_data("game_started", 3)
    Settings.Session.set_data("game_player_alive", false)
    FreecoiLInterface.reload_start()
    record_game_event("end_game", {"reason": reason})
    get_tree().call_group("Container", "next_menu", "0,1")
    if reason == "time":
        EndReason.text = "Out of Time"
    elif reason == "elimination":
        EndReason.text = "Out of Lives"
    elif reason == "team_elimination":
        EndReason.text = "Only One Team Left Standing"

###############################################################################
# Game Event Recording Functions
###############################################################################

func _process(__):
    var easy_day = true
    if events_not_sent.size() > 0:
        send_game_event_to_server(events_not_sent.pop_front())
        easy_day = false
    if rxd_events.size() > 0:
        easy_day = false
        var event_to_sort = rxd_events.pop_front()
        if game_history.size() > 0:
            if not game_history.has(event_to_sort):
                for index in range(game_history.size() - 1, -1, -1):
                    var event = game_history[index]
                    if event_to_sort["client_time"] < event["client_time"]:
                        game_history.insert(index + 1, event_to_sort)
                        break
                    elif event_to_sort["client_time"] == event["client_time"]:
                        if event_to_sort["event_id"] > event["event_id"]:
                            game_history.insert(index + 1, event_to_sort)
                            break
                        elif event_to_sort["event_id"] == event["event_id"]:
                            # Duplication happens, but not as bad as the old system. We may need to return to prevent the processing below.
                            break
                        else:
                            pass  # Sort Further down the list.
        else:
            game_history.append(event_to_sort)
        # Process Alerts
        if game_history.has(event_to_sort):
            if event_to_sort["rec_by"] != Settings.Session.get_data("mup_id"): # We already alert off our own events in real time.
                if near_time(event_to_sort["client_time"]):
                    if event_to_sort["type"] == "fired":
                        GunShotSound.volume_db = -25
                        GunShotSound.play()
                    elif event_to_sort["type"] == "misfired":
                        EmptyShotSound.volume_db = -20
                        EmptyShotSound.play()
                    elif event_to_sort["type"] == "reloading":
                        ReloadSound.volume_db = -20
                        ReloadSound.pitch_scale = 0.45 / event_to_sort["additional"]["reload_speed"]
                        ReloadSound.play()
                    elif event_to_sort["type"] == "died":
                        if event_to_sort["additional"]["laser_id"] == Settings.Session.get_data("game_player_laser_id"):
                            TangoDownSound.play()
                    elif event_to_sort["type"] == "hit":
                        if event_to_sort["additional"]["laser_id"] == Settings.Session.get_data("game_player_laser_id"):
                            if not NiceSound.playing:
                                NiceSound.play()
                if event_to_sort["type"] == "died":
                    if event_to_sort["additional"]["laser_id"] == Settings.Session.get_data("game_player_laser_id"):
                        Settings.Session.set_data("game_player_kills", Settings.Session.get_data("game_player_kills") + 1)
                if event_to_sort["type"] == "eliminated":
                    if event_to_sort["additional"]["laser_id"] == Settings.Session.get_data("game_player_laser_id"):
                        Settings.Session.set_data("game_player_kills", Settings.Session.get_data("game_player_kills") + 1)
                if event_to_sort["type"] == "end_game":
                    if Settings.Session.get_data("game_started") != 3:
                        end_game(event_to_sort["additional"]["reason"])
            if Settings.Session.get_data("mup_id") == "1":  # Server
                if event_to_sort["type"] == "eliminated":
                    var player_team_by_id = Settings.InGame.get_data("player_team_by_id")
                    var elim_player_team = player_team_by_id[event_to_sort["rec_by"]]
                    var player_status_by_id = Settings.InGame.get_data("player_status_by_id")
                    player_status_by_id[event_to_sort["rec_by"]] = "eliminated"
                    Settings.InGame.set_data("player_status_by_id", player_status_by_id)
                    # TODO: Catch if whole team is eliminated. And that there is only 1 remaining team.
                    var team_is_eliminated = true
                    for player in player_team_by_id:
                        if player_team_by_id[player] == elim_player_team:
                            if player_status_by_id[player] != "eliminated":
                                team_is_eliminated = false
                    if team_is_eliminated:
                        var team_status_by_num = Settings.InGame.get_data("game_team_status_by_num")
                        team_status_by_num[elim_player_team] = "eliminated"
                        Settings.InGame.set_data("game_team_status_by_num", team_status_by_num)
                        print(Settings.InGame.get_data("game_team_status_by_num"))
                        var teams_remaining = 0
                        for team in team_status_by_num:
                            if team_status_by_num[team] == "playing":
                                teams_remaining += 1
                        if teams_remaining <= 1:
                            call_deferred("end_game", "team_elimination")
                elif event_to_sort["type"] == "died":
                    var laser_id = event_to_sort["additional"]["laser_id"]
                    var shooter_mup = Settings.InGame.get_data("player_id_by_laser")[laser_id]
                    var victim_mup = event_to_sort["rec_by"]
                    var player_kills_by_id = Settings.InGame.get_data("player_kills_by_id")
                    var player_deaths_by_id = Settings.InGame.get_data("player_deaths_by_id")
                    player_kills_by_id[shooter_mup] = player_kills_by_id[shooter_mup] + 1
                    Settings.InGame.set_data("player_kills_by_id", player_kills_by_id)
                    player_deaths_by_id[victim_mup] = player_deaths_by_id[victim_mup] + 1
                    Settings.InGame.set_data("player_deaths_by_id", player_deaths_by_id)
                elif event_to_sort["type"] == "eliminated":
                    var laser_id = event_to_sort["additional"]["laser_id"]
                    var shooter_mup = Settings.InGame.get_data("player_id_by_laser")[laser_id]
                    var victim_mup = event_to_sort["rec_by"]
                    var player_kills_by_id = Settings.InGame.get_data("player_kills_by_id")
                    var player_deaths_by_id = Settings.InGame.get_data("player_deaths_by_id")
                    player_kills_by_id[shooter_mup] = player_kills_by_id[shooter_mup] + 1
                    Settings.InGame.set_data("player_kills_by_id", player_kills_by_id)
                    player_deaths_by_id[victim_mup] = player_deaths_by_id[victim_mup] + 1
                    Settings.InGame.set_data("player_deaths_by_id", player_deaths_by_id)
                elif event_to_sort["type"] == "hit":
                    pass
    else:
        if easy_day:
            if catch_up_active == false:
                catch_up_clients()

func setup_recording_vars():
    if Settings.Session.get_data("mup_id") != null:  # else: No Network game.
        event_counter = int(Settings.Session.get_data("mup_id")) * 10000
        if Settings.Session.get_data("mup_id") == "1":
            for mup in Settings.Network.get_data("mups_to_peers"):
                server_unackn_events_by_mup[mup] = []
            

func record_game_event(type, additional={}):
    var new_event = event_template.duplicate(true)
    #{"client_time": null, "event_id": null, "type": null, "rec_by": null, "additional": {}}
    # int() Prevents floating point percision errors when passed across the network.
    new_event["client_time"] = int(EventRecordTimer.time_left)
    new_event["event_id"] = event_counter
    event_counter += 1
    new_event["type"] = type
    new_event["additional"] = additional
    new_event["rec_by"] = Settings.Session.get_data("mup_id")
    events_not_sent.append(new_event)

func send_game_event_to_server(event):
    if Settings.Session.get_data("mup_id") != null:  # else: No Network game.
        if Settings.Session.get_data("mup_id") == "1":
            call_deferred("server_rx_game_event_remote", event)
        else:
            if Settings.Session.get_data("connection_status") == "connected":
                rpc_id(1, "server_rx_game_event_remote", event)
        events_not_acknowledged.append(event)
        rxd_events.append(event)
            
remote func server_rx_game_event_remote(event):
    var rpc_sender_id = get_tree().get_rpc_sender_id()
    if rpc_sender_id == 0:
        rpc_sender_id = 1
    Settings.Log("Server: RPC: 'server_rx_game_event_remote( " + str(event) + " )' from sender_id = " + str(rpc_sender_id))
    var sender_mup = Settings.Network.get_data("peers_to_mups")[rpc_sender_id]
    # If we are going to record the server recieved time do it in a seperate array, not on the events.
    #event["server_rec_time"] = EventRecordTimer.time_left
    if event["rec_by"] != "1":
        rxd_events.append(event)
    for mup in server_unackn_events_by_mup:
        if mup != "1":
            if mup != sender_mup:
                server_unackn_events_by_mup[mup].append(event)
    rpc("forwarded_event_remote", event)
        

remote func forwarded_event_remote(event):
    Settings.Log("Client: RPC: MUPID:" + str(Settings.Session.get_data("mup_id")) + 
        " 'forwarded_event_remote( )' event= " + str(event))
    rxd_events.append(event)
    for local_event in events_not_acknowledged:
        if local_event["event_id"] == event["event_id"]:
            events_not_acknowledged.erase(event)
            break
    rpc_id(1, "ack_event_remote", event["event_id"])
            
remote func ack_event_remote(event_id):
    Settings.Log("Server: RPC: MUPID:" + str(Settings.Session.get_data("mup_id")) + 
        " 'ack_event_remote( )' event= " + str(event_id))
    var sender_mup = Settings.Network.get_data("peers_to_mups")[get_tree().get_rpc_sender_id()]
    for event in server_unackn_events_by_mup[sender_mup]:
        if event["event_id"] == event_id:
            server_unackn_events_by_mup[sender_mup].erase(event)
            break
            
func near_time(input):
    return abs(EventRecordTimer.time_left - input) <= 1  # 2 is the currrent delta(min/max) variance allowed.

func catch_up_clients():
    catch_up_active = true
    for mup_id in server_unackn_events_by_mup:
        if server_unackn_events_by_mup[mup_id].size() > 0:
            if Settings.Network.get_data("mups_status")[mup_id] == "reconnected":
                var peer_id = Settings.Network.get_data("mups_to_peers")[mup_id]
                for event in server_unackn_events_by_mup[mup_id]:
                    if peer_id in get_tree().get_network_connected_peers():
                        rpc_id(peer_id, "you_are_missing_this", event)
                        yield(get_tree(), 'idle_frame')
                    else:
                        var mups_status = Settings.Network.get_data("mups_status").duplicate()
                        mups_status[mup_id] = "disconnected"
                        Settings.Network.set_data("mups_status", mups_status)
                        break
    catch_up_active = false

func on_mup_reconnected(mups_reconnected):
    var mup_id = mups_reconnected.pop_front()
    var peer_id = Settings.Network.get_data("mups_to_peers")[mup_id]
    Settings.Session.set_data("mups_reconnected", mups_reconnected, false, false)
    rpc_id(peer_id, "send_unacknowledged_events_remote")

remote func send_unacknowledged_events_remote():
    var rpc_sender_id = get_tree().get_rpc_sender_id()
    Settings.Log("Client: RPC: MUPID:" + str(Settings.Session.get_data("mup_id")) + 
        " 'send_unacknowledged_events( )' from sender_id = " + str(rpc_sender_id))
    events_not_sent = events_not_acknowledged + events_not_sent
    events_not_acknowledged.clear()
        
remote func you_are_missing_this(event):
    Settings.Log("Server: RPC: 'you_are_missing_this( " + str(event) + " )' from sender_id = 1")
    rxd_events.append(event)
    rpc_id(1, "ack_event_remote", event["event_id"])
    
func connection_status_event(new_status):
    if last_connection_status != new_status:
        last_connection_status = new_status
        record_game_event("connection", {"status": new_status})
###############################################################################
# TIMER Functions
###############################################################################

func tick_toc():
    if Settings.Session.get_data("game_started") == 1:
        if Settings.InGame.get_data("game_limit_mode") == "time":
            Settings.Session.set_data("game_tick_toc_time_remaining", Settings.Session.get_data("game_tick_toc_time_remaining") - 1)
        Settings.Session.set_data("game_tick_toc_time_elapsed", Settings.Session.get_data("game_tick_toc_time_elapsed") + 1)
        if not Settings.Session.get_data("game_player_alive"):
            Settings.Session.set_data("game_tick_toc_respawn", Settings.Session.get_data("game_tick_toc_respawn") - 1)
    else:
        Settings.Session.set_data("game_tick_toc_start_delay", Settings.Session.get_data("game_tick_toc_start_delay") - 1)
    
    
func reload_start():
    FreecoiLInterface.reload_start()
    ReloadTimer.start()
    var collect_magazine_ammo = Settings.Session.get_data("game_weapon_magazine_ammo") + Settings.Session.get_data("game_weapon_total_ammo")
    Settings.Session.set_data("game_weapon_total_ammo", collect_magazine_ammo)
    Settings.Session.set_data("game_weapon_magazine_ammo", 0)
    ReloadSound.volume_db = 0
    ReloadSound.pitch_scale = 0.45 / Settings.Session.get_data("game_weapon_reload_speed")
    ReloadSound.play()
    record_game_event("reloading", {"gun": Settings.Session.get_data("game_weapon_type"), 
        "reload_speed": Settings.Session.get_data("game_weapon_reload_speed")})
    
func reload_finish():
    var remove_magazine_ammo = 0
    if Settings.Session.get_data("game_weapon_total_ammo") > Settings.Session.get_data("game_weapon_magazine_size"):
        Settings.Session.set_data("game_weapon_magazine_ammo", Settings.Session.get_data("game_weapon_magazine_size"))
        remove_magazine_ammo = Settings.Session.get_data("game_weapon_total_ammo") - Settings.Session.get_data("game_weapon_magazine_size")
    elif Settings.Session.get_data("game_weapon_total_ammo") == 0:
        Settings.Session.set_data("game_weapon_magazine_ammo", 0)
    else:
        Settings.Session.set_data("game_weapon_magazine_ammo", Settings.Session.get_data("game_weapon_total_ammo"))
    Settings.Session.set_data("game_weapon_total_ammo", remove_magazine_ammo)
    FreecoiLInterface.reload_finish(Settings.Session.get_data("game_weapon_magazine_ammo"))

func eliminated(laser_id):
    FreecoiLInterface.reload_start()
    Settings.Session.set_data("game_player_alive", false)
    record_game_event("eliminated", {"laser_id": laser_id})
    if laser_id != 0:
        var shooter_mup = Settings.InGame.get_data("player_id_by_laser")[laser_id]
        var shooter_name = Settings.InGame.get_data("player_name_by_id")[shooter_mup]
        Settings.Session.set_data("game_player_last_killed_by", shooter_name)
    else:
        Settings.Session.set_data("game_player_last_killed_by", "ID 0")
    Settings.Session.set_data("game_player_deaths", Settings.Session.get_data("game_player_deaths") + 1)
    get_tree().call_group("Container", "next_menu", "2,0")

func respawn_start(laser_id):
    if Settings.Session.get_data("game_started") == 1:
        FreecoiLInterface.reload_start()
        Settings.Session.set_data("game_player_alive", false)
        RespawnTimer.start()
        Settings.Session.set_data("game_tick_toc_respawn", Settings.InGame.get_data("game_respawn_delay"))
        record_game_event("died", {"laser_id": laser_id})
        if laser_id != 0:
            var shooter_mup = Settings.InGame.get_data("player_id_by_laser")[laser_id]
            var shooter_name = Settings.InGame.get_data("player_name_by_id")[shooter_mup]
            Settings.Session.set_data("game_player_last_killed_by", shooter_name)
        else:
            Settings.Session.set_data("game_player_last_killed_by", "ID 0")
        Settings.Session.set_data("game_player_deaths", Settings.Session.get_data("game_player_deaths") + 1)
        get_tree().call_group("Container", "next_menu", "1,0")
    
func respawn_finish():
    if Settings.Session.get_data("game_started") == 1:
        set_player_respawn_vars()
        Settings.Session.set_data("game_player_alive", true)
        record_game_event("alive")
        reload_start()
        get_tree().call_group("Container", "next_menu", "0,0")

func delayed_vibrate():
    FreecoiLInterface.vibrate(200)
    
func hit_indicator_start():
    pass
    
func hit_indicator_stop():
    pass

###############################################################################
# FreecoiL group callback Functions
###############################################################################  
func fi_trigger_btn_pushed(__):
    if Settings.Session.get_data("game_player_alive"):
        if Settings.Session.get_data("game_weapon_magazine_ammo") == 0:
            EmptyShotSound.volume_db = 0
            EmptyShotSound.play()
            record_game_event("misfired", {"gun": Settings.Session.get_data("game_weapon_type")})
        else:
            GunShotSound.volume_db = 0
            GunShotSound.play()
            record_game_event("fired", {"gun": Settings.Session.get_data("game_weapon_type")})
        #else your dead so pass.
            
    
func fi_reload_btn_pushed():
    if Settings.Session.get_data("game_player_alive"):
        reload_start()

func fi_got_shot(laser_id):
    var legit_hit = false
    Settings.Log("Shot By Player ID # " + str(laser_id))
    if laser_id != 0:
        if Settings.Session.get_data("game_player_alive"):
            if Settings.InGame.get_data("game_teams"):
                if Settings.InGame.get_data("game_friendly_fire"):
                    legit_hit = true
                else:
                    if not (laser_id in Settings.Session.get_data("game_player_teammates")):
                        legit_hit = true
    if legit_hit:
        record_game_event("hit", {"laser_id": laser_id})
        Settings.Session.set_data("game_player_health", Settings.Session.get_data("game_player_health") - 1)
        call_deferred("delayed_vibrate")  # Because it was slowing down the processing of shots.
        if Settings.Session.get_data("game_player_health") <= 0:
            if Settings.Session.get_data("game_player_deaths") + 1 == Settings.InGame.get_data("game_death_limit"):
                eliminated(laser_id)
            else:
                respawn_start(laser_id)
    
func fi_power_btn_pushed():
    if FreecoiLInterface.recoil_enabled:
        FreecoiLInterface.enable_recoil(false)
    else:
        FreecoiLInterface.enable_recoil(true)
