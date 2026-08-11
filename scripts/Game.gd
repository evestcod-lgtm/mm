extends Node3D

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const COIN_SCENE   := preload("res://scenes/items/Coin.tscn")
const GUN_SCENE    := preload("res://scenes/items/DroppedGun.tscn")
const HUD_SCENE    := preload("res://scenes/ui/HUD.tscn")
const END_SCENE    := preload("res://scenes/ui/EndScreen.tscn")

const MAPS := [
    preload("res://scenes/maps/Map_Mansion.tscn"),
    preload("res://scenes/maps/Map_Workshop.tscn"),
    preload("res://scenes/maps/Map_Rooftop.tscn"),
]
const SPAWN_POINTS := [
    Vector3(3, 0.1, 3), Vector3(-3, 0.1, 3),
    Vector3(3, 0.1, -3), Vector3(-3, 0.1, -3), Vector3(0, 0.1, 0)
]

var hud: Control
var _winner_str: String = ""

func _ready() -> void:
    _load_map()
    if multiplayer.is_server():
        _spawn_coins()
        await get_tree().create_timer(0.6).timeout
        _assign_roles_server()
    _spawn_players()
    _setup_hud()
    RoleManager.innocents_win.connect(_on_innocents_win)
    RoleManager.murderer_wins.connect(_on_murderer_wins)
    GameManager.round_ended.connect(_on_round_ended)

func _load_map() -> void:
    var idx := clampi(GameManager.vote_result, 0, MAPS.size() - 1)
    $MapRoot.add_child(MAPS[idx].instantiate())

func _spawn_players() -> void:
    var ids := NetworkManager.get_all_ids()
    for i in range(ids.size()):
        var pid: int = ids[i]
        var p := PLAYER_SCENE.instantiate()
        p.name = "Player_%d" % pid
        p.position = SPAWN_POINTS[i % SPAWN_POINTS.size()]
        p.set_meta("peer_id", pid)
        $PlayersRoot.add_child(p)
        GameManager.player_nodes[pid] = p
        var is_local := (pid == multiplayer.get_unique_id())
        p.setup(pid, is_local, NetworkManager.players[pid].get("name", "Player"))

func _assign_roles_server() -> void:
    RoleManager.assign_roles(NetworkManager.get_all_ids())
    for pid in RoleManager.roles:
        _rpc_set_role.rpc_id(pid, RoleManager.roles[pid] as int)

@rpc("authority", "call_local", "reliable")
func _rpc_set_role(role_int: int) -> void:
    var my_id := multiplayer.get_unique_id()
    var p := GameManager.player_nodes.get(my_id)
    if p and p.has_method("set_role"):
        p.set_role(role_int as RoleManager.Role)
    if hud and hud.has_method("set_role"):
        hud.set_role(role_int as RoleManager.Role)

func _spawn_coins() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for _i in range(22):
        var coin := COIN_SCENE.instantiate()
        coin.position = Vector3(
            rng.randf_range(-11.0, 11.0), 0.22,
            rng.randf_range(-11.0, 11.0)
        )
        $ItemsRoot.add_child(coin)
        _rpc_spawn_coin.rpc(coin.position)

@rpc("authority", "reliable")
func _rpc_spawn_coin(pos: Vector3) -> void:
    if multiplayer.is_server():
        return
    var coin := COIN_SCENE.instantiate()
    coin.position = pos
    $ItemsRoot.add_child(coin)

func _setup_hud() -> void:
    hud = HUD_SCENE.instantiate()
    $HUD.add_child(hud)
    hud.game_node = self

func spawn_dropped_gun(pos: Vector3) -> void:
    if not multiplayer.is_server():
        return
    _rpc_spawn_gun.rpc(pos)

@rpc("authority", "call_local", "reliable")
func _rpc_spawn_gun(pos: Vector3) -> void:
    var gun := GUN_SCENE.instantiate()
    gun.position = pos
    $ItemsRoot.add_child(gun)

func _on_innocents_win() -> void:
    _winner_str = "Innocents"

func _on_murderer_wins() -> void:
    _winner_str = "Murderer"

func _on_round_ended(winner: String) -> void:
    _winner_str = winner
    await get_tree().create_timer(1.2).timeout
    _show_end_screen.rpc(_winner_str)

@rpc("authority", "call_local", "reliable")
func _show_end_screen(winner: String) -> void:
    if not is_instance_valid(hud):
        return
    var end := END_SCENE.instantiate()
    get_tree().root.add_child(end)
    end.show_result(winner)
