extends TextureProgress

# Declare member variables here. Examples:
# var a = 2
var battery_lvl = 100

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lazercoil")

# We update the progress inverse so that it looks like the battery is draining.
# That is also why we hide the value percentage.
func update_battery():
    value = battery_lvl
    print("FIXME: Battery level not working: Printing self.value | battery_lvl", self.value, " | ", battery_lvl)
    if battery_lvl > 82:
        self_modulate = Color("07f210")  # Green
    if battery_lvl <= 82:
        self_modulate = Color("ebf207")  # Yellow
    if battery_lvl <= 69:
        self_modulate = Color("ff9601")  # Orange
    if battery_lvl <= 50:
        self_modulate = Color("f80505")  # Red

func li_battery_lvl_changed():
    # If full batteries for a pistol are a charge of 16 then 100 / 16 == 6.25
    battery_lvl = LazerInterface.battery_lvl_avg * 6.25
    update_battery()