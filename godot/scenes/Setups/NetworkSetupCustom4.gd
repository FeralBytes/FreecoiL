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


func _on_GoToLobby_pressed():
    NetworkingCode.set_scenario_player_options_as_server(null)
    SceneManager.goto_scene("res://scenes/Lobbies/NetworkTeamLobby.tscn")
