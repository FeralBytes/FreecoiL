tool
extends Control

onready var Version = get_node("Version")

# Called when the node enters the scene tree for the first time.
func _ready():
    Version.text = " Ver: " + Settings.VERSION + " "

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
