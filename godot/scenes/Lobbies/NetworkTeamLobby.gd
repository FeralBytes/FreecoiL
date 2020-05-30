extends Control

var player_readied
onready var TeamWidget = get_node("ChooseTeam/TeamWidget")
onready var TeamsLR = get_node("LobbyPlayers/TeamsLeftRightWidget")
onready var TeamGrid = get_node("LobbyPlayers/ScrollContainer/TeamGrid")
onready var ReadyGameBtn = get_node("ReadyGameBtn")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lobby")
    calc_players_per_team()
    TeamWidget.allow_zero = true
    TeamWidget.set_val(0)
    TeamsLR.clear_options()
    for i in range(1, SetConf.Session.num_of_teams + 1):
        TeamsLR.add_option("Team #" + str(i), i)
    TeamsLR.set_selected_by_index(0)

func calc_players_per_team():
    FreecoiLInterface.players_per_team = FreecoiLInterface.MAX_PLAYERS / SetConf.Session.num_of_teams

func _on_TeamWidget_PMWidChanged(new_val):
    if new_val > SetConf.Session.num_of_teams:
        TeamWidget.set_val(SetConf.Session.num_of_teams)
    else:
        SetConf.Session.player_team = new_val
        # Player ID gets updated by the server.
        if new_val - 1 == TeamsLR.list_selected:
            _on_TeamsLeftRightWidget_LRWidChanged(new_val)

func _on_TeamsLeftRightWidget_LRWidChanged(team_num):
    for i in TeamGrid.get_children():
        i.queue_free()
    for player in NetworkingCode.players_data:
        if NetworkingCode.players_data[player]["player_team"] == team_num:
            var temp = load("res://scenes/Lobbies/LobbyPlayerBtn.tscn").instance()
            temp.text = NetworkingCode.players_data[player]["player_name"]
            TeamGrid.add_child(temp)

func _on_ReadyGameBtn_pressed():
    NetworkingCode.tell_server_i_am_ready()
    player_readied = true
    ReadyGameBtn.disabled = true

##########################################
# "lobby" group calls
##########################################
func lobby_update_team_grid():
    _on_TeamsLeftRightWidget_LRWidChanged(TeamsLR.list_options_setting[TeamsLR.list_selected])
    ReadyGameBtn.disabled = true
    if not player_readied:
        if NetworkingCode.my_data["player_team"] > 0:
            if NetworkingCode.my_data["player_number"] > 0:
                if NetworkingCode.my_data["player_id"] > 0:
                    ReadyGameBtn.disabled = false
