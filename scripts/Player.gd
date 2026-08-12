extends CharacterBody3D

const SPEED := 6.0
const JUMP_VEL := 9.0
const GRAVITY := -20.0
const MOUSE_SENS := 0.003
const TOUCH_SENS := 0.004

var peer_id: int = 0
var is_local: bool = false
var player_name: String = "Player"
var role: RoleManager.Role = RoleManager.Role.INNOCENT
var is_dead: bool = false
var has_gun: bool = false

var joy_touch_id: int = -1
var joy_origin: Vector2 = Vector2.ZERO
var joy_delta: Vector2 = Vector2.ZERO
var look_touch_id: int = -1
var look_prev: Vector2 = Vector2.ZERO

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var name_lbl: Label3D = $NameLabel
@onready var melee_col: CollisionShape3D = $MeleeArea/MeleeShape
@onready var pickup_area: Area3D = $PickupArea

const ROLE_COLORS := {
    RoleManager.Role.INNOCENT: Color(0.2, 0.5, 0.9),
    RoleManager.Role.MURDERER: Color(0.9, 0.1, 0.1),
    RoleManager.Role.SHERIFF:  Color(0.9, 0.8, 0.1),
    RoleManager.Role.HERO:     Color(0.1, 0.9, 0.4),
    RoleManager.Role.DEAD:     Color(0.3, 0.3, 0.3),
}

func setup(pid: int, local: bool, pname: String) -> void:
    peer_id = pid
    is_local = local
    player_name = pname
    name_lbl.text = pname
    if not local:
        camera.current = false
    else:
        camera.current = true
        name_lbl.visible = false
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    _set_role_color()

func set_role(r: RoleManager.Role) -> void:
    role = r
    has_gun = (r == RoleManager.Role.SHERIFF)
    melee_col.disabled = (r != RoleManager.Role.MURDERER)
    _set_role_color()

func give_gun() -> void:
    has_gun = true
    role = RoleManager.Role.HERO
    _set_role_color()
    AudioManager.play("pickup")

func _set_role_color() -> void:
    var mat := StandardMaterial3D.new()
    var col: Color = ROLE_COLORS.get(role, Color(0.5, 0.5, 0.5))
    mat.albedo_color = col
    mesh.surface_material_override[0] = mat

func _ready() -> void:
    set_process(is_local)
    set_physics_process(is_local)
    set_process_input(is_local)
    pickup_area.area_entered.connect(_on_pickup_area)
    $MeleeArea.body_entered.connect(_on_melee_touch)

func _input(event: InputEvent) -> void:
    if not is_local or is_dead:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENS)
        head.rotate_x(-event.relative.y * MOUSE_SENS)
        head.rotation.x = clamp(head.rotation.x, -1.2, 1.2)
    if event is InputEventScreenTouch:
        _handle_screen_touch(event)
    if event is InputEventScreenDrag:
        _handle_screen_drag(event)
    if event is InputEventKey and event.keycode == KEY_ESCAPE:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _handle_screen_touch(e: InputEventScreenTouch) -> void:
    var is_left: bool = e.position.x < get_viewport().get_visible_rect().size.x * 0.35
    if e.pressed:
        if is_left and joy_touch_id < 0:
            joy_touch_id = e.index
            joy_origin = e.position
            joy_delta = Vector2.ZERO
        elif not is_left and look_touch_id < 0:
            look_touch_id = e.index
            look_prev = e.position
    else:
        if e.index == joy_touch_id:
            joy_touch_id = -1
            joy_delta = Vector2.ZERO
        elif e.index == look_touch_id:
            look_touch_id = -1

func _handle_screen_drag(e: InputEventScreenDrag) -> void:
    if e.index == joy_touch_id:
        joy_delta = (e.position - joy_origin).limit_length(60.0)
    elif e.index == look_touch_id:
        var d: Vector2 = e.position - look_prev
        look_prev = e.position
        rotate_y(-d.x * TOUCH_SENS)
        head.rotate_x(-d.y * TOUCH_SENS)
        head.rotation.x = clamp(head.rotation.x, -1.2, 1.2)

func _physics_process(delta: float) -> void:
    if not is_local or is_dead:
        return
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    else:
        velocity.y = 0.0
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VEL
        AudioManager.play("footstep")
    var dir := Vector3.ZERO
    if joy_touch_id >= 0:
        dir = Vector3(joy_delta.x, 0, joy_delta.y).normalized()
    else:
        var key_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        dir = Vector3(key_dir.x, 0, key_dir.y)
    if dir.length() > 0.1:
        var fwd: Vector3 = transform.basis * dir
        velocity.x = fwd.x * SPEED
        velocity.z = fwd.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED * 4 * delta)
        velocity.z = move_toward(velocity.z, 0, SPEED * 4 * delta)
    move_and_slide()
    if Engine.get_physics_frames() % 3 == 0:
        _rpc_sync.rpc(global_position, rotation, head.rotation.x)

@rpc("any_peer", "unreliable")
func _rpc_sync(pos: Vector3, rot: Vector3, head_x: float) -> void:
    if is_local:
        return
    global_position = pos
    rotation = rot
    if head:
        head.rotation.x = head_x

func do_action() -> void:
    if is_dead:
        return
    match role:
        RoleManager.Role.MURDERER:
            _try_stab()
        RoleManager.Role.SHERIFF, RoleManager.Role.HERO:
            _try_shoot()

func _try_stab() -> void:
    melee_col.disabled = false
    AudioManager.play("knife")
    await get_tree().create_timer(0.3).timeout
    melee_col.disabled = true

func _try_shoot() -> void:
    if not has_gun:
        return
    AudioManager.play("gunshot")
    var space := get_world_3d().direct_space_state
    var from: Vector3 = camera.global_position
    var to: Vector3 = from - camera.global_transform.basis.z * 30.0
    var query := PhysicsRayQueryParameters3D.create(from, to, 1)
    var hit := space.intersect_ray(query)
    if hit and hit.collider is CharacterBody3D:
        var target := hit.collider as CharacterBody3D
        var tid: int = target.get_meta("peer_id", -1)
        if tid < 0:
            return
        if multiplayer.is_server():
            _server_handle_shoot(peer_id, tid)
        else:
            _rpc_request_shoot.rpc_id(1, peer_id, tid)

@rpc("any_peer", "reliable")
func _rpc_request_shoot(shooter_id: int, target_id: int) -> void:
    if not multiplayer.is_server():
        return
    _server_handle_shoot(shooter_id, target_id)

func _server_handle_shoot(shooter_id: int, target_id: int) -> void:
    var target_role: RoleManager.Role = RoleManager.get_role(target_id)
    if target_role == RoleManager.Role.MURDERER:
        _rpc_die.rpc_id(target_id)
        RoleManager.on_murderer_killed()
    else:
        _rpc_die.rpc_id(shooter_id)
        RoleManager.on_sheriff_killed_innocent(shooter_id, target_id)
        var snode: Node = GameManager.player_nodes.get(shooter_id)
        if snode:
            var gm: Node3D = get_tree().current_scene as Node3D
            if gm and gm.has_method("spawn_dropped_gun"):
                gm.spawn_dropped_gun(snode.global_position + Vector3(0, 0.3, 0))
    _rpc_kill_feed.rpc(shooter_id, target_id)

@rpc("authority", "call_local", "reliable")
func _rpc_die() -> void:
    die()

func die() -> void:
    if is_dead:
        return
    is_dead = true
    role = RoleManager.Role.DEAD
    mesh.transparency = 0.6
    AudioManager.play("death")
    name_lbl.text += " [DEAD]"
    if is_local:
        camera.current = false
        var hud_node: Node = get_tree().root.find_child("HUD", true, false)
        if hud_node and hud_node.has_method("enter_spectate"):
            hud_node.enter_spectate()

@rpc("authority", "call_local", "reliable")
func _rpc_kill_feed(shooter_id: int, target_id: int) -> void:
    var sname: String = NetworkManager.players.get(shooter_id, {}).get("name", "?")
    var tname: String = NetworkManager.players.get(target_id, {}).get("name", "?")
    var hud_node: Node = get_tree().root.find_child("HUD", true, false)
    if hud_node and hud_node.has_method("add_kill"):
        hud_node.add_kill(sname + " → " + tname)

func _on_melee_touch(body: Node3D) -> void:
    if role != RoleManager.Role.MURDERER or is_dead:
        return
    if not (body is CharacterBody3D):
        return
    var tid: int = body.get_meta("peer_id", -1)
    if tid < 0 or tid == peer_id:
        return
    if multiplayer.is_server():
        _server_handle_kill(tid)
    else:
        _rpc_request_kill.rpc_id(1, tid)

@rpc("any_peer", "reliable")
func _rpc_request_kill(target_id: int) -> void:
    if multiplayer.is_server():
        _server_handle_kill(target_id)

func _server_handle_kill(target_id: int) -> void:
    var tr: RoleManager.Role = RoleManager.get_role(target_id)
    if tr == RoleManager.Role.DEAD:
        return
    if tr == RoleManager.Role.SHERIFF or tr == RoleManager.Role.HERO:
        var tnode: Node = GameManager.player_nodes.get(target_id)
        if tnode:
            var gm: Node3D = get_tree().current_scene as Node3D
            if gm and gm.has_method("spawn_dropped_gun"):
                gm.spawn_dropped_gun(tnode.global_position + Vector3(0, 0.3, 0))
    _rpc_die.rpc_id(target_id)
    GameManager.player_died(target_id)
    _rpc_kill_feed.rpc(peer_id, target_id)

func _on_pickup_area(area: Area3D) -> void:
    if is_dead:
        return
    if area.has_method("pickup_coin"):
        area.pickup_coin(peer_id)
    elif area.has_method("pickup_gun"):
        if role == RoleManager.Role.INNOCENT:
            area.pickup_gun(peer_id)
            give_gun()
            _rpc_notify_hero.rpc_id(1, peer_id)

@rpc("any_peer", "reliable")
func _rpc_notify_hero(pid: int) -> void:
    if multiplayer.is_server():
        RoleManager.on_gun_picked_up(pid)
