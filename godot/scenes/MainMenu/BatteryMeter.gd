extends TextureProgress

# Called when the node enters the scene tree for the first time.
func _ready():
    SetConf.Session.connect("Session_battery_lvl_changed", self, "update_battery")
    update_battery()

func update_battery():
    value = SetConf.Session.battery_lvl
    if value > 82:
        self_modulate = Color("07f210")  # Green
    if value <= 82:
        self_modulate = Color("ebf207")  # Yellow
    if value <= 69:
        self_modulate = Color("ff9601")  # Orange
    if value <= 50:
        self_modulate = Color("f80505")  # Red
