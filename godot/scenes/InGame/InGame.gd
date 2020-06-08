extends Control

var game_over = false

onready var ReloadSound = get_node("ReloadSound")
onready var EmptyShotSound = get_node("EmptyShotSound")
onready var GunShotSound = get_node("GunShotSound")
onready var HitIndicatorTimer = get_node("HitIndicatorTimer")
onready var TimeRemainingTimer = get_node("TimeRemainingTimer")
onready var RespawnTimer = get_node("RespawnDelayTimer")
onready var StartGameTimer = get_node("StartGamedelayTimer")
onready var ReloadTimer = get_node("ReloadTimer")
onready var TickTocTimer = get_node("TickTocTimer")
onready var EndReason = get_node("0,1-End of Game/CenterContainer/VBoxContainer/EndReason")
onready var FastGunShot = get_node("GunShotSound").stream


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
        invert_mups_to_lasers(Settings.InGame.get_data("player_laser_by_id"))
    add_to_group("FreecoiL")
    get_tree().call_group("Container", "next_menu", "0,-1")
    FreecoiLInterface.set_laser_id(Settings.InGame.get_data("player_laser_by_id")[Settings.Session.get_data("mup_id")])
    set_player_start_game_vars()
    get_tree().call_group("Network", "tell_server_i_am_ready", true)


func set_player_start_game_vars():
    set_player_respawn_vars()
    Settings.Session.set_data("game_player_alive", false)
    Settings.Session.set_data("game_tick_toc_start_delay", Settings.InGame.get_data("game_start_delay"))
    Settings.Session.set_data("game_tick_toc_time_remaining", Settings.InGame.get_data("game_time_limit"))
    Settings.Session.set_data("game_tick_toc_respawn", Settings.InGame.get_data("game_respawn_delay"))
    Settings.Session.set_data("game_tick_toc_time_elapsed", 0)
    Settings.Session.set_data("game_started", false)
    Settings.Session.set_data("game_player_team", Settings.InGame.get_data("player_team_by_id")[Settings.Session.get_data("mup_id")])
    Settings.Session.set_data("game_player_teammates", Settings.InGame.get_data("game_teams_by_team_num_by_id")[Settings.Session.get_data("game_player_team")])
    Settings.Session.set_data("game_player_last_killed_by", "")
    StartGameTimer.wait_time = Settings.InGame.get_data("game_start_delay")
    StartGameTimer.connect("timeout", self, "start_the_game")
    StartGameTimer.one_shot = true
    ReloadTimer.wait_time = Settings.Session.get_data("game_weapon_reload_speed")
    ReloadTimer.connect("timeout", self, "reload_finish")
    ReloadTimer.one_shot = true
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
    Settings.Session.set_data("game_player_alive", true)
    
func start_game_start_delay(__):
    if get_tree().is_network_server():
        get_tree().call_group("Network", "unready_all_mups")
        yield(get_tree().create_timer(0.2), "timeout")  # Just to let the network settle out.
        rpc("remote_start_game_start_delay")
    
remotesync func remote_start_game_start_delay():
    TickTocTimer.start()
    StartGameTimer.start()
    get_tree().call_group("Container", "next_menu", "-1,-1")
    
func start_the_game():
    Settings.Session.set_data("game_started", true)
    TimeRemainingTimer.start()
    get_tree().call_group("Container", "next_menu", "0,0")
    respawn_finish()
    
func back_to_Playing():
    pass
    
func end_game(reason):
    Settings.Session.set_data("game_player_alive", false)
    FreecoiLInterface.reload_start()
    get_tree().call_group("Container", "next_menu", "0,1")
    if reason == "time":
        EndReason.text = "Out of Time"

###############################################################################
# TIMER Functions
###############################################################################

func tick_toc():
    if Settings.Session.get_data("game_started"):
        Settings.Session.set_data("game_tick_toc_time_remaining", Settings.Session.get_data("game_tick_toc_time_remaining") - 1)
        Settings.Session.set_data("game_tick_toc_time_elapsed", Settings.Session.get_data("game_tick_toc_time_elapsed") + 1)
        if not Settings.Session.get_data("player_alive"):
            Settings.Session.set_data("game_tick_toc_respawn", Settings.Session.get_data("game_tick_toc_respawn") - 1)
    else:
        Settings.Session.set_data("game_tick_toc_start_delay", Settings.Session.get_data("game_tick_toc_start_delay") - 1)
    
    
func reload_start():
    FreecoiLInterface.reload_start()
    ReloadTimer.start()
    var collect_magazine_ammo = Settings.Session.get_data("game_weapon_magazine_ammo") + Settings.Session.get_data("game_weapon_total_ammo")
    Settings.Session.set_data("game_weapon_total_ammo", collect_magazine_ammo)
    Settings.Session.set_data("game_weapon_magazine_ammo", 0)
    ReloadSound.pitch_scale = 0.5 / Settings.Session.get_data("game_weapon_reload_speed")
    ReloadSound.play()
    
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

func respawn_start(shooter_id):
    Settings.Session.set_data("game_player_alive", false)
    RespawnTimer.start()
    FreecoiLInterface.reload_start()
    Settings.Session.set_data("game_tick_toc_respawn", Settings.InGame.get_data("game_respawn_delay"))
    if shooter_id != 0:
        var shooter_mup = Settings.InGame.get_data("player_id_by_laser")[shooter_id]
        var shooter_name = Settings.InGame.get_data("player_name_by_id")[shooter_mup]
        Settings.Session.set_data("game_player_last_killed_by", shooter_name)
    else:
        Settings.Session.set_data("game_player_last_killed_by", "ID 0")
    get_tree().call_group("Container", "next_menu", "1,0")
    
func respawn_finish():
    set_player_respawn_vars()
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
func fi_trigger_btn_pushed():
    if Settings.Session.get_data("game_weapon_magazine_ammo") == 0:
        EmptyShotSound.play()
    else:
        if Settings.Session.get_data("game_player_alive"):
            GunShotSound.play()
        #else your dead so pass.
            
    
func fi_reload_btn_pushed():
    if Settings.Session.get_data("game_player_alive"):
        reload_start()

func fi_got_shot(shooter_id):
    # We vibrate here just to make the player aware they are being shot 
    # It gives them a chance to shout "I'm Dead."
    var legit_hit = false
    Settings.Log("Shot By Player ID # " + str(shooter_id))
    if shooter_id != 0:
        if Settings.Session.get_data("game_player_alive"):
            if Settings.InGame.get_data("game_teams"):
                if Settings.InGame.get_data("game_friendly_fire"):
                    legit_hit = true
                else:
                    if not (shooter_id in Settings.Session.get_data("game_player_teammates")):
                        legit_hit = true
    if legit_hit:
        Settings.Session.set_data("game_player_health", Settings.Session.get_data("game_player_health") - 1)
        call_deferred("delayed_vibrate")  # Because it was slowing down the processing of shots.
        if Settings.Session.get_data("game_player_health") <= 0:
            respawn_start(shooter_id)
    
func fi_power_btn_pushed():
    if FreecoiLInterface.recoil_enabled:
        FreecoiLInterface.enable_recoil(false)
    else:
        FreecoiLInterface.enable_recoil(true)
