extends Node

# Note: bt is short for Bluetooth.
#######################################
# Group "lazercoil" methods start with "li_" which
# stands for LazerInterface.
# Add your listening nodes to group "lazercoil"
# Then implement the methods below for them to be called.
# To call lazercoil methods you will use the Singleton name
# of "LazerInterface", ie: LazerInterface.connect_to_lazer_gun()
# li_bt_connection_timed_out
# li_bt_connect_timeout
# li_gun_connected
# li_trigger_btn_pushed
# li_reload_btn_pushed
# li_thumb_btn_pushed
# li_power_btn_pushed
# li_battery_lvl_changed
# li_got_shot(shooter_id)

# The LazercoiL Singleton
var lazercoil = null

# constants for max and mins
const MAX_PLAYERS = 63  # 0-63, but 0 is not useable as it is the laser's default for no shot.
# It could be used if we detected the shooter_id at the same time as the shot_counter. 
const MAX_TEAMS = 31  # Literally teams not player per team. i.e.: 2 players per team would be 31 teams.
const MIN_TEAMS = 2  # FFA is not a team battle.
# vars for storing game details
var players_per_team
var full_health
var current_health
var player_kills
var player_deaths
var reload_delay
var is_player_alive
# var current_ammo = shots_remaining


var status_scroll = null
# State vars below.
var state_lazer_gun_is_connected
var state_auto_reconnect_bt_dev
var state_lazer_gun_id
var state_shot_mode
# Permission related vars below.
var state_bt_on
var state_bt_scanning
var state_fine_access_location
# Various timer vars below.
var bt_connect_timeout = Timer.new()
var bt_connection_timed_out = Timer.new()

# Various counters below.
var trigger_btn_counter = 0
var reload_btn_counter = 0
var thumb_btn_counter = 0
var power_btn_counter = 0

var battery_lvl_avg = null
var prev_battery_lvl_avg = null
var battery_lvl_array = []

var shots_remaining
var command_id
var recoil_enabled

# Shot Details:
var shot_by_id_1 = null
var shot_by_id_2 = null
var shot_counter_1 = null
var shot_counter_2 = null

#####################
# Public Godot API
#####################

func connect_to_lazer_gun():
    start_bt_scan()
    bt_connect_timeout.start()
  
func start_bt_scan():
    if lazercoil != null:
        lazercoil.startBluetoothScan()

func stop_bt_scan():
    if lazercoil != null:
        lazercoil.stopBluetoothScan()

func vibrate(duration_millis):
    if lazercoil != null:
        lazercoil.vibrate(duration_millis)

func set_lazer_id(new_id):
    if lazercoil != null:
        lazercoil.setLazerId(new_id)

func reload_start():
    if lazercoil != null:
        lazercoil.startReload()

func reload_finish():
    if lazercoil != null:
        lazercoil.finishReload(SettingsConf.S.QuickStart.magazine)

func set_shot_mode(shot_mode, indoor_outdoor_mode):
    # SHOT_MODE_FULL_AUTO = 1
    # SHOT_MODE_SINGLE = 2
    # SHOT_MODE_BURST = 4
    # FIRING_MODE_OUTDOOR_NO_CONE = 0;
    # FIRING_MODE_OUTDOOR_WITH_CONE = 1;
    # FIRING_MODE_INDOOR_NO_CONE = 2;
    if shot_mode == "single":
        shot_mode = 2
    elif shot_mode == "burst":
        shot_mode = 4
    else:  # shot_mode == "auto"
        shot_mode = 1
    if indoor_outdoor_mode == "outdoor_no_cone":
        indoor_outdoor_mode = 0
    elif indoor_outdoor_mode == "outdoor_with_cone":
        indoor_outdoor_mode = 1
    else:  # "indoor_no_cone"
        indoor_outdoor_mode = 2
    if lazercoil != null:
        lazercoil.setShotMode(shot_mode, indoor_outdoor_mode)

func enable_recoil(enabled):
    if lazercoil != null:
        print("Sending Recoil = ", enabled)
        recoil_enabled = enabled
        lazercoil.enableRecoil(recoil_enabled)
        get_tree().call_group("lazercoil", "li_recoil_enabled_changed")
        

#####################
# Private Godot API
#####################
func _ready():
    bt_connect_timeout.one_shot = true
    bt_connection_timed_out.one_shot = true
    bt_connect_timeout.wait_time = 10
    bt_connection_timed_out.wait_time = 2  # Bumped this up because some phones are slower to load resources.
    bt_connect_timeout.connect("timeout", self, "_on_bt_connect_timeout")
    bt_connection_timed_out.connect("timeout", self, "_on_bt_connection_timed_out")
    add_child(bt_connect_timeout)
    add_child(bt_connection_timed_out)
    init_vars()
    # Delay the loading of LazercoiL, so as to not delay the UI.
    call_deferred('_on_delay_loading')
   
func _on_delay_loading():
    if get_node("/root").has_node("TestContainer"):
        if get_node("/root/TestContainer").has_node("StatusScroll"):
            status_scroll = get_node("/root/TestContainer/StatusScroll")
    if(Engine.has_singleton("FreecoiL")):
        lazercoil = Engine.get_singleton("FreecoiL")
        lazercoil.init(get_instance_id())
    
func init_vars():
    # We initialize the vars here to allow loading from saved defaults but also to 
    # improve Godot error checking by removing the warnings about unused vars.
    players_per_team = 31
    full_health = 30
    current_health = 20
    player_kills = 0
    player_deaths = 0
    reload_delay = 1.5
    is_player_alive = false
    state_lazer_gun_is_connected = false
    state_auto_reconnect_bt_dev = false
    state_lazer_gun_id = 0
    state_shot_mode = 2
    recoil_enabled = true
    state_bt_on = null
    state_bt_scanning = false
    state_fine_access_location = null
    shots_remaining = 0
    command_id = 0
        
func _bt_status():
    if lazercoil != null:
        state_bt_on = lazercoil.bluetoothStatus()
    
func _bt_on():
    if state_bt_on == 1:
        print('Bluetooth is on.')
        _fine_access_location_status()
        call_deferred('_fine_access_location_enabled')
    elif state_bt_on == 0:
        print('Bluetooth is off.')
        if lazercoil != null:
            lazercoil.enableBluetooth()
    else:  # = 2
        print('Bluetooth is NOT supported on this device.')
    
func _fine_access_location_status():
    state_fine_access_location = lazercoil.fineAccessPermissionStatus()
        
func _fine_access_location_enabled():
    if state_fine_access_location == 1:
        print('Fine Access Enabled!')
    else:
        if lazercoil != null:
            lazercoil.enableFineAccess()
        
func _on_bt_connect_timeout():
    if lazercoil != null:
        lazercoil.stopBluetoothScan()
    get_tree().call_group("lazercoil", "li_bt_connect_timeout")
    
func _on_bt_connection_timed_out():
    bt_connection_timed_out.stop()
    get_tree().call_group("lazercoil", "li_bt_connection_timed_out")
    if state_lazer_gun_is_connected:
        _on_lazer_gun_disconnected()
    if state_auto_reconnect_bt_dev:
      pass  # TODO: generic connect to device, and delete from _on_lazer_gun_disconnected()

func _on_lazer_gun_connected():
    _new_status("Lazer gun, connected.", 1)
    state_lazer_gun_is_connected = true
    get_tree().call_group("lazercoil", "li_lazer_gun_connected")
    bt_connect_timeout.stop()
    bt_connection_timed_out.start()

func _on_lazer_gun_disconnected():
    _new_status("Lazer gun, disconnected.", 1)
    state_lazer_gun_is_connected = false
    get_tree().call_group("lazercoil", "li_lazer_gun_disconnected")
    bt_connection_timed_out.stop()
    if state_auto_reconnect_bt_dev:
        connect_to_lazer_gun()
# LazercoiL Callbacks
func _on_mod_init():
    _on_activity_result_bt_enable()
    
func _on_activity_result_bt_enable():
    _bt_status()
    call_deferred('_bt_on')

func _on_activity_result_fine_access():
    _fine_access_location_status()
    call_deferred('_fine_access_location_enabled')
    
func _on_lazer_gun_still_connected():
    bt_connection_timed_out.start()  # resets the timer.

# NEW CHANGE ONLY Oriented Callbacks From Java.
func _changed_lazer_telem_commandId(commandId):
    command_id = commandId
    get_tree().call_group("lazercoil", "li_command_accepted")

func _changed_lazer_telem_playerId(playerId):
    get_tree().call_group("lazercoil", "li_player_id_changed")

func _changed_lazer_telem_shotsRemaining(shotsRemaining):
    shots_remaining = shotsRemaining
    get_tree().call_group("lazercoil", "li_shots_remaining_changed")

func _changed_lazer_telem_triggerBtnCounter(triggerBtnCounter):
    get_tree().call_group_flags(2, "lazercoil", "li_trigger_btn_pushed")  # GROUP_CALL_REALTIME = 2
    trigger_btn_counter = triggerBtnCounter 

func _changed_lazer_telem_reloadBtnCounter(reloadBtnCounter):
    reload_btn_counter = reloadBtnCounter
    get_tree().call_group("lazercoil", "li_reload_btn_pushed")

func _changed_lazer_telem_thumbBtnCounter(thumbBtnCounter):
    thumb_btn_counter = thumbBtnCounter
    get_tree().call_group("lazercoil", "li_thumb_btn_pushed")

func _changed_lazer_telem_powerBtnCounter(powerBtnCounter):
    power_btn_counter = powerBtnCounter
    get_tree().call_group("lazercoil", "li_power_btn_pushed")

func _lazer_telem_batteryLvl(batteryLvl):
    # 0x10 = 00010000 = 16 = Brand New Alkalines
    # 0x0E = 00001110 = 14
    # 0x0D = 00001101 = 13
    # High order byte for battery level - RK-45, 10 is brand new 
    # alkalines, 0E for fully charged rechargables with 0D showing 
    # up pretty quick. The SR-12 uses 6 AA instead of 4 and the 
    # battery level value will be 50% higher than the RK-45 
    battery_lvl_array.append(batteryLvl)
    if battery_lvl_array.size() > 30:  # is 3 seconds of battery level.
        battery_lvl_array.pop_front()
    var battery_sum = 0
    for i in range(0, battery_lvl_array.size() - 1):
         battery_sum += battery_lvl_array[i]
    battery_lvl_avg = battery_sum / battery_lvl_array.size()
    if battery_lvl_avg != prev_battery_lvl_avg:
        get_tree().call_group("lazercoil", "li_battery_lvl_changed")
        prev_battery_lvl_avg = battery_lvl_avg
    # Battery Telemetry is called every Telemetry, so we also use this to ensure connected still.
    print("here still connected, telemetry")
    _on_lazer_gun_still_connected()
    
func _changed_lazer_telem_shot_data(shotById1, shotCounter1, shotById2, shotCounter2):
    print("shotById1 = ", shotById1, "   shotCounter1 = ", shotCounter1)
    print("shotById2 = ", shotById2, "   shotCounter2 = ", shotCounter2)
    if shotCounter1 != shot_counter_1:
        shot_counter_1 = shotCounter1
        shot_by_id_1 = shotById1
        get_tree().call_group("lazercoil", "li_got_shot", shotById1)
    if shotCounter2 != shot_counter_2:
        shot_counter_2 = shotCounter2
        shot_by_id_2 = shotById2
        get_tree().call_group("lazercoil", "li_got_shot", shotById2)

func _changed_telem_button_pressed(buttonsPressed):
    # buttonsPressed Values:
    #default = 0
    #trigger = 1
    #reload = 2
    #trigger + reload = 3
    #back = 4
    #trigger + back = 5
    #reload + back = 6
    #triger + reload + back = 7
    #power = 16
    #trigger + power = 17
    #reload + power = 18
    #trigger + reload + power = 19
    #back + power = 20
    #trigger + power + back = 21
    #reload + back + power = 22
    #triger + reload + back + power = 23
    pass

func _new_status(status, level):
    # Debug Levels:
    #     0 = debug
    #     1 = info
    #     2 = warning
    #     3 = error
    #     4 = critical
    #     5 = exception
    print('LazercoiL Java: DEBUG: ', status) # debug level always print
    if status_scroll != null:
        if level == 1:
            status_scroll.text = 'LazercoiL Java: INFO: ' + status + '\n' + status_scroll.text
        elif level == 2:
            status_scroll.text = 'LazercoiL Java: WARNING: ' + status + '\n' + status_scroll.text
        elif level == 3:
            status_scroll.text = 'LazercoiL Java: ERROR: ' + status + '\n' + status_scroll.text
        elif level == 4:
            status_scroll.text = 'LazercoiL Java: CRITICAL: ' + status + '\n' + status_scroll.text
        elif level == 5:
            status_scroll.text = 'LazercoiL Java: EXCEPTION: ' + status + '\n' + status_scroll.text
    
