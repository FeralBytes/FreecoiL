
extends Node
# Declaring String that contains the default paths
signal Saved_changed
signal Network_changed

const user_dir = "user://"
const res_dir = "res://"
const settings_path = user_dir + "settings.cfg"
const VERSION = "0.2.1-rc1"

# 0 : File didn't open
# 1 : File open
enum {LOAD_ERROR_COULDNT_OPEN, LOAD_SUCCESS}


var config = ConfigFile.new()
var save_thread = null
var extra_save = false
var Session

func _ready():
    #Check if settingSaved.ini exist if not create a new one with the default Settings
    Session = SessData.new()
    if _load_Settings() == LOAD_ERROR_COULDNT_OPEN :
        save()
    #_apply_Settings()

func _load_Settings():
    # Check for error if true exist the function else parse the file and load the config settings into Settings
    var error = config.load(settings_path)
    if error != OK:
        print("Error loading the settings. Error code: %s" % error)
        return LOAD_ERROR_COULDNT_OPEN
    for section in Saved.keys():
        for key in Saved[section]:
            var val = config.get_value(section,key)
            if val == null:
                print("SetConf: Error: _load_Settings(): Couldn't find: ", section, " -> ", key)
            if section == "SetConf":
                if key == "setconf_version":
                    if val != Saved.SetConf.setconf_version:
                        print("Previous SetConf version does not match current default. Will overwrite Settings.conf")
                        return LOAD_ERROR_COULDNT_OPEN
            if section == "QuickStart":  # This lets us ensure loaded settings are put in both places.
                funcref(Session, "set_" + key).call_func(val) 
            else:  # This prevents Saved being set twice while we are doing the QuickStart Section.
                Saved[section][key] = val
    return LOAD_SUCCESS

# Save the Settings into the config file if the config file dosen't exist create a new one
func save():
    if save_thread == null:
        save_thread = Thread.new()
        call_deferred("_deferred_save")
    else:
        extra_save = true
            
func _deferred_save():
    save_thread.start(self, "_threaded_save")
    
func _threaded_save(not_used):
    not_used = null
    for section in Saved.keys():
        for key in Saved[section]:
            config.set_value(section,key,Saved[section][key])
    config.save(settings_path)
    call_deferred("_call_cleanup")
    
func _call_cleanup():
    call_deferred("_cleanup_thread")
    
func _cleanup_thread():
    save_thread.wait_to_finish()
    save_thread = null
    if extra_save:
        extra_save = false
        save()

func _apply_Settings():
    # Check out the documentation about :
    # OS class : http://docSaved.godotengine.org/en/3.0/classes/class_oSaved.html
    # Engine class : http://docSaved.godotengine.org/en/3.0/classes/class_engine.html
    # for this case i only use OS to change the resolution,fullscreen and Vsync 
    Saved.window_size = Vector2(Saved.Display.WIDTH,Saved.Display.HEIGHT)
    Saved.window_fullscreen = Saved.Display.FullScreen
    Saved.vsync_enabled = Saved.Display.Vsync

func update_Settings(H,W,Full,Audio,Mute,Vsync):
    Saved.Display.Height = H
    Saved.Display.Width = W
    Saved.Display.FullScreen = Full
    Saved.Display.Vsync = Vsync
    Saved.Audio.Speech = Audio.x
    Saved.Audio.Music = Audio.y
    Saved.Audio.SoundEffects = Audio.z
    Saved.Audio.Mute = Mute
    #Saving the file than applying it
    #_apply_Settings()
    
####################################################
# SetConf.Saved
var Saved = {
    "SetConf":
    {
        "setconf_version": 3,
    },
    "Display": 
    {
        "Height" : 960,
        "Width" : 540,
        "FullScreen": 2,  # 2 means not set, dont' use null.
        "Vsync": 2
    },
    "Audio":
    {
        "Mute" : false,
        "Music": 100,
        "Speech": 100,
        "SoundEffects": 100
    },
    "ColorTheme":
    {
        "Name" : "Default",
        "Path": 2,
        "Text": "ffffff",
        "Background": "000000",
        "Sectionals": "94843B",
        "WidgetBackgrounds": "6799b2",
        "SuccessNotification": "63a966",
        "WarningAlert" : "e0992e",
        "CriticalAlert" : "f44336"
    },
    "LazercoilDefaults":
    {
        "Speech": 100,
        "SoundEffects": 100
    },
    "LazercoilPreferences":
    {
        "PlayerName": ""
    },
    "QuickStart":
    {
        "game_type": "NoNetwork",
        "teams": true,
        "host": false,
        "num_of_teams": 2,
        "player_team": 1,
        "player_number": 1,
        "player_name": "",
        "player_id": 1,
        "recoil_enabled": true,
        "starting_ammo": 99999999,
        "magazine": 30,  # This equals a single reload. Max = 253
        "end_game": "time",
        "end_game_death_limit": 5,
        "end_game_time_limit": 600, # in seconds
        "start_delay": 5,
        "respawn_delay": 10,
        "quick_start_complete": false,
        "semi_auto_allowed": true,
        "burst_3_allowed": true,
        "full_auto_allowed": true,
        "indoor_outdoor_mode": "indoor_no_cone",
        "server_ip": "127.0.0.1",
        "server_port": 8808,
        "team_colors":
        [
            "0000ff",  # Blue
            "ff0000"   # Red
        ]
    }
} setget set_Saved, get_Saved

func get_Saved():
    return Saved
    
func set_Saved(new_val):
    Saved = new_val
    save()
    emit_signal("Saved_changed")

####################################################
# SetConf.Network
var Network = {
    "connected": false
} setget set_Network, get_Network

func get_Network():
    return Network
    
func set_Network(new_val):
    Network = new_val
    emit_signal("Network_changed")

####################################################
# SetConf.Session
class SessData:
    signal Session_game_type_changed
    signal Session_teams_changed
    signal Session_host_changed
    signal Session_num_of_teams_changed
    signal Session_player_team_changed
    signal Session_player_number_changed
    signal Session_player_name_changed
    signal Session_player_id_changed
    signal Session_recoil_enabled_changed
    signal Session_starting_ammo_changed
    signal Session_magazine_changed
    signal Session_end_game_changed
    signal Session_end_game_death_limit_changed
    signal Session_end_game_time_limit_changed
    signal Session_start_delay_changed
    signal Session_respawn_delay_changed
    signal Session_quick_start_complete_changed
    signal Session_semi_auto_allowed_changed
    signal Session_burst_3_allowed_changed
    signal Session_full_auto_allowed_changed
    signal Session_indoor_outdoor_mode_changed
    signal Session_team_colors_changed
    signal Session_battery_lvl_changed
    signal Session_connected_to_host_status_changed
    signal Session_server_ip_changed
    signal Session_server_port_changed
    signal Session_testing_active_changed
    
    var game_type = "NoNetwork" setget set_game_type, get_game_type
    var teams = true setget set_teams, get_teams
    var host = false setget set_host, get_host 
    var num_of_teams = 2 setget set_num_of_teams, get_num_of_teams
    var player_team = 0 setget set_player_team, get_player_team
    var player_number = 0 setget set_player_number, get_player_number
    var player_name = "" setget set_player_name, get_player_name
    var player_id = 0 setget set_player_id, get_player_id
    var recoil_enabled = false setget set_recoil_enabled, get_recoil_enabled
    var starting_ammo = 99999999 setget set_starting_ammo, get_starting_ammo
    var magazine = 30 setget set_magazine, get_magazine
    var end_game = "time" setget set_end_game, get_end_game
    var end_game_death_limit = null setget set_end_game_death_limit, get_end_game_death_limit
    var end_game_time_limit = 600 setget set_end_game_time_limit, get_end_game_time_limit
    var start_delay = 15 setget set_start_delay, get_start_delay 
    var respawn_delay = 30 setget set_respawn_delay, get_respawn_delay 
    var quick_start_complete = false setget set_quick_start_complete, get_quick_start_complete
    var semi_auto_allowed = true setget set_semi_auto_allowed, get_semi_auto_allowed
    var burst_3_allowed = true setget set_burst_3_allowed, get_burst_3_allowed
    var full_auto_allowed = true setget set_full_auto_allowed, get_full_auto_allowed
    var indoor_outdoor_mode = "indoor_no_cone" setget set_indoor_outdoor_mode, get_indoor_outdoor_mode
    var team_colors = ["0000ff", "ff0000" ] setget set_team_colors, get_team_colors
    var battery_lvl = 0 setget set_battery_lvl, get_battery_lvl
    # Unconnected -> Connecting -> Connected -> Disconnected -> Reconnecting -> Reconnected -> Connected (Loop to Disconnected)
    var connected_to_host_status = "Unconnected" setget set_connected_to_host_status, get_connected_to_host_status
    var server_ip = "127.0.0.1" setget set_server_ip, get_server_ip
    var server_port = 8808 setget set_server_port, get_server_port
    var testing_active = false setget set_testing_active, get_testing_active

    func get_game_type():
        return game_type

    func set_game_type(new_val):
        game_type = new_val
        emit_signal("Session_game_type_changed")
        SetConf.Saved.QuickStart.game_type = new_val

    func get_teams():
        return teams

    func set_teams(new_val):
        teams = new_val
        emit_signal("Session_teams_changed")
        SetConf.Saved.QuickStart.teams = new_val
    
    func get_host():
        return host

    func set_host(new_val):
        host = new_val
        emit_signal("Session_host_changed")
        SetConf.Saved.QuickStart.host = new_val

    func get_num_of_teams():
        return num_of_teams

    func set_num_of_teams(new_val):
        num_of_teams = new_val
        emit_signal("Session_num_of_teams_changed")
        SetConf.Saved.QuickStart.num_of_teams = new_val

    func get_player_team():
        return player_team

    func set_player_team(new_val):
        player_team = new_val
        emit_signal("Session_player_team_changed")
        SetConf.Saved.QuickStart.player_team = new_val

    func get_player_number():
        return player_number

    func set_player_number(new_val):
        player_number = new_val
        emit_signal("Session_player_number_changed")
        SetConf.Saved.QuickStart.player_number = new_val

    func get_player_name():
        return player_name

    func set_player_name(new_val):
        player_name = new_val
        emit_signal("Session_player_name_changed")
        SetConf.Saved.QuickStart.player_name = new_val

    func get_player_id():
        return player_id

    func set_player_id(new_val):
        player_id = new_val
        emit_signal("Session_player_id_changed")
        SetConf.Saved.QuickStart.player_id = new_val

    func get_recoil_enabled():
        return recoil_enabled

    func set_recoil_enabled(new_val):
        recoil_enabled = new_val
        emit_signal("Session_recoil_enabled_changed")
        SetConf.Saved.QuickStart.recoil_enabled = new_val

    func get_starting_ammo():
        return starting_ammo

    func set_starting_ammo(new_val):
        starting_ammo = new_val
        emit_signal("Session_starting_ammo_changed")
        SetConf.Saved.QuickStart.starting_ammo = new_val

    func get_magazine():
        return magazine

    func set_magazine(new_val):
        magazine = new_val
        emit_signal("Session_magazine_changed")
        SetConf.Saved.QuickStart.magazine = new_val

    func get_end_game():
        return end_game

    func set_end_game(new_val):
        end_game = new_val
        emit_signal("Session_end_game_changed")
        SetConf.Saved.QuickStart.end_game = new_val

    func get_end_game_death_limit():
        return end_game_death_limit

    func set_end_game_death_limit(new_val):
        end_game_death_limit = new_val
        emit_signal("Session_end_game_death_limit_changed")
        SetConf.Saved.QuickStart.end_game_death_limit = new_val

    func get_end_game_time_limit():
        return end_game_time_limit

    func set_end_game_time_limit(new_val):
        end_game_time_limit = new_val
        emit_signal("Session_end_game_time_limit_changed")
        SetConf.Saved.QuickStart.end_game_time_limit = new_val

    func get_start_delay():
        return start_delay

    func set_start_delay(new_val):
        start_delay = new_val
        emit_signal("Session_start_delay_changed")
        SetConf.Saved.QuickStart.start_delay = new_val

    func get_respawn_delay():
        return respawn_delay

    func set_respawn_delay(new_val):
        respawn_delay = new_val
        emit_signal("Session_respawn_delay_changed")
        SetConf.Saved.QuickStart.respawn_delay = new_val

    func get_quick_start_complete():
        return quick_start_complete

    func set_quick_start_complete(new_val):
        quick_start_complete = new_val
        emit_signal("Session_quick_start_complete_changed")
        SetConf.Saved.QuickStart.quick_start_complete = new_val

    func get_semi_auto_allowed():
        return semi_auto_allowed

    func set_semi_auto_allowed(new_val):
        semi_auto_allowed = new_val
        emit_signal("Session_semi_auto_allowed_changed")
        SetConf.Saved.QuickStart.semi_auto_allowed = new_val

    func get_burst_3_allowed():
        return burst_3_allowed

    func set_burst_3_allowed(new_val):
        burst_3_allowed = new_val
        emit_signal("Session_burst_3_allowed_changed")
        SetConf.Saved.QuickStart.burst_3_allowed = new_val

    func get_full_auto_allowed():
        return full_auto_allowed

    func set_full_auto_allowed(new_val):
        full_auto_allowed = new_val
        emit_signal("Session_full_auto_allowed_changed")
        SetConf.Saved.QuickStart.full_auto_allowed = new_val

    func get_indoor_outdoor_mode():
        return indoor_outdoor_mode

    func set_indoor_outdoor_mode(new_val):
        indoor_outdoor_mode = new_val
        emit_signal("Session_indoor_outdoor_mode_changed")
        SetConf.Saved.QuickStart.indoor_outdoor_mode = new_val

    func get_team_colors():
        return team_colors

    func set_team_colors(new_val):
        team_colors = new_val
        emit_signal("Session_team_colors_changed")
        SetConf.Saved.QuickStart.team_colors = new_val

    func get_battery_lvl():
        return battery_lvl

    func set_battery_lvl(new_val):
        battery_lvl = new_val
        emit_signal("Session_battery_lvl_changed")

    func get_connected_to_host_status():
        return connected_to_host_status

    func set_connected_to_host_status(new_val):
        connected_to_host_status = new_val
        emit_signal("Session_connected_to_host_status_changed")

    func get_server_ip():
        return server_ip

    func set_server_ip(new_val):
        server_ip = new_val
        emit_signal("Session_server_ip_changed")
        SetConf.Saved.QuickStart.server_ip = new_val

    func get_server_port():
        return server_port

    func set_server_port(new_val):
        server_port = new_val
        emit_signal("Session_server_port_changed")
        SetConf.Saved.QuickStart.server_port = new_val

    func get_testing_active():
        return testing_active

    func set_testing_active(new_val):
        testing_active = new_val
        emit_signal("Session_testing_active_changed")
