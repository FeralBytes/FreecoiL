extends "res://addons/gut/test.gd"

var Obj
var _obj
var _map_maker

func before_all():
    Settings.Testing.register_data("testing", true, false)
    Obj = load("res://code/Geodetic.gd")
    _obj = Obj.new()
    add_child(_obj)

func before_each():
    pass

func after_each():
    pass

func after_all():
    remove_child(_obj)
    _obj.queue_free()

func test_haversine_v0():
    #58°38'38.0"N 5°42'53.6"W
    #N 36°7.2',   W 86°40.2'
    var lat1 = 36.12
    var long1 =  -86.67
    #58°38'38.0"N 5°42'53.5"W
    #N 33°56.4',  W 118°24.0'
    var lat2 = 33.94
    var long2 = -118.40
    assert_almost_eq(_obj.haversine_v1(lat1, long1, lat2, long2, 6372800), 2887259.95060711, 0.000001)
    assert_almost_eq(_obj.haversine_v0(lat1, long1, lat2, long2, 6372800), 2887259.95060711, 0.000001)
    lat1 = 51.5007
    long1 =  0.1246
    lat2 = 40.6892
    long2 = 74.0445
    assert_almost_eq(_obj.haversine_v0(lat1, long1, lat2, long2, 6371000), 5574840.456848555, 0.000001)
    assert_almost_eq(_obj.haversine_v1(lat1, long1, lat2, long2, 6371000), 5574840.456848555, 0.000001)
    lat1 = 61.320658
    long1 = -149.531634
    lat2 = 61.320604
    long2 = -149.531658
    assert_almost_eq(_obj.haversine_v0(lat1, long1, lat2, long2, 6371000), 6.139591, 0.000001)
    assert_almost_eq(_obj.haversine_v1(lat1, long1, lat2, long2, 6371000), 6.139591, 0.000001)

func test_wrap360():
    assert_eq(_obj.wrap360(361), 1.0)
    assert_eq(_obj.wrap360(1), 1.0)
    assert_eq(_obj.wrap360(181), 181.0)
    assert_eq(_obj.wrap360(360), 0.0)
    assert_eq(_obj.wrap360(0), 0.0)
    assert_eq(_obj.wrap360(722), 2.0)
    assert_almost_eq(_obj.wrap360(722.56), 2.56, 0.01)
