extends Node2D

const RADAR_PULSE_RATE = 0.2

var player_position = {}
var count = 0
var last_downloaded_tile_coords
var my_menu = "1,7"
var wifi_hub_set = false
var respawn_for_each_team_set = null

onready var MapDownloader = get_node("MapDownloader")
onready var CenterTile = get_node("MapMoverContainer/Center")
onready var MapEntity = preload("res://scenes/Maps/MapEntity.tscn")
onready var MapContainer = get_node("MapMoverContainer")
onready var PlayerMarker = get_node("PlayerMarker")
onready var Accuracy = get_node("UI/Label2")

# Called when the node enters the scene tree for the first time.
func _ready():
    Settings.Session.connect(Settings.Session.monitor_data("current_menu"), self, "check_if_visible")
    if Settings.Session.get_data("experimental_toggles")["map_downloads_testing"]:
        Settings.LiteAutoLoads.load_lightly("Geodetic", "res://code/Geodetic.gd")
        var initial_location = {"latitude": 41.850002, "longitude": -87.652191, "accuracy": 5, "timestamp": OS.get_unix_time()}
        Settings.Session.set_data("fi_current_location", initial_location)
        Settings.LiteAutoLoads.get_lightly("Geodetic").set_map_origin(
                41.850002,-87.652191, 19)
        Settings.Session.connect(Settings.Session.monitor_data("fi_current_location"), self, 
            "update_player_location")
        display_maps()
        change_player_location()
    
func check_if_visible(current_menu):
    if current_menu == my_menu:
        Settings.Session.connect(Settings.Session.monitor_data("fi_current_location"), self, 
            "update_player_location")
        display_maps()
        Accuracy.text = "Accuracy: " + str(Settings.Session.get_data("fi_current_location")["accuracy"])
    else:
        if is_connected(Settings.Session.monitor_data("fi_current_location"), self, "update_player_location"):
            Settings.Session.disconnect(Settings.Session.monitor_data("fi_current_location"), self, 
                "update_player_location")


func update_player_location(new_location):
    var map_container_new_xy = Settings.LiteAutoLoads.get_lightly("Geodetic").calc_map_movement(
        new_location["latitude"], new_location["longitude"], 19)
    print("New Map XY = " + str(map_container_new_xy))
    MapContainer.position.x = map_container_new_xy[0]
    MapContainer.position.y = map_container_new_xy[1]
    Accuracy.text = "Accuracy: " + str(new_location["accuracy"])
    highlight_player_marker()

func highlight_player_marker():
    PlayerMarker.polygon_color = Color("4f568c")
    yield(get_tree().create_timer(0.5), "timeout")
    PlayerMarker.polygon_color = Color("0018d8")
    
func display_maps():
    var texture = ImageTexture.new()
    var image = Image.new()
    image.load("user://maps/" + str(Settings.Session.get_data("map_origin_lat")) + "," +
        str(Settings.Session.get_data("map_origin_long")) + ".png")
    texture.create_from_image(image)
    CenterTile.texture = texture
    
func change_player_location():
    while true:
        var new_long = Settings.Session.get_data("fi_current_location")
        new_long["latitude"] += 0.0001
        new_long["timestamp"] = OS.get_unix_time()
        Settings.Session.set_data("fi_current_location", new_long)
        yield(get_tree().create_timer(5.0), "timeout")


func _on_SetPositionBtn_pressed():
    if not wifi_hub_set:
        # plot the wifi hub
        var wifi_hub_location = Settings.Session.get_data("fi_current_location")
        var WiFiHub = MapEntity.instance()
        MapEntity.name = "WiFiHub"
        CenterTile.add_child(MapEntity)
        var entity_x_y = Settings.LiteAutoLoads.get("Geodetic").plot_entity(wifi_hub_location["latitude"], 
            wifi_hub_location["longitude"], 19)
        MapEntity.position.x = entity_x_y[0]
        MapEntity.position.y = entity_x_y[1]
        # build the team array.
        Settings.Session.set_data("maps_wifi_hub_location", wifi_hub_location)
        if Settings.InGame.get_data("game_teams"):
            Settings.InGame.get_data("game_number_of_teams")
        else:
            pass
            # Get the number of respawn locations choosen.
