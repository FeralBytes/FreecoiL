extends ColorRect

onready var HostClient = get_node("HostClientWidget")
onready var GoToNext = get_node("../GoToNext")

# Called when the node enters the scene tree for the first time.
func _ready():
    HostClient.add_option("Client", "client")
    HostClient.add_option("Host", "host")
    if SetConf.Session.host:
        HostClient.set_selected_by_index(1)
        GoToNext.text = "Go To Setup >"
    else:  # elif SetConf.Session.host == false:
        HostClient.set_selected_by_index(0)
        GoToNext.text = "Go To Lobby >"




func _on_HostClientWidget_LRWidChanged(new_val):
    if new_val == "host":
        SetConf.Session.host = true
        GoToNext.text = "Go To Setup >"
    else:
        SetConf.Session.host = false
        GoToNext.text = "Go To Lobby >"


func _on_GoToNext_pressed():
    if SetConf.Session.host:
        SceneManager.goto_scene("res://scenes/Setups/NetworkSetup1.tscn")
    else:
        SceneManager.goto_scene("res://scenes/Lobbies/NetworkLobby.tscn")
