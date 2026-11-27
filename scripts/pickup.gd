extends Node3D

signal pickup_collected(pickup_id: String)
var collected := false
var pickup_id := ""

func _process(delta: float) -> void:
    if not collected:
        rotate_y(delta * 0.8)

func interact(_actor: Node3D) -> String:
    if collected:
        return "Already collected"
    collected = true
    pickup_collected.emit(pickup_id)
    queue_free()
    return "Supply collected"
