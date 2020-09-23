extends "res://addons/gut/test.gd"

var Obj
var _obj
var _map_maker

func before_all():
    Settings.Testing.register_data("testing", true, false)
    Obj = load("res://code/Helpers.gd")
    _obj = Obj.new()
    add_child(_obj)

func before_each():
    pass

func after_each():
    pass

func after_all():
    remove_child(_obj)
    _obj.queue_free()

func test_list_files_in_directory():
    pass
