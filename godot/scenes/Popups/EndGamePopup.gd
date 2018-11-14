extends ColorRect

# This Popup must be on the bottom to ensure it is always on top.
# Rare condition killed then time runs out before respawn.
signal about_to_show

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func popup():
    emit_signal("about_to_show")
    self.show()

func add_reason(reason):
    get_node("Background/EndReason").text += reason


func _on_ReturnToMainBtn_pressed():
    SceneManager.goto_scene("res://scenes/MainMenu/MainMenu2.tscn")


func _on_EndGamePopup_about_to_show():
    get_tree().call_group("in_game", "player_game_over")
