extends Control

var fog_alpha = 0.01

onready var Fog = get_node("Fog")

# Called when the node enters the scene tree for the first time.
func _ready():
    OS.set_window_maximized(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    _fade_to_fog()
    
func _fade_to_fog():
    fog_alpha += 0.01
    Fog.material.set_shader_param("alpha_val", fog_alpha)
    if fog_alpha >= 2.5:
        SceneManager.goto_scene("res://scenes/Testing/Testing.tscn")

#func _fog_fade_out():
#    Fog.texture = load(SetConf.img_aset_dir + fog + str(fog_count) + png)
#    if fog_count == MAX_FOG_COUNT:
#        SceneManager.goto_scene("res://scenes/MainMenu/MainMenu2.tscn")
#    else:
#        if fog_delay_counter == 0:
#            fog_delay_counter = fog_delay
#            fog_count += 1
#        else:
#            fog_delay_counter -= 1
    