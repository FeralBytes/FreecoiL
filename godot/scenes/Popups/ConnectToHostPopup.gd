extends ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
    if SetConf.Session.server_ip != "127.0.0.1":
        get_node("Background/IPAddress").text = SetConf.Session.server_ip

