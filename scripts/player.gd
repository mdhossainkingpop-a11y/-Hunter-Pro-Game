extends CharacterBody3D

var walk_speed := 6.0
var run_speed := 9.5
var acceleration := 26.0
var gravity := 22.0
var jump_velocity := 8.0
var camera: Camera3D
var vehicles: Array[Node3D] = []
var interactables: Array[Node3D] = []
var current_vehicle: Node3D
var in_vehicle := false
var yaw := 0.0

func _ready() -> void:
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(48.0)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.07, 0.15, 0.28)
    body.material_override = mat
    add_child(body)

    var cs := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.8
    cs.shape = shape
    cs.position.y = 0.9
    add_child(cs)

    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.current = true
    camera.fov = 70.0
    add_child(camera)
    camera.position = Vector3(0, 4.5, 9.0)

func setup_vehicles(car: Node3D, plane: Node3D, ship: Node3D) -> void:
    vehicles = [car, plane, ship]

func setup_interactables(items: Array[Node3D]) -> void:
    interactables = items

func _physics_process(delta: float) -> void:
    var ui = get_node_or_null("/root/Main/MobileUI")
    if in_vehicle and is_instance_valid(current_vehicle):
        global_position = current_vehicle.global_position + Vector3.UP * 1.5
        velocity = Vector3.ZERO
        _follow_camera(delta, true)
        return

    var input_vector := Vector2(
        float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")),
        float(Input.is_action_pressed("move_forward")) - float(Input.is_action_pressed("move_back"))
    )
    if ui:
        input_vector += ui.get_move_vector()
    input_vector = input_vector.limit_length()

    var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
    var right := Vector3(-forward.z, 0.0, forward.x)
    var direction := (right * input_vector.x + forward * input_vector.y).normalized()
    var sprinting := Input.is_action_pressed("sprint")
    if ui:
        sprinting = sprinting or ui.is_sprinting()
    var target_speed := run_speed if sprinting else walk_speed

    if direction.length() > 0.05:
        velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
        rotation.y = atan2(-direction.x, -direction.z)
    else:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

    var jump_requested := Input.is_action_just_pressed("jump")
    if ui:
        jump_requested = jump_requested or ui.consume_jump()
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        if velocity.y < 0.0:
            velocity.y = -0.1
        if jump_requested:
            velocity.y = jump_velocity

    if Input.is_action_just_pressed("interact"):
        try_interact()

    move_and_slide()
    _follow_camera(delta, false)

func _follow_camera(delta: float, driving: bool) -> void:
    var target := global_position + Vector3(0.0, 1.25, 0.0)
    var distance := 10.0 if not driving else 13.0
    var desired := target + Vector3(sin(yaw) * distance, 4.4, cos(yaw) * distance)

    # Raycast from the player focus to the desired camera position so walls and cliffs
    # move the camera forward instead of allowing it to clip through the world.
    var query := PhysicsRayQueryParameters3D.create(target, desired)
    query.exclude = [get_rid()]
    query.collision_mask = 1
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var away_from_wall: Vector3 = (target - hit.position).normalized()
        desired = hit.position + away_from_wall * 0.35

    camera.global_position = camera.global_position.lerp(desired, min(1.0, delta * 8.0))
    camera.look_at(target, Vector3.UP)

func try_interact() -> void:
    if in_vehicle:
        toggle_vehicle()
        return

    var nearest: Node3D
    var nearest_distance := 3.6
    for item in interactables:
        if not is_instance_valid(item):
            continue
        var distance := global_position.distance_to(item.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = item

    if nearest:
        var message := "Interaction complete"
        if nearest.has_method("interact"):
            message = str(nearest.call("interact", self))
        if nearest.is_queued_for_deletion():
            interactables.erase(nearest)
        var ui = get_node_or_null("/root/Main/MobileUI")
        if ui:
            ui.set_status(message)
        return

    toggle_vehicle()

func toggle_vehicle() -> void:
    if in_vehicle:
        if is_instance_valid(current_vehicle):
            current_vehicle.call("set_control", false)
            var old_vehicle := current_vehicle
            current_vehicle = null
            in_vehicle = false
            visible = true
            global_position = old_vehicle.global_position + old_vehicle.global_basis.x * 3.2 + Vector3.UP
            velocity = Vector3.ZERO
            # Explicitly restore the on-foot camera after a vehicle camera is disabled.
            camera.current = true
        return

    var nearest: Node3D
    var best_distance := 9999.0
    for vehicle in vehicles:
        if not is_instance_valid(vehicle):
            continue
        var distance := global_position.distance_to(vehicle.global_position)
        if distance < best_distance:
            best_distance = distance
            nearest = vehicle
    if nearest and best_distance < 8.0:
        current_vehicle = nearest
        in_vehicle = true
        visible = false
        camera.current = false
        current_vehicle.call("set_control", true)
