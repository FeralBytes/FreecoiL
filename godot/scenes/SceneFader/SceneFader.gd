extends Node2D

# Declare member variables here. Examples:
var dark = false
onready var AnimPlayer = $TextureRect/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func fade_in():
    AnimPlayer.play("Fade_In")
    yield(AnimPlayer, "animation_finished")    
    dark = true
    
func fade_out():
    if AnimPlayer.is_playing():
        yield(AnimPlayer, "animation_finished")
    AnimPlayer.play("Fade_Out")
    yield(AnimPlayer, "animation_finished")
    dark = false
