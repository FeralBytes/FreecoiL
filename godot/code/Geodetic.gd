extends Node

const EARTH_RADIUS = 6371000.0  # in meters
#const EARTH_RADIUS = 6372800  # in meters
#-- 6371.0 km is the authalic radius based on/extracted from surface area;
# -- 6372.8 km is an approximation of the radius of the average circumference
#    (i.e., the average great-elliptic or great-circle radius), where the
#     boundaries are the meridian (6367.45 km) and the equator (6378.14 km).
#
#Using either of these values results, of course, in differing distances:
#
# 6371.0 km -> 2886.44444283798329974715782394574671655 km;
# 6372.8 km -> 2887.25995060711033944886005029688505340 km;
# (results extended for accuracy check:  Given that the radii are only
#  approximations anyways, .01' ≈ 1.0621333 km and .001" ≈ .00177 km,
#  practical precision required is certainly no greater than about
#  .0000001——i.e., .1 mm!)
#
#As distances are segments of great circles/circumferences, it is
#recommended that the latter value (r = 6372.8 km) be used (which
#most of the given solutions have already adopted, anyways). 
#When applying these examples in real applications, it is better to use 
#the mean earth radius, 6371 km. This value is recommended by the International 
#Union of Geodesy and Geophysics and it minimizes the RMS relative error between 
#the great circle and geodesic distance.
# https://www.movable-type.co.uk/scripts/latlong.html

var map_origin_lat
var map_origin_long
var map_origin_x
var map_origin_y
var player_x
var player_y
var moved_x
var moved_y

func haversine_v0(lat1, long1, lat2, long2, radius=EARTH_RADIUS):
    # Version 0 of the formula was fastest in testing.
    var rlat1 = deg2rad(lat1)
    var rlong1 = deg2rad(long1)
    var rlat2 = deg2rad(lat2)
    var rlong2 = deg2rad(long2)
    var delta_lat = rlat2 - rlat1
    var delta_long = rlong2 - rlong1
    var a  = pow(sin(delta_lat / 2), 2) + cos(rlat1) * cos(rlat2) * pow(sin(delta_long / 2), 2)
    var c = 2 * asin(sqrt(a))
    return c * radius  # Distance between the 2 points.

func haversine_v1(lat1, long1, lat2, long2, radius=EARTH_RADIUS):
    var rlat1 = deg2rad(lat1)
    var rlat2 = deg2rad(lat2)
    var delta_lat = deg2rad(lat2 - lat1)
    var delta_long = deg2rad(long2 - long1)
    var a  = sin(delta_lat / 2) * sin(delta_lat / 2) + cos(rlat1) * cos(rlat2) * sin(delta_long / 2) * sin(delta_long / 2)
    var c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return c * radius

func bearing_from_to(lat1, long1, lat2, long2):
    if lat1 == lat2:
        if long1 == long2:
            return 0  # Same Point
    var rlat1 = deg2rad(lat1)
    var rlong1 = deg2rad(long1)
    var rlat2 = deg2rad(lat2)
    var rlong2 = deg2rad(long2)
    var delta_rlong = rlong2 - rlong1
    var x = cos(rlat1) * sin(rlat2) - sin(rlat1) * cos(rlat2) * cos(delta_rlong)
    var y = sin(delta_rlong) * cos(rlat2)
    var bearing_rad = atan2(y, x)
    var bearing_deg = wrap360(rad2deg(bearing_rad))
    return bearing_deg
    
func wrap360(degrees_beyond):
    degrees_beyond = float(degrees_beyond)
    if 0.0 <= degrees_beyond and degrees_beyond < 360.0:
        return degrees_beyond
    else:
        return fmod((fmod(degrees_beyond, 360.0) + 360.0), 360.0)
        
func midpoint(lat1, long1, lat2, long2):
    var rlat1 = deg2rad(lat1)
    var rlat2 = deg2rad(lat2)
    var delta_rlong = deg2rad(long2) - deg2rad(long1)
    var xb = cos(rlat2) * cos(delta_rlong)
    var yb = cos(rlat2) * sin(delta_rlong)
    var mid_rlat = atan2(sin(rlat1) + sin(rlat2), sqrt(cos(rlat1) + xb) * cos(rlat1) + yb * yb)
    var mid_rlong = atan2(yb, cos(rlat1) + xb)
    return [wrap360(rad2deg(mid_rlat)), wrap360(rad2deg(mid_rlong))]
    
func get_dest_from_bearing_range(start_lat, start_long, distance, bearing):
    var start_rlat = deg2rad(start_lat)
    var start_rlong = deg2rad(start_long)
    var dest_rlat = asin(sin(start_rlat) * cos(distance / EARTH_RADIUS) + cos(start_rlat) *
        sin(distance / EARTH_RADIUS) * cos(bearing))
    var dest_rlong = start_rlong + atan2(sin(bearing) * sin(distance / EARTH_RADIUS) * 
        cos(start_rlat), cos(distance / EARTH_RADIUS) - sin(start_rlat) * sin(dest_rlat))
    return [wrap360(rad2deg(dest_rlat)), wrap360(rad2deg(dest_rlong))]
    
func get_meters_per_pixel(zoom_lvl, latitude):
    return 156543.03392 * cos(latitude * PI / 180) / pow(2, zoom_lvl + 1)
    
func get_next_tile_from_center(center_lat, center_long, zoom_lvl, bearing):
    var meters_per_px = get_meters_per_pixel(zoom_lvl, center_lat)
    var distance = meters_per_px * 640
    var next_tile_center = get_dest_from_bearing_range(center_lat, center_long, distance, bearing)
    return next_tile_center

func get_neighbor_tile_centers(center_lat, center_long, zoom_lvl):
    var north_tile_center = get_next_tile_from_center(center_lat, center_long, zoom_lvl, 0)
    var north_east_tile_center = get_next_tile_from_center(north_tile_center[0], north_tile_center[1], zoom_lvl, 90)
    var east_tile_center = get_next_tile_from_center(center_lat, center_long, zoom_lvl, 90)
    var south_east_tile_center = get_next_tile_from_center(east_tile_center[0], east_tile_center[1], zoom_lvl, 180)
    var south_tile_center = get_next_tile_from_center(center_lat, center_long, zoom_lvl, 180)
    var south_west_tile_center = get_next_tile_from_center(south_tile_center[0], south_tile_center[1], zoom_lvl, 270)
    var west_tile_center = get_next_tile_from_center(center_lat, center_long, zoom_lvl, 270)
    var north_west_tile_center = get_next_tile_from_center(west_tile_center[0], west_tile_center[1], zoom_lvl, 0)
   
func get_bearing_n_range(lat1, long1, lat2, long2):
    var distance = haversine_v0(lat1, long1, lat2, long2)  # distance == range
    var bearing = bearing_from_to(lat1, long1, lat2, long2)
    return [bearing, distance]

# The mapping between latitude, longitude and pixels is defined by the web mercator projection.
# https://developers.google.com/maps/documentation/javascript/examples/map-coordinates?hl=ko
# https://developers.google.com/maps/documentation/javascript/coordinates
func apply_projection(lat, long, tile_size):
    var siny = sin((lat * PI) / 180.0)
    # Truncating to 0.9999 effectively limits latitude to 89.189. This is
    # about a third of a tile past the edge of the world tile.
    if siny < -0.9999:
        siny = -0.9999
    if siny > 0.9999:
        siny = 0.9999
    var long_to_x = tile_size * (0.5 + long / 360.0)
    var lat_to_y = tile_size * (0.5 - log((1.0 + siny) / (1.0 - siny)) / (4.0 * PI))
    return [long_to_x, lat_to_y]


func convert_lat_long_to_pixel(lat, long, zoom):
    var projected_lat_long = apply_projection(lat, long, 256)  # 256 is the constant used by Google.
    lat = projected_lat_long[0]
    long = projected_lat_long[1]
    var total_x = int(lat * pow(2, zoom))
    var total_y = int(long * pow(2, zoom))
    return [total_x, total_y]

func convert_pixel_to_projection(x, y, zoom):
    var scale = pow(2, zoom)
    var projection_x = x / scale
    var projection_y = y / scale
    return [projection_x, projection_y]

func convert_pixel_to_projection_attempt_beter(x, y, zoom):
    # Ultimately this failed: time to move on.
    # https://stackoverflow.com/questions/7477003/calculating-new-longitude-latitude-from-old-n-meters
    var scale = pow(2, zoom)
    var lat_quotient = floor(x / 256)
    var long_qoutient = floor(y / 256)
    var lat_whole = lat_quotient * 256
    var long_whole = long_qoutient * 256
    var lat_remains = x - lat_whole
    var long_remains = y - long_whole
    var almost_lat = lat_whole / scale
    var almost_long = long_whole / scale
    # to make all of the extra stuff work below, we would have to accept that 
    # the calculated projection value would always be off, and then we have to 
    # pass out the remain meters and in the final conversion to lat long we 
    # could then add in the missing meters and then maybe it would come out 
    # correctly.
    print("almost_lat = " + str(almost_lat) + " | lat_remains = " + str(lat_remains))
    print("almost_long = " + str(almost_long) + " | long_remains = " + str(long_remains))
    var lat_long = convert_projection_to_lat_long(almost_lat, almost_long, zoom, 256)
    var mets_per_px = get_meters_per_pixel(zoom, lat_long[0])
    print("Meters Per Pixel = %0.8f" % mets_per_px)
    var mets_in_lat = mets_per_px * lat_remains
    # number of km per degree = ~111km (111.32 in google maps, but range varies
    # between 110.567km at the equator and 111.699km at the poles)
    # 1km in degree = 1 / 111.32km = 0.0089
    # 1m in degree = 0.0089 / 1000 = 0.0000089
    var coef = mets_in_lat *  0.000008983
    print("coef = " + str(coef))
    var lat = almost_lat + coef
    print("lat = " + str(lat) + " | almost_lat = " + str(almost_lat))
    return [almost_lat, almost_long]

func total_tiles_at_zoom(zoom):
    return pow(2, zoom) * pow(2, zoom)
    
func get_tile_coordinates_from_x_y(x, y, tile_size):
    return [int(x / tile_size), int(y / tile_size)]

func convert_projection_to_lat_long(projected_x, projected_y, zoom, tile_size):  #reverse_projection
    # https://gis.stackexchange.com/questions/66247/what-is-the-formula-for-calculating-world-coordinates-for-a-given-latlng-in-goog
    var long = projected_x / 256 * 360 - 180
    var n = PI - 2 * PI * projected_y / 256
    var lat = (180 / PI * atan(0.5 * (exp(n) - exp(-n))))
    return [lat, long]
    
func convert_pixel_to_lat_long(x, y, zoom, tile_size):
    var result = convert_pixel_to_projection(x, y, zoom)
    return convert_projection_to_lat_long(result[0], result[1], zoom, tile_size)

func set_map_origin(lat, long, zoom):
    map_origin_lat = lat
    map_origin_long = long
    var results = convert_lat_long_to_pixel(lat, long, zoom)
    map_origin_x = results[0]
    map_origin_y = results[1]

func calc_map_movement(player_new_lat, player_new_long, zoom):  # We move the map because the player is the center of our universe.
    var results = convert_lat_long_to_pixel(player_new_lat, player_new_long, zoom)
    moved_x = results[0] - map_origin_x
    moved_y = map_origin_y - results[1]
    return [moved_x, moved_y]

# Long Name: plot_entity_by_lat_long_from_origin_in_px()
func plot_entity(entity_lat, entity_long, zoom):
    var results = convert_lat_long_to_pixel(entity_lat, entity_long, zoom)
    var entity_x = map_origin_x - results[0]
    var entity_y = results[1] - map_origin_y
    return [entity_x, entity_y]

# Specifically when enough of a difference in latitude will cause a change in "y" pixel coordinates.
func calc_difference_for_lat_change():
    if map_orig_lat == null:
        return null
    var diff = 0.0
    var var_lat = map_orig_lat
    var pos_diff_lat = 0.0
    var neg_diff_lat = 0.0
    var temp_y
    while true:
        var_lat += 0.0000001
        temp_y = plot_entity(var_lat, map_orig_long)[1]
        if temp_y == 1:
            pos_diff_lat = var_lat - map_orig_lat
            break
    var_lat = map_orig_lat
    while true:
        var_lat -= 0.0000001
        temp_y = plot_entity(var_lat, map_orig_long)[1]
        if temp_y == -1:
            neg_diff_lat = map_orig_lat - var_lat
            break
    diff = neg_diff_lat + pos_diff_lat
    return diff

# Specifically when enough of a difference in longitude will cause a change in "x" pixel coordinates.
func calc_difference_for_long_change():  
    if map_orig_long == null:
        return null
    var diff = 0.0
    var var_long = map_orig_long
    var pos_diff_long = 0.0
    var neg_diff_long = 0.0
    var temp_x
    while true:
        var_long += 0.0000001
        temp_x = plot_entity(map_orig_lat, var_long)[0]
        if temp_x == 1:
            pos_diff_long = var_long - map_orig_long
            break
    var_long = map_orig_long
    while true:
        var_long -= 0.0000001
        temp_x = plot_entity(map_orig_lat, var_long)[0]
        if temp_x == -1:
            neg_diff_long = map_orig_long - var_long
            break
    diff = neg_diff_long + pos_diff_long
    return diff
    
