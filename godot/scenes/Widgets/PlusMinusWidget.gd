extends CenterContainer

signal PMWidChanged

export(int) var current_val = 0 setget set_current_val, get_current_val
export(bool) var allow_negative = false
export(bool) var allow_zero = true
export(bool) var apply_minimum_value = false
export(int) var minimum_value = 0
export(bool) var apply_maximum_value = false
export(int) var maximum_value = 0

onready var Display = get_node("HBoxContainer/Display")

# Called when the node enters the scene tree for the first time.
func _ready():
    Display.text = "%03d" % current_val

func set_current_val(val, trigger=true):
    current_val = val
    if Display != null:
        if trigger:
            _on_val_changed()
        else:
            Display.text = "%03d" % current_val

func get_current_val():
    return current_val

func _on_val_changed():
    Display.text = "%03d" % current_val
    emit_signal("PMWidChanged", current_val)

func _on_PlusBtn_pressed():
    if apply_maximum_value:
        if current_val + 1 > maximum_value:
            return
    current_val += 1    
    _on_val_changed()


func _on_MinusBtn_pressed():
    if apply_minimum_value:
        if current_val - 1 < minimum_value:
            return
    if current_val == 1:
        if not allow_zero:
            return
    if current_val == 0:
        if not allow_negative:
            return
    current_val -= 1
    _on_val_changed()
