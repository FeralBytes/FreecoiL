extends ColorRect

onready var MagazineSize = get_node("MagazineSize")

# Called when the node enters the scene tree for the first time.
func _ready():
    MagazineSize.set_val(SettingsConf.S.QuickStart.magazine)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_MagazineSize_PMWidChanged(new_val):
    if new_val > 253:
        MagazineSize.set_val(253)
    else:
        SettingsConf.S.QuickStart.magazine = new_val
