extends ColorRect

onready var RespawnDelay = get_node("RespawnDelay")
onready var StartgameDelay = get_node("StartGameDelay")

# Called when the node enters the scene tree for the first time.
func _ready():
    RespawnDelay.set_val(SettingsConf.S.QuickStart.respawn_delay)
    StartgameDelay.set_val(SettingsConf.S.QuickStart.start_delay)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_RespawnDelay_PMWidChanged(new_val):
    SettingsConf.S.QuickStart.respawn_delay = new_val


func _on_StartGameDelay_PMWidChanged(new_val):
    SettingsConf.S.QuickStart.start_delay = new_val
