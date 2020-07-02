extends Button

func _on_BackToMenu_pressed():
    get_tree().call_group("Container", "goto_scene", "res://scenes/MainMenu/MainMenu2.tscn")
