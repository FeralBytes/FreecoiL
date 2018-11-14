extends ColorRect

signal on_teams_changed
signal on_num_of_teams_changed

onready var TeamsBtn = get_node("TeamsBtn")
onready var NumOfTeams = get_node("NumOfTeams")
onready var HowManyLbl = get_node("HowManyTeamsLbl")
# Called when the node enters the scene tree for the first time.
func _ready():
    TeamsBtn.pressed = SettingsConf.S.QuickStart.teams
    NumOfTeams.set_val(SettingsConf.S.QuickStart.num_of_teams)
    _on_TeamsBtn_pressed()

func teams_active():
    HowManyLbl.visible = true
    NumOfTeams.visible = true

func teams_deactivated():
    HowManyLbl.visible = false
    NumOfTeams.visible = false

func _on_TeamsBtn_pressed():
    SettingsConf.S.QuickStart.teams = TeamsBtn.pressed
    if TeamsBtn.pressed:
        NumOfTeams.set_val(2)
        teams_active()
    else:
        NumOfTeams.set_val(62)
        teams_deactivated()
    emit_signal("on_teams_changed", TeamsBtn.pressed)
    

func _on_NumOfTeams_PMWidChanged(new_val):
    if SettingsConf.S.QuickStart.teams:
        if new_val <= 1:
            NumOfTeams.set_val(2)
        elif new_val >= LazerInterface.MAX_TEAMS + 1:
            NumOfTeams.set_val(LazerInterface.MAX_TEAMS)
        else:
            SettingsConf.S.QuickStart.num_of_teams = new_val
    else:
        SettingsConf.S.QuickStart.num_of_teams = new_val
    emit_signal("on_num_of_teams_changed", SettingsConf.S.QuickStart.num_of_teams)
