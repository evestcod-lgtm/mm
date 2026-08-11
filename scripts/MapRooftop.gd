extends Node3D

var spawn_points: Array[Vector3] = [
    Vector3(3, 0.1, 3), Vector3(-3, 0.1, 3),
    Vector3(3, 0.1, -3), Vector3(-3, 0.1, -3), Vector3(0, 2.6, 0)
]

func _ready() -> void:
    _build()

func _build() -> void:
    # Main roof
    _add_box(Vector3(0,-0.25,0), Vector3(32,0.5,32), Color(0.25,0.25,0.28))
    # Low barrier walls
    for d in [Vector3(0,0.3,-16), Vector3(0,0.3,16)]:
        _add_box(d, Vector3(32,0.6,0.4), Color(0.35,0.35,0.38))
    for d in [Vector3(-16,0.3,0), Vector3(16,0.3,0)]:
        _add_box(d, Vector3(0.4,0.6,32), Color(0.35,0.35,0.38))
    # Staircase structure
    _add_box(Vector3(0,1.25,0), Vector3(4,2.5,4), Color(0.3,0.3,0.33))
    _add_box(Vector3(2,0.5,0), Vector3(2,0.5,2), Color(0.35,0.35,0.38))  # step
    # AC units / vents
    for pos in [Vector3(6,0.5,6), Vector3(-6,0.5,6), Vector3(6,0.5,-6), Vector3(-6,0.5,-6)]:
        _add_box(pos, Vector3(2.5,1.0,1.5), Color(0.5,0.5,0.55))
    # Water towers
    for pos in [Vector3(10,1.5,10), Vector3(-10,1.5,10)]:
        _add_box(pos, Vector3(2,3,2), Color(0.45,0.4,0.35))
    # Pipes / cover
    for i in range(-5, 6):
        if abs(i) < 2:
            continue
        _add_box(Vector3(float(i)*2.0, 0.2, -10), Vector3(0.4,0.4,3), Color(0.4,0.4,0.45))

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
