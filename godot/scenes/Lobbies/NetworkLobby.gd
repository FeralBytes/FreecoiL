extends Control

onready var ConnectPopup = get_node("ConnectToHostPopup")

func _ready():
    add_to_group("lobby")
    if SettingsConf.S.QuickStart.host:
        pass
        # TODO: Change to the correct lobby type.
    else:
        ConnectPopup.add_content("res://scenes/Popups/ConnectToHostPopup.tscn")
        call_deferred("first_frame_show_connect_popup")

func first_frame_show_connect_popup():
    ConnectPopup.popup()

func _on_BackToSetup_pressed():
    SettingsConf.save()
    if SettingsConf.S.QuickStart.host:
        SceneManager.goto_scene("res://scenes/Setups/NetworkSetup1.tscn")
    else:
        SceneManager.goto_scene("res://scenes/Setups/NetworkSetup0.tscn")

# DEAD Code Below
func _on_ReadyGame_pressed():
    SettingsConf.S.QuickStart.quick_start_complete = true
    SettingsConf.save()
    if not LazerInterface.state_lazer_gun_is_connected:
        get_tree().call_group("connect_weapon", "connect_weapon_guard", "res://scenes/InGame/InGameNetwork.tscn")
    else:
        SceneManager.goto_scene("res://scenes/InGame/InGameNetwork.tscn")
        
####################################
# "lobby" group calls
####################################
func lobby_host_ip(Ip):
    ConnectPopup.hide()
    NetworkingCode.server_ip = Ip
    NetworkingCode.setup_as_client()
