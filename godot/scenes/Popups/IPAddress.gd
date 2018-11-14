extends LineEdit

# Declare member variables here. Examples:
# var a = 2

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_IPAddress_text_entered(new_text):
    var matches = null
    matches = NetworkingCode.validate_ip.search(new_text)
    if matches != null:
        self.modulate = Color("ffffff")
        get_tree().call_group("lobby", "lobby_host_ip", matches.get_strings()[0])
    else:
        self.modulate = Color("ff0000")
