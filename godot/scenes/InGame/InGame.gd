extends Control

var game_over = false

onready var ReloadSound = get_node("Reload")
onready var EmptyShotSound = get_node("EmptyShot")
onready var GunShotSound = get_node("GunShot")
onready var HitIndicatorTimer = get_node("HitIndicatorTimer")
onready var TimeRemaining = get_node("TimeRemainingTimer")
onready var RespawnTimer = get_node("RespawnDelayTimer")
onready var StartGameTimer = get_node("StartGamedelayTimer")


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
