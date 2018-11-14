extends ColorRect

onready var HostIPLbl = get_node("Background/HostIPLbl")

# Called when the node enters the scene tree for the first time.
func _ready():
    HostIPLbl.text = NetworkingCode.server_ip

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_Button_pressed():
    get_tree().call_group("lobby", "lobby_hide_popup")
