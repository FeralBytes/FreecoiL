extends Label

var timer = Timer.new()
var max_ticks
var current_ticks
var saved_node_name

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("time_tick")
    timer.wait_time = 1
    timer.one_shot = true
    timer.connect("timeout", self, "tick_tock")
    add_child(timer)

func time_tick_start(duration, node_name):
    var popup_name = get_parent().get_parent().name
    if popup_name == node_name:
        self.text = "In: " + "%03d" % duration
        current_ticks = 0
        max_ticks = duration
        saved_node_name = node_name
        timer.start()
    
func tick_tock():
    current_ticks += 1
    self.text = "In: " + "%03d" % (max_ticks - current_ticks)
    if current_ticks == max_ticks:
        timer.stop()
        get_tree().call_group("time_tick", "time_tick_stop", saved_node_name)
    else:
        timer.start()
