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

func test_apply_projection():
    var results = _obj.apply_projection(41.85, -87.65, 256)  # Chicago, Illionois, USA
    assert_almost_eq(results[0], 65.67111111111112, 0.00000000000001)
    assert_almost_eq(results[1], 95.17492654697409, 0.00000000000001)
    results = _obj.apply_projection(61.3533146,-163.4431429, 256)  # Yukon Delta National Wildlife Refuge, Alaska, USA
    assert_almost_eq(results[0], 11.77376504888889, 0.00000000000001)
    assert_almost_eq(results[1], 72.37692684178135, 0.00000000000001)
    results = _obj.apply_projection(50.1213479, 8.4964819, 256)  # Frankfurt, Germany
    assert_almost_eq(results[0], 134.04194268444445, 0.00000000000001)
    assert_almost_eq(results[1], 86.68664622374683, 0.00000000000001)
    results = _obj.apply_projection(-34.6156625, -58.503338, 256)  # Buenos Aires, Argentina
    assert_almost_eq(results[0], 86.39762631111111, 0.00000000000001)
    assert_almost_eq(results[1], 154.266087980084, 0.00000000000001)
    
    
func test_lat_long_to_pixel():
    # Chicago, Illionois, USA
    assert_eq(_obj.convert_lat_long_to_pixel(41.85, -87.65, 19, 640), [34430575, 49899071])
    # Yukon Delta National Wildlife Refuge, Alaska, USA
    assert_eq(_obj.convert_lat_long_to_pixel(61.3533146,-163.4431429, 19, 640), [6172843, 37946354])
    # Frankfurt, Germany
    assert_eq(_obj.convert_lat_long_to_pixel(50.1213479, 8.4964819, 19, 640), [70276582, 45448768])
    # Buenos Aires, Argentina
    assert_eq(_obj.convert_lat_long_to_pixel(-34.6156625, -58.503338, 19, 640), [45297238, 80879858])
