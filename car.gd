extends CharacterBody3D
var controlled := false
var speed := 0.0
var steering := 0.0
var wheels: Array[MeshInstance3D] = []
var camera: Camera3D
var camera_mode := 0
func _ready() -> void:
    _box(Vector3(0,0.72,0),Vector3(2.15,0.72,4.15),Color(0.72,0.035,0.025),0.45)
    _box(Vector3(0,1.35,-0.25),Vector3(1.62,0.68,1.95),Color(0.055,0.16,0.23),0.65)
    _box(Vector3(0,1.72,0.65),Vector3(1.45,0.10,0.75),Color(0.72,0.035,0.025),0.35)
    for x in [-1.08,1.08]:
        for z in [-1.35,1.35]:
            var w:=MeshInstance3D.new(); var c:=CylinderMesh.new()
            c.top_radius=0.43; c.bottom_radius=0.43; c.height=0.27
            w.mesh=c; w.rotation.z=PI/2; w.position=Vector3(x,0.43,z)
            w.material_override=_mat(Color(0.025,0.027,0.03),0.1); add_child(w); wheels.append(w)
    var cs:=CollisionShape3D.new(); var sh:=BoxShape3D.new(); sh.size=Vector3(2.1,1.5,3.9); cs.shape=sh; cs.position.y=0.8; add_child(cs)
    camera=Camera3D.new(); camera.name="VehicleCamera"; add_child(camera); camera.current=false
func _mat(c:Color,metal:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=c; m.metallic=metal; m.roughness=0.34; return m
func _box(pos:Vector3,size:Vector3,color:Color,metal:float=0.1)->void:
    var m:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; m.mesh=b; m.position=pos; m.material_override=_mat(color,metal); add_child(m)
func set_control(v: bool) -> void:
    controlled = v
    camera.current = v
    if v:
        _set_camera()
func switch_camera()->void:
    camera_mode=(camera_mode+1)%2; _set_camera()
func _set_camera()->void:
    if camera_mode==0: camera.position=Vector3(0,4.5,8); camera.fov=70
    else: camera.position=Vector3(0,1.5,-0.25); camera.fov=88
    camera.look_at(to_global(Vector3(0, 1, 0)), Vector3.UP)
func _physics_process(delta:float)->void:
    var throttle:=0.0; var steer:=0.0; var brake:=false
    if controlled:
        throttle=float(Input.is_action_pressed("move_forward"))-float(Input.is_action_pressed("move_back"))
        steer=float(Input.is_action_pressed("move_left"))-float(Input.is_action_pressed("move_right"))
        var ui=get_node_or_null("/root/Main/MobileUI")
        if ui:
            throttle+=ui.get_drive_throttle(); steer+=ui.get_drive_steer(); brake=ui.is_braking()
    if brake: speed=move_toward(speed,0,38*delta)
    else: speed=move_toward(speed,clamp(throttle,-0.65,1.0)*32,12*delta if throttle==0 else 17*delta)
    steering=move_toward(steering,steer,3.5*delta)
    if abs(speed)>0.15: rotate_y(steering*1.45*delta*sign(speed))
    for w in wheels: w.rotate_x(speed*delta*0.7)
    velocity=-global_basis.z*speed; velocity.y=-0.1; move_and_slide()
