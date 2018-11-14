extends Label

var team_num

onready var ColorPick = get_node("ColorPickerButton")

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

func set_color(new_color):
    ColorPick.color = Color(new_color)


func _on_ColorPickerButton_color_changed(color):
    SettingsConf.S.QuickStart.TeamColors[team_num - 1] = color
