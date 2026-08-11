extends Node

const GAME_PORT    := 7777
const DISC_PORT    := 7778
const MAX_PLAYERS  := 5
const BROADCAST_INTERVAL := 1.5
const MAGIC := "MM_GAME_V1"

signal player_joined(id: int, info: Dictionary)
signal player_left(id: int)
signal connection_ok
signal connection_fail
signal server_gone
signal hosts_updated

var players: Dictionary = {}
var local_info: Dictionary = {"name": "Player"}
var is_host: bool = false

# Discovery
var _broadcast_udp: PacketPeerUDP
var _listen_udp: PacketPeerUDP
var _broadcast_timer: float = 0.0
var discovered_hosts: Dictionary = {}   # ip -> {name, time}
var _discovering: bool = false

func _ready() -> void:
    multiplayer.peer_connected.connect(_peer_up)
    multiplayer.peer_disconnected.connect(_peer_down)
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(_on_fail)
    multiplayer.server_disconnected.connect(_on_server_gone)

func _process(delta: float) -> void:
    if is_host and _broadcast_udp:
        _broadcast_timer -= delta
        if _broadcast_timer <= 0.0:
            _broadcast_timer = BROADCAST_INTERVAL
            _send_broadcast()
    if _discovering and _listen_udp:
        _read_broadcasts()
        _prune_hosts()

# ── Discovery ────────────────────────────────────────────────────────────────

func start_discovering() -> void:
    _discovering = true
    discovered_hosts.clear()
    _listen_udp = PacketPeerUDP.new()
    _listen_udp.set_broadcast_enabled(true)
    var err := _listen_udp.bind(DISC_PORT, "0.0.0.0")
    if err != OK:
        push_warning("MM: can't bind discovery port %d: %s" % [DISC_PORT, err])

func stop_discovering() -> void:
    _discovering = false
    if _listen_udp:
        _listen_udp.close()
        _listen_udp = null
    discovered_hosts.clear()

func _send_broadcast() -> void:
    if not _broadcast_udp:
        return
    var msg := "%s|%s|%d" % [MAGIC, local_info.name, GAME_PORT]
    _broadcast_udp.put_packet(msg.to_utf8_buffer())

func _read_broadcasts() -> void:
    while _listen_udp and _listen_udp.get_available_packet_count() > 0:
        var pkt := _listen_udp.get_packet()
        var ip  := _listen_udp.get_packet_ip()
        var txt := pkt.get_string_from_utf8()
        var parts := txt.split("|")
        if parts.size() >= 3 and parts[0] == MAGIC:
            var host_name := parts[1]
            var prev_size := discovered_hosts.size()
            discovered_hosts[ip] = {
                "name": host_name,
                "port": int(parts[2]),
                "time": Time.get_ticks_msec()
            }
            if discovered_hosts.size() != prev_size:
                hosts_updated.emit()

func _prune_hosts() -> void:
    var now := Time.get_ticks_msec()
    var changed := false
    for ip in discovered_hosts.keys():
        if now - discovered_hosts[ip].time > 5000:
            discovered_hosts.erase(ip)
            changed = true
    if changed:
        hosts_updated.emit()

# ── Hosting ──────────────────────────────────────────────────────────────────

func host(player_name: String) -> int:
    local_info.name = player_name
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_server(GAME_PORT, MAX_PLAYERS)
    if err != OK:
        return err
    multiplayer.multiplayer_peer = peer
    is_host = true
    players[1] = local_info.duplicate()
    # Start broadcasting presence
    _broadcast_udp = PacketPeerUDP.new()
    _broadcast_udp.set_broadcast_enabled(true)
    _broadcast_udp.bind(0)  # any local port
    _broadcast_udp.set_dest_address("255.255.255.255", DISC_PORT)
    _broadcast_timer = 0.0
    return OK

func join(ip: String, port: int, player_name: String) -> int:
    local_info.name = player_name
    stop_discovering()
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_client(ip, port)
    if err != OK:
        return err
    multiplayer.multiplayer_peer = peer
    is_host = false
    return OK

func disconnect_all() -> void:
    stop_discovering()
    if _broadcast_udp:
        _broadcast_udp.close()
        _broadcast_udp = null
    multiplayer.multiplayer_peer = null
    players.clear()
    is_host = false

# ── Multiplayer callbacks ─────────────────────────────────────────────────────

func _peer_up(id: int) -> void:
    if multiplayer.is_server():
        for pid in players:
            _rpc_send_info.rpc_id(id, pid, players[pid])

func _peer_down(id: int) -> void:
    players.erase(id)
    player_left.emit(id)

func _on_connected() -> void:
    var my_id := multiplayer.get_unique_id()
    players[my_id] = local_info.duplicate()
    _rpc_register.rpc(my_id, local_info)
    connection_ok.emit()

func _on_fail() -> void:
    multiplayer.multiplayer_peer = null
    connection_fail.emit()

func _on_server_gone() -> void:
    multiplayer.multiplayer_peer = null
    players.clear()
    server_gone.emit()

@rpc("any_peer", "reliable")
func _rpc_register(id: int, info: Dictionary) -> void:
    players[id] = info
    player_joined.emit(id, info)
    if multiplayer.is_server():
        _rpc_send_info.rpc(id, info)

@rpc("authority", "reliable")
func _rpc_send_info(id: int, info: Dictionary) -> void:
    players[id] = info
    player_joined.emit(id, info)

func get_player_count() -> int:
    return players.size()

func get_all_ids() -> Array:
    return players.keys()

func get_local_ip() -> String:
    for addr in IP.get_local_addresses():
        if (addr.begins_with("192.168.") or addr.begins_with("10.")
                or addr.begins_with("172.")):
            return addr
    return "unknown"
