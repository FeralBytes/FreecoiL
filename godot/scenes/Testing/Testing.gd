extends Node

onready var Status = get_node("StatusScroll")
onready var TestBtn = get_node("Button")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lazercoil")

func _on_Button_pressed():
    TestBtn.text = "Testing..."
    TestBtn.disabled = true
    

