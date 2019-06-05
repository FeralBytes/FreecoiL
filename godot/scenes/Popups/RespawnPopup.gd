extends ColorRect

signal about_to_show

var current_ticks = 0

onready var TickTockTimer = get_node("TickTockTimer")
onready var TimeTick = get_node("Background/TimeTick")

# Called when the node enters the scene tree for the first time.
func _ready():
    TimeTick.text = "In: " + "%03d" % SetConf.Session.respawn_delay

func popup():
    emit_signal("about_to_show")
    self.show()
      
func _on_RespawnPopup_about_to_show():
    current_ticks = 0
    TimeTick.text = "In: " + "%03d" % SetConf.Session.respawn_delay
    TickTockTimer.start()    

func _on_TickTockTimer_timeout():
    current_ticks += 1
    TimeTick.text = "In: " + "%03d" % (SetConf.Session.respawn_delay - current_ticks)
    if current_ticks == SetConf.Session.respawn_delay:
        TickTockTimer.stop()
        self.hide()
        get_tree().call_group("in_game", "ig_respawn_player")
    else:
        TickTockTimer.start()

