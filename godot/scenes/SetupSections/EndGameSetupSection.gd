extends ColorRect

var minutes

onready var EndGame = get_node("EndGameWidget")
onready var Limit = get_node("PlusMinusWidget")


# Called when the node enters the scene tree for the first time.
func _ready():
    add_default_end_game()
    set_selected()
    
func set_selected():
    if SettingsConf.S.QuickStart.end_game == "deaths":
        EndGame.set_selected_by_index(0)
    elif SettingsConf.S.QuickStart.end_game == "time":
        EndGame.set_selected_by_index(1)
    
func add_default_end_game():
    # Each Item is always added in the same order to make setting this possible.
    EndGame.add_option("Death Limit", "deaths")  # 0
    EndGame.add_option("Time Limit Minutes", "time")  # 1


func _on_EndGameWidget_LRWidChanged(new_setting):
    SettingsConf.S.QuickStart.end_game = new_setting
    if SettingsConf.S.QuickStart.end_game == "deaths":
        Limit.set_val(SettingsConf.S.QuickStart.end_game_death_limit)
    elif SettingsConf.S.QuickStart.end_game == "time":
        Limit.set_val(SettingsConf.S.QuickStart.end_game_time_limit / 60)


func _on_PlusMinusWidget_PMWidChanged(new_val):
    if SettingsConf.S.QuickStart.end_game == "deaths":
        SettingsConf.S.QuickStart.end_game_death_limit = new_val
    if SettingsConf.S.QuickStart.end_game == "time":
        SettingsConf.S.QuickStart.end_game_time_limit = new_val * 60
