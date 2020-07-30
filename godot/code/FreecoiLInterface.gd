extends Node

# Note: bt is short for Bluetooth.
#######################################
# Group "FreecoiL" methods start with "fi_" which
# stands for FreecoiLInterface.
# Add your listening nodes to group "FreecoiL"
# Then implement the methods below for them to be called.
# To call FreecoiL methods you will use the Singleton name
# of "FreecoiLInterface", ie: FreecoiLInterface.connect_to_laser_gun()
# fi_bt_connection_timed_out
# fi_bt_connect_timeout
# fi_gun_connected
# fi_trigger_btn_pushed
# fi_reload_btn_pushed
# fi_thumb_btn_pushed
# fi_power_btn_pushed
# fi_got_shot(shooter_id)

# The FreecoiL Singleton
var FreecoiL = null

# State vars below.
var auto_reconnect_laser
var laser_gun_id
var shot_mode
# Permission related vars below.
var bt_on
var bt_scanning
var fine_access_location
# Various timer vars below.
var bt_connect_timeout = Timer.new()
var bt_connection_timed_out = Timer.new()

# Various counters below.
var reload_btn_counter = 0
var thumb_btn_counter = 0
var power_btn_counter = 0

var battery_lvl_avg = null
var prev_battery_lvl_avg = null
var battery_lvl_array = []

var command_id
var recoil_enabled

# Shot Details:
var shot_by_id_1 = null
var shot_by_id_2 = null
var previous_shot_counter_1 = null
var previous_shot_counter_2 = null

#####################
# Public Godot API
#####################

func connect_to_laser_gun():
    Settings.Session.set_data("fi_laser_is_connected", 1)
    start_bt_scan()
    bt_connect_timeout.start()
    prev_battery_lvl_avg = null
    battery_lvl_array = []
    battery_lvl_avg = null
  
func start_bt_scan():
    if FreecoiL != null:
        FreecoiL.startBluetoothScan()

func stop_bt_scan():
    if FreecoiL != null:
        FreecoiL.stopBluetoothScan()

func vibrate(duration_millis):
    Input.vibrate_handheld(duration_millis)

func set_laser_id(new_id):
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.setLaserId(new_id)

func reload_start():
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.startReload()

func reload_finish(new_rounds, new_player_id=null, wpn_prfl=null):
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            if new_player_id == null:
                if wpn_prfl == null:
                    FreecoiL.finishReload(new_rounds, Settings.Session.get_data("fi_laser_id"), 0)
                else:
                    FreecoiL.finishReload(new_rounds, Settings.Session.get_data("fi_laser_id"), wpn_prfl)
            else:
                if wpn_prfl == null:
                    FreecoiL.finishReload(new_rounds, new_player_id, 0)
                else:
                    FreecoiL.finishReload(new_rounds, new_player_id, wpn_prfl)

func set_shot_mode(shot_mode, indoor_outdoor_mode):
    var narrow_beam_pwr = 0
    var wide_beam_pwr = 0
    if shot_mode == "single":
        shot_mode = 0
    elif shot_mode == "burst":
        shot_mode = 3
    elif shot_mode == "auto":
        shot_mode = 1
    else:
        shot_mode = 2 # Custom Shot Mode.
    if indoor_outdoor_mode == "outdoor_no_cone":
        narrow_beam_pwr = 255  # 255 == 0xFF
        wide_beam_pwr = 0
    elif indoor_outdoor_mode == "outdoor_with_cone":
        narrow_beam_pwr = 255
        wide_beam_pwr = 200  # 200 == 0xC8
    else:  # "indoor_no_cone"
        narrow_beam_pwr = 25  # 25 = 0x19
        wide_beam_pwr = 0
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            if shot_mode == 2:
                FreecoiL.setShotMode(shot_mode, narrow_beam_pwr, wide_beam_pwr, 0)
            else:
                FreecoiL.setShotMode(shot_mode, narrow_beam_pwr, wide_beam_pwr, 0)
            
func new_set_shot_mode(shot_mode, narrow_beam_pwr, wide_beam_pwr, custom_rate_of_fire=0):
    if shot_mode == "single":
        shot_mode = 0
    elif shot_mode == "burst":
        shot_mode = 3
    elif shot_mode == "auto":
        shot_mode = 1
    else:
        shot_mode = 2 # Custom Shot Mode.
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            if shot_mode == 2:
                FreecoiL.setShotMode(shot_mode, narrow_beam_pwr, wide_beam_pwr, custom_rate_of_fire)
            else:
                FreecoiL.setShotMode(shot_mode, narrow_beam_pwr, wide_beam_pwr, 0)

func enable_recoil(enabled):
    if FreecoiL != null:
        recoil_enabled = enabled
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.enableRecoil(recoil_enabled)   
            if recoil_enabled:
                Settings.Session.set_data("fi_laser_recoil", 1)
            else:
                Settings.Session.set_data("fi_laser_recoil", 2)  
        get_tree().call_group("FreecoiL", "fi_recoil_enabled_changed")
        
func toggle_recoil():
    var fi_laser_recoil = Settings.Session.get_data("fi_laser_recoil")
    if fi_laser_recoil != 0:
        if fi_laser_recoil == 1:
            FreecoiL.enableRecoil(false)
        else:
            FreecoiL.enableRecoil(true)
        

#####################
# Private Godot API
#####################
func _ready():
    bt_connect_timeout.one_shot = true
    bt_connection_timed_out.one_shot = true
    bt_connect_timeout.wait_time = 30
    bt_connection_timed_out.wait_time = 2  # Bumped this up because some phones are slower to load resources.
    bt_connect_timeout.connect("timeout", self, "_on_bt_connect_timeout")
    bt_connection_timed_out.connect("timeout", self, "_on_bt_connection_timed_out")
    add_child(bt_connect_timeout)
    add_child(bt_connection_timed_out)
    init_vars()
    # Delay the loading of FreecoiL, so as to not delay the UI.
    call_deferred('_on_delay_loading')
   
func _on_delay_loading():
    if Engine.has_singleton("FreecoiL"):
        FreecoiL = Engine.get_singleton("FreecoiL")
        print(" ************* " + str(FreecoiL.hello()))
        if OS.get_granted_permissions().empty():
            _fine_access_location_status()
            while OS.get_granted_permissions().empty():
                yield(get_tree(), 'idle_frame')
            FreecoiL.init(get_instance_id())
        else:
            FreecoiL.init(get_instance_id())
    
func init_vars():
    # We initialize the vars here to allow loading from saved defaults but also to 
    # improve Godot error checking by removing the warnings about unused vars.
    # fi_laser_is_connected:
    # Pent state: 0=never connected, 1=trying, 2=connected, 3=disconnected, 4=retrying.
    Settings.Session.set_data("fi_laser_is_connected", 0)
    #fi_laser_recoil:
    # Tri state: 0=disconnected, 1=enabled, 2=disabled.
    Settings.Session.set_data("fi_laser_recoil", 0)
    auto_reconnect_laser = false
    laser_gun_id = 0
    shot_mode = 2
    recoil_enabled = true
    bt_on = null
    bt_scanning = false
    fine_access_location = null
    command_id = 0
        
func _bt_status():
    if FreecoiL != null:
        bt_on = FreecoiL.bluetoothStatus()
    
func _bt_on():
    if bt_on == 1:
        print('Bluetooth is on.')
        _fine_access_location_status()
        call_deferred('_fine_access_location_enabled')
    elif bt_on == 0:
        print('Bluetooth is off.')
        if FreecoiL != null:
            FreecoiL.enableBluetooth()
    else:  # = 2
        print('Bluetooth is NOT supported on this device.')
    
func _fine_access_location_status():
    print("Granted Permissions: " + str(OS.get_granted_permissions()))
    if OS.get_granted_permissions().empty():
        _fine_access_location_enabled()
    return OS.get_granted_permissions()
    #fine_access_location = FreecoiL.fineAccessPermissionStatus()
        
func _fine_access_location_enabled():
    if fine_access_location == 1:
        print('Fine Access Enabled!')
    else:
        if FreecoiL != null:
            # TODO: detect if permissions were granted, should be in the returned bool below.
            var __ = OS.request_permissions()
            #FreecoiL.enableFineAccess()
        
func _on_bt_connect_timeout():
    if FreecoiL != null:
        FreecoiL.stopBluetoothScan()
    if Settings.Session.get_data("fi_laser_is_connected") == 1:
        Settings.Session.set_data("fi_laser_is_connected", 0)
    elif Settings.Session.get_data("fi_laser_is_connected") == 4:
        Settings.Session.set_data("fi_laser_is_connected", 3)
    get_tree().call_group("FreecoiL", "fi_bt_connect_timeout")
    
func _on_bt_connection_timed_out():
    bt_connection_timed_out.stop()
    get_tree().call_group("FreecoiL", "fi_bt_connection_timed_out")
    if Settings.Session.get_data("fi_laser_is_connected") == 2:
        _on_laser_gun_disconnected()
    if auto_reconnect_laser:
      pass  # TODO: generic connect to device, and delete from _on_laser_gun_disconnected()

func _on_laser_gun_connected():
    Settings.Session.set_data("fi_laser_is_connected", 2)
    Settings.Session.set_data("fi_laser_recoil", 1)
    bt_connect_timeout.stop()
    bt_connection_timed_out.start()

func _on_laser_gun_disconnected():
    Settings.Session.set_data("fi_laser_is_connected", 3)
    #get_tree().call_group("FreecoiL", "fi_laser_gun_disconnected")
    Settings.Session.set_data("fi_laser_battery_lvl", 0)
    Settings.Session.set_data("fi_laser_recoil", 0)
    bt_connection_timed_out.stop()
    if auto_reconnect_laser:
        connect_to_laser_gun()
# FreecoiL Callbacks
func _on_mod_init():
    _on_activity_result_bt_enable()
    
func _on_activity_result_bt_enable():
    _bt_status()
    call_deferred('_bt_on')

func _on_activity_result_fine_access():
    _fine_access_location_status()
    call_deferred('_fine_access_location_enabled')
    
func _on_laser_gun_still_connected():
    bt_connection_timed_out.start()  # resets the timer.

func _changed_laser_telem_commandId(commandId):
    if commandId != command_id:
        command_id = commandId
        get_tree().call_group("FreecoiL", "fi_command_accepted")
        Settings.Session.set_data("fi_command_id", commandId)

# warning-ignore:unused_argument
func _changed_laser_telem_playerId(laser_id):
    if Settings.Session.get_data("fi_laser_id") != laser_id:
        get_tree().call_group("FreecoiL", "fi_player_id_changed")
        Settings.Session.set_data("fi_laser_id", laser_id)
        laser_gun_id = laser_id

func _changed_laser_telem_shotsRemaining(shotsRemaining):
    if Settings.Session.get_data("game_weapon_magazine_ammo") != shotsRemaining:
        if Settings.Session.get_data("game_player_alive"):
            Settings.Session.set_data("game_weapon_magazine_ammo", shotsRemaining)
        else:
            reload_start()
            Settings.Session.set_data("game_weapon_magazine_ammo", 0)

func _changed_laser_telem_triggerBtnCounter(triggerBtnCounter):
    if Settings.Session.get_data("fi_trigger_btn_counter") != triggerBtnCounter:
        Settings.Session.set_data("fi_trigger_btn_counter", triggerBtnCounter)

func _changed_laser_telem_reloadBtnCounter(reload_btn_counter):
    if Settings.Session.get_data("fi_reload_btn_counter") != reload_btn_counter:
        Settings.Session.set_data("fi_reload_btn_counter", reload_btn_counter)

func _changed_laser_telem_thumbBtnCounter(thumb_btn_counter):
    if Settings.Session.get_data("fi_thumb_btn_counter") != thumb_btn_counter:
        Settings.Session.set_data("fi_thumb_btn_counter", thumb_btn_counter)

func _changed_laser_telem_powerBtnCounter(power_btn_counter):
    if Settings.Session.get_data("fi_power_btn_counter") != power_btn_counter:
        Settings.Session.set_data("fi_power_btn_counter", power_btn_counter)

func _laser_telem_batteryLvl(batteryLvl):
    # 0x10 = 00010000 = 16 = Brand New Alkalines
    # 0x0E = 00001110 = 14
    # 0x0D = 00001101 = 13
    # High order byte for battery level - RK-45, 10 is brand new 
    # alkalines, 0E for fully charged rechargables with 0D showing 
    # up pretty quick. The SR-12 uses 6 AA instead of 4 and the 
    # battery level value will be 50% higher than the RK-45 
    battery_lvl_array.append(batteryLvl)
    if battery_lvl_array.size() > 60:  # is 6 seconds of battery level.
        battery_lvl_array.pop_front()
    var battery_sum = 0
    for i in range(0, battery_lvl_array.size() - 1):
         battery_sum += battery_lvl_array[i]
    battery_lvl_avg = battery_sum / battery_lvl_array.size()
    if battery_lvl_avg != prev_battery_lvl_avg:
        var physical_laser_type = Settings.Session.get_data("physical_laser_type")
        if physical_laser_type == null:
            physical_laser_type = "RK-45"
        if physical_laser_type == "SR-12":
            Settings.Session.set_data("fi_laser_battery_lvl", battery_lvl_avg * 6.25 / 1.5)
            prev_battery_lvl_avg = battery_lvl_avg
        else:
            # If full batteries for a pistol are a charge of 16 then 100 / 16 == 6.25
            Settings.Session.set_data("fi_laser_battery_lvl", battery_lvl_avg * 6.25)
            prev_battery_lvl_avg = battery_lvl_avg
    
func _changed_laser_telem_shot_data(shooter1LaserId, shooter2LaserId, shotCounter1, shotCounter2):
    if shotCounter1 != previous_shot_counter_1:
        previous_shot_counter_1 = shotCounter1
        shot_by_id_1 = shooter1LaserId
        Settings.Session.set_data("fi_shooter1_laser_id", shooter1LaserId)
        Settings.Session.set_data("fi_shooter1_shot_counter", shotCounter1)
        get_tree().call_group("FreecoiL", "fi_got_shot", shooter1LaserId)
    if shotCounter2 != previous_shot_counter_2:
        previous_shot_counter_2 = shotCounter2
        shot_by_id_2 = shooter1LaserId
        Settings.Session.set_data("fi_shooter2_laser_id", shooter2LaserId)
        Settings.Session.set_data("fi_shooter2_shot_counter", shotCounter2)
        get_tree().call_group("FreecoiL", "fi_got_shot", shooter2LaserId)

func _changed_laser_telem_got_shot(shooter1LaserId, shooter1ShotCounter, shooter1WpnPrfl, shooter1ChargeLvl,
    shooter1SensorClip, shooter1SensorFront, shooter1SensorLeft, shooter1SensorRight, shooter2LaserId,
    shooter2ShotCounter, shooter2WpnPrfl, shooter2ChargeLvl, shooter2SensorClip, shooter2SensorFront,
    shooter2SensorLeft, shooter2SensorRight):
    if shooter1ShotCounter != Settings.Session.get_data("fi_shooter1_shot_counter"):
        Settings.Session.set_data("fi_shooter1_laser_id", shooter1LaserId)
        Settings.Session.set_data("fi_shooter1_weapon_profile", shooter1WpnPrfl)
        Settings.Session.set_data("fi_shooter1_charge_level", shooter1ChargeLvl)
        Settings.Session.set_data("fi_shooter1_sensor_clip", shooter1SensorClip)
        Settings.Session.set_data("fi_shooter1_sensor_front", shooter1SensorFront)
        Settings.Session.set_data("fi_shooter1_sensor_left", shooter1SensorLeft)
        Settings.Session.set_data("fi_shooter1_sensor_right", shooter1SensorRight)
        # We set "fi_shooter1_shot_counter" last to make it the trigger for fi_got_shot, which replaces the group call.
        Settings.Session.set_data("fi_shooter1_shot_counter", shooter1ShotCounter)
    if shooter2ShotCounter != Settings.Session.get_data("fi_shooter2_shot_counter"):
        Settings.Session.set_data("fi_shooter2_laser_id", shooter2LaserId)
        Settings.Session.set_data("fi_shooter2_weapon_profile", shooter2WpnPrfl)
        Settings.Session.set_data("fi_shooter2_charge_level", shooter2ChargeLvl)
        Settings.Session.set_data("fi_shooter2_sensor_clip", shooter2SensorClip)
        Settings.Session.set_data("fi_shooter2_sensor_front", shooter2SensorFront)
        Settings.Session.set_data("fi_shooter2_sensor_left", shooter2SensorLeft)
        Settings.Session.set_data("fi_shooter2_sensor_right", shooter2SensorRight)
        # We set "fi_shooter2_shot_counter" last to make it the trigger for fi_got_shot, which replaces the group call.
        Settings.Session.set_data("fi_shooter2_shot_counter", shooter2ShotCounter)

# warning-ignore:unused_argument
func _changed_telem_button_pressed(powerBtnPressed, triggerBtnPressed, thumbBtnPressed, reloadBtnPressed):
    if Settings.Session.get_data("fi_power_btn_pressed") != powerBtnPressed:
        Settings.Session.set_data("fi_power_btn_pressed", powerBtnPressed)
    if Settings.Session.get_data("fi_trigger_btn_pressed") != triggerBtnPressed:
        Settings.Session.set_data("fi_trigger_btn_pressed", triggerBtnPressed)
    if Settings.Session.get_data("fi_thumb_btn_pressed") != thumbBtnPressed:
        Settings.Session.set_data("fi_thumb_btn_pressed", thumbBtnPressed)
    if Settings.Session.get_data("fi_reload_btn_pressed") != reloadBtnPressed:
        Settings.Session.set_data("fi_reload_btn_pressed", reloadBtnPressed)
    #get_tree().call_group("FreecoiL", "fi_buttons_pressed", powerBtnPressed, triggerBtnPressed, thumbBtnPressed, reloadBtnPressed)

func _processed_laser_telemetry2(array_of_args):
#    if Settings.Session.get_data("fi_shooter1_shot_counter") != array_of_args[22]:
#        print("commandId = " + str(array_of_args[0]) + " | playerId = " + str(array_of_args[1]) + 
#            " | buttonsPressed = " + str(array_of_args[2]) + " | triggerBtnCounter = " + str(array_of_args[3]) + 
#            " | reloadBtnCounter = " + str(array_of_args[4]) + " | thumbBtnCounter = " + str(array_of_args[5]) + 
#            " | powerBtnCounter = " + str(array_of_args[6]) + " | batteryLvlHigh = " + str(array_of_args[7]) + 
#            " | batteryLvlLow = " + str(array_of_args[8]) + " | powerBtnPressed = " + str(array_of_args[9]) + 
#            " | triggerBtnPressed = " + str(array_of_args[10]) + " | reloadBtnPressed = " + str(array_of_args[11]) + 
#            " | thumbBtnPressed = " + str(array_of_args[12]) + " | shotsRemaining = " + str(array_of_args[13]) + 
#            " | shooter1LaserId = " + str(array_of_args[14]) + " | shooter2LaserId = " + str(array_of_args[15]) + 
#            " | shooter1WpnProfile = " + str(array_of_args[16]) + " | shooter2WpnProfile = " + str(array_of_args[17]) + 
#            " | shooter1charge = " + str(array_of_args[18]) + " | shooter1check = " + str(array_of_args[19]) + 
#            " | shooter2charge = " + str(array_of_args[20]) + " | shooter2check = " + str(array_of_args[21]) + 
#            " | shotCounter1 = " + str(array_of_args[22]) + " | shotCounter2 = " + str(array_of_args[23]) + 
#            " | sensorsHit1 = " + str(array_of_args[24]) + " | sensorsHit2 = " + str(array_of_args[25]) + 
#            " | clipSensor1 = " + str(array_of_args[26]) + " | frontSensor1 = " + str(array_of_args[27]) + 
#            " | leftSensor1 = " + str(array_of_args[28]) + " | rightSensor1 = " + str(array_of_args[29]) + 
#            " | clipSensor2 = " + str(array_of_args[30]) + " | frontSensor2 = " + str(array_of_args[31]) + 
#            " | leftSensor2 = " + str(array_of_args[32]) + " | rightSensor2 = " + str(array_of_args[33]) + 
#            " | status = " + str(array_of_args[34]) + " | PlayerIdAccepted = " + str(array_of_args[35]) + 
#            " | wpnProfileAgain = " + str(array_of_args[36]))
    _changed_laser_telem_triggerBtnCounter(array_of_args[3])
    if Settings.Session.get_data("experimental_toggles")["hexes_flash_on_sensor_hit"]:
        _changed_laser_telem_got_shot(array_of_args[14], array_of_args[22], array_of_args[16], array_of_args[18],
            array_of_args[26], array_of_args[27], array_of_args[28], array_of_args[29], array_of_args[15], array_of_args[23],
            array_of_args[17], array_of_args[20], array_of_args[30], array_of_args[31], array_of_args[32], array_of_args[33])
    else:
        _changed_laser_telem_shot_data(array_of_args[14], array_of_args[15], array_of_args[22], array_of_args[23])
        if Settings.Session.get_data("fi_shooter1_wpn_prfl") != array_of_args[16]:
            Settings.Session.set_data("fi_shooter1_wpn_prfl", array_of_args[16])
        if Settings.Session.get_data("fi_shooter1_charge") != array_of_args[18]:
            Settings.Session.set_data("fi_shooter1_charge", array_of_args[18])
        if Settings.Session.get_data("fi_shooter1_sensor_clip") != array_of_args[26]:
            Settings.Session.set_data("fi_shooter1_sensor_clip", array_of_args[26])
        if Settings.Session.get_data("fi_shooter1_sensor_front") != array_of_args[27]:
            Settings.Session.set_data("fi_shooter1_sensor_front", array_of_args[27])
        if Settings.Session.get_data("fi_shooter1_sensor_left") != array_of_args[28]:
            Settings.Session.set_data("fi_shooter1_sensor_left", array_of_args[28])
        if Settings.Session.get_data("fi_shooter1_sensor_right") != array_of_args[29]:
            Settings.Session.set_data("fi_shooter1_sensor_right", array_of_args[29])
    _changed_laser_telem_shotsRemaining(array_of_args[13])
    if Settings.Session.get_data("fi_laser_status") != array_of_args[34]:
        Settings.Session.set_data("fi_laser_status", array_of_args[34])
    if Settings.Session.get_data("fi_wpn_prfl") != array_of_args[36]:
        Settings.Session.set_data("fi_wpn_prfl", array_of_args[36])
    _on_laser_gun_still_connected()
    _laser_telem_batteryLvl(array_of_args[7])
    _changed_telem_button_pressed(array_of_args[9], array_of_args[10], array_of_args[11], array_of_args[12])
    _changed_laser_telem_reloadBtnCounter(array_of_args[4])
    _changed_laser_telem_thumbBtnCounter(array_of_args[5])
    _changed_laser_telem_powerBtnCounter(array_of_args[6])
    _changed_laser_telem_playerId(array_of_args[1])
    _changed_laser_telem_commandId(array_of_args[0])
    

func _new_status(status, level):
    # Debug Levels:
    #     0 = debug
    #     1 = info
    #     2 = warning
    #     3 = error
    #     4 = critical
    #     5 = exception
    Settings.Log('FreecoiL Java: DEBUG: ' + status) # debug level always print
    if "Pistol detected." in status:
        Settings.Session.set_data("physical_laser_type", "RK-45")
    elif "Riffle detected." in status:
        Settings.Session.set_data("physical_laser_type", "SR-12")
    
