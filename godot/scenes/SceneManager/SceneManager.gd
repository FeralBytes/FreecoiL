extends CanvasLayer

var current_scene
var threaded_scene_loader = null
var loading_state = 'idle'
var ProgBar
var timer = Timer.new()
onready var root = get_tree().get_root()

func _ready():
    current_scene = root.get_child(root.get_child_count() -1)
    ProgBar = get_node('/root/SceneManager/SceneFader/SM_ProgBar')
    timer.one_shot = true
    
        
func goto_scene(path): # game requests to switch to this scene
    if loading_state != 'idle':
        return 'Error'
    else:
        loading_state = 'loading'
    # start your "loading..." animation
    get_node("SceneFader/AnimationPlayer").play("Fade_In")
#    threaded_scene_loader = Thread.new()
#    threaded_scene_loader.start(self, '_threaded_loading', path)
    call_deferred("non_threaded_loading", path)
    current_scene.queue_free() # get rid of the old scene
    

func non_threaded_loading(path):
    yield(get_tree(), "idle_frame")
    var progress = 0.0
    yield(get_tree(), "idle_frame")
    var loader = ResourceLoader.load_interactive(path)
    var err = OK
    while err == OK:  # ERR_FILE_EOF = loading finished
        yield(get_tree(), "idle_frame")
        err = loader.poll()
        #print('Error ', err, '  | Stage ', loader.get_stage(), ' / ', loader.get_stage_count())
        if err == OK:
            progress = float(loader.get_stage()) / loader.get_stage_count()
        else:
            progress = 0.97
        call_deferred('update_progress', [progress])
    if err == ERR_FILE_EOF:
        yield(get_tree(), "idle_frame")
        var resource = loader.get_resource()
        progress = 0.98
        call_deferred('update_progress', [progress])
        loader = null
        call_deferred('set_new_scene', resource)
        return resource
    else: # error during loading
            #show_error()
            loader = null

func _threaded_loading(path):
    var progress = 0.0
    var loader = ResourceLoader.load_interactive(path)
    var err = OK
    while err == OK:  # ERR_FILE_EOF = loading finished
        err = loader.poll()
        #print('Error ', err, '  | Stage ', loader.get_stage(), ' / ', loader.get_stage_count())
        if err == OK:
            progress = float(loader.get_stage()) / loader.get_stage_count()
        else:
            progress = 0.999
        call_deferred('update_progress', [progress])
        #yield(update_progress(progress), 'finished')
        #call_defered('update_progress', [progress])
        #print('Progress = ', progress * 100)
    if err == ERR_FILE_EOF:
        var resource = loader.get_resource()
        loader = null
        call_deferred('set_new_scene')
        return resource
    else: # error during loading
            #show_error()
            loader = null

            
func update_progress(progress):
    #print('Loading: ' + str(progress[0] * 100) + '%')
    ProgBar.value = progress[0] * 100

    # or update a progress animation?
    #var length = get_node("animation").get_current_animation_length()

    # call this on a paused animation. use "true" as the second parameter to force the animation to update
    #get_node("animation").seek(progress * length, true)

func set_new_scene(scene_resource=null):
    if scene_resource == null:
        scene_resource = threaded_scene_loader.wait_to_finish()
    current_scene = scene_resource.instance()
    update_progress([0.99])
    call_deferred("set_new_scene_part2", current_scene)
    
func set_new_scene_part2(current_scene):
    get_node("/root").add_child(current_scene)
    update_progress([1.0])
    get_node("SceneFader/AnimationPlayer").play("Fade_Out")
    loading_state = 'idle'
