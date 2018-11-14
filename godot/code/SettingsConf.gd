
extends Node
# Declaring String that contains the default paths
signal S_changed

const user_dir = "user://"
const res_dir = "res://"
const settings_path = user_dir + "settings.cfg"
const VERSION = "0.2.0-alpha"

# 0 : File didn't open
# 1 : File open
enum {LOAD_ERROR_COULDNT_OPEN, LOAD_SUCCESS}


var config = ConfigFile.new()
var save_thread = null

# A Dictionnary is very handy in this situation :
# Default Settings
var S = {
    "SettingsConf":
    {
        "version": 1
    },
    "Display": 
    {
        "Height" : 960,
        "Width" : 540,
        "FullScreen": null,
        "Vsync": null
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
        "Path": null,
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
        "type": "NoNetwork",
        "teams": true,
        "host": false,
        "num_of_teams": 2,
        "player_team": 1,
        "player_number": 1,
        "player_name": null,
        "player_id": 1,
        "recoil_enabled": true,
        "starting_ammo": null,
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
        "TeamColors":
        [
            "0000ff",  # Blue
            "ff0000"   # Red
        ]
    },
    "testing": 
    {
        "test": false
    }
} setget set_S, get_S

func _ready():
    #Check if settings.ini exist if not create a new one with the default Settings
    if _load_Settings() == LOAD_ERROR_COULDNT_OPEN :
        save()
    #_apply_Settings()
    NetworkingCode.connect("my_data_changed", self, "_on_network_my_data_changed")

func _load_Settings():
    # Check for error if true exist the function else parse the file and load the config settings into Settings
    var error = config.load(settings_path)
    if error != OK:
        print("Error loading the settings. Error code: %s" % error)
        return LOAD_ERROR_COULDNT_OPEN
    for section in S.keys():
        for key in S[section]:
            var val = config.get_value(section,key)
            if section == "SettingsConf":
                if key == "version":
                    if val != S.SettingsConf.version:
                        print("Previous SettingsConf version does not match current default. Will overwrite Settings.conf")
                        return LOAD_ERROR_COULDNT_OPEN
            S[section][key] = val
    return LOAD_SUCCESS

# Save the Settings into the config file if the config file dosen't exist create a new one
func save():
    for section in S.keys():
        for key in S[section]:
            config.set_value(section,key,S[section][key])
    save_thread = Thread.new()
    call_deferred("_deferred_save")
            
func _deferred_save():
    save_thread.start(self, "_threaded_save")
    
func _threaded_save(not_used):
    not_used = null
    config.save(settings_path)
    call_deferred("_call_cleanup")
    
func _call_cleanup():
    call_deferred("_cleanup_thread")
    
func _cleanup_thread():
    save_thread.wait_to_finish()
    save_thread = null

func _apply_Settings():
    # Check out the documentation about :
    # OS class : http://docs.godotengine.org/en/3.0/classes/class_os.html
    # Engine class : http://docs.godotengine.org/en/3.0/classes/class_engine.html
    # for this case i only use OS to change the resolution,fullscreen and Vsync 
    OS.window_size = Vector2(S.Display.WIDTH,S.Display.HEIGHT)
    OS.window_fullscreen = S.Display.FullScreen
    OS.vsync_enabled = S.Display.Vsync

func update_Settings(H,W,Full,Audio,Mute,Vsync):
    S.Display.Height = H
    S.Display.Width = W
    S.Display.FullScreen = Full
    S.Display.Vsync = Vsync
    S.Audio.Speech = Audio.x
    S.Audio.Music = Audio.y
    S.Audio.SoundEffects = Audio.z
    S.Audio.Mute = Mute
    #Saving the file than applying it
    save()
    #_apply_Settings()
    
####################################################
# New SettingsConf
    
func get_S():
    return S
    
func set_S(new_val):
    S = new_val
    emit_signal("S_changed")
    
func _on_network_my_data_changed():
    S.QuickStart.player_id = NetworkingCode.my_data["player_id"]
    S.QuickStart.player_name = NetworkingCode.my_data["player_name"]
    S.QuickStart.player_number = NetworkingCode.my_data["player_number"]
    S.QuickStart.player_team = NetworkingCode.my_data["player_team"]