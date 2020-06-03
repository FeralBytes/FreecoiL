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


# Called when the node enters the scene tree for the first time.
func _ready():
    if get_tree().is_network_server():
        Settings.Session.connect(Settings.Session.monitor_data("all_ready"), self, "start_game_start_delay")
    add_to_group("FreecoiL")
    get_tree().call_group("Container", "next_menu", "0,-1")
    FreecoiLInterface.set_laser_id(Settings.InGame.get_data("player_laser_by_id")[Settings.Session.get_data("mup_id")])
    set_player_respawn_vars()
    get_tree().call_group("Network", "tell_server_i_am_ready", true)


func set_player_respawn_vars():
    var weapon_type = Settings.InGame.get_data("game_start_weapon_type")
    Settings.Session.set_data("game_weapon_type", weapon_type)
    Settings.Session.set_data("game_weapon_damage", Settings.InGame.get_data("game_weapon_types")[weapon_type]["damage"])
    Settings.Session.set_data("game_weapon_shot_modes", Settings.InGame.get_data("game_weapon_types")[weapon_type]["shot_modes"])
    Settings.Session.set_data("game_weapon_shot_mode", Settings.Session.get_data("game_weapon_shot_modes")[0])
    Settings.Session.set_data("game_weapon_magazine_size", Settings.InGame.get_data("game_weapon_types")[weapon_type]["magazine_size"])
    Settings.Session.set_data("game_weapon_magazine_ammo", Settings.Session.get_data("game_weapon_magazine_size"))
    Settings.Session.set_data("game_player_health", Settings.InGame.get_data("game_start_health"))
    Settings.Session.set_data("game_player_alive", false)
    Settings.Session.set_data("game_player_ammo", Settings.InGame.get_data("game_start_ammo"))
    Settings.Session.set_data("game_weapon_total_ammo", Settings.Session.get_data("game_player_ammo")[weapon_type])
    Settings.Session.set_data("game_weapon_reload_speed", Settings.InGame.get_data("game_weapon_types")[weapon_type]["reload_speed"])
    Settings.Session.set_data("game_weapon_rate_of_fire", Settings.InGame.get_data("game_weapon_types")[weapon_type]["rate_of_fire"])
    Settings.Session.set_data("game_tick_toc_start_delay", Settings.InGame.get_data("game_start_delay"))
    Settings.Session.set_data("game_tick_toc_time_remaining", Settings.InGame.get_data("game_time_limit"))
    Settings.Session.set_data("game_tick_toc_respawn", Settings.InGame.get_data("game_respawn_delay"))
    Settings.Session.set_data("game_tick_toc_time_elapsed", 0)
    Settings.Session.set_data("game_started", false)
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
    
func start_game_start_delay(__):
    if get_tree().is_network_server():
        get_tree().call_group("Network", "unready_all_mups")
        rpc("remote_start_game_start_delay")
    
remotesync func remote_start_game_start_delay():
    TickTocTimer.start()
    StartGameTimer.start()
    get_tree().call_group("Container", "next_menu", "1,-1")
    
func start_the_game():
    Settings.Session.set_data("game_started", true)
    TimeRemainingTimer.start()
    get_tree().call_group("Container", "next_menu", "0,0")
    respawn_finish()
    
func back_to_Playing():
    pass
    
func end_game(reason):
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
    Settings.Session.set_data("game_weapon_magazine_ammo", 0)
    ReloadSound.pitch_scale = 0.5 / Settings.Session.get_data("game_weapon_reload_speed")
    ReloadSound.play()
    
func reload_finish():
    if Settings.Session.get_data("game_weapon_total_ammo") > Settings.Session.get_data("game_weapon_magazine_size"):
        Settings.Session.set_data("game_weapon_magazine_ammo", Settings.Session.get_data("game_weapon_magazine_size"))
    elif Settings.Session.get_data("game_weapon_total_ammo") == 0:
        Settings.Session.set_data("game_weapon_magazine_ammo", 0)
    else:
        Settings.Session.set_data("game_weapon_magazine_ammo", Settings.Session.get_data("game_weapon_total_ammo"))
    FreecoiLInterface.reload_finish(Settings.Session.get_data("game_weapon_magazine_ammo"))

func respawn_start(shooter_id):
    FreecoiLInterface.is_player_alive = false
    Settings.Session.get_data("game_player_alive", false)
    FreecoiLInterface.reload_start()
    
func respawn_finish():
    FreecoiLInterface.current_health = FreecoiLInterface.full_health
    FreecoiLInterface.is_player_alive = true
    Settings.Session.get_data("game_player_alive", true)
    reload_start()

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
    if FreecoiLInterface.shots_remaining == 0:
        EmptyShotSound.play()
    else:
        GunShotSound.play()
            
    
func fi_reload_btn_pushed():
    if FreecoiLInterface.is_player_alive:
        reload_start()

func fi_got_shot(shooter_id):
    # We vibrate here just to make the player aware they are being shot 
    # It gives them a chance to shout "I'm Dead."
    var legit_hit = false
    Settings.Log("Shot By Player ID # " + str(shooter_id))
    call_deferred("delayed_vibrate")  # Because it was slowing down the processing of shots.
    
func fi_shots_remaining_changed():
    if FreecoiLInterface.is_player_alive:
        if FreecoiLInterface.shots_remaining == Settings.Session.get_data("game_weapon_magazine_size"):
            pass
        elif FreecoiLInterface.shots_remaining == 0:
            pass
        else:
            pass
    
func fi_power_btn_pushed():
    if FreecoiLInterface.recoil_enabled:
        FreecoiLInterface.enable_recoil(false)
    else:
        FreecoiLInterface.enable_recoil(true)
