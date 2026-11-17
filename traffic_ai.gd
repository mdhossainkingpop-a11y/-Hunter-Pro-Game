extends Node3D

@export var speed: float = 5.0
var route: PackedVector3Array = PackedVector3Array()
var target_index := 0

func _ready() -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.65, 0.72, 3.2)
    body.mesh = mesh
    body.position.y = 0.62
    var material := StandardMaterial3D.new()
    var colors := [Color(0.78,0.12,0.09), Color(0.10,0.28,0.72), Color(0.82,0.65,0.10), Color(0.76,0.78,0.80)]
    material.albedo_color = colors[randi() % colors.size()]
    body.material_override = material
    add_child(body)
    var cabin := MeshInstance3D.new()
    var cabin_mesh := BoxMesh.new()
    cabin_mesh.size = Vector3(1.25, 0.55, 1.45)
    cabin.mesh = cabin_mesh
    cabin.position = Vector3(0, 1.18, -0.15)
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.10, 0.18, 0.23)
    cabin.material_override = glass
    add_child(cabin)

func set_route(points: PackedVector3Array) -> void:
    route = points

func _process(delta: float) -> void:
    if route.size() < 2:
        return
    var offset := route[target_index] - global_position
    offset.y = 0.0
    if offset.length() < 2.0:
        target_index = (target_index + 1) % route.size()
        return
    var direction := offset.normalized()
    global_position += direction * speed * delta
    rotation.y = atan2(-direction.x, -direction.z)
