extends Button

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_StartGame_pressed():
    SetConf.Session.quick_start_complete = true
    if not FreecoiLInterface.state_laser_gun_is_connected:
        get_tree().call_group("connect_weapon", "connect_weapon_guard", "res://scenes/InGame/InGameNoNetwork.tscn")
    else:
        SceneManager.goto_scene("res://scenes/InGame/InGameNoNetwork.tscn")
