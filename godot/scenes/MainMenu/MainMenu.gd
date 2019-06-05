extends Control

# Declare member variables here. Examples:
# var a = 2
onready var QuickStartBtn = get_node("ColorRect/QuickStart")
onready var NonBlockingPopup = get_node("NonBlockingPopup")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lobby")
    if not SetConf.Session.quick_start_complete:
        QuickStartBtn.disabled = true
    call_deferred("first_frame")
        
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func first_frame():
    if SetConf.Session.player_name == "":
        NonBlockingPopup.add_content("res://scenes/Popups/MissingPlayerNamePopup.tscn")
        NonBlockingPopup.popup()
    var temp = load("res://code/Resets.gd").new()
    temp.reset_networking_code()

func _on_NoNetwork_pressed():
    SceneManager.goto_scene("res://scenes/Setups/NoNetworkSetup.tscn")


func _on_Testing_pressed():
    SceneManager.goto_scene("res://scenes/TestingScene/TestingScene.tscn")


func _on_QuickStart_pressed():
    if not LazerInterface.state_lazer_gun_is_connected:
        get_tree().call_group("connect_weapon", "connect_weapon_guard", "res://scenes/InGame/InGameNoNetwork.tscn")
    else:
        SceneManager.goto_scene("res://scenes/InGame/InGameNoNetwork.tscn")


func _on_Networked_pressed():
    SceneManager.goto_scene("res://scenes/Setups/NetworkSetup0.tscn")


##############################################
# "lobby" group calls
##############################################
func lobby_hide_popup():
    NonBlockingPopup.hide()
    NonBlockingPopup.clear_content()