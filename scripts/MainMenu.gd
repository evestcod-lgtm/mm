extends Control

@onready var name_input: LineEdit   = $Panel/VBox/NameInput
@onready var btn_host: Button       = $Panel/VBox/BtnHost
@onready var hosts_list: VBoxContainer = $Panel/VBox/HostsScroll/HostsList
@onready var status_lbl: Label      = $Panel/VBox/StatusLabel
@onready var local_ip_lbl: Label    = $LocalIP
@onready var no_hosts_lbl: Label    = $Panel/VBox/NoHostsLabel

func _ready() -> void:
    btn_host.pressed.connect(_on_host)
    $Panel/VBox/BtnQuit.pressed.connect(get_tree().quit)
    NetworkManager.connection_ok.connect(_on_connected)
    NetworkManager.connection_fail.connect(_on_fail)
    NetworkManager.hosts_updated.connect(_refresh_hosts)
    NetworkManager.server_gone.connect(_on_server_gone)
    local_ip_lbl.text = "My IP: " + NetworkManager.get_local_ip()
    NetworkManager.start_discovering()
    _refresh_hosts()

func _get_name() -> String:
    var n := name_input.text.strip_edges()
    return n if n.length() > 0 else "Player"

func _on_host() -> void:
    var err := NetworkManager.host(_get_name())
    if err == OK:
        status_lbl.text = "Hosting — waiting for players..."
        btn_host.disabled = true
        NetworkManager.stop_discovering()
        get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
    else:
        status_lbl.text = "Failed to host (port busy?)"

func _refresh_hosts() -> void:
    for c in hosts_list.get_children():
        c.queue_free()
    var hosts := NetworkManager.discovered_hosts
    no_hosts_lbl.visible = hosts.is_empty()
    for ip in hosts:
        var info: Dictionary = hosts[ip]
        var btn := Button.new()
        btn.text = "  %s   [%s]" % [info.get("name","?"), ip]
        btn.theme_override_font_sizes["font_size"] = 20
        btn.custom_minimum_size = Vector2(0, 52)
        btn.pressed.connect(_join.bind(ip, info.get("port", 7777)))
        hosts_list.add_child(btn)

func _join(ip: String, port: int) -> void:
    status_lbl.text = "Connecting to " + ip + "..."
    var err := NetworkManager.join(ip, port, _get_name())
    if err != OK:
        status_lbl.text = "Connection error"

func _on_connected() -> void:
    get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_fail() -> void:
    status_lbl.text = "Connection failed — host still up?"
    NetworkManager.start_discovering()

func _on_server_gone() -> void:
    status_lbl.text = "Host disconnected"
    NetworkManager.start_discovering()
