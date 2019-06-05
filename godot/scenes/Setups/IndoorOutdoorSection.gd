extends ColorRect

onready var IndoorOutdoor = get_node("IndoorOutdoorWidget")

# Called when the node enters the scene tree for the first time.
func _ready():
    IndoorOutdoor.add_option("Indoor No Cone", "indoor_no_cone")
    IndoorOutdoor.add_option("Outdoor With Cone", "outdoor_with_cone")
    IndoorOutdoor.add_option("Outdoor No Cone", "outdoor_no_cone")
    if SetConf.Session.indoor_outdoor_mode == "indoor_no_cone":
        IndoorOutdoor.set_selected_by_index(0)
    elif SetConf.Session.indoor_outdoor_mode == "outdoor_with_cone":
        IndoorOutdoor.set_selected_by_index(1)
    else:  # elif SetConf.Session.indoor_outdoor_mode == "outdoor_no_cone":
        IndoorOutdoor.set_selected_by_index(2)




func _on_IndoorOutdoorWidget_LRWidChanged(new_val):
    SetConf.Session.indoor_outdoor_mode = new_val
