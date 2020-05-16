extends Camera2D

var panning = false
var last_x = 0
var last_y = 0
var screen_width = 540
var screen_height = 960

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
    
func pan_camera(steps_x, steps_y):
    while panning:
        yield(get_tree().create_timer(0.01), "timeout")
    #get_tree().call_group("Particle", "emit_on", true)
    Settings.Log("Camera: Panning to: " + str(steps_x) + ", " + str(steps_y), "info")
    panning = true
    var pan_horizontal_direction = null
    var pan_vertical_direction = null
    var speed_step = 100
    var total_to_pan_x = (steps_x * screen_width)  # + (screen_width / 2)
    var total_to_pan_y = (steps_y * screen_height)  # + (screen_height / 2)
    print(total_to_pan_x, "  ", total_to_pan_y)
    # Horizontal Panning in the x coordinate.
    if steps_x < self.position.x:  # Negative
        pan_horizontal_direction = "left"
    else:  # Positive
        pan_horizontal_direction = "right"
    # Vertical Panning in the y coordinate.
    if steps_y < self.position.y:  # Negative
        pan_vertical_direction = "up"
    else:
        pan_vertical_direction = "down"
    # Do the panning.
    while panning:
        if pan_horizontal_direction == "right":
            if self.position.x + speed_step > total_to_pan_x:
                self.position.x = total_to_pan_x
            else:
                self.position.x += speed_step
        else:
            if self.position.x - speed_step < total_to_pan_x:
                self.position.x = total_to_pan_x
            else:
                self.position.x -= speed_step
        if pan_vertical_direction == "down":
            if self.position.y + speed_step > total_to_pan_y:
                self.position.y = total_to_pan_y
            else:
                self.position.y += speed_step
        else:
            if self.position.y - speed_step < total_to_pan_y:
                self.position.y = total_to_pan_y
            else:
                self.position.y -= speed_step
        yield(get_tree().create_timer(0.001), "timeout")
        if self.position.x == total_to_pan_x and self.position.y == total_to_pan_y:
            panning = false
    yield(get_tree().create_timer(0.5), "timeout")
    if not panning:
        self.last_x = steps_x
        self.last_y = steps_y
        #get_tree().call_group("Particle", "emit_on", false)
        get_tree().call_group("MenuButtons", "enabled", true)

func return_to_last_pan():
    self.pan_camera(self.last_x, self.last_y)        