extends TextureButton

onready var SettingsMenu = get_node("SettingsMenu")

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

func _on_SettingsBtn_pressed():
    SettingsMenu.popup()
    SettingsMenu.rect_position = rect_global_position + Vector2(30, 70)


func _on_MainMenuBtn_pressed():
    SettingsMenu.hide()
    get_tree().call_group("Container", "next_menu", "0,0")


func _on_ToggleRecoil_pressed():
    LazerInterface.enable_recoil(!LazerInterface.recoil_enabled)
    SettingsMenu.hide()


func _on_ExitApp_pressed():
    SettingsMenu.hide()
    call_deferred("exit_the_app")
    
func exit_the_app():
    get_tree().quit()


func _on_ChangePlayerName_pressed():
    get_tree().call_group("Container", "next_menu", "0,-1")
