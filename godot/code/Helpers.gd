extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

static func general_type_of(obj):
    var typ = typeof(obj)
    var builtin_type_names = ["Area2D", "nil", "bool", "int", "real", "string", "vector2", "rect2", "vector3", 
        "maxtrix32", "plane", "quat", "aabb",  "matrix3", "transform", "color", "image", "nodepath",
        "rid", null, "inputevent", "dictionary", "array", "rawarray", "intarray", "realarray",
        "stringarray", "vector2array", "vector3array", "colorarray", "unknown"]
    if(typ == TYPE_OBJECT):
       return obj.type_of()
    else:
        return builtin_type_names[typ]

static func bearing(origin, destination):
    return degrees_360_from_to(origin, destination)
    
static func inverse_bearing(bearing):
    if bearing > 180:
        return bearing - 180
    elif bearing < 180:
        return bearing + 180
    else:  # bearing == 180
        return 360

static func degrees_360_from_to(from, to):
    var delta_x = from.x - to.x 
    var delta_y = from.y - to.y
    var inverse_tangent_2 = atan2(delta_x, delta_y)
    var angle_degrees = rad2deg(inverse_tangent_2)
    var angle_degrees_360
    if angle_degrees == 0:
        angle_degrees_360 = 0
    elif angle_degrees < 0:
        angle_degrees_360 = angle_degrees * -1
    elif angle_degrees > 0:
        angle_degrees_360 = (180 - angle_degrees) + 180
    return angle_degrees_360
    
static func join_array_to_str(arr, delimiter=","):
    var str_arr = ""
    for item in arr:
        if str_arr == "":
            str_arr = str(item)
        else:
            str_arr += delimiter + str(item)
    return str_arr
    
func error_lookup(err_num):
    var error_lookup_script = load("res://code/error_lookup.gd")
    return error_lookup_script.get_error_description(err_num)
    
func print_display_metrics():
    var display_script = load("res://code/display.gd").new()
    display_script.print_display_metrics()
    
func get_display_metrics():
    var display_script = load("res://code/display.gd").new()
    return display_script.get_display_metrics()
    
