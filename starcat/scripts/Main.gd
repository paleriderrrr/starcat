extends Node

const GameLogic = preload("res://scripts/GameLogic.gd")
const InitialData = preload("res://scripts/data/InitialData.gd")
const MAIN_MENU_DIVIDER_PATH: String = "res://assets/ui/menu/main_menu_divider.png"
const PANEL_STRONG_TEXTURE_PATH: String = "res://assets/ui/bridge/panel_shell_strong.png"
const PANEL_TEXTURE_PATH: String = "res://assets/ui/bridge/panel_shell.png"
const INPUT_TEXTURE_PATH: String = "res://assets/ui/bridge/input_panel.png"
const INPUT_FOCUS_TEXTURE_PATH: String = "res://assets/ui/bridge/input_panel_focus.png"
const BUTTON_TEXTURE_PATHS: Dictionary = {
	"normal": "res://assets/ui/bridge/button_base.png",
	"hover": "res://assets/ui/bridge/button_hover.png",
	"pressed": "res://assets/ui/bridge/button_pressed.png",
	"focus": "res://assets/ui/bridge/button_hover.png"
}

@onready var star_map: Node = $StarMap
@onready var hud_layer: CanvasLayer = $HudLayer
@onready var main_menu_layer: CanvasLayer = $MainMenuLayer
@onready var menu_panel: PanelContainer = $MainMenuLayer/Root/Panel
@onready var menu_margin: MarginContainer = $MainMenuLayer/Root/Panel/Margin
@onready var menu_title: Label = $MainMenuLayer/Root/Panel/Margin/Layout/Title
@onready var menu_subtitle: Label = $MainMenuLayer/Root/Panel/Margin/Layout/Subtitle
@onready var menu_divider: TextureRect = $MainMenuLayer/Root/Panel/Margin/Layout/Divider
@onready var menu_content: HBoxContainer = $MainMenuLayer/Root/Panel/Margin/Layout/Content
@onready var controls_column: VBoxContainer = $MainMenuLayer/Root/Panel/Margin/Layout/Content/ControlsColumn
@onready var civilization_option: OptionButton = $MainMenuLayer/Root/Panel/Margin/Layout/Content/ControlsColumn/Controls/CivilizationRow/CivilizationOption
@onready var map_scale_option: OptionButton = $MainMenuLayer/Root/Panel/Margin/Layout/Content/ControlsColumn/Controls/MapScaleRow/MapScaleOption
@onready var difficulty_option: OptionButton = $MainMenuLayer/Root/Panel/Margin/Layout/Content/ControlsColumn/Controls/DifficultyRow/DifficultyOption
@onready var opponent_count_option: OptionButton = $MainMenuLayer/Root/Panel/Margin/Layout/Content/ControlsColumn/Controls/OpponentRow/OpponentCountOption
@onready var start_button: Button = $MainMenuLayer/Root/Panel/Margin/Layout/Content/ControlsColumn/StartButton
@onready var preview_panel: PanelContainer = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel
@onready var portrait_frame: PanelContainer = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel/PreviewMargin/PreviewLayout/PortraitFrame
@onready var civilization_portrait: TextureRect = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel/PreviewMargin/PreviewLayout/PortraitFrame/PortraitMargin/CivilizationPortrait
@onready var leader_value: Label = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel/PreviewMargin/PreviewLayout/LeaderValue
@onready var focus_value: Label = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel/PreviewMargin/PreviewLayout/FocusValue
@onready var trait_value: Label = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel/PreviewMargin/PreviewLayout/TraitValue
@onready var setup_summary: Label = $MainMenuLayer/Root/Panel/Margin/Layout/Content/PreviewPanel/PreviewMargin/PreviewLayout/SetupSummary

var _menu_texture_cache: Dictionary = {}

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.tab_changed.connect(_on_tab_changed)
	_populate_main_menu_options()
	_apply_main_menu_textures()
	civilization_option.item_selected.connect(_on_setup_option_selected)
	map_scale_option.item_selected.connect(_on_map_scale_selected)
	difficulty_option.item_selected.connect(_on_setup_option_selected)
	opponent_count_option.item_selected.connect(_on_setup_option_selected)
	_update_main_menu_preview()
	_set_game_layers_visible(false)
	get_viewport().size_changed.connect(_update_main_menu_layout)
	start_button.shortcut = _make_key_shortcut(KEY_ENTER)
	start_button.shortcut_in_tooltip = false
	start_button.pressed.connect(_on_start_button_pressed)
	_update_main_menu_layout()
	civilization_option.call_deferred("grab_focus")
	_on_state_changed(GameState.game_state)
	_on_selection_changed(GameState.selected_system_id, GameState.selected_fleet_id)
	_on_tab_changed(GameState.active_tab)
	if OS.get_cmdline_user_args().has("--capture-runtime"):
		call_deferred("_capture_runtime_views")

func _populate_main_menu_options() -> void:
	civilization_option.clear()
	for template: Dictionary in InitialData.civilization_pool():
		var item_index: int = civilization_option.item_count
		civilization_option.add_item(str(template.get("name", "未知文明")))
		civilization_option.set_item_metadata(item_index, str(template.get("template_id", "")))
	map_scale_option.clear()
	var map_scales: Dictionary = InitialData.map_scale_presets()
	for scale_id: String in ["SKIRMISH", "STANDARD", "GRAND"]:
		var scale_index: int = map_scale_option.item_count
		map_scale_option.add_item(str(map_scales.get(scale_id, {}).get("label", scale_id)))
		map_scale_option.set_item_metadata(scale_index, scale_id)
	map_scale_option.select(1)
	difficulty_option.clear()
	var difficulties: Dictionary = InitialData.difficulty_presets()
	for difficulty_id: String in ["CASUAL", "STANDARD", "HARD"]:
		var difficulty_index: int = difficulty_option.item_count
		difficulty_option.add_item(str(difficulties.get(difficulty_id, {}).get("label", difficulty_id)))
		difficulty_option.set_item_metadata(difficulty_index, difficulty_id)
	difficulty_option.select(1)
	_refresh_opponent_options_for_scale()

func _apply_main_menu_textures() -> void:
	menu_divider.texture = _load_menu_texture(MAIN_MENU_DIVIDER_PATH)
	menu_divider.modulate = Color(1.0, 1.0, 1.0, 0.9)
	menu_panel.add_theme_stylebox_override("panel", _make_bridge_panel_style(PANEL_STRONG_TEXTURE_PATH, 36.0, Vector4(2, 2, 2, 2)))
	preview_panel.add_theme_stylebox_override("panel", _make_bridge_panel_style(PANEL_TEXTURE_PATH, 24.0, Vector4(18, 12, 18, 12)))
	portrait_frame.add_theme_stylebox_override("panel", _make_bridge_panel_style(PANEL_TEXTURE_PATH, 24.0, Vector4(12, 10, 12, 10)))
	var option_style: StyleBoxTexture = _make_bridge_panel_style(INPUT_TEXTURE_PATH, 28.0, Vector4(16, 8, 16, 8))
	var option_hover_style: StyleBoxTexture = _make_bridge_panel_style(INPUT_FOCUS_TEXTURE_PATH, 28.0, Vector4(16, 8, 16, 8))
	for option_button: OptionButton in [civilization_option, map_scale_option, difficulty_option, opponent_count_option]:
		option_button.add_theme_stylebox_override("normal", option_style)
		option_button.add_theme_stylebox_override("hover", option_hover_style)
		option_button.add_theme_stylebox_override("pressed", option_hover_style)
		option_button.add_theme_stylebox_override("focus", option_hover_style)
		option_button.add_theme_color_override("font_color", Color(0.88, 0.96, 0.98, 1.0))
		option_button.add_theme_color_override("font_hover_color", Color(0.95, 0.36, 0.08, 1.0))
		option_button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))
	start_button.add_theme_stylebox_override("normal", _make_bridge_button_style("normal"))
	start_button.add_theme_stylebox_override("hover", _make_bridge_button_style("hover"))
	start_button.add_theme_stylebox_override("pressed", _make_bridge_button_style("pressed"))
	start_button.add_theme_stylebox_override("focus", _make_bridge_button_style("focus"))
	start_button.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94, 1.0))
	start_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	start_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.94, 1.0))


func _update_main_menu_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 700.0
	var panel_width: float = clampf(viewport_size.x - 48.0, 760.0, 980.0)
	var panel_height: float = clampf(viewport_size.y - 48.0, 540.0, 620.0)
	if compact:
		panel_width = clampf(viewport_size.x - 32.0, 620.0, 760.0)
		panel_height = clampf(viewport_size.y - 32.0, 500.0, 600.0)
	menu_panel.custom_minimum_size = Vector2(panel_width, 0)
	menu_panel.offset_left = -panel_width * 0.5
	menu_panel.offset_right = panel_width * 0.5
	menu_panel.offset_top = -panel_height * 0.5
	menu_panel.offset_bottom = panel_height * 0.5
	menu_margin.add_theme_constant_override("margin_left", 28 if compact else 42)
	menu_margin.add_theme_constant_override("margin_right", 28 if compact else 42)
	menu_margin.add_theme_constant_override("margin_top", 28 if compact else 40)
	menu_margin.add_theme_constant_override("margin_bottom", 28 if compact else 40)
	menu_content.add_theme_constant_override("separation", 16 if compact else 26)
	controls_column.custom_minimum_size = Vector2(340, 0) if compact else Vector2(420, 0)
	preview_panel.visible = not compact
	menu_title.add_theme_font_size_override("font_size", 32 if compact else 38)
	menu_subtitle.add_theme_font_size_override("font_size", 14 if compact else 15)


func _make_key_shortcut(keycode: Key) -> Shortcut:
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()
	event.keycode = keycode
	shortcut.events = [event]
	return shortcut


func _make_bridge_panel_style(texture_path: String, texture_margin: float, content_margin: Vector4) -> StyleBoxTexture:
	var style_box := StyleBoxTexture.new()
	style_box.texture = _load_menu_texture(texture_path)
	style_box.texture_margin_left = texture_margin
	style_box.texture_margin_top = texture_margin
	style_box.texture_margin_right = texture_margin
	style_box.texture_margin_bottom = texture_margin
	style_box.content_margin_left = content_margin.x
	style_box.content_margin_top = content_margin.y
	style_box.content_margin_right = content_margin.z
	style_box.content_margin_bottom = content_margin.w
	return style_box

func _make_bridge_button_style(state: String = "normal") -> StyleBoxTexture:
	var texture_path: String = str(BUTTON_TEXTURE_PATHS.get(state, BUTTON_TEXTURE_PATHS.get("normal", "")))
	return _make_bridge_panel_style(texture_path, 12.0, Vector4(18, 10, 18, 10))


func _refresh_opponent_options_for_scale() -> void:
	var previous_count: int = 3
	if opponent_count_option.item_count > 0:
		previous_count = int(opponent_count_option.get_selected_metadata())
	var scale_id: String = str(map_scale_option.get_selected_metadata())
	var scale_data: Dictionary = InitialData.map_scale_presets().get(scale_id, InitialData.map_scale_presets().get("STANDARD", {}))
	var max_count: int = int(scale_data.get("max_opponents", 3))
	opponent_count_option.clear()
	for count: int in range(1, max_count + 1):
		opponent_count_option.add_item("%s 个 AI 文明" % count)
		opponent_count_option.set_item_metadata(opponent_count_option.item_count - 1, count)
	opponent_count_option.select(clampi(previous_count, 1, max_count) - 1)
	_update_main_menu_preview()

func _on_setup_option_selected(_index: int) -> void:
	AudioManager.play_event("ui_tick")
	_update_main_menu_preview()


func _on_map_scale_selected(_index: int) -> void:
	AudioManager.play_event("ui_tick")
	_refresh_opponent_options_for_scale()

func _update_main_menu_preview() -> void:
	if civilization_option.item_count == 0 or map_scale_option.item_count == 0 or difficulty_option.item_count == 0 or opponent_count_option.item_count == 0:
		return
	var template_id: String = str(civilization_option.get_selected_metadata())
	var selected_template: Dictionary = _selected_civilization_template(template_id)
	var visual_bundle: Dictionary = InitialData.civilization_visual_bundle(str(selected_template.get("visualId", "")))
	civilization_portrait.texture = _load_menu_texture(str(visual_bundle.get("portraitPath", "")))
	leader_value.text = "领袖: %s / %s" % [selected_template.get("leaderName", "-"), selected_template.get("name", "-")]
	focus_value.text = "路线: %s / %s胜利" % [_civilization_type_label(str(selected_template.get("type", ""))), _victory_focus_label(str(selected_template.get("victoryFocus", "")))]
	trait_value.text = "特质: %s" % "、".join(_top_personality_traits(selected_template.get("personality", {})))
	var scale_id: String = str(map_scale_option.get_selected_metadata())
	var difficulty_id: String = str(difficulty_option.get_selected_metadata())
	var scale_data: Dictionary = InitialData.map_scale_presets().get(scale_id, {})
	var difficulty_data: Dictionary = InitialData.difficulty_presets().get(difficulty_id, {})
	setup_summary.text = "%s: %s星系 / %s航道\n%s: AI x%s / 扩张 x%s\n对手: %s" % [
		scale_data.get("label", scale_id),
		str(scale_data.get("system_count", "?")),
		str(scale_data.get("hyperlane_count", "?")),
		difficulty_data.get("label", difficulty_id),
		str(difficulty_data.get("ai_resource_multiplier", 1.0)),
		str(difficulty_data.get("ai_expansion_pressure", 1.0)),
		str(opponent_count_option.get_selected_metadata()),
	]

func _selected_civilization_template(template_id: String) -> Dictionary:
	for template: Dictionary in InitialData.civilization_pool():
		if str(template.get("template_id", "")) == template_id:
			return template
	return InitialData.civilization_pool()[0]

func _top_personality_traits(personality: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	var entries: Array = [
		{"label": "进攻", "value": float(personality.get("aggression", 0.0))},
		{"label": "警觉", "value": float(personality.get("paranoia", 0.0))},
		{"label": "贸易", "value": float(personality.get("greed", 0.0))},
		{"label": "守约", "value": float(personality.get("loyalty", 0.0))},
		{"label": "理性", "value": float(personality.get("rationality", 0.0))},
	]
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("value", 0.0)) > float(b.get("value", 0.0)))
	for entry: Dictionary in entries.slice(0, 3):
		labels.append("%s %.0f" % [entry.get("label", ""), float(entry.get("value", 0.0))])
	return labels

func _victory_focus_label(value: String) -> String:
	match value:
		"SCIENCE":
			return "科技"
		"DIPLOMACY":
			return "外交"
		"DOMINATION":
			return "军事"
		"ECONOMY":
			return "经济"
		_:
			return "均衡"

func _civilization_type_label(value: String) -> String:
	return value.replace("_", " ").capitalize()

func _load_menu_texture(texture_path: String) -> Texture2D:
	if _menu_texture_cache.has(texture_path):
		return _menu_texture_cache.get(texture_path)
	var texture: Texture2D = ResourceLoader.load(texture_path) as Texture2D
	if texture == null and texture_path.begins_with("res://") and texture_path.to_lower().ends_with(".png"):
		var absolute_path: String = ProjectSettings.globalize_path(texture_path)
		if FileAccess.file_exists(absolute_path):
			var image: Image = Image.load_from_file(absolute_path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
	_menu_texture_cache[texture_path] = texture
	return texture

func _on_start_button_pressed() -> void:
	AudioManager.play_event("ui_confirm")
	var options: Dictionary = {
		"player_template_id": str(civilization_option.get_selected_metadata()),
		"map_scale": str(map_scale_option.get_selected_metadata()),
		"difficulty": str(difficulty_option.get_selected_metadata()),
		"opponent_count": int(opponent_count_option.get_selected_metadata())
	}
	GameState.start_new_game(options)
	main_menu_layer.visible = false
	_set_game_layers_visible(true)

func _set_game_layers_visible(visible: bool) -> void:
	star_map.visible = visible
	hud_layer.visible = visible

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
	await _save_capture("runtime_main_menu.png")
	_on_start_button_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_game_overview.png")
	if hud_layer.has_method("_on_tab_pressed"):
		hud_layer.call("_on_tab_pressed", "OBJECTIVES")
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_objectives.png")
	if hud_layer.has_method("_close_center_modal"):
		hud_layer.call("_close_center_modal")
	if hud_layer.has_method("_on_tab_pressed"):
		hud_layer.call("_on_tab_pressed", "TECH")
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_tech.png")
	if hud_layer.has_method("_close_center_modal"):
		hud_layer.call("_close_center_modal")
	if hud_layer.has_method("_on_tab_pressed"):
		hud_layer.call("_on_tab_pressed", "DIPLOMACY")
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_diplomacy.png")
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogic.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var active_treaties: Array = GameLogic.active_treaties_between(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var history: Array = GameState.get_relation_history(faction.get("id", ""))
		if hud_layer.has_method("_open_faction_modal"):
			hud_layer.call("_open_faction_modal", faction, relation, active_treaties, history)
		break
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture("runtime_diplomacy_detail.png")
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
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	var capture_dir: String = ProjectSettings.globalize_path("res://../runtime_captures")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var image: Image
	if DisplayServer.get_name() == "headless":
		image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.02, 0.04, 0.08, 1.0))
	else:
		image = get_viewport().get_texture().get_image()
	image.save_png("%s/%s" % [capture_dir, file_name])
