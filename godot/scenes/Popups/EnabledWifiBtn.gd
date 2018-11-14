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


func _on_EnabledWifiBtn_pressed():
    get_tree().call_group("lobby", "lobby_hide_popup")
    NetworkingCode.setup_as_host()
