extends Control

var votes: Dictionary = {}   # peer_id -> map_index
var vote_counts: Array = [0, 0, 0]
var my_vote: int = -1
var timer_left: float = 15.0

@onready var timer_lbl: Label = $Timer
@onready var status_lbl: Label = $StatusLabel
@onready var vote_timer: Timer = $VoteTimer
@onready var btns: Array = [$MapsBox/MapBtn0, $MapsBox/MapBtn1, $MapsBox/MapBtn2]

func _ready() -> void:
    for i in range(3):
        btns[i].pressed.connect(_vote.bind(i))
    vote_timer.timeout.connect(_finalize)
    vote_timer.start()

func _process(delta: float) -> void:
    timer_left -= delta
    timer_lbl.text = "%.0f" % max(0, timer_left)

func _vote(map_idx: int) -> void:
    if my_vote == map_idx:
        return
    my_vote = map_idx
    AudioManager.play("vote")
    _rpc_cast_vote.rpc(multiplayer.get_unique_id(), map_idx)
    status_lbl.text = "Voted for " + _map_name(map_idx)

@rpc("any_peer", "call_local", "reliable")
func _rpc_cast_vote(peer_id: int, map_idx: int) -> void:
    if votes.has(peer_id):
        vote_counts[votes[peer_id]] -= 1
    votes[peer_id] = map_idx
    vote_counts[map_idx] += 1
    _update_buttons()

func _update_buttons() -> void:
    var names := ["MANSION", "WORKSHOP", "ROOFTOP"]
    for i in range(3):
        btns[i].text = "%s\n\nVotes: %d" % [names[i], vote_counts[i]]

func _map_name(i: int) -> String:
    return ["Mansion", "Workshop", "Rooftop"][i]

func _finalize() -> void:
    var winner := vote_counts.find(vote_counts.max())
    if multiplayer.is_server():
        _rpc_start_game.rpc(winner)

@rpc("authority", "call_local", "reliable")
func _rpc_start_game(map_idx: int) -> void:
    GameManager.start_game(map_idx)
    queue_free()
