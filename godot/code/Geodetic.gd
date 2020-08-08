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
    return c * radius

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
    var delta_long = rlong2 - rlong1
    var x = cos(rlat1) * sin(rlat2) - sin(rlat1) * cos(rlat2) * cos(delta_long)
    var y = sin(delta_long) * cos(rlat2)
    var bearing_rad = atan2(y, x)
    var bearing_deg = wrap360(rad2deg(bearing_rad))
    return bearing_deg
    
func wrap360(degrees_beyond):
    degrees_beyond = float(degrees_beyond)
    if 0.0 <= degrees_beyond and degrees_beyond < 360.0:
        return degrees_beyond
    else:
        return fmod((fmod(degrees_beyond, 360.0) + 360.0), 360.0)
