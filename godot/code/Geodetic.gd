extends Node

const EARTH_RADIUS = 6371000  # in meters
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
    var delta_rlong = rlong2 - rlong1
    var xb = cos(rlat2) * cos(delta_rlong)
    var yb = cos(rlat2) * sin(delta_rlong)
    var mid_rlat = atan2(sin(rlat1) + sin(rlat2), sqrt(cos(rlat1) + xb) * cos(rlat1) + yb * yb))
    var mid_rlong = atan2(yb, cos(rlat1) + xb)
    return [wrap360(rad2deg(mid_rlat)), wrap360(rad2deg(mid_rlong))]
    
func get_dest_from_bearing_range(start_lat, start_long, distance, bearing):
    var start_rlat = deg2rad(start_lat)
    var start_rlong = deg2rad(start_long)
    var dest_rlat = asin(sin(start_rlat) * cos(distance / EARTH_RADIUS) + cos(start_rlat) *
        sin(distance / EARTH_RADIUS) * cos(bearing))
    var dest_rlong = start_rlong + atan2(sin(bearing) * sin(distance / EARTH_RADIUS) * 
        cos(start_rlat), cos(distance / EARTH_RADIUS) - sin(start_rlat) * sin(dest_rlong)
    return [wrap360(rad2deg(dest_rlat)), wrap360(rad2deg(dest_rlong))]
    
func get_meters_per_pixel(zoom_lvl, latitude):
    return 156543.03392 cos(latitude * PI / 180) / pow(2, zoom_lvl + 1)
    
func get_next_tile_from_center(center_lat, center_long, zoom_lvl, bearing):
    var meters_per_px = get_meters_per_pixel(zomm_lvl, center_lat)
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
    var range = haversine_v0(lat1, long1, lat2, long2)
    var bearing = bearing_from_to(lat1, long1, lat2, long2)
    return [bearing, range]
 
 func calc_map_movement():
    pass
    
