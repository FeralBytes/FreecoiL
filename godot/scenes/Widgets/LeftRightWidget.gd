extends ColorRect

signal LRWidChanged

var list_selected
var list_options = []
var list_options_setting = []

onready var Display = get_node("Display")

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func set_selected_by_index(index):
    list_selected = index
    Display.text = list_options[list_selected]
    _on_selected_changed()

func clear_options():
    list_options.clear()
    list_options_setting.clear()

func add_option(disp_option, set_option):
    list_options.append(disp_option)
    list_options_setting.append(set_option)

func _on_selected_changed():
    emit_signal("LRWidChanged", list_options_setting[list_selected])

func _on_LeftBtn_pressed():
    var length = list_options.size()
    if list_selected == 0:  # Roll over
        list_selected = length - 1
    else:
        list_selected -= 1
    Display.text = list_options[list_selected]
    _on_selected_changed()


func _on_RightBtn_pressed():
    var length = list_options.size()
    if list_selected == length - 1:  # Roll over
        list_selected = 0
    else:
        list_selected += 1
    Display.text = list_options[list_selected]
    _on_selected_changed()