extends CharacterBody3D
var controlled:=false
var speed:=0.0
var throttle:=0.0
var propeller:Node3D
var camera:Camera3D
var camera_mode:=0
func _ready()->void:
    _box(Vector3(0,0,0),Vector3(1.05,0.75,6.2),Color(0.78,0.82,0.87),0.45)
    _box(Vector3(0,0.08,0.2),Vector3(14,0.18,1.35),Color(0.66,0.72,0.79),0.5)
    _box(Vector3(0,0.14,2.55),Vector3(4.8,0.16,0.72),Color(0.68,0.74,0.80),0.45)
    _box(Vector3(0,1.25,2.55),Vector3(0.18,2.2,1.15),Color(0.72,0.035,0.025),0.3)
    propeller=Node3D.new(); propeller.position=Vector3(0,0,-3.25); add_child(propeller)
    for sign in [-1,1]:
        var b:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=Vector3(0.18,2.0,0.12); b.mesh=mesh; b.rotation.z=0 if sign==1 else PI; b.material_override=_mat(Color(0.12,0.13,0.15),0.5); propeller.add_child(b)
    var cs:=CollisionShape3D.new(); var sh:=BoxShape3D.new(); sh.size=Vector3(12,1.4,6); cs.shape=sh; add_child(cs)
    camera=Camera3D.new(); camera.name="AircraftCamera"; add_child(camera); camera.current=false
func _mat(c:Color,metal:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=c; m.metallic=metal; m.roughness=0.3; return m
func _box(pos:Vector3,size:Vector3,color:Color,metal:float=0.1)->void:
    var m:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; m.mesh=b; m.position=pos; m.material_override=_mat(color,metal); add_child(m)
func set_control(v: bool) -> void:
    controlled = v
    camera.current = v
    if v:
        _set_camera()

func switch_camera() -> void:
    camera_mode = (camera_mode + 1) % 2
    _set_camera()

func _set_camera() -> void:
    camera.position = Vector3(0, 2.2, 8) if camera_mode == 0 else Vector3(0, 0.65, -1.2)
    camera.fov = 72 if camera_mode == 0 else 92
    camera.look_at(to_global(Vector3.ZERO), Vector3.UP)
func _physics_process(delta:float)->void:
    var pitch:=0.0; var roll:=0.0; var yaw:=0.0
    if controlled:
        throttle=float(Input.is_action_pressed("move_forward"))-float(Input.is_action_pressed("move_back"))
        yaw=float(Input.is_action_pressed("move_left"))-float(Input.is_action_pressed("move_right"))
        pitch=float(Input.is_action_pressed("jump"))
        var ui=get_node_or_null("/root/Main/MobileUI")
        if ui:
            throttle+=ui.get_drive_throttle(); yaw+=ui.get_drive_steer(); pitch+=ui.get_vertical_input(); roll=ui.get_roll_input()
    speed=move_toward(speed,clamp(throttle,0,1)*42,10*delta)
    rotation.y+=yaw*0.65*delta
    rotation.x=clamp(rotation.x-pitch*0.5*delta,-0.65,0.65)
    rotation.z=clamp(rotation.z+roll*0.7*delta,-0.7,0.7)
    var lift=max(0.0,speed-10.0)*0.38
    velocity=-global_basis.z*speed+Vector3.UP*(lift-2.5)*delta*3
    move_and_slide()
    global_position.y=max(global_position.y,0.8)
func _process(delta:float)->void:
    if controlled and propeller: propeller.rotate_z(delta*speed*5+delta*8)
