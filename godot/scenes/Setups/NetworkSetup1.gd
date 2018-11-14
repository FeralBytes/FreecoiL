extends Control

onready var HostPopup = get_node("HostSetupPopup")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("networking")
    add_to_group("lobby")
    NetworkingCode.setup_as_host()
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_GoToLobby_pressed():
    SettingsConf.save()
    SceneManager.goto_scene("res://scenes/Lobbies/NetworkLobby.tscn")

##########################################
# "networking" group calls
##########################################
func nw_too_many_inet_facing_addresses(addresses):
    HostPopup.clear_content()
    HostPopup.add_content("res://scenes/Popups/HostTooManyAddressesPopup.tscn")
    HostPopup.popup()
    
func nw_inet_bound_address(address):
    HostPopup.clear_content()
    HostPopup.add_content("res://scenes/Popups/HostBoundAddressPopup.tscn")
    HostPopup.popup()

func nw_no_inet_facing_addresses():
    HostPopup.clear_content()
    HostPopup.add_content("res://scenes/Popups/HostNoIpAddressesPopup.tscn")
    HostPopup.popup()
    
###############################################
# "lobby" group calls
###############################################
func lobby_hide_popup():
    HostPopup.hide()

func _on_CustomMatchSetupBtn_pressed():
    SceneManager.goto_scene("res://scenes/Setups/NetworkSetupCustom2.tscn")


func _on_ScenariomatchSetupBtn_pressed():
    pass # Replace with function body.