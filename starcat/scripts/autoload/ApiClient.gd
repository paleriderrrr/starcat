extends Node

const GameLogicScript = preload("res://scripts/GameLogic.gd")
const LocalConfigScript = preload("res://scripts/config/LocalConfig.gd")
const GameAnalysisServiceScript = preload("res://scripts/services/GameAnalysisService.gd")
const LocalAIServiceScript = preload("res://scripts/services/LocalAIService.gd")
const NarrativeServiceScript = preload("res://scripts/services/NarrativeService.gd")
const DecisionIterationServiceScript = preload("res://scripts/services/DecisionIterationService.gd")
const BailianProviderScript = preload("res://scripts/llm/BailianProvider.gd")
const OpenAIChatProviderScript = preload("res://scripts/llm/OpenAIChatProvider.gd")

signal service_health_checked(ok: bool)
signal world_query_received(payload: Dictionary)
signal ai_decision_received(payload: Dictionary)
signal merchant_decision_received(payload: Dictionary)
signal diplomatic_message_received(payload: Dictionary)
signal conversation_received(payload: Dictionary)
signal request_failed(route: String, message: String)

var _settings: Dictionary = {}
var _analysis_service
var _ai_service
var _narrative_service
var _iteration_service
var _provider

func _ready() -> void:
	_ensure_services()

func _ensure_services() -> void:
	if _analysis_service != null:
		return
	_settings = LocalConfigScript.load_settings()
	_analysis_service = GameAnalysisServiceScript.new()
	_ai_service = LocalAIServiceScript.new()
	_narrative_service = NarrativeServiceScript.new()
	_iteration_service = DecisionIterationServiceScript.new()
	if str(_settings.get("provider", "bailian")).to_lower() == "mimo":
		_provider = OpenAIChatProviderScript.new()
	else:
		_provider = BailianProviderScript.new()
	_provider.configure(_settings)
	add_child(_provider)

func check_service_health() -> void:
	_ensure_services()
	service_health_checked.emit(_analysis_service.check_health())

func request_world_query(game_state: Dictionary, focus_system_id: Variant) -> void:
	_ensure_services()
	world_query_received.emit(_analysis_service.query_world(game_state, focus_system_id))

func request_world_state(game_state: Dictionary, query_filter: String = "ALL") -> void:
	_ensure_services()
	world_query_received.emit({
		"world_state_report": _analysis_service.query_world_state(game_state, query_filter, ["faction_count", "fleet_count", "average_military_power", "war_count"])
	})

func request_decision_iteration_snapshot(game_state: Dictionary, perspective_faction_id: String = "f_player", game_id: String = "starcat_local") -> void:
	_ensure_services()
	world_query_received.emit({
		"decision_iteration_snapshot": _iteration_service.build_turn_snapshot(game_state, perspective_faction_id, game_id)
	})

func request_decision_iteration_record(snapshot: Dictionary, decision: Dictionary, provider_payload: Dictionary = {}, playbook_id: String = "strategist_v0", tools_called: Array = []) -> void:
	_ensure_services()
	world_query_received.emit({
		"decision_iteration_record": _iteration_service.build_decision_record(snapshot, decision, provider_payload, playbook_id, tools_called)
	})

func request_decision_transition_evaluation(before_snapshot: Dictionary, after_snapshot: Dictionary) -> void:
	_ensure_services()
	world_query_received.emit({
		"decision_iteration_evaluation": _iteration_service.evaluate_transition(before_snapshot, after_snapshot)
	})

func request_decision_trial_record(game_id: String, snapshots: Array, decisions: Array, evaluations: Array, metadata: Dictionary = {}) -> void:
	_ensure_services()
	world_query_received.emit({
		"decision_iteration_trial": _iteration_service.build_trial_record(game_id, snapshots, decisions, evaluations, metadata)
	})

func request_decision_artifact_write(record: Dictionary, path: String = "user://decision_iterations/records.jsonl") -> void:
	_ensure_services()
	world_query_received.emit({
		"decision_iteration_write": _iteration_service.append_jsonl(record, path)
	})

func request_fleet_move_validation(game_state: Dictionary, fleet_id: String, target_system_id: String) -> void:
	_ensure_services()
	world_query_received.emit({
		"fleet_move_report": _analysis_service.validate_fleet_move(game_state, fleet_id, target_system_id)
	})

func request_relationship_status(game_state: Dictionary, faction_a_id: String, faction_b_id: String) -> void:
	_ensure_services()
	world_query_received.emit({
		"relationship_report": _analysis_service.query_relationship_status(game_state, faction_a_id, faction_b_id)
	})

func request_proposal_evaluation(game_state: Dictionary, proposal_id: String, evaluator_faction_id: String) -> void:
	_ensure_services()
	world_query_received.emit({
		"proposal_evaluation_report": _analysis_service.evaluate_proposal(game_state, proposal_id, evaluator_faction_id)
	})

func request_diplomatic_action(game_state: Dictionary, source_faction_id: String, target_faction_id: String, action_type: String, action_payload: Dictionary = {}) -> void:
	_ensure_services()
	world_query_received.emit({
		"diplomatic_action_report": _analysis_service.execute_diplomatic_action(game_state, source_faction_id, target_faction_id, action_type, action_payload)
	})

func request_construction_validation(game_state: Dictionary, system_id: String, target_id: String, kind: String) -> void:
	_ensure_services()
	world_query_received.emit({
		"construction_validation_report": _analysis_service.validate_construction(game_state, system_id, target_id, kind)
	})

func request_ai_decision(game_state: Dictionary) -> void:
	_ensure_services()
	var request_data: Dictionary = _ai_service.build_player_request(game_state)
	var fallback: Dictionary = _ai_service.fallback_decision(request_data)
	if not _provider.enabled():
		ai_decision_received.emit(fallback)
		return
	var prompt: String = _ai_service.build_decision_prompt(request_data)
	_provider.request_text(prompt, 180, func(ok: bool, text: String, _payload: Dictionary) -> void:
		if not ok:
			ai_decision_received.emit(fallback)
			return
		var decision: Dictionary = _ai_service.parse_model_decision(text, fallback)
		ai_decision_received.emit(decision if not decision.is_empty() else fallback)
	)

func request_merchant_decision(game_state: Dictionary) -> void:
	_ensure_services()
	var request_data: Dictionary = _ai_service.build_merchant_request(game_state)
	var fallback: Dictionary = _ai_service.fallback_decision(request_data)
	if not _provider.enabled():
		merchant_decision_received.emit(fallback)
		return
	var prompt: String = _ai_service.build_decision_prompt(request_data)
	_provider.request_text(prompt, 180, func(ok: bool, text: String, _payload: Dictionary) -> void:
		if not ok:
			merchant_decision_received.emit(fallback)
			return
		var decision: Dictionary = _ai_service.parse_model_decision(text, fallback)
		merchant_decision_received.emit(decision if not decision.is_empty() else fallback)
	)

func request_diplomatic_message(sender: Dictionary, target: Dictionary, relationship_level: String, tone: String, game_state: Dictionary) -> void:
	_ensure_services()
	var fallback: Dictionary = _narrative_service.fallback_diplomatic_message(sender, target, relationship_level, tone)
	if not _provider.enabled():
		diplomatic_message_received.emit(fallback)
		return
	var prompt: String = _narrative_service.build_diplomatic_prompt(sender, target, relationship_level, tone, game_state)
	_provider.request_text(prompt, 160, func(ok: bool, text: String, _payload: Dictionary) -> void:
		if not ok:
			diplomatic_message_received.emit(fallback)
			return
		var message_payload: Dictionary = _narrative_service.parse_diplomatic_message(text, fallback)
		diplomatic_message_received.emit(message_payload if not message_payload.is_empty() else fallback)
	)

func request_ai_conversation(sender: Dictionary, target: Dictionary, relationship_level: String, tone: String, player_message: String, visibility_level: String, intent_type: String = "MESSAGE", intent_detail: String = "", game_state: Dictionary = {}) -> void:
	_ensure_services()
	var recipient_name: String = str(target.get("leaderName", target.get("name", "")))
	var fallback: Dictionary = _narrative_service.fallback_conversation(sender, recipient_name, relationship_level, tone, player_message, visibility_level)
	if not _provider.enabled():
		conversation_received.emit(fallback)
		return
	var prompt: String = _narrative_service.build_conversation_prompt(sender, recipient_name, relationship_level, tone, player_message, visibility_level, intent_type, intent_detail, game_state)
	_provider.request_text(prompt, 220, func(ok: bool, text: String, _payload: Dictionary) -> void:
		if not ok:
			conversation_received.emit(fallback)
			return
		var response_payload: Dictionary = _narrative_service.parse_conversation(text, fallback)
		conversation_received.emit(response_payload if not response_payload.is_empty() else fallback)
	)

func request_fleet_status(game_state: Dictionary, fleet_id: String) -> void:
	_ensure_services()
	world_query_received.emit({
		"fleet_status_fleet_id": fleet_id,
		"fleet_status_report": _analysis_service.query_fleet_status(game_state, fleet_id, true)
	})

func request_tactical_approach(game_state: Dictionary, attacker_fleet_id: String, target_system_id: String, defender_fleet_id: String = "") -> void:
	_ensure_services()
	world_query_received.emit({
		"tactical_report": _analysis_service.recommend_tactical_approach(game_state, attacker_fleet_id, target_system_id, defender_fleet_id)
	})

func request_director_event(game_state: Dictionary, event_template_id: String, target_location: String, affected_factions: Array) -> void:
	_ensure_services()
	world_query_received.emit({
		"director_event_report": _analysis_service.preview_director_event(game_state, event_template_id, target_location, affected_factions)
	})

func request_resource_status(game_state: Dictionary, faction_id: String, scope: String = "GLOBAL", system_id: Variant = null) -> void:
	_ensure_services()
	world_query_received.emit({
		"resource_status_report": _analysis_service.query_resource_status(game_state, faction_id, scope, system_id)
	})

func request_resource_policy(game_state: Dictionary, faction_id: String, policy_name: String, value: float, priority_focus: String = "BALANCED", scope: String = "GLOBAL", system_id: Variant = null) -> void:
	_ensure_services()
	world_query_received.emit({
		"resource_policy_report": _analysis_service.apply_resource_policy(game_state, faction_id, policy_name, value, priority_focus, scope, system_id)
	})

func request_research_priority(game_state: Dictionary, faction_id: String, tech_id: String, allocation: float = 1.0) -> void:
	_ensure_services()
	world_query_received.emit({
		"research_priority_report": _analysis_service.query_research_priority(game_state, faction_id, tech_id, allocation)
	})

func request_ship_production(game_state: Dictionary, faction_id: String, system_id: String, ship_type: String, quantity: int = 1, priority: String = "NORMAL") -> void:
	_ensure_services()
	world_query_received.emit({
		"ship_production_report": _analysis_service.order_ship_production(game_state, faction_id, system_id, ship_type, quantity, priority)
	})

func request_combat_protocol(game_state: Dictionary, fleet_id: String, target_type: String, target_id: String, engagement_rules: String = "ALL_OUT", formation: String = "LINE") -> void:
	_ensure_services()
	world_query_received.emit({
		"combat_protocol_report": _analysis_service.preview_combat_protocol(game_state, fleet_id, target_type, target_id, engagement_rules, formation)
	})

func request_director_intervention(_game_state: Dictionary, intervention_type: String, intensity: float = 0.5, _target_scope: String = "GLOBAL", duration: int = 3) -> void:
	_ensure_services()
	world_query_received.emit({
		"director_intervention_report": _analysis_service.preview_director_intervention(intervention_type, intensity, duration)
	})

func request_narrative_generation(context: String, style: String = "FORMAL", recipient: String = "", content_type: String = "DECLARATION", game_state: Dictionary = {}) -> void:
	_ensure_services()
	var fallback: Dictionary = _narrative_service.fallback_narrative_content(context, style, recipient, content_type)
	if not _provider.enabled():
		world_query_received.emit({"narrative_generation_report": fallback})
		return
	var prompt: String = _narrative_service.build_narrative_prompt(context, style, recipient, content_type, game_state)
	_provider.request_text(prompt, 220, func(ok: bool, text: String, _payload: Dictionary) -> void:
		if not ok:
			world_query_received.emit({"narrative_generation_report": fallback})
			return
		var narrative_payload: Dictionary = _narrative_service.parse_narrative_content(text, fallback)
		world_query_received.emit({"narrative_generation_report": narrative_payload if not narrative_payload.is_empty() else fallback})
	)

func _system_has_shipyard(system: Dictionary) -> bool:
	for building: Dictionary in system.get("buildings", []):
		if building.get("type", "") == "SHIPYARD":
			return true
	return false
