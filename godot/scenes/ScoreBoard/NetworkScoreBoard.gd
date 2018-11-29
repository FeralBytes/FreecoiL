extends Control

onready var ViewLR = get_node("ContainerSection/ViewLeftRightWidget")
onready var TheGrid = get_node("ContainerSection/ScrollContainer/TheGrid")
onready var MainMenuBtn = get_node("MainMenuBtn")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lobby")
    calc_players_per_team()
    ViewLR.clear_options()
    ViewLR.add_option("Team Score", 0)
    ViewLR.set_selected_by_index(0)

func calc_players_per_team():
    LazerInterface.players_per_team = LazerInterface.MAX_PLAYERS / SetConf.Session.num_of_teams

func _on_ViewLeftRightWidget_LRWidChanged(team_num):
    for i in TheGrid.get_children():
        i.queue_free()
    for player in NetworkingCode.players_data:
        if NetworkingCode.players_data[player]["player_team"] == team_num:
            var temp = load("res://scenes/Lobbies/LobbyPlayerBtn.tscn").instance()
            temp.text = NetworkingCode.players_data[player]["player_name"]
            TheGrid.add_child(temp)

func _on_ReadyGameBtn_pressed():
    NetworkingCode.tell_server_i_am_ready()

##########################################
# "lobby" group calls
##########################################
func lobby_update_team_grid():
    _on_ViewLeftRightWidget_LRWidChanged(ViewLR.list_options_setting[ViewLR.list_selected])
