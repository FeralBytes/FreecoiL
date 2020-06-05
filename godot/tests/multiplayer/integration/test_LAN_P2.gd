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
    yield(yield_for(0.15), YIELD)

func before_all():
    time_started = OS.get_unix_time()
    Settings.Testing.register_data("testing", true, false)
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
        yield(yield_for(1.0), YIELD)
    assert_eq(true, true)
    yield(yield_for(1), YIELD) # To finish loading and screen transition.
        
func test_can_click_start_a_networked_game():
    yield(do_a_left_click(Vector2(240, 400)), "completed")
    assert_eq(Settings.Session.get_data("current_menu"), "0,1")

func test_can_click_client():
    yield(do_a_left_click(Vector2(215, 480)), "completed")
    assert_true(Settings.Session.get_data("current_menu") == "2,1" or Settings.Session.get_data("current_menu") == "3,1")

func test_can_join_team_1():
    while _obj.current_scene.name != "Lobbies":
        yield(yield_for(1.0), YIELD)
    while Settings.InGame.get_data("game_teams") != true:
        yield(get_tree(), 'idle_frame')
    yield(yield_for(1), YIELD) # To finish loading and screen transition.
    yield(do_a_left_click(Vector2(518, 640)), "completed")
    assert_eq(Settings.Session.get_data("ui_team_being_viewed"), 1)
    yield(do_a_left_click(Vector2(266, 280)), "completed")
    assert_eq(Settings.Session.get_data("player_team"), 1)
    yield(do_a_left_click(Vector2(415, 381)), "completed")
    assert_eq(Settings.Network.get_data("mups_ready")[2], true)

func test_can_start_a_match():
    while _obj.current_scene.name != "InGame":
        yield(yield_for(1.0), YIELD)
    yield(yield_for(1), YIELD) # To finish loading and screen transition.
    while Settings.Session.get_data("game_started") == false:
        yield(get_tree(), 'idle_frame')
    pending()

func test_yield_to_show_result():
    yield(yield_for(5), YIELD)
    pending()
