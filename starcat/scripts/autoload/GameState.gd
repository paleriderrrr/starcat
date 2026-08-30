extends Node

const GameLogicScript = preload("res://scripts/GameLogic.gd")
const InitialDataScript = preload("res://scripts/data/InitialData.gd")
const DecisionIterationServiceScript = preload("res://scripts/services/DecisionIterationService.gd")

signal state_changed(state: Dictionary)
signal selection_changed(system_id: String, fleet_id: String)
signal labels_visibility_changed(visible: bool)
signal tab_changed(tab_name: String)
signal service_status_changed(status: String)
signal advisor_changed(ai_advice: String, world_data: Dictionary, diplomatic_message: Dictionary)
signal diplomacy_changed()
signal decision_iteration_recorded(result: Dictionary)

const PLAYER_FACTION_ID: String = "f_player"
const MERCHANT_FACTION_ID: String = "f_merchant"
const DECISION_ITERATION_JSONL_PATH: String = "user://decision_iterations/records.jsonl"
const DECISION_ITERATION_PLAYBOOK_ID: String = "merchant_turn_v1"

var labels_visible: bool = true
var active_tab: String = "OBJECTIVES"
var selected_system_id: String = ""
var selected_fleet_id: String = ""
var fleet_move_mode: bool = false

var service_status: String = "checking"
var ai_advice: String = ""
var world_data: Dictionary = {}
var diplomatic_message: Dictionary = {}
var diplomatic_drafts: Dictionary = {}
var diplomatic_visibility_prefs: Dictionary = {}
var turn_busy: bool = false
var _pending_conversation_target_id: String = ""
var _pending_conversation_visibility: String = "PUBLIC"
var _decision_iteration_service: DecisionIterationService = DecisionIterationServiceScript.new()
var _pending_turn_snapshot: Dictionary = {}
var _decision_iteration_game_id: String = ""

var game_state: Dictionary = InitialDataScript.create_initial_state()

func _ready() -> void:
	_decision_iteration_game_id = _new_decision_iteration_game_id()
	if has_node("/root/ApiClient"):
		ApiClient.service_health_checked.connect(_on_service_health_checked)
		ApiClient.world_query_received.connect(_on_world_query_received)
		ApiClient.ai_decision_received.connect(_on_ai_decision_received)
		ApiClient.merchant_decision_received.connect(_on_merchant_decision_received)
		ApiClient.diplomatic_message_received.connect(_on_diplomatic_message_received)
		ApiClient.conversation_received.connect(_on_conversation_received)
		ApiClient.request_failed.connect(_on_api_failed)
		ApiClient.check_service_health()
	_emit_all()

func _emit_all() -> void:
	state_changed.emit(game_state)
	selection_changed.emit(selected_system_id, selected_fleet_id)
	labels_visibility_changed.emit(labels_visible)
	tab_changed.emit(active_tab)
	service_status_changed.emit(service_status)
	advisor_changed.emit(ai_advice, world_data, diplomatic_message)
	diplomacy_changed.emit()

func reset_state() -> void:
	game_state = InitialDataScript.create_initial_state()
	_clear_selected_fleet()
	ai_advice = ""
	world_data = {}
	diplomatic_message = {}
	diplomatic_drafts = {}
	diplomatic_visibility_prefs = {}
	turn_busy = false
	_pending_conversation_target_id = ""
	_pending_conversation_visibility = "PUBLIC"
	_pending_turn_snapshot = {}
	_decision_iteration_game_id = _new_decision_iteration_game_id()
	_emit_all()

func start_new_game(options: Dictionary) -> void:
	var normalized_options: Dictionary = InitialDataScript.normalize_game_setup_options(options)
	game_state = InitialDataScript.create_initial_state(normalized_options)
	_clear_selected_fleet()
	selected_system_id = ""
	active_tab = "OBJECTIVES"
	ai_advice = ""
	world_data = {}
	diplomatic_message = {}
	diplomatic_drafts = {}
	diplomatic_visibility_prefs = {}
	turn_busy = false
	_pending_conversation_target_id = ""
	_pending_conversation_visibility = "PUBLIC"
	_pending_turn_snapshot = {}
	_decision_iteration_game_id = _new_decision_iteration_game_id()
	_emit_all()

func get_player_faction() -> Dictionary:
	return GameLogicScript.player_faction(game_state)

func get_system_by_id(system_id: String) -> Dictionary:
	for system: Dictionary in game_state.get("starSystems", []):
		if system.get("id", "") == system_id:
			return system
	return {}

func get_fleet_by_id(fleet_id: String) -> Dictionary:
	for fleet: Dictionary in game_state.get("fleets", []):
		if fleet.get("id", "") == fleet_id:
			return fleet
	return {}

func get_owner_name(owner_id: Variant) -> String:
	if owner_id == null:
		return "无归属"
	for faction: Dictionary in game_state.get("factions", []):
		if faction.get("id", "") == owner_id:
			return faction.get("name", "未知势力")
	return "未知势力"

func get_enemy_fleet_for_selected_context() -> Dictionary:
	if selected_fleet_id == "":
		return {}
	var selected_fleet: Dictionary = get_fleet_by_id(selected_fleet_id)
	if selected_fleet.is_empty():
		return {}
	var system_id: String = selected_system_id if selected_system_id != "" else selected_fleet.get("systemId", "")
	for fleet: Dictionary in game_state.get("fleets", []):
		if fleet.get("ownerId", "") == PLAYER_FACTION_ID:
			continue
		if fleet.get("systemId", "") == system_id:
			return fleet
	return {}

func get_reachable_system_ids(fleet_id: String) -> Array:
	return GameLogicScript.reachable_systems(game_state, fleet_id)

func get_reachable_system_details(fleet_id: String) -> Array:
	return GameLogicScript.reachable_system_details(game_state, fleet_id)

func get_player_fleets() -> Array:
	var result: Array = []
	for fleet: Dictionary in game_state.get("fleets", []):
		if fleet.get("ownerId", "") == PLAYER_FACTION_ID:
			result.append(fleet)
	return result

func get_player_queue_items() -> Array:
	var result: Array = []
	for item: Dictionary in game_state.get("constructionQueue", []):
		if item.get("ownerId", "") == PLAYER_FACTION_ID:
			result.append(item)
	return result

func get_player_fleets_in_system(system_id: String) -> Array:
	return GameLogicScript.player_fleets_in_system(game_state, system_id, PLAYER_FACTION_ID)

func available_buildings() -> Array:
	return GameLogicScript.available_buildings(game_state)

func available_ship_types() -> Array:
	return GameLogicScript.available_ship_types(game_state)

func colonization_modes() -> Dictionary:
	return InitialDataScript.colonization_modes()

func colonization_preview(system_id: String, mode: String) -> Dictionary:
	if selected_fleet_id == "":
		return {"allowed": false, "reason": "需要先选中一支己方舰队。", "cost": InitialDataScript.colonization_modes().get(mode, {}).get("cost", {}), "turns": 0}
	return GameLogicScript.colonization_preview(game_state, selected_fleet_id, system_id, mode)

func get_faction_by_id(faction_id: String) -> Dictionary:
	for faction: Dictionary in game_state.get("factions", []):
		if faction.get("id", "") == faction_id:
			return faction
	return {}

func get_visible_diplomatic_messages() -> Array:
	return GameLogicScript.visible_diplomatic_messages_for_player(game_state)

func get_visible_diplomatic_memories() -> Array:
	return GameLogicScript.visible_diplomatic_memories_for_player(game_state)

func get_recent_interaction_memory() -> Array:
	return game_state.get("recentInteractionMemory", [])

func get_archived_interaction_memory() -> Array:
	return game_state.get("archivedInteractionMemory", [])

func get_pending_proposals() -> Array:
	return GameLogicScript.pending_proposals_for_player(game_state)

func get_active_narrative_events() -> Array:
	return GameLogicScript.active_narrative_events_for_player(game_state)

func get_active_interventions() -> Array:
	var result: Array = []
	for item: Dictionary in game_state.get("activeInterventions", []):
		if item.get("status", "ACTIVE") == "ACTIVE":
			result.append(item)
	return result

func get_recent_combat_reports() -> Array:
	return game_state.get("combatReports", [])

func get_relation_history(faction_id: String) -> Array:
	return GameLogicScript.relation_history_for_pair(game_state, PLAYER_FACTION_ID, faction_id)

func get_recent_intelligence_feed() -> Array:
	return GameLogicScript.recent_intelligence_feed(game_state, 10)

func get_strategic_posture_report() -> Dictionary:
	return GameLogicScript.strategic_posture_report(game_state, PLAYER_FACTION_ID)

func get_interception_report() -> Dictionary:
	return GameLogicScript.interception_report(game_state)

func get_diplomatic_victory_report() -> Dictionary:
	return GameLogicScript.player_diplomatic_victory_report(game_state)

func get_victory_progress_report() -> Dictionary:
	return GameLogicScript.player_victory_progress_report(game_state)

func get_diplomatic_intent_preview(faction_id: String) -> Dictionary:
	return GameLogicScript.describe_player_diplomatic_intent(get_diplomatic_draft(faction_id))

func get_diplomatic_draft(faction_id: String) -> String:
	return str(diplomatic_drafts.get(faction_id, ""))

func set_diplomatic_draft(faction_id: String, text: String) -> void:
	diplomatic_drafts[faction_id] = text

func get_diplomatic_visibility(faction_id: String) -> String:
	return str(diplomatic_visibility_prefs.get(faction_id, "PUBLIC"))

func set_diplomatic_visibility(faction_id: String, value: String) -> void:
	diplomatic_visibility_prefs[faction_id] = value

func get_resource_breakdown(resource_key: String) -> Dictionary:
	return GameLogicScript.faction_resource_breakdown(game_state, PLAYER_FACTION_ID, resource_key)

func select_system(system_id: String) -> void:
	if try_move_selected_fleet_to_system(system_id):
		return
	selected_system_id = system_id
	selected_fleet_id = ""
	fleet_move_mode = false
	selection_changed.emit(selected_system_id, selected_fleet_id)

func focus_system(system_id: String) -> void:
	selected_system_id = system_id
	selected_fleet_id = ""
	fleet_move_mode = false
	selection_changed.emit(selected_system_id, selected_fleet_id)

func select_fleet(fleet_id: String) -> void:
	var fleet: Dictionary = get_fleet_by_id(fleet_id)
	if fleet.is_empty():
		_clear_selected_fleet()
		selection_changed.emit(selected_system_id, selected_fleet_id)
		return
	fleet_move_mode = false
	selected_fleet_id = fleet_id
	selected_system_id = fleet.get("systemId", "")
	AudioManager.play_event("fleet_select")
	selection_changed.emit(selected_system_id, selected_fleet_id)

func clear_selection() -> void:
	_clear_selected_fleet()
	selection_changed.emit(selected_system_id, selected_fleet_id)

func _clear_selected_fleet() -> void:
	fleet_move_mode = false
	selected_system_id = ""
	selected_fleet_id = ""

func set_active_tab(tab_name: String) -> void:
	active_tab = tab_name
	tab_changed.emit(active_tab)

func toggle_labels() -> void:
	labels_visible = !labels_visible
	labels_visibility_changed.emit(labels_visible)

func start_research(tech_id: String) -> void:
	game_state = GameLogicScript.start_research(game_state, tech_id)
	state_changed.emit(game_state)

func cancel_research() -> void:
	game_state = GameLogicScript.cancel_research(game_state)
	state_changed.emit(game_state)

func queue_structure(system_id: String, building_type: String) -> void:
	game_state = GameLogicScript.queue_structure(game_state, system_id, building_type)
	state_changed.emit(game_state)

func queue_ship(system_id: String, ship_type: String) -> void:
	game_state = GameLogicScript.queue_ship_construction(game_state, system_id, ship_type)
	state_changed.emit(game_state)

func queue_ship_batch(system_id: String, ship_type: String, count: int) -> void:
	for _index: int in range(maxi(0, count)):
		game_state = GameLogicScript.queue_ship_construction(game_state, system_id, ship_type)
	state_changed.emit(game_state)

func repair_fleet(fleet_id: String) -> void:
	game_state = GameLogicScript.repair_fleet(game_state, fleet_id)
	state_changed.emit(game_state)

func begin_fleet_move_mode(fleet_id: String = "") -> void:
	if fleet_id != "":
		selected_fleet_id = fleet_id
		var fleet: Dictionary = get_fleet_by_id(fleet_id)
		if fleet.is_empty():
			_clear_selected_fleet()
			selection_changed.emit(selected_system_id, selected_fleet_id)
			return
		selected_system_id = str(fleet.get("systemId", ""))
		if str(fleet.get("mission", "IDLE")) == "COLONIZING":
			fleet_move_mode = false
			selection_changed.emit(selected_system_id, selected_fleet_id)
			return
	fleet_move_mode = selected_fleet_id != ""
	selection_changed.emit(selected_system_id, selected_fleet_id)

func cancel_fleet_move_mode() -> void:
	if not fleet_move_mode:
		return
	fleet_move_mode = false
	selection_changed.emit(selected_system_id, selected_fleet_id)

func try_move_selected_fleet_to_system(system_id: String) -> bool:
	if not fleet_move_mode or selected_fleet_id == "" or system_id == "":
		return false
	var selected_fleet: Dictionary = get_fleet_by_id(selected_fleet_id)
	if selected_fleet.is_empty():
		_clear_selected_fleet()
		selection_changed.emit(selected_system_id, selected_fleet_id)
		return false
	if str(selected_fleet.get("systemId", "")) == system_id:
		return false
	if not get_reachable_system_ids(selected_fleet_id).has(system_id):
		return false
	move_selected_fleet(system_id)
	return true

func set_selected_fleet_mission(mission: String) -> void:
	if selected_fleet_id == "":
		return
	game_state = GameLogicScript.set_fleet_mission(game_state, selected_fleet_id, mission)
	state_changed.emit(game_state)

func split_selected_fleet() -> void:
	if selected_fleet_id == "":
		return
	game_state = GameLogicScript.split_fleet(game_state, selected_fleet_id)
	state_changed.emit(game_state)

func merge_player_fleets_at_selected_system() -> void:
	var system_id: String = selected_system_id
	if system_id == "" and selected_fleet_id != "":
		system_id = str(get_fleet_by_id(selected_fleet_id).get("systemId", ""))
	if system_id == "":
		return
	game_state = GameLogicScript.merge_player_fleets(game_state, system_id)
	var selection_repaired: bool = _repair_selected_fleet_context(system_id)
	state_changed.emit(game_state)
	if selection_repaired:
		selection_changed.emit(selected_system_id, selected_fleet_id)

func trade_with_faction(target_faction_id: String) -> void:
	game_state = GameLogicScript.trade_with_faction(game_state, target_faction_id)
	state_changed.emit(game_state)

func threaten_faction(target_faction_id: String) -> void:
	game_state = GameLogicScript.threaten_faction(game_state, target_faction_id)
	state_changed.emit(game_state)

func propose_treaty(target_faction_id: String, treaty_type: String) -> void:
	game_state = GameLogicScript.propose_treaty(game_state, target_faction_id, treaty_type)
	state_changed.emit(game_state)

func revoke_treaty(target_faction_id: String, treaty_type: String) -> void:
	game_state = GameLogicScript.revoke_treaty(game_state, target_faction_id, treaty_type)
	state_changed.emit(game_state)

func declare_war(target_faction_id: String) -> void:
	game_state = GameLogicScript.declare_war_on_faction(game_state, PLAYER_FACTION_ID, target_faction_id)
	state_changed.emit(game_state)

func send_ultimatum(target_faction_id: String) -> void:
	game_state = GameLogicScript.send_ultimatum(game_state, target_faction_id)
	state_changed.emit(game_state)

func propose_peace_talk(target_faction_id: String) -> void:
	game_state = GameLogicScript.propose_peace_talk(game_state, target_faction_id)
	state_changed.emit(game_state)

func explore_system(system_id: String) -> void:
	if selected_fleet_id == "":
		return
	game_state = GameLogicScript.explore_system(game_state, selected_fleet_id, system_id)
	state_changed.emit(game_state)

func colonize_system(system_id: String, mode: String = "STANDARD") -> void:
	if selected_fleet_id == "":
		return
	var colonizing_fleet_id: String = selected_fleet_id
	game_state = GameLogicScript.colonize_system(game_state, selected_fleet_id, system_id, mode)
	var selection_repaired: bool = false
	if colonizing_fleet_id != "" and get_fleet_by_id(colonizing_fleet_id).is_empty():
		selected_fleet_id = ""
		selected_system_id = system_id
		fleet_move_mode = false
		selection_repaired = true
	else:
		var updated_fleet: Dictionary = get_fleet_by_id(colonizing_fleet_id)
		if str(updated_fleet.get("mission", "IDLE")) == "COLONIZING" and fleet_move_mode:
			fleet_move_mode = false
			selection_repaired = true
	state_changed.emit(game_state)
	if selection_repaired:
		selection_changed.emit(selected_system_id, selected_fleet_id)

func move_selected_fleet(system_id: String) -> void:
	if selected_fleet_id == "":
		return
	var moving_fleet_id: String = selected_fleet_id
	var previous_fleet: Dictionary = get_fleet_by_id(moving_fleet_id)
	if previous_fleet.is_empty():
		_clear_selected_fleet()
		selection_changed.emit(selected_system_id, selected_fleet_id)
		return
	var previous_system_id: String = str(previous_fleet.get("systemId", ""))
	game_state = GameLogicScript.move_fleet(game_state, moving_fleet_id, system_id)
	var updated_fleet: Dictionary = get_fleet_by_id(moving_fleet_id)
	if updated_fleet.is_empty():
		_clear_selected_fleet()
		state_changed.emit(game_state)
		selection_changed.emit(selected_system_id, selected_fleet_id)
		return
	var updated_system_id: String = str(updated_fleet.get("systemId", previous_system_id))
	var moved_successfully: bool = updated_system_id != "" and updated_system_id != previous_system_id
	if moved_successfully:
		fleet_move_mode = false
		AudioManager.play_event("fleet_move")
	selected_system_id = updated_system_id if updated_system_id != "" else previous_system_id
	state_changed.emit(game_state)
	selection_changed.emit(selected_system_id, selected_fleet_id)

func advance_turn() -> void:
	if turn_busy:
		return
	turn_busy = true
	_begin_turn_iteration()
	state_changed.emit(game_state)
	if has_node("/root/ApiClient") and service_status == "online":
		ApiClient.request_merchant_decision(game_state)
	else:
		game_state = GameLogicScript.process_turn(game_state)
		var local_decision: Dictionary = _local_turn_decision()
		_finish_turn_iteration(local_decision, {"source": "local", "tokens": {}})
		turn_busy = false
		AudioManager.play_event("turn_ready")
		state_changed.emit(game_state)

func request_world_query() -> void:
	if has_node("/root/ApiClient"):
		ApiClient.request_world_query(game_state, selected_system_id if selected_system_id != "" else null)

func request_world_state_scan() -> void:
	if has_node("/root/ApiClient"):
		ApiClient.request_world_state(game_state, "ALL")

func request_decision_iteration_snapshot() -> void:
	if has_node("/root/ApiClient"):
		ApiClient.request_decision_iteration_snapshot(game_state, PLAYER_FACTION_ID)

func request_fleet_move_validation(target_system_id: String) -> void:
	if has_node("/root/ApiClient") and selected_fleet_id != "" and target_system_id != "":
		ApiClient.request_fleet_move_validation(game_state, selected_fleet_id, target_system_id)

func request_relationship_scan(faction_id: String) -> void:
	if has_node("/root/ApiClient") and faction_id != "":
		ApiClient.request_relationship_status(game_state, PLAYER_FACTION_ID, faction_id)

func request_proposal_evaluation(proposal_id: String) -> void:
	if has_node("/root/ApiClient") and proposal_id != "":
		ApiClient.request_proposal_evaluation(game_state, proposal_id, PLAYER_FACTION_ID)

func request_diplomatic_action(target_faction_id: String, action_type: String, action_payload: Dictionary = {}) -> void:
	if has_node("/root/ApiClient") and target_faction_id != "" and action_type != "":
		ApiClient.request_diplomatic_action(game_state, PLAYER_FACTION_ID, target_faction_id, action_type, action_payload)

func request_construction_validation(system_id: String, target_id: String, kind: String) -> void:
	if has_node("/root/ApiClient") and system_id != "" and target_id != "":
		ApiClient.request_construction_validation(game_state, system_id, target_id, kind)

func request_selected_fleet_status() -> void:
	if has_node("/root/ApiClient") and selected_fleet_id != "":
		ApiClient.request_fleet_status(game_state, selected_fleet_id)

func request_selected_tactical_approach() -> void:
	if not has_node("/root/ApiClient") or selected_fleet_id == "":
		return
	var target_system_id: String = selected_system_id
	if target_system_id == "":
		var fleet: Dictionary = get_fleet_by_id(selected_fleet_id)
		target_system_id = str(fleet.get("systemId", ""))
	var defender_fleet_id: String = ""
	for fleet: Dictionary in game_state.get("fleets", []):
		if fleet.get("systemId", "") == target_system_id and fleet.get("ownerId", "") != PLAYER_FACTION_ID:
			defender_fleet_id = fleet.get("id", "")
			break
	ApiClient.request_tactical_approach(game_state, selected_fleet_id, target_system_id, defender_fleet_id)

func request_director_event_preview(event_template_id: String) -> void:
	if not has_node("/root/ApiClient"):
		return
	var target_system_id: String = selected_system_id
	if target_system_id == "":
		for system: Dictionary in game_state.get("starSystems", []):
			if system.get("ownerId", null) == null and system.get("visibilityLevel", "") == "FULL":
				target_system_id = system.get("id", "")
				break
	if target_system_id == "":
		return
	ApiClient.request_director_event(game_state, event_template_id, target_system_id, [PLAYER_FACTION_ID])

func request_resource_diagnosis() -> void:
	if has_node("/root/ApiClient"):
		ApiClient.request_resource_status(game_state, PLAYER_FACTION_ID, "GLOBAL", selected_system_id if selected_system_id != "" else null)

func request_combat_preview() -> void:
	if not has_node("/root/ApiClient") or selected_fleet_id == "":
		return
	var target_fleet_id: String = get_enemy_fleet_for_selected_context().get("id", "")
	if target_fleet_id == "":
		return
	ApiClient.request_combat_protocol(game_state, selected_fleet_id, "FLEET", target_fleet_id, "ALL_OUT", "WEDGE")

func request_director_intervention_preview(intervention_type: String) -> void:
	if has_node("/root/ApiClient"):
		ApiClient.request_director_intervention(game_state, intervention_type, 0.6, "GLOBAL", 4)

func request_narrative_generation_preview() -> void:
	if not has_node("/root/ApiClient"):
		return
	var posture: Dictionary = get_strategic_posture_report()
	var summary: String = str(posture.get("summary", "玩家文明正在重新评估当前银河态势。"))
	ApiClient.request_narrative_generation(summary, "FORMAL", "", "INTELLIGENCE_BRIEFING", game_state)

func execute_selected_combat_protocol(engagement_rules: String = "ALL_OUT", formation: String = "WEDGE", tactic_card: String = "BATTLE_LINE") -> void:
	if selected_fleet_id == "":
		return
	var attacking_fleet_id: String = selected_fleet_id
	var target_fleet: Dictionary = get_enemy_fleet_for_selected_context()
	if target_fleet.is_empty():
		return
	game_state = GameLogicScript.initiate_combat_protocol(game_state, attacking_fleet_id, "FLEET", target_fleet.get("id", ""), engagement_rules, formation, tactic_card)
	var updated_attacker: Dictionary = get_fleet_by_id(attacking_fleet_id)
	if updated_attacker.is_empty():
		_clear_selected_fleet()
	else:
		selected_system_id = str(updated_attacker.get("systemId", selected_system_id))
	state_changed.emit(game_state)
	selection_changed.emit(selected_system_id, selected_fleet_id)
	diplomacy_changed.emit()
	AudioManager.play_event("combat_alert")

func apply_director_event_to_world(event_template_id: String) -> void:
	var target_system_id: String = selected_system_id
	if target_system_id == "":
		for system: Dictionary in game_state.get("starSystems", []):
			if system.get("visibilityLevel", "") == "FULL":
				target_system_id = system.get("id", "")
				break
	if target_system_id == "":
		return
	game_state = GameLogicScript.trigger_narrative_event(game_state, event_template_id, target_system_id, [PLAYER_FACTION_ID])
	state_changed.emit(game_state)

func apply_director_intervention_to_world(intervention_type: String) -> void:
	game_state = GameLogicScript.apply_director_intervention(game_state, intervention_type, 0.6, 4)
	state_changed.emit(game_state)

func resolve_narrative_event(event_id: String, option_label: String) -> void:
	game_state = GameLogicScript.resolve_narrative_event_choice(game_state, event_id, option_label)
	state_changed.emit(game_state)

func request_ai_advice() -> void:
	if has_node("/root/ApiClient"):
		ApiClient.request_ai_decision(game_state)

func request_diplomatic_message(faction_id: String, tone: String) -> void:
	if has_node("/root/ApiClient"):
		var target: Dictionary = get_faction_by_id(faction_id)
		if target.is_empty():
			return
		var relation: Dictionary = GameLogicScript.relation_between(game_state, PLAYER_FACTION_ID, faction_id)
		ApiClient.request_diplomatic_message(get_player_faction(), target, relation.get("level", "NEUTRAL"), tone, game_state)

func send_player_message(target_faction_id: String) -> void:
	var message_text: String = get_diplomatic_draft(target_faction_id).strip_edges()
	if message_text == "":
		return
	var target: Dictionary = get_faction_by_id(target_faction_id)
	if target.is_empty():
		return
	var visibility: String = get_diplomatic_visibility(target_faction_id)
	game_state = GameLogicScript.player_freeform_message(game_state, target_faction_id, message_text, visibility)
	diplomatic_drafts[target_faction_id] = ""
	_pending_conversation_target_id = target_faction_id
	_pending_conversation_visibility = visibility
	state_changed.emit(game_state)
	diplomacy_changed.emit()
	if has_node("/root/ApiClient"):
		var relation: Dictionary = GameLogicScript.relation_between(game_state, PLAYER_FACTION_ID, target_faction_id)
		var intent_preview: Dictionary = GameLogicScript.describe_player_diplomatic_intent(message_text)
		ApiClient.request_ai_conversation(
			get_player_faction(),
			target,
			relation.get("level", "NEUTRAL"),
			intent_preview.get("tone", "neutral"),
			message_text,
			visibility,
			GameLogicScript.parse_player_diplomatic_intent(message_text).get("type", "MESSAGE"),
			intent_preview.get("detail", ""),
			game_state
		)

func accept_diplomatic_proposal(proposal_id: String) -> void:
	game_state = GameLogicScript.accept_pending_proposal(game_state, proposal_id)
	state_changed.emit(game_state)
	diplomacy_changed.emit()

func reject_diplomatic_proposal(proposal_id: String) -> void:
	game_state = GameLogicScript.reject_pending_proposal(game_state, proposal_id)
	state_changed.emit(game_state)
	diplomacy_changed.emit()

func _on_service_health_checked(ok: bool) -> void:
	service_status = "online" if ok else "offline"
	service_status_changed.emit(service_status)

func _on_world_query_received(payload: Dictionary) -> void:
	world_data.merge(payload, true)
	advisor_changed.emit(ai_advice, world_data, diplomatic_message)
	diplomacy_changed.emit()

func _on_ai_decision_received(payload: Dictionary) -> void:
	ai_advice = payload.get("structured_text", "")
	advisor_changed.emit(ai_advice, world_data, diplomatic_message)

func _on_diplomatic_message_received(payload: Dictionary) -> void:
	diplomatic_message = payload
	ai_advice = payload.get("structured_text", ai_advice)
	advisor_changed.emit(ai_advice, world_data, diplomatic_message)

func _on_conversation_received(payload: Dictionary) -> void:
	if _pending_conversation_target_id != "":
		game_state = GameLogicScript.receive_ai_reply(game_state, _pending_conversation_target_id, payload.get("title", ""), payload.get("content", ""), _pending_conversation_visibility, payload.get("tone", "neutral"))
		state_changed.emit(game_state)
		diplomacy_changed.emit()
	diplomatic_message = payload
	ai_advice = payload.get("structured_text", ai_advice)
	_pending_conversation_target_id = ""
	_pending_conversation_visibility = "PUBLIC"
	advisor_changed.emit(ai_advice, world_data, diplomatic_message)

func _on_merchant_decision_received(payload: Dictionary) -> void:
	game_state = GameLogicScript.process_turn(game_state, payload)
	_finish_turn_iteration(payload, payload)
	ai_advice = payload.get("structured_text", ai_advice)
	turn_busy = false
	AudioManager.play_event("turn_ready")
	state_changed.emit(game_state)
	advisor_changed.emit(ai_advice, world_data, diplomatic_message)

func _on_api_failed(_route: String, _message: String) -> void:
	service_status = "offline"
	if _route == "conversation":
		_pending_conversation_target_id = ""
		_pending_conversation_visibility = "PUBLIC"
	if turn_busy:
		game_state = GameLogicScript.process_turn(game_state)
		var local_decision: Dictionary = _local_turn_decision()
		_finish_turn_iteration(local_decision, {"source": "local", "tokens": {}, "fallback": true})
		turn_busy = false
		AudioManager.play_event("turn_ready")
		state_changed.emit(game_state)
	service_status_changed.emit(service_status)

func _begin_turn_iteration() -> void:
	if _decision_iteration_game_id == "":
		_decision_iteration_game_id = _new_decision_iteration_game_id()
	_pending_turn_snapshot = _decision_iteration_service.build_turn_snapshot(
		game_state,
		MERCHANT_FACTION_ID,
		_decision_iteration_game_id
	)

func _finish_turn_iteration(decision: Dictionary, provider_payload: Dictionary = {}) -> void:
	if _pending_turn_snapshot.is_empty():
		return
	var after_snapshot: Dictionary = _decision_iteration_service.build_turn_snapshot(
		game_state,
		MERCHANT_FACTION_ID,
		_decision_iteration_game_id
	)
	var normalized_decision: Dictionary = decision.duplicate(true)
	if normalized_decision.is_empty():
		normalized_decision = _local_turn_decision()
	var decision_record: Dictionary = _decision_iteration_service.build_decision_record(
		_pending_turn_snapshot,
		normalized_decision,
		provider_payload,
		DECISION_ITERATION_PLAYBOOK_ID,
		["merchant_decision", "process_turn"]
	)
	var evaluation: Dictionary = _decision_iteration_service.evaluate_transition(_pending_turn_snapshot, after_snapshot)
	var records: Array = [_pending_turn_snapshot, decision_record, evaluation, after_snapshot]
	var write_result: Dictionary = _decision_iteration_service.append_jsonl_records(records, DECISION_ITERATION_JSONL_PATH)
	var result: Dictionary = {
		"game_id": _decision_iteration_game_id,
		"turn": int(after_snapshot.get("turn", game_state.get("turn", 0))),
		"records_written": int(write_result.get("written", 0)),
		"ok": bool(write_result.get("ok", false)),
		"errors": write_result.get("errors", []),
	}
	world_data["decision_iteration_write"] = result
	_pending_turn_snapshot = {}
	decision_iteration_recorded.emit(result)

func _local_turn_decision() -> Dictionary:
	return {
		"action": "PROCESS_TURN",
		"target": null,
		"reasoning": "Use deterministic local turn processing because no remote strategist is available.",
		"fallback": true,
	}

func _new_decision_iteration_game_id() -> String:
	return "starcat_%s" % str(Time.get_unix_time_from_system())

func _repair_selected_fleet_context(fallback_system_id: String = "") -> bool:
	if selected_fleet_id == "" or not get_fleet_by_id(selected_fleet_id).is_empty():
		return false
	fleet_move_mode = false
	selected_fleet_id = ""
	selected_system_id = fallback_system_id
	if fallback_system_id != "":
		var fleets_at_system: Array = get_player_fleets_in_system(fallback_system_id)
		if not fleets_at_system.is_empty():
			var surviving_fleet: Dictionary = fleets_at_system[0]
			selected_fleet_id = str(surviving_fleet.get("id", ""))
			selected_system_id = str(surviving_fleet.get("systemId", fallback_system_id))
	return true
