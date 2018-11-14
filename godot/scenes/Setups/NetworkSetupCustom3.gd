extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_ContinueSetup_pressed():
    SettingsConf.save()
    NetworkingCode.set_scenario_as_server(null)
    SceneManager.goto_scene("res://scenes/Setups/NetworkSetupCustom4.tscn")
