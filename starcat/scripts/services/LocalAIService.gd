extends RefCounted

class_name LocalAIService

const FORMAT_VERSION: String = "1.0"
const DEFAULT_PLAYER_ID: String = "f_player"
const MERCHANT_ID: String = "f_merchant"
const GameLogicScript = preload("res://scripts/GameLogic.gd")

func build_player_request(game_state: Dictionary) -> Dictionary:
	var player: Dictionary = GameLogicScript.player_faction(game_state)
	return _build_request_from_faction(game_state, player, DEFAULT_PLAYER_ID, MERCHANT_ID, false)

func build_merchant_request(game_state: Dictionary) -> Dictionary:
	var merchant: Dictionary = _faction_by_id(game_state, MERCHANT_ID)
	return _build_request_from_faction(game_state, merchant, MERCHANT_ID, DEFAULT_PLAYER_ID, true)

func fallback_decision(request_data: Dictionary) -> Dictionary:
	var resources: Dictionary = request_data.get("resources", {})
	var visible_neutral_systems: Array = request_data.get("visible_neutral_systems", [])
	var relation_trust: float = float(request_data.get("relation_trust", 0))
	var relation_utility: float = float(request_data.get("relation_utility", 0))
	var relation_fear: float = float(request_data.get("relation_fear", 0))
	var relation_memory: float = float(request_data.get("relation_memory_impact", 0))
	var home_has_shipyard: bool = bool(request_data.get("home_has_shipyard", false))
	var available_build_targets: Array = request_data.get("available_build_targets", ["CORVETTE"])
	var can_attack_player: bool = bool(request_data.get("can_attack_player", false))
	var player_system_id: String = str(request_data.get("player_system_id", ""))
	var richest_target: Dictionary = {}
	for target: Dictionary in visible_neutral_systems:
		if richest_target.is_empty() or int(target.get("value", 0)) > int(richest_target.get("value", 0)):
			richest_target = target
	var action: String = "WAIT"
	var target: Variant = null
	var reasoning: String = "本回合储备不足或目标不明确，暂时观望并等待更好窗口。"
	if relation_trust <= -25 and relation_fear <= 55 and can_attack_player and player_system_id != "":
		action = "DECLARE_WAR"
		target = player_system_id
		reasoning = "边境互信跌破警戒线，先发制人可以迫使对手回防。"
	elif not home_has_shipyard and int(resources.get("minerals", 0)) >= 60 and int(resources.get("industry", 0)) >= 50:
		action = "BUILD"
		target = "SHIPYARD"
		reasoning = "先补齐本土造舰能力，后续扩张和护航都会更稳定。"
	elif available_build_targets.has("CRUISER") and int(resources.get("minerals", 0)) >= 100 and int(resources.get("industry", 0)) >= 90:
		action = "BUILD"
		target = "CRUISER"
		reasoning = "当前储备足够支撑主力舰下水，应尽快建立质量优势。"
	elif available_build_targets.has("DESTROYER") and int(resources.get("minerals", 0)) >= 50 and int(resources.get("industry", 0)) >= 40:
		action = "BUILD"
		target = "DESTROYER"
		reasoning = "驱逐舰能同时承担护航和威慑任务，性价比最高。"
	elif not richest_target.is_empty():
		action = "EXPLORE"
		target = richest_target.get("id", "")
		reasoning = "%s 资源回报最高，优先抢占能扩大资源纵深。" % str(richest_target.get("name", "目标星系"))
	elif relation_trust + relation_utility * 0.4 + relation_memory * 0.2 >= 45.0:
		action = "TRADE"
		target = DEFAULT_PLAYER_ID
		reasoning = "当前关系仍有合作空间，短期交易比消耗战更划算。"
	elif relation_fear >= 65 and not richest_target.is_empty():
		action = "EXPLORE"
		target = richest_target.get("id", "")
		reasoning = "对敌方军势存在明显忌惮，优先外扩比正面冲突更稳妥。"
	elif available_build_targets.has("CORVETTE") and int(resources.get("minerals", 0)) >= 30 and int(resources.get("industry", 0)) >= 25:
		action = "BUILD"
		target = "CORVETTE"
		reasoning = "先补轻型护航舰，确保商路和边境不会出现空档。"
	return _decision_payload(action, target, reasoning, "fallback", true)

func build_decision_prompt(request_data: Dictionary) -> String:
	return "\n".join([
		"TASK",
		"为该 4X 势力选择本回合唯一最佳行动，并返回 JSON。",
		"",
		"OUTPUT_SCHEMA",
		'{"action":"BUILD|EXPLORE|TRADE|DECLARE_WAR|WAIT","target":"string|null","reasoning":"short Chinese sentence"}',
		"",
		"HARD_RULES",
		"- 只返回一个 JSON 对象。",
		"- 不要输出 Markdown。",
		"- BUILD 目标必须是 SHIPYARD/CORVETTE/DESTROYER/CRUISER。",
		"- DECLARE_WAR 目标必须是 player_system_id。",
		"- WAIT 的 target 必须为 null。",
		"",
		"INPUT_JSON",
		JSON.stringify(request_data),
	])

func parse_model_decision(raw_text: String, fallback: Dictionary) -> Dictionary:
	var parsed: Dictionary = _extract_json(raw_text)
	var action: String = str(parsed.get("action", fallback.get("action", "WAIT"))).to_upper()
	if not ["BUILD", "EXPLORE", "TRADE", "DECLARE_WAR", "WAIT"].has(action):
		return fallback
	var target: Variant = parsed.get("target", fallback.get("target", null))
	var reasoning: String = _sanitize_text(str(parsed.get("reasoning", fallback.get("reasoning", ""))), 60)
	if reasoning == "":
		return fallback
	if action == "WAIT":
		target = null
	elif target != null:
		target = str(target)
	return _decision_payload(action, target, reasoning, "bailian", false)

func _build_request_from_faction(game_state: Dictionary, faction: Dictionary, source_id: String, rival_id: String, is_merchant: bool) -> Dictionary:
	var visible_neutral_systems: Array = []
	var current_system_id: String = ""
	if is_merchant:
		for fleet: Dictionary in game_state.get("fleets", []):
			if fleet.get("ownerId", "") == source_id:
				current_system_id = str(fleet.get("systemId", ""))
				break
	var connected_ids: Array = [] if current_system_id == "" else GameLogicScript.connected_to(game_state, current_system_id)
	for system: Dictionary in game_state.get("starSystems", []):
		var owner_id: Variant = system.get("ownerId", null)
		var visible: bool = system.get("visibilityLevel", "") == "FULL"
		if owner_id == null and (visible or connected_ids.has(system.get("id", ""))):
			var resources: Dictionary = system.get("resources", {})
			visible_neutral_systems.append({
				"id": str(system.get("id", "")),
				"name": str(system.get("name", "")),
				"value": int(resources.get("food", 0)) + int(resources.get("minerals", 0)) * 3 + int(resources.get("industry", 0)) * 2 + int(resources.get("energy", 0)) * 3,
			})
	var home_system: Dictionary = {}
	for system: Dictionary in game_state.get("starSystems", []):
		if system.get("ownerId", null) == source_id:
			home_system = system
			break
	var relation: Dictionary = GameLogicScript.relation_between(game_state, source_id, rival_id)
	var build_targets: Array = ["CORVETTE"]
	if int(game_state.get("turn", 1)) >= 9:
		build_targets.append("DESTROYER")
	if int(game_state.get("turn", 1)) >= 13:
		build_targets.append("CRUISER")
	return {
		"leader_name": str(faction.get("leaderName", "")),
		"faction_name": str(faction.get("name", "")),
		"personality": faction.get("personality", {}),
		"turn": int(game_state.get("turn", 1)),
		"era": str(game_state.get("era", "PIONEER")),
		"resources": faction.get("resources", {}),
		"owned_systems": faction.get("controlledSystems", []),
		"visible_neutral_systems": visible_neutral_systems,
		"relation_trust": int(relation.get("trust", 0)),
		"relation_utility": int(relation.get("utility", 0)),
		"relation_fear": int(relation.get("fear", 0)),
		"relation_memory_impact": int(relation.get("memoryImpact", 0)),
		"home_system_id": str(home_system.get("id", "")),
		"home_has_shipyard": _system_has_shipyard(home_system),
		"available_build_targets": build_targets,
		"can_attack_player": current_system_id != "" and connected_ids.has("sys_cat_home"),
		"player_system_id": "sys_cat_home",
		"rival_relations": game_state.get("relationships", []),
		"related_memories": GameLogicScript.related_long_term_memories(game_state, "turn decision", [source_id, rival_id], 4),
	}

func _decision_payload(action: String, target: Variant, reasoning: String, source: String, is_fallback: bool) -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"source": source,
		"is_fallback": is_fallback,
		"structured_text": _decision_text(action, target, reasoning, source, is_fallback),
		"action": action,
		"target": target,
		"reasoning": reasoning,
	}

func _decision_text(action: String, target: Variant, reasoning: String, source: String, is_fallback: bool) -> String:
	return "\n".join([
		"[AI_DECISION]",
		"format_version: %s" % FORMAT_VERSION,
		"source: %s" % source,
		"is_fallback: %s" % str(is_fallback).to_lower(),
		"action: %s" % action,
		"target: %s" % ("null" if target == null else str(target)),
		"reasoning: %s" % reasoning,
		"[/AI_DECISION]",
	])

func _extract_json(raw_text: String) -> Dictionary:
	var matcher: RegEx = RegEx.new()
	matcher.compile("\\{[\\s\\S]*\\}")
	var result: RegExMatch = matcher.search(raw_text)
	if result == null:
		return {}
	var parsed: Variant = JSON.parse_string(result.get_string())
	return parsed if parsed is Dictionary else {}

func _sanitize_text(text: String, max_chars: int) -> String:
	var normalized: String = text.replace("\n", " ").replace("\r", " ").strip_edges()
	var compact: String = RegEx.new().sub(normalized, " ", true) if false else normalized
	if compact.length() > max_chars:
		return compact.substr(0, max_chars).strip_edges()
	return compact

func _faction_by_id(game_state: Dictionary, faction_id: String) -> Dictionary:
	for faction: Dictionary in game_state.get("factions", []):
		if str(faction.get("id", "")) == faction_id:
			return faction
	return {}

func _system_has_shipyard(system: Dictionary) -> bool:
	for building: Dictionary in system.get("buildings", []):
		if str(building.get("type", "")) == "SHIPYARD":
			return true
	return false

