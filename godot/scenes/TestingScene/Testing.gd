extends Node

onready var Status = get_node("StatusScroll")
onready var TestBtn = get_node("Button")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("FreecoiL")

func _on_Button_pressed():
    TestBtn.text = "Testing..."
    TestBtn.disabled = true
    FreecoiLInterface.set_laser_id(2)
    FreecoiLInterface.set_shot_mode("single")
    FreecoiLInterface.start_reload()
    FreecoiLInterface.finish_reload()
    
    
func fi_player_id_changed():
    Status.text = "Player ID changed to " + str(FreecoiLInterface.player_id) + "\n" + Status.text
    
func fi_shots_remaining_changed():
    Status.text = "Shots Remaining changed to " + str(FreecoiLInterface.shots_remaining) + "\n" + Status.text
    
func fi_command_accepted():
    Status.text = "Command Accepted changed to " + str(FreecoiLInterface.command_id) + "\n" + Status.text
