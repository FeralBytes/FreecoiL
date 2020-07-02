extends ColorRect

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_LineEdit_text_entered(new_text):
    Settings.Session.set_data("player_name", new_text)
    get_tree().call_group("lobby", "lobby_hide_popup")
