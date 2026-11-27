extends Node

signal mission_updated(title: String, description: String, progress: String)
signal rewards_updated(cash: int, xp: int, level: int)
signal notification(message: String)

const SAVE_PATH := "user://world_life_save.json"
const MISSIONS := [
    {"id": "city_visit", "title": "Airport Recon", "description": "Visit the airport runway", "kind": "visit", "target": Vector3(-20, 0, 22), "radius": 16.0, "reward": 150, "xp": 40},
    {"id": "supply_run", "title": "Supply Run", "description": "Collect all 3 supply crates", "kind": "collect", "target": 3, "reward": 300, "xp": 90},
    {"id": "port_visit", "title": "Harbour Delivery", "description": "Reach the port", "kind": "visit", "target": Vector3(74, 0, -42), "radius": 20.0, "reward": 500, "xp": 140}
]

var mission_index := 0
var completed_missions: Array[String] = []
var collected_pickups: Array[String] = []
var cash := 0
var xp := 0
var level := 1
var supply_count := 0
var _last_progress := ""

func _ready() -> void:
    _emit_state()

func update_player_position(world_position: Vector3) -> void:
    if mission_index >= MISSIONS.size():
        return
    var mission: Dictionary = MISSIONS[mission_index]
    if mission.kind == "visit":
        var target: Vector3 = mission.target
        if Vector2(world_position.x, world_position.z).distance_to(Vector2(target.x, target.z)) <= float(mission.radius):
            _complete_current_mission()

func collect_pickup(pickup_id: String) -> void:
    if collected_pickups.has(pickup_id):
        return
    collected_pickups.append(pickup_id)
    supply_count += 1
    notification.emit("Supply collected (%d/3)" % min(supply_count, 3))
    if mission_index < MISSIONS.size() and MISSIONS[mission_index].id == "supply_run" and supply_count >= 3:
        _complete_current_mission()
    else:
        _emit_state()

func _complete_current_mission() -> void:
    if mission_index >= MISSIONS.size():
        return
    var mission: Dictionary = MISSIONS[mission_index]
    completed_missions.append(str(mission.id))
    cash += int(mission.reward)
    xp += int(mission.xp)
    while xp >= level * 100:
        xp -= level * 100
        level += 1
        notification.emit("Level up! Level %d" % level)
    notification.emit("Mission complete: %s  |  +$%d  +%d XP" % [mission.title, mission.reward, mission.xp])
    mission_index += 1
    if mission_index < MISSIONS.size() and MISSIONS[mission_index].id == "supply_run" and supply_count >= 3:
        _emit_state()
        _complete_current_mission()
        return
    _emit_state()

func get_mission_title() -> String:
    return "All missions complete!" if mission_index >= MISSIONS.size() else str(MISSIONS[mission_index].title)

func get_mission_description() -> String:
    return "Island champion — save your progress" if mission_index >= MISSIONS.size() else str(MISSIONS[mission_index].description)

func get_progress_text() -> String:
    if mission_index >= MISSIONS.size():
        return "%d/%d missions" % [completed_missions.size(), MISSIONS.size()]
    var mission: Dictionary = MISSIONS[mission_index]
    if mission.kind == "collect":
        return "%d/3 supplies" % min(supply_count, 3)
    return "Explore the marked area"

func save_game(player: Node3D) -> bool:
    var data := {
        "version": "0.10",
        "player_position": [player.global_position.x, player.global_position.y, player.global_position.z],
        "cash": cash,
        "xp": xp,
        "level": level,
        "mission_index": mission_index,
        "completed_missions": completed_missions,
        "collected_pickups": collected_pickups,
        "supply_count": supply_count
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        notification.emit("Save failed: cannot open save file")
        return false
    file.store_string(JSON.stringify(data, "\t"))
    notification.emit("Game saved successfully")
    return true

func load_game(player: Node3D, pickups: Array[Node3D]) -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        notification.emit("No save found")
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        notification.emit("Load failed")
        return false
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        notification.emit("Save file is invalid")
        return false
    var data: Dictionary = parsed
    var position_data: Array = data.get("player_position", [0.0, 1.0, 0.0])
    if position_data.size() == 3:
        player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
    cash = int(data.get("cash", 0))
    xp = int(data.get("xp", 0))
    level = maxi(1, int(data.get("level", 1)))
    mission_index = clampi(int(data.get("mission_index", 0)), 0, MISSIONS.size())
    completed_missions.clear()
    for item in data.get("completed_missions", []):
        completed_missions.append(str(item))
    collected_pickups.clear()
    for item in data.get("collected_pickups", []):
        collected_pickups.append(str(item))
    supply_count = int(data.get("supply_count", collected_pickups.size()))
    for pickup in pickups:
        if is_instance_valid(pickup) and collected_pickups.has(str(pickup.get_meta("pickup_id", ""))):
            pickup.queue_free()
    notification.emit("Save loaded successfully")
    _emit_state()
    return true

func _emit_state() -> void:
    var title := get_mission_title()
    var description := get_mission_description()
    var progress := get_progress_text()
    var state_key := "%s|%s|%s" % [title, description, progress]
    if state_key != _last_progress:
        _last_progress = state_key
        mission_updated.emit(title, description, progress)
    rewards_updated.emit(cash, xp, level)
