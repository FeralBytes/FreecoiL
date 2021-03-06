extends Control

var ColorPick = load("res://scenes/Widgets/TeamColorPicker.tscn") 

onready var TeamsColors = get_node("ColorRect/ScrollContainer/TeamsColorsContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
    on_teams_changed()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func on_teams_changed():
    for i in TeamsColors.get_children():
        i.queue_free()
    if SetConf.Session.teams:
        for team in range(1, SetConf.Session.num_of_teams + 1):
            var temp = ColorPick.instance()
            temp.text = "Team #" + str(team) + "'s Color ="
            temp.team_num = team
            TeamsColors.add_child(temp)
            #yield(get_tree(), "idle_frame")
            if SetConf.Session.team_colors.size() >= team:
                temp.set_color(SetConf.Session.team_colors[team - 1])
            else:
                SetConf.Session.team_colors.append("ffffff")
                temp.set_color("ffffff")


func _on_TeamSetupSection_on_teams_changed(teams_active):
    teams_active = null
    on_teams_changed()


func _on_TeamSetupSection_on_num_of_teams_changed(num_of_teams):
    num_of_teams = null
    on_teams_changed()


func _on_ContinueSetup_pressed():
    NetworkingCode.set_lobby_team_or_ffa_as_server(null)
    SceneManager.goto_scene("res://scenes/Setups/NetworkSetupCustom3.tscn")
