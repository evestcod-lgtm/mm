extends Node

enum State { MENU, LOBBY, VOTING, PLAYING, END }

var state: State = State.MENU
var vote_result: int = 0
var coins_collected: Dictionary = {}
var player_nodes: Dictionary = {}

signal state_changed(new_state: State)
signal game_started
signal round_ended(winner: String)

func go_to_state(s: State) -> void:
    state = s
    state_changed.emit(s)

func load_lobby() -> void:
    go_to_state(State.LOBBY)
    get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func start_game(map_index: int) -> void:
    vote_result = map_index
    coins_collected.clear()
    player_nodes.clear()
    go_to_state(State.PLAYING)
    get_tree().change_scene_to_file("res://scenes/Game.tscn")
    game_started.emit()

func player_died(peer_id: int) -> void:
    RoleManager.on_player_died(peer_id)

func collect_coin(peer_id: int) -> void:
    coins_collected[peer_id] = coins_collected.get(peer_id, 0) + 1

func get_coins(peer_id: int) -> int:
    return coins_collected.get(peer_id, 0)

func end_round(winner_role: String) -> void:
    go_to_state(State.END)
    round_ended.emit(winner_role)

func return_to_menu() -> void:
    NetworkManager.disconnect_all()
    go_to_state(State.MENU)
    get_tree().change_scene_to_file("res://scenes/Main.tscn")
