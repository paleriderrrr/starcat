extends SceneTree

const GameLogicScript = preload("res://scripts/GameLogic.gd")

var _errors: Array[String] = []
var _main: Node
var _game_state: Node


func _initialize() -> void:
	_game_state = root.get_node("GameState")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)
	await process_frame
	await process_frame
	_main.call("_on_start_button_pressed")
	await process_frame
	await process_frame

	_game_state.call("select_fleet", "fleet_player_1")
	await process_frame
	await process_frame
	var fleet_buttons_before: Array[String] = _visible_button_texts()
	_expect(_has_text(fleet_buttons_before, "移动"), "fleet command panel exposes move mode")
	_expect(_has_text(fleet_buttons_before, "侦察"), "fleet route panel exposes scouting from selected fleet")
	_expect(_has_text(fleet_buttons_before, "跃迁至此"), "fleet route panel exposes direct jump action")

	_game_state.call("move_selected_fleet", "sys_polaris")
	await process_frame
	await process_frame
	var state: Dictionary = _game_state.get("game_state")
	state = GameLogicScript.start_research(state, "tech_deep_colonization")
	for _index: int in range(2):
		state = GameLogicScript.process_turn(state)
	_game_state.set("game_state", state)
	_game_state.emit_signal("state_changed", state)
	_game_state.call("select_fleet", "fleet_player_1")
	await process_frame
	await process_frame
	var fleet_buttons_after: Array[String] = _visible_button_texts()
	_expect(_has_text(fleet_buttons_after, "标准殖民"), "fleet panel exposes current-system colonization")

	var before_message_count: int = int(_game_state.get("game_state").get("messages", []).size())
	_game_state.call("begin_fleet_move_mode", "fleet_player_1")
	await process_frame
	await process_frame
	_expect(bool(_game_state.get("fleet_move_mode")), "fleet move mode can be entered before colonization")
	_game_state.call("colonize_system", "sys_polaris", "STANDARD")
	await process_frame
	await process_frame
	var target_system: Dictionary = _game_state.call("get_system_by_id", "sys_polaris")
	_expect(str(target_system.get("ownerId", "")) == "f_player", "colonization is executable through selected fleet context")
	_expect(int(_game_state.get("game_state").get("messages", []).size()) > before_message_count, "colonization emits player-facing feedback")
	_expect(not bool(_game_state.get("fleet_move_mode")), "colonization exits fleet move mode")
	var colonizing_fleet: Dictionary = _game_state.call("get_fleet_by_id", "fleet_player_1")
	_expect(str(colonizing_fleet.get("mission", "")) == "COLONIZING", "colonization locks fleet into deployment mission")
	_expect(str(_game_state.get("selected_fleet_id")) == "fleet_player_1", "colonizing fleet remains selected for status tracking")
	_game_state.call("begin_fleet_move_mode", "fleet_player_1")
	await process_frame
	await process_frame
	_expect(not bool(_game_state.get("fleet_move_mode")), "colonizing fleet cannot re-enter move mode")
	var move_button: Button = _visible_button_by_text("移动")
	_expect(move_button != null and move_button.disabled, "colonizing fleet move button is disabled")
	var jump_button: Button = _visible_button_by_text("跃迁至此")
	_expect(jump_button != null and jump_button.disabled, "colonizing fleet route jump buttons are disabled")

	_game_state.call("advance_turn")
	await process_frame
	await process_frame
	_game_state.call("select_fleet", "fleet_player_1")
	await process_frame
	await process_frame
	colonizing_fleet = _game_state.call("get_fleet_by_id", "fleet_player_1")
	var colonizing_system_id: String = str(colonizing_fleet.get("systemId", ""))
	_expect(str(colonizing_fleet.get("mission", "")) == "COLONIZING", "colonization deployment persists across interim turns")
	_expect(int(colonizing_fleet.get("movementCooldown", 0)) <= 0, "colonization regression check reaches post-cooldown state")
	var blocked_message_count: int = int(_game_state.get("game_state").get("messages", []).size())
	_game_state.call("move_selected_fleet", "sys_cat_home")
	await process_frame
	await process_frame
	var blocked_fleet: Dictionary = _game_state.call("get_fleet_by_id", "fleet_player_1")
	_expect(str(blocked_fleet.get("systemId", "")) == colonizing_system_id, "colonizing fleet cannot move before deployment completes")
	_expect(int(_game_state.get("game_state").get("messages", []).size()) > blocked_message_count, "blocked colonizing move emits player-facing feedback")
	_game_state.call("set_selected_fleet_mission", "IDLE")
	await process_frame
	await process_frame
	blocked_fleet = _game_state.call("get_fleet_by_id", "fleet_player_1")
	_expect(str(blocked_fleet.get("mission", "")) == "COLONIZING", "colonizing fleet cannot be reassigned before deployment completes")

	var target_faction: Dictionary = _first_non_player_faction()
	if not target_faction.is_empty():
		var hud_layer: Node = _main.get_node("HudLayer")
		var relation: Dictionary = GameLogicScript.relation_breakdown(_game_state.get("game_state"), "f_player", target_faction.get("id", ""))
		var treaties: Array = GameLogicScript.active_treaties_between(_game_state.get("game_state"), "f_player", target_faction.get("id", ""))
		var history: Array = _game_state.call("get_relation_history", target_faction.get("id", ""))
		hud_layer.call("_open_faction_modal", target_faction, relation, treaties, history)
		await process_frame
		await process_frame
		var draft_box: TextEdit = _visible_text_edit()
		var send_button: Button = _visible_button_by_text("发送照会")
		var preset_button: Button = _visible_button_by_text("友好试探")
		_expect(draft_box != null and send_button != null and preset_button != null, "diplomacy composer exposes preset, editor and send button")
		if draft_box != null and send_button != null and preset_button != null:
			preset_button.pressed.emit()
			await process_frame
			await process_frame
			_expect(draft_box.text.strip_edges() != "" and not send_button.disabled, "diplomacy preset enables sending")
			send_button.pressed.emit()
			await process_frame
			await process_frame
			_expect(draft_box.text.strip_edges() == "", "sent diplomacy draft is cleared in the active editor")
			_expect(send_button.disabled, "sent diplomacy button is disabled after draft clears")

	if _errors.is_empty():
		print("STARCAT_INTERACTION_FLOW_OK buttons_before=%s buttons_after=%s" % [str(fleet_buttons_before.size()), str(fleet_buttons_after.size())])
		_cleanup()
		quit(0)
	else:
		for error: String in _errors:
			push_error(error)
		_cleanup()
		quit(1)


func _visible_button_texts() -> Array[String]:
	var result: Array[String] = []
	_collect_button_texts(root, result)
	return result


func _collect_button_texts(node: Node, result: Array[String]) -> void:
	if node is Button:
		var button: Button = node
		if button.is_visible_in_tree():
			result.append(button.text)
	for child: Node in node.get_children():
		_collect_button_texts(child, result)


func _has_text(values: Array[String], expected: String) -> bool:
	for value: String in values:
		if value == expected or value.contains(expected):
			return true
	return false


func _visible_button_by_text(expected: String) -> Button:
	return _find_visible_button_by_text(root, expected)


func _find_visible_button_by_text(node: Node, expected: String) -> Button:
	if node is Button:
		var button: Button = node
		if button.is_visible_in_tree() and (button.text == expected or button.text.contains(expected)):
			return button
	for child: Node in node.get_children():
		var found: Button = _find_visible_button_by_text(child, expected)
		if found != null:
			return found
	return null


func _visible_text_edit() -> TextEdit:
	return _find_visible_text_edit(root)


func _find_visible_text_edit(node: Node) -> TextEdit:
	if node is TextEdit:
		var editor: TextEdit = node
		if editor.is_visible_in_tree():
			return editor
	for child: Node in node.get_children():
		var found: TextEdit = _find_visible_text_edit(child)
		if found != null:
			return found
	return null


func _first_non_player_faction() -> Dictionary:
	for faction: Dictionary in _game_state.get("game_state").get("factions", []):
		if not bool(faction.get("isPlayer", false)):
			return faction
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _cleanup() -> void:
	if _main != null and is_instance_valid(_main):
		root.remove_child(_main)
		_main.free()
