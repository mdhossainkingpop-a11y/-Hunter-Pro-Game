extends CharacterBody3D
var controlled:=false
var speed:=0.0
var camera:Camera3D
var camera_mode:=0
func _ready()->void:
    _box(Vector3(0,0,0),Vector3(4.2,1.1,12),Color(0.055,0.12,0.19),0.5)
    _box(Vector3(0,0.72,-1.5),Vector3(2.7,1.7,3.2),Color(0.78,0.81,0.82),0.25)
    _box(Vector3(0,1.72,-1.55),Vector3(2.0,0.45,2.2),Color(0.08,0.18,0.25),0.6)
    var cs:=CollisionShape3D.new(); var sh:=BoxShape3D.new(); sh.size=Vector3(4.2,2,12); cs.shape=sh; add_child(cs)
    camera=Camera3D.new(); camera.name="ShipCamera"; add_child(camera); camera.current=false; _set_camera()
func _mat(c:Color,metal:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=c; m.metallic=metal; return m
func _box(pos:Vector3,size:Vector3,color:Color,metal:float=0.1)->void:
    var m:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; m.mesh=b; m.position=pos; m.material_override=_mat(color,metal); add_child(m)
func set_control(v: bool) -> void:
    controlled = v
    camera.current = v
    if v:
        _set_camera()
func switch_camera()->void: camera_mode=(camera_mode+1)%2; _set_camera()
func _set_camera()->void:
    camera.position=Vector3(0,5,13) if camera_mode==0 else Vector3(0,2,-2); camera.fov=72 if camera_mode==0 else 90; camera.look_at(to_global(Vector3(0, 1, 0)), Vector3.UP)
func _physics_process(delta:float)->void:
    var throttle:=0.0; var steer:=0.0
    if controlled:
        throttle=float(Input.is_action_pressed("move_forward"))-float(Input.is_action_pressed("move_back"))
        steer=float(Input.is_action_pressed("move_left"))-float(Input.is_action_pressed("move_right"))
        var ui=get_node_or_null("/root/Main/MobileUI")
        if ui: throttle+=ui.get_drive_throttle(); steer+=ui.get_drive_steer()
    speed=move_toward(speed,clamp(throttle,-0.5,1)*13,4.5*delta)
    if abs(speed)>0.1: rotate_y(steer*0.45*delta*sign(speed))
    velocity=-global_basis.z*speed; velocity.y=sin(Time.get_ticks_msec()*0.0018)*0.08
    move_and_slide()
    # Dock zone: slow down near the port berth.
    if global_position.distance_to(Vector3(53,0.15,-42))<8 and abs(speed)<1.2:
        var ui=get_node_or_null("/root/Main/MobileUI")
        if ui: ui.set_status("SHIP DOCKED • Port berth")
