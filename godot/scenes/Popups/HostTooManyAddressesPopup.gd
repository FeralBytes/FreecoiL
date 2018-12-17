extends ColorRect

onready var IPChoice = get_node("Background/IPChoiceLeftRightWidget")

# Called when the node enters the scene tree for the first time.
func _ready():
    for opt in NetworkingCode.possible_server_ips:
        IPChoice.add_option(opt, opt)
    IPChoice.set_selected_by_index(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_IPChoiceLeftRightWidget_LRWidChanged(ip):
    SetConf.Session.server_ip = ip
    


func _on_Button_pressed():
    get_tree().call_group("lobby", "lobby_hide_popup")
    get_tree().call_group("networking", "nw_inet_bound_address", SetConf.Session.server_ip)
    get_tree().call_group("networking", "finish_host_setup")
