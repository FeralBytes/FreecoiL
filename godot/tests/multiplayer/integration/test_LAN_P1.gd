extends "res://addons/gut/test.gd"

var Obj
var _obj
var _map_maker
var time_started

onready var OvertimeTimer = Timer.new()

func _ready():
    add_child(OvertimeTimer)
    OvertimeTimer.connect("timeout", self, "overtime_exit")
    OvertimeTimer.wait_time = 60
    OvertimeTimer.start()
    
func overtime_exit():
    get_tree().quit(1)

func do_a_left_click(position:Vector2):
    var evt = InputEventMouseButton.new()
    evt.button_index = BUTTON_LEFT
    evt.position = position
    evt.pressed = true
    get_tree().input_event(evt)
    yield(yield_for(0.1), YIELD)
    evt.pressed = false
    get_tree().input_event(evt)
    yield(yield_for(0.16), YIELD)

func before_all():
    time_started = OS.get_unix_time()
    Settings.Testing.register_data("testing", true, false)
    var FailTimer = Timer.new()
    Obj = load("res://scenes/Container/Container.tscn")
    _obj = Obj.instance()
    add_child(_obj)

func before_each():
    pass

func after_each():
    pass

func after_all():
    remove_child(_obj)
    _obj.queue_free()
    var time_now = OS.get_unix_time()
    var elapsed = time_now - time_started
    var minutes = elapsed / 60
    var seconds = elapsed % 60
    var str_elapsed = "%02d : %02d" % [minutes, seconds]
    print("Elapsed Time = ", str_elapsed)
    
func test_p1_loads_to_main_menu():
    while _obj.current_scene.name != "MainMenu":
        yield(get_tree(), 'idle_frame')
    assert_eq(_obj.current_scene.name, "MainMenu")
    while _obj.loading_state != "idle":
        yield(get_tree(), 'idle_frame')
        
func test_p1_can_change_player_name():
    var line_edit = _obj.get_node("Scene1/MainMenu/0,-1-Get Player Name/CenterContainer/VBoxContainer/VBoxContainer/LineEdit")
    var new_player_name = "Player 1"
    line_edit.text = new_player_name
    line_edit.emit_signal("text_entered", new_player_name)
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Preferences.get_data("player_name"), new_player_name)
     
func test_p1_can_click_start_a_networked_game():
    var btn = _obj.get_node("Scene1/MainMenu/0,0-Game Options/CenterContainer/VBoxContainer/VBoxContainer/Button2")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "0,1")

func test_p1_can_click_host():
    var btn = _obj.get_node("Scene1/MainMenu/0,1-Networked Game 1/CenterContainer/VBoxContainer/HBoxContainer/Button2")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "1,1")

func test_p1_can_click_custom_match_setup():
    var btn = _obj.get_node("Scene1/MainMenu/1,1-Networked Game 2/CenterContainer/VBoxContainer/Button")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "0,3")

func test_p1_can_click_yes():
    var btn = _obj.get_node("Scene1/MainMenu/0,3-Custom Setup 1/CenterContainer/VBoxContainer/HBoxContainer/Button")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "1,3")
    
func test_p1_can_click_submit_team_num():
    var btn = _obj.get_node("Scene1/MainMenu/1,3-Custom Setup 2/CenterContainer/VBoxContainer/VBoxContainer/Button")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "2,3")
    
func test_p1_can_click_outdoors():
    var btn = _obj.get_node("Scene1/MainMenu/2,3-Custom Setup 3/CenterContainer/VBoxContainer/HBoxContainer/Button2")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "3,3")
    
func test_p1_can_click_time_limit():
    var btn = _obj.get_node("Scene1/MainMenu/3,3-Custom Setup 4/CenterContainer/VBoxContainer/HBoxContainer/Button2")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "4,3")
    
func test_p1_can_click_submit_respawn_delay():
    var btn = _obj.get_node("Scene1/MainMenu/4,3-Custom Setup 5/CenterContainer/VBoxContainer/VBoxContainer/Button")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "3,1")
    
func test_p1_can_join_team_2():
    while _obj.current_scene.name != "Lobbies":
        yield(get_tree(), 'idle_frame')
    assert_eq(_obj.current_scene.name, "Lobbies")
    while _obj.loading_state != "idle":
        yield(get_tree(), 'idle_frame')
    # We make sure the host waits for all of the bots to join.
    while Settings.Network.get_data("mups_to_peers").size() != 3:
        yield(get_tree(), 'idle_frame')
    var btn = _obj.get_node("Scene0/Lobbies/0,0-Game Lobby/CenterContainer/VBoxContainer/HBoxContainer/RightBtn")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("ui_team_being_viewed"), 1)
    btn = _obj.get_node("Scene0/Lobbies/0,0-Game Lobby/CenterContainer/VBoxContainer/HBoxContainer/RightBtn")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("ui_team_being_viewed"), 2)
    btn = _obj.get_node("Scene0/Lobbies/0,0-Game Lobby/CenterContainer/VBoxContainer/JoinTeam")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("player_team"), 2)
    var tmp = _obj.get_node("Scene0/Lobbies/0,0-Game Lobby/CenterContainer/VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer/TeamContainer")
    btn = tmp.get_child(0).get_child(1)
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    # mups being ready is too fast to catch, but the fact that it
    # transitions to the InGame definitely means that it is working.
    
func test_p1_can_start_a_match():
    while Settings.Session.get_data("game_started") == 1:
        yield(get_tree(), 'idle_frame')
    
func test_p1_can_be_respawned():
    while Settings.Session.get_data("game_player_alive") != true:
        yield(get_tree(), 'idle_frame')
    while Settings.Session.get_data("game_weapon_magazine_ammo") == 0:
        yield(get_tree(), 'idle_frame')
    yield(get_tree().create_timer(1.0), "timeout")
    FreecoiLInterface._changed_laser_telem_triggerBtnCounter(0)
    yield(get_tree(), 'idle_frame')
    FreecoiLInterface._changed_laser_telem_shotsRemaining(0)
    yield(get_tree().create_timer(0.1), "timeout")
    FreecoiLInterface._changed_laser_telem_triggerBtnCounter(1)
    yield(get_tree().create_timer(1.0), "timeout")
    FreecoiLInterface._changed_laser_telem_reloadBtnCounter(0)
    yield(get_tree().create_timer(1.0), "timeout")
    Settings.Session.set_data("game_player_health", 1)
    yield(get_tree(), 'idle_frame')
    FreecoiLInterface._changed_laser_telem_shot_data(Settings.InGame.get_data("player_laser_by_id")["2"], 0, 0, 0)
    yield(get_tree().create_timer(1.0), "timeout")
    

func test_p1_yield_to_show_result():
    yield(yield_for(15), YIELD)
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    print("Signals Used = " + str(Settings.__signals_used))
    print("Memory Useage = " + str(OS.get_static_memory_peak_usage()))
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    print("Player 1 (Server) Game History:")
    print(_obj.current_scene.game_history.size())
    print(_obj.current_scene.game_history)
    yield(get_tree(), 'idle_frame')
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    print("Settings.Session:")
    print(Settings.Session.__settings)
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    print("Settings.Network:")
    print(Settings.Network.__settings)
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    print("Settings.InGame:")
    print(Settings.InGame.__settings)
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    print("Settings.Preferences:")
    print(Settings.Preferences.__settings)
    print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    yield(get_tree().create_timer(1.0), "timeout")
    pending()
