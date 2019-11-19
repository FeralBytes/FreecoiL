extends TextureButton

onready var SettingsMenu = get_node("SettingsMenu")

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

func _on_SettingsBtn_pressed():
    SettingsMenu.popup()


func _on_MainMenuBtn_pressed():
    SettingsMenu.hide()
    SceneManager.goto_scene("res://scenes/MainMenu/MainMenu2.tscn")


func _on_ToggleRecoil_pressed():
    LazerInterface.enable_recoil(!LazerInterface.recoil_enabled)
    SettingsMenu.hide()


func _on_ExitApp_pressed():
    SettingsMenu.hide()
    call_deferred("exit_the_app")
    
func exit_the_app():
    get_tree().quit()
