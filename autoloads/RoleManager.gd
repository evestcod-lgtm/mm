extends Node

enum Role { INNOCENT, MURDERER, SHERIFF, HERO, DEAD }

var roles: Dictionary = {}
var alive: Array[int] = []
var sheriff_id: int = -1
var murderer_id: int = -1
var dropped_gun_owner: int = -1

signal role_assigned(peer_id: int, role: Role)
signal player_eliminated(peer_id: int)
signal innocents_win
signal murderer_wins

func assign_roles(peer_ids: Array) -> void:
    roles.clear()
    alive.clear()
    sheriff_id = -1
    murderer_id = -1

    var shuffled := peer_ids.duplicate()
    shuffled.shuffle()
    var count := shuffled.size()

    murderer_id = shuffled[0]
    roles[murderer_id] = Role.MURDERER

    if count >= 2:
        sheriff_id = shuffled[1]
        roles[sheriff_id] = Role.SHERIFF

    for i in range(2, count):
        roles[shuffled[i]] = Role.INNOCENT

    for pid in shuffled:
        alive.append(pid)

    for pid in roles:
        role_assigned.emit(pid, roles[pid])

func get_role(peer_id: int) -> Role:
    return roles.get(peer_id, Role.INNOCENT)

func on_player_died(peer_id: int) -> void:
    alive.erase(peer_id)
    roles[peer_id] = Role.DEAD
    player_eliminated.emit(peer_id)
    _check_win()

func on_murderer_killed() -> void:
    alive.erase(murderer_id)
    roles[murderer_id] = Role.DEAD
    player_eliminated.emit(murderer_id)
    innocents_win.emit()
    GameManager.end_round("Innocents")

func on_sheriff_killed_innocent(shooter_id: int, victim_id: int) -> void:
    alive.erase(shooter_id)
    roles[shooter_id] = Role.DEAD
    player_eliminated.emit(shooter_id)
    dropped_gun_owner = shooter_id
    _check_win()

func on_gun_picked_up(picker_id: int) -> void:
    if roles.get(picker_id, Role.DEAD) == Role.INNOCENT:
        roles[picker_id] = Role.HERO
        role_assigned.emit(picker_id, Role.HERO)

func _check_win() -> void:
    var innocents_alive: int = 0
    var murderer_alive: bool = (roles.get(murderer_id, Role.DEAD) as Role) != Role.DEAD
    for pid in alive:
        var r: Role = roles.get(pid, Role.DEAD) as Role
        if r == Role.INNOCENT or r == Role.SHERIFF or r == Role.HERO:
            innocents_alive += 1
    if not murderer_alive:
        innocents_win.emit()
        GameManager.end_round("Innocents")
    elif innocents_alive == 0:
        murderer_wins.emit()
        GameManager.end_round("Murderer")

func is_alive(pid: int) -> bool:
    return alive.has(pid)
