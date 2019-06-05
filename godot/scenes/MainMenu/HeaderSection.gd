extends ColorRect

onready var Version = get_node("Version")

# Called when the node enters the scene tree for the first time.
func _ready():
    Version.text += SetConf.VERSION

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
