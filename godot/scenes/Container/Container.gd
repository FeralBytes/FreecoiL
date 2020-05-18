extends Node

signal finished_loading
export(String) var lobby_xy = "3,1"
# Declare member variables here.
var current_scene
var previous_scene
var active_scene_container = 0
#warning-ignore:unused_class_variable
var scene_loaded = false
var threaded_scene_loader1 = null
var threaded_scene_loader2 = null
var loading_state = "idle"
var loading_state2 = "idle"
var integration_testing = false
var splash_timer = Timer.new()
var SplashScene = preload("res://scenes/Splash/Splash.tscn").instance()
onready var SceneFader = $Camera/TopLayer/SceneFader

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("Container")
    var test_file = File.new()
    if OS.get_environment("FeralBytes_UNIT_TEST") == "true":
        call_deferred("run_unit_tests")
        Settings.Testing.register_data("testing_active", true)
    elif test_file.file_exists("res://FeralBytes_UNIT_TEST"):
        call_deferred("run_unit_tests")
        Settings.Testing.register_data("testing_active", true)
    elif OS.get_environment("FeralBytes_INTEGRATION_TEST") == "true":
        call_deferred("run_integration_tests")
        Settings.Testing.register_data("testing_active", true)
    elif test_file.file_exists("res://FeralBytes_INTEGRATION_TEST"):
        call_deferred("run_integration_tests")
        Settings.Testing.register_data("testing_active", true)
    elif OS.get_environment("FeralBytes_MULTIPLAYER_TEST") == "true":
        call_deferred("run_multiplayer_tests")
        Settings.Testing.register_data("testing_active", true)
    elif OS.get_environment("FeralBytes_2PLAYER_TEST") == "true":
        call_deferred("run_2player_tests")
        Settings.Testing.register_data("testing_active", true)
    else:
        Settings.Testing.register_data("testing_active", false)
        Settings.InGame.register_data("except_pause_disable_input", false)
        current_scene = SplashScene
        $Scene0.add_child(current_scene)
        self.add_child(splash_timer)
        splash_timer.one_shot = true
        splash_timer.wait_time = 0.001  # TODO: 4
        splash_timer.connect("timeout",self,"_on_splash_timer_timeout") 
        splash_timer.start()
        SplashScene = null
        
        

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func do_remote_goto_scene(path):
    rpc("remote_goto_scene", path)

remotesync func remote_goto_scene(path):
    if get_tree().get_rpc_sender_id() == 1:
        get_tree().call_group("MenuButtons", "enabled", false)
        get_tree().call_group("Camera", "pan_camera", 0, 0)
        goto_scene(path)

func goto_scene(scene_path):
    if loading_state != "idle":
        yield(self, "finished_loading")
    Settings.Log("Going to scene: " + str(scene_path))
    if SceneFader != null:
        get_tree().call_group("SceneFader", "fade_in")
    #   SceneFader.fade_in()
    background_load_scene(scene_path)
    
    
func background_load_scene(scene_path,  resource_type="scene"):
    if resource_type == "scene":
        Settings.Log("Background loading scene: " + str(scene_path))
        if loading_state != "idle":
            return ERR_ALREADY_IN_USE
        else:
            loading_state = "loading"
        # start your "loading..." animation
        threaded_scene_loader1 = Thread.new()
        threaded_scene_loader1.start(self, '_threaded_loading', [scene_path])
    elif resource_type == "scene_fader":
        threaded_loading2([scene_path, "scene_fader"])
    elif resource_type == "background":
        threaded_loading2([scene_path, "background"])
            
func threaded_loading2(user_data):
    while loading_state2 != "idle":
        yield(get_tree(), "idle_frame")
    loading_state2 = "loading"
    threaded_scene_loader2 = Thread.new()
    threaded_scene_loader2.start(self, '_threaded_loading', user_data)
    
func _threaded_loading(user_data):
    var path = null
    var resource_type = "scene"
    for i in range(0, len(user_data)):
        match i:
            0:
                path = user_data[0]
            1:
                resource_type = user_data[1]
    var progress = 0.0
    var loader = ResourceLoader.load_interactive(path)
    var err = OK
    call_deferred('update_progress', [progress])
    while err == OK:  # ERR_FILE_EOF = loading finished
        err = loader.poll()
        if err == OK:
            progress = float(loader.get_stage()) / loader.get_stage_count()
        else:
            progress = 0.99
        call_deferred('update_progress', [progress])
    if err == ERR_FILE_EOF:
        var resource = loader.get_resource()
        match resource_type:
            "scene":
                call_deferred('set_new_scene')
            "scene_fader":
                call_deferred("set_new_scene_fader")
            "background":
                call_deferred("set_new_background")
        return resource
    else: # error during loading
            call_deferred('display_error', "Error during Loading! Error Number = " + str(err))

func display_error(error):
    Settings.Log(error, "critical")
            
# warning-ignore:unused_argument
func update_progress(progress):
    Settings.Log("Loading Progress = " + str(progress[0] * 100) + "%")
    #ProgBar.value = progress[0] * 100

    # or update a progress animation?
    #var length = get_node("animation").get_current_animation_length()

func set_new_scene(scene_resource=null):
    if scene_resource == null:
        scene_resource = threaded_scene_loader1.wait_to_finish()
    previous_scene = current_scene
    current_scene = scene_resource.instance()
    update_progress([0.999])
    call_deferred("set_new_scene_part2")
    
func set_new_scene_part2():
    while not SceneFader.dark:
        yield(get_tree().create_timer(0.01), "timeout")
    if active_scene_container == 0:
        $Scene1.add_child(current_scene)
        active_scene_container = 1
    else:
        $Scene0.add_child(current_scene)
        active_scene_container = 0
    update_progress([1.0])
    # start to End your loading animation.
    #get_node("SceneFader/AnimationPlayer").play("Fade_Out")
    get_tree().call_group("SceneFader", "fade_out")
    if active_scene_container == 0:
        $Scene1.remove_child(previous_scene)
    else:
        $Scene0.remove_child(previous_scene)
    previous_scene.queue_free()
    loading_state = 'idle'
    emit_signal("finished_loading")
    
func set_new_background():
    var resource = threaded_scene_loader2.wait_to_finish().instance()
    $Background.add_child(resource)
    Settings.Log("Loaded Background Resource: " + resource.name)
    finished_loading_thread2()
    
func finished_loading_thread2():
    loading_state2 = "idle"
    
func next_menu(menu):
    var xy = menu.split_floats(",")
    get_tree().call_group("Camera", "instant_pan_camera", int(xy[0]), int(xy[1]))
    Settings.Session.set_data("current_menu", menu)
    
func load_lobby():
    var xy = lobby_xy.split_floats(",")
    get_tree().call_group("Camera", "instant_pan_camera", int(xy[0]), int(xy[1]))
    Settings.Session.set_data("current_menu", lobby_xy)
    
    
func _on_splash_timer_timeout():
    goto_scene("res://scenes/MainMenu/MainMenu.tscn")
    
func run_unit_tests():
    var test_runner = load("res://tests/RunUnitTests.gd")
    test_runner = test_runner.new()
    add_child(test_runner)

func run_integration_tests():
    integration_testing = true 
    var test_runner = load("res://tests/RunIntegrationTests.gd")
    test_runner = test_runner.new()
    add_child(test_runner)

func run_multiplayer_tests():
    var test_runner = load("res://tests/RunMultiplayerTests.gd")
    test_runner = test_runner.new()
    add_child(test_runner)

func run_2player_tests():
    var test_runner = load("res://tests/Run2PlayerTests.gd")
    test_runner = test_runner.new()
    add_child(test_runner)
