extends Node3D

const SYSTEM_SCENE_RADIUS: float = 0.45
const FLEET_HEIGHT: float = 0.95
const MIN_ZOOM: float = 9.0
const MAX_ZOOM: float = 28.0
const ZOOM_STEP: float = 1.4
const PAN_SPEED: float = 0.018
const KEYBOARD_PAN_SPEED: float = 11.5
const CAMERA_HEIGHT_RATIO: float = 1.28
const CAMERA_MIN_HEIGHT: float = 12.0
const CAMERA_MAX_HEIGHT: float = 32.0
const CAMERA_PITCH_DEGREES: float = -52.0

@onready var systems_root: Node3D = $SystemsRoot
@onready var lanes_root: Node3D = $LanesRoot
@onready var fleets_root: Node3D = $FleetsRoot
@onready var camera: Camera3D = $Camera3D

var _dragging: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO
var _camera_pan: Vector2 = Vector2.ZERO
var _zoom_distance: float = 18.0

func _ready() -> void:
	GameState.labels_visibility_changed.connect(_on_labels_toggled)
	GameState.selection_changed.connect(_on_selection_changed)
	_zoom_distance = camera.position.z
	_camera_pan = Vector2(camera.position.x, camera.position.z - _zoom_distance)
	camera.rotation_degrees.x = CAMERA_PITCH_DEGREES
	_apply_camera()
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_zoom_distance = max(MIN_ZOOM, _zoom_distance - ZOOM_STEP)
			_apply_camera()
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_zoom_distance = min(MAX_ZOOM, _zoom_distance + ZOOM_STEP)
			_apply_camera()
		elif mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse_button.pressed
			_last_mouse_position = mouse_button.position
	elif event is InputEventMouseMotion and _dragging:
		var motion: InputEventMouseMotion = event
		var delta: Vector2 = motion.position - _last_mouse_position
		_pan_map(Vector2(-delta.x * PAN_SPEED, delta.y * PAN_SPEED))
		_last_mouse_position = motion.position

func _process(delta: float) -> void:
	if _has_text_input_focus():
		return
	var pan_input: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("map_pan_left"):
		pan_input.x -= 1.0
	if Input.is_action_pressed("map_pan_right"):
		pan_input.x += 1.0
	if Input.is_action_pressed("map_pan_up"):
		pan_input.y -= 1.0
	if Input.is_action_pressed("map_pan_down"):
		pan_input.y += 1.0
	if pan_input == Vector2.ZERO:
		return
	_pan_map(pan_input.normalized() * KEYBOARD_PAN_SPEED * delta)

func refresh() -> void:
	_clear_children(systems_root)
	_clear_children(lanes_root)
	_clear_children(fleets_root)
	_build_hyperlanes()
	_build_systems()
	_build_fleets()

func _build_systems() -> void:
	var reachable: Array = GameState.get_reachable_system_ids(GameState.selected_fleet_id)
	for system: Dictionary in GameState.game_state.get("starSystems", []):
		var body: StaticBody3D = StaticBody3D.new()
		body.name = system.get("id", "")
		body.position = system.get("position", Vector3.ZERO)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		collision.shape.radius = SYSTEM_SCENE_RADIUS
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = SYSTEM_SCENE_RADIUS
		sphere.height = SYSTEM_SCENE_RADIUS * 2.0
		mesh_instance.mesh = sphere
		mesh_instance.material_override = _make_system_material(system, reachable.has(system.get("id", "")))
		body.add_child(collision)
		body.add_child(mesh_instance)
		body.input_ray_pickable = true
		body.input_event.connect(_on_system_input.bind(system.get("id", "")))
		systems_root.add_child(body)
		if GameState.labels_visible and system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
			body.add_child(_make_label(str(system.get("name", "")), _system_label_offset(false)))
			body.add_child(_make_label(GameState.get_owner_name(system.get("ownerId", null)), _system_label_offset(true), true))

func _build_hyperlanes() -> void:
	var reachable: Array = GameState.get_reachable_system_ids(GameState.selected_fleet_id)
	var current_system_id: String = GameState.get_fleet_by_id(GameState.selected_fleet_id).get("systemId", "")
	for lane: Dictionary in GameState.game_state.get("hyperlanes", []):
		var start_system: Dictionary = GameState.get_system_by_id(lane.get("startSystemId", ""))
		var end_system: Dictionary = GameState.get_system_by_id(lane.get("endSystemId", ""))
		if start_system.is_empty() or end_system.is_empty():
			continue
		var highlighted: bool = (lane.get("startSystemId", "") == current_system_id and reachable.has(lane.get("endSystemId", ""))) or (lane.get("endSystemId", "") == current_system_id and reachable.has(lane.get("startSystemId", "")))
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = _make_lane_mesh(start_system.get("position", Vector3.ZERO), end_system.get("position", Vector3.ZERO))
		mesh_instance.material_override = _make_lane_material(lane.get("type", "LANE") == "WORMHOLE", highlighted)
		lanes_root.add_child(mesh_instance)

func _build_fleets() -> void:
	var fleet_counts_by_system: Dictionary = {}
	for fleet: Dictionary in GameState.game_state.get("fleets", []):
		var system_id: String = str(fleet.get("systemId", ""))
		var system: Dictionary = GameState.get_system_by_id(system_id)
		if system.is_empty() or system.get("visibilityLevel", "HIDDEN") == "HIDDEN":
			continue
		var fleet_slot: int = int(fleet_counts_by_system.get(system_id, 0))
		fleet_counts_by_system[system_id] = fleet_slot + 1
		var marker: StaticBody3D = StaticBody3D.new()
		marker.name = fleet.get("id", "")
		marker.position = system.get("position", Vector3.ZERO) + Vector3(0.0, FLEET_HEIGHT, 0.0)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		collision.shape.radius = 0.28
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.22
		mesh.height = 0.44
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _make_fleet_material(fleet)
		marker.add_child(collision)
		marker.add_child(mesh_instance)
		marker.input_ray_pickable = true
		marker.input_event.connect(_on_fleet_input.bind(fleet.get("id", "")))
		fleets_root.add_child(marker)
		if GameState.labels_visible:
			marker.add_child(_make_label(str(fleet.get("name", "")), _fleet_label_offset(fleet_slot), true))

func _make_system_material(system: Dictionary, reachable: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("BFA5FF") if reachable else _get_owner_color(system.get("ownerId", null))
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 1.4 if GameState.selected_system_id == system.get("id", "") else 1.0 if reachable else 0.7
	var visibility: String = system.get("visibilityLevel", "HIDDEN")
	if visibility == "PARTIAL":
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.65
	elif visibility == "HIDDEN":
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.18
	return material

func _make_fleet_material(fleet: Dictionary) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = _get_owner_color(fleet.get("ownerId", ""))
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 1.6 if GameState.selected_fleet_id == fleet.get("id", "") else 1.0
	return material

func _make_lane_material(is_wormhole: bool, highlighted: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("C8B7FF") if highlighted else Color("4ECDC4") if is_wormhole else Color("7A8AB7")
	return material

func _make_lane_mesh(start: Vector3, end: Vector3) -> ImmediateMesh:
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	return mesh

func _make_label(text: String, offset: Vector3, compact: bool = false) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.position = offset
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("F8F7FF")
	label.pixel_size = 0.012 if compact else 0.014
	label.font_size = 34 if compact else 42
	label.outline_size = 4
	return label

func _system_label_offset(compact: bool = false) -> Vector3:
	return Vector3(0.0, 1.5 if compact else 2.1, 0.0)

func _fleet_label_offset(slot: int) -> Vector3:
	return Vector3(0.0, 2.55 + 0.62 * float(slot), 0.0)

func _get_owner_color(owner_id: Variant) -> Color:
	if owner_id == null:
		return Color("9CA3AF")
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("id", "") == owner_id:
			return faction.get("color", Color.WHITE)
	return Color("6B7280")

func _clear_children(root: Node) -> void:
	for child: Node in root.get_children():
		child.queue_free()

func _apply_camera() -> void:
	camera.rotation_degrees.x = CAMERA_PITCH_DEGREES
	camera.position = Vector3(
		_camera_pan.x,
		clamp(_zoom_distance * CAMERA_HEIGHT_RATIO, CAMERA_MIN_HEIGHT, CAMERA_MAX_HEIGHT),
		_camera_pan.y + _zoom_distance
	)

func _pan_map(delta: Vector2) -> void:
	_camera_pan += delta
	_apply_camera()

func _has_text_input_focus() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit

func _on_system_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, system_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState.try_move_selected_fleet_to_system(system_id):
			return
		GameState.select_system(system_id)

func _on_fleet_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, fleet_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameState.select_fleet(fleet_id)

func _on_labels_toggled(_visible: bool) -> void:
	refresh()

func _on_selection_changed(_system_id: String, _fleet_id: String) -> void:
	refresh()
