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
