extends ColorRect

# The In Game Popups are not actually popups because the default ones
# from Godot block even parts of the UI that still visible.
# In order for this to work they must be the lowest ui elements
# on the scene tree so that they show on top.
# I also faked the func popup and signal about_to_show.
signal about_to_show

var current_ticks = 0

onready var StartGameTimer = get_node("StartGameTimer")
onready var TickTockTimer = get_node("TickTockTimer")
onready var TimeTick = get_node("Background/TimeTick")

# Called when the node enters the scene tree for the first time.
func _ready():
    TimeTick.text = "In: " + "%03d" % SettingsConf.S.QuickStart.start_delay
    
func popup():
    emit_signal("about_to_show")
    self.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass   

func _on_StartGamePopup_about_to_show():
    StartGameTimer.wait_time = SettingsConf.S.QuickStart.start_delay
    StartGameTimer.start()
    TickTockTimer.start()

func _on_StartGameTimer_timeout():
    StartGameTimer.stop()
    self.hide()

func _on_TickTockTimer_timeout():
    current_ticks += 1
    TimeTick.text = "In: " + "%03d" % (SettingsConf.S.QuickStart.start_delay - current_ticks)
    if current_ticks == SettingsConf.S.QuickStart.start_delay:
        TickTockTimer.stop()
        get_tree().call_group("in_game", "ig_start_game")
    else:
        TickTockTimer.start()
