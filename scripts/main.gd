extends Node3D

const PLAYER = preload("res://scripts/player.gd")
const CAR = preload("res://scripts/car.gd")
const PLANE = preload("res://scripts/plane.gd")
const SHIP = preload("res://scripts/ship.gd")
const UI = preload("res://scripts/mobile_ui.gd")
const DOOR = preload("res://scripts/door.gd")
const PICKUP = preload("res://scripts/pickup.gd")
const PEDESTRIAN = preload("res://scripts/pedestrian.gd")
const TRAFFIC_AI = preload("res://scripts/traffic_ai.gd")
const MISSION_MANAGER = preload("res://scripts/mission_manager.gd")

var player
var car: CharacterBody3D
var plane: CharacterBody3D
var ship: CharacterBody3D
var ui
var targets: Array[Node3D] = []
var traffic: Array[Node3D] = []
var interactables: Array[Node3D] = []
var pedestrians: Array[Node3D] = []
var sun: DirectionalLight3D
var mission_manager
var pickups: Array[Node3D] = []
var world_environment: WorldEnvironment
var sky_material: ProceduralSkyMaterial
var day_clock := 0.28
var day_cycle_speed := 0.006
var low_graphics_mode := true

func _ready() -> void:
    _setup_environment()
    _create_landscape()
    _create_city()
    _create_city_expansion()
    _create_vegetation()
    _create_airport_and_port()
    car = CAR.new()
    car.name = "PlayerCar"
    add_child(car)
    car.global_position = Vector3(9, 0.9, 4)
    plane = PLANE.new()
    plane.name = "PlayerPlane"
    add_child(plane)
    plane.global_position = Vector3(-19, 0.8, -22)
    ship = SHIP.new()
    ship.name = "PlayerShip"
    add_child(ship)
    ship.global_position = Vector3(53, 0.15, -42)
    for i in range(7):
        targets.append(_create_destructible(Vector3(-34 + i * 10, 2, -48)))
    player = PLAYER.new()
    player.name = "Player"
    add_child(player)
    player.global_position = Vector3(0, 1, 0)
    player.setup_vehicles(car, plane, ship)
    player.setup_interactables(interactables)
    _create_traffic()
    _create_pedestrians()
    ui = UI.new()
    ui.name = "MobileUI"
    add_child(ui)
    ui.interact_pressed.connect(Callable(player, "try_interact"))
    ui.bomb_pressed.connect(_drop_bomb)
    ui.set_status("WORLD LIFE 3D  |  Explore the island")
    mission_manager = MISSION_MANAGER.new()
    mission_manager.name = "MissionManager"
    add_child(mission_manager)
    mission_manager.mission_updated.connect(ui.set_mission)
    mission_manager.rewards_updated.connect(ui.set_rewards)
    mission_manager.notification.connect(ui.set_status)
    ui.set_mission(mission_manager.get_mission_title(), mission_manager.get_mission_description(), mission_manager.get_progress_text())
    ui.set_rewards(mission_manager.cash, mission_manager.xp, mission_manager.level)
    ui.save_pressed.connect(_save_game)
    ui.load_pressed.connect(_load_game)
    ui.quality_pressed.connect(_toggle_graphics_quality)
    low_graphics_mode = OS.has_feature("mobile")
    _apply_graphics_quality()

func _setup_environment() -> void:
    var we := WorldEnvironment.new()
    world_environment = we
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_material = sky_mat
    sky_mat.sky_top_color = Color(0.075, 0.22, 0.48)
    sky_mat.sky_horizon_color = Color(0.58, 0.76, 0.91)
    sky_mat.ground_bottom_color = Color(0.12, 0.16, 0.13)
    sky_mat.ground_horizon_color = Color(0.42, 0.52, 0.43)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.79, 0.9)
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 1.0
    env.fog_enabled = true
    env.fog_light_color = Color(0.62, 0.74, 0.83)
    env.fog_density = 0.0018
    we.environment = env
    add_child(we)
    sun = DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 110.0
    add_child(sun)

func _create_landscape() -> void:
    _create_island_terrain()
    _create_ocean()
    _road(Vector3(0,0.03,0), Vector3(9,0.16,176), true)
    _road(Vector3(0,0.04,0), Vector3(176,0.16,8), false)
    _road(Vector3(-23,0.04,25), Vector3(7,0.16,75), true)
    _river()
    _bridge()
    # Roadside lamps
    for z in range(-76,80,18):
        _streetlamp(Vector3(6.2,0,z))
        _streetlamp(Vector3(-6.2,0,z))

func _create_island_terrain() -> void:
    # A generated 3D heightfield replaces the old flat island slab and decorative-only hills.
    # The urban core stays mostly level; the outer island rises into rolling hills and falls
    # below sea level around the coast. The same triangles are used for visible mesh and collision.
    const SEGMENTS := 72
    const ISLAND_SIZE := 210.0
    var half_size := ISLAND_SIZE * 0.5
    var vertices := PackedVector3Array()
    var faces := PackedVector3Array()
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)

    for z_index in range(SEGMENTS + 1):
        for x_index in range(SEGMENTS + 1):
            var x := -half_size + ISLAND_SIZE * float(x_index) / float(SEGMENTS)
            var z := -half_size + ISLAND_SIZE * float(z_index) / float(SEGMENTS)
            vertices.append(Vector3(x, _terrain_height(x, z), z))

    for z_index in range(SEGMENTS):
        for x_index in range(SEGMENTS):
            var a := z_index * (SEGMENTS + 1) + x_index
            var b := a + 1
            var d := (z_index + 1) * (SEGMENTS + 1) + x_index
            var c := d + 1
            # Counter-clockwise winding gives upward-facing terrain normals.
            for vertex_index in [a, c, b, a, d, c]:
                var vertex: Vector3 = vertices[vertex_index]
                surface.set_uv(Vector2((vertex.x + half_size) / ISLAND_SIZE, (vertex.z + half_size) / ISLAND_SIZE))
                surface.add_vertex(vertex)
                faces.append(vertex)

    surface.index()
    surface.generate_normals()
    var terrain_mesh := surface.commit()
    var terrain_material := StandardMaterial3D.new()
    terrain_material.albedo_color = Color(0.17, 0.34, 0.15)
    terrain_material.roughness = 0.96

    var terrain_body := StaticBody3D.new()
    terrain_body.name = "IslandTerrain"
    var terrain_visual := MeshInstance3D.new()
    terrain_visual.name = "TerrainMesh"
    terrain_visual.mesh = terrain_mesh
    terrain_visual.material_override = terrain_material
    terrain_body.add_child(terrain_visual)

    var terrain_collision := CollisionShape3D.new()
    var terrain_shape := ConcavePolygonShape3D.new()
    terrain_shape.set_faces(faces)
    terrain_collision.shape = terrain_shape
    terrain_body.add_child(terrain_collision)
    add_child(terrain_body)

func _terrain_height(x: float, z: float) -> float:
    var normalized_radius := sqrt(pow(x / 105.0, 2.0) + pow(z / 105.0, 2.0))
    var coast_drop := _smoothstep(0.76, 1.0, normalized_radius) * 7.0
    var urban_extent := max(abs(x) / 54.0, abs(z) / 68.0)
    var hills_mask := _smoothstep(0.82, 1.18, urban_extent)
    var road_mask := 1.0 - _smoothstep(5.0, 12.0, abs(x))
    road_mask = max(road_mask, 1.0 - _smoothstep(5.0, 12.0, abs(z)))
    if z > -18.0 and z < 66.0:
        road_mask = max(road_mask, 1.0 - _smoothstep(4.0, 9.0, abs(x + 23.0)))
    var rolling_hills := sin(x * 0.052) * 1.8 + cos(z * 0.045) * 1.6 + sin((x + z) * 0.028) * 1.2
    var base_height := rolling_hills * hills_mask * (1.0 - road_mask) - coast_drop
    # Keep the port apron and crane foundations on a shared, level coastal platform.
    var port_extent := max(abs(x - 74.0) / 17.0, abs(z + 42.0) / 18.0)
    var port_blend := 1.0 - _smoothstep(0.82, 1.0, port_extent)
    return lerp(base_height, -1.5, port_blend)

func _smoothstep(edge_a: float, edge_b: float, value: float) -> float:
    var t := clamp((value - edge_a) / (edge_b - edge_a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

func _create_ocean() -> void:
    var ocean := MeshInstance3D.new()
    ocean.name = "SurroundingOcean"
    var plane_mesh := PlaneMesh.new()
    plane_mesh.size = Vector2(600.0, 600.0)
    plane_mesh.subdivide_width = 48
    plane_mesh.subdivide_depth = 48
    ocean.mesh = plane_mesh
    ocean.position.y = -2.2
    var ocean_material := ShaderMaterial.new()
    ocean_material.shader = load("res://shaders/water.gdshader")
    ocean.material_override = ocean_material
    add_child(ocean)

func _road(pos:Vector3, size:Vector3, vertical:bool) -> void:
    _static_box(pos,size,Color(0.075,0.085,0.095))
    var line_color := Color(0.95,0.83,0.42)
    if vertical:
        for z in range(-82,84,12):
            _visual_box(Vector3(pos.x,0.13,z),Vector3(0.18,0.025,5.0),line_color)
        for x in [-4.25,4.25]:
            _visual_box(Vector3(x,0.13,pos.z),Vector3(0.12,0.025,size.z),Color(0.82,0.82,0.78))
    else:
        for x in range(-82,84,12):
            _visual_box(Vector3(x,0.14,pos.z),Vector3(5.0,0.025,0.18),line_color)

func _river() -> void:
    _visual_box(Vector3(52,0.01,-18),Vector3(42,0.04,126),Color(0.025,0.22,0.40,0.92))
    var watermat := StandardMaterial3D.new()
    watermat.albedo_color = Color(0.04,0.31,0.48,0.86)
    watermat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    watermat.roughness = 0.18
    var water := MeshInstance3D.new()
    var p := PlaneMesh.new()
    p.size = Vector2(39,122)
    p.subdivide_width = 32
    p.subdivide_depth = 64
    water.mesh = p
    water.position = Vector3(52,0.06,-18)
    var wave_material := ShaderMaterial.new()
    wave_material.shader = load("res://shaders/water.gdshader")
    water.material_override = wave_material
    add_child(water)

func _bridge() -> void:
    _static_box(Vector3(52,1.0,-18),Vector3(49,0.75,6),Color(0.43,0.46,0.49))
    for x in [-70,-55,-40,-25,-10,5,20,35,50,65,80,95,110,125,140,155]:
        if x > 30 and x < 75:
            continue
        _static_box(Vector3(x,0.1,-18),Vector3(1.2,2.4,1.2),Color(0.46,0.48,0.50))
    # bridge cable towers
    for x in [34.0,70.0]:
        _visual_box(Vector3(x,4.2,-18),Vector3(0.7,7.0,0.7),Color(0.68,0.70,0.72))
        for z in [-2.0,2.0]:
            _visual_box(Vector3(x,2.3,-18+z),Vector3(0.16,4.2,0.16),Color(0.75,0.77,0.79))

func _create_city() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 8801
    for i in range(58):
        var x := rng.randf_range(-46,44)
        var z := rng.randf_range(-60,62)
        if abs(x)<8 or abs(z)<9 or (x>-15 and x< -10 and z>-55 and z<35):
            continue
        var w := rng.randf_range(4.5,9.0)
        var d := rng.randf_range(4.5,9.0)
        var h := rng.randf_range(4.0,22.0)
        var color := [Color(0.55,0.58,0.62),Color(0.68,0.62,0.51),Color(0.43,0.52,0.59),Color(0.72,0.70,0.63)][i%4]
        _building(Vector3(x,_terrain_height(x,z)+h/2,z),Vector3(w,h,d),color, i%7==0)
    # skyline towers
    for i in range(7):
        var x := -34.0 + i*10.0
        var h := 24.0 + float(i%3)*9.0
        _building(Vector3(x,_terrain_height(x,-67)+h/2,-67),Vector3(7,h,8),Color(0.32,0.45,0.55),true)
    # small village homes
    for i in range(12):
        var x := 24.0 + float(i%4)*9.0
        var z := 38.0 + float(i/4)*10.0
        _house(Vector3(x,_terrain_height(x,z),z))
    _create_supply_pickup(Vector3(20.0, 0.0, 35.0))
    _create_supply_pickup(Vector3(58.0, 0.0, 48.0))
    _create_supply_pickup(Vector3(39.0, 0.0, 68.0))

func _building(pos:Vector3,size:Vector3,color:Color,glass:bool) -> void:
    _static_box(pos,size,color)
    var window_mat := Color(0.12,0.24,0.32) if glass else Color(0.22,0.30,0.34)
    var floors := int(size.y/3.0)
    for floor_i in range(min(floors,7)):
        for side in [-1.0,1.0]:
            for col in [-1.0,0.0,1.0]:
                _visual_box(pos+Vector3(col*size.x*0.27, -size.y/2+1.3+floor_i*2.7, side*(size.z/2+0.025)),Vector3(0.8,1.1,0.06),window_mat)
    if glass:
        _visual_box(pos+Vector3(0,size.y/2+0.18,0),Vector3(size.x*0.72,0.35,size.z*0.72),Color(0.17,0.22,0.28))

func _house(pos:Vector3) -> void:
    var wall_color := Color(0.73, 0.65, 0.51)
    # Split front wall leaves a real doorway opening for the animated door.
    _static_box(pos + Vector3(0, 0.08, 0), Vector3(5.7, 0.16, 5.7), Color(0.48, 0.43, 0.35))
    _static_box(pos + Vector3(-2.85, 1.5, 0), Vector3(0.3, 3.0, 6.0), wall_color)
    _static_box(pos + Vector3(2.85, 1.5, 0), Vector3(0.3, 3.0, 6.0), wall_color)
    _static_box(pos + Vector3(0, 1.5, -2.85), Vector3(5.7, 3.0, 0.3), wall_color)
    _static_box(pos + Vector3(-1.95, 1.5, 2.85), Vector3(1.8, 3.0, 0.3), wall_color)
    _static_box(pos + Vector3(1.95, 1.5, 2.85), Vector3(1.8, 3.0, 0.3), wall_color)
    _static_box(pos + Vector3(0, 2.75, 2.85), Vector3(2.1, 0.5, 0.3), wall_color)

    var roof := MeshInstance3D.new()
    var prism := PrismMesh.new()
    prism.size = Vector3(7, 2.0, 7)
    roof.mesh = prism
    roof.position = pos + Vector3(0, 3.8, 0)
    var roof_material := StandardMaterial3D.new()
    roof_material.albedo_color = Color(0.48, 0.15, 0.11)
    roof.material_override = roof_material
    add_child(roof)

    var door := DOOR.new() as Node3D
    door.name = "InteractiveDoor"
    door.position = pos + Vector3(-0.9, 0.0, 2.86)
    var door_body := StaticBody3D.new()
    door_body.position = Vector3(0.9, 1.22, 0.0)
    var door_mesh := MeshInstance3D.new()
    var door_box := BoxMesh.new()
    door_box.size = Vector3(1.8, 2.1, 0.12)
    door_mesh.mesh = door_box
    var door_material := StandardMaterial3D.new()
    door_material.albedo_color = Color(0.20, 0.12, 0.08)
    door_material.roughness = 0.8
    door_mesh.material_override = door_material
    door_body.add_child(door_mesh)
    var door_collision := CollisionShape3D.new()
    var door_shape := BoxShape3D.new()
    door_shape.size = Vector3(1.8, 2.1, 0.12)
    door_collision.shape = door_shape
    door_body.add_child(door_collision)
    door.add_child(door_body)
    add_child(door)
    interactables.append(door)

func _create_supply_pickup(pos: Vector3) -> void:
    var pickup := PICKUP.new() as Node3D
    pickup.name = "SupplyPickup_%d" % pickups.size()
    pickup.set_meta("pickup_id", pickup.name)
    pickup.pickup_id = pickup.name
    pickup.pickup_collected.connect(_on_pickup_collected)
    pickups.append(pickup)
    pickup.position = Vector3(pos.x, _terrain_height(pos.x, pos.z) + 0.65, pos.z)
    var crate := MeshInstance3D.new()
    var crate_mesh := BoxMesh.new()
    crate_mesh.size = Vector3(0.9, 0.9, 0.9)
    crate.mesh = crate_mesh
    var crate_material := StandardMaterial3D.new()
    crate_material.albedo_color = Color(0.92, 0.62, 0.12)
    crate_material.metallic = 0.15
    crate.material_override = crate_material
    pickup.add_child(crate)
    var marker := MeshInstance3D.new()
    var marker_mesh := SphereMesh.new()
    marker_mesh.radius = 0.16
    marker_mesh.height = 0.32
    marker.mesh = marker_mesh
    marker.position.y = 0.62
    var marker_material := StandardMaterial3D.new()
    marker_material.albedo_color = Color(1.0, 0.9, 0.35)
    marker.material_override = marker_material
    pickup.add_child(marker)
    add_child(pickup)
    interactables.append(pickup)

func _create_vegetation() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1919
    for i in range(175):
        var x := rng.randf_range(-96,96)
        var z := rng.randf_range(-96,96)
        if abs(x)<10 or abs(z)<10 or (x>30 and x<74) or (x < -29 and x > -31) or (x>58 and x<92 and z>-60 and z<-25):
            continue
        var ground_y := _terrain_height(x, z)
        if ground_y < -1.5:
            continue
        _tree(Vector3(x,ground_y,z),rng.randf_range(0.75,1.4))
    # low bushes
    for i in range(70):
        var x := rng.randf_range(-88,88)
        var z := rng.randf_range(-88,88)
        var ground_y := _terrain_height(x, z)
        if abs(x)>12 and abs(z)>12 and ground_y > -1.5 and not (x>58 and x<92 and z>-60 and z<-25):
            _sphere(Vector3(x,ground_y+0.7,z),Vector3(0.7,0.7,0.7),Color(0.08,0.25,0.08))

func _tree(pos:Vector3,s:float) -> void:
    var trunk := MeshInstance3D.new()
    var c := CylinderMesh.new()
    c.top_radius=0.13*s
    c.bottom_radius=0.23*s
    c.height=1.8*s
    trunk.mesh=c
    trunk.position=pos+Vector3(0,0.9*s,0)
    var tm:=StandardMaterial3D.new()
    tm.albedo_color=Color(0.25,0.13,0.06)
    trunk.material_override=tm
    add_child(trunk)
    for j in range(3):
        var crown:=MeshInstance3D.new()
        var cone:=SphereMesh.new()
        cone.radius=(1.0-j*0.12)*s
        cone.height=(1.65-j*0.12)*s
        crown.mesh=cone
        crown.position=pos+Vector3(0,(1.8+j*0.48)*s,0)
        var cm:=StandardMaterial3D.new()
        cm.albedo_color=[Color(0.055,0.24,0.07),Color(0.07,0.31,0.08),Color(0.10,0.36,0.09)][j]
        crown.material_override=cm
        add_child(crown)

func _create_airport_and_port() -> void:
    _static_box(Vector3(-20,0.01,-20),Vector3(18,0.12,82),Color(0.14,0.15,0.17))
    for z in range(-55,20,12):
        _visual_box(Vector3(-20,0.09,z),Vector3(0.3,0.025,5),Color(0.95,0.91,0.72))
    _visual_box(Vector3(-20,0.13,22),Vector3(34,0.18,16),Color(0.50,0.52,0.53))
    for x in [-31,-24,-17,-10]:
        _visual_box(Vector3(x,0.5,22),Vector3(0.4,0.8,0.4),Color(0.75,0.75,0.74))
    # port cranes, placed against the generated coastal terrain height
    for x in [77.0,87.0]:
        var crane_ground := _terrain_height(x, -48.0)
        _visual_box(Vector3(x,crane_ground+5,-48),Vector3(0.8,10,0.8),Color(0.85,0.35,0.10))
        _visual_box(Vector3(x+3,crane_ground+9,-48),Vector3(7,0.5,0.5),Color(0.85,0.35,0.10))
        _visual_box(Vector3(x+6,crane_ground+5,-48),Vector3(0.4,8,0.4),Color(0.85,0.35,0.10))
    var port_ground := _terrain_height(74.0, -42.0)
    _static_box(Vector3(74,port_ground+0.2,-42),Vector3(28,0.4,30),Color(0.36,0.35,0.31))
    # petrol station canopy and pumps
    _static_box(Vector3(15,3,15),Vector3(12,0.5,8),Color(0.86,0.13,0.08))
    for x in [11.0,15.0,19.0]:
        _static_box(Vector3(x,0.8,15),Vector3(0.8,1.6,0.8),Color(0.91,0.91,0.85))
    _visual_box(Vector3(15,3.32,15),Vector3(12.4,0.12,8.4),Color(0.92,0.92,0.88))

func _create_traffic() -> void:
    var north_south := PackedVector3Array([Vector3(-3.0, 0.0, -82.0), Vector3(-3.0, 0.0, 82.0), Vector3(3.0, 0.0, 82.0), Vector3(3.0, 0.0, -82.0)])
    var east_west := PackedVector3Array([Vector3(-82.0, 0.0, 3.0), Vector3(82.0, 0.0, 3.0), Vector3(82.0, 0.0, -3.0), Vector3(-82.0, 0.0, -3.0)])
    for i in range(6):
        var vehicle = TRAFFIC_AI.new()
        vehicle.name = "TrafficAI_%02d" % i
        add_child(vehicle)
        var route: PackedVector3Array = north_south if i % 2 == 0 else east_west
        vehicle.set_route(route)
        var route_index := int(i / 2) % route.size()
        vehicle.global_position = route[route_index] + Vector3(0.0, 0.0, float(i % 2) * 5.0)
        vehicle.target_index = (route_index + 1) % route.size()
        traffic.append(vehicle)

func _create_pedestrians() -> void:
    var sidewalk_routes: Array[PackedVector3Array] = [
        PackedVector3Array([Vector3(-16.0, 0.0, -27.0), Vector3(15.0, 0.0, -27.0), Vector3(15.0, 0.0, -33.0), Vector3(-16.0, 0.0, -33.0)]),
        PackedVector3Array([Vector3(-16.0, 0.0, 27.0), Vector3(15.0, 0.0, 27.0), Vector3(15.0, 0.0, 33.0), Vector3(-16.0, 0.0, 33.0)]),
        PackedVector3Array([Vector3(42.0, 0.0, 10.0), Vector3(54.0, 0.0, 10.0), Vector3(54.0, 0.0, 26.0), Vector3(42.0, 0.0, 26.0)])
    ]
    for i in range(12):
        var npc = PEDESTRIAN.new()
        npc.name = "Pedestrian_%02d" % i
        add_child(npc)
        var route: PackedVector3Array = sidewalk_routes[i % sidewalk_routes.size()]
        var route_index := int(i / sidewalk_routes.size()) % route.size()
        npc.global_position = route[route_index] + Vector3(0.0, 0.15, 0.0)
        npc.set_route(route, player)
        npc.target_index = (route_index + 1) % route.size()
        pedestrians.append(npc)

func _update_day_night(delta: float) -> void:
    day_clock = fposmod(day_clock + delta * day_cycle_speed, 1.0)
    var sun_angle := day_clock * TAU - PI * 0.5
    var daylight := clamp(sin(sun_angle) * 0.5 + 0.5, 0.04, 1.0)
    if is_instance_valid(sun):
        sun.rotation_degrees = Vector3(-rad_to_deg(sun_angle), -32.0, 0.0)
        sun.light_energy = lerp(0.08, 1.25, daylight)
        sun.light_color = Color(1.0, 0.72, 0.48).lerp(Color(1.0, 0.96, 0.84), daylight)
    if is_instance_valid(world_environment) and world_environment.environment:
        world_environment.environment.ambient_light_energy = lerp(0.18, 0.78, daylight)
        world_environment.environment.background_energy_multiplier = lerp(0.22, 1.0, daylight)
    if is_instance_valid(sky_material):
        sky_material.sky_top_color = Color(0.008, 0.014, 0.055).lerp(Color(0.075, 0.22, 0.48), daylight)
        sky_material.sky_horizon_color = Color(0.055, 0.07, 0.13).lerp(Color(0.58, 0.76, 0.91), daylight)

func _create_destructible(pos:Vector3)->Node3D:
    var body:=StaticBody3D.new()
    body.position=pos
    body.set_meta("destructible",true)
    var m:=MeshInstance3D.new()
    var box:=BoxMesh.new()
    box.size=Vector3(5,4,5)
    m.mesh=box
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color(0.62,0.36,0.20)
    m.material_override = mat
    body.add_child(m)
    var cs:=CollisionShape3D.new()
    var sh:=BoxShape3D.new()
    sh.size=Vector3(5,4,5)
    cs.shape=sh
    body.add_child(cs)
    add_child(body)
    return body

func _static_box(pos:Vector3,size:Vector3,color:Color)->StaticBody3D:
    var body:=StaticBody3D.new()
    body.position=pos
    var m:=MeshInstance3D.new()
    var box:=BoxMesh.new()
    box.size=size
    m.mesh=box
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.roughness=0.9
    m.material_override=mat
    body.add_child(m)
    var cs:=CollisionShape3D.new()
    var sh:=BoxShape3D.new()
    sh.size=size
    cs.shape=sh
    body.add_child(cs)
    add_child(body)
    return body

func _visual_box(pos:Vector3,size:Vector3,color:Color)->MeshInstance3D:
    var m:=MeshInstance3D.new()
    var box:=BoxMesh.new()
    box.size=size
    m.mesh=box
    m.position=pos
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    m.material_override=mat
    add_child(m)
    return m

func _sphere(pos:Vector3,scale:Vector3,color:Color)->void:
    var m:=MeshInstance3D.new()
    var s:=SphereMesh.new()
    s.radius=1.0
    s.height=2.0
    m.mesh=s
    m.position=pos
    m.scale=scale
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    m.material_override=mat
    add_child(m)

func _streetlamp(pos:Vector3)->void:
    _visual_box(pos+Vector3(0,2,0),Vector3(0.12,4,0.12),Color(0.18,0.19,0.20))
    _visual_box(pos+Vector3(0.65,3.9,0),Vector3(1.4,0.12,0.12),Color(0.18,0.19,0.20))
    var light:=OmniLight3D.new()
    light.position=pos+Vector3(1.2,3.8,0)
    light.light_color=Color(1.0,0.86,0.62)
    light.light_energy=0.45
    light.omni_range=5
    add_child(light)

func _drop_bomb()->void:
    if not player.in_vehicle or player.current_vehicle!=plane:
        ui.set_status("Enter the plane before dropping a bomb")
        return
    var bomb:=RigidBody3D.new()
    bomb.position=plane.global_position+Vector3(0,-1.2,-2)
    var visual:=MeshInstance3D.new()
    var sphere:=SphereMesh.new()
    sphere.radius=0.3
    sphere.height=0.6
    visual.mesh=sphere
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color(0.08,0.08,0.09)
    visual.material_override=mat
    bomb.add_child(visual)
    var cs:=CollisionShape3D.new()
    var sh:=SphereShape3D.new()
    sh.radius=0.3
    cs.shape=sh
    bomb.add_child(cs)
    add_child(bomb)
    bomb.linear_velocity=plane.velocity+Vector3(0,-2,0)
    get_tree().create_timer(3.5).timeout.connect(func():
        if is_instance_valid(bomb):
            _explode(bomb.global_position)
            bomb.queue_free()
    )

func _explode(pos:Vector3)->void:
    for t in targets.duplicate():
        if is_instance_valid(t) and t.global_position.distance_to(pos)<13:
            targets.erase(t)
            t.queue_free()
    var fx:=OmniLight3D.new()
    fx.position=pos
    fx.light_color=Color(1.0,0.28,0.04)
    fx.light_energy=5
    fx.omni_range=13
    add_child(fx)
    get_tree().create_timer(0.35).timeout.connect(func():
        if is_instance_valid(fx): fx.queue_free()
    )


func _toggle_graphics_quality() -> void:
    low_graphics_mode = not low_graphics_mode
    _apply_graphics_quality()
    if ui:
        ui.set_status("Graphics: Low power" if low_graphics_mode else "Graphics: Standard")

func _apply_graphics_quality() -> void:
    # Runtime quality switch intended for mid-range Android devices.
    Engine.max_fps = 45 if low_graphics_mode else 60
    if is_instance_valid(sun):
        sun.shadow_enabled = not low_graphics_mode
        sun.directional_shadow_max_distance = 65.0 if low_graphics_mode else 110.0
    if is_instance_valid(world_environment) and world_environment.environment:
        world_environment.environment.fog_enabled = not low_graphics_mode
        world_environment.environment.ambient_light_energy = 0.62 if low_graphics_mode else 0.72
    if ui:
        ui.set_quality_label("LOW" if low_graphics_mode else "STD")

func _process(delta:float)->void:
    _update_day_night(delta)
    if mission_manager and player:
        mission_manager.update_player_position(player.global_position)
    if ui and player:
        var mode := "ON FOOT"
        if player.in_vehicle:
            if player.current_vehicle==car: mode="DRIVING"
            elif player.current_vehicle==plane: mode="FLYING"
            elif player.current_vehicle==ship: mode="SAILING"
        ui.set_mode(mode)


func _on_pickup_collected(pickup_id: String) -> void:
    if mission_manager:
        mission_manager.collect_pickup(pickup_id)

func _save_game() -> void:
    if mission_manager and player:
        mission_manager.save_game(player)

func _load_game() -> void:
    if mission_manager and player:
        mission_manager.load_game(player, pickups)

# v0.8 Modern City Expansion: organized districts, sidewalks, parks and street furniture.
func _create_city_expansion() -> void:
    _create_city_district_roads()
    _create_city_blocks()
    _create_city_park()
    _create_city_street_furniture()
    _create_city_landmarks()

func _create_city_district_roads() -> void:
    # Secondary east-west roads; the existing main cross-road remains the city spine.
    for z in [-48.0, -30.0, 30.0, 48.0]:
        _static_box(Vector3(-2.0, 0.035, z), Vector3(88.0, 0.12, 5.5), Color(0.085, 0.095, 0.105))
        for x in range(-42, 43, 12):
            _visual_box(Vector3(float(x), 0.105, z), Vector3(4.2, 0.018, 0.12), Color(0.92, 0.82, 0.48))
    # Sidewalk strips along the district streets.
    for z in [-48.0, -30.0, 30.0, 48.0]:
        for side in [-1.0, 1.0]:
            _static_box(Vector3(-2.0, 0.10, z + side * 3.8), Vector3(88.0, 0.20, 1.2), Color(0.48, 0.49, 0.48))
    # North-south neighborhood connectors.
    for x in [-38.0, -20.0, 20.0, 38.0]:
        _static_box(Vector3(x, 0.04, 0.0), Vector3(4.8, 0.12, 112.0), Color(0.09, 0.10, 0.11))
        for z in range(-52, 53, 14):
            _visual_box(Vector3(x, 0.11, float(z)), Vector3(0.12, 0.018, 4.8), Color(0.90, 0.80, 0.45))

func _create_city_blocks() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 208
    # A compact commercial strip around the central avenue.
    for i in range(10):
        var x := -43.0 + float(i) * 9.0
        var z := -16.0 if i % 2 == 0 else 16.0
        var h := rng.randf_range(8.0, 17.0)
        var c := [Color(0.58,0.62,0.66), Color(0.70,0.61,0.49), Color(0.46,0.55,0.60)][i % 3]
        _building(Vector3(x, _terrain_height(x,z) + h/2.0, z), Vector3(6.4,h,7.0), c, i % 3 == 0)
    # Residential blocks on the outer side of the city grid.
    for row in range(3):
        for col in range(5):
            var x := 24.0 + float(col) * 8.0
            var z := -42.0 + float(row) * 17.0
            if abs(z) < 8.0:
                continue
            var h := rng.randf_range(5.0, 9.0)
            _building(Vector3(x, _terrain_height(x,z) + h/2.0, z), Vector3(5.8,h,6.5), Color(0.68,0.65,0.57), false)

func _create_city_park() -> void:
    # Park placed beside the eastern residential blocks.
    _static_box(Vector3(48.0, 0.08, 18.0), Vector3(13.0, 0.16, 18.0), Color(0.20,0.43,0.22))
    _static_box(Vector3(48.0, 0.17, 18.0), Vector3(1.6, 0.08, 15.0), Color(0.72,0.68,0.56))
    _static_box(Vector3(48.0, 0.17, 18.0), Vector3(10.5, 0.08, 1.4), Color(0.72,0.68,0.56))
    for p in [Vector3(44,0,12), Vector3(52,0,12), Vector3(44,0,24), Vector3(52,0,24)]:
        _tree(p, 1.0)

func _create_city_street_furniture() -> void:
    # Bus shelters and benches are visual props, deliberately lightweight.
    for z in [-34.0, 34.0]:
        _static_box(Vector3(-12.0, 1.2, z), Vector3(3.2, 0.12, 1.0), Color(0.28,0.30,0.32))
        _visual_box(Vector3(-12.0, 2.0, z), Vector3(3.0, 0.08, 0.08), Color(0.16,0.20,0.24))
        for x in [-13.3, -10.7]:
            _visual_box(Vector3(x, 1.6, z), Vector3(0.08, 0.8, 0.08), Color(0.16,0.20,0.24))
    # Crosswalk markings at the main intersections.
    for z in [-30.0, 30.0]:
        for stripe in range(7):
            _visual_box(Vector3(-3.0 + float(stripe)*1.0, 0.13, z), Vector3(0.65,0.025,2.8), Color(0.88,0.89,0.86))

func _create_city_landmarks() -> void:
    # A small civic plaza and a simple clock-tower landmark.
    _static_box(Vector3(-30.0, 0.10, 18.0), Vector3(12.0, 0.20, 10.0), Color(0.55,0.55,0.53))
    _static_box(Vector3(-30.0, 3.0, 18.0), Vector3(2.2, 5.8, 2.2), Color(0.72,0.68,0.58))
    _static_box(Vector3(-30.0, 6.2, 18.0), Vector3(3.0, 0.7, 3.0), Color(0.35,0.39,0.43))
    _visual_box(Vector3(-30.0, 7.0, 18.0), Vector3(0.25,0.9,0.25), Color(0.86,0.82,0.66))
