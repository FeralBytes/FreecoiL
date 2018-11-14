extends ColorRect

onready var TeamWidget = get_node("TeamWidget")
onready var PlayerWidget = get_node("ColorRect/PlayerWidget")
onready var PlayerLbl = get_node("ColorRect/PlayerLbl")
# Called when the node enters the scene tree for the first time.
func _ready():
    if not SettingsConf.S.QuickStart.teams:
        PlayerWidget.visible = false
        PlayerLbl.visible = false
    calc_players_per_team()
    TeamWidget.set_val(SettingsConf.S.QuickStart.player_team)
    PlayerWidget.set_val(SettingsConf.S.QuickStart.player_number)

func update_player_id():
    SettingsConf.S.QuickStart.player_id = ((SettingsConf.S.QuickStart.player_team - 1) * LazerInterface.players_per_team) + SettingsConf.S.QuickStart.player_number

func calc_players_per_team():
    LazerInterface.players_per_team = LazerInterface.MAX_PLAYERS / SettingsConf.S.QuickStart.num_of_teams

func _on_TeamWidget_PMWidChanged(new_val):
    if new_val > SettingsConf.S.QuickStart.num_of_teams:
        TeamWidget.set_val(SettingsConf.S.QuickStart.num_of_teams)
    else:
        SettingsConf.S.QuickStart.player_team = new_val
        update_player_id()


func _on_PlayerWidget_PMWidChanged(new_val):
    if new_val > LazerInterface.players_per_team:
        PlayerWidget.set_val(LazerInterface.players_per_team)
    else:
        SettingsConf.S.QuickStart.player_number = new_val
        update_player_id()
