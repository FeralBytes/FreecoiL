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
    var results = _obj.apply_projection(41.850004, -87.6521887, 256)  # Chicago, Illionois, USA
    assert_almost_eq(results[0], 65.66955470222223, 0.00000000000001)
    assert_almost_eq(results[1], 95.17492272838473, 0.00000000000001)
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
    assert_eq(_obj.convert_lat_long_to_pixel(41.850004, -87.6521887, 19), [34429759, 49899069])
    # Test Close changes of longitude:
    assert_eq(_obj.convert_lat_long_to_pixel(41.850006, -87.6521873, 19), [34429760, 49899068])
    assert_eq(_obj.convert_lat_long_to_pixel(41.850006, -87.6521874, 19), [34429759, 49899068])
    assert_eq(_obj.convert_lat_long_to_pixel(41.850006, -87.6521900, 19), [34429759, 49899068])
    assert_eq(_obj.convert_lat_long_to_pixel(41.850006, -87.6521901, 19), [34429758, 49899068])
    # Yukon Delta National Wildlife Refuge, Alaska, USA
    assert_eq(_obj.convert_lat_long_to_pixel(61.3533146,-163.4431429, 19), [6172843, 37946354])
    # Frankfurt, Germany
    assert_eq(_obj.convert_lat_long_to_pixel(50.1213479, 8.4964819, 19), [70276582, 45448768])
    # Buenos Aires, Argentina
    assert_eq(_obj.convert_lat_long_to_pixel(-34.6156625, -58.503338, 19), [45297238, 80879858])

func test_tile_coordinates():
    assert_eq(_obj.get_tile_coordinates_from_x_y(34429759, 49899069, 256), [134491, 194918])

func test_pixel_to_projection():
    # Chicago, Illionois, USA
    var results = _obj.convert_pixel_to_projection(34429759, 49899069, 19)
    assert_almost_eq(results[0], 65.66955470222223, 0.00001)
    assert_almost_eq(results[1], 95.17492272838473, 0.00001)
    
func test_convert_projection_to_lat_long():
    var results = _obj.convert_projection_to_lat_long(65.67111111111112, 95.17492654697409, 19, 256)
    assert_almost_eq(results[0], 41.85, 0.000001)
    assert_almost_eq(results[1], -87.65, 0.000001)
    
func test_convert_pixel_to_lat_long():
    var results = _obj.convert_pixel_to_lat_long(34429759, 49899069, 19, 256)
    assert_almost_eq(results[0], 41.850004, 0.00001) # Accuracy is 1.1 meter.
    assert_almost_eq(results[1], -87.6521887, 0.00001)
    results = _obj.convert_pixel_to_lat_long(34429759, 49899069, 19, 256)
    assert_almost_eq(results[0], 41.850004, 0.00001) # Accuracy is 1.1 meter.
    assert_almost_eq(results[1], -87.6521887, 0.00001)
    
func test_convert_pixel_to_lat_long_from_origin():
    _obj.set_map_origin(41.850000, -87.652194, 19)
    var results = _obj.convert_pixel_to_lat_long_from_origin(-298, -303, 19) 
    # Accuracy of the new method is well beyond 1 meter, not that we need that.
    # {lat:41.85060337950517, lng:-87.65299029828644} px_x:22, px_y:17
    assert_almost_eq(results[0], 41.85060337950517, 0.000001) # 6th Decimal Place Accuracy is 0.11 meters.
    assert_almost_eq(results[1], -87.65299029828644, 0.000001)
    # {lat:41.85055343091795, lng:-87.65195496560669} px_x:408, px_y:42
    results = _obj.convert_pixel_to_lat_long_from_origin(88, -278, 19)
    assert_almost_eq(results[0], 41.85055343091795, 0.000001) 
    assert_almost_eq(results[1], -87.65195496560669, 0.000001)
    # {lat:41.85055343091795, lng:-87.65131123544312} px_x:648, px_y:42
    results = _obj.convert_pixel_to_lat_long_from_origin(328, -278, 19)
    assert_almost_eq(results[0], 41.85055343091795, 0.000001) 
    assert_almost_eq(results[1], -87.65131123544312, 0.000001)
    # {lat:41.85055343091795, lng:-87.65307076455689} px_x:-8, px_y:42
    results = _obj.convert_pixel_to_lat_long_from_origin(-328, -278, 19)
    assert_almost_eq(results[0], 41.85055343091795, 0.000001) 
    assert_almost_eq(results[1], -87.65307076455689, 0.000001)
    # {lat:41.85065133011219, lng:-87.65307076455689} px_x:-8, px_y:-7
    results = _obj.convert_pixel_to_lat_long_from_origin(-328, -327, 19)
    assert_almost_eq(results[0], 41.85065133011219, 0.000001) 
    assert_almost_eq(results[1], -87.65307076455689, 0.000001)
    # {lat:41.84934466321518, lng:-87.65307076455689} px_x:-8, px_y:647
    results = _obj.convert_pixel_to_lat_long_from_origin(-328, 327, 19)
    assert_almost_eq(results[0], 41.84934466321518, 0.000001) 
    assert_almost_eq(results[1], -87.65307076455689, 0.000001)
    # GPS Percision by decimal place: 
    # https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude
    

func test_calc_map_movement():
    _obj.set_map_origin(41.850002, -87.652191, 19)
    assert_eq(_obj.calc_map_movement(41.850002, -87.652191, 19), [0, 0])
    # Move North which will cause the map to shift to the South.
    assert_eq(_obj.calc_map_movement(41.850004, -87.652191, 19), [0, 1])
    # Move South which will cause the map to shift to the North.
    assert_eq(_obj.calc_map_movement(41.850000, -87.652191, 19), [0, -1])
    # Reset to center.
    assert_eq(_obj.calc_map_movement(41.850002, -87.652191, 19), [0, 0])
    # Move East which will cause the map to shift to the West.
    assert_eq(_obj.calc_map_movement(41.850002, -87.652193, 19), [1, 0])
    # Move West which will cause the map to shift to the East.
    assert_eq(_obj.calc_map_movement(41.850002, -87.652188, 19), [-1, 0])
    
func test_plot_entity():
    _obj.set_map_origin(41.850002, -87.652191, 19)
    # Plot entity to the North.
    assert_eq(_obj.plot_entity(41.850004, -87.652191, 19), [0, -1])
    # Plot entity to the South.
    assert_eq(_obj.plot_entity(41.850000, -87.652191, 19), [0, 1])
    # Plot entity at map origin.
    assert_eq(_obj.plot_entity(41.850002, -87.652191, 19), [0, 0])
    # Plot entity to the East.
    assert_eq(_obj.plot_entity(41.850002, -87.652189, 19), [-1, 0])
    # Plot entity to the West.
    assert_eq(_obj.plot_entity(41.850002, -87.652193, 19), [1, 0])

func test_normalize_longitude():
    assert_eq(_obj.normalize_longitude(-87.6521887), -87.6521887)

func test_get_next_tile_from_center():
    # Invalid test at this time.
    _obj.set_map_origin(41.850004, -87.6521887, 19)
    var result = _obj.get_next_tile_from_center(41.850004, -87.6521887, 19, 90)
    print("%0.14f" % result[0])
    print("%0.14f" % result[1])
    assert_almost_eq(result[0], 41.84971720170569, 0.00000000000001)
    assert_almost_eq(result[1], -87.65142052037216, 0.00000000000001)
    
func test_get_neighbor_tile_centers_2():
    var lat = 41.850004
    var long = -87.6521887
    var result = _obj.get_neighbor_tile_centers_2(lat, long)
    assert_almost_eq(result[0][0], 41.851281, 0.000001)
    assert_almost_eq(result[0][1], -87.652191, 0.000001)
    assert_almost_eq(result[1][0], 41.851281, 0.000001)
    assert_almost_eq(result[1][1], -87.650475, 0.000001)
    assert_almost_eq(result[2][0], 41.850002, 0.000001)
    assert_almost_eq(result[2][1], -87.650475, 0.000001)
    assert_almost_eq(result[3][0], 41.848724, 0.000001)
    assert_almost_eq(result[3][1], -87.650475, 0.000001)
    assert_almost_eq(result[4][0], 41.848724, 0.000001)
    assert_almost_eq(result[4][1], -87.652191, 0.000001)
    assert_almost_eq(result[5][0], 41.848724, 0.000001)
    assert_almost_eq(result[5][1], -87.653908, 0.000001)
    assert_almost_eq(result[6][0], 41.850002, 0.000001)
    assert_almost_eq(result[6][1], -87.653908, 0.000001)
    assert_almost_eq(result[7][0], 41.851281, 0.000001)
    assert_almost_eq(result[7][1], -87.653908, 0.000001)
    lat = 41.850002
    long = -87.652191
    result = _obj.get_neighbor_tile_centers_2(lat, long)
    assert_almost_eq(result[0][0], 41.851281, 0.000001)
    assert_almost_eq(result[0][1], -87.652191, 0.000001)
    assert_almost_eq(result[1][0], 41.851281, 0.000001)
    assert_almost_eq(result[1][1], -87.650475, 0.000001)
    assert_almost_eq(result[2][0], 41.850002, 0.000001)
    assert_almost_eq(result[2][1], -87.650475, 0.000001)
    assert_almost_eq(result[3][0], 41.848724, 0.000001)
    assert_almost_eq(result[3][1], -87.650475, 0.000001)
    assert_almost_eq(result[4][0], 41.848724, 0.000001)
    assert_almost_eq(result[4][1], -87.652191, 0.000001)
    assert_almost_eq(result[5][0], 41.848724, 0.000001)
    assert_almost_eq(result[5][1], -87.653908, 0.000001)
    assert_almost_eq(result[6][0], 41.850002, 0.000001)
    assert_almost_eq(result[6][1], -87.653908, 0.000001)
    assert_almost_eq(result[7][0], 41.851281, 0.000001)
    assert_almost_eq(result[7][1], -87.653908, 0.000001)
    
func test_get_saveable_center_point():
    var lat = 41.850004
    var long = -179.6521887
    var result = _obj.get_saveable_center_point(lat, long)
    assert_almost_eq(result[0], 41.850002, 0.000001)
    assert_almost_eq(result[1], -179.652191, 0.000001)
    lat = 41.850002
    long = -179.652191
    result = _obj.get_saveable_center_point(lat, long)
    assert_almost_eq(result[0], 41.850002, 0.000001)
    assert_almost_eq(result[1], -179.652191, 0.000001)

#func test_convert_pixel_to_lat_long_and_back():
#    assert_eq(_obj.convert_lat_long_to_pixel(41.850004, -87.6521887, 19), [34429759, 49899069])
#    var results = _obj.convert_pixel_to_lat_long(34429759, 49899069, 19, 256)
#    assert_almost_eq(results[0], 41.850004, 0.000001) 
#    assert_almost_eq(results[1], -87.6521887, 0.000001)
#    results = _obj.convert_pixel_to_lat_long(34429759, 49899069, 19, 256)
#    assert_almost_eq(results[0], 41.850004, 0.00001) # Accuracy is 1.1 meter.
#    assert_almost_eq(results[1], -87.6521887, 0.00001)
#     # Chicago, Illionois, USA
#    assert_eq(_obj.convert_lat_long_to_pixel(41.850004, -87.6521887, 19), [34429759, 49899069])
#    #    print("%0.14f" % results[0])
#    #    print("%0.6f" % results[0])
#    #    print("%0.14f" % 41.850004)
#    #    print("%0.14f" % results[1])
#    #    print("%0.6f" % results[1])
#    #    print("%0.14f" % -87.6521887)
#    # Test the New Method.
#    results = _obj.convert_pixel_to_lat_long_from_tile(34429759, 49899069, 0, 0, 19)
#    assert_almost_eq(results[0], 41.850004, 0.00000001) # 8th Decimal Place Accuracy is 1.1 milimeter or 0.0011 meters.
#    assert_almost_eq(results[1], -87.6521887, 0.00000001)    

#########################################
# Example Data
#Chicago, IL
#LatLng: (41.850004, -87.6521887)
#Zoom level: 19
#World Coordinate: (65.66955470222223, 95.17492272838473)
#Pixel Coordinate: (34429759, 49899069)
#Tile Coordinate: (134491, 194918)
#
#Yukon Delta National Wildlife Refuge, Alaska, USA
#LatLng: (61.3533146, -163.4431429)
#Zoom level: 19
#World Coordinate: (11.77376504888889, 72.37692684178135)
#Pixel Coordinate: (6172843, 37946354)
#Tile Coordinate: (24112, 148227)
