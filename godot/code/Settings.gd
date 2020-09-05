extends Node
# alpha, beta, rc, preview, dev
const VERSION = "0.3.1-dev11"
#Major.Minor.Micro
const VERSION_MICRO_INT = 2  # Increment any time the micro changes.
const DEBUG_LEVELS = ["not_set", "debug", "info", "warning", "error", "critical"]
const USER_DIR = "user://"
const GAME_NAME = "FreecoiL"
const SETTINGS_VERSION = 0
const UDP_BROADCAST_GREETING = "Want to play " + GAME_NAME + "?"
const UDP_BROADCAST_HOST = "I am hosting " + GAME_NAME + "!"
const NETWORK_BROADCAST_LAN_PORT = 8808
const NETWORK_LAN_PORT = 8818
const MAX_PLAYERS = 62
const MIN_PLAYERS = 2
const MAX_OBSERVERS = 1
const __MAX_SIGNALS = 255  #  + 1 is the real max because S0 is a possible signal.

# 0=Rebuild Boot Splash Screen, 1=Print all Log Entries, 3=Typical Release Level.
var DEBUG_LEVEL = 1  #DEBUG_LEVELS = ["not_set", "debug", "info", "warning", "error", "critical"]
# Overide sequence_enforcer() on Main Menu, set below to true.
var OVERRIDE_SEQUENCE_ENFORCER = true
var DEBUG_GUI = false
var experimental_toggles = {"hexes_flash_on_sensor_hit":true, "gun_test_screen":true,
        "background_resource_loader":true, "gps_location": true, "gun_names":false, 
        "map_downloads": false, "map_downloads_testing": false}
# warning-ignore:unused_class_variable
var __signals_used = -1
# warning-ignore:unused_class_variable
var Testing = Data.new("Testing", null, false, false, false)
# warning-ignore:unused_class_variable
var Preferences = Data.new("Preferences", USER_DIR + "Preferences.json", true, true, false)
# warning-ignore:unused_class_variable
var InGame = Data.new("InGame", USER_DIR + "InGame.json", false, true, true)
# warning-ignore:unused_class_variable
var Session = Data.new("Session", null, false, false, false)
# warning-ignore:unused_class_variable
var Network = Data.new("Network", null, false, false, true)

func Log(to_print, level="debug"):
    if DEBUG_LEVELS.find(level) >= DEBUG_LEVEL:
        print(to_print)
        if DEBUG_GUI:
            get_tree().call_group("DebugOutput", "put", to_print)

class Data:
    var __settings = {}  # {"dumby": [1234, "S00"]}
    var auto_save = false
    var __additional_save = false
    var __save_thread = null
    var settings_path
    var network_sync
    var name
    var load_on_ready = false
    
    func _init(set_name, path=null, load_on_init=false, set_auto_save=false, set_network_sync=false):
        name = set_name
        settings_path = path
        auto_save = set_auto_save
        network_sync = set_network_sync
        if load_on_init:
            load_on_ready = load_on_init
            
    func loading_on_ready():
        if load_on_ready:
            var result = load_settings()
            if result != OK:
                register_data("SETTINGS_VERSION", SETTINGS_VERSION, false)
        else:
            register_data("SETTINGS_VERSION", SETTINGS_VERSION, false)
        
    func set_data(data_name, new_val, called_by_sync=false, emit_a_signal=true):
        Settings.Log("Settings: set_data(): " + self.name + ": " + str(data_name) + " = " + str(new_val), "debug")
        if not __settings.has(data_name):
            register_data(data_name, new_val)
        else:
            __settings[data_name][0] = new_val
        if emit_a_signal:
            emit_signal(__settings[data_name][1], __settings[data_name][0])
        if auto_save:
            save_settings()
        if network_sync:
            if not called_by_sync:
                if Settings.get_tree().get_network_peer() != null:
                    Settings.get_tree().call_group("Network", "rpc", "sync_var", name, data_name, __settings[data_name][0])
        
    func get_data(data_name):
        if __settings.has(data_name):
            return __settings[data_name][0]
        else:
            return null
        
    func register_data(data_name, new_val, add_signal=true):
        if __settings.has(data_name):  # Duplicate registration
            # Set the data to the new_value but don't emit a signal.
            __settings[data_name][0] = new_val
            if auto_save:
                save_settings()
            return __settings[data_name][1]  # return the signal to listen for.
        else:
            if add_signal:
                Settings.__signals_used += 1
                if Settings.__signals_used > Settings.__MAX_SIGNALS:
                    Settings.Log("Error Out of Signals: Settings Autoload: Max Data Signals exhausted! " +
                            "Please add more or reduce the amount of settings. " + 
                            "Max signals = " + str(Settings.__MAX_SIGNALS + 1), "critical")
                    Helpers.get_tree().quit()
                __settings[data_name] = [new_val, "S" + str(Settings.__signals_used)]
            else:
                __settings[data_name] = [new_val, "S00"]
            if auto_save:
                save_settings()
            return __settings[data_name][1]  # return signal to listen too.
            
    func monitor_data(data_name):
        if __settings.has(data_name):
            return __settings[data_name][1]  # return signal to monitor.
        else:
            return register_data(data_name, null)

    func save_settings():
        if __save_thread == null:
            __save_thread = Thread.new()
            call_deferred("__deferred_save")
        else:
            __additional_save = true
                
    func __deferred_save():
        __save_thread.start(self, "__threaded_save")
        
    func __threaded_save(__):
        var file = File.new()
        file.open(settings_path, file.WRITE)
        file.store_string(to_json(__settings))
        file.close()
        call_deferred("__call_cleanup")
        
    func __call_cleanup():
        call_deferred("__cleanup_thread")
        
    func __cleanup_thread():
        __save_thread.wait_to_finish()
        __save_thread = null
        if __additional_save:
            __additional_save = false
            save_settings()

    func load_settings():
        var config = ConfigFile.new()
        var error = config.load(settings_path)
        if error != OK:
            Settings.Log("Error loading the settings file " + str(settings_path) + 
                ". Error code: " + str(error) + " " + Helpers.error_lookup(error), "debug")
            return error
        else:
            var file = File.new()
            file.open(settings_path, file.READ)
            var text = file.get_as_text()
            __settings = parse_json(text)
            file.close()
            if __settings["SETTINGS_VERSION"][0] != SETTINGS_VERSION:
                Settings.Log("SETTINGS_VERSION mismatch. Current Program SETTINGS_VERSION = " + str(SETTINGS_VERSION) +
                        "  | Saved SETTINGS_VERSION = " + str(__settings["SETTINGS_VERSION"]), "debug")
                # Run Upgrades as needed. Downgrades autofail, unless we find a need for that usecase.
            return OK
    
    func sync_peer(target_peer):
        if network_sync:
            if Settings.get_tree().get_network_peer() != null:
                for setting in __settings:
                    Settings.get_tree().call_group("Network", "rpc_id", target_peer, "sync_var", name, setting, __settings[setting][0])

    ######## BEGIN SIGNALS ########
    # warning-ignore:unused_signal
    signal S00
    # warning-ignore:unused_signal
    signal S0
    # warning-ignore:unused_signal
    signal S1
    # warning-ignore:unused_signal
    signal S2
    # warning-ignore:unused_signal
    signal S3
    # warning-ignore:unused_signal
    signal S4
    # warning-ignore:unused_signal
    signal S5
    # warning-ignore:unused_signal
    signal S6
    # warning-ignore:unused_signal
    signal S7
    # warning-ignore:unused_signal
    signal S8
    # warning-ignore:unused_signal
    signal S9
    # warning-ignore:unused_signal
    signal S10
    # warning-ignore:unused_signal
    signal S11
    # warning-ignore:unused_signal
    signal S12
    # warning-ignore:unused_signal
    signal S13
    # warning-ignore:unused_signal
    signal S14
    # warning-ignore:unused_signal
    signal S15
    # warning-ignore:unused_signal
    signal S16
    # warning-ignore:unused_signal
    signal S17
    # warning-ignore:unused_signal
    signal S18
    # warning-ignore:unused_signal
    signal S19
    # warning-ignore:unused_signal
    signal S20
    # warning-ignore:unused_signal
    signal S21
    # warning-ignore:unused_signal
    signal S22
    # warning-ignore:unused_signal
    signal S23
    # warning-ignore:unused_signal
    signal S24
    # warning-ignore:unused_signal
    signal S25
    # warning-ignore:unused_signal
    signal S26
    # warning-ignore:unused_signal
    signal S27
    # warning-ignore:unused_signal
    signal S28
    # warning-ignore:unused_signal
    signal S29
    # warning-ignore:unused_signal
    signal S30
    # warning-ignore:unused_signal
    signal S31
    # warning-ignore:unused_signal
    signal S32
    # warning-ignore:unused_signal
    signal S33
    # warning-ignore:unused_signal
    signal S34
    # warning-ignore:unused_signal
    signal S35
    # warning-ignore:unused_signal
    signal S36
    # warning-ignore:unused_signal
    signal S37
    # warning-ignore:unused_signal
    signal S38
    # warning-ignore:unused_signal
    signal S39
    # warning-ignore:unused_signal
    signal S40
    # warning-ignore:unused_signal
    signal S41
    # warning-ignore:unused_signal
    signal S42
    # warning-ignore:unused_signal
    signal S43
    # warning-ignore:unused_signal
    signal S44
    # warning-ignore:unused_signal
    signal S45
    # warning-ignore:unused_signal
    signal S46
    # warning-ignore:unused_signal
    signal S47
    # warning-ignore:unused_signal
    signal S48
    # warning-ignore:unused_signal
    signal S49
    # warning-ignore:unused_signal
    signal S50
    # warning-ignore:unused_signal
    signal S51
    # warning-ignore:unused_signal
    signal S52
    # warning-ignore:unused_signal
    signal S53
    # warning-ignore:unused_signal
    signal S54
    # warning-ignore:unused_signal
    signal S55
    # warning-ignore:unused_signal
    signal S56
    # warning-ignore:unused_signal
    signal S57
    # warning-ignore:unused_signal
    signal S58
    # warning-ignore:unused_signal
    signal S59
    # warning-ignore:unused_signal
    signal S60
    # warning-ignore:unused_signal
    signal S61
    # warning-ignore:unused_signal
    signal S62
    # warning-ignore:unused_signal
    signal S63
    # warning-ignore:unused_signal
    signal S64
    # warning-ignore:unused_signal
    signal S65
    # warning-ignore:unused_signal
    signal S66
    # warning-ignore:unused_signal
    signal S67
    # warning-ignore:unused_signal
    signal S68
    # warning-ignore:unused_signal
    signal S69
    # warning-ignore:unused_signal
    signal S70
    # warning-ignore:unused_signal
    signal S71
    # warning-ignore:unused_signal
    signal S72
    # warning-ignore:unused_signal
    signal S73
    # warning-ignore:unused_signal
    signal S74
    # warning-ignore:unused_signal
    signal S75
    # warning-ignore:unused_signal
    signal S76
    # warning-ignore:unused_signal
    signal S77
    # warning-ignore:unused_signal
    signal S78
    # warning-ignore:unused_signal
    signal S79
    # warning-ignore:unused_signal
    signal S80
    # warning-ignore:unused_signal
    signal S81
    # warning-ignore:unused_signal
    signal S82
    # warning-ignore:unused_signal
    signal S83
    # warning-ignore:unused_signal
    signal S84
    # warning-ignore:unused_signal
    signal S85
    # warning-ignore:unused_signal
    signal S86
    # warning-ignore:unused_signal
    signal S87
    # warning-ignore:unused_signal
    signal S88
    # warning-ignore:unused_signal
    signal S89
    # warning-ignore:unused_signal
    signal S90
    # warning-ignore:unused_signal
    signal S91
    # warning-ignore:unused_signal
    signal S92
    # warning-ignore:unused_signal
    signal S93
    # warning-ignore:unused_signal
    signal S94
    # warning-ignore:unused_signal
    signal S95
    # warning-ignore:unused_signal
    signal S96
    # warning-ignore:unused_signal
    signal S97
    # warning-ignore:unused_signal
    signal S98
    # warning-ignore:unused_signal
    signal S99
    # warning-ignore:unused_signal
    signal S100
    # warning-ignore:unused_signal
    signal S101
    # warning-ignore:unused_signal
    signal S102
    # warning-ignore:unused_signal
    signal S103
    # warning-ignore:unused_signal
    signal S104
    # warning-ignore:unused_signal
    signal S105
    # warning-ignore:unused_signal
    signal S106
    # warning-ignore:unused_signal
    signal S107
    # warning-ignore:unused_signal
    signal S108
    # warning-ignore:unused_signal
    signal S109
    # warning-ignore:unused_signal
    signal S110
    # warning-ignore:unused_signal
    signal S111
    # warning-ignore:unused_signal
    signal S112
    # warning-ignore:unused_signal
    signal S113
    # warning-ignore:unused_signal
    signal S114
    # warning-ignore:unused_signal
    signal S115
    # warning-ignore:unused_signal
    signal S116
    # warning-ignore:unused_signal
    signal S117
    # warning-ignore:unused_signal
    signal S118
    # warning-ignore:unused_signal
    signal S119
    # warning-ignore:unused_signal
    signal S120
    # warning-ignore:unused_signal
    signal S121
    # warning-ignore:unused_signal
    signal S122
    # warning-ignore:unused_signal
    signal S123
    # warning-ignore:unused_signal
    signal S124
    # warning-ignore:unused_signal
    signal S125
    # warning-ignore:unused_signal
    signal S126
    # warning-ignore:unused_signal
    signal S127
    # warning-ignore:unused_signal
    signal S128
    # warning-ignore:unused_signal
    signal S129
    # warning-ignore:unused_signal
    signal S130
    # warning-ignore:unused_signal
    signal S131
    # warning-ignore:unused_signal
    signal S132
    # warning-ignore:unused_signal
    signal S133
    # warning-ignore:unused_signal
    signal S134
    # warning-ignore:unused_signal
    signal S135
    # warning-ignore:unused_signal
    signal S136
    # warning-ignore:unused_signal
    signal S137
    # warning-ignore:unused_signal
    signal S138
    # warning-ignore:unused_signal
    signal S139
    # warning-ignore:unused_signal
    signal S140
    # warning-ignore:unused_signal
    signal S141
    # warning-ignore:unused_signal
    signal S142
    # warning-ignore:unused_signal
    signal S143
    # warning-ignore:unused_signal
    signal S144
    # warning-ignore:unused_signal
    signal S145
    # warning-ignore:unused_signal
    signal S146
    # warning-ignore:unused_signal
    signal S147
    # warning-ignore:unused_signal
    signal S148
    # warning-ignore:unused_signal
    signal S149
    # warning-ignore:unused_signal
    signal S150
    # warning-ignore:unused_signal
    signal S151
    # warning-ignore:unused_signal
    signal S152
    # warning-ignore:unused_signal
    signal S153
    # warning-ignore:unused_signal
    signal S154
    # warning-ignore:unused_signal
    signal S155
    # warning-ignore:unused_signal
    signal S156
    # warning-ignore:unused_signal
    signal S157
    # warning-ignore:unused_signal
    signal S158
    # warning-ignore:unused_signal
    signal S159
    # warning-ignore:unused_signal
    signal S160
    # warning-ignore:unused_signal
    signal S161
    # warning-ignore:unused_signal
    signal S162
    # warning-ignore:unused_signal
    signal S163
    # warning-ignore:unused_signal
    signal S164
    # warning-ignore:unused_signal
    signal S165
    # warning-ignore:unused_signal
    signal S166
    # warning-ignore:unused_signal
    signal S167
    # warning-ignore:unused_signal
    signal S168
    # warning-ignore:unused_signal
    signal S169
    # warning-ignore:unused_signal
    signal S170
    # warning-ignore:unused_signal
    signal S171
    # warning-ignore:unused_signal
    signal S172
    # warning-ignore:unused_signal
    signal S173
    # warning-ignore:unused_signal
    signal S174
    # warning-ignore:unused_signal
    signal S175
    # warning-ignore:unused_signal
    signal S176
    # warning-ignore:unused_signal
    signal S177
    # warning-ignore:unused_signal
    signal S178
    # warning-ignore:unused_signal
    signal S179
    # warning-ignore:unused_signal
    signal S180
    # warning-ignore:unused_signal
    signal S181
    # warning-ignore:unused_signal
    signal S182
    # warning-ignore:unused_signal
    signal S183
    # warning-ignore:unused_signal
    signal S184
    # warning-ignore:unused_signal
    signal S185
    # warning-ignore:unused_signal
    signal S186
    # warning-ignore:unused_signal
    signal S187
    # warning-ignore:unused_signal
    signal S188
    # warning-ignore:unused_signal
    signal S189
    # warning-ignore:unused_signal
    signal S190
    # warning-ignore:unused_signal
    signal S191
    # warning-ignore:unused_signal
    signal S192
    # warning-ignore:unused_signal
    signal S193
    # warning-ignore:unused_signal
    signal S194
    # warning-ignore:unused_signal
    signal S195
    # warning-ignore:unused_signal
    signal S196
    # warning-ignore:unused_signal
    signal S197
    # warning-ignore:unused_signal
    signal S198
    # warning-ignore:unused_signal
    signal S199
    # warning-ignore:unused_signal
    signal S200
    # warning-ignore:unused_signal
    signal S201
    # warning-ignore:unused_signal
    signal S202
    # warning-ignore:unused_signal
    signal S203
    # warning-ignore:unused_signal
    signal S204
    # warning-ignore:unused_signal
    signal S205
    # warning-ignore:unused_signal
    signal S206
    # warning-ignore:unused_signal
    signal S207
    # warning-ignore:unused_signal
    signal S208
    # warning-ignore:unused_signal
    signal S209
    # warning-ignore:unused_signal
    signal S210
    # warning-ignore:unused_signal
    signal S211
    # warning-ignore:unused_signal
    signal S212
    # warning-ignore:unused_signal
    signal S213
    # warning-ignore:unused_signal
    signal S214
    # warning-ignore:unused_signal
    signal S215
    # warning-ignore:unused_signal
    signal S216
    # warning-ignore:unused_signal
    signal S217
    # warning-ignore:unused_signal
    signal S218
    # warning-ignore:unused_signal
    signal S219
    # warning-ignore:unused_signal
    signal S220
    # warning-ignore:unused_signal
    signal S221
    # warning-ignore:unused_signal
    signal S222
    # warning-ignore:unused_signal
    signal S223
    # warning-ignore:unused_signal
    signal S224
    # warning-ignore:unused_signal
    signal S225
    # warning-ignore:unused_signal
    signal S226
    # warning-ignore:unused_signal
    signal S227
    # warning-ignore:unused_signal
    signal S228
    # warning-ignore:unused_signal
    signal S229
    # warning-ignore:unused_signal
    signal S230
    # warning-ignore:unused_signal
    signal S231
    # warning-ignore:unused_signal
    signal S232
    # warning-ignore:unused_signal
    signal S233
    # warning-ignore:unused_signal
    signal S234
    # warning-ignore:unused_signal
    signal S235
    # warning-ignore:unused_signal
    signal S236
    # warning-ignore:unused_signal
    signal S237
    # warning-ignore:unused_signal
    signal S238
    # warning-ignore:unused_signal
    signal S239
    # warning-ignore:unused_signal
    signal S240
    # warning-ignore:unused_signal
    signal S241
    # warning-ignore:unused_signal
    signal S242
    # warning-ignore:unused_signal
    signal S243
    # warning-ignore:unused_signal
    signal S244
    # warning-ignore:unused_signal
    signal S245
    # warning-ignore:unused_signal
    signal S246
    # warning-ignore:unused_signal
    signal S247
    # warning-ignore:unused_signal
    signal S248
    # warning-ignore:unused_signal
    signal S249
    # warning-ignore:unused_signal
    signal S250
    # warning-ignore:unused_signal
    signal S251
    # warning-ignore:unused_signal
    signal S252
    # warning-ignore:unused_signal
    signal S253
    # warning-ignore:unused_signal
    signal S254
    # warning-ignore:unused_signal
    signal S255
        ######## END SIGNALS ########

func _ready():
    print(Settings.GAME_NAME + ": Version: " + Settings.VERSION + " = Integer Version Number: " 
        + str(Settings.VERSION_MICRO_INT) + " | FrecoiL Plugin Loaded=" + str(Engine.has_singleton("FreecoiL")))
    Testing.loading_on_ready()
    Preferences.loading_on_ready()
    InGame.loading_on_ready()
    Session.loading_on_ready()
    Network.loading_on_ready()
    Session.set_data("experimental_toggles", experimental_toggles)
    if OVERRIDE_SEQUENCE_ENFORCER:
        Testing.register_data("testing", true)
