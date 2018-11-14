extends Button

func _on_BackToMenu_pressed():
    SettingsConf.save()
    SceneManager.goto_scene("res://scenes/MainMenu/MainMenu2.tscn")
