extends Control

@onready var winner_lbl:  Label          = $Winner
@onready var roles_box:   VBoxContainer  = $RolesBox
@onready var coins_box:   HBoxContainer  = $CoinsBox
@onready var btn_menu:    Button         = $BtnMenu
@onready var auto_timer:  Timer          = $VoteTimer

const ROLE_NAMES := {
    RoleManager.Role.INNOCENT: "Innocent",
    RoleManager.Role.MURDERER: "Murderer",
    RoleManager.Role.SHERIFF:  "Sheriff",
    RoleManager.Role.HERO:     "Hero",
    RoleManager.Role.DEAD:     "Dead",
}
const ROLE_COLORS := {
    RoleManager.Role.INNOCENT: Color(0.3, 0.7, 1.0),
    RoleManager.Role.MURDERER: Color(1.0, 0.1, 0.1),
    RoleManager.Role.SHERIFF:  Color(1.0, 0.85, 0.1),
    RoleManager.Role.HERO:     Color(0.1, 0.9, 0.4),
    RoleManager.Role.DEAD:     Color(0.5, 0.5, 0.5),
}

func _ready() -> void:
    btn_menu.pressed.connect(_go_menu)
    auto_timer.timeout.connect(_go_menu)
    auto_timer.start()
    AudioManager.play("join")

func show_result(winner_role: String) -> void:
    # Header
    if winner_role == "Innocents":
        winner_lbl.text = "INNOCENTS WIN!"
        winner_lbl.theme_override_colors["font_color"] = Color(0.1, 0.9, 0.3)
        AudioManager.play("win")
    else:
        winner_lbl.text = "MURDERER WINS!"
        winner_lbl.theme_override_colors["font_color"] = Color(0.9, 0.1, 0.1)
        AudioManager.play("lose")
    # Role reveal
    for pid in RoleManager.roles:
        var lbl := Label.new()
        var pname: String = NetworkManager.players.get(pid, {}).get("name", "?")
        var r: RoleManager.Role = RoleManager.roles[pid]
        lbl.text = "%-16s  —  %s" % [pname, ROLE_NAMES.get(r, "?")]
        lbl.theme_override_colors["font_color"] = ROLE_COLORS.get(r, Color.WHITE)
        lbl.theme_override_font_sizes["font_size"] = 22
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        roles_box.add_child(lbl)
    # Coins
    for pid in GameManager.coins_collected:
        var vb := VBoxContainer.new()
        var nl := Label.new()
        nl.text = NetworkManager.players.get(pid, {}).get("name", "?")
        nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nl.theme_override_font_sizes["font_size"] = 16
        var cl := Label.new()
        cl.text = "🪙 %d" % GameManager.get_coins(pid)
        cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cl.theme_override_colors["font_color"] = Color(1.0, 0.85, 0.1)
        cl.theme_override_font_sizes["font_size"] = 20
        vb.add_child(nl)
        vb.add_child(cl)
        coins_box.add_child(vb)

func _go_menu() -> void:
    GameManager.return_to_menu()
