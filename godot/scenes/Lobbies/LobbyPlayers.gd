extends ColorRect

# Declare member variables here. Examples:
# var a = 2
onready var TeamGrid = get_node("ScrollContainer/TeamGrid")

# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("lobby")

#################################################
# "lobby" group calls
#################################################
func add_player_to_lobby(peer_id):
    update_team_grid()
    
func update_team_grid():
    for i in TeamGrid.get_children():
        i.queue_free()
    var viewing_team = 0
    for peer in NetworkingCode.players_data:
        print(NetworkingCode.players_data[peer])
        if NetworkingCode.players_data[peer]["player_team"] == viewing_team:
            var temp = load("res://scenes/Lobbies/LobbyPlayerBtn.tscn").instance()
            temp.text = NetworkingCode.players_data[peer]["player_name"]
            TeamGrid.add_child(temp)

