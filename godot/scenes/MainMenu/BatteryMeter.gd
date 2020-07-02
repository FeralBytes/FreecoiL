extends TextureProgress

# Called when the node enters the scene tree for the first time.
func _ready():
    Settings.Session.connect(Settings.Session.monitor_data("battery_lvl"), self, "update_battery")
    update_battery(Settings.Session.get_data("battery_lvl"))

func update_battery(new_val):
    if new_val == null:
        value = 0
    else:
        value = new_val
    if value > 82:
        self_modulate = Color("07f210")  # Green
    if value <= 82:
        self_modulate = Color("ebf207")  # Yellow
    if value <= 69:
        self_modulate = Color("ff9601")  # Orange
    if value <= 50:
        self_modulate = Color("f80505")  # Red
