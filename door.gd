extends Node3D

var is_open := false
var closed_yaw := 0.0
var active_tween: Tween

func _ready() -> void:
    closed_yaw = rotation.y

func interact(_actor: Node3D) -> String:
    is_open = not is_open
    if active_tween and active_tween.is_running():
        active_tween.kill()
    active_tween = create_tween()
    var target_yaw := closed_yaw + deg_to_rad(95.0) if is_open else closed_yaw
    active_tween.tween_property(self, "rotation:y", target_yaw, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    return "Door opened" if is_open else "Door closed"
