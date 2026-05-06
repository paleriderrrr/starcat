extends Node

@onready var star_map: Node = $StarMap
@onready var hud_layer: CanvasLayer = $HudLayer

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.tab_changed.connect(_on_tab_changed)
	_on_state_changed(GameState.game_state)
	_on_selection_changed(GameState.selected_system_id, GameState.selected_fleet_id)
	_on_tab_changed(GameState.active_tab)
	if OS.get_cmdline_user_args().has("--capture-runtime"):
		call_deferred("_capture_runtime_views")

func _on_state_changed(_state: Dictionary) -> void:
	if star_map.has_method("refresh"):
		star_map.call_deferred("refresh")
	if hud_layer.has_method("refresh"):
		hud_layer.call_deferred("refresh")

func _on_selection_changed(_system_id: String, _fleet_id: String) -> void:
	if hud_layer.has_method("refresh"):
		hud_layer.call_deferred("refresh")

func _on_tab_changed(_tab_name: String) -> void:
	if hud_layer.has_method("refresh"):
		hud_layer.call_deferred("refresh")

func _capture_runtime_views() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if hud_layer.has_method("_on_tab_pressed"):
		hud_layer.call("_on_tab_pressed", "OBJECTIVES")
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_objectives.png")
	if hud_layer.has_method("_close_center_modal"):
		hud_layer.call("_close_center_modal")
	GameState.select_fleet("fleet_player_1")
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_fleet.png")
	GameState.clear_selection()
	if hud_layer.has_method("_on_tab_pressed"):
		hud_layer.call("_on_tab_pressed", "COMMS")
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_comms.png")
	get_tree().quit()

func _save_capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png("user://captures/%s" % file_name)
