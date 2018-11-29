extends ColorRect

onready var TeamWidget = get_node("TeamWidget")
onready var PlayerWidget = get_node("ColorRect/PlayerWidget")
onready var PlayerLbl = get_node("ColorRect/PlayerLbl")
# Called when the node enters the scene tree for the first time.
func _ready():
    if not SetConf.Session.teams:
        PlayerWidget.visible = false
        PlayerLbl.visible = false
    calc_players_per_team()
    TeamWidget.set_val(SetConf.Session.player_team)
    PlayerWidget.set_val(SetConf.Session.player_number)

func update_player_id():
    SetConf.Session.player_id = ((SetConf.Session.player_team - 1) * LazerInterface.players_per_team) + SetConf.Session.player_number

func calc_players_per_team():
    LazerInterface.players_per_team = LazerInterface.MAX_PLAYERS / SetConf.Session.num_of_teams

func _on_TeamWidget_PMWidChanged(new_val):
    if new_val > SetConf.Session.num_of_teams:
        TeamWidget.set_val(SetConf.Session.num_of_teams)
    else:
        SetConf.Session.player_team = new_val
        update_player_id()


func _on_PlayerWidget_PMWidChanged(new_val):
    if new_val > LazerInterface.players_per_team:
        PlayerWidget.set_val(LazerInterface.players_per_team)
    else:
        SetConf.Session.player_number = new_val
        update_player_id()
