extends Control

var reload_timer = Timer.new()
var end_game_timer = Timer.new()
var max_team_id
var min_team_id 
var shot_mode = "single"
var indoor_outdoor_mode
var remaining_time = SetConf.Session.end_game_time_limit + 1
var game_over = false

onready var reload_sound = get_node("Reload")
onready var empty_sound = get_node("EmptyGunShot")
onready var gun_sound = get_node("GunShot")
onready var Deaths = get_node("MainSection/Deaths")
onready var Kills = get_node("MainSection/Kills")
onready var CurrentAmmo = get_node("AmmoSection/CurrentAmmo")
onready var Magazine = get_node("AmmoSection/Magazine")
onready var AmmoBar = get_node("AmmoSection/AmmoBar")
onready var CurrentHealth = get_node("HealthSection/CurrentHealth")
onready var FullHealth = get_node("HealthSection/FullHealth")
onready var HealthBar = get_node("HealthSection/HealthBar")
onready var MyTeamScore = get_node("MainSection/MyTeamScore")
onready var OtherTeamScore = get_node("MainSection/OtherTeamScore")
onready var PlayerNum = get_node("MainSection/PlayerNum")
onready var StatusMessages = get_node("StatusSection/StatusMessages")
onready var Recoil = get_node("HealthSection/Recoil")
onready var StartGamePopup = get_node("StartGamePopup")
onready var RespawnPopup = get_node("RespawnPopup")
onready var EndGamePopup = get_node("EndGamePopup")
onready var RemainingGameTimer = get_node("RemainingGameTimer")
onready var TimeRemaining = get_node("MainSection/TimeRemaining")
onready var TimeRemainingLbl = get_node("MainSection/TimeRemainingLbl")
onready var ShotMode = get_node("AmmoSection/ShotMode")
onready var MainSection = get_node("MainSection")
onready var HitIndicatorTimer = get_node("HitIndicatorTimer")
onready var WaitForPlayers = get_node("WaitForPlayersPopup")

# Called when the node enters the scene tree for the first time.
func _ready():
    WaitForPlayers.popup()
    reset_li_vars()
    add_to_group("lazercoil")
    add_to_group("in_game")
    LazerInterface.set_lazer_id(SetConf.Session.player_id)
    init_shot_mode()
    CurrentAmmo.text = "%03d" % LazerInterface.shots_remaining
    Magazine.text = "%03d" % SetConf.Session.magazine
    AmmoBar.value = 0
    CurrentHealth.text = "%02d" % LazerInterface.current_health
    FullHealth.text = "%03d" % LazerInterface.full_health
    HealthBar.value = LazerInterface.full_health
    Kills.text = "%02d" % LazerInterface.player_kills
    Deaths.text = "%02d" % LazerInterface.player_deaths
    update_recoil()
    li_player_id_changed()
    reload_timer.one_shot = true
    reload_timer.connect("timeout", self, "reload_finish")
    reload_timer.wait_time = LazerInterface.reload_delay
    build_team_filter()
    add_child(reload_timer)
    add_child(end_game_timer)
    respawn_start(0)
    LazerInterface.enable_recoil(false)
    call_deferred("defered_send_ready")
    
func defered_send_ready():
    # We defer calling ready to let a frame go by and make sure everything is finished.
    NetworkingCode.tell_server_i_am_ready()
    
func reset_li_vars():
    LazerInterface.current_health = 0
    LazerInterface.player_deaths = 0
    LazerInterface.player_kills = 0
    
###############################################################################
# TIMER Functions
###############################################################################
func reload_start():
    LazerInterface.reload_start()
    reload_timer.start()
    CurrentAmmo.text = "000"
    reload_sound.play()
    
func reload_finish():
    LazerInterface.reload_finish()
    CurrentAmmo.text = "%03d" % SetConf.Session.magazine
    AmmoBar.value = SetConf.Session.magazine

func respawn_start(shooter_id):
    LazerInterface.is_player_alive = false
    LazerInterface.reload_start()
    StatusMessages.text = "Reload Start Called, should not be able to shot.\n" + StatusMessages.text
    CurrentAmmo.text = str("000")
    AmmoBar.value = 0
    if shooter_id > 0:
        # Killed By shooter_id
        LazerInterface.player_deaths += 1
        NetworkingCode.record_game_event("killed", [shooter_id, LazerInterface.player_deaths])
        Deaths.text = "%02d" % LazerInterface.player_deaths
        if SetConf.Session.end_game == "deaths":
            if LazerInterface.player_deaths == SetConf.Session.end_game_death_limit:
                end_game("LIVES!")
                NetworkingCode.record_game_event("end_game", ["lives"])
            else:
                RespawnPopup.popup()
        else:
            RespawnPopup.popup()
    elif shooter_id == 0:
        pass  # Start Game Popup
    else:  # shooter_id = -1
        pass  # End of Game if shooter_id = -1
    
func respawn_finish():
    LazerInterface.current_health = LazerInterface.full_health
    HealthBar.value = LazerInterface.current_health
    CurrentHealth.text = "%03d" % LazerInterface.current_health
    LazerInterface.is_player_alive = true
    reload_sound.play()
    reload_finish()
    NetworkingCode.record_game_event("reloaded", [])

###############################################################################
# lazercoil group callback Functions
###############################################################################  
func li_trigger_btn_pushed():
    if LazerInterface.shots_remaining == 0:
            empty_sound.play()
            
    
func li_reload_btn_pushed():
    if LazerInterface.is_player_alive:
        reload_start()

func li_got_shot(shooter_id):
    # We vibrate here just to make the player aware they are being shot 
    # It gives them a chance to shout "I'm Dead."
    var legit_hit = false
    StatusMessages.text = "Shot By Player ID # " + str(shooter_id) + "\n" + StatusMessages.text
    call_deferred("delayed_vibrate")  # Because it was slowing down the processing of shots.
    if shooter_id != 0:  # Don't register shots from Player Id 0.
        if SetConf.Session.teams:  # Team Match
            # Don't get shot by your own team.
            if shooter_id > max_team_id or shooter_id < min_team_id:
                if LazerInterface.is_player_alive:
                    legit_hit = true
        else:  # Free For All
            if LazerInterface.is_player_alive:
                legit_hit = true    
    if legit_hit:
        LazerInterface.current_health -= 1
        NetworkingCode.record_game_event("got_shot", [shooter_id, LazerInterface.current_health])
        HealthBar.value = LazerInterface.current_health
        CurrentHealth.text = "%03d" % LazerInterface.current_health
        if LazerInterface.current_health <= 0:
            respawn_start(shooter_id)
        MainSection.self_modulate = Color("e01010")
        HitIndicatorTimer.start()

func li_player_id_changed():
    PlayerNum.text = "Player # " + str(SetConf.Session.player_number)
    StatusMessages.text = "Self Player ID Set as ID # " + str(SetConf.Session.player_id) + "\n" + StatusMessages.text
    
func li_shots_remaining_changed():
    if LazerInterface.is_player_alive:
        if LazerInterface.shots_remaining == SetConf.Session.magazine:
            pass
        elif LazerInterface.shots_remaining == 0:
            pass
        else:
            NetworkingCode.record_game_event("shooting", [LazerInterface.shots_remaining])
            gun_sound.play()
        CurrentAmmo.text = "%03d" % LazerInterface.shots_remaining
        AmmoBar.value = LazerInterface.shots_remaining
    
func li_recoil_enabled_changed():
    update_recoil()
    
func li_thumb_btn_pushed():
    set_shot_mode()
    
func li_power_btn_pushed():
    if LazerInterface.recoil_enabled:
        LazerInterface.enable_recoil(false)
    else:
        LazerInterface.enable_recoil(true)

# li_battery_lvl_changed

###############################################################################
# In Game Functions
###############################################################################
func build_team_filter():
    max_team_id = SetConf.Session.player_team * LazerInterface.players_per_team
    min_team_id = max_team_id - LazerInterface.players_per_team + 1

func update_recoil():
    if LazerInterface.recoil_enabled:
        Recoil.text = "Recoil: Enabled"
    else:
        Recoil.text = "Recoil: Disabled"
    
func update_remaining_time():
    remaining_time -= 1
    var minutes = remaining_time / 60
    var seconds = remaining_time - minutes * 60
    TimeRemaining.text = "%02d" % minutes + ":" + "%02d" % seconds
    RemainingGameTimer.start()
    
func _on_HitIndicatorTimer_timeout():
    MainSection.self_modulate = Color("ffffff")
    HitIndicatorTimer.stop()
    
func set_shot_mode():
    if shot_mode == "single":
        if SetConf.Session.burst_3_allowed:
            shot_mode = "burst"
        elif SetConf.Session.full_auto_allowed:
            shot_mode = "auto"
        # else: pass
    elif shot_mode == "burst":
        if SetConf.Session.full_auto_allowed:
            shot_mode = "auto"
        elif SetConf.Session.semi_auto_allowed:
            shot_mode = "single"
        # else: pass
    elif shot_mode == "auto":
        if SetConf.Session.semi_auto_allowed:
            shot_mode = "single"
        elif SetConf.Session.burst_3_allowed:
            shot_mode = "burst"
    update_shot_mode()

func init_shot_mode():
    if SetConf.Session.semi_auto_allowed:
        shot_mode = "single"
    elif SetConf.Session.burst_3_allowed:
        shot_mode = "burst"
    elif SetConf.Session.full_auto_allowed:
        shot_mode = "auto" 
    indoor_outdoor_mode = SetConf.Session.indoor_outdoor_mode
    update_shot_mode()

func update_shot_mode():
    LazerInterface.set_shot_mode(shot_mode, indoor_outdoor_mode)
    if shot_mode == "auto":
        ShotMode.text = "Shot Mode: Full-Auto"
    elif shot_mode == "single":
        ShotMode.text = "Shot Mode: Semi-Auto"
    else:
        ShotMode.text = "Shot Mode: 3-Round Burst"
    
func delayed_vibrate():
    LazerInterface.vibrate(150)  # May want to bump it up to 250.
    
###############################################################################
# Popup Functions
###############################################################################
func ig_respawn_player():
    if not game_over:  # A guard against dying then End Game Time then you respawn.
        respawn_finish()
    
func ig_start_game():
    if SetConf.Session.end_game == "time":
        update_remaining_time()
        end_game_timer.one_shot = true
        end_game_timer.wait_time = SetConf.Session.end_game_time_limit
        TimeRemainingLbl.visible = true
        TimeRemaining.visible = true
        end_game_timer.connect("timeout", self, "end_game", ["TIME!"])
        RemainingGameTimer.connect("timeout", self, "update_remaining_time")
        end_game_timer.start()
        RemainingGameTimer.start()
        HitIndicatorTimer.start()
    respawn_finish()
    
func ig_all_players_ready():
    WaitForPlayers.hide()
    StartGamePopup.popup()

func end_game(reason):
    EndGamePopup.popup()
    EndGamePopup.add_reason(reason)
    game_over = true
    respawn_start(-1)
