extends CharacterBody3D

@export var walk_speed: float = 1.35
var route: PackedVector3Array = PackedVector3Array()
var target_index := 0
var pause_timer := 0.0
var player: Node3D

func _ready() -> void:
    floor_snap_length = 0.25
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.28
    capsule.height = 1.55
    body.mesh = capsule
    body.position.y = 0.78
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.from_hsv(randf(), 0.48, 0.82)
    body.material_override = material
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.28
    shape.height = 1.55
    collision.shape = shape
    collision.position.y = 0.78
    add_child(collision)

func set_route(points: PackedVector3Array, player_node: Node3D) -> void:
    route = points
    player = player_node

func _physics_process(delta: float) -> void:
    if route.size() < 2:
        return
    if pause_timer > 0.0:
        pause_timer -= delta
        velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
    else:
        var offset := route[target_index] - global_position
        offset.y = 0.0
        if offset.length() < 1.0:
            target_index = (target_index + 1) % route.size()
            pause_timer = randf_range(0.6, 2.2)
        else:
            var direction := offset.normalized()
            if is_instance_valid(player):
                var away := global_position - player.global_position
                away.y = 0.0
                if away.length() < 2.0 and away.length() > 0.01:
                    direction = (direction + away.normalized() * 1.8).normalized()
            velocity.x = direction.x * walk_speed
            velocity.z = direction.z * walk_speed
            if direction.length() > 0.1:
                rotation.y = atan2(-direction.x, -direction.z)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = -0.1
    move_and_slide()
