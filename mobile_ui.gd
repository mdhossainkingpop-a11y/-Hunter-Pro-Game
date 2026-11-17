extends CanvasLayer

signal interact_pressed
signal bomb_pressed
signal save_pressed
signal load_pressed
signal quality_pressed

var move_vector := Vector2.ZERO
var drive_vector := Vector2.ZERO
var vertical_input := 0.0
var jump_requested := false
var sprint_held := false
var brake_held := false
var roll_input := 0.0
var status: Label
var mode_label: Label
var mission_label: Label
var reward_label: Label

func _ready() -> void:
    var hud := PanelContainer.new()
    hud.anchor_left = 0.015
    hud.anchor_top = 0.02
    hud.anchor_right = 0.43
    hud.anchor_bottom = 0.22
    add_child(hud)

    var vb := VBoxContainer.new()
    hud.add_child(vb)
    var title := Label.new()
    title.text = "🌍 WORLD LIFE 3D"
    title.add_theme_font_size_override("font_size", 19)
    vb.add_child(title)
    status = Label.new()
    status.text = "Explore the island • Walk • Run • Jump"
    vb.add_child(status)
    mode_label = Label.new()
    mode_label.text = "ON FOOT"
    mode_label.add_theme_color_override("font_color", Color(0.25, 0.95, 0.55))
    vb.add_child(mode_label)
    mission_label = Label.new()
    mission_label.text = "MISSION: City Explorer\nVisit the city centre"
    mission_label.add_theme_font_size_override("font_size", 13)
    vb.add_child(mission_label)
    reward_label = Label.new()
    reward_label.text = "$0  |  LV 1  |  0 XP"
    reward_label.add_theme_font_size_override("font_size", 12)
    vb.add_child(reward_label)

    _pad("◀", Vector2(0.025, 0.72), Vector2(-1, 0), false)
    _pad("▶", Vector2(0.16, 0.72), Vector2(1, 0), false)
    _pad("▲", Vector2(0.092, 0.58), Vector2(0, 1), false)
    _pad("▼", Vector2(0.092, 0.86), Vector2(0, -1), false)
    _pad("◀", Vector2(0.73, 0.72), Vector2(-1, 0), true)
    _pad("▶", Vector2(0.865, 0.72), Vector2(1, 0), true)
    _pad("▲", Vector2(0.797, 0.58), Vector2(0, -1), true)
    _pad("▼", Vector2(0.797, 0.86), Vector2(0, 1), true)

    _action("JUMP", Vector2(0.39, 0.66), Vector2(0.52, 0.79), func(): jump_requested = true)
    _hold_action("RUN", Vector2(0.53, 0.66), Vector2(0.67, 0.79), func(): sprint_held = true, func(): sprint_held = false)
    _action("INTERACT", Vector2(0.39, 0.84), Vector2(0.60, 0.96), func(): interact_pressed.emit())
    _action("DROP BOMB", Vector2(0.67, 0.04), Vector2(0.84, 0.15), func(): bomb_pressed.emit())
    _action("SAVE", Vector2(0.44, 0.04), Vector2(0.54, 0.12), func(): save_pressed.emit())
    _action("LOAD", Vector2(0.55, 0.04), Vector2(0.65, 0.12), func(): load_pressed.emit())
    _action("GFX: LOW", Vector2(0.86, 0.04), Vector2(0.985, 0.14), func(): quality_pressed.emit())
    _hold_action("BRAKE", Vector2(0.70, 0.86), Vector2(0.82, 0.97), func(): brake_held = true, func(): brake_held = false)
    _action("CAM", Vector2(0.85, 0.86), Vector2(0.97, 0.97), func(): _switch_vehicle_camera())
    _hold_action("ROLL ◀", Vector2(0.62, 0.48), Vector2(0.73, 0.58), func(): roll_input = -1.0, func(): roll_input = 0.0)
    _hold_action("ROLL ▶", Vector2(0.85, 0.48), Vector2(0.96, 0.58), func(): roll_input = 1.0, func(): roll_input = 0.0)
    _minimap()

func _minimap() -> void:
    var panel := Panel.new()
    panel.anchor_left = 0.82
    panel.anchor_top = 0.18
    panel.anchor_right = 0.98
    panel.anchor_bottom = 0.42
    panel.modulate = Color(0.75, 0.9, 0.8, 0.92)
    add_child(panel)
    var label := Label.new()
    label.text = "N\n━━━━\n  •  CITY\n~~~~ RIVER\n━━ ROAD"
    label.add_theme_font_size_override("font_size", 12)
    label.position = Vector2(8, 5)
    panel.add_child(label)

func _pad(text_value: String, anchor: Vector2, direction: Vector2, driving: bool) -> void:
    var button := Button.new()
    button.text = text_value
    button.anchor_left = anchor.x
    button.anchor_top = anchor.y
    button.anchor_right = anchor.x + 0.12
    button.anchor_bottom = anchor.y + 0.12
    button.add_theme_font_size_override("font_size", 23)
    button.button_down.connect(func():
        if driving:
            drive_vector = direction
            if direction.y != 0.0:
                vertical_input = -direction.y
        else:
            move_vector = direction
    )
    button.button_up.connect(func():
        if driving:
            if drive_vector == direction:
                drive_vector = Vector2.ZERO
            if direction.y != 0.0:
                vertical_input = 0.0
        elif move_vector == direction:
            move_vector = Vector2.ZERO
    )
    add_child(button)

func _action(text_value: String, anchor: Vector2, end_anchor: Vector2, callback: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.anchor_left = anchor.x
    button.anchor_top = anchor.y
    button.anchor_right = end_anchor.x
    button.anchor_bottom = end_anchor.y
    button.pressed.connect(callback)
    add_child(button)

func _hold_action(text_value: String, anchor: Vector2, end_anchor: Vector2, on_down: Callable, on_up: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.anchor_left = anchor.x
    button.anchor_top = anchor.y
    button.anchor_right = end_anchor.x
    button.anchor_bottom = end_anchor.y
    button.button_down.connect(on_down)
    button.button_up.connect(on_up)
    add_child(button)

func get_move_vector() -> Vector2:
    return move_vector

func get_drive_vector() -> Vector2:
    return drive_vector

func get_vertical_input() -> float:
    return vertical_input

func consume_jump() -> bool:
    var requested := jump_requested
    jump_requested = false
    return requested

func is_sprinting() -> bool:
    return sprint_held

func set_status(value: String) -> void:
    if status:
        status.text = value

func set_mode(value: String) -> void:
    if mode_label:
        mode_label.text = value

func set_mission(title_value: String, description: String, progress: String) -> void:
    if mission_label:
        mission_label.text = "MISSION: %s\n%s — %s" % [title_value, description, progress]

func set_rewards(cash: int, xp: int, level: int) -> void:
    if reward_label:
        reward_label.text = "$%d  |  LV %d  |  %d XP" % [cash, level, xp]

func get_drive_throttle() -> float:
    return -drive_vector.y
func get_drive_steer() -> float:
    return drive_vector.x
func is_braking() -> bool:
    return brake_held
func get_roll_input() -> float:
    return roll_input
func _switch_vehicle_camera() -> void:
    var p=get_node_or_null("/root/Main/Player")
    if p and p.in_vehicle and is_instance_valid(p.current_vehicle) and p.current_vehicle.has_method("switch_camera"):
        p.current_vehicle.call("switch_camera")

func set_quality_label(value: String) -> void:
    for child in get_children():
        if child is Button and str(child.text).begins_with("GFX:"):
            child.text = "GFX: " + value
            return
