extends Node3D

const SYSTEM_SCENE_RADIUS: float = 0.45
const SYSTEM_SOLAR_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_solar.png"
const SYSTEM_BINARY_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_binary.png"
const SYSTEM_NEBULA_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_nebula.png"
const SYSTEM_STORM_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_storm.png"
const SYSTEM_BLACK_HOLE_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_black_hole.png"
const SYSTEM_COLONY_HUB_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_colony_hub.png"
const SYSTEM_SOLAR_DUST_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_solar_dust.png"
const SYSTEM_SOLAR_BLUE_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_solar_blue.png"
const SYSTEM_RED_DWARF_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_red_dwarf.png"
const SYSTEM_BINARY_CLOSE_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_binary_close.png"
const SYSTEM_BINARY_ACCRETION_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_binary_accretion.png"
const SYSTEM_MAGNETAR_STORM_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_magnetar_storm.png"
const SYSTEM_BLACK_HOLE_LENSED_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_black_hole_lensed.png"
const SYSTEM_STAR_CLUSTER_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_star_cluster.png"
const SYSTEM_COLONY_ORBITAL_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_colony_orbital.png"
const SYSTEM_SOLAR_TEXTURE_PATHS: Array[String] = [
	SYSTEM_SOLAR_TEXTURE_PATH,
	SYSTEM_SOLAR_DUST_TEXTURE_PATH,
	SYSTEM_SOLAR_BLUE_TEXTURE_PATH,
	SYSTEM_RED_DWARF_TEXTURE_PATH
]
const SYSTEM_BINARY_TEXTURE_PATHS: Array[String] = [
	SYSTEM_BINARY_TEXTURE_PATH,
	SYSTEM_BINARY_CLOSE_TEXTURE_PATH,
	SYSTEM_BINARY_ACCRETION_TEXTURE_PATH
]
const SYSTEM_STORM_TEXTURE_PATHS: Array[String] = [
	SYSTEM_STORM_TEXTURE_PATH,
	SYSTEM_MAGNETAR_STORM_TEXTURE_PATH
]
const SYSTEM_BLACK_HOLE_TEXTURE_PATHS: Array[String] = [
	SYSTEM_BLACK_HOLE_TEXTURE_PATH,
	SYSTEM_BLACK_HOLE_LENSED_TEXTURE_PATH
]
const SYSTEM_COLONY_TEXTURE_PATHS: Array[String] = [
	SYSTEM_COLONY_HUB_TEXTURE_PATH,
	SYSTEM_COLONY_ORBITAL_TEXTURE_PATH
]
const HYPERLANE_DASH_TEXTURE_PATH: String = "res://assets/vfx/starmap/hyperlane_dash.png"
const WORMHOLE_ROUTE_TICK_TEXTURE_PATH: String = "res://assets/vfx/starmap/wormhole_route_tick.png"
const FLEET_MARKER_TEXTURE_PATH: String = "res://assets/vfx/starmap/fleet_marker_chevron.png"
const NEBULA_BACKDROP_TEXTURE_PATH: String = "res://assets/vfx/starmap/background_nebula_low_visibility.png"
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
const STARFIELD_COUNT: int = 120
const BRIGHT_STARFIELD_COUNT: int = 34
const STARFIELD_RADIUS: float = 34.0
const STARFIELD_SEED: int = 42137
const NEBULA_BACKDROP_SIZE: Vector2 = Vector2(76.0, 42.75)
const NEBULA_BACKDROP_ALPHA: float = 0.42
const NEBULA_BACKDROP_HEIGHT: float = -0.47
const DEPTH_GRID_EXTENT: float = 32.0
const DEPTH_GRID_STEP: float = 4.0
const DEPTH_GRID_HEIGHT: float = -0.42
const SYSTEM_TEXTURE_WORLD_SIZE: float = 2.28
const SELECTED_SYSTEM_TEXTURE_WORLD_SIZE: float = 2.56
const SELECTED_SYSTEM_BRACKET_RADIUS: float = 1.08
const SYSTEM_TACTICAL_RADIUS: float = 1.08
const SYSTEM_SELECTED_TACTICAL_RADIUS: float = 1.28
const SYSTEM_TACTICAL_SEGMENTS: int = 48
const SYSTEM_TACTICAL_GAP_SEGMENTS: int = 5
const FLEET_MARKER_PIXEL_SIZE: float = 0.0046
const LANE_STRIP_WIDTH: float = 0.032
const HIGHLIGHTED_LANE_STRIP_WIDTH: float = 0.044
const LANE_GLOW_WIDTH_MULTIPLIER: float = 1.45
const LANE_TEXTURE_WIDTH: float = 0.22
const HIGHLIGHTED_LANE_TEXTURE_WIDTH: float = 0.28
const VFX_LANE_FLOW_SPEED: float = 0.075
const VFX_LANE_ALPHA_PULSE: float = 0.035
const VFX_SYSTEM_PULSE_AMOUNT: float = 0.045
const VFX_FLEET_PULSE_AMOUNT: float = 0.07
const VFX_RETICLE_ALPHA_PULSE: float = 0.16
const VFX_NEBULA_DRIFT_SPEED: float = 0.006
const VFX_NEBULA_ALPHA_PULSE: float = 0.018
const RESOURCE_BADGE_LABELS: Dictionary = {"food": "食", "minerals": "矿", "industry": "工", "energy": "能"}
const RESOURCE_BADGE_COLORS: Dictionary = {
	"food": Color("FF8B6B"),
	"minerals": Color("4ECDC4"),
	"industry": Color("FFE66D"),
	"energy": Color("95E1D3")
}
const MAX_RESOURCE_BADGES: int = 2
const SYSTEM_LABEL_CHANNELS: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0),
	Vector3(0.74, -0.14, 0.0),
	Vector3(-0.74, -0.14, 0.0),
	Vector3(0.0, 0.34, 0.0)
]
const FLEET_LABEL_CHANNELS: Array[Vector3] = [
	Vector3(0.82, 0.0, 0.0),
	Vector3(-0.82, 0.0, 0.0),
	Vector3(0.32, 0.46, 0.0),
	Vector3(-0.32, 0.46, 0.0)
]
const FLEET_STACK_OFFSETS: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0),
	Vector3(0.48, 0.0, 0.18),
	Vector3(-0.48, 0.0, 0.18),
	Vector3(0.0, 0.0, -0.44),
	Vector3(0.68, 0.0, -0.34),
	Vector3(-0.68, 0.0, -0.34)
]

@onready var ambient_root: Node3D = $AmbientRoot
@onready var systems_root: Node3D = $SystemsRoot
@onready var lanes_root: Node3D = $LanesRoot
@onready var fleets_root: Node3D = $FleetsRoot
@onready var camera: Camera3D = $Camera3D

var _dragging: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO
var _camera_pan: Vector2 = Vector2.ZERO
var _zoom_distance: float = 18.0
var _texture_cache: Dictionary = {}
var _vfx_time: float = 0.0

func _ready() -> void:
	GameState.labels_visibility_changed.connect(_on_labels_toggled)
	GameState.selection_changed.connect(_on_selection_changed)
	_zoom_distance = camera.position.z
	_camera_pan = Vector2(camera.position.x, camera.position.z - _zoom_distance)
	camera.rotation_degrees.x = CAMERA_PITCH_DEGREES
	_apply_camera()
	_build_ambient_space()
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
	_vfx_time += delta
	_animate_star_map_vfx()
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

func _build_ambient_space() -> void:
	_clear_children(ambient_root)
	ambient_root.add_child(_make_nebula_backdrop())
	ambient_root.add_child(_make_starfield())
	ambient_root.add_child(_make_bright_starfield())
	ambient_root.add_child(_make_depth_grid())

func _build_systems() -> void:
	var reachable: Array = GameState.get_reachable_system_ids(GameState.selected_fleet_id)
	for system: Dictionary in GameState.game_state.get("starSystems", []):
		var body: StaticBody3D = StaticBody3D.new()
		body.name = system.get("id", "")
		body.position = system.get("position", Vector3.ZERO)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		collision.shape.radius = SYSTEM_SCENE_RADIUS
		body.add_child(collision)
		if system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
			body.add_child(_make_system_tactical_overlay(system, reachable.has(system.get("id", ""))))
		body.add_child(_make_system_texture_sprite(system, reachable.has(system.get("id", ""))))
		if system.get("ownerId", null) != null and system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
			body.add_child(_make_system_owner_plate(system))
		if GameState.selected_system_id == system.get("id", ""):
			body.add_child(_make_system_reticle(system))
		body.input_ray_pickable = true
		body.input_event.connect(_on_system_input.bind(system.get("id", "")))
		systems_root.add_child(body)
		if GameState.labels_visible and system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
			var label_channel: int = _label_channel_for_id(str(system.get("id", "")), SYSTEM_LABEL_CHANNELS.size())
			body.add_child(_make_label(str(system.get("name", "")), _system_label_offset(false, label_channel)))
			body.add_child(_make_system_resource_badges(system))

func _build_hyperlanes() -> void:
	var reachable: Array = GameState.get_reachable_system_ids(GameState.selected_fleet_id)
	var current_system_id: String = GameState.get_fleet_by_id(GameState.selected_fleet_id).get("systemId", "")
	var lane_anchors: Dictionary = {}
	for lane: Dictionary in GameState.game_state.get("hyperlanes", []):
		var start_system: Dictionary = GameState.get_system_by_id(lane.get("startSystemId", ""))
		var end_system: Dictionary = GameState.get_system_by_id(lane.get("endSystemId", ""))
		if start_system.is_empty() or end_system.is_empty():
			continue
		var highlighted: bool = (lane.get("startSystemId", "") == current_system_id and reachable.has(lane.get("endSystemId", ""))) or (lane.get("endSystemId", "") == current_system_id and reachable.has(lane.get("startSystemId", "")))
		var lane_width: float = HIGHLIGHTED_LANE_STRIP_WIDTH if highlighted else LANE_STRIP_WIDTH
		if start_system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
			_remember_lane_anchor(lane_anchors, start_system, lane.get("type", "LANE") == "WORMHOLE", highlighted)
		if end_system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
			_remember_lane_anchor(lane_anchors, end_system, lane.get("type", "LANE") == "WORMHOLE", highlighted)
		var glow_instance: MeshInstance3D = MeshInstance3D.new()
		glow_instance.mesh = _make_lane_mesh(
			start_system.get("position", Vector3.ZERO),
			end_system.get("position", Vector3.ZERO),
			lane_width * LANE_GLOW_WIDTH_MULTIPLIER
		)
		glow_instance.material_override = _make_lane_glow_material(lane.get("type", "LANE") == "WORMHOLE", highlighted)
		lanes_root.add_child(glow_instance)
		lanes_root.add_child(_make_textured_lane_overlay(
			start_system.get("position", Vector3.ZERO),
			end_system.get("position", Vector3.ZERO),
			lane.get("type", "LANE") == "WORMHOLE",
			highlighted
		))
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = _make_lane_mesh(
			start_system.get("position", Vector3.ZERO),
			end_system.get("position", Vector3.ZERO),
			lane_width
		)
		mesh_instance.material_override = _make_lane_material(lane.get("type", "LANE") == "WORMHOLE", highlighted)
		lanes_root.add_child(mesh_instance)
	for anchor_data: Dictionary in lane_anchors.values():
		lanes_root.add_child(_make_lane_anchor(
			anchor_data.get("position", Vector3.ZERO),
			bool(anchor_data.get("is_wormhole", false)),
			bool(anchor_data.get("highlighted", false))
		))

func _remember_lane_anchor(anchors: Dictionary, system: Dictionary, is_wormhole: bool, highlighted: bool) -> void:
	var system_id: String = str(system.get("id", ""))
	if system_id == "":
		return
	if not anchors.has(system_id):
		anchors[system_id] = {
			"position": system.get("position", Vector3.ZERO),
			"is_wormhole": is_wormhole,
			"highlighted": highlighted
		}
		return
	var anchor: Dictionary = anchors.get(system_id, {})
	anchor["is_wormhole"] = bool(anchor.get("is_wormhole", false)) or is_wormhole
	anchor["highlighted"] = bool(anchor.get("highlighted", false)) or highlighted
	anchors[system_id] = anchor

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
		marker.position = system.get("position", Vector3.ZERO) + Vector3(0.0, FLEET_HEIGHT, 0.0) + _fleet_stack_offset(fleet_slot)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		collision.shape.radius = 0.28
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = 0.2
		mesh.bottom_radius = 0.28
		mesh.height = 0.14
		mesh.radial_segments = 6
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _make_fleet_material(fleet)
		marker.add_child(collision)
		marker.add_child(_make_fleet_marker_sprite(fleet))
		marker.add_child(mesh_instance)
		marker.add_child(_make_fleet_readiness_badge(fleet))
		marker.input_ray_pickable = true
		marker.input_event.connect(_on_fleet_input.bind(fleet.get("id", "")))
		fleets_root.add_child(marker)
		if GameState.labels_visible and _should_show_fleet_label(fleet):
			var fleet_channel: int = _label_channel_for_id(system_id, FLEET_LABEL_CHANNELS.size())
			marker.add_child(_make_label(_compact_label_text(str(fleet.get("name", "")), 10), _fleet_label_offset(fleet_slot, fleet_channel), true))

func _make_fleet_material(fleet: Dictionary) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = _get_owner_color(fleet.get("ownerId", ""))
	material.albedo_color.a = 0.34
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.62 if GameState.selected_fleet_id == fleet.get("id", "") else 0.18
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _make_lane_material(is_wormhole: bool, highlighted: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("9FC7D0") if highlighted else Color("7BBDB6") if is_wormhole else Color("6C8798")
	material.emission_enabled = highlighted or is_wormhole
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.42 if highlighted else 0.18
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.28 if highlighted else (0.18 if is_wormhole else 0.13)
	material.no_depth_test = true
	return material

func _make_lane_glow_material(is_wormhole: bool, highlighted: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color("9FC7D0", 0.055) if highlighted else Color("7BBDB6", 0.04) if is_wormhole else Color("6C8798", 0.025)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.16 if highlighted else 0.08
	material.no_depth_test = true
	return material

func _make_lane_anchor(position: Vector3, is_wormhole: bool, highlighted: bool) -> MeshInstance3D:
	var anchor := MeshInstance3D.new()
	anchor.name = "LaneAnchor"
	anchor.position = position + Vector3(0.0, 0.028 if highlighted else 0.02, 0.0)
	var mesh := ImmediateMesh.new()
	var radius: float = 0.24 if highlighted else 0.16
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for axis: Vector3 in [Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT, Vector3.BACK]:
		var tangent := Vector3(-axis.z, 0.0, axis.x)
		mesh.surface_add_vertex(axis * radius + tangent * 0.07)
		mesh.surface_add_vertex(axis * radius - tangent * 0.07)
	mesh.surface_end()
	var color: Color = Color("9FC7D0") if highlighted else Color("7BBDB6") if is_wormhole else Color("6C8798")
	color.a = 0.24 if highlighted else 0.16
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.34 if highlighted else 0.18
	material.no_depth_test = true
	anchor.mesh = mesh
	anchor.material_override = material
	return anchor

func _make_textured_lane_overlay(start: Vector3, end: Vector3, is_wormhole: bool, highlighted: bool) -> MeshInstance3D:
	var direction: Vector3 = end - start
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length() <= 0.001:
		flat_direction = Vector3.RIGHT
	var length: float = flat_direction.length()
	var tangent: Vector3 = flat_direction.normalized()
	var lane := MeshInstance3D.new()
	lane.name = "WormholeRouteTexture" if is_wormhole else "HyperlaneDashTexture"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(length, HIGHLIGHTED_LANE_TEXTURE_WIDTH if highlighted else LANE_TEXTURE_WIDTH)
	lane.mesh = mesh
	lane.position = (start + end) * 0.5 + Vector3(0.0, 0.026 if highlighted else 0.018, 0.0)
	lane.rotation_degrees.y = rad_to_deg(atan2(-tangent.z, tangent.x))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = _load_texture_cached(WORMHOLE_ROUTE_TICK_TEXTURE_PATH if is_wormhole else HYPERLANE_DASH_TEXTURE_PATH)
	var base_alpha: float = 0.27 if highlighted else (0.22 if is_wormhole else 0.16)
	material.albedo_color = Color("A8DCD8", base_alpha)
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.16 if highlighted else 0.10
	material.no_depth_test = true
	lane.material_override = material
	lane.add_to_group("starmap_vfx_animated")
	lane.set_meta("vfx_kind", "lane_flow")
	lane.set_meta("base_alpha", base_alpha)
	lane.set_meta("base_emission", material.emission_energy_multiplier)
	lane.set_meta("phase", start.x * 0.17 + end.z * 0.11)
	lane.set_meta("flow_speed", VFX_LANE_FLOW_SPEED * (1.35 if is_wormhole else 1.0))
	return lane

func _make_lane_mesh(start: Vector3, end: Vector3, width: float) -> ArrayMesh:
	var direction: Vector3 = end - start
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length() <= 0.001:
		flat_direction = Vector3.FORWARD
	var tangent: Vector3 = flat_direction.normalized()
	var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x) * width
	var vertices := PackedVector3Array([
		start + side,
		start - side,
		end + side,
		end - side,
	])
	var indices := PackedInt32Array([0, 1, 2, 2, 1, 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_nebula_backdrop() -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = "NebulaBackdrop"
	instance.mesh = _make_nebula_backdrop_mesh()
	instance.position = Vector3(0.0, NEBULA_BACKDROP_HEIGHT, 0.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color("FFFFFF", NEBULA_BACKDROP_ALPHA)
	material.albedo_texture = _load_texture_cached(NEBULA_BACKDROP_TEXTURE_PATH)
	material.emission_enabled = true
	material.emission = Color("1C536A")
	material.emission_energy_multiplier = 0.08
	instance.material_override = material
	instance.add_to_group("starmap_vfx_animated")
	instance.set_meta("vfx_kind", "nebula_backdrop")
	instance.set_meta("base_alpha", NEBULA_BACKDROP_ALPHA)
	instance.set_meta("phase", 1.8)
	return instance

func _make_nebula_backdrop_mesh() -> ArrayMesh:
	var half_size: Vector2 = NEBULA_BACKDROP_SIZE * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_size.x, 0.0, -half_size.y),
		Vector3(half_size.x, 0.0, -half_size.y),
		Vector3(-half_size.x, 0.0, half_size.y),
		Vector3(half_size.x, 0.0, half_size.y),
	])
	var uvs := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
	])
	var indices := PackedInt32Array([0, 1, 2, 2, 1, 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_starfield() -> MultiMeshInstance3D:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.035
	star_mesh.height = 0.07
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("D7E9FF", 0.78)
	material.emission_enabled = true
	material.emission = Color("D7E9FF")
	material.emission_energy_multiplier = 0.45
	star_mesh.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = star_mesh
	multimesh.instance_count = STARFIELD_COUNT
	var rng := RandomNumberGenerator.new()
	rng.seed = STARFIELD_SEED
	for index: int in range(STARFIELD_COUNT):
		var x: float = rng.randf_range(-STARFIELD_RADIUS, STARFIELD_RADIUS)
		var z: float = rng.randf_range(-STARFIELD_RADIUS, STARFIELD_RADIUS)
		var y: float = rng.randf_range(-3.4, -1.6)
		var scale_value: float = rng.randf_range(0.55, 1.55)
		var transform := Transform3D(Basis().scaled(Vector3.ONE * scale_value), Vector3(x, y, z))
		multimesh.set_instance_transform(index, transform)
	var instance := MultiMeshInstance3D.new()
	instance.name = "ProceduralStarfield"
	instance.multimesh = multimesh
	return instance

func _make_bright_starfield() -> MultiMeshInstance3D:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.055
	star_mesh.height = 0.11
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("D7E9FF", 0.72)
	material.emission_enabled = true
	material.emission = Color("D7E9FF")
	material.emission_energy_multiplier = 0.62
	star_mesh.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = star_mesh
	multimesh.instance_count = BRIGHT_STARFIELD_COUNT
	var rng := RandomNumberGenerator.new()
	rng.seed = STARFIELD_SEED + 917
	for index: int in range(BRIGHT_STARFIELD_COUNT):
		var x: float = rng.randf_range(-STARFIELD_RADIUS, STARFIELD_RADIUS)
		var z: float = rng.randf_range(-STARFIELD_RADIUS, STARFIELD_RADIUS)
		var y: float = rng.randf_range(-3.7, -1.25)
		var scale_value: float = rng.randf_range(0.65, 2.2)
		var transform := Transform3D(Basis().scaled(Vector3.ONE * scale_value), Vector3(x, y, z))
		multimesh.set_instance_transform(index, transform)
	var instance := MultiMeshInstance3D.new()
	instance.name = "BrightStarfield"
	instance.multimesh = multimesh
	return instance

func _make_depth_grid() -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var line_count: int = int(DEPTH_GRID_EXTENT * 2.0 / DEPTH_GRID_STEP)
	for index: int in range(line_count + 1):
		var offset: float = -DEPTH_GRID_EXTENT + float(index) * DEPTH_GRID_STEP
		mesh.surface_add_vertex(Vector3(-DEPTH_GRID_EXTENT, DEPTH_GRID_HEIGHT, offset))
		mesh.surface_add_vertex(Vector3(DEPTH_GRID_EXTENT, DEPTH_GRID_HEIGHT, offset))
		mesh.surface_add_vertex(Vector3(offset, DEPTH_GRID_HEIGHT, -DEPTH_GRID_EXTENT))
		mesh.surface_add_vertex(Vector3(offset, DEPTH_GRID_HEIGHT, DEPTH_GRID_EXTENT))
	mesh.surface_end()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color("24506A", 0.18)
	material.emission_enabled = true
	material.emission = Color("24506A")
	material.emission_energy_multiplier = 0.28
	var instance := MeshInstance3D.new()
	instance.name = "DepthGrid"
	instance.mesh = mesh
	instance.material_override = material
	return instance

func _make_system_reticle(system: Dictionary) -> MeshInstance3D:
	var reticle := MeshInstance3D.new()
	reticle.name = "SelectedSystemReticle"
	var mesh := ImmediateMesh.new()
	var radius: float = SELECTED_SYSTEM_BRACKET_RADIUS
	var bracket: float = 0.38
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var x: float = corner.x * radius
		var z: float = corner.y * radius
		mesh.surface_add_vertex(Vector3(x, 0.03, z))
		mesh.surface_add_vertex(Vector3(x - corner.x * bracket, 0.03, z))
		mesh.surface_add_vertex(Vector3(x, 0.03, z))
		mesh.surface_add_vertex(Vector3(x, 0.03, z - corner.y * bracket))
	mesh.surface_end()
	var color: Color = _system_display_color(system, true)
	color.a = 0.92
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.1
	material.no_depth_test = true
	reticle.mesh = mesh
	reticle.material_override = material
	reticle.add_to_group("starmap_vfx_animated")
	reticle.set_meta("vfx_kind", "selection_reticle")
	reticle.set_meta("base_alpha", color.a)
	reticle.set_meta("phase", float(abs(str(system.get("id", "")).hash()) % 1000) / 100.0)
	return reticle

func _make_system_tactical_overlay(system: Dictionary, reachable: bool) -> MeshInstance3D:
	var overlay := MeshInstance3D.new()
	overlay.name = "SystemTacticalOverlay"
	var selected: bool = GameState.selected_system_id == system.get("id", "")
	var radius: float = SYSTEM_SELECTED_TACTICAL_RADIUS if selected else SYSTEM_TACTICAL_RADIUS
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for index: int in range(SYSTEM_TACTICAL_SEGMENTS):
		if index % 12 < SYSTEM_TACTICAL_GAP_SEGMENTS:
			continue
		var start_angle: float = TAU * float(index) / float(SYSTEM_TACTICAL_SEGMENTS)
		var end_angle: float = TAU * float(index + 1) / float(SYSTEM_TACTICAL_SEGMENTS)
		mesh.surface_add_vertex(Vector3(cos(start_angle) * radius, 0.035, sin(start_angle) * radius))
		mesh.surface_add_vertex(Vector3(cos(end_angle) * radius, 0.035, sin(end_angle) * radius))
	for index: int in range(8):
		var angle: float = TAU * float(index) / 8.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		mesh.surface_add_vertex(direction * (radius + 0.12) + Vector3(0.0, 0.035, 0.0))
		mesh.surface_add_vertex(direction * (radius + (0.32 if selected else 0.22)) + Vector3(0.0, 0.035, 0.0))
	mesh.surface_end()
	var color: Color = _system_display_color(system, reachable)
	color.a = 0.58 if selected else 0.38 if reachable else 0.22
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.72 if selected or reachable else 0.34
	material.no_depth_test = true
	overlay.mesh = mesh
	overlay.material_override = material
	overlay.add_to_group("starmap_vfx_animated")
	overlay.set_meta("vfx_kind", "system_overlay")
	overlay.set_meta("base_alpha", color.a)
	overlay.set_meta("rotation_speed", 0.18 if selected else 0.06 if reachable else 0.0)
	overlay.set_meta("phase", float(abs(str(system.get("id", "")).hash()) % 1000) / 80.0)
	return overlay

func _make_system_texture_sprite(system: Dictionary, reachable: bool) -> MeshInstance3D:
	var sprite := MeshInstance3D.new()
	sprite.name = "SystemTextureTopDown"
	var size: float = SELECTED_SYSTEM_TEXTURE_WORLD_SIZE if GameState.selected_system_id == system.get("id", "") else SYSTEM_TEXTURE_WORLD_SIZE
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(size, size)
	sprite.mesh = mesh
	sprite.position = Vector3(0.0, 0.055, 0.0)
	var visibility: String = system.get("visibilityLevel", "HIDDEN")
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = _load_texture_cached(_system_texture_path(system))
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.34 if visibility == "HIDDEN" else 0.48
	material.no_depth_test = true
	var tint: Color = Color(1.0, 1.0, 1.0, 0.94)
	if visibility == "HIDDEN":
		tint = Color("8FB9D6", 0.34)
	elif visibility == "PARTIAL":
		tint = Color("D4ECFF", 0.72)
	elif reachable:
		tint = Color("E5D9FF", 1.0)
	material.albedo_color = tint
	material.emission = tint
	sprite.material_override = material
	sprite.add_to_group("starmap_vfx_animated")
	sprite.set_meta("vfx_kind", "system_node")
	sprite.set_meta("base_alpha", tint.a)
	sprite.set_meta("base_scale", sprite.scale)
	sprite.set_meta("phase", float(abs(str(system.get("id", "")).hash()) % 1000) / 90.0)
	return sprite

func _make_system_owner_plate(system: Dictionary) -> MeshInstance3D:
	var plate := MeshInstance3D.new()
	plate.name = "SystemOwnerPlate"
	var radius: float = 1.18
	var notch: float = 0.42
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var points: Array[Vector3] = [
		Vector3(0.0, 0.01, -radius),
		Vector3(radius, 0.01, 0.0),
		Vector3(0.0, 0.01, radius),
		Vector3(-radius, 0.01, 0.0)
	]
	for index: int in range(points.size()):
		var start: Vector3 = points[index].lerp(points[(index + 1) % points.size()], 0.16)
		var end: Vector3 = points[index].lerp(points[(index + 1) % points.size()], 0.84)
		mesh.surface_add_vertex(start)
		mesh.surface_add_vertex(end)
	for axis: Vector3 in [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]:
		mesh.surface_add_vertex(axis * (radius + 0.12))
		mesh.surface_add_vertex(axis * (radius + notch))
	mesh.surface_end()
	var color: Color = _get_owner_color(system.get("ownerId", null))
	color.a = 0.46
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.42
	material.no_depth_test = true
	plate.mesh = mesh
	plate.material_override = material
	return plate

func _make_fleet_marker_sprite(fleet: Dictionary) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = "FleetChevronGlyph"
	sprite.texture = _load_texture_cached(FLEET_MARKER_TEXTURE_PATH)
	sprite.position = Vector3(0.0, 0.2, 0.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = FLEET_MARKER_PIXEL_SIZE * (1.18 if GameState.selected_fleet_id == fleet.get("id", "") else 1.0)
	sprite.no_depth_test = true
	var tint: Color = _get_owner_color(fleet.get("ownerId", ""))
	tint.a = 0.96 if GameState.selected_fleet_id == fleet.get("id", "") else 0.78
	sprite.modulate = tint
	sprite.add_to_group("starmap_vfx_animated")
	sprite.set_meta("vfx_kind", "fleet_marker")
	sprite.set_meta("base_alpha", tint.a)
	sprite.set_meta("base_pixel_size", sprite.pixel_size)
	sprite.set_meta("phase", float(abs(str(fleet.get("id", "")).hash()) % 1000) / 120.0)
	return sprite

func _make_fleet_readiness_badge(fleet: Dictionary) -> Label3D:
	var badge := Label3D.new()
	badge.text = "待命" if int(fleet.get("movementCooldown", 0)) <= 0 else "冷却"
	badge.visible = str(fleet.get("ownerId", "")) == GameState.PLAYER_FACTION_ID or str(fleet.get("id", "")) == GameState.selected_fleet_id
	badge.position = Vector3(0.0, 0.88, 0.0)
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.pixel_size = 0.011
	badge.font_size = 30
	badge.outline_size = 4
	badge.modulate = Color("F8F7FF") if int(fleet.get("movementCooldown", 0)) <= 0 else Color("FFD6A5")
	return badge

func _make_system_resource_badges(system: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "ResourceBadges"
	var entries: Array = _top_resource_entries(system.get("resources", {}))
	var badge_index: int = 0
	for entry: Dictionary in entries:
		if badge_index >= MAX_RESOURCE_BADGES:
			break
		var resource_key: String = str(entry.get("key", ""))
		var resource_value: int = int(entry.get("value", 0))
		if resource_value <= 0:
			continue
		var badge := Label3D.new()
		badge.text = "%s%s" % [RESOURCE_BADGE_LABELS.get(resource_key, resource_key.substr(0, 1)), str(resource_value)]
		badge.position = Vector3(-0.56 + float(badge_index) * 0.56, -0.72, 0.0)
		badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge.pixel_size = 0.010
		badge.font_size = 26
		badge.outline_size = 4
		badge.modulate = RESOURCE_BADGE_COLORS.get(resource_key, Color("F8F7FF"))
		root.add_child(badge)
		badge_index += 1
	var habitability: int = int(system.get("habitability", 0))
	if habitability > 0 and system.get("ownerId", null) == null:
		var habitability_badge := Label3D.new()
		habitability_badge.text = "宜%s" % str(int(system.get("habitability", 0)))
		habitability_badge.position = Vector3(0.0, -1.12, 0.0)
		habitability_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		habitability_badge.pixel_size = 0.010
		habitability_badge.font_size = 24
		habitability_badge.outline_size = 4
		habitability_badge.modulate = Color("D7E9FF") if habitability >= 70 else Color("AAB4C8")
		root.add_child(habitability_badge)
	return root

func _top_resource_entries(resources: Dictionary) -> Array:
	var entries: Array = []
	for resource_key: String in ["food", "minerals", "industry", "energy"]:
		entries.append({"key": resource_key, "value": int(resources.get(resource_key, 0))})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("value", 0)) == int(b.get("value", 0)):
			return str(a.get("key", "")) < str(b.get("key", ""))
		return int(a.get("value", 0)) > int(b.get("value", 0))
	)
	return entries

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

func _load_texture_cached(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if _texture_cache.has(texture_path):
		return _texture_cache.get(texture_path)
	var texture_resource: Texture2D = ResourceLoader.load(texture_path) as Texture2D
	if texture_resource == null and texture_path.to_lower().ends_with(".png"):
		var png_path: String = ProjectSettings.globalize_path(texture_path) if texture_path.begins_with("res://") else texture_path
		texture_resource = _load_external_png_texture(png_path)
	_texture_cache[texture_path] = texture_resource
	return texture_resource

func _load_external_png_texture(texture_path: String) -> Texture2D:
	if not texture_path.to_lower().ends_with(".png") or not FileAccess.file_exists(texture_path):
		return null
	var image: Image = Image.load_from_file(texture_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _system_label_offset(compact: bool = false, channel: int = 0) -> Vector3:
	var channel_offset: Vector3 = SYSTEM_LABEL_CHANNELS[channel % SYSTEM_LABEL_CHANNELS.size()]
	return Vector3(0.0, 1.5 if compact else 2.1, 0.0) + channel_offset

func _fleet_label_offset(slot: int, channel: int = 0) -> Vector3:
	var row: int = slot / FLEET_LABEL_CHANNELS.size()
	var channel_offset: Vector3 = FLEET_LABEL_CHANNELS[channel % FLEET_LABEL_CHANNELS.size()]
	return Vector3(0.0, 2.42 + 0.56 * float(row), 0.0) + channel_offset

func _fleet_stack_offset(slot: int) -> Vector3:
	if slot < FLEET_STACK_OFFSETS.size():
		return FLEET_STACK_OFFSETS[slot]
	var ring: float = 0.72 + float(slot / FLEET_STACK_OFFSETS.size()) * 0.22
	var angle: float = float(slot) * 2.399963
	return Vector3(cos(angle) * ring, 0.0, sin(angle) * ring)

func _label_channel_for_id(source_id: String, channel_count: int) -> int:
	if channel_count <= 0:
		return 0
	var hash_value: int = 0
	for index: int in range(source_id.length()):
		hash_value += source_id.unicode_at(index) * (index + 1)
	return abs(hash_value) % channel_count

func _compact_label_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, max_length)

func _should_show_fleet_label(fleet: Dictionary) -> bool:
	return str(fleet.get("ownerId", "")) == GameState.PLAYER_FACTION_ID or str(fleet.get("id", "")) == GameState.selected_fleet_id

func _get_owner_color(owner_id: Variant) -> Color:
	if owner_id == null:
		return Color("9CA3AF")
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("id", "") == owner_id:
			return faction.get("color", Color.WHITE)
	return Color("6B7280")

func _system_display_color(system: Dictionary, reachable: bool) -> Color:
	if reachable:
		return Color("BFA5FF")
	if system.get("ownerId", null) != null:
		return _get_owner_color(system.get("ownerId", null))
	return _system_type_color(system)

func _system_type_color(system: Dictionary) -> Color:
	match str(system.get("type", "SOLAR")):
		"NEBULA":
			return Color("4ECDC4")
		"BINARY":
			return Color("F26A1B")
		"STORM":
			return Color("7DD3FC")
		"BLACK_HOLE":
			return Color("9CA3AF")
		_:
			return Color("D7E9FF")

func _system_texture_path(system: Dictionary) -> String:
	if system.get("ownerId", null) != null and system.get("visibilityLevel", "HIDDEN") != "HIDDEN":
		return _stable_system_texture_path(SYSTEM_COLONY_TEXTURE_PATHS, system)
	match str(system.get("type", "SOLAR")):
		"NEBULA":
			return SYSTEM_STAR_CLUSTER_TEXTURE_PATH
		"BINARY":
			return _stable_system_texture_path(SYSTEM_BINARY_TEXTURE_PATHS, system)
		"STORM":
			return _stable_system_texture_path(SYSTEM_STORM_TEXTURE_PATHS, system)
		"BLACK_HOLE":
			return _stable_system_texture_path(SYSTEM_BLACK_HOLE_TEXTURE_PATHS, system)
		_:
			return _stable_system_texture_path(SYSTEM_SOLAR_TEXTURE_PATHS, system)

func _stable_system_texture_path(paths: Array[String], system: Dictionary) -> String:
	if paths.is_empty():
		return SYSTEM_SOLAR_TEXTURE_PATH
	var hash_value: int = abs(str(system.get("id", "")).hash())
	return paths[hash_value % paths.size()]

func _animate_star_map_vfx() -> void:
	for node: Node in get_tree().get_nodes_in_group("starmap_vfx_animated"):
		if not is_instance_valid(node):
			continue
		var kind: String = str(node.get_meta("vfx_kind", ""))
		var phase: float = float(node.get_meta("phase", 0.0))
		var wave: float = sin(_vfx_time * TAU * 0.35 + phase)
		match kind:
			"nebula_backdrop":
				_animate_nebula_backdrop(node, wave)
			"lane_flow":
				_animate_lane_flow(node, wave)
			"system_node":
				_animate_system_node(node, wave)
			"system_overlay":
				_animate_system_overlay(node, wave)
			"fleet_marker":
				_animate_fleet_marker(node, wave)
			"selection_reticle":
				_animate_selection_reticle(node, wave)

func _animate_nebula_backdrop(node: Node, wave: float) -> void:
	if not node is MeshInstance3D:
		return
	var mesh_instance: MeshInstance3D = node
	if not mesh_instance.material_override is StandardMaterial3D:
		return
	var material: StandardMaterial3D = mesh_instance.material_override
	var base_alpha: float = float(node.get_meta("base_alpha", NEBULA_BACKDROP_ALPHA))
	var color: Color = material.albedo_color
	color.a = clamp(base_alpha + wave * VFX_NEBULA_ALPHA_PULSE, 0.34, 0.48)
	material.albedo_color = color
	material.uv1_offset.x = fmod(_vfx_time * VFX_NEBULA_DRIFT_SPEED, 1.0)
	material.uv1_offset.y = fmod(_vfx_time * VFX_NEBULA_DRIFT_SPEED * 0.42, 1.0)

func _animate_lane_flow(node: Node, wave: float) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance == null:
		return
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null:
		return
	var base_alpha: float = float(mesh_instance.get_meta("base_alpha", 0.16))
	var base_emission: float = float(mesh_instance.get_meta("base_emission", 0.1))
	var flow_speed: float = float(mesh_instance.get_meta("flow_speed", VFX_LANE_FLOW_SPEED))
	var color: Color = material.albedo_color
	color.a = clamp(base_alpha + wave * VFX_LANE_ALPHA_PULSE, 0.04, 0.45)
	material.albedo_color = color
	material.emission = color
	material.emission_energy_multiplier = max(0.04, base_emission + wave * 0.035)
	material.uv1_offset.x = fmod(_vfx_time * flow_speed, 1.0)

func _animate_system_node(node: Node, wave: float) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var material := mesh_instance.material_override as StandardMaterial3D
		if material == null:
			return
		var base_alpha: float = float(mesh_instance.get_meta("base_alpha", material.albedo_color.a))
		var base_scale: Vector3 = mesh_instance.get_meta("base_scale", Vector3.ONE)
		var color: Color = material.albedo_color
		color.a = clamp(base_alpha + wave * 0.025, 0.08, 1.0)
		material.albedo_color = color
		material.emission = color
		mesh_instance.scale = base_scale * (1.0 + wave * VFX_SYSTEM_PULSE_AMOUNT)
	elif node is Sprite3D:
		var sprite := node as Sprite3D
		var base_alpha: float = float(sprite.get_meta("base_alpha", sprite.modulate.a))
		var base_pixel_size: float = float(sprite.get_meta("base_pixel_size", sprite.pixel_size))
		var color: Color = sprite.modulate
		color.a = clamp(base_alpha + wave * 0.025, 0.08, 1.0)
		sprite.modulate = color
		sprite.pixel_size = base_pixel_size * (1.0 + wave * VFX_SYSTEM_PULSE_AMOUNT)

func _animate_system_overlay(node: Node, wave: float) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance == null:
		return
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null:
		return
	var base_alpha: float = float(mesh_instance.get_meta("base_alpha", material.albedo_color.a))
	var color: Color = material.albedo_color
	color.a = clamp(base_alpha + wave * 0.07, 0.08, 0.86)
	material.albedo_color = color
	material.emission = color
	var rotation_speed: float = float(mesh_instance.get_meta("rotation_speed", 0.0))
	if rotation_speed > 0.0:
		mesh_instance.rotation.y = fmod(_vfx_time * rotation_speed, TAU)

func _animate_fleet_marker(node: Node, wave: float) -> void:
	var sprite := node as Sprite3D
	if sprite == null:
		return
	var base_alpha: float = float(sprite.get_meta("base_alpha", sprite.modulate.a))
	var base_pixel_size: float = float(sprite.get_meta("base_pixel_size", sprite.pixel_size))
	var color: Color = sprite.modulate
	color.a = clamp(base_alpha + wave * 0.075, 0.35, 1.0)
	sprite.modulate = color
	sprite.pixel_size = base_pixel_size * (1.0 + wave * VFX_FLEET_PULSE_AMOUNT)

func _animate_selection_reticle(node: Node, wave: float) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance == null:
		return
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null:
		return
	var base_alpha: float = float(mesh_instance.get_meta("base_alpha", material.albedo_color.a))
	var color: Color = material.albedo_color
	color.a = clamp(base_alpha + wave * VFX_RETICLE_ALPHA_PULSE, 0.28, 1.0)
	material.albedo_color = color
	material.emission = color

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
