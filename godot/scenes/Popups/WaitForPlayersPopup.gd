extends ColorRect

# The In Game Popups are not actually popups because the default ones
# from Godot block even parts of the UI that still visible.
# In order for this to work they must be the lowest ui elements
# on the scene tree so that they show on top.
# I also faked the func popup and signal about_to_show.
signal about_to_show

# Called when the node enters the scene tree for the first time.
func _ready():
    pass
    
func popup():
    emit_signal("about_to_show")
    self.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass   

func _on_StartGamePopup_about_to_show():
    pass
