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
    
func test_loads_to_main_menu():
    while _obj.current_scene.name != "MainMenu":
        yield(get_tree(), 'idle_frame')
    assert_eq(_obj.current_scene.name, "MainMenu")
    while _obj.loading_state != "idle":
        yield(get_tree(), 'idle_frame')
     
func test_can_click_preferences_btn():
    var btn = _obj.get_node("Scene1/MainMenu/0,0-Game Options/Header2/HBoxContainer/MenuBtn")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    btn = _obj.get_node("Scene1/MainMenu/0,0-Game Options/Header2/HBoxContainer/MenuBtn/SettingsMenu/VBoxContainer/Preferences")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "2,-1")
    
func test_can_change_player_name():
    var player_name = Settings.Preferences.get_data("player_name")
    var new_player_name = player_name + "_test"
    var line_edit = _obj.get_node("Scene1/MainMenu/2,-1-Preferences/CenterContainer/VBoxContainer/HBoxContainer/PlayerName")
    line_edit.text = new_player_name
    line_edit.emit_signal("text_entered", new_player_name)
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Preferences.get_data("player_name"), new_player_name)

func test_yield_to_show_result():
    yield(yield_for(5), YIELD)
    pending()
