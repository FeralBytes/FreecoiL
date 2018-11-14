extends ColorRect

signal PMWidChanged

var current_val
var allow_negative = false
var allow_zero = false

onready var Display = get_node("Display")

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func set_val(val):
    current_val = val
    _on_val_changed()
    
func set_allow_negative(boolean):
    allow_negative = boolean
    
func set_allow_zero(boolean):
    allow_zero = boolean

func _on_val_changed():
    Display.text = "%03d" % current_val
    emit_signal("PMWidChanged", current_val)

func _on_PlusBtn_pressed():
    current_val += 1
    _on_val_changed()


func _on_MinusBtn_pressed():
    if current_val == 1:
        if allow_zero:
            current_val -= 1
    elif current_val == 0:
        if allow_negative:
            current_val -= 1
    else:
        current_val -= 1
    _on_val_changed()