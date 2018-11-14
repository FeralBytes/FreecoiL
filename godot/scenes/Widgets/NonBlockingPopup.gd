extends ColorRect

signal about_to_show

# Called when the node enters the scene tree for the first time.
func _ready():
    self.hide()
    
func add_content(content_path):
    var resource = load(content_path).instance()
    add_child(resource)
    
func clear_content():
    for i in get_children():
        i.queue_free()
    

func popup():
    emit_signal("about_to_show")
    self.show()

