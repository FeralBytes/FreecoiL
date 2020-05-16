extends Camera2D

var panning = false
var panning_speed = 25
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

func calc_panning(steps_x, steps_y):
    var horizontal_dir = null
    var vertical_dir = null
    var total_x = (steps_x * screen_width)  # + (screen_width / 2)
    var total_y = (steps_y * screen_height)  # + (screen_height / 2)
    # Horizontal Panning in the x coordinate.
    if total_x < self.position.x:  # Negative
        horizontal_dir = "left"
    else:  # Positive
        horizontal_dir = "right"
    # Vertical Panning in the y coordinate.
    if total_y < self.position.y:  # Negative
        vertical_dir = "up"
    else:
        vertical_dir = "down"
    return [vertical_dir, horizontal_dir, total_x, total_y]
    
func pan_camera(steps_x, steps_y):
    while panning:
        yield(get_tree().create_timer(0.01), "timeout")
    #get_tree().call_group("Particle", "emit_on", true)
    Settings.Log("Camera: Panning to: " + str(steps_x) + ", " + str(steps_y), "info")
    panning = true
    var array = calc_panning(steps_x, steps_y)
    var pan_vertical_direction = array[0]
    var pan_horizontal_direction = array[1]
    var total_to_pan_x = array[2]
    var total_to_pan_y = array[3]
    while panning:
        if pan_horizontal_direction == "right":
            if self.position.x + panning_speed > total_to_pan_x:
                self.position.x = total_to_pan_x
            else:
                self.position.x += panning_speed
        else:
            if self.position.x - panning_speed < total_to_pan_x:
                self.position.x = total_to_pan_x
            else:
                self.position.x -= panning_speed
        if pan_vertical_direction == "down":
            if self.position.y + panning_speed > total_to_pan_y:
                self.position.y = total_to_pan_y
            else:
                self.position.y += panning_speed
        else:
            if self.position.y - panning_speed < total_to_pan_y:
                self.position.y = total_to_pan_y
            else:
                self.position.y -= panning_speed
        yield(get_tree().create_timer(0.01), "timeout")
        if self.position.x == total_to_pan_x and self.position.y == total_to_pan_y:
            panning = false
    #yield(get_tree().create_timer(0.5), "timeout")
    if not panning:
        self.last_x = steps_x
        self.last_y = steps_y
        #get_tree().call_group("Particle", "emit_on", false)
        get_tree().call_group("MenuButtons", "enabled", true)

func return_to_last_pan():
    self.pan_camera(self.last_x, self.last_y)        
    
func instant_pan_camera(steps_x, steps_y):
    var array = calc_panning(steps_x, steps_y)
    var total_to_pan_x = array[2]
    var total_to_pan_y = array[3]
    self.position.x = total_to_pan_x
    self.position.y = total_to_pan_y
    self.last_x = steps_x
    self.last_y = steps_y
    get_tree().call_group("MenuButtons", "enabled", true)
