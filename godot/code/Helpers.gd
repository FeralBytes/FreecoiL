extends Node

var background_threads = []

# Called when the node enters the scene tree for the first time.
func _ready():
    Settings.Session.set_data("Helpers_background_load_progress", [])
    Settings.Session.set_data("Helpers_background_load_result", [])

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
    

func threaded_background_loader(resource_path):
    var background_load_thread = Thread.new()
    background_threads.append(background_load_thread)
    var thread_num = background_threads.size() - 1
    var background_load_progress =  Settings.Session.get_data("Helpers_background_load_progress")
    background_load_progress.append(0.0)
    Settings.Session.set_data("Helpers_background_load_progress", background_load_progress)
    var background_load_results = Settings.Session.get_data("Helpers_background_load_result")
    background_load_results.append(null)
    Settings.Session.set_data("Helpers_background_load_result", background_load_results)
    background_load_thread.start(self, '_threaded_loader', [resource_path, thread_num])
    return thread_num
    
func background_loading_progress(progress, thread_num):
    var background_load_progress =  Settings.Session.get_data("Helpers_background_load_progress")
    background_load_progress[thread_num] = progress
    Settings.Session.set_data("Helpers_background_load_progress", background_load_progress)
    
func finished_background_loading(thread_num):
    var background_load_results = Settings.Session.get_data("Helpers_background_load_result")
    background_load_results[thread_num] = "finished"
    Settings.Session.set_data("Helpers_background_load_result", background_load_results)
    
func failed_background_loading(err_msg, thread_num):
    Settings.Log(err_msg)
    var background_load_results = Settings.Session.get_data("Helpers_background_load_result")
    background_load_results[thread_num] = "failed"
    Settings.Session.set_data("Helpers_background_load_result", background_load_results)

func _threaded_loader(resource_data):
    var path = null
    var thread_num = null
    for i in range(0, len(resource_data)):
        match i:
            0:
                path = resource_data[i]
            1: 
                thread_num = resource_data[i]
    var progress = 0.01
    var loader = ResourceLoader.load_interactive(path)
    var err = OK
    call_deferred('background_loading_progress', progress, thread_num)
    while err == OK:  # ERR_FILE_EOF = loading finished
        err = loader.poll()
        if err == OK:
            progress = float(loader.get_stage()) / loader.get_stage_count()
        else:
            progress = 0.99
        call_deferred('background_loading_progress', progress, thread_num)
    if err == ERR_FILE_EOF:
        var resource = loader.get_resource()
        call_deferred("finished_background_loading", thread_num)
        return resource
    else: # error during loading
            call_deferred('failed_background_loading', "Error during background loading! Error Number = " 
                + str(err), thread_num)

func get_loaded_resource_from_background(thread_num):
    var result = Settings.Session.get_data("Helpers_background_load_result")[thread_num]
    var loaded_resource = null
    var tear_down = false
    if result == "finished":
        loaded_resource = background_threads[thread_num].wait_to_finish()
        tear_down = true
    elif result == "failed":
        var __ = background_threads[thread_num].wait_to_finish()
        tear_down = true
    else:
        pass
    if tear_down:
        background_threads.remove(thread_num)
    return loaded_resource
