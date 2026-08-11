extends Node3D

var spawn_points: Array[Vector3] = [
    Vector3(2, 0.1, 2), Vector3(-2, 0.1, 4),
    Vector3(4, 0.1, -2), Vector3(-4, 0.1, -2), Vector3(0, 0.1, -4)
]

func _ready() -> void:
    _build()

func _build() -> void:
    # Floor - concrete
    _add_box(Vector3(0,-0.25,0), Vector3(28,0.5,28), Color(0.35,0.34,0.33))
    # Outer walls
    for d in [Vector3(0,1.5,-14), Vector3(0,1.5,14)]:
        _add_box(d, Vector3(28,3,0.5), Color(0.3,0.29,0.28))
    for d in [Vector3(-14,1.5,0), Vector3(14,1.5,0)]:
        _add_box(d, Vector3(0.5,3,28), Color(0.3,0.29,0.28))
    # Shelving units (obstacles)
    for i in range(-3, 4):
        _add_box(Vector3(float(i)*3.0, 1.0, -6), Vector3(0.4,2,4), Color(0.5,0.4,0.3))
    # Workbenches
    for pos in [Vector3(5,0.4,4), Vector3(-5,0.4,4), Vector3(0,0.4,8), Vector3(0,0.4,-10)]:
        _add_box(pos, Vector3(3,0.1,1.2), Color(0.45,0.35,0.25))
    # Central machine
    _add_box(Vector3(0,0.8,0), Vector3(2,1.6,2), Color(0.4,0.4,0.45))
    # Crates
    for cp in [Vector3(8,0.4,8), Vector3(-8,0.4,8), Vector3(8,0.4,-8), Vector3(-8,0.4,-8)]:
        _add_box(cp, Vector3(1.2,0.8,1.2), Color(0.55,0.45,0.3))

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
    var st := StaticBody3D.new()
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mi.mesh = mesh
    mi.surface_material_override[0] = mat
    st.add_child(mi)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    col.shape = shape
    st.add_child(col)
    st.global_position = pos
    add_child(st)
