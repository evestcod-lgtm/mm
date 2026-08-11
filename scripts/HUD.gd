extends Control

var game_node: Node3D
var role: RoleManager.Role = RoleManager.Role.INNOCENT
var _is_spectating: bool = false
var _spectate_ids: Array = []
var _spectate_idx: int = 0

const ROLE_NAMES := {
    RoleManager.Role.INNOCENT: "INNOCENT",
    RoleManager.Role.MURDERER: "MURDERER 🔪",
    RoleManager.Role.SHERIFF:  "SHERIFF 🔫",
    RoleManager.Role.HERO:     "HERO 🔫",
    RoleManager.Role.DEAD:     "DEAD",
}
const ROLE_COLORS := {
    RoleManager.Role.INNOCENT: Color(0.3, 0.7, 1.0),
    RoleManager.Role.MURDERER: Color(1.0, 0.1, 0.1),
    RoleManager.Role.SHERIFF:  Color(1.0, 0.85, 0.1),
    RoleManager.Role.HERO:     Color(0.1, 0.9, 0.4),
    RoleManager.Role.DEAD:     Color(0.5, 0.5, 0.5),
}

@onready var role_lbl:     Label          = $RolePanel/RoleLabel
@onready var coins_lbl:    Label          = $CoinsLabel
@onready var alive_lbl:    Label          = $PlayersAlive
@onready var kill_feed:    VBoxContainer  = $KillFeed
@onready var action_btn:   Button         = $ActionBtn
@onready var jump_btn:     Button         = $JumpBtn
@onready var role_reveal:  Label          = $RoleReveal
@onready var spectator_lbl:Label          = $SpectatorLabel
@onready var kill_msg:     Label          = $KillMsg

func _ready() -> void:
    action_btn.pressed.connect(_do_action)
    jump_btn.pressed.connect(_do_jump)
    RoleManager.player_eliminated.connect(_on_eliminated)
    _update_alive()

func _process(_delta: float) -> void:
    var my_id := multiplayer.get_unique_id()
    coins_lbl.text = "🪙 %d" % GameManager.get_coins(my_id)

func set_role(r: RoleManager.Role) -> void:
    role = r
    var rname := ROLE_NAMES.get(r, "?")
    var rcol  := ROLE_COLORS.get(r, Color.WHITE)
    role_lbl.text = rname
    role_lbl.theme_override_colors["font_color"] = rcol
    # Big role reveal popup
    role_reveal.text = "YOU ARE\n" + rname
    role_reveal.theme_override_colors["font_color"] = rcol
    role_reveal.visible = true
    get_tree().create_timer(3.0).timeout.connect(func(): role_reveal.visible = false)
    # Update action button label
    match r:
        RoleManager.Role.MURDERER:
            action_btn.text = "STAB [F]"
        RoleManager.Role.SHERIFF, RoleManager.Role.HERO:
            action_btn.text = "SHOOT [F]"
        _:
            action_btn.text = "ACTION [F]"

func _do_action() -> void:
    var my_id := multiplayer.get_unique_id()
    var p := GameManager.player_nodes.get(my_id)
    if p and p.has_method("do_action"):
        p.do_action()

func _do_jump() -> void:
    Input.action_press("jump")
    await get_tree().create_timer(0.08).timeout
    Input.action_release("jump")

func add_kill(text: String) -> void:
    var lbl := Label.new()
    lbl.text = text
    lbl.theme_override_font_sizes["font_size"] = 15
    lbl.theme_override_colors["font_color"] = Color(1, 0.4, 0.4, 0.9)
    kill_feed.add_child(lbl)
    await get_tree().create_timer(6.0).timeout
    if is_instance_valid(lbl):
        lbl.queue_free()

func _on_eliminated(pid: int) -> void:
    _update_alive()
    var pname: String = NetworkManager.players.get(pid, {}).get("name", "?")
    add_kill(pname + " eliminated")

func _update_alive() -> void:
    alive_lbl.text = "Alive: %d" % RoleManager.alive.size()

func enter_spectate() -> void:
    _is_spectating = true
    spectator_lbl.visible = true
    action_btn.visible = false
    jump_btn.visible = false
    _spectate_ids = RoleManager.alive.duplicate()
    _spectate_idx = 0
    if _spectate_ids.size() > 0:
        _watch(_spectate_ids[0])
    # Tap right half to cycle targets
    var tap_btn := Button.new()
    tap_btn.text = "NEXT PLAYER ▶"
    tap_btn.anchor_left = 0.38
    tap_btn.anchor_right = 0.62
    tap_btn.anchor_top = 0.90
    tap_btn.anchor_bottom = 0.98
    tap_btn.theme_override_font_sizes["font_size"] = 16
    tap_btn.pressed.connect(_cycle_spectate)
    add_child(tap_btn)

func _cycle_spectate() -> void:
    if _spectate_ids.is_empty():
        return
    _spectate_idx = (_spectate_idx + 1) % _spectate_ids.size()
    _watch(_spectate_ids[_spectate_idx])

func _watch(pid: int) -> void:
    var p := GameManager.player_nodes.get(pid)
    if not p:
        return
    var cam := p.get_node_or_null("Head/Camera3D") as Camera3D
    if cam:
        cam.current = true
    spectator_lbl.text = "SPECTATING: " + NetworkManager.players.get(pid, {}).get("name","?")
