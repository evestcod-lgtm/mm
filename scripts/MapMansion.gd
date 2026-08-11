extends Node3D

const FLOOR_MAT_COLOR := Color(0.3, 0.25, 0.2)
const WALL_MAT_COLOR  := Color(0.25, 0.22, 0.18)

var spawn_points: Array[Vector3] = [
    Vector3(3, 0.1, 3), Vector3(-3, 0.1, 3),
    Vector3(3, 0.1, -3), Vector3(-3, 0.1, -3), Vector3(0, 0.1, 0)
]

func _ready() -> void:
    _build()

func _build() -> void:
    # Floor
    _add_box(Vector3(0, -0.25, 0), Vector3(30, 0.5, 30), FLOOR_MAT_COLOR)
    # Outer walls
    _add_box(Vector3(0, 1.5, -15), Vector3(30, 3, 0.5), WALL_MAT_COLOR)
    _add_box(Vector3(0, 1.5, 15),  Vector3(30, 3, 0.5), WALL_MAT_COLOR)
    _add_box(Vector3(-15, 1.5, 0), Vector3(0.5, 3, 30), WALL_MAT_COLOR)
    _add_box(Vector3(15, 1.5, 0),  Vector3(0.5, 3, 30), WALL_MAT_COLOR)
    # Inner walls / rooms
    _add_box(Vector3(0, 1.5, -5),  Vector3(10, 3, 0.5), WALL_MAT_COLOR)
    _add_box(Vector3(6, 1.5, 0),   Vector3(0.5, 3, 10), WALL_MAT_COLOR)
    _add_box(Vector3(-6, 1.5, 0),  Vector3(0.5, 3, 10), WALL_MAT_COLOR)
    _add_box(Vector3(0, 1.5, 5),   Vector3(8, 3, 0.5),  WALL_MAT_COLOR)
    # Pillars
    for px in [-8.0, 8.0]:
        for pz in [-8.0, 8.0]:
            _add_box(Vector3(px, 1.5, pz), Vector3(0.7, 3, 0.7), Color(0.4, 0.35, 0.3))
    # Tables (obstacles)
    _add_box(Vector3(3, 0.4, 2),   Vector3(2, 0.1, 1), Color(0.4,0.3,0.2))
    _add_box(Vector3(-4, 0.4, -3), Vector3(3, 0.1, 1), Color(0.4,0.3,0.2))
    _add_box(Vector3(0, 0.4, -8),  Vector3(4, 0.1, 2), Color(0.4,0.3,0.2))

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
