extends Control

@onready var players_box:  VBoxContainer = $PlayersBox
@onready var ip_label:     Label         = $IPLabel
@onready var btn_start:    Button        = $BtnStart
@onready var status_label: Label         = $StatusLabel

func _ready() -> void:
    NetworkManager.player_joined.connect(_refresh_any)
    NetworkManager.player_left.connect(_refresh_any)
    NetworkManager.server_gone.connect(_on_server_gone)
    btn_start.pressed.connect(_start_vote)
    $BtnLeave.pressed.connect(_leave)
    btn_start.visible = multiplayer.is_server()
    ip_label.text = "Your IP: " + NetworkManager.get_local_ip() + "  (auto-discovery active)"
    _refresh()

func _refresh_any(_a = null, _b = null) -> void:
    _refresh()

func _refresh() -> void:
    for c in players_box.get_children():
        c.queue_free()
    var my_id := multiplayer.get_unique_id()
    for pid in NetworkManager.players:
        var info: Dictionary = NetworkManager.players[pid]
        var lbl := Label.new()
        var n: String = info.get("name", "Player")
        var you := " ◀ YOU" if pid == my_id else ""
        var host_tag := " [HOST]" if pid == 1 else ""
        lbl.text = "• " + n + host_tag + you
        lbl.theme_override_font_sizes["font_size"] = 22
        lbl.theme_override_colors["font_color"] = (
            Color(0.9, 0.85, 0.1) if pid == 1 else Color(0.9, 0.9, 0.9)
        )
        players_box.add_child(lbl)
    var cnt := NetworkManager.get_player_count()
    status_label.text = "Players: %d / 5%s" % [
        cnt, "" if cnt >= 2 else "  (need at least 2 to start)"
    ]
    btn_start.disabled = cnt < 2

func _start_vote() -> void:
    if not multiplayer.is_server():
        return
    _rpc_start_vote.rpc()

@rpc("authority", "call_local", "reliable")
func _rpc_start_vote() -> void:
    var vote: Node = load("res://scenes/ui/VoteUI.tscn").instantiate()
    get_tree().root.add_child(vote)
    queue_free()

func _leave() -> void:
    NetworkManager.disconnect_all()
    GameManager.return_to_menu()

func _on_server_gone() -> void:
    status_label.text = "Host disconnected!"
    await get_tree().create_timer(2.0).timeout
    GameManager.return_to_menu()
