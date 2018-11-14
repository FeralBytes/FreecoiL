extends Node

onready var Status = get_node("StatusScroll")
onready var TestBtn = get_node("Button")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lazercoil")

func _on_Button_pressed():
    TestBtn.text = "Testing..."
    TestBtn.disabled = true
    LazerInterface.set_lazer_id(2)
    LazerInterface.set_shot_mode("single")
    LazerInterface.start_reload()
    LazerInterface.finish_reload()
    
    
func li_player_id_changed():
    Status.text = "Player ID changed to " + str(LazerInterface.player_id) + "\n" + Status.text
    
func li_shots_remaining_changed():
    Status.text = "Shots Remaining changed to " + str(LazerInterface.shots_remaining) + "\n" + Status.text
    
func li_command_accepted():
    Status.text = "Command Accepted changed to " + str(LazerInterface.command_id) + "\n" + Status.text
