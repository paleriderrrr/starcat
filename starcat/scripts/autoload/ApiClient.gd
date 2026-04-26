extends Node

signal health_checked(ok: bool)
signal world_query_received(payload: Dictionary)
signal ai_decision_received(payload: Dictionary)
signal merchant_decision_received(payload: Dictionary)
signal diplomatic_message_received(payload: Dictionary)
signal conversation_received(payload: Dictionary)
signal request_failed(route: String, message: String)

const API_BASE: String = "http://127.0.0.1:8000"

var _http: HTTPRequest
var _active_route: String = ""

func _ready() -> void:
	_ensure_http()

func _ensure_http() -> void:
	if _http != null and is_instance_valid(_http):
		return
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func build_url(path: String) -> String:
	return "%s%s" % [API_BASE, path]

func make_json_headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json"])

func check_health() -> void:
	_ensure_http()
	_active_route = "health"
	var error_code: int = _http.request(build_url("/api/health"))
	if error_code != OK:
		health_checked.emit(false)
		request_failed.emit("health", "无法发起健康检查。")

func request_world_query(game_state: Dictionary, focus_system_id: Variant) -> void:
	var payload: Dictionary = {"game_state": game_state, "focus_system_id": focus_system_id}
	_post_json("world_query", "/api/world/query", payload)

func request_world_state(game_state: Dictionary, query_filter: String = "ALL") -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"query_filter": query_filter,
		"metrics": ["faction_count", "fleet_count", "average_military_power", "war_count"]
	}
	_post_json("world_state", "/api/world/state", payload)

func request_fleet_move_validation(game_state: Dictionary, fleet_id: String, target_system_id: String) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"fleet_id": fleet_id,
		"target_system_id": target_system_id
	}
	_post_json("fleet_move_validation", "/api/fleet/move", payload)

func request_relationship_status(game_state: Dictionary, faction_a_id: String, faction_b_id: String) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"faction_a_id": faction_a_id,
		"faction_b_id": faction_b_id
	}
	_post_json("relationship_status", "/api/diplomacy/relationship", payload)

func request_proposal_evaluation(game_state: Dictionary, proposal_id: String, evaluator_faction_id: String) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"proposal_id": proposal_id,
		"evaluator_faction_id": evaluator_faction_id
	}
	_post_json("proposal_evaluation", "/api/diplomacy/evaluate-proposal", payload)

func request_diplomatic_action(game_state: Dictionary, source_faction_id: String, target_faction_id: String, action_type: String, action_payload: Dictionary = {}) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"source_faction_id": source_faction_id,
		"target_faction_id": target_faction_id,
		"action_type": action_type,
		"payload": action_payload
	}
	_post_json("diplomatic_action", "/api/diplomacy/execute", payload)

func request_construction_validation(game_state: Dictionary, system_id: String, target_id: String, kind: String) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"system_id": system_id,
		"target_id": target_id,
		"kind": kind
	}
	_post_json("construction_validation", "/api/construction/manage", payload)

func request_ai_decision(game_state: Dictionary) -> void:
	var player: Dictionary = GameLogic.player_faction(game_state)
	var visible_neutral_systems: Array = []
	for system: Dictionary in game_state.get("starSystems", []):
		if system.get("ownerId", null) == null and system.get("visibilityLevel", "") == "FULL":
			var resources: Dictionary = system.get("resources", {})
			var value: int = int(resources.get("food", 0)) + int(resources.get("minerals", 0)) * 3 + int(resources.get("industry", 0)) * 2 + int(resources.get("energy", 0)) * 3
			visible_neutral_systems.append({"id": system.get("id", ""), "name": system.get("name", ""), "value": value})
	var payload: Dictionary = {
		"leader_name": player.get("leaderName", ""),
		"faction_name": player.get("name", ""),
		"personality": player.get("personality", {}),
		"game_state": {
			"turn": game_state.get("turn", 1),
			"era": game_state.get("era", "PIONEER"),
			"resources": player.get("resources", {}),
			"owned_systems": player.get("controlledSystems", []),
			"visible_neutral_systems": visible_neutral_systems,
			"relation_trust": GameLogic.relation_between(game_state, "f_player", "f_merchant").get("trust", 0),
			"rival_relations": game_state.get("relationships", [])
		}
	}
	_post_json("ai_decide", "/api/ai/decide", payload)

func request_merchant_decision(game_state: Dictionary) -> void:
	var merchant: Dictionary = {}
	var merchant_fleet: Dictionary = {}
	var merchant_home: Dictionary = {}
	for faction: Dictionary in game_state.get("factions", []):
		if faction.get("id", "") == "f_merchant":
			merchant = faction
	for fleet: Dictionary in game_state.get("fleets", []):
		if fleet.get("ownerId", "") == "f_merchant":
			merchant_fleet = fleet
	for system: Dictionary in game_state.get("starSystems", []):
		if system.get("ownerId", null) == "f_merchant":
			merchant_home = system
	var connected_ids: Array = [] if merchant_fleet.is_empty() else GameLogic.connected_to(game_state, merchant_fleet.get("systemId", ""))
	var visible_neutral_systems: Array = []
	for system: Dictionary in game_state.get("starSystems", []):
		if system.get("ownerId", null) == null and (system.get("visibilityLevel", "") == "FULL" or connected_ids.has(system.get("id", ""))):
			var resources: Dictionary = system.get("resources", {})
			var value: int = int(resources.get("food", 0)) + int(resources.get("minerals", 0)) * 3 + int(resources.get("industry", 0)) * 2 + int(resources.get("energy", 0)) * 3
			visible_neutral_systems.append({"id": system.get("id", ""), "name": system.get("name", ""), "value": value})
	var available_build_targets: Array = ["CORVETTE"]
	if int(game_state.get("turn", 1)) >= 9:
		available_build_targets.append("DESTROYER")
	if int(game_state.get("turn", 1)) >= 13:
		available_build_targets.append("CRUISER")
	var relation: Dictionary = GameLogic.relation_between(game_state, "f_player", "f_merchant")
	var payload: Dictionary = {
		"leader_name": merchant.get("leaderName", ""),
		"faction_name": merchant.get("name", ""),
		"personality": merchant.get("personality", {}),
		"game_state": {
			"turn": game_state.get("turn", 1),
			"era": game_state.get("era", "PIONEER"),
			"resources": merchant.get("resources", {}),
			"owned_systems": merchant.get("controlledSystems", []),
			"visible_neutral_systems": visible_neutral_systems,
			"relation_trust": relation.get("trust", 0),
			"relation_utility": relation.get("utility", 0),
			"relation_fear": relation.get("fear", 0),
			"relation_memory_impact": relation.get("memoryImpact", 0),
			"home_system_id": merchant_home.get("id", ""),
			"home_has_shipyard": _system_has_shipyard(merchant_home),
			"available_build_targets": available_build_targets,
			"can_attack_player": not merchant_fleet.is_empty() and connected_ids.has("sys_cat_home"),
			"player_system_id": "sys_cat_home"
		}
	}
	_post_json("merchant_decide", "/api/ai/decide", payload)

func request_diplomatic_message(sender: Dictionary, target: Dictionary, relationship_level: String, tone: String) -> void:
	var payload: Dictionary = {
		"sender_name": sender.get("leaderName", ""),
		"recipient_name": target.get("name", ""),
		"relationship_level": relationship_level,
		"tone": tone,
		"personality": sender.get("personality", {}),
		"game_state": GameState.game_state
	}
	_post_json("diplomatic_message", "/api/ai/diplomatic-message", payload)

func request_ai_conversation(sender: Dictionary, target: Dictionary, relationship_level: String, tone: String, player_message: String, visibility_level: String, intent_type: String = "MESSAGE", intent_detail: String = "") -> void:
	var payload: Dictionary = {
		"sender_name": sender.get("leaderName", ""),
		"recipient_name": target.get("leaderName", target.get("name", "")),
		"relationship_level": relationship_level,
		"tone": tone,
		"visibility_level": visibility_level,
		"intent_type": intent_type,
		"intent_detail": intent_detail,
		"player_message": player_message,
		"personality": target.get("personality", {}),
		"game_state": GameState.game_state
	}
	_post_json("conversation", "/api/ai/conversation", payload)

func request_fleet_status(game_state: Dictionary, fleet_id: String) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"fleet_id": fleet_id,
		"include_units": true
	}
	_post_json("fleet_status", "/api/fleet/status", payload)

func request_tactical_approach(game_state: Dictionary, attacker_fleet_id: String, target_system_id: String, defender_fleet_id: String = "") -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"attacker_fleet_id": attacker_fleet_id,
		"target_system_id": target_system_id,
		"attack_objective": "OCCUPY"
	}
	if defender_fleet_id != "":
		payload["defender_fleet_id"] = defender_fleet_id
	_post_json("tactical_approach", "/api/combat/tactical-approach", payload)

func request_director_event(game_state: Dictionary, event_template_id: String, target_location: String, affected_factions: Array) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"event_template_id": event_template_id,
		"target_location": target_location,
		"affected_factions": affected_factions
	}
	_post_json("director_event", "/api/director/trigger-event", payload)

func request_resource_status(game_state: Dictionary, faction_id: String, scope: String = "GLOBAL", system_id: Variant = null) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"faction_id": faction_id,
		"scope": scope,
		"system_id": system_id
	}
	_post_json("resource_status", "/api/resources/status", payload)

func request_resource_policy(game_state: Dictionary, faction_id: String, policy_name: String, value: float, priority_focus: String = "BALANCED", scope: String = "GLOBAL", system_id: Variant = null) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"faction_id": faction_id,
		"scope": scope,
		"system_id": system_id,
		"policy_name": policy_name,
		"value": value,
		"priority_focus": priority_focus
	}
	_post_json("resource_policy", "/api/resources/policy", payload)

func request_research_priority(game_state: Dictionary, faction_id: String, tech_id: String, allocation: float = 1.0) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"faction_id": faction_id,
		"tech_id": tech_id,
		"allocation": allocation
	}
	_post_json("research_priority", "/api/research/set-priority", payload)

func request_ship_production(game_state: Dictionary, faction_id: String, system_id: String, ship_type: String, quantity: int = 1, priority: String = "NORMAL") -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"faction_id": faction_id,
		"system_id": system_id,
		"ship_type": ship_type,
		"quantity": quantity,
		"priority": priority
	}
	_post_json("ship_production", "/api/production/order-ship", payload)

func request_combat_protocol(game_state: Dictionary, fleet_id: String, target_type: String, target_id: String, engagement_rules: String = "ALL_OUT", formation: String = "LINE") -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"fleet_id": fleet_id,
		"target_type": target_type,
		"target_id": target_id,
		"engagement_rules": engagement_rules,
		"formation": formation
	}
	_post_json("combat_protocol", "/api/combat/initiate", payload)

func request_director_intervention(game_state: Dictionary, intervention_type: String, intensity: float = 0.5, target_scope: String = "GLOBAL", duration: int = 3) -> void:
	var payload: Dictionary = {
		"game_state": game_state,
		"intervention_type": intervention_type,
		"intensity": intensity,
		"target_scope": target_scope,
		"duration": duration
	}
	_post_json("director_intervention", "/api/director/intervention", payload)

func request_narrative_generation(context: String, style: String = "FORMAL", recipient: String = "", content_type: String = "DECLARATION", game_state: Dictionary = {}) -> void:
	var payload: Dictionary = {
		"context": context,
		"style": style,
		"recipient": recipient if recipient != "" else null,
		"content_type": content_type,
		"game_state": game_state
	}
	_post_json("narrative_generation", "/api/director/generate-narrative", payload)

func _post_json(route: String, path: String, payload: Dictionary) -> void:
	_ensure_http()
	_active_route = route
	var error_code: int = _http.request(build_url(path), make_json_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error_code != OK:
		request_failed.emit(route, "请求未能发起。")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	var payload: Dictionary = parsed if parsed is Dictionary else {}
	if _active_route == "health":
		health_checked.emit(result == HTTPRequest.RESULT_SUCCESS and response_code == 200 and payload.get("status", "") == "ok")
		return
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		request_failed.emit(_active_route, text if text != "" else "接口返回失败。")
		return
	match _active_route:
		"world_query":
			world_query_received.emit(payload)
		"world_state":
			world_query_received.emit({"world_state_report": payload})
		"fleet_move_validation":
			world_query_received.emit({"fleet_move_report": payload})
		"relationship_status":
			world_query_received.emit({"relationship_report": payload})
		"proposal_evaluation":
			world_query_received.emit({"proposal_evaluation_report": payload})
		"diplomatic_action":
			world_query_received.emit({"diplomatic_action_report": payload})
		"construction_validation":
			world_query_received.emit({"construction_validation_report": payload})
		"ai_decide":
			ai_decision_received.emit(payload)
		"merchant_decide":
			merchant_decision_received.emit(payload)
		"diplomatic_message":
			diplomatic_message_received.emit(payload)
		"conversation":
			conversation_received.emit(payload)
		"fleet_status":
			world_query_received.emit({"fleet_status_report": payload})
		"tactical_approach":
			world_query_received.emit({"tactical_report": payload})
		"director_event":
			world_query_received.emit({"director_event_report": payload})
		"resource_status":
			world_query_received.emit({"resource_status_report": payload})
		"resource_policy":
			world_query_received.emit({"resource_policy_report": payload})
		"research_priority":
			world_query_received.emit({"research_priority_report": payload})
		"ship_production":
			world_query_received.emit({"ship_production_report": payload})
		"combat_protocol":
			world_query_received.emit({"combat_protocol_report": payload})
		"director_intervention":
			world_query_received.emit({"director_intervention_report": payload})
		"narrative_generation":
			world_query_received.emit({"narrative_generation_report": payload})

func _system_has_shipyard(system: Dictionary) -> bool:
	for building: Dictionary in system.get("buildings", []):
		if building.get("type", "") == "SHIPYARD":
			return true
	return false
