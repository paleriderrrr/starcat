extends RefCounted

class_name GameLogic

const InitialDataScript = preload("res://scripts/data/InitialData.gd")
const COLONY_COST: Dictionary = {"food": 60, "minerals": 50, "industry": 40, "energy": 20}
const RECENT_INTERACTION_MEMORY_LIMIT: int = 20
const INTERACTION_ARCHIVE_BATCH: int = 10
const ARCHIVED_INTERACTION_MEMORY_LIMIT: int = 64

static func empty_resources() -> Dictionary:
	return {"food": 0, "minerals": 0, "industry": 0, "energy": 0}

static func duplicate_state(state: Dictionary) -> Dictionary:
	return state.duplicate(true)

static func make_state_id(state: Dictionary, prefix: String) -> String:
	var count: int = 0
	count += state.get("messages", []).size()
	count += state.get("diplomaticMessages", []).size()
	count += state.get("diplomaticMemories", []).size()
	count += state.get("constructionQueue", []).size()
	count += state.get("fleets", []).size()
	for system: Dictionary in state.get("starSystems", []):
		count += system.get("buildings", []).size()
	for fleet: Dictionary in state.get("fleets", []):
		count += fleet.get("ships", []).size()
	return "%s_%s_%s_%s" % [prefix, str(state.get("turn", 1)), str(count), str(Time.get_ticks_msec())]

static func _tokenize_semantic_keywords(text: String, participants: Array = []) -> Array:
	var normalized: String = text.to_lower()
	for mark: String in [",", "，", "。", "！", "？", ":", "：", ";", "；", "\n", "\t", "(", ")", "[", "]", "{", "}", "\"", "'"]:
		normalized = normalized.replace(mark, " ")
	var keywords: Array = []
	for fragment: String in normalized.split(" ", false):
		var token: String = fragment.strip_edges()
		if token.length() < 2:
			continue
		if not keywords.has(token):
			keywords.append(token)
	for participant: Variant in participants:
		var participant_token: String = str(participant).strip_edges().to_lower()
		if participant_token != "" and not keywords.has(participant_token):
			keywords.append(participant_token)
	return keywords

static func _memory_emotional_impact(category: String, importance: int) -> float:
	var baseline: float = clamp(float(importance) * 0.18, 0.1, 0.9)
	match category:
		"WAR", "ULTIMATUM", "WARNING":
			return -baseline
		"AGREEMENT", "ALLY", "TRADE", "PUBLIC":
			return baseline * 0.8
		_:
			return baseline * 0.45

static func _build_memory_node(state: Dictionary, title: String, summary: String, participants: Array, category: String, importance: int, emotional_impact: float = 0.0, decay_factor: float = 0.98) -> Dictionary:
	var resolved_impact: float = emotional_impact if emotional_impact != 0.0 else _memory_emotional_impact(category, importance)
	return {
		"id": make_state_id(state, "mem"),
		"turn": int(state.get("turn", 1)),
		"title": title,
		"summary": summary,
		"participants": participants,
		"category": category,
		"importance": importance,
		"semantic_keywords": _tokenize_semantic_keywords("%s %s" % [title, summary], participants),
		"emotionalImpact": resolved_impact,
		"decayFactor": decay_factor
	}

static func _compress_interaction_batch(entries: Array) -> Dictionary:
	if entries.is_empty():
		return {}
	var participants: Array = []
	var categories: Array = []
	var highlights: Array = []
	var importance: int = 1
	var total_impact: float = 0.0
	for item: Dictionary in entries:
		for participant: Variant in item.get("participants", []):
			if not participants.has(participant):
				participants.append(participant)
		var category: String = str(item.get("category", "EVENT"))
		if not categories.has(category):
			categories.append(category)
		var title: String = str(item.get("title", "未命名交互"))
		var summary: String = str(item.get("summary", ""))
		highlights.append("%s：%s" % [title, summary if summary != "" else "无补充说明"])
		importance = maxi(importance, int(item.get("importance", 1)))
		total_impact += float(item.get("emotionalImpact", 0.0))
	var combined_summary: String = "归档摘要：%s" % "；".join(highlights.slice(0, min(3, highlights.size())))
	return {
		"title": "交互归档摘要",
		"summary": combined_summary,
		"participants": participants,
		"category": " / ".join(categories),
		"importance": maxi(importance, 2),
		"emotionalImpact": clamp(total_impact / maxf(1.0, float(entries.size())), -1.0, 1.0),
		"decayFactor": 0.985
	}

static func _archive_old_interactions(next_state: Dictionary) -> Dictionary:
	var recent: Array = next_state.get("recentInteractionMemory", [])
	if recent.size() <= RECENT_INTERACTION_MEMORY_LIMIT:
		next_state["recentInteractionMemory"] = recent
		return next_state
	var oldest_batch: Array = recent.slice(recent.size() - INTERACTION_ARCHIVE_BATCH, recent.size())
	recent = recent.slice(0, recent.size() - INTERACTION_ARCHIVE_BATCH)
	var archived: Array = next_state.get("archivedInteractionMemory", [])
	var archive_payload: Dictionary = _compress_interaction_batch(oldest_batch)
	if not archive_payload.is_empty():
		archived.push_front(_build_memory_node(
			next_state,
			str(archive_payload.get("title", "交互归档摘要")),
			str(archive_payload.get("summary", "")),
			archive_payload.get("participants", []),
			str(archive_payload.get("category", "ARCHIVE")),
			int(archive_payload.get("importance", 2)),
			float(archive_payload.get("emotionalImpact", 0.0)),
			float(archive_payload.get("decayFactor", 0.985))
		))
	if archived.size() > ARCHIVED_INTERACTION_MEMORY_LIMIT:
		archived = archived.slice(0, ARCHIVED_INTERACTION_MEMORY_LIMIT)
	next_state["recentInteractionMemory"] = recent
	next_state["archivedInteractionMemory"] = archived
	return next_state

static func _append_interaction_memory(state: Dictionary, title: String, summary: String, participants: Array, category: String, importance: int) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var recent: Array = next_state.get("recentInteractionMemory", [])
	recent.push_front(_build_memory_node(next_state, title, summary, participants, category, importance))
	next_state["recentInteractionMemory"] = recent
	return _archive_old_interactions(next_state)

static func related_long_term_memories(state: Dictionary, query_text: String, participants: Array = [], limit: int = 4) -> Array:
	var query_keywords: Array = _tokenize_semantic_keywords(query_text, participants)
	var candidates: Array = []
	for memory: Dictionary in state.get("archivedInteractionMemory", []):
		var keywords: Array = memory.get("semantic_keywords", [])
		var overlap: int = 0
		for keyword: Variant in query_keywords:
			if keywords.has(keyword):
				overlap += 1
		var participant_bonus: int = 0
		for participant: Variant in participants:
			if memory.get("participants", []).has(participant):
				participant_bonus += 1
		var age_turns: int = maxi(0, int(state.get("turn", 1)) - int(memory.get("turn", 1)))
		var current_influence: float = float(memory.get("emotionalImpact", 0.0)) * pow(float(memory.get("decayFactor", 0.98)), age_turns)
		var relevance: float = float(overlap * 2 + participant_bonus) + absf(current_influence)
		if relevance <= 0.0:
			continue
		var entry: Dictionary = memory.duplicate(true)
		entry["currentInfluence"] = snappedf(current_influence, 0.001)
		entry["relevanceScore"] = snappedf(relevance, 0.001)
		candidates.append(entry)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.get("relevanceScore", 0.0)) == float(b.get("relevanceScore", 0.0)):
			return int(a.get("turn", 0)) > int(b.get("turn", 0))
		return float(a.get("relevanceScore", 0.0)) > float(b.get("relevanceScore", 0.0))
	)
	if candidates.size() > limit:
		return candidates.slice(0, limit)
	return candidates

static func player_faction(state: Dictionary) -> Dictionary:
	for faction: Dictionary in state.get("factions", []):
		if faction.get("isPlayer", false):
			return faction
	return {}

static func connected_to(state: Dictionary, system_id: String) -> Array:
	var result: Array = []
	for lane: Dictionary in state.get("hyperlanes", []):
		if lane.get("startSystemId", "") == system_id:
			result.append(lane.get("endSystemId", ""))
		elif lane.get("endSystemId", "") == system_id:
			result.append(lane.get("startSystemId", ""))
	return result

static func relation_between(state: Dictionary, faction_a_id: String, faction_b_id: String) -> Dictionary:
	for relation: Dictionary in state.get("relationships", []):
		var a_matches: bool = relation.get("factionAId", "") == faction_a_id and relation.get("factionBId", "") == faction_b_id
		var b_matches: bool = relation.get("factionAId", "") == faction_b_id and relation.get("factionBId", "") == faction_a_id
		if a_matches or b_matches:
			return relation
	return {}

static func relation_breakdown(state: Dictionary, faction_a_id: String, faction_b_id: String) -> Dictionary:
	var relation: Dictionary = relation_between(state, faction_a_id, faction_b_id)
	if relation.is_empty():
		return {
			"trust": 0,
			"utility": 0,
			"fear": 0,
			"affinity": 0,
			"memoryImpact": 0,
			"level": "UNKNOWN"
		}
	return {
		"trust": int(relation.get("trust", 0)),
		"utility": int(relation.get("utility", 0)),
		"fear": int(relation.get("fear", 0)),
		"affinity": int(relation.get("affinity", 0)),
		"memoryImpact": int(relation.get("memoryImpact", 0)),
		"level": str(relation.get("level", "UNKNOWN"))
	}

static func relation_history_for_pair(state: Dictionary, faction_a_id: String, faction_b_id: String, limit: int = 6) -> Array:
	var result: Array = []
	for snapshot: Dictionary in state.get("relationshipHistory", []):
		var a_matches: bool = snapshot.get("factionAId", "") == faction_a_id and snapshot.get("factionBId", "") == faction_b_id
		var b_matches: bool = snapshot.get("factionAId", "") == faction_b_id and snapshot.get("factionBId", "") == faction_a_id
		if a_matches or b_matches:
			result.append(snapshot)
	result.reverse()
	if result.size() > limit:
		return result.slice(result.size() - limit, result.size())
	return result

static func relationship_trend_report(state: Dictionary, faction_a_id: String, faction_b_id: String, limit: int = 4) -> Dictionary:
	var history: Array = relation_history_for_pair(state, faction_a_id, faction_b_id, limit)
	var latest: Dictionary = relation_breakdown(state, faction_a_id, faction_b_id)
	if history.size() < 2:
		return {
			"history": history,
			"trust_delta": 0,
			"fear_delta": 0,
			"memory_delta": 0,
			"trust_rising": false,
			"trust_falling": false,
			"fear_rising": false,
			"opportunity_rising": false,
			"pressure_rising": false,
			"latest": latest
		}
	var previous: Dictionary = history[history.size() - 2]
	var trust_delta: int = int(latest.get("trust", 0)) - int(previous.get("trust", 0))
	var fear_delta: int = int(latest.get("fear", 0)) - int(previous.get("fear", 0))
	var memory_delta: int = int(latest.get("memoryImpact", 0)) - int(previous.get("memoryImpact", 0))
	return {
		"history": history,
		"trust_delta": trust_delta,
		"fear_delta": fear_delta,
		"memory_delta": memory_delta,
		"trust_rising": trust_delta > 0,
		"trust_falling": trust_delta < 0,
		"fear_rising": fear_delta > 0,
		"opportunity_rising": trust_delta > 0 and int(latest.get("utility", 0)) >= 15,
		"pressure_rising": fear_delta > 0 or trust_delta < 0 or memory_delta > 0,
		"latest": latest
	}

static func append_relationship_snapshots(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var history: Array = next_state.get("relationshipHistory", [])
	for relation: Dictionary in next_state.get("relationships", []):
		history.append({
			"turn": int(next_state.get("turn", 1)),
			"factionAId": relation.get("factionAId", ""),
			"factionBId": relation.get("factionBId", ""),
			"trust": int(relation.get("trust", 0)),
			"utility": int(relation.get("utility", 0)),
			"fear": int(relation.get("fear", 0)),
			"affinity": int(relation.get("affinity", 0)),
			"memoryImpact": int(relation.get("memoryImpact", 0)),
			"level": str(relation.get("level", "UNKNOWN"))
		})
	if history.size() > 60:
		history = history.slice(history.size() - 60, history.size())
	next_state["relationshipHistory"] = history
	return next_state

static func get_faction_by_id(state: Dictionary, faction_id: String) -> Dictionary:
	for faction: Dictionary in state.get("factions", []):
		if faction.get("id", "") == faction_id:
			return faction
	return {}

static func non_player_faction_ids(state: Dictionary) -> Array:
	var ids: Array = []
	for faction: Dictionary in state.get("factions", []):
		if not faction.get("isPlayer", false):
			ids.append(faction.get("id", ""))
	return ids

static func system_name_by_id(state: Dictionary, system_id: String) -> String:
	for system: Dictionary in state.get("starSystems", []):
		if system.get("id", "") == system_id:
			return str(system.get("name", system_id))
	return system_id

static func active_treaties_between(state: Dictionary, faction_a_id: String, faction_b_id: String) -> Array:
	var result: Array = []
	for treaty: Dictionary in state.get("treaties", []):
		if treaty.get("status", "") != "ACTIVE":
			continue
		var a_matches: bool = treaty.get("sourceFactionId", "") == faction_a_id and treaty.get("targetFactionId", "") == faction_b_id
		var b_matches: bool = treaty.get("sourceFactionId", "") == faction_b_id and treaty.get("targetFactionId", "") == faction_a_id
		if a_matches or b_matches:
			result.append(treaty)
	return result

static func active_treaties_for_faction(state: Dictionary, faction_id: String, treaty_type: String = "") -> Array:
	var result: Array = []
	for treaty: Dictionary in state.get("treaties", []):
		if treaty.get("status", "") != "ACTIVE":
			continue
		if treaty_type != "" and treaty.get("type", "") != treaty_type:
			continue
		if treaty.get("sourceFactionId", "") == faction_id or treaty.get("targetFactionId", "") == faction_id:
			result.append(treaty)
	return result

static func has_treaty(state: Dictionary, faction_a_id: String, faction_b_id: String, treaty_type: String) -> bool:
	for treaty: Dictionary in active_treaties_between(state, faction_a_id, faction_b_id):
		if treaty.get("type", "") == treaty_type:
			return true
	return false

static func owned_systems(state: Dictionary, faction_id: String) -> Array:
	var result: Array = []
	for system: Dictionary in state.get("starSystems", []):
		if system.get("ownerId", null) == faction_id:
			result.append(system)
	return result

static func add_resources(base: Dictionary, delta: Dictionary) -> Dictionary:
	return {
		"food": int(base.get("food", 0)) + int(delta.get("food", 0)),
		"minerals": int(base.get("minerals", 0)) + int(delta.get("minerals", 0)),
		"industry": int(base.get("industry", 0)) + int(delta.get("industry", 0)),
		"energy": int(base.get("energy", 0)) + int(delta.get("energy", 0))
	}

static func subtract_resources(base: Dictionary, delta: Dictionary) -> Dictionary:
	return {
		"food": int(base.get("food", 0)) - int(delta.get("food", 0)),
		"minerals": int(base.get("minerals", 0)) - int(delta.get("minerals", 0)),
		"industry": int(base.get("industry", 0)) - int(delta.get("industry", 0)),
		"energy": int(base.get("energy", 0)) - int(delta.get("energy", 0))
	}

static func can_afford(stock: Dictionary, cost: Dictionary) -> bool:
	return int(stock.get("food", 0)) >= int(cost.get("food", 0)) and int(stock.get("minerals", 0)) >= int(cost.get("minerals", 0)) and int(stock.get("industry", 0)) >= int(cost.get("industry", 0)) and int(stock.get("energy", 0)) >= int(cost.get("energy", 0))

static func find_building_blueprint(building_type: String) -> Dictionary:
	for blueprint: Dictionary in InitialDataScript.building_catalog():
		if blueprint.get("type", "") == building_type:
			return blueprint
	return {}

static func system_has_or_queued_building(state: Dictionary, system_id: String, building_type: String) -> bool:
	for system: Dictionary in state.get("starSystems", []):
		if system.get("id", "") != system_id:
			continue
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == building_type:
				return true
	for queue_item: Dictionary in state.get("constructionQueue", []):
		if queue_item.get("systemId", "") == system_id and queue_item.get("kind", "") == "BUILDING" and queue_item.get("targetId", "") == building_type:
			return true
	return false

static func queued_building_count_for_system(state: Dictionary, system_id: String) -> int:
	var count: int = 0
	for queue_item: Dictionary in state.get("constructionQueue", []):
		if queue_item.get("systemId", "") == system_id and queue_item.get("kind", "") == "BUILDING":
			count += 1
	return count

static func has_research(state: Dictionary, tech_id: String) -> bool:
	for tech: Dictionary in state.get("technologies", []):
		if tech.get("id", "") == tech_id and tech.get("status", "") == "RESEARCHED":
			return true
	return false

static func add_researched_tech_to_faction(state: Dictionary, faction_id: String, tech_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if tech_id == "":
		return next_state
	for faction_index: int in range(next_state.get("factions", []).size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") != faction_id:
			continue
		var researched_tech_ids: Array = faction.get("researchedTechIds", [])
		if not researched_tech_ids.has(tech_id):
			researched_tech_ids.append(tech_id)
		faction["researchedTechIds"] = researched_tech_ids
		next_state["factions"][faction_index] = faction
		break
	return next_state

static func colony_mode_data(mode: String) -> Dictionary:
	return InitialDataScript.colonization_modes().get(mode, {})

static func system_yield_multiplier(system: Dictionary) -> float:
	var colony_stage: String = system.get("colonyStage", "NONE")
	var multiplier: float = 1.0
	match colony_stage:
		"OUTPOST":
			multiplier = 0.45
		"COLONY":
			multiplier = 1.0
		"CORE":
			multiplier = 1.1
		_:
			multiplier = 1.0
	return multiplier + float(system.get("ascensionWonderBonus", 0.0))

static func scale_resources(bundle: Dictionary, multiplier: float) -> Dictionary:
	return {
		"food": int(round(float(bundle.get("food", 0)) * multiplier)),
		"minerals": int(round(float(bundle.get("minerals", 0)) * multiplier)),
		"industry": int(round(float(bundle.get("industry", 0)) * multiplier)),
		"energy": int(round(float(bundle.get("energy", 0)) * multiplier))
	}

static func apply_energy_shortage_penalty(bundle: Dictionary) -> Dictionary:
	var adjusted: Dictionary = bundle.duplicate(true)
	if int(adjusted.get("energy", 0)) >= 0:
		return adjusted
	adjusted["food"] = int(round(float(adjusted.get("food", 0)) * 0.5))
	adjusted["minerals"] = int(round(float(adjusted.get("minerals", 0)) * 0.5))
	adjusted["industry"] = int(round(float(adjusted.get("industry", 0)) * 0.5))
	return adjusted

static func colony_growth_speed(system: Dictionary, state: Dictionary) -> float:
	var mode: Dictionary = colony_mode_data(system.get("colonizationMode", "STANDARD"))
	var habitability_bonus: float = (float(system.get("habitability", 60)) - 50.0) / 100.0
	var supply_bonus: float = (float(system.get("supplyLevel", 50)) - 50.0) / 200.0
	var tech_bonus: float = 0.0
	if has_research(state, "tech_colony_charter"):
		tech_bonus += 0.25
	if has_research(state, "tech_expanded_housing"):
		tech_bonus += 0.1
	return 0.34 + float(mode.get("growth_bonus", 0.0)) + habitability_bonus + supply_bonus + tech_bonus

static func _colonization_preview_payload(mode_data: Dictionary, allowed: bool, reason: String) -> Dictionary:
	return {
		"allowed": allowed,
		"reason": reason,
		"cost": mode_data.get("cost", COLONY_COST),
		"turns": int(mode_data.get("turns", 0)),
		"initial_population": int(mode_data.get("initial_population", 0)),
		"initial_stability": int(mode_data.get("initial_stability", 0)),
		"initial_supply": int(mode_data.get("initial_supply", 0)),
		"slot_cap": int(mode_data.get("slot_cap", 0)),
		"maintenance": mode_data.get("maintenance", empty_resources()),
		"risk": str(mode_data.get("risk", "未知"))
	}

static func colonization_preview(state: Dictionary, fleet_id: String, system_id: String, mode: String) -> Dictionary:
	var player: Dictionary = player_faction(state)
	var fleet: Dictionary = {}
	var system: Dictionary = {}
	var mode_data: Dictionary = colony_mode_data(mode)
	if mode_data.is_empty():
		return _colonization_preview_payload({}, false, "殖民模式无效。")
	for entry: Dictionary in state.get("fleets", []):
		if entry.get("id", "") == fleet_id:
			fleet = entry
			break
	for entry: Dictionary in state.get("starSystems", []):
		if entry.get("id", "") == system_id:
			system = entry
			break
	if fleet.is_empty() or system.is_empty():
		return _colonization_preview_payload(mode_data, false, "未找到目标舰队或目标星系。")
	if fleet.get("ownerId", "") != player.get("id", "") or fleet.get("systemId", "") != system_id:
		return _colonization_preview_payload(mode_data, false, "殖民舰队必须位于目标星系内。")
	if str(fleet.get("mission", "IDLE")) == "COLONIZING":
		return _colonization_preview_payload(mode_data, false, "该舰队已经投入殖民部署，无法重复启动殖民。")
	if system.get("visibilityLevel", "") != "FULL":
		return _colonization_preview_payload(mode_data, false, "需要对目标星系拥有完整视野后才能殖民。")
	if system.get("ownerId", null) != null or system.get("colonyStage", "NONE") != "NONE":
		return _colonization_preview_payload(mode_data, false, "该星系已被占领或已经处于殖民流程中。")
	for other_fleet: Dictionary in state.get("fleets", []):
		if other_fleet.get("systemId", "") != system_id:
			continue
		if other_fleet.get("ownerId", "") == player.get("id", ""):
			continue
		return _colonization_preview_payload(mode_data, false, "目标星系正被敌对舰队封锁。")
	if not has_research(state, "tech_deep_colonization"):
		return _colonization_preview_payload(mode_data, false, "尚未完成深空殖民科技，无法执行殖民。")
	if not can_afford(player.get("resources", {}), mode_data.get("cost", COLONY_COST)):
		return _colonization_preview_payload(mode_data, false, "资源不足，无法启动殖民。")
	return _colonization_preview_payload(mode_data, true, "满足殖民条件。")

static func next_era(turn: int) -> String:
	if turn < 20:
		return "PIONEER"
	if turn < 50:
		return "EXPANSION"
	if turn < 100:
		return "CONFLICT"
	if turn < 150:
		return "UNIFICATION"
	return "ASCENSION"

static func relation_level(trust: int) -> String:
	if trust >= 80:
		return "SUPREME_ALLIANCE"
	if trust >= 60:
		return "ALLIED"
	if trust >= 20:
		return "NEUTRAL"
	if trust >= -19:
		return "COLD"
	if trust >= -59:
		return "TENSE"
	if trust >= -79:
		return "HOSTILE"
	return "BITTER_ENEMY"

static func add_message(state: Dictionary, title: String, content: String, message_type: String = "EVENT") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var messages: Array = next_state.get("messages", [])
	messages.push_front({
		"id": "msg_%s_%s" % [str(next_state.get("turn", 1)), str(messages.size() + 1)],
		"title": title,
		"content": content,
		"turn": next_state.get("turn", 1),
		"type": message_type
	})
	next_state["messages"] = messages
	return next_state

static func append_ai_action_record(state: Dictionary, faction_id: String, action_type: String, target_id: String, summary: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var faction: Dictionary = get_faction_by_id(next_state, faction_id)
	var log: Array = next_state.get("aiActionLog", [])
	log.push_front({
		"id": "ai_action_%s_%s" % [str(next_state.get("turn", 1)), str(log.size() + 1)],
		"turn": int(next_state.get("turn", 1)),
		"factionId": faction_id,
		"factionName": faction.get("name", faction_id),
		"actionType": action_type,
		"targetId": target_id,
		"summary": summary
	})
	next_state["aiActionLog"] = log
	return add_message(next_state, "AI 行动: %s" % faction.get("name", faction_id), summary, "AI_ACTION")

static func add_diplomatic_message(
	state: Dictionary,
	sender_id: String,
	target_ids: Array,
	target_type: String,
	visibility_level: String,
	content_type: String,
	title: String,
	content: String,
	visible_to_player: bool,
	attachments: Dictionary = {},
	security_settings: Dictionary = {}
) -> Dictionary:
	var next_state: Dictionary = _append_interaction_memory(state, title, content, [sender_id] + target_ids, content_type, maxi(1, target_ids.size()))
	var sender: Dictionary = get_faction_by_id(next_state, sender_id)
	var diplomatic_messages: Array = next_state.get("diplomaticMessages", [])
	diplomatic_messages.push_front({
		"id": "dmsg_%s_%s" % [str(next_state.get("turn", 1)), str(diplomatic_messages.size() + 1)],
		"turn": next_state.get("turn", 1),
		"senderId": sender_id,
		"senderName": sender.get("name", sender_id),
		"targetType": target_type,
		"targetIds": target_ids,
		"visibilityLevel": visibility_level,
		"contentType": content_type,
		"title": title,
		"content": content,
		"summary": title,
		"visibleToPlayer": visible_to_player,
		"attachments": attachments,
		"securitySettings": {
			"encryptionLevel": int(security_settings.get("encryptionLevel", 0)),
			"expiresAfterTurns": int(security_settings.get("expiresAfterTurns", 10))
		},
	})
	next_state["diplomaticMessages"] = diplomatic_messages
	return next_state

static func add_diplomatic_memory(
	state: Dictionary,
	title: String,
	summary: String,
	participants: Array,
	category: String = "EVENT",
	importance: int = 1
) -> Dictionary:
	var next_state: Dictionary = _append_interaction_memory(state, title, summary, participants, category, importance)
	var memories: Array = next_state.get("diplomaticMemories", [])
	memories.push_front({
		"id": "dmem_%s_%s" % [str(next_state.get("turn", 1)), str(memories.size() + 1)],
		"turn": next_state.get("turn", 1),
		"title": title,
		"summary": summary,
		"participants": participants,
		"category": category,
		"importance": importance,
		"relatedLongTermMemories": related_long_term_memories(next_state, "%s %s" % [title, summary], participants)
	})
	if memories.size() > 24:
		memories = memories.slice(0, 24)
	next_state["diplomaticMemories"] = memories
	return next_state

static func add_combat_report(
	state: Dictionary,
	title: String,
	attacker_name: String,
	defender_name: String,
	victory: bool,
	casualties: int,
	kills: int,
	remaining_power: int,
	tactical_notes: Array
) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var reports: Array = next_state.get("combatReports", [])
	reports.push_front({
		"id": "crep_%s_%s" % [str(next_state.get("turn", 1)), str(reports.size() + 1)],
		"turn": int(next_state.get("turn", 1)),
		"title": title,
		"attackerName": attacker_name,
		"defenderName": defender_name,
		"victory": victory,
		"casualties": casualties,
		"kills": kills,
		"remainingPower": remaining_power,
		"tacticalNotes": tactical_notes,
	})
	next_state["combatReports"] = reports
	return next_state

static func pending_proposals_for_player(state: Dictionary) -> Array:
	var result: Array = []
	for proposal: Dictionary in state.get("pendingProposals", []):
		if proposal.get("targetFactionId", "") == "f_player" and proposal.get("status", "PENDING") == "PENDING":
			result.append(proposal)
	return result

static func visible_diplomatic_memories_for_player(state: Dictionary) -> Array:
	var result: Array = []
	for memory: Dictionary in state.get("diplomaticMemories", []):
		var participants: Array = memory.get("participants", [])
		var memory_view: Dictionary = memory.duplicate(true)
		memory_view["relatedLongTermMemories"] = related_long_term_memories(state, "%s %s" % [str(memory.get("title", "")), str(memory.get("summary", ""))], participants)
		if participants.has("f_player") or memory.get("category", "") == "PUBLIC":
			result.append(memory_view)
			continue
		if int(memory.get("importance", 1)) >= 3:
			result.append(memory_view)
	return result

static func interception_capability(state: Dictionary) -> float:
	var capability: float = 0.1
	if has_research(state, "tech_deep_space_scans"):
		capability += 0.4
	if has_research(state, "tech_planetary_grid"):
		capability += 0.2
	var player_orchid_relation: Dictionary = relation_between(state, "f_player", "f_orchid")
	if int(player_orchid_relation.get("trust", 0)) >= 30:
		capability += 0.1
	return clamp(capability, 0.0, 0.95)

static func interception_report(state: Dictionary) -> Dictionary:
	var capability: float = interception_capability(state)
	var restricted_rate: int = int(round(clamp(capability + 0.08, 0.0, 0.9) * 100.0))
	var secret_rate: int = int(round(clamp(capability - 0.15, 0.0, 0.85) * 100.0))
	var encrypted_rate: int = int(round(clamp(capability - 0.35, 0.0, 0.85) * 100.0))
	return {
		"base": int(round(capability * 100.0)),
		"restricted": restricted_rate,
		"secret": secret_rate,
		"encrypted": encrypted_rate,
		"status": "截获能力优秀" if capability >= 0.65 else "截获能力稳定" if capability >= 0.35 else "截获能力薄弱"
	}

static func recent_intelligence_feed(state: Dictionary, limit: int = 10) -> Array:
	var feed: Array = []
	var visible_memories: Array = visible_diplomatic_memories_for_player(state)
	var visible_messages: Array = visible_diplomatic_messages_for_player(state)
	for report: Dictionary in state.get("combatReports", []):
		feed.append({
			"turn": int(report.get("turn", 0)),
			"priority": 5,
			"category": "COMBAT",
			"title": str(report.get("title", "战斗报告")),
			"summary": "%s vs %s / %s / 剩余战力 %s%%" % [
				str(report.get("attackerName", "进攻方")),
				str(report.get("defenderName", "防守方")),
				"进攻方获胜" if report.get("victory", false) else "防守方守住",
				str(report.get("remainingPower", 0))
			]
		})
	for event_item: Dictionary in state.get("activeNarrativeEvents", []):
		if event_item.get("status", "ACTIVE") != "ACTIVE":
			continue
		var event_system_name: String = str(event_item.get("systemId", "未知星系"))
		for system: Dictionary in state.get("starSystems", []):
			if system.get("id", "") == event_item.get("systemId", ""):
				event_system_name = str(system.get("name", event_system_name))
				break
		feed.append({
			"turn": int(event_item.get("turnCreated", state.get("turn", 1))),
			"priority": 4,
			"category": "EVENT",
			"title": str(event_item.get("title", "星系事件")),
			"summary": "%s / %s" % [event_system_name, str(event_item.get("summary", ""))]
		})
	for intervention: Dictionary in state.get("activeInterventions", []):
		if intervention.get("status", "ACTIVE") != "ACTIVE":
			continue
		feed.append({
			"turn": int(intervention.get("turnCreated", state.get("turn", 1))),
			"priority": 3,
			"category": "INTERVENTION",
			"title": str(intervention.get("type", "DIRECTOR")),
			"summary": "剩余回合 %s / 强度 %s" % [str(intervention.get("remainingTurns", 0)), str(intervention.get("intensity", 0.0))]
		})
	for memory: Dictionary in visible_memories.slice(0, min(6, visible_memories.size())):
		feed.append({
			"turn": int(memory.get("turn", 0)),
			"priority": 2 + int(memory.get("importance", 1)),
			"category": "DIPLOMACY",
			"title": str(memory.get("title", "外交记忆")),
			"summary": str(memory.get("summary", ""))
		})
	for message: Dictionary in visible_messages.slice(0, min(6, visible_messages.size())):
		feed.append({
			"turn": int(message.get("turn", 0)),
			"priority": 2,
			"category": "SIGNAL",
			"title": str(message.get("title", "截获信号")),
			"summary": "%s / %s" % [str(message.get("visibilityLevel", "PUBLIC")), str(message.get("content", ""))]
		})
	for message: Dictionary in state.get("messages", []).slice(0, min(6, state.get("messages", []).size())):
		feed.append({
			"turn": int(message.get("turn", 0)),
			"priority": 1,
			"category": str(message.get("type", "EVENT")),
			"title": str(message.get("title", "系统消息")),
			"summary": str(message.get("content", ""))
		})
	feed.sort_custom(_compare_intelligence_entry)
	if feed.size() > limit:
		return feed.slice(0, limit)
	return feed

static func _compare_intelligence_entry(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("turn", 0)) == int(b.get("turn", 0)):
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	return int(a.get("turn", 0)) > int(b.get("turn", 0))

static func parse_player_diplomatic_intent(message_text: String) -> Dictionary:
	var lowered: String = message_text.to_lower()
	if "限制" in message_text or "保持两跳" in message_text or "暂停边境扩张" in message_text or "停止扩张" in message_text:
		return {
			"type": "RESTRICTION",
			"restriction_kind": "FLEET_DISTANCE" if "舰队" in message_text or "两跳" in message_text else "BORDER_LIMIT",
			"tone": "firm",
			"trust_delta": -2
		}
	if "停火" in message_text or "互不侵犯" in message_text or "ceasefire" in lowered or "non aggression" in lowered:
		return {"type": "TREATY", "treaty": "NON_AGGRESSION", "tone": "friendly", "trust_delta": 6}
	if "科研协定" in message_text or "联合研究" in message_text or "research" in lowered:
		return {"type": "TREATY", "treaty": "RESEARCH_ACCORD", "tone": "friendly", "trust_delta": 5}
	if "同盟" in message_text or "结盟" in message_text or "alliance" in lowered:
		return {"type": "TREATY", "treaty": "ALLIANCE", "tone": "friendly", "trust_delta": 7}
	if "资源换停火" in message_text or ("停火" in message_text and ("资源" in message_text or "矿产" in message_text or "能源" in message_text)):
		return {"type": "TRADE", "trade_kind": "RESOURCE_FOR_CEASEFIRE", "tone": "friendly", "trust_delta": 4}
	if "科研互换" in message_text or "技术互换" in message_text or ("科研" in message_text and "交换" in message_text):
		return {"type": "TRADE", "trade_kind": "RESEARCH_EXCHANGE", "tone": "friendly", "trust_delta": 5}
	if "贸易" in message_text or "通商" in message_text or "trade" in lowered or "peace" in lowered or "和平" in message_text:
		return {"type": "TRADE", "trade_kind": "RESOURCE_TRADE", "tone": "friendly", "trust_delta": 5}
	if "进攻" in message_text or "宣战" in message_text or "威胁" in message_text or "attack" in lowered or "war" in lowered:
		return {"type": "WARNING", "tone": "firm", "trust_delta": -8}
	return {"type": "MESSAGE", "tone": "neutral", "trust_delta": 1}

static func describe_player_diplomatic_intent(message_text: String) -> Dictionary:
	var intent: Dictionary = parse_player_diplomatic_intent(message_text)
	var intent_type: String = str(intent.get("type", "MESSAGE"))
	var label: String = "普通致函"
	var detail: String = "这条信息会被视为常规外交接触，主要用于表达立场，不会直接触发条约或贸易意图。"
	if intent_type == "TREATY":
		var treaty_id: String = str(intent.get("treaty", "NON_AGGRESSION"))
		var treaty_label: String = InitialDataScript.treaty_labels().get(treaty_id, treaty_id)
		label = "条约提案"
		detail = "这条信息会被识别为对“%s”的正式提案，AI 会按当前关系、战略处境和人格倾向进行回应。" % treaty_label
	elif intent_type == "RESTRICTION":
		label = "限制请求"
		detail = "这条信息会被视为带条件的限制要求，AI 会重点评估压力、边境安全和可接受的退让空间。"
	elif intent_type == "TRADE":
		label = "交易提案"
		var trade_kind: String = str(intent.get("trade_kind", "RESOURCE_TRADE"))
		detail = "这条信息会被识别为交易导向接触，更容易触发资源交换和条件谈判。"
		if trade_kind == "RESOURCE_FOR_CEASEFIRE":
			detail = "这条信息会被识别为“资源换停火”提案，AI 会同时衡量现实利益与缓和局势的价值。"
		elif trade_kind == "RESEARCH_EXCHANGE":
			detail = "这条信息会被识别为“科研互换”提案，AI 会重点评估信任水平与技术泄露风险。"
	elif intent_type == "WARNING":
		label = "强硬警告"
		detail = "这条信息会被视为威胁或战争信号，通常会降低信任，并可能推动 AI 进入警戒或敌对姿态。"
	return {
		"label": label,
		"detail": detail,
		"tone": str(intent.get("tone", "neutral")),
		"trust_delta": int(intent.get("trust_delta", 0))
	}

static func should_intercept_message(state: Dictionary, sender_id: String, target_ids: Array, visibility_level: String) -> bool:
	if visibility_level == "PUBLIC":
		return true
	if sender_id == "f_player" or target_ids.has("f_player"):
		return true
	var chance: float = interception_capability(state)
	if visibility_level == "RESTRICTED":
		chance += 0.08
	elif visibility_level == "SECRET":
		chance -= 0.15
	elif visibility_level == "ENCRYPTED":
		chance -= 0.35
	chance = clamp(chance, 0.0, 0.85)
	var signature: String = "%s|%s|%s|%s" % [str(state.get("turn", 1)), sender_id, ",".join(target_ids), visibility_level]
	var roll: float = float(abs(signature.hash()) % 1000) / 1000.0
	return roll <= chance

static func visible_diplomatic_messages_for_player(state: Dictionary) -> Array:
	var result: Array = []
	for message: Dictionary in state.get("diplomaticMessages", []):
		if message.get("visibleToPlayer", false):
			result.append(message)
			continue
		if message.get("visibilityLevel", "PUBLIC") == "PUBLIC":
			result.append(message)
			continue
		var target_ids: Array = message.get("targetIds", [])
		if message.get("senderId", "") == "f_player" or target_ids.has("f_player"):
			result.append(message)
	return result

static func update_diplomatic_profile(state: Dictionary, faction_id: String, tone: String, trust_delta: int, private_agenda_hint: String = "") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][index]
		if faction.get("id", "") != faction_id:
			continue
		var profile: Dictionary = faction.get("diplomaticProfile", {}).duplicate(true)
		profile["recentTone"] = tone
		profile["trustBias"] = clamp(int(profile.get("trustBias", 0)) + trust_delta, -40, 40)
		if private_agenda_hint != "":
			profile["privateAgenda"] = private_agenda_hint
		profile["lastUpdatedTurn"] = next_state.get("turn", 1)
		faction["diplomaticProfile"] = profile
		var personality: Dictionary = faction.get("personality", {}).duplicate(true)
		personality["paranoia"] = clamp(float(personality.get("paranoia", 5.0)) + (-0.2 if trust_delta > 0 else 0.3 if trust_delta < 0 else 0.0), 0.0, 10.0)
		personality["loyalty"] = clamp(float(personality.get("loyalty", 5.0)) + (0.2 if trust_delta > 0 else -0.1 if trust_delta < 0 else 0.0), 0.0, 10.0)
		faction["personality"] = personality
		next_state["factions"][index] = faction
		break
	return next_state

static func create_pending_proposal(state: Dictionary, sender_id: String, target_id: String, proposal_type: String, title: String, summary: String, duration_turns: int = 4) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for proposal: Dictionary in next_state.get("pendingProposals", []):
		if proposal.get("senderFactionId", "") == sender_id and proposal.get("targetFactionId", "") == target_id and proposal.get("proposalType", "") == proposal_type and proposal.get("status", "PENDING") == "PENDING":
			return next_state
	var proposals: Array = next_state.get("pendingProposals", [])
	proposals.append({
		"id": "proposal_%s" % str(Time.get_ticks_msec()),
		"senderFactionId": sender_id,
		"targetFactionId": target_id,
		"proposalType": proposal_type,
		"title": title,
		"summary": summary,
		"status": "PENDING",
		"createdOnTurn": next_state.get("turn", 1),
		"expiresOnTurn": int(next_state.get("turn", 1)) + duration_turns
	})
	next_state["pendingProposals"] = proposals
	next_state = add_diplomatic_message(next_state, sender_id, [target_id], "SINGLE", "PUBLIC", "PROPOSAL", title, summary, true)
	next_state = add_diplomatic_memory(next_state, title, summary, [sender_id, target_id], "PROPOSAL", 2)
	return next_state

static func find_pending_proposal_id(state: Dictionary, sender_id: String, target_id: String, proposal_type: String) -> String:
	for proposal: Dictionary in state.get("pendingProposals", []):
		if proposal.get("senderFactionId", "") == sender_id and proposal.get("targetFactionId", "") == target_id and proposal.get("proposalType", "") == proposal_type and proposal.get("status", "PENDING") == "PENDING":
			return str(proposal.get("id", ""))
	return ""

static func end_war_between(state: Dictionary, faction_a_id: String, faction_b_id: String, summary: String = "") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var treaties: Array = next_state.get("treaties", [])
	for index: int in range(treaties.size()):
		var treaty: Dictionary = treaties[index]
		var touches: bool = (treaty.get("sourceFactionId", "") == faction_a_id and treaty.get("targetFactionId", "") == faction_b_id) or (treaty.get("sourceFactionId", "") == faction_b_id and treaty.get("targetFactionId", "") == faction_a_id)
		if not touches:
			continue
		if treaty.get("type", "") == "WAR_STATE" and treaty.get("status", "") == "ACTIVE":
			treaty["status"] = "ENDED"
			treaty["summary"] = "War ended"
			treaties[index] = treaty
	next_state["treaties"] = treaties
	if not has_treaty(next_state, faction_a_id, faction_b_id, "PEACE_TREATY"):
		var next_treaties: Array = next_state.get("treaties", [])
		next_treaties.append({
			"id": "treaty_%s" % str(Time.get_ticks_msec()),
			"sourceFactionId": faction_a_id,
			"targetFactionId": faction_b_id,
			"type": "PEACE_TREATY",
			"status": "ACTIVE",
			"proposedOnTurn": next_state.get("turn", 1),
			"expiresOnTurn": int(next_state.get("turn", 1)) + 10,
			"summary": summary if summary != "" else "Peace treaty accepted by both sides"
		})
		next_state["treaties"] = next_treaties
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches_relation: bool = (relation.get("factionAId", "") == faction_a_id and relation.get("factionBId", "") == faction_b_id) or (relation.get("factionAId", "") == faction_b_id and relation.get("factionBId", "") == faction_a_id)
		if not touches_relation:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) + 18, -100, 100)
		relation["trust"] = trust
		relation["tension"] = max(0, int(relation.get("tension", 0)) - 35)
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	next_state = add_diplomatic_memory(next_state, "和平达成", summary if summary != "" else "双方结束战争并签署了和平条款。", [faction_a_id, faction_b_id], "AGREEMENT", 3)
	return next_state

static func accept_pending_proposal(state: Dictionary, proposal_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var target_proposal: Dictionary = {}
	for index: int in range(next_state.get("pendingProposals", []).size()):
		var proposal: Dictionary = next_state["pendingProposals"][index]
		if proposal.get("id", "") != proposal_id or proposal.get("status", "PENDING") != "PENDING":
			continue
		proposal["status"] = "ACCEPTED"
		next_state["pendingProposals"][index] = proposal
		target_proposal = proposal
		break
	if target_proposal.is_empty():
		return next_state
	var sender_id: String = target_proposal.get("senderFactionId", "")
	var target_id: String = target_proposal.get("targetFactionId", "")
	var proposal_type: String = target_proposal.get("proposalType", "")
	if proposal_type == "ULTIMATUM":
		for index: int in range(next_state["relationships"].size()):
			var relation: Dictionary = next_state["relationships"][index]
			var touches: bool = (relation.get("factionAId", "") == sender_id and relation.get("factionBId", "") == target_id) or (relation.get("factionAId", "") == target_id and relation.get("factionBId", "") == sender_id)
			if not touches:
				continue
			var trust: int = clamp(int(relation.get("trust", 0)) - 6, -100, 100)
			relation["trust"] = trust
			relation["fear"] = int(relation.get("fear", 0)) + 10
			relation["tension"] = max(0, int(relation.get("tension", 0)) - 10)
			relation["level"] = relation_level(trust)
			next_state["relationships"][index] = relation
		next_state = add_diplomatic_memory(next_state, "最后通牒被接受", "%s 接受了最后通牒，战争暂时被避免。" % get_faction_by_id(next_state, target_id).get("name", target_id), [sender_id, target_id], "AGREEMENT", 2)
		return add_message(next_state, "最后通牒", "%s 接受了最后通牒，战争暂时被避免。" % get_faction_by_id(next_state, target_id).get("name", target_id), "DIPLOMATIC")
	if proposal_type == "PEACE_TALK":
		next_state = end_war_between(next_state, sender_id, target_id, target_proposal.get("summary", "双方已接受停火条件。"))
		return add_message(next_state, "和平达成", "%s" % target_proposal.get("summary", "双方已接受停火条件。"), "DIPLOMATIC")
	if proposal_type in ["TRADE_PACT", "NON_AGGRESSION", "RESEARCH_ACCORD", "ALLIANCE"] and not has_treaty(next_state, sender_id, target_id, proposal_type):
		var treaties: Array = next_state.get("treaties", [])
		treaties.append({
			"id": "treaty_%s" % str(Time.get_ticks_msec()),
			"sourceFactionId": sender_id,
			"targetFactionId": target_id,
			"type": proposal_type,
			"status": "ACTIVE",
			"proposedOnTurn": next_state.get("turn", 1),
			"expiresOnTurn": null if proposal_type == "ALLIANCE" else int(next_state.get("turn", 1)) + 12,
			"summary": target_proposal.get("summary", "")
		})
		next_state["treaties"] = treaties
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == sender_id and relation.get("factionBId", "") == target_id) or (relation.get("factionAId", "") == target_id and relation.get("factionBId", "") == sender_id)
		if not touches:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) + 12, -100, 100)
		relation["trust"] = trust
		relation["utility"] = int(relation.get("utility", 0)) + 6
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	next_state = update_diplomatic_profile(next_state, sender_id, "friendly", 6, "提案已被接受。")
	next_state = add_diplomatic_memory(next_state, "提案被接受", "%s 已被接受。" % target_proposal.get("title", "外交提案"), [sender_id, target_id], "AGREEMENT", 3)
	return add_message(next_state, "外交进展", "%s 接受了提案：%s" % [get_faction_by_id(next_state, target_id).get("name", target_id), target_proposal.get("title", "外交提案")], "DIPLOMATIC")

static func reject_pending_proposal(state: Dictionary, proposal_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var target_proposal: Dictionary = {}
	for index: int in range(next_state.get("pendingProposals", []).size()):
		var proposal: Dictionary = next_state["pendingProposals"][index]
		if proposal.get("id", "") != proposal_id or proposal.get("status", "PENDING") != "PENDING":
			continue
		proposal["status"] = "REJECTED"
		next_state["pendingProposals"][index] = proposal
		target_proposal = proposal
		break
	if target_proposal.is_empty():
		return next_state
	var sender_id: String = target_proposal.get("senderFactionId", "")
	var target_id: String = target_proposal.get("targetFactionId", "")
	var proposal_type: String = target_proposal.get("proposalType", "")
	if proposal_type == "ULTIMATUM":
		next_state = add_diplomatic_memory(next_state, "最后通牒被拒绝", "%s 的最后通牒遭到拒绝，战争随即爆发。" % get_faction_by_id(next_state, sender_id).get("name", sender_id), [sender_id, target_id], "WAR", 4)
		return declare_war_on_faction(next_state, sender_id, target_id)
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == sender_id and relation.get("factionBId", "") == target_id) or (relation.get("factionAId", "") == target_id and relation.get("factionBId", "") == sender_id)
		if not touches:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) - 8, -100, 100)
		relation["trust"] = trust
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	next_state = update_diplomatic_profile(next_state, sender_id, "firm", -5, "提案遭到拒绝。")
	next_state = add_diplomatic_memory(next_state, "提案被拒绝", "%s 被拒绝。" % target_proposal.get("title", "外交提案"), [sender_id, target_id], "PROPOSAL", 2)
	return add_message(next_state, "外交进展", "%s 拒绝了提案：%s" % [get_faction_by_id(next_state, target_id).get("name", target_id), target_proposal.get("title", "外交提案")], "DIPLOMATIC")

static func expire_pending_proposals(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var proposals: Array = next_state.get("pendingProposals", [])
	var changed: bool = false
	for index: int in range(proposals.size()):
		var proposal: Dictionary = proposals[index]
		if proposal.get("status", "PENDING") != "PENDING":
			continue
		if int(proposal.get("expiresOnTurn", 0)) > int(next_state.get("turn", 1)):
			continue
		proposal["status"] = "EXPIRED"
		proposals[index] = proposal
		changed = true
		next_state = add_diplomatic_memory(next_state, "提案过期", "%s 因超过期限而自动失效。" % proposal.get("title", "外交提案"), [proposal.get("senderFactionId", ""), proposal.get("targetFactionId", "")], "PROPOSAL", 1)
	if changed:
		next_state["pendingProposals"] = proposals
	return next_state

static func available_buildings(state: Dictionary) -> Array:
	var result: Array = []
	for building: Dictionary in InitialDataScript.building_catalog():
		if building.get("unlock_tech_id", "") == "" or has_research(state, building.get("unlock_tech_id", "")):
			result.append(building)
	return result

static func available_ship_types(state: Dictionary) -> Array:
	var ships: Array = ["CORVETTE"]
	if has_research(state, "tech_destroyer_hulls"):
		ships.append("DESTROYER")
	if has_research(state, "tech_cruiser_doctrine"):
		ships.append("CRUISER")
	if has_research(state, "tech_flagship_systems"):
		ships.append("BATTLESHIP")
	return ships

static func reachable_systems(state: Dictionary, fleet_id: String) -> Array:
	for fleet: Dictionary in state.get("fleets", []):
		if fleet.get("id", "") == fleet_id:
			return connected_to(state, fleet.get("systemId", ""))
	return []

static func reachable_system_details(state: Dictionary, fleet_id: String) -> Array:
	var fleet: Dictionary = {}
	for item: Dictionary in state.get("fleets", []):
		if item.get("id", "") == fleet_id:
			fleet = item
			break
	if fleet.is_empty():
		return []
	var current_system_id: String = str(fleet.get("systemId", ""))
	var result: Array = []
	for target_system_id: String in connected_to(state, current_system_id):
		for lane: Dictionary in state.get("hyperlanes", []):
			var direct: bool = lane.get("startSystemId", "") == current_system_id and lane.get("endSystemId", "") == target_system_id
			var reverse: bool = lane.get("endSystemId", "") == current_system_id and lane.get("startSystemId", "") == target_system_id
			if not (direct or reverse):
				continue
			result.append({
				"systemId": target_system_id,
				"systemName": system_name_by_id(state, target_system_id),
				"laneType": str(lane.get("type", "LANE")),
				"traversalCost": int(lane.get("traversalCost", 1)),
				"bandwidth": int(lane.get("bandwidth", 0)),
				"fleetSize": int(fleet.get("ships", []).size()),
				"fitsBandwidth": int(lane.get("bandwidth", 0)) <= 0 or int(fleet.get("ships", []).size()) <= int(lane.get("bandwidth", 0))
			})
			break
	return result

static func lane_traversal_cost(state: Dictionary, from_system_id: String, to_system_id: String) -> int:
	for lane: Dictionary in state.get("hyperlanes", []):
		var direct: bool = lane.get("startSystemId", "") == from_system_id and lane.get("endSystemId", "") == to_system_id
		var reverse: bool = lane.get("endSystemId", "") == from_system_id and lane.get("startSystemId", "") == to_system_id
		if direct or reverse:
			return int(lane.get("traversalCost", 1))
	return 1

static func progress_fleet_movement_cooldowns(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for fleet_index: int in range(next_state.get("fleets", []).size()):
		var fleet: Dictionary = next_state["fleets"][fleet_index]
		var cooldown: int = int(fleet.get("movementCooldown", 0))
		if cooldown <= 0:
			continue
		fleet["movementCooldown"] = cooldown - 1
		next_state["fleets"][fleet_index] = fleet
	return next_state

static func fleet_mission_label(mission: String) -> String:
	return str(InitialDataScript.fleet_mission_labels().get(mission, mission))

static func set_fleet_mission(state: Dictionary, fleet_id: String, mission: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var fleet_index: int = find_fleet_index(next_state, fleet_id)
	if fleet_index == -1:
		return next_state
	var fleet: Dictionary = next_state["fleets"][fleet_index]
	if fleet.get("ownerId", "") != "f_player":
		return next_state
	if str(fleet.get("mission", "IDLE")) == "COLONIZING" and mission != "COLONIZING":
		return add_message(next_state, "舰队正在殖民部署", "%s 正在建立殖民据点，部署完成前无法调整任务。" % str(fleet.get("name", "玩家舰队")), "SYSTEM")
	fleet["mission"] = mission
	next_state["fleets"][fleet_index] = fleet
	return add_message(next_state, "舰队任务已更新", "%s 当前任务调整为 %s。" % [str(fleet.get("name", "玩家舰队")), fleet_mission_label(mission)], "SYSTEM")

static func start_research(state: Dictionary, tech_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if next_state.get("status", "") != "PLAYING" or next_state.get("currentResearchId", null) != null:
		return next_state
	var player: Dictionary = player_faction(next_state)
	if player.is_empty():
		return next_state
	var technologies: Array = next_state.get("technologies", [])
	var target_index: int = -1
	for index: int in range(technologies.size()):
		if technologies[index].get("id", "") == tech_id:
			target_index = index
			break
	if target_index == -1:
		return next_state
	var target: Dictionary = technologies[target_index]
	if target.get("status", "") != "AVAILABLE":
		return next_state
	if int(player.get("resources", {}).get("industry", 0)) < int(target.get("cost", 0)):
		return next_state
	for index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][index]
		if faction.get("id", "") == player.get("id", ""):
			var resources: Dictionary = faction.get("resources", {}).duplicate(true)
			resources["industry"] = int(resources.get("industry", 0)) - int(target.get("cost", 0))
			faction["resources"] = resources
			next_state["factions"][index] = faction
	technologies[target_index]["status"] = "RESEARCHING"
	technologies[target_index]["progress"] = 0.0
	next_state["technologies"] = technologies
	next_state["currentResearchId"] = tech_id
	next_state["researchProgress"] = 0.0
	return add_message(next_state, "研究已启动", "当前开始研究 %s。" % target.get("name", ""), "SYSTEM")

static func cancel_research(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var current_research_id: Variant = next_state.get("currentResearchId", null)
	if next_state.get("status", "") != "PLAYING" or current_research_id == null:
		return next_state
	var player: Dictionary = player_faction(next_state)
	var technologies: Array = next_state.get("technologies", [])
	for index: int in range(technologies.size()):
		var tech: Dictionary = technologies[index]
		if tech.get("id", "") != str(current_research_id):
			continue
		var refund: int = int(ceil(float(tech.get("cost", 0)) * 0.5))
		for faction_index: int in range(next_state["factions"].size()):
			var faction: Dictionary = next_state["factions"][faction_index]
			if faction.get("id", "") == player.get("id", ""):
				var resources: Dictionary = faction.get("resources", {}).duplicate(true)
				resources["industry"] = int(resources.get("industry", 0)) + refund
				faction["resources"] = resources
				next_state["factions"][faction_index] = faction
		tech["status"] = "AVAILABLE"
		tech["progress"] = 0.0
		technologies[index] = tech
		next_state["technologies"] = technologies
		next_state["currentResearchId"] = null
		next_state["researchProgress"] = 0.0
		return add_message(next_state, "研究已取消", "%s 已取消研究，返还 %s 工业。" % [tech.get("name", ""), str(refund)], "SYSTEM")
	return next_state

static func ship_stats(ship_type: String, state: Dictionary, owner_id: String) -> Dictionary:
	var player_bonus: bool = owner_id == "f_player" and has_research(state, "tech_shipyard")
	match ship_type:
		"DESTROYER":
			return {"hp": 165, "maxHp": 165, "damage": 34, "evasion": 20, "tracking": 58, "speed": 8 + (1 if player_bonus else 0)}
		"CRUISER":
			return {"hp": 250, "maxHp": 250, "damage": 52, "evasion": 14, "tracking": 62, "speed": 7 + (1 if player_bonus else 0)}
		"BATTLESHIP":
			return {"hp": 360, "maxHp": 360, "damage": 74, "evasion": 10, "tracking": 70, "speed": 6 + (1 if player_bonus else 0)}
		_:
			return {"hp": 115 if player_bonus else 100, "maxHp": 115 if player_bonus else 100, "damage": 24 if player_bonus else 20, "evasion": 30, "tracking": 50, "speed": 10}

static func create_ship(ship_type: String, name: String, state: Dictionary, owner_id: String) -> Dictionary:
	var stats: Dictionary = ship_stats(ship_type, state, owner_id)
	return {
		"id": make_state_id(state, "ship"),
		"type": ship_type,
		"name": name,
		"hp": stats["hp"],
		"maxHp": stats["maxHp"],
		"damage": stats["damage"],
		"evasion": stats["evasion"],
		"tracking": stats["tracking"],
		"speed": stats["speed"]
	}

static func ship_cost(ship_type: String, state: Dictionary, owner_id: String) -> Dictionary:
	var player_discount: bool = owner_id == "f_player" and has_research(state, "tech_shipyard")
	if ship_type == "BATTLESHIP":
		return {"food": 45, "minerals": 128 if player_discount else 145, "industry": 118 if player_discount else 132, "energy": 40}
	if ship_type == "CRUISER":
		return {"food": 30, "minerals": 88 if player_discount else 100, "industry": 80 if player_discount else 90, "energy": 28}
	if ship_type == "DESTROYER":
		return {"food": 18, "minerals": 44 if player_discount else 50, "industry": 36 if player_discount else 40, "energy": 16}
	return {"food": 10, "minerals": 24 if player_discount else 30, "industry": 20 if player_discount else 25, "energy": 10}

static func fleet_power(fleet: Dictionary) -> float:
	var total: float = 0.0
	for ship: Dictionary in fleet.get("ships", []):
		total += float(ship.get("damage", 0)) + float(ship.get("hp", 0)) / 10.0
	return total

static func fleet_needs_repair(fleet: Dictionary) -> bool:
	for ship: Dictionary in fleet.get("ships", []):
		if int(ship.get("hp", 0)) < int(ship.get("maxHp", 0)):
			return true
	return false

static func repair_cost_for_fleet(fleet: Dictionary) -> Dictionary:
	var missing_hp: int = 0
	for ship: Dictionary in fleet.get("ships", []):
		missing_hp += int(ship.get("maxHp", 0)) - int(ship.get("hp", 0))
	return {"food": 0, "minerals": int(ceil(float(missing_hp) / 12.0)), "industry": int(ceil(float(missing_hp) / 14.0)), "energy": int(ceil(float(missing_hp) / 18.0))}

static func damage_fleet(fleet: Dictionary, amount: int) -> Dictionary:
	var next_fleet: Dictionary = fleet.duplicate(true)
	for index: int in range(next_fleet["ships"].size()):
		var ship: Dictionary = next_fleet["ships"][index]
		ship["hp"] = max(20, int(ship.get("hp", 0)) - amount)
		next_fleet["ships"][index] = ship
	return next_fleet

static func ship_type_count(fleet: Dictionary, ship_type: String) -> int:
	var total: int = 0
	for ship: Dictionary in fleet.get("ships", []):
		if ship.get("type", "") == ship_type:
			total += 1
	return total

static func system_defense_power(state: Dictionary, system_id: String, owner_id: String) -> int:
	for system: Dictionary in state.get("starSystems", []):
		if system.get("id", "") != system_id or system.get("ownerId", null) != owner_id:
			continue
		var power: int = 0
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "DEFENSE_PLATFORM":
				power += 28
		return power
	return 0

static func nearest_friendly_system_id(state: Dictionary, faction_id: String, from_system_id: String) -> String:
	var visited: Dictionary = {from_system_id: true}
	var frontier: Array = [from_system_id]
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for adjacent: String in connected_to(state, current):
			if visited.has(adjacent):
				continue
			visited[adjacent] = true
			for system: Dictionary in state.get("starSystems", []):
				if system.get("id", "") == adjacent and system.get("ownerId", null) == faction_id:
					return adjacent
			frontier.append(adjacent)
	return ""

static func find_fleet_index(state: Dictionary, fleet_id: String) -> int:
	for index: int in range(state.get("fleets", []).size()):
		if state["fleets"][index].get("id", "") == fleet_id:
			return index
	return -1

static func player_fleets_in_system(state: Dictionary, system_id: String, owner_id: String = "f_player") -> Array:
	var result: Array = []
	for fleet: Dictionary in state.get("fleets", []):
		if fleet.get("ownerId", "") == owner_id and fleet.get("systemId", "") == system_id:
			result.append(fleet)
	return result

static func split_fleet(state: Dictionary, fleet_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var fleet_index: int = find_fleet_index(next_state, fleet_id)
	if fleet_index == -1:
		return next_state
	var fleet: Dictionary = next_state["fleets"][fleet_index]
	if fleet.get("ownerId", "") != "f_player":
		return next_state
	if str(fleet.get("mission", "IDLE")) == "COLONIZING":
		return add_message(next_state, "分舰队失败", "%s 正在殖民部署，部署完成前无法拆分。" % str(fleet.get("name", "玩家舰队")), "SYSTEM")
	var ships: Array = fleet.get("ships", [])
	if ships.size() < 2:
		return add_message(next_state, "分舰队失败", "舰队至少需要 2 艘舰船才能执行分舰队。", "SYSTEM")
	var split_count: int = maxi(1, int(floor(float(ships.size()) / 2.0)))
	var detached: Array = []
	var remain: Array = []
	for index: int in range(ships.size()):
		if index < split_count:
			detached.append(ships[index])
		else:
			remain.append(ships[index])
	fleet["ships"] = remain
	next_state["fleets"][fleet_index] = fleet
	var new_fleet: Dictionary = {
		"id": "fleet_split_%s" % str(Time.get_ticks_msec()),
		"name": "%s-分舰队" % str(fleet.get("name", "玩家舰队")),
		"ownerId": fleet.get("ownerId", ""),
		"systemId": fleet.get("systemId", ""),
		"mission": fleet.get("mission", "IDLE"),
		"ships": detached
	}
	var fleets: Array = next_state.get("fleets", [])
	fleets.append(new_fleet)
	next_state["fleets"] = fleets
	return add_message(next_state, "分舰队完成", "%s 已拆分出一支新的舰队。" % str(fleet.get("name", "玩家舰队")), "EVENT")

static func merge_player_fleets(state: Dictionary, system_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player_fleets: Array = player_fleets_in_system(next_state, system_id, "f_player")
	if player_fleets.size() < 2:
		return add_message(next_state, "合并舰队失败", "同一星系内至少需要 2 支玩家舰队才能执行合并。", "SYSTEM")
	for fleet: Dictionary in player_fleets:
		if str(fleet.get("mission", "IDLE")) == "COLONIZING":
			return add_message(next_state, "合并舰队失败", "%s 正在殖民部署，部署完成前无法合并。" % str(fleet.get("name", "玩家舰队")), "SYSTEM")
	var keeper_id: String = str(player_fleets[0].get("id", ""))
	var keeper_index: int = find_fleet_index(next_state, keeper_id)
	var merged_ships: Array = []
	for fleet: Dictionary in player_fleets:
		for ship: Dictionary in fleet.get("ships", []):
			merged_ships.append(ship)
	var retained_fleets: Array = []
	for fleet: Dictionary in next_state.get("fleets", []):
		if fleet.get("ownerId", "") == "f_player" and fleet.get("systemId", "") == system_id and fleet.get("id", "") != keeper_id:
			continue
		retained_fleets.append(fleet)
	next_state["fleets"] = retained_fleets
	keeper_index = find_fleet_index(next_state, keeper_id)
	if keeper_index != -1:
		var keeper: Dictionary = next_state["fleets"][keeper_index]
		keeper["ships"] = merged_ships
		keeper["name"] = "%s联合舰队" % system_name_by_id(next_state, system_id)
		next_state["fleets"][keeper_index] = keeper
	return add_message(next_state, "联合舰队已整编", "%s 的玩家舰队已合并为一支联合舰队。" % system_name_by_id(next_state, system_id), "EVENT")

static func queue_structure(state: Dictionary, system_id: String, building_type: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var system_index: int = -1
	var target_system: Dictionary = {}
	for index: int in range(next_state.get("starSystems", []).size()):
		var system: Dictionary = next_state["starSystems"][index]
		if system.get("id", "") == system_id:
			target_system = system
			system_index = index
			break
	if system_index == -1 or target_system.get("ownerId", null) != player.get("id", ""):
		return next_state
	var blueprint: Dictionary = {}
	for item: Dictionary in available_buildings(next_state):
		if item.get("type", "") == building_type:
			blueprint = item
			break
	if blueprint.is_empty():
		return next_state
	if int(target_system.get("buildings", []).size()) + queued_building_count_for_system(next_state, system_id) >= int(target_system.get("buildingSlots", 0)):
		return add_message(next_state, "建筑排队失败", "%s 的建筑格位已满，无法继续加入新建筑。" % target_system.get("name", system_id), "SYSTEM")
	for building: Dictionary in target_system.get("buildings", []):
		if building.get("type", "") == building_type and building_type == "SHIPYARD":
			return add_message(next_state, "建筑排队失败", "%s 已拥有太空船坞，无法重复建造。" % target_system.get("name", system_id), "SYSTEM")
	for item: Dictionary in next_state.get("constructionQueue", []):
		if item.get("systemId", "") == system_id and item.get("targetId", "") == building_type:
			return add_message(next_state, "建筑排队失败", "%s 已在当前建造队列中。" % blueprint.get("name", building_type), "SYSTEM")
	if not can_afford(player.get("resources", {}), blueprint.get("cost", {})):
		return add_message(next_state, "建筑排队失败", "资源不足，无法将该建筑加入建造队列。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			faction["resources"] = subtract_resources(faction.get("resources", {}), blueprint.get("cost", {}))
			next_state["factions"][faction_index] = faction
	var queue_item: Dictionary = {
		"id": make_state_id(next_state, "queue"),
		"systemId": system_id,
		"ownerId": player.get("id", ""),
		"kind": "BUILDING",
		"targetId": building_type,
		"displayName": blueprint.get("name", ""),
		"turnsRemaining": InitialDataScript.building_turns().get(building_type, 1),
		"totalTurns": InitialDataScript.building_turns().get(building_type, 1)
	}
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append(queue_item)
	next_state["constructionQueue"] = queue
	return add_message(next_state, "建筑已加入队列", "%s 已开始排队建造 %s。" % [target_system.get("name", ""), blueprint.get("name", "")], "SYSTEM")

static func queue_ship_construction(state: Dictionary, system_id: String, ship_type: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var target_system: Dictionary = {}
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("id", "") == system_id:
			target_system = system
			break
	if target_system.is_empty() or target_system.get("ownerId", null) != player.get("id", ""):
		return next_state
	var has_shipyard: bool = false
	for building: Dictionary in target_system.get("buildings", []):
		if building.get("type", "") == "SHIPYARD":
			has_shipyard = true
			break
	if not has_shipyard:
		return add_message(next_state, "舰船排队失败", "%s 尚未建成太空船坞，无法建造舰船。" % target_system.get("name", system_id), "SYSTEM")
	if not available_ship_types(next_state).has(ship_type):
		return add_message(next_state, "舰船排队失败", "当前科技尚未解锁该舰船。", "SYSTEM")
	var cost: Dictionary = ship_cost(ship_type, next_state, player.get("id", ""))
	if not can_afford(player.get("resources", {}), cost):
		return add_message(next_state, "舰船排队失败", "资源不足，无法开始建造该舰船。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			faction["resources"] = subtract_resources(faction.get("resources", {}), cost)
			next_state["factions"][faction_index] = faction
	var queue_item: Dictionary = {
		"id": make_state_id(next_state, "queue"),
		"systemId": system_id,
		"ownerId": player.get("id", ""),
		"kind": "SHIP",
		"targetId": ship_type,
		"displayName": InitialDataScript.ship_labels().get(ship_type, ship_type),
		"turnsRemaining": InitialDataScript.ship_turns().get(ship_type, 1),
		"totalTurns": InitialDataScript.ship_turns().get(ship_type, 1)
	}
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append(queue_item)
	next_state["constructionQueue"] = queue
	return add_message(next_state, "舰船已加入队列", "%s 已开始建造 %s。" % [target_system.get("name", ""), InitialDataScript.ship_labels().get(ship_type, ship_type)], "SYSTEM")

static func repair_fleet(state: Dictionary, fleet_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var fleet_index: int = -1
	var fleet: Dictionary = {}
	for index: int in range(next_state.get("fleets", []).size()):
		var item: Dictionary = next_state["fleets"][index]
		if item.get("id", "") == fleet_id and item.get("ownerId", "") == player.get("id", ""):
			fleet_index = index
			fleet = item
			break
	if fleet_index == -1 or not fleet_needs_repair(fleet):
		return next_state
	var system: Dictionary = {}
	for entry: Dictionary in next_state.get("starSystems", []):
		if entry.get("id", "") == fleet.get("systemId", ""):
			system = entry
			break
	if system.is_empty() or system.get("ownerId", null) != player.get("id", ""):
		return next_state
	var cost: Dictionary = repair_cost_for_fleet(fleet)
	if not can_afford(player.get("resources", {}), cost):
		return add_message(next_state, "舰队修理失败", "资源不足，无法执行当前舰队修理。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			faction["resources"] = subtract_resources(faction.get("resources", {}), cost)
			next_state["factions"][faction_index] = faction
	var repaired_fleet: Dictionary = fleet.duplicate(true)
	for ship_index: int in range(repaired_fleet["ships"].size()):
		var ship: Dictionary = repaired_fleet["ships"][ship_index]
		ship["hp"] = ship.get("maxHp", 0)
		repaired_fleet["ships"][ship_index] = ship
	next_state["fleets"][fleet_index] = repaired_fleet
	return add_message(next_state, "舰队修理完成", "%s 已在 %s 完成修理并恢复战备。" % [fleet.get("name", ""), system.get("name", "")], "SYSTEM")

static func trade_with_faction(state: Dictionary, target_faction_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var target: Dictionary = {}
	for faction: Dictionary in next_state.get("factions", []):
		if faction.get("id", "") == target_faction_id:
			target = faction
			break
	var relation: Dictionary = relation_between(next_state, player.get("id", ""), target_faction_id)
	if target.is_empty() or relation.is_empty():
		return next_state
	for index: int in range(next_state["relationships"].size()):
		var item: Dictionary = next_state["relationships"][index]
		var touches: bool = (item.get("factionAId", "") == player.get("id", "") and item.get("factionBId", "") == target_faction_id) or (item.get("factionAId", "") == target_faction_id and item.get("factionBId", "") == player.get("id", ""))
		if not touches:
			continue
		var trust: int = min(100, int(item.get("trust", 0)) + 15)
		item["trust"] = trust
		item["utility"] = int(item.get("utility", 0)) + 10
		item["level"] = relation_level(trust)
		next_state["relationships"][index] = item
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			var res: Dictionary = faction.get("resources", {}).duplicate(true)
			res["minerals"] = int(res.get("minerals", 0)) + 20
			res["energy"] = int(res.get("energy", 0)) + 10
			faction["resources"] = res
			next_state["factions"][faction_index] = faction
	if not has_treaty(next_state, player.get("id", ""), target_faction_id, "TRADE_PACT"):
		var treaties: Array = next_state.get("treaties", [])
		treaties.append({
			"id": "treaty_%s" % str(Time.get_ticks_msec()),
			"sourceFactionId": player.get("id", ""),
			"targetFactionId": target_faction_id,
			"type": "TRADE_PACT",
			"status": "ACTIVE",
			"proposedOnTurn": next_state.get("turn", 1),
			"expiresOnTurn": null,
			"summary": "双方建立贸易协定。"
		})
		next_state["treaties"] = treaties
	next_state = update_diplomatic_profile(next_state, target_faction_id, "friendly", 6, "愿意通过贸易改善双边关系。")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "PROPOSAL", "贸易协定已签署", "双方已建立贸易协定，后续将获得稳定资源往来。", true)
	next_state = add_diplomatic_memory(next_state, "贸易协定成立", "玩家与目标势力建立了新的贸易合作。", [player.get("id", ""), target_faction_id], "AGREEMENT", 2)
	return add_message(next_state, "外交进展", "你与 %s 正式签署了贸易协定。" % target.get("name", ""), "DIPLOMATIC")

static func threaten_faction(state: Dictionary, target_faction_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var target_name: String = target_faction_id
	for faction: Dictionary in next_state.get("factions", []):
		if faction.get("id", "") == target_faction_id:
			target_name = faction.get("name", "")
			break
	for index: int in range(next_state["relationships"].size()):
		var item: Dictionary = next_state["relationships"][index]
		var touches: bool = (item.get("factionAId", "") == player.get("id", "") and item.get("factionBId", "") == target_faction_id) or (item.get("factionAId", "") == target_faction_id and item.get("factionBId", "") == player.get("id", ""))
		if not touches:
			continue
		var trust: int = max(-100, int(item.get("trust", 0)) - 20)
		item["trust"] = trust
		item["fear"] = int(item.get("fear", 0)) + 15
		item["level"] = relation_level(trust)
		next_state["relationships"][index] = item
	for index: int in range(next_state["treaties"].size()):
		var treaty: Dictionary = next_state["treaties"][index]
		var touches: bool = (treaty.get("sourceFactionId", "") == player.get("id", "") and treaty.get("targetFactionId", "") == target_faction_id) or (treaty.get("sourceFactionId", "") == target_faction_id and treaty.get("targetFactionId", "") == player.get("id", ""))
		if not touches or treaty.get("status", "") != "ACTIVE" or treaty.get("type", "") == "TRADE_PACT":
			continue
		treaty["status"] = "BROKEN"
		treaty["summary"] = "%s 已因威胁而破裂。" % treaty.get("summary", "")
		next_state["treaties"][index] = treaty
	next_state = update_diplomatic_profile(next_state, target_faction_id, "firm", -8, "认为玩家正在提高外交与军事压力。")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "WARNING", "最后通牒", "玩家向该势力发出了公开警告。", true)
	next_state = add_diplomatic_memory(next_state, "公开威胁", "玩家对目标势力发出了明确威胁。", [player.get("id", ""), target_faction_id], "WARNING", 2)
	return add_message(next_state, "外交施压", "你已向 %s 发出强硬警告。" % target_name, "DIPLOMATIC")

static func revoke_treaty(state: Dictionary, target_faction_id: String, treaty_type: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var changed: bool = false
	for index: int in range(next_state["treaties"].size()):
		var treaty: Dictionary = next_state["treaties"][index]
		var touches: bool = (treaty.get("sourceFactionId", "") == player.get("id", "") and treaty.get("targetFactionId", "") == target_faction_id) or (treaty.get("sourceFactionId", "") == target_faction_id and treaty.get("targetFactionId", "") == player.get("id", ""))
		if not touches or treaty.get("status", "") != "ACTIVE" or treaty.get("type", "") != treaty_type:
			continue
		treaty["status"] = "BROKEN"
		treaty["summary"] = "该条约已被单方面废止。"
		next_state["treaties"][index] = treaty
		changed = true
	if not changed:
		return next_state
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches_relation: bool = (relation.get("factionAId", "") == player.get("id", "") and relation.get("factionBId", "") == target_faction_id) or (relation.get("factionAId", "") == target_faction_id and relation.get("factionBId", "") == player.get("id", ""))
		if not touches_relation:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) - 12, -100, 100)
		relation["trust"] = trust
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	var treaty_label: String = InitialDataScript.treaty_labels().get(treaty_type, treaty_type)
	next_state = update_diplomatic_profile(next_state, target_faction_id, "hostile", -6, "认为玩家不再愿意维持既有承诺。")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "NOTIFICATION", "条约废止通知", "玩家已正式废止 %s。" % treaty_label, true)
	next_state = add_diplomatic_memory(next_state, "条约终止", "玩家终止了与目标势力之间的现行条约。", [player.get("id", ""), target_faction_id], "TREATY", 2)
	return add_message(next_state, "条约终止", "你已废止 %s。" % treaty_label, "DIPLOMATIC")

static func declare_war_on_faction(state: Dictionary, source_faction_id: String, target_faction_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var source_name: String = source_faction_id
	var target_name: String = target_faction_id
	for faction: Dictionary in next_state.get("factions", []):
		if faction.get("id", "") == source_faction_id:
			source_name = faction.get("name", source_name)
		elif faction.get("id", "") == target_faction_id:
			target_name = faction.get("name", target_name)
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == source_faction_id and relation.get("factionBId", "") == target_faction_id) or (relation.get("factionAId", "") == target_faction_id and relation.get("factionBId", "") == source_faction_id)
		if not touches:
			continue
		relation["trust"] = -100
		relation["fear"] = int(relation.get("fear", 0)) + 25
		relation["tension"] = int(relation.get("tension", 0)) + 35
		relation["level"] = "BITTER_ENEMY"
		next_state["relationships"][index] = relation
	for index: int in range(next_state["treaties"].size()):
		var treaty: Dictionary = next_state["treaties"][index]
		var touches_treaty: bool = (treaty.get("sourceFactionId", "") == source_faction_id and treaty.get("targetFactionId", "") == target_faction_id) or (treaty.get("sourceFactionId", "") == target_faction_id and treaty.get("targetFactionId", "") == source_faction_id)
		if not touches_treaty or treaty.get("status", "") != "ACTIVE":
			continue
		treaty["status"] = "BROKEN"
		treaty["summary"] = "双方关系已升级为战争状态。"
		next_state["treaties"][index] = treaty
	if not has_treaty(next_state, source_faction_id, target_faction_id, "WAR_STATE"):
		var treaties: Array = next_state.get("treaties", [])
		treaties.append({
			"id": "treaty_%s" % str(Time.get_ticks_msec()),
			"sourceFactionId": source_faction_id,
			"targetFactionId": target_faction_id,
			"type": "WAR_STATE",
			"status": "ACTIVE",
			"proposedOnTurn": next_state.get("turn", 1),
			"expiresOnTurn": null,
			"summary": "双方进入战争状态。"
		})
		next_state["treaties"] = treaties
	next_state = update_diplomatic_profile(next_state, source_faction_id, "hostile", -10, "已将对方视为直接军事对手。")
	next_state = update_diplomatic_profile(next_state, target_faction_id, "hostile", -10, "已将对方视为直接军事对手。")
	next_state = add_diplomatic_message(next_state, source_faction_id, [target_faction_id], "BROADCAST", "PUBLIC", "WARNING", "战争宣告", "%s 已对 %s 宣战。" % [source_name, target_name], true)
	next_state = add_diplomatic_memory(next_state, "战争爆发", "%s 与 %s 已进入公开战争状态。" % [source_name, target_name], [source_faction_id, target_faction_id], "WAR", 4)
	return add_message(next_state, "战争爆发", "%s 已对 %s 宣战。" % [source_name, target_name], "DIPLOMATIC")

static func treaty_acceptance(state: Dictionary, treaty_type: String, target_faction_id: String) -> Dictionary:
	var player: Dictionary = player_faction(state)
	var relation: Dictionary = relation_between(state, player.get("id", ""), target_faction_id)
	var trust: int = int(relation.get("trust", 0))
	var requires_tech: bool = treaty_type == "TRADE_PACT" or has_research(state, "tech_diplomatic_protocols")
	if not requires_tech:
		return {"accepted": false, "reason": "尚未完成外交协议相关科技，对方不会接受这类正式条约。"}
	if treaty_type == "TRADE_PACT" and trust >= -10:
		return {"accepted": true, "reason": "对方认为贸易互利且风险可控，因此愿意接受贸易协定。"}
	if treaty_type == "NON_AGGRESSION" and trust >= 10:
		return {"accepted": true, "reason": "双方关系达到可缓和区间，对方愿意签署互不侵犯条约。"}
	if treaty_type == "RESEARCH_ACCORD" and trust >= 30:
		return {"accepted": true, "reason": "对方信任度足够，愿意开放科研合作并共享研究收益。"}
	if treaty_type == "ALLIANCE" and trust >= 65:
		return {"accepted": true, "reason": "双方已形成高度信任，对方愿意进入正式同盟关系。"}
	return {"accepted": false, "reason": "当前信任度或战略环境不足，对方拒绝了这份条约提案。"}

static func propose_treaty(state: Dictionary, target_faction_id: String, treaty_type: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	if has_treaty(next_state, player.get("id", ""), target_faction_id, treaty_type):
		return next_state
	var target_name: String = target_faction_id
	for faction: Dictionary in next_state.get("factions", []):
		if faction.get("id", "") == target_faction_id:
			target_name = faction.get("name", "")
			break
	var verdict: Dictionary = treaty_acceptance(next_state, treaty_type, target_faction_id)
	var accepted: bool = verdict.get("accepted", false)
	var treaties: Array = next_state.get("treaties", [])
	treaties.append({
		"id": "treaty_%s" % str(Time.get_ticks_msec()),
		"sourceFactionId": player.get("id", ""),
		"targetFactionId": target_faction_id,
		"type": treaty_type,
		"status": "ACTIVE" if accepted else "REJECTED",
		"proposedOnTurn": next_state.get("turn", 1),
		"expiresOnTurn": null if treaty_type == "ALLIANCE" else int(next_state.get("turn", 1)) + 12,
		"summary": verdict.get("reason", "")
	})
	next_state["treaties"] = treaties
	var trust_delta: int = 18 if accepted and treaty_type == "ALLIANCE" else 10 if accepted else -6
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == player.get("id", "") and relation.get("factionBId", "") == target_faction_id) or (relation.get("factionAId", "") == target_faction_id and relation.get("factionBId", "") == player.get("id", ""))
		if not touches:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) + trust_delta, -100, 100)
		relation["trust"] = trust
		relation["utility"] = int(relation.get("utility", 0)) + (8 if accepted else -2)
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	var treaty_label: String = InitialDataScript.treaty_labels().get(treaty_type, treaty_type)
	next_state = update_diplomatic_profile(next_state, target_faction_id, "friendly" if accepted else "firm", 4 if accepted else -4, "玩家发起条约提案")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "PROPOSAL", treaty_label, "玩家提出条约：%s。" % treaty_label, true)
	next_state = add_diplomatic_memory(next_state, "条约提案", "已向 %s 发出条约提案：%s。" % [target_name, treaty_label], [player.get("id", ""), target_faction_id], "PROPOSAL", 2)
	if accepted:
		return add_message(next_state, treaty_label, "%s 接受了 %s。%s" % [target_name, treaty_label, verdict.get("reason", "")], "DIPLOMATIC")
	return add_message(next_state, "条约被拒绝", "%s 拒绝了 %s。%s" % [target_name, treaty_label, verdict.get("reason", "")], "DIPLOMATIC")

static func send_ultimatum(state: Dictionary, target_faction_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var target_name: String = get_faction_by_id(next_state, target_faction_id).get("name", target_faction_id)
	if has_treaty(next_state, player.get("id", ""), target_faction_id, "WAR_STATE"):
		return next_state
	var relation: Dictionary = relation_between(next_state, player.get("id", ""), target_faction_id)
	var intimidation_score: int = int(relation.get("fear", 0)) + int(relation.get("trust", 0)) / 2 + int(relation.get("utility", 0)) / 3
	next_state = create_pending_proposal(next_state, player.get("id", ""), target_faction_id, "ULTIMATUM", "最后通牒", "玩家要求 %s 立即让步，否则战争将立刻爆发。" % target_name, 2)
	var proposal_id: String = find_pending_proposal_id(next_state, player.get("id", ""), target_faction_id, "ULTIMATUM")
	if intimidation_score < 45:
		next_state = reject_pending_proposal(next_state, proposal_id)
		return add_message(next_state, "最后通牒", "%s 拒绝了最后通牒，危机升级为战争。" % target_name, "DIPLOMATIC")
	next_state = accept_pending_proposal(next_state, proposal_id)
	return add_message(next_state, "最后通牒", "%s 接受了最后通牒，战争暂时被避免。" % target_name, "DIPLOMATIC")

static func propose_peace_talk(state: Dictionary, target_faction_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	if not has_treaty(next_state, player.get("id", ""), target_faction_id, "WAR_STATE"):
		return next_state
	var target_name: String = get_faction_by_id(next_state, target_faction_id).get("name", target_faction_id)
	var relation: Dictionary = relation_between(next_state, player.get("id", ""), target_faction_id)
	var willingness: int = int(relation.get("fear", 0)) + int(relation.get("utility", 0)) / 2 - int(relation.get("tension", 0)) / 3
	next_state = create_pending_proposal(next_state, player.get("id", ""), target_faction_id, "PEACE_TALK", "停火谈判", "玩家向 %s 提出停火与和平谈判。" % target_name, 3)
	var proposal_id: String = find_pending_proposal_id(next_state, player.get("id", ""), target_faction_id, "PEACE_TALK")
	if willingness >= 18:
		next_state = accept_pending_proposal(next_state, proposal_id)
		return add_message(next_state, "停火谈判", "%s 接受了停火提议，双方恢复和平。" % target_name, "DIPLOMATIC")
	return add_message(next_state, "停火谈判", "%s 已收到和平提议，正在评估之中。" % target_name, "DIPLOMATIC")

static func unlock_technologies(technologies: Array) -> Array:
	var updated: Array = []
	for technology: Dictionary in technologies:
		var next_tech: Dictionary = technology.duplicate(true)
		var prerequisites: Array = next_tech.get("prerequisites", [])
		if next_tech.get("status", "") == "LOCKED" and not prerequisites.is_empty():
			var unlocked: bool = true
			for requirement: String in prerequisites:
				var found: bool = false
				for other: Dictionary in technologies:
					if other.get("id", "") == requirement and other.get("status", "") == "RESEARCHED":
						found = true
						break
				if not found:
					unlocked = false
					break
			if unlocked:
				next_tech["status"] = "AVAILABLE"
		updated.append(next_tech)
	return updated

static func player_research_speed(state: Dictionary) -> float:
	var speed: float = 1.0
	for system: Dictionary in owned_systems(state, "f_player"):
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "RESEARCH_LAB":
				speed += 0.4
	if has_research(state, "tech_research_lab"):
		speed += 0.35
	for treaty: Dictionary in active_treaties_for_faction(state, "f_player", "RESEARCH_ACCORD"):
		speed += 0.3
	return speed

static func progress_research(state: Dictionary) -> Dictionary:
	var current_research_id: Variant = state.get("currentResearchId", null)
	var technologies: Array = state.get("technologies", []).duplicate(true)
	if current_research_id == null:
		return {"technologies": unlock_technologies(technologies), "currentResearchId": null, "researchProgress": 0.0, "completedName": null}
	for index: int in range(technologies.size()):
		var tech: Dictionary = technologies[index]
		if tech.get("id", "") != str(current_research_id):
			continue
		var progress_gain: float = (100.0 / float(tech.get("researchTime", 1))) * player_research_speed(state)
		var progress: float = min(100.0, float(tech.get("progress", 0.0)) + progress_gain)
		var completed: bool = progress >= 100.0
		tech["progress"] = progress
		tech["status"] = "RESEARCHED" if completed else "RESEARCHING"
		technologies[index] = tech
		return {"technologies": unlock_technologies(technologies), "currentResearchId": null if completed else tech.get("id", ""), "researchProgress": 0.0 if completed else progress, "completedName": tech.get("name", "") if completed else null, "completedId": tech.get("id", "") if completed else ""}
	return {"technologies": unlock_technologies(technologies), "currentResearchId": null, "researchProgress": 0.0, "completedName": null, "completedId": ""}

static func faction_yield(state: Dictionary, faction_id: String) -> Dictionary:
	var bundle: Dictionary = empty_resources()
	for system: Dictionary in owned_systems(state, faction_id):
		var multiplier: float = system_yield_multiplier(system)
		bundle = add_resources(bundle, scale_resources(system.get("resources", {}), multiplier))
		for building: Dictionary in system.get("buildings", []):
			bundle = add_resources(bundle, scale_resources(building.get("production", {}), multiplier))
			bundle = add_resources(bundle, building.get("maintenance", {}))
	if has_research(state, "tech_trade_net"):
		bundle["energy"] = int(bundle.get("energy", 0)) + owned_systems(state, faction_id).size() * 2
		bundle["minerals"] = int(bundle.get("minerals", 0)) + owned_systems(state, faction_id).size()
	if faction_id == "f_player":
		for _treaty: Dictionary in active_treaties_for_faction(state, "f_player", "TRADE_PACT"):
			bundle["energy"] = int(bundle.get("energy", 0)) + 3
			bundle["minerals"] = int(bundle.get("minerals", 0)) + 2
		for _accord: Dictionary in active_treaties_for_faction(state, "f_player", "RESEARCH_ACCORD"):
			bundle["industry"] = int(bundle.get("industry", 0)) + 2
	return apply_energy_shortage_penalty(bundle)

static func faction_resource_breakdown(state: Dictionary, faction_id: String, resource_key: String) -> Dictionary:
	var base_production: Dictionary = empty_resources()
	var building_maintenance: Dictionary = empty_resources()
	var fleet_maintenance: Dictionary = empty_resources()
	var treaty_modifier: Dictionary = empty_resources()
	var owned: Array = owned_systems(state, faction_id)
	for system: Dictionary in owned:
		var multiplier: float = system_yield_multiplier(system)
		base_production = add_resources(base_production, scale_resources(system.get("resources", {}), multiplier))
		for building: Dictionary in system.get("buildings", []):
			base_production = add_resources(base_production, scale_resources(building.get("production", {}), multiplier))
			building_maintenance = add_resources(building_maintenance, building.get("maintenance", {}))
	if has_research(state, "tech_trade_net"):
		treaty_modifier["energy"] = int(treaty_modifier.get("energy", 0)) + owned.size() * 2
		treaty_modifier["minerals"] = int(treaty_modifier.get("minerals", 0)) + owned.size()
	if faction_id == "f_player":
		for _treaty: Dictionary in active_treaties_for_faction(state, "f_player", "TRADE_PACT"):
			treaty_modifier["energy"] = int(treaty_modifier.get("energy", 0)) + 3
			treaty_modifier["minerals"] = int(treaty_modifier.get("minerals", 0)) + 2
		for _accord: Dictionary in active_treaties_for_faction(state, "f_player", "RESEARCH_ACCORD"):
			treaty_modifier["industry"] = int(treaty_modifier.get("industry", 0)) + 2
	var combined: Dictionary = add_resources(add_resources(base_production, building_maintenance), add_resources(fleet_maintenance, treaty_modifier))
	var net: Dictionary = apply_energy_shortage_penalty(combined)
	var residual: int = int(net.get(resource_key, 0)) - int(combined.get(resource_key, 0))
	if residual != 0:
		fleet_maintenance[resource_key] = int(fleet_maintenance.get(resource_key, 0)) + residual
		combined = add_resources(add_resources(base_production, building_maintenance), add_resources(fleet_maintenance, treaty_modifier))
		net = apply_energy_shortage_penalty(combined)
	return {
		"base_production": int(base_production.get(resource_key, 0)),
		"building_maintenance": int(building_maintenance.get(resource_key, 0)),
		"fleet_maintenance": int(fleet_maintenance.get(resource_key, 0)),
		"treaty_modifier": int(treaty_modifier.get(resource_key, 0)),
		"net": int(net.get(resource_key, 0)),
	}

static func apply_faction_economy(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][index]
		var yield_bundle: Dictionary = faction_yield(next_state, faction.get("id", ""))
		faction["resources"] = add_resources(faction.get("resources", {}), yield_bundle)
		faction["resourceRates"] = yield_bundle
		next_state["factions"][index] = faction
	return next_state

static func apply_passive_repairs(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for fleet_index: int in range(next_state["fleets"].size()):
		var fleet: Dictionary = next_state["fleets"][fleet_index]
		for system: Dictionary in next_state.get("starSystems", []):
			if system.get("id", "") != fleet.get("systemId", "") or system.get("ownerId", null) != fleet.get("ownerId", ""):
				continue
			var repair_amount: int = 5
			for building: Dictionary in system.get("buildings", []):
				if building.get("type", "") == "SHIPYARD":
					repair_amount = 12
			for ship_index: int in range(fleet["ships"].size()):
				var ship: Dictionary = fleet["ships"][ship_index]
				ship["hp"] = min(int(ship.get("maxHp", 0)), int(ship.get("hp", 0)) + repair_amount)
				fleet["ships"][ship_index] = ship
			next_state["fleets"][fleet_index] = fleet
	return next_state

static func complete_queue_item(state: Dictionary, item: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if item.get("kind", "") == "BUILDING":
		for blueprint: Dictionary in InitialDataScript.building_catalog():
			if blueprint.get("type", "") != item.get("targetId", ""):
				continue
			for system_index: int in range(next_state["starSystems"].size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") == item.get("systemId", ""):
					var building: Dictionary = blueprint.duplicate(true)
					building["id"] = make_state_id(next_state, "building")
					var buildings: Array = system.get("buildings", [])
					buildings.append(building)
					system["buildings"] = buildings
					next_state["starSystems"][system_index] = system
					return add_message(next_state, "建筑完工", "%s 已在 %s 完成建造。" % [item.get("displayName", ""), system.get("name", "")], "EVENT")
	else:
		var ship_type: String = item.get("targetId", "")
		var ship: Dictionary = create_ship(ship_type, "%s级舰" % InitialDataScript.ship_labels().get(ship_type, ship_type), next_state, item.get("ownerId", ""))
		for fleet_index: int in range(next_state["fleets"].size()):
			var fleet: Dictionary = next_state["fleets"][fleet_index]
			if fleet.get("ownerId", "") == item.get("ownerId", "") and fleet.get("systemId", "") == item.get("systemId", ""):
				var ships: Array = fleet.get("ships", [])
				ships.append(ship)
				fleet["ships"] = ships
				next_state["fleets"][fleet_index] = fleet
				return add_message(next_state, "舰船建造完成", "%s 已加入当前驻留舰队。" % item.get("displayName", ""), "EVENT")
		var fleets: Array = next_state.get("fleets", [])
		fleets.append({"id": make_state_id(next_state, "fleet"), "ownerId": item.get("ownerId", ""), "systemId": item.get("systemId", ""), "name": "%s 防卫舰队" % item.get("systemId", ""), "ships": [ship]})
		if not fleets.is_empty():
			fleets[fleets.size() - 1]["mission"] = "IDLE"
		next_state["fleets"] = fleets
		return add_message(next_state, "舰船建造完成", "%s 已作为新舰队投入部署。" % item.get("displayName", ""), "EVENT")
	return next_state

static func queue_turn_bonus(state: Dictionary, system_id: String) -> int:
	for system: Dictionary in state.get("starSystems", []):
		if system.get("id", "") != system_id:
			continue
		var bonus: int = 0
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "SHIPYARD":
				bonus += 1
			if building.get("type", "") == "INTEGRATED_FACTORY":
				bonus += 1
		if has_research(state, "tech_auto_assembly"):
			bonus += 1
		return bonus
	return 0

static func advance_construction_queue(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var updated_queue: Array = []
	for item: Dictionary in state.get("constructionQueue", []):
		var reduced: int = max(0, int(item.get("turnsRemaining", 0)) - 1 - queue_turn_bonus(next_state, item.get("systemId", "")))
		if reduced <= 0:
			next_state = complete_queue_item(next_state, item)
		else:
			var updated_item: Dictionary = item.duplicate(true)
			updated_item["turnsRemaining"] = reduced
			updated_queue.append(updated_item)
	next_state["constructionQueue"] = updated_queue
	return next_state

static func default_ascension_project() -> Dictionary:
	return {
		"stage": "INACTIVE",
		"siteSystemId": "",
		"siteSystemName": "",
		"foundationTurnsRemaining": 30,
		"chargeProgress": 0,
		"chargeRequired": 120,
		"finalTurnsRemaining": 15,
		"globallyVisible": false,
		"blockedReason": "",
		"lastBlockedTurn": 0
	}

static func ascension_project_data(state: Dictionary) -> Dictionary:
	var project: Dictionary = default_ascension_project()
	project.merge(state.get("ascensionProject", {}), true)
	return project

static func best_ascension_site(state: Dictionary, faction_id: String = "f_player") -> Dictionary:
	var best_site: Dictionary = {}
	var best_value: int = -999999
	for system: Dictionary in owned_systems(state, faction_id):
		if system.get("colonyStage", "NONE") == "OUTPOST":
			continue
		var site_value: int = int(system.get("habitability", 0)) + int(system.get("population", 0)) / 10 + int(system.get("migrationPull", 0)) + int(system.get("stability", 0)) / 5
		if site_value > best_value:
			best_value = site_value
			best_site = system
	return best_site

static func ascension_charge_cost(state: Dictionary) -> Dictionary:
	var base_cost: Dictionary = {"food": 0, "minerals": 18, "industry": 24, "energy": 30}
	var lab_count: int = 0
	for system: Dictionary in owned_systems(state, "f_player"):
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "RESEARCH_LAB":
				lab_count += 1
	base_cost["energy"] = max(18, int(base_cost.get("energy", 0)) - mini(8, lab_count * 2))
	if has_treaty(state, "f_player", "f_merchant", "RESEARCH_ACCORD"):
		base_cost["minerals"] = max(12, int(base_cost.get("minerals", 0)) - 4)
	return base_cost

static func ascension_charge_gain(state: Dictionary) -> int:
	var gain: int = 8
	if has_research(state, "tech_star_harmonics"):
		gain += 10
	if has_research(state, "tech_singularity_lattice"):
		gain += 18
	if has_treaty(state, "f_player", "f_merchant", "RESEARCH_ACCORD"):
		gain += 6
	for system: Dictionary in owned_systems(state, "f_player"):
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "RESEARCH_LAB":
				gain += 2
	return gain

static func set_ascension_site_bonus(state: Dictionary, system_id: String, active: bool, stage_name: String = "") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for system_index: int in range(next_state.get("starSystems", []).size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") == system_id and active:
			system["ascensionWonderBonus"] = 0.5
			system["ascensionWonderStage"] = stage_name
			system["ascensionWonderVisible"] = true
		else:
			system["ascensionWonderBonus"] = 0.0
			if system.has("ascensionWonderStage"):
				system.erase("ascensionWonderStage")
			system["ascensionWonderVisible"] = false
		next_state["starSystems"][system_index] = system
	return next_state

static func update_ascension_progress(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var project: Dictionary = ascension_project_data(next_state)
	var just_started: bool = false
	if project.get("stage", "INACTIVE") == "INACTIVE":
		if has_research(next_state, "tech_star_harmonics") and has_research(next_state, "tech_singularity_lattice"):
			var site: Dictionary = best_ascension_site(next_state, "f_player")
			if not site.is_empty():
				project["stage"] = "FOUNDATION"
				project["siteSystemId"] = site.get("id", "")
				project["siteSystemName"] = site.get("name", site.get("id", ""))
				project["foundationTurnsRemaining"] = 30
				project["chargeProgress"] = 0
				project["chargeRequired"] = 120
				project["finalTurnsRemaining"] = 15
				project["globallyVisible"] = true
				project["blockedReason"] = ""
				project["lastBlockedTurn"] = 0
				next_state = add_message(next_state, "飞升计划启动", "帝国已在 %s 启动文明飞升计划，进入 30 回合的基座铺设阶段。该星系现已成为全银河关注焦点。" % project.get("siteSystemName", "未知星系"), "SYSTEM")
				just_started = true
	if project.get("stage", "INACTIVE") == "FOUNDATION":
		if not just_started:
			project["foundationTurnsRemaining"] = max(0, int(project.get("foundationTurnsRemaining", 30)) - 1)
		if int(project.get("foundationTurnsRemaining", 0)) <= 0:
			project["stage"] = "CORE_CHARGING"
			project["chargeProgress"] = 0
			project["blockedReason"] = ""
			next_state = set_ascension_site_bonus(next_state, str(project.get("siteSystemId", "")), true, "CORE_CHARGING")
			next_state = add_message(next_state, "飞升基座完成", "%s 的飞升基座已完成，星系产出提升 50%，进入核心充能阶段。" % project.get("siteSystemName", "未知星系"), "SYSTEM")
	elif project.get("stage", "") == "CORE_CHARGING":
		var charge_cost: Dictionary = ascension_charge_cost(next_state)
		var player: Dictionary = player_faction(next_state)
		if can_afford(player.get("resources", {}), charge_cost):
			for faction_index: int in range(next_state.get("factions", []).size()):
				var faction: Dictionary = next_state["factions"][faction_index]
				if not faction.get("isPlayer", false):
					continue
				faction["resources"] = subtract_resources(faction.get("resources", {}), charge_cost)
				next_state["factions"][faction_index] = faction
				break
			project["chargeProgress"] = min(int(project.get("chargeRequired", 120)), int(project.get("chargeProgress", 0)) + ascension_charge_gain(next_state))
			project["blockedReason"] = ""
			if int(project.get("chargeProgress", 0)) >= int(project.get("chargeRequired", 120)):
				project["stage"] = "FINAL_LAUNCH"
				project["finalTurnsRemaining"] = 15
				next_state = set_ascension_site_bonus(next_state, str(project.get("siteSystemId", "")), true, "FINAL_LAUNCH")
				next_state = add_message(next_state, "飞升核心就绪", "%s 的奇观核心已完成充能，进入最后 15 回合的启动保护期。" % project.get("siteSystemName", "未知星系"), "SYSTEM")
		else:
			project["blockedReason"] = "RESOURCE_SHORTAGE"
			if int(next_state.get("turn", 1)) - int(project.get("lastBlockedTurn", 0)) >= 3:
				next_state = add_message(next_state, "飞升充能受阻", "文明飞升计划因资源不足暂停充能。当前每回合至少需要 矿产 %s / 工业 %s / 能源 %s。" % [str(charge_cost.get("minerals", 0)), str(charge_cost.get("industry", 0)), str(charge_cost.get("energy", 0))], "SYSTEM")
				project["lastBlockedTurn"] = int(next_state.get("turn", 1))
	elif project.get("stage", "") == "FINAL_LAUNCH":
		project["finalTurnsRemaining"] = max(0, int(project.get("finalTurnsRemaining", 15)) - 1)
		if int(project.get("finalTurnsRemaining", 0)) <= 0:
			project["stage"] = "COMPLETED"
			project["globallyVisible"] = true
			next_state = set_ascension_site_bonus(next_state, str(project.get("siteSystemId", "")), true, "COMPLETED")
			next_state = add_message(next_state, "飞升启动完成", "%s 的最终启动窗口已经闭合，文明飞升计划宣告成功。" % project.get("siteSystemName", "未知星系"), "SYSTEM")
	elif project.get("stage", "") == "COMPLETED":
		next_state = set_ascension_site_bonus(next_state, str(project.get("siteSystemId", "")), true, "COMPLETED")
	var stage_progress: int = 0
	match str(project.get("stage", "INACTIVE")):
		"FOUNDATION":
			stage_progress = int(round((30.0 - float(project.get("foundationTurnsRemaining", 30))) / 30.0 * 34.0))
		"CORE_CHARGING":
			stage_progress = 34 + int(round(float(project.get("chargeProgress", 0)) / max(1.0, float(project.get("chargeRequired", 120))) * 33.0))
		"FINAL_LAUNCH":
			stage_progress = 67 + int(round((15.0 - float(project.get("finalTurnsRemaining", 15))) / 15.0 * 33.0))
		"COMPLETED":
			stage_progress = 100
		_:
			stage_progress = 0
	next_state["ascensionProject"] = project
	next_state["ascension_progress"] = clamp(stage_progress, 0, 100)
	return next_state

static func expire_treaties(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var treaties: Array = next_state.get("treaties", [])
	var changed: bool = false
	for index: int in range(treaties.size()):
		var treaty: Dictionary = treaties[index]
		if treaty.get("status", "") != "ACTIVE":
			continue
		var expires_raw: Variant = treaty.get("expiresOnTurn", 0)
		var expires_on: int = int(expires_raw) if expires_raw != null else 0
		if expires_on <= 0 or expires_on > int(next_state.get("turn", 1)):
			continue
		treaty["status"] = "EXPIRED"
		treaties[index] = treaty
		changed = true
		next_state = add_message(next_state, "条约到期", "%s 已达到有效期并自动失效。" % treaty.get("name", "外交条约"), "DIPLOMATIC")
	if changed:
		next_state["treaties"] = treaties
	return next_state

static func default_galactic_council() -> Dictionary:
	return {
		"established": false,
		"speakerFactionId": "",
		"speakerTitle": "未设立",
		"charterStatus": "INACTIVE",
		"charterVotesFor": [],
		"charterVotesAgainst": [],
		"lastVoteTurn": 0
	}

static func galactic_council_data(state: Dictionary) -> Dictionary:
	var council: Dictionary = default_galactic_council()
	council.merge(state.get("galacticCouncil", {}), true)
	return council

static func diplomatic_influence_score(state: Dictionary, faction_id: String) -> int:
	var score: int = 0
	for faction: Dictionary in state.get("factions", []):
		if faction.get("id", "") == faction_id:
			score += int(faction.get("population", 0)) / 40
			score += int(faction.get("technologyLevel", 0)) * 3
			break
	for other: Dictionary in state.get("factions", []):
		var other_id: String = other.get("id", "")
		if other_id == faction_id:
			continue
		if has_treaty(state, faction_id, other_id, "ALLIANCE"):
			score += 20
		if has_treaty(state, faction_id, other_id, "RESEARCH_ACCORD"):
			score += 12
		if has_treaty(state, faction_id, other_id, "NON_AGGRESSION"):
			score += 8
		if has_treaty(state, faction_id, other_id, "WAR_STATE"):
			score -= 18
		var relation: Dictionary = relation_breakdown(state, faction_id, other_id)
		score += int(relation.get("trust", 0)) / 8
		score += int(relation.get("utility", 0)) / 10
		score -= int(relation.get("fear", 0)) / 10
	return score

static func council_vote_for_player(state: Dictionary, faction_id: String) -> bool:
	if faction_id == "f_player":
		return true
	if has_treaty(state, "f_player", faction_id, "WAR_STATE"):
		return false
	var relation: Dictionary = relation_breakdown(state, "f_player", faction_id)
	var support_score: int = int(relation.get("trust", 0)) + int(relation.get("utility", 0)) - int(relation.get("fear", 0))
	if has_treaty(state, "f_player", faction_id, "ALLIANCE"):
		support_score += 24
	if has_treaty(state, "f_player", faction_id, "RESEARCH_ACCORD"):
		support_score += 14
	if has_treaty(state, "f_player", faction_id, "NON_AGGRESSION"):
		support_score += 10
	return support_score >= 28

static func update_galactic_council(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var council: Dictionary = galactic_council_data(next_state)
	var diplomacy_report: Dictionary = player_diplomatic_victory_report(next_state)
	var player_ready_for_council: bool = has_research(next_state, "tech_federal_council") and int(diplomacy_report.get("peace_partners", 0)) >= maxi(1, int(ceil(float(diplomacy_report.get("total_rivals", 0)) * 0.5)))
	if not bool(council.get("established", false)) and player_ready_for_council:
		council["established"] = true
		council["speakerFactionId"] = "f_player"
		council["speakerTitle"] = "泛星际联合国议长"
		next_state = add_message(next_state, "联合国成立", "在多边和平网络支撑下，泛星际联合国已成立，你成为首任议长。", "DIPLOMATIC")
	if bool(council.get("established", false)):
		var best_speaker_id: String = str(council.get("speakerFactionId", "f_player"))
		var best_score: int = -999999
		for faction: Dictionary in next_state.get("factions", []):
			var faction_id: String = faction.get("id", "")
			var score: int = diplomatic_influence_score(next_state, faction_id)
			if score > best_score:
				best_score = score
				best_speaker_id = faction_id
		council["speakerFactionId"] = best_speaker_id
		var speaker_name: String = get_faction_by_id(next_state, best_speaker_id).get("name", best_speaker_id)
		council["speakerTitle"] = "%s议长" % speaker_name
		if best_speaker_id == "f_player" and str(council.get("charterStatus", "INACTIVE")) == "INACTIVE" and int(diplomacy_report.get("peace_partners", 0)) >= int(diplomacy_report.get("total_rivals", 0)):
			council["charterStatus"] = "VOTING"
			next_state = add_message(next_state, "和平统一宪章", "你已以议长身份提交和平统一宪章，银河各势力开始表决。", "DIPLOMATIC")
		if str(council.get("charterStatus", "")) == "VOTING" and best_speaker_id == "f_player":
			var votes_for: Array = []
			var votes_against: Array = []
			for faction: Dictionary in next_state.get("factions", []):
				var faction_id: String = faction.get("id", "")
				if council_vote_for_player(next_state, faction_id):
					votes_for.append(faction_id)
				else:
					votes_against.append(faction_id)
			council["charterVotesFor"] = votes_for
			council["charterVotesAgainst"] = votes_against
			council["lastVoteTurn"] = int(next_state.get("turn", 1))
			var required_votes: int = maxi(1, int(ceil(float(next_state.get("factions", []).size()) * (2.0 / 3.0))))
			if votes_for.size() >= required_votes:
				council["charterStatus"] = "PASSED"
				next_state = add_message(next_state, "和平统一宪章通过", "和平统一宪章已取得 %s/%s 票支持并正式通过。" % [str(votes_for.size()), str(next_state.get("factions", []).size())], "DIPLOMATIC")
			else:
				council["charterStatus"] = "VOTING"
	next_state["galacticCouncil"] = council
	return next_state

static func determine_ai_victory_focus(state: Dictionary, faction: Dictionary) -> String:
	var personality: Dictionary = faction.get("personality", {})
	var military_score: float = float(faction.get("militaryPower", 0)) + float(personality.get("aggression", 0.0)) * 12.0
	var science_score: float = float(faction.get("technologyLevel", 0)) * 18.0 + float(personality.get("rationality", 0.0)) * 10.0
	var diplomacy_score: float = float(personality.get("loyalty", 0.0)) * 10.0 + float(personality.get("greed", 0.0)) * 6.0
	for other: Dictionary in state.get("factions", []):
		var other_id: String = other.get("id", "")
		if other_id == faction.get("id", ""):
			continue
		if has_treaty(state, faction.get("id", ""), other_id, "ALLIANCE"):
			diplomacy_score += 18.0
		if has_treaty(state, faction.get("id", ""), other_id, "RESEARCH_ACCORD"):
			science_score += 8.0
		if has_treaty(state, faction.get("id", ""), other_id, "WAR_STATE"):
			military_score += 14.0
	if military_score >= science_score and military_score >= diplomacy_score:
		return "MILITARY"
	if science_score >= diplomacy_score:
		return "SCIENCE"
	return "DIPLOMATIC"

static func update_ai_victory_focuses(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for faction_index: int in range(next_state.get("factions", []).size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("isPlayer", false):
			continue
		faction["victoryFocus"] = determine_ai_victory_focus(next_state, faction)
		next_state["factions"][faction_index] = faction
	return next_state

static func apply_ai_victory_interference(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var science_report: Dictionary = player_science_victory_report(next_state)
	var diplomacy_report: Dictionary = player_diplomatic_victory_report(next_state)
	var military_report: Dictionary = player_military_victory_report(next_state)
	for faction: Dictionary in next_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var faction_id: String = faction.get("id", "")
		var relation: Dictionary = relation_breakdown(next_state, "f_player", faction_id)
		var hostile: bool = int(relation.get("trust", 0)) <= 10 or has_treaty(next_state, "f_player", faction_id, "WAR_STATE")
		if not hostile:
			continue
		if str(science_report.get("phase", "INACTIVE")) in ["CORE_CHARGING", "FINAL_LAUNCH"]:
			next_state = update_diplomatic_profile(next_state, faction_id, "firm", 2, "检测到玩家接近科技飞升，开始准备阻击。")
			if int(next_state.get("turn", 1)) % 6 == 0:
				next_state = add_diplomatic_message(next_state, faction_id, ["f_player"], "SINGLE", "PUBLIC", "WARNING", "奇观威慑", "%s 认为你的飞升奇观正在破坏银河平衡，并要求你停止推进计划。" % faction.get("name", faction_id), true)
		if bool(diplomacy_report.get("council_established", false)) and str(diplomacy_report.get("charter_status", "INACTIVE")) in ["VOTING", "PASSED"]:
			next_state = update_diplomatic_profile(next_state, faction_id, "scheming", 2, "检测到玩家接近外交胜利，尝试制造分裂。")
			if int(next_state.get("turn", 1)) % 7 == 0:
				next_state = add_diplomatic_memory(next_state, "联合国分裂活动", "%s 正在联合国内部游说反对票，试图阻止玩家达成外交胜利。" % faction.get("name", faction_id), ["f_player", faction_id], "EVENT", 2)
		if int(military_report.get("controlled_habitable_systems", 0)) >= max(1, int(military_report.get("required_control", 0)) - 1):
			next_state = update_diplomatic_profile(next_state, faction_id, "hostile", 2, "检测到玩家接近征服胜利，开始边境集结。")
	return next_state

static func ensure_faction_controls(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		var controlled_systems: Array = []
		var population: int = 0
		for system: Dictionary in next_state.get("starSystems", []):
			if system.get("ownerId", null) == faction.get("id", "") and system.get("colonyStage", "NONE") != "OUTPOST":
				controlled_systems.append(system.get("id", ""))
			if system.get("ownerId", null) == faction.get("id", ""):
				population += int(system.get("population", 0))
		var military_power: float = 0.0
		for fleet: Dictionary in next_state.get("fleets", []):
			if fleet.get("ownerId", "") == faction.get("id", ""):
				military_power += fleet_power(fleet)
		var technology_level: int = 0
		var researched_tech_ids: Array = faction.get("researchedTechIds", [])
		if faction.get("isPlayer", false):
			for tech: Dictionary in next_state.get("technologies", []):
				if tech.get("status", "") == "RESEARCHED":
					technology_level += 1
			technology_level = maxi(technology_level, researched_tech_ids.size())
		elif faction.has("researchedTechIds"):
			technology_level = researched_tech_ids.size()
		else:
			technology_level = int(faction.get("technologyLevel", 0))
		faction["controlledSystems"] = controlled_systems
		faction["population"] = population
		faction["militaryPower"] = int(round(military_power))
		faction["technologyLevel"] = technology_level
		next_state["factions"][faction_index] = faction
	return next_state

static func player_diplomatic_victory_report(state: Dictionary) -> Dictionary:
	var council: Dictionary = galactic_council_data(state)
	var total_rivals: int = 0
	var alliance_count: int = 0
	var accord_count: int = 0
	var peace_count: int = 0
	var war_count: int = 0
	for faction: Dictionary in state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		total_rivals += 1
		var faction_id: String = faction.get("id", "")
		if has_treaty(state, "f_player", faction_id, "ALLIANCE"):
			alliance_count += 1
		if has_treaty(state, "f_player", faction_id, "RESEARCH_ACCORD"):
			accord_count += 1
		if has_treaty(state, "f_player", faction_id, "NON_AGGRESSION") or has_treaty(state, "f_player", faction_id, "ALLIANCE"):
			peace_count += 1
		if has_treaty(state, "f_player", faction_id, "WAR_STATE"):
			war_count += 1
	var total_voters: int = state.get("factions", []).size()
	var votes_for: int = int(council.get("charterVotesFor", []).size())
	var required_votes: int = maxi(1, int(ceil(float(total_voters) * (2.0 / 3.0))))
	var achieved: bool = bool(council.get("established", false)) and str(council.get("speakerFactionId", "")) == "f_player" and str(council.get("charterStatus", "")) == "PASSED" and votes_for >= required_votes
	return {
		"achieved": achieved,
		"total_rivals": total_rivals,
		"alliances": alliance_count,
		"accords": accord_count,
		"peace_partners": peace_count,
		"wars": war_count,
		"council_established": bool(council.get("established", false)),
		"speaker_faction_id": str(council.get("speakerFactionId", "")),
		"speaker_title": str(council.get("speakerTitle", "未设立")),
		"charter_status": str(council.get("charterStatus", "INACTIVE")),
		"votes_for": votes_for,
		"votes_against": int(council.get("charterVotesAgainst", []).size()),
		"required_votes": required_votes
	}

static func player_military_victory_report(state: Dictionary) -> Dictionary:
	var player_id: String = "f_player"
	var total_habitable_systems: int = 0
	var controlled_habitable_systems: int = 0
	var rival_capitals: int = 0
	var captured_capitals: int = 0
	for system: Dictionary in state.get("starSystems", []):
		if system.get("colonyStage", "NONE") == "OUTPOST":
			continue
		if int(system.get("habitability", 0)) > 0:
			total_habitable_systems += 1
			if system.get("ownerId", null) == player_id:
				controlled_habitable_systems += 1
	for faction: Dictionary in state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var capital_system_id: String = str(faction.get("capitalSystemId", ""))
		if capital_system_id == "":
			continue
		rival_capitals += 1
		for system: Dictionary in state.get("starSystems", []):
			if system.get("id", "") != capital_system_id:
				continue
			if system.get("ownerId", null) == player_id:
				captured_capitals += 1
			break
	var required_control: int = int(ceil(float(total_habitable_systems) * 0.65))
	var achieved_by_control: bool = total_habitable_systems > 0 and controlled_habitable_systems >= required_control
	var achieved_by_capitals: bool = rival_capitals > 0 and captured_capitals >= rival_capitals
	return {
		"achieved": achieved_by_control or achieved_by_capitals,
		"controlled_habitable_systems": controlled_habitable_systems,
		"total_habitable_systems": total_habitable_systems,
		"required_control": required_control,
		"captured_capitals": captured_capitals,
		"rival_capitals": rival_capitals,
		"achieved_by_control": achieved_by_control,
		"achieved_by_capitals": achieved_by_capitals,
	}

static func player_science_victory_report(state: Dictionary) -> Dictionary:
	var project: Dictionary = ascension_project_data(state)
	var ascension_progress: int = int(state.get("ascension_progress", 0))
	var singularity_ready: bool = has_research(state, "tech_singularity_lattice")
	var star_harmonics_ready: bool = has_research(state, "tech_star_harmonics")
	var best_site: Dictionary = best_ascension_site(state, "f_player")
	var site_name: String = str(project.get("siteSystemName", ""))
	if site_name == "":
		site_name = str(best_site.get("name", "暂无可用星系"))
	var phase_name: String = str(project.get("stage", "INACTIVE"))
	var phase_label: String = "未启动"
	var status_summary: String = "尚未满足飞升计划启动条件。"
	match phase_name:
		"FOUNDATION":
			phase_label = "基座铺设"
			status_summary = "%s 正在进行基座铺设，剩余 %s 回合。" % [str(project.get("siteSystemName", "未知星系")), str(project.get("foundationTurnsRemaining", 30))]
		"CORE_CHARGING":
			phase_label = "核心充能"
			status_summary = "%s 正在进行核心充能，进度 %s/%s。" % [str(project.get("siteSystemName", "未知星系")), str(project.get("chargeProgress", 0)), str(project.get("chargeRequired", 120))]
			if str(project.get("blockedReason", "")) == "RESOURCE_SHORTAGE":
				status_summary += " 当前因资源不足而暂停。"
		"FINAL_LAUNCH":
			phase_label = "最终启动"
			status_summary = "%s 进入最终启动保护期，剩余 %s 回合。" % [str(project.get("siteSystemName", "未知星系")), str(project.get("finalTurnsRemaining", 15))]
		"COMPLETED":
			phase_label = "飞升完成"
			status_summary = "%s 已完成文明飞升计划。" % str(project.get("siteSystemName", "未知星系"))
		_:
			phase_name = "INACTIVE"
			phase_label = "未启动"
			status_summary = "建议在 %s 启动飞升奇观建设。" % str(best_site.get("name", "暂无可用星系"))
	return {
		"achieved": phase_name == "COMPLETED",
		"progress": ascension_progress,
		"phase": phase_name,
		"phase_label": phase_label,
		"required_tech_ready": singularity_ready,
		"supporting_tech_ready": star_harmonics_ready,
		"best_site_name": site_name,
		"foundation_turns_remaining": int(project.get("foundationTurnsRemaining", 30)),
		"charge_progress": int(project.get("chargeProgress", 0)),
		"charge_required": int(project.get("chargeRequired", 120)),
		"final_turns_remaining": int(project.get("finalTurnsRemaining", 15)),
		"globally_visible": bool(project.get("globallyVisible", false)),
		"status_summary": status_summary,
	}

static func player_victory_progress_report(state: Dictionary) -> Dictionary:
	return {
		"military": player_military_victory_report(state),
		"diplomatic": player_diplomatic_victory_report(state),
		"science": player_science_victory_report(state),
	}

static func strategic_posture_report(state: Dictionary, source_faction_id: String = "f_player") -> Dictionary:
	var high_pressure: Array = []
	var high_opportunity: Array = []
	var deteriorating: Array = []
	var improving: Array = []
	var flashpoints: Array = []
	for faction: Dictionary in state.get("factions", []):
		if faction.get("id", "") == source_faction_id:
			continue
		var faction_id: String = faction.get("id", "")
		var relation: Dictionary = relation_breakdown(state, source_faction_id, faction_id)
		var trend: Dictionary = relationship_trend_report(state, source_faction_id, faction_id)
		var pressure_score: int = maxi(int(relation.get("fear", 0)), -int(relation.get("trust", 0))) + maxi(int(trend.get("fear_delta", 0)), int(trend.get("memory_delta", 0)))
		var opportunity_score: int = int(relation.get("trust", 0)) + int(relation.get("utility", 0)) + maxi(int(trend.get("trust_delta", 0)), 0)
		if pressure_score >= 45 or has_treaty(state, source_faction_id, faction_id, "WAR_STATE"):
			high_pressure.append(faction.get("name", "未知势力"))
		if opportunity_score >= 40 and not has_treaty(state, source_faction_id, faction_id, "WAR_STATE"):
			high_opportunity.append(faction.get("name", "未知势力"))
		if bool(trend.get("pressure_rising", false)):
			deteriorating.append(faction.get("name", "未知势力"))
		if bool(trend.get("opportunity_rising", false)):
			improving.append(faction.get("name", "未知势力"))
		if has_treaty(state, source_faction_id, faction_id, "WAR_STATE") or pressure_score >= 55:
			flashpoints.append(faction.get("name", "未知势力"))
	var recommended_posture: String = "CONSOLIDATE"
	if not flashpoints.is_empty():
		recommended_posture = "CONTAIN"
	elif not high_opportunity.is_empty() and high_pressure.is_empty():
		recommended_posture = "EXPAND_DIPLOMACY"
	elif not deteriorating.is_empty():
		recommended_posture = "STABILIZE"
	return {
		"high_pressure": high_pressure,
		"high_opportunity": high_opportunity,
		"deteriorating": deteriorating,
		"improving": improving,
		"flashpoints": flashpoints,
		"recommended_posture": recommended_posture,
		"summary": "高压对象 %s / 合作机会 %s / 恶化关系 %s / 改善关系 %s" % [
			", ".join(high_pressure) if not high_pressure.is_empty() else "无",
			", ".join(high_opportunity) if not high_opportunity.is_empty() else "无",
			", ".join(deteriorating) if not deteriorating.is_empty() else "无",
			", ".join(improving) if not improving.is_empty() else "无"
		]
	}

static func assess_game_status(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var player_system_count: int = 0
	var rival_system_count: int = 0
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("colonyStage", "NONE") == "OUTPOST":
			continue
		if system.get("ownerId", null) == player.get("id", ""):
			player_system_count += 1
		elif system.get("ownerId", null) != null:
			rival_system_count += 1
	var military_report: Dictionary = player_military_victory_report(next_state)
	var diplomacy_report: Dictionary = player_diplomatic_victory_report(next_state)
	var science_report: Dictionary = player_science_victory_report(next_state)
	var diplomacy_status: String = "外交目标已完成"
	if not diplomacy_report.get("achieved", false):
		if bool(diplomacy_report.get("council_established", false)):
			diplomacy_status = "%s %s/%s票" % [str(diplomacy_report.get("charter_status", "VOTING")), str(diplomacy_report.get("votes_for", 0)), str(diplomacy_report.get("required_votes", 0))]
		else:
			diplomacy_status = "联合国未成立 / 和平伙伴 %s" % str(diplomacy_report.get("peace_partners", 0))
	var science_status: String = "%s %s/100" % [str(science_report.get("phase_label", "未启动")), str(science_report.get("progress", 0))]
	if str(science_report.get("phase", "INACTIVE")) == "FOUNDATION":
		science_status = "%s 剩余%s回合" % [str(science_report.get("phase_label", "基座铺设")), str(science_report.get("foundation_turns_remaining", 0))]
	elif str(science_report.get("phase", "INACTIVE")) == "CORE_CHARGING":
		science_status = "%s %s/%s" % [str(science_report.get("phase_label", "核心充能")), str(science_report.get("charge_progress", 0)), str(science_report.get("charge_required", 0))]
	elif str(science_report.get("phase", "INACTIVE")) == "FINAL_LAUNCH":
		science_status = "%s 剩余%s回合" % [str(science_report.get("phase_label", "最终启动")), str(science_report.get("final_turns_remaining", 0))]
	elif str(science_report.get("phase", "INACTIVE")) == "COMPLETED":
		science_status = "飞升完成"
	next_state["objective"] = "军事 %s/%s 星系控制 | 外交 %s | 科技飞升 %s" % [str(military_report.get("controlled_habitable_systems", 0)), str(military_report.get("required_control", 0)), diplomacy_status, science_status]
	if player_system_count == 0:
		next_state["status"] = "DEFEAT"
		return add_message(next_state, "帝国覆灭", "你已失去全部控制星系，本局以失败结束。", "SYSTEM")
	if bool(science_report.get("achieved", false)):
		next_state["status"] = "VICTORY"
		next_state["victory_path"] = "ASCENSION"
		return add_message(next_state, "科技飞升胜利", "你的帝国已完成文明飞升计划的全部阶段，达成科技胜利。", "SYSTEM")
	if diplomacy_report.get("achieved", false):
		next_state["status"] = "VICTORY"
		next_state["victory_path"] = "DIPLOMATIC"
		return add_message(next_state, "外交胜利", "你已通过联盟、协定与和平网络建立银河主导地位。", "SYSTEM")
	if bool(military_report.get("achieved", false)) or rival_system_count == 0:
		next_state["status"] = "VICTORY"
		next_state["victory_path"] = "MILITARY"
		return add_message(next_state, "军事胜利", "敌对势力已无力争夺星图，你取得了军事胜利。", "SYSTEM")
	next_state["status"] = "PLAYING"
	next_state["victory_path"] = null
	return next_state

static func event_reward(event_type: Variant) -> Dictionary:
	match str(event_type):
		"ANCIENT_RUINS":
			return {
				"title": "远古遗迹",
				"content": "勘探队在废墟深处找到可回收的工业构件与矿物缓存，帝国工程部门已完成打包回收。",
				"reward": {"food": 0, "minerals": 25, "industry": 40, "energy": 10}
			}
		"RICH_ASTEROIDS":
			return {
				"title": "富矿小行星带",
				"content": "该星系的小行星带富含高品位矿脉，临时开采队已带回一批矿石与可用能源晶体。",
				"reward": {"food": 0, "minerals": 50, "industry": 0, "energy": 20}
			}
		"SOLAR_STORM":
			return {
				"title": "太阳风暴余波",
				"content": "恒星活动短暂冲击了轨道设施，但工程队借机完成了一轮应急改造，留下部分工业与能源收益。",
				"reward": {"food": 0, "minerals": 0, "industry": 10, "energy": 45}
			}
		"PIRATE_RAID":
			return {
				"title": "海盗袭扰",
				"content": "本地航路遭遇掠袭，商船与补给线受到影响，帝国为稳定局势付出了额外资源代价。",
				"reward": {"food": -8, "minerals": -12, "industry": 0, "energy": -18}
			}
		"WARP_STORM":
			return {
				"title": "跃迁风暴",
				"content": "异常跃迁潮汐扰乱了航道与阵列，维修与调度消耗了额外资源，但也迫使系统完成了局部适应性升级。",
				"reward": {"food": 0, "minerals": 0, "industry": 8, "energy": -10}
			}
		_:
			return {}

static func resolve_player_system_event(state: Dictionary, system_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") != system_id or system.get("eventResolved", false):
			continue
		var reward_data: Dictionary = event_reward(system.get("eventType", null))
		if reward_data.is_empty():
			return next_state
		system["eventResolved"] = true
		system["note"] = "%s 事件已处理，局势暂时恢复稳定。" % system.get("note", "")
		next_state["starSystems"][system_index] = system
		for faction_index: int in range(next_state["factions"].size()):
			var faction: Dictionary = next_state["factions"][faction_index]
			if faction.get("id", "") == player.get("id", ""):
				faction["resources"] = add_resources(faction.get("resources", {}), reward_data.get("reward", {}))
				next_state["factions"][faction_index] = faction
		return add_message(next_state, reward_data.get("title", ""), "%s：%s" % [system.get("name", ""), reward_data.get("content", "")], "EVENT")
	return next_state

static func trigger_narrative_event(state: Dictionary, event_template_id: String, target_system_id: String, affected_factions: Array = [], narrative_override: String = "", outcome_modifiers: Dictionary = {}) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var event_type: String = "ANCIENT_RUINS"
	var default_note: String = "边境勘探队在目标星系发现异常信号，建议立即决定后续处置方案。"
	var follow_up_options: Array = ["派工程队调查", "保持观察", "直接开发回收"]
	match event_template_id:
		"ANCIENT_RUINS_DISCOVERY":
			event_type = "ANCIENT_RUINS"
			default_note = "勘探队在古代遗迹中发现仍可运作的设施节点。你可以深入调查、保持观望，或直接拆解回收。"
			follow_up_options = ["派工程队调查", "建立联合研究站", "直接开发回收"]
		"PIRATE_RAID":
			event_type = "PIRATE_RAID"
			default_note = "当地航线遭遇海盗袭扰。你可以选择强势清剿、协商护航，或投入资源加固航路。"
			follow_up_options = ["派舰队清剿", "与商路势力协商护航", "投入资源加固航路"]
		"WARP_STORM":
			event_type = "WARP_STORM"
			default_note = "跃迁风暴正在穿越目标星系。你可以派工程队稳定航道、临时封闭节点，或趁乱进行高风险回收。"
			follow_up_options = ["派工程队稳定航道", "临时封闭跃迁节点", "趁乱进行高风险回收"]
	for system_index: int in range(next_state.get("starSystems", []).size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") != target_system_id:
			continue
		system["eventType"] = event_type
		system["eventResolved"] = false
		system["note"] = narrative_override if narrative_override != "" else default_note
		if event_type == "PIRATE_RAID":
			system["stability"] = max(20, int(system.get("stability", 60)) - int(round(10.0 * float(outcome_modifiers.get("threat_scale", 1.0)))))
			system["supplyLevel"] = max(25, int(system.get("supplyLevel", 70)) - int(round(12.0 * float(outcome_modifiers.get("threat_scale", 1.0)))))
		elif event_type == "WARP_STORM":
			system["supplyLevel"] = max(30, int(system.get("supplyLevel", 70)) - 8)
		next_state["starSystems"][system_index] = system
		break
	var active_events: Array = next_state.get("activeNarrativeEvents", [])
	active_events.push_front({
		"id": "nev_%s_%s" % [str(next_state.get("turn", 1)), target_system_id],
		"eventTemplateId": event_template_id,
		"systemId": target_system_id,
		"title": event_type,
		"summary": narrative_override if narrative_override != "" else default_note,
		"followUpOptions": follow_up_options,
		"status": "ACTIVE",
		"createdOnTurn": int(next_state.get("turn", 1)),
		"chainStage": int(outcome_modifiers.get("chainStage", 1)),
	})
	next_state["activeNarrativeEvents"] = active_events
	var affected_names: Array = []
	for faction_id: String in affected_factions:
		affected_names.append(get_faction_by_id(next_state, faction_id).get("name", faction_id))
	var suffix: String = "" if affected_names.is_empty() else " 受影响势力：%s。" % ", ".join(affected_names)
	return add_message(next_state, "叙事事件触发", "%s%s" % [default_note if narrative_override == "" else narrative_override, suffix], "EVENT")

static func apply_director_intervention(state: Dictionary, intervention_type: String, intensity: float = 0.5, duration: int = 3) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var interventions: Array = next_state.get("activeInterventions", [])
	interventions.push_front({
		"id": "din_%s_%s" % [str(next_state.get("turn", 1)), intervention_type.to_lower()],
		"type": intervention_type,
		"intensity": intensity,
		"remainingTurns": duration,
		"status": "ACTIVE",
	})
	next_state["activeInterventions"] = interventions
	match intervention_type:
		"SPAWN_PIRATES":
			for system: Dictionary in next_state.get("starSystems", []):
				if system.get("visibilityLevel", "") == "FULL" and system.get("ownerId", null) == null:
					return trigger_narrative_event(next_state, "PIRATE_RAID", system.get("id", ""), ["f_player"], "边境航线出现海盗集结迹象，附近中立航道正遭受持续袭扰。", {"threat_scale": intensity})
		"BOOST_AI":
			for index: int in range(next_state.get("factions", []).size()):
				var faction: Dictionary = next_state["factions"][index]
				if faction.get("isPlayer", false):
					continue
				var resources: Dictionary = faction.get("resources", {}).duplicate(true)
				resources["minerals"] = int(resources.get("minerals", 0)) + int(round(30.0 * intensity))
				resources["industry"] = int(resources.get("industry", 0)) + int(round(24.0 * intensity))
				resources["energy"] = int(resources.get("energy", 0)) + int(round(20.0 * intensity))
				faction["resources"] = resources
				next_state["factions"][index] = faction
			return add_message(next_state, "导演干预", "外部势力获得了额外的资源补给，预计在接下来的 %s 回合内会更加积极扩张。" % str(duration), "EVENT")
		"REDUCE_RESOURCES":
			for index: int in range(next_state.get("factions", []).size()):
				var faction: Dictionary = next_state["factions"][index]
				if not faction.get("isPlayer", false):
					continue
				var resources: Dictionary = faction.get("resources", {}).duplicate(true)
				resources["food"] = max(0, int(resources.get("food", 0)) - int(round(20.0 * intensity)))
				resources["energy"] = max(0, int(resources.get("energy", 0)) - int(round(24.0 * intensity)))
				faction["resources"] = resources
				next_state["factions"][index] = faction
			return add_message(next_state, "导演干预", "后勤与能源网络受到压制，本回合你损失了一部分粮食与能源储备。", "EVENT")
		"TRIGGER_CRISIS":
			for system: Dictionary in next_state.get("starSystems", []):
				if system.get("ownerId", null) == "f_player":
					return trigger_narrative_event(next_state, "WARP_STORM", system.get("id", ""), ["f_player"], "异常跃迁风暴正在逼近你的殖民星系，航道与轨道设施都面临压力测试。", {"storm_scale": intensity})
	return next_state

static func resolve_narrative_event_choice(state: Dictionary, event_id: String, option_label: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var target_event: Dictionary = {}
	for index: int in range(next_state.get("activeNarrativeEvents", []).size()):
		var item: Dictionary = next_state["activeNarrativeEvents"][index]
		if item.get("id", "") != event_id or item.get("status", "ACTIVE") != "ACTIVE":
			continue
		item["status"] = "RESOLVED"
		item["selectedOption"] = option_label
		next_state["activeNarrativeEvents"][index] = item
		target_event = item
		break
	if target_event.is_empty():
		return next_state
	var system_id: String = target_event.get("systemId", "")
	var system_name: String = system_id
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("id", "") == system_id:
			system_name = system.get("name", system_id)
			break
	var event_template_id: String = str(target_event.get("eventTemplateId", ""))
	match option_label:
		"派工程队调查", "派工程队稳定航道":
			for index: int in range(next_state.get("factions", []).size()):
				var faction: Dictionary = next_state["factions"][index]
				if not faction.get("isPlayer", false):
					continue
				var resources: Dictionary = faction.get("resources", {}).duplicate(true)
				resources["industry"] = int(resources.get("industry", 0)) + 20
				resources["energy"] = int(resources.get("energy", 0)) + 12
				faction["resources"] = resources
				next_state["factions"][index] = faction
			if event_template_id == "ANCIENT_RUINS_DISCOVERY":
				next_state["researchProgress"] = float(next_state.get("researchProgress", 0.0)) + 18.0
			next_state = add_diplomatic_memory(next_state, "工程调查报告", "%s 的调查行动带回了可观的工程样本与现场数据。" % system_name, ["f_player"], "EVENT", 2)
		"建立联合研究站", "与商路势力协商护航", "临时封闭跃迁节点":
			for system_index: int in range(next_state.get("starSystems", []).size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") != system_id:
					continue
				system["stability"] = min(100, int(system.get("stability", 60)) + 8)
				system["supplyLevel"] = min(100, int(system.get("supplyLevel", 60)) + 10)
				system["eventResolved"] = true
				next_state["starSystems"][system_index] = system
				break
			if option_label == "与商路势力协商护航":
				for index: int in range(next_state.get("relationships", []).size()):
					var relation: Dictionary = next_state["relationships"][index]
					var touches_merchant: bool = (relation.get("factionAId", "") == "f_player" and relation.get("factionBId", "") == "f_merchant") or (relation.get("factionAId", "") == "f_merchant" and relation.get("factionBId", "") == "f_player")
					if not touches_merchant:
						continue
					relation["trust"] = clamp(int(relation.get("trust", 0)) + 4, -100, 100)
					relation["utility"] = int(relation.get("utility", 0)) + 4
					relation["level"] = relation_level(int(relation.get("trust", 0)))
					next_state["relationships"][index] = relation
				next_state = update_diplomatic_profile(next_state, "f_merchant", "friendly", 3, "玩家愿意通过合作方式稳定航路。")
				next_state = add_diplomatic_memory(next_state, "商路护航协定", "%s 已与商路势力达成临时护航安排，局部航线恢复稳定。" % system_name, ["f_player", "f_merchant"], "AGREEMENT", 2)
		"直接开发回收", "派舰队清剿", "投入资源加固航路":
			for system_index: int in range(next_state.get("starSystems", []).size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") != system_id:
					continue
				system["stability"] = max(25, int(system.get("stability", 60)) - 4)
				system["eventResolved"] = true
				next_state["starSystems"][system_index] = system
				break
			if option_label == "派舰队清剿":
				for fleet_index: int in range(next_state.get("fleets", []).size()):
					var fleet: Dictionary = next_state["fleets"][fleet_index]
					if fleet.get("ownerId", "") != "f_player":
						continue
					if fleet.get("systemId", "") != system_id:
						continue
					next_state["fleets"][fleet_index] = damage_fleet(fleet, 10)
					break
				next_state = update_diplomatic_profile(next_state, "f_merchant", "firm", 1, "玩家选择以武力压制海盗威胁。")
				next_state = add_diplomatic_memory(next_state, "海盗清剿行动", "%s 周边航道展开清剿作战，玩家舰队承受了少量战损。" % system_name, ["f_player", "f_merchant"], "EVENT", 3)
			elif option_label == "投入资源加固航路":
				for index: int in range(next_state.get("factions", []).size()):
					var faction: Dictionary = next_state["factions"][index]
					if not faction.get("isPlayer", false):
						continue
					var resources: Dictionary = faction.get("resources", {}).duplicate(true)
					resources["energy"] = max(0, int(resources.get("energy", 0)) - 16)
					resources["industry"] = int(resources.get("industry", 0)) + 16
					faction["resources"] = resources
					next_state["factions"][index] = faction
				next_state = add_diplomatic_memory(next_state, "航路加固", "%s 的基础设施升级已完成，后续商路与补给线会更加稳固。" % system_name, ["f_player"], "EVENT", 2)
		"保持观察", "趁乱进行高风险回收", "直接开发回收":
			next_state = resolve_player_system_event(next_state, system_id)
			if option_label == "趁乱进行高风险回收":
				for system_index: int in range(next_state.get("starSystems", []).size()):
					var system: Dictionary = next_state["starSystems"][system_index]
					if system.get("id", "") != system_id:
						continue
					system["supplyLevel"] = max(35, int(system.get("supplyLevel", 60)) - 6)
					system["eventResolved"] = true
					next_state["starSystems"][system_index] = system
					break
				next_state = update_diplomatic_profile(next_state, "f_orchid", "neutral", -1, "玩家在风险条件下推进资源回收。")
				next_state = add_diplomatic_memory(next_state, "高风险回收", "%s 在风暴扰动中完成了一次冒险回收，收益与风险并存。" % system_name, ["f_player", "f_orchid"], "EVENT", 1)
	var follow_up: Dictionary = event_chain_follow_up(event_template_id, option_label)
	if not follow_up.is_empty():
		next_state = trigger_narrative_event(
			next_state,
			str(follow_up.get("eventTemplateId", event_template_id)),
			system_id,
			["f_player"],
			str(follow_up.get("narrative", "")),
			{"chainStage": int(follow_up.get("chainStage", 2))}
		)
		for event_index: int in range(next_state.get("activeNarrativeEvents", []).size()):
			var event_item: Dictionary = next_state["activeNarrativeEvents"][event_index]
			if event_item.get("status", "ACTIVE") != "ACTIVE":
				continue
			if event_item.get("systemId", "") != system_id:
				continue
			if int(event_item.get("chainStage", 1)) != int(follow_up.get("chainStage", 2)):
				continue
			event_item["followUpOptions"] = follow_up.get("options", [])
			event_item["title"] = "%s-阶段%s" % [str(event_item.get("title", "叙事事件")), str(event_item.get("chainStage", 2))]
			next_state["activeNarrativeEvents"][event_index] = event_item
			break
	next_state = add_message(next_state, "事件决议", "%s 已执行选项：%s。" % [system_name, option_label], "EVENT")
	return next_state

static func advance_active_interventions(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var updated: Array = []
	for item: Dictionary in next_state.get("activeInterventions", []):
		if item.get("status", "ACTIVE") != "ACTIVE":
			updated.append(item)
			continue
		item["remainingTurns"] = max(0, int(item.get("remainingTurns", 0)) - 1)
		if int(item.get("remainingTurns", 0)) <= 0:
			item["status"] = "EXPIRED"
		updated.append(item)
	next_state["activeInterventions"] = updated
	return next_state

static func active_narrative_events_for_player(state: Dictionary) -> Array:
	var result: Array = []
	for item: Dictionary in state.get("activeNarrativeEvents", []):
		if item.get("status", "ACTIVE") == "ACTIVE":
			result.append(item)
	return result

static func event_chain_follow_up(event_template_id: String, option_label: String) -> Dictionary:
	match event_template_id:
		"ANCIENT_RUINS_DISCOVERY":
			if option_label == "派工程队调查":
				return {
					"eventTemplateId": "ANCIENT_RUINS_DISCOVERY",
					"narrative": "初步勘探后，遗迹深层区显露出更多未解锁模块。你可以继续谨慎推进、建立研究站，或直接拆解核心构件。",
					"options": ["派工程队稳定航道", "建立联合研究站", "直接开发回收"],
					"chainStage": 2
				}
		"PIRATE_RAID":
			if option_label == "派舰队清剿":
				return {
					"eventTemplateId": "PIRATE_RAID",
					"narrative": "清剿后仍有零散海盗潜伏在外围航道。你可以转入协商护航、继续强压，或改为加固基础设施。",
					"options": ["与商路势力协商护航", "临时封闭跃迁节点", "投入资源加固航路"],
					"chainStage": 2
				}
		"WARP_STORM":
			if option_label == "派工程队稳定航道":
				return {
					"eventTemplateId": "WARP_STORM",
					"narrative": "主风暴带已经偏移，但余波仍在扰动局部航线。你可以继续封闭节点、进行高风险回收，或转回常规工程调查。",
					"options": ["临时封闭跃迁节点", "趁乱进行高风险回收", "派工程队调查"],
					"chainStage": 2
				}
	return {}

static func initiate_combat_protocol(state: Dictionary, attacker_fleet_id: String, target_type: String, target_id: String, engagement_rules: String = "ALL_OUT", formation: String = "LINE", tactic_card: String = "BATTLE_LINE") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var attacker_index: int = find_fleet_index(next_state, attacker_fleet_id)
	if attacker_index == -1:
		return next_state
	var attacker: Dictionary = next_state["fleets"][attacker_index]
	var attacker_owner: String = attacker.get("ownerId", "")
	var defender_index: int = -1
	var defender: Dictionary = {}
	if target_type == "FLEET":
		defender_index = find_fleet_index(next_state, target_id)
		if defender_index == -1:
			return add_message(next_state, "战斗发起失败", "未找到目标舰队，无法发起交战。", "SYSTEM")
		defender = next_state["fleets"][defender_index]
	else:
		return add_message(next_state, "战斗发起失败", "当前仅支持对舰队目标发起交战。", "SYSTEM")
	if defender.get("ownerId", "") == attacker_owner:
		return add_message(next_state, "战斗发起失败", "不能攻击己方舰队。", "SYSTEM")
	if not has_treaty(next_state, attacker_owner, defender.get("ownerId", ""), "WAR_STATE"):
		next_state = declare_war_on_faction(next_state, attacker_owner, defender.get("ownerId", ""))
		attacker_index = find_fleet_index(next_state, attacker_fleet_id)
		defender_index = find_fleet_index(next_state, target_id)
		attacker = next_state["fleets"][attacker_index]
		defender = next_state["fleets"][defender_index]
	var attacker_modifier: float = 1.0
	var defender_modifier: float = 1.0
	var notes: Array = [
		"交战规则：%s" % engagement_rules,
		"阵型：%s" % formation,
		"战术卡：%s" % tactic_card,
	]
	var attacker_damage_taken: int = 22
	var defender_damage_taken: int = 14
	var rounds: int = 3
	var system_id: String = str(defender.get("systemId", ""))
	var defense_power: int = system_defense_power(next_state, system_id, defender.get("ownerId", ""))
	if engagement_rules == "HIT_AND_RUN":
		attacker_modifier *= 0.88
		notes.append("采取袭扰撤离策略，战斗更短促。")
		attacker_damage_taken = 12
		defender_damage_taken = 10
	elif engagement_rules == "ALL_OUT":
		attacker_modifier *= 1.08
		notes.append("双方进入全面交战状态。")
		attacker_damage_taken = 28
		defender_damage_taken = 18
	elif engagement_rules == "DEFENSIVE":
		attacker_modifier *= 0.96
		notes.append("攻击方保持谨慎推进。")
		attacker_damage_taken = 10
		defender_damage_taken = 8
	if formation == "WEDGE":
		attacker_modifier *= 1.12
		notes.append("楔形突击提升了前线火力。")
		defender_damage_taken += 6
	elif formation == "SPHERE":
		attacker_modifier *= 0.95
		notes.append("球形阵收缩了火力但降低了战损。")
		attacker_damage_taken = max(6, attacker_damage_taken - 8)
	elif formation == "LINE":
		attacker_modifier *= 1.02
		notes.append("线列阵保持了稳定输出。")
	var attacker_ship_count: int = attacker.get("ships", []).size()
	var corvette_count: int = ship_type_count(attacker, "CORVETTE")
	var capital_ship_count: int = ship_type_count(attacker, "CRUISER") + ship_type_count(attacker, "BATTLESHIP")
	var defender_fleet_modifier: float = 1.0
	var defense_structure_modifier: float = 1.0
	match tactic_card:
		"SCORCHED_EARTH":
			attacker_modifier *= 1.20
			notes.append("焦土政策提供了 20% 攻击加成。")
		"ORBITAL_BOMBARDMENT":
			defender_fleet_modifier *= 1.25
			defense_structure_modifier *= 0.5
			notes.append("轨道轰炸强化了对防御建筑的打击，并降低了对舰队的伤害。")
		"WOLF_PACK":
			if attacker_ship_count > 0:
				var corvette_ratio: float = float(corvette_count) / float(attacker_ship_count)
				var capital_ratio: float = float(capital_ship_count) / float(attacker_ship_count)
				attacker_damage_taken = int(round(float(attacker_damage_taken) * (1.0 - 0.25 * corvette_ratio)))
				attacker_modifier *= maxf(0.75, 1.0 - 0.25 * capital_ratio)
			notes.append("狼群突袭提高了护卫舰闪避，并压低了主力舰命中。")
		"JUMP_ASSAULT":
			attacker_modifier *= 1.15
			attacker_damage_taken += 6
			notes.append("跃迁突击在首轮制造了强冲击。")
		"BATTLE_LINE":
			if capital_ship_count > 0:
				attacker_modifier *= 1.15
			notes.append("战列线为巡洋舰与战列舰提供了 15% 火力加成。")
	if defense_power > 0:
		notes.append("目标星系提供了 %s 点防御火力。" % str(defense_power))
	var attacker_power: float = fleet_power(attacker) * attacker_modifier
	var defender_power: float = fleet_power(defender) * defender_modifier * defender_fleet_modifier + float(defense_power) * defense_structure_modifier
	for round_index: int in range(rounds):
		var round_factor: float = 1.0
		if tactic_card == "JUMP_ASSAULT":
			round_factor = 2.0 if round_index == 0 else 0.7
		elif tactic_card == "BATTLE_LINE":
			round_factor = 1.05
		attacker_power += (fleet_power(attacker) * attacker_modifier * round_factor) / 3.0
		defender_power += (fleet_power(defender) * defender_modifier + float(defense_power) * 0.4) / 3.0
	var attacker_wins: bool = attacker_power >= defender_power
	var casualties: int = max(1, int(attacker.get("ships", []).size() * (0.2 if attacker_wins else 0.5 if engagement_rules == "ALL_OUT" else 0.25)))
	var kills: int = defender.get("ships", []).size() if attacker_wins and engagement_rules != "HIT_AND_RUN" else max(1, int(defender.get("ships", []).size() * 0.5)) if attacker_wins else max(0, int(defender.get("ships", []).size() * 0.25))
	var remaining_power: int = max(8, int((attacker_power - defender_power) / max(1.0, attacker_power) * 100.0)) if attacker_wins else max(0, int((fleet_power(attacker) - defender_power) / max(1.0, fleet_power(attacker)) * 100.0))
	if attacker_wins:
		var damaged_attacker: Dictionary = damage_fleet(attacker, attacker_damage_taken)
		next_state["fleets"][attacker_index] = damaged_attacker
		var damaged_defender: Dictionary = damage_fleet(defender, defender_damage_taken + 18)
		var defender_retreat_id: String = nearest_friendly_system_id(next_state, defender.get("ownerId", ""), defender.get("systemId", ""))
		if defender_retreat_id != "":
			damaged_defender["systemId"] = defender_retreat_id
			next_state["fleets"][defender_index] = damaged_defender
			notes.append("防守方撤退至 %s。" % defender_retreat_id)
		elif defender_index > attacker_index:
			next_state["fleets"].remove_at(defender_index)
		else:
			next_state["fleets"].remove_at(defender_index)
			attacker_index = max(0, attacker_index - 1)
		for system_index: int in range(next_state.get("starSystems", []).size()):
			var system: Dictionary = next_state["starSystems"][system_index]
			if system.get("id", "") != defender.get("systemId", ""):
				continue
			system["ownerId"] = attacker_owner
			system["visibilityLevel"] = "FULL"
			if tactic_card == "SCORCHED_EARTH":
				system["buildings"] = []
				notes.append("焦土打击摧毁了目标地表建筑。")
			elif tactic_card == "ORBITAL_BOMBARDMENT":
				var surviving_buildings: Array = []
				for building: Dictionary in system.get("buildings", []):
					if str(building.get("type", "")) == "DEFENSE_PLATFORM":
						continue
					surviving_buildings.append(building)
				system["buildings"] = surviving_buildings
				notes.append("轨道轰炸摧毁了目标星系的防御平台。")
			next_state["starSystems"][system_index] = system
			break
		if engagement_rules == "HIT_AND_RUN":
			next_state = add_message(next_state, "袭扰得手", "%s 在短促交火后压制敌军并成功脱离。" % attacker.get("name", "舰队"), "COMBAT")
		else:
			next_state = add_message(next_state, "战斗胜利", "%s 击溃了目标舰队并夺取了战场主动权。" % attacker.get("name", "舰队"), "COMBAT")
		for index: int in range(next_state.get("relationships", []).size()):
			var relation: Dictionary = next_state["relationships"][index]
			var touches: bool = (relation.get("factionAId", "") == attacker_owner and relation.get("factionBId", "") == defender.get("ownerId", "")) or (relation.get("factionAId", "") == defender.get("ownerId", "") and relation.get("factionBId", "") == attacker_owner)
			if not touches:
				continue
			relation["trust"] = clamp(int(relation.get("trust", 0)) - 12, -100, 100)
			relation["fear"] = int(relation.get("fear", 0)) + 14
			relation["memoryImpact"] = int(relation.get("memoryImpact", 0)) + 10
			relation["level"] = relation_level(int(relation.get("trust", 0)))
			next_state["relationships"][index] = relation
		next_state = update_diplomatic_profile(next_state, defender.get("ownerId", ""), "hostile", -6, "我方舰队在战斗中失利。")
		next_state = add_diplomatic_memory(next_state, "舰队会战", "%s 在与 %s 的交战中取得胜利。" % [attacker.get("name", "舰队"), defender.get("name", "敌方舰队")], [attacker_owner, defender.get("ownerId", "")], "WAR", 3)
	else:
		next_state["fleets"][defender_index] = damage_fleet(defender, defender_damage_taken)
		if engagement_rules == "DEFENSIVE" or engagement_rules == "HIT_AND_RUN":
			next_state["fleets"][attacker_index] = damage_fleet(attacker, attacker_damage_taken)
			next_state = add_message(next_state, "战斗受挫", "%s 未能打开局面，双方在有限交战后脱离接触。" % attacker.get("name", "舰队"), "COMBAT")
			next_state = update_diplomatic_profile(next_state, defender.get("ownerId", ""), "firm", 2, "我方成功抵御了敌军试探。")
			for index: int in range(next_state.get("relationships", []).size()):
				var relation: Dictionary = next_state["relationships"][index]
				var touches: bool = (relation.get("factionAId", "") == attacker_owner and relation.get("factionBId", "") == defender.get("ownerId", "")) or (relation.get("factionAId", "") == defender.get("ownerId", "") and relation.get("factionBId", "") == attacker_owner)
				if not touches:
					continue
				relation["trust"] = clamp(int(relation.get("trust", 0)) - 6, -100, 100)
				relation["fear"] = max(0, int(relation.get("fear", 0)) - 2)
				relation["memoryImpact"] = int(relation.get("memoryImpact", 0)) + 4
				relation["level"] = relation_level(int(relation.get("trust", 0)))
				next_state["relationships"][index] = relation
		else:
			var damaged_attacker: Dictionary = damage_fleet(attacker, attacker_damage_taken + 18)
			var retreat_id: String = nearest_friendly_system_id(next_state, attacker_owner, attacker.get("systemId", ""))
			if retreat_id != "":
				damaged_attacker["systemId"] = retreat_id
				next_state["fleets"][attacker_index] = damaged_attacker
				next_state = add_message(next_state, "进攻失败", "%s 被迫撤退至 %s。" % [attacker.get("name", "舰队"), retreat_id], "COMBAT")
				notes.append("进攻方撤退至 %s。" % retreat_id)
			else:
				next_state["fleets"].remove_at(attacker_index)
				next_state = add_message(next_state, "舰队覆灭", "%s 在交战中损失殆尽。" % attacker.get("name", "舰队"), "COMBAT")
			next_state = add_diplomatic_memory(next_state, "舰队会战", "%s 在与 %s 的交战中失利。" % [attacker.get("name", "舰队"), defender.get("name", "敌方舰队")], [attacker_owner, defender.get("ownerId", "")], "WAR", 3)
			for index: int in range(next_state.get("relationships", []).size()):
				var relation: Dictionary = next_state["relationships"][index]
				var touches: bool = (relation.get("factionAId", "") == attacker_owner and relation.get("factionBId", "") == defender.get("ownerId", "")) or (relation.get("factionAId", "") == defender.get("ownerId", "") and relation.get("factionBId", "") == attacker_owner)
				if not touches:
					continue
				relation["trust"] = clamp(int(relation.get("trust", 0)) - 10, -100, 100)
				relation["fear"] = int(relation.get("fear", 0)) + 6
				relation["memoryImpact"] = int(relation.get("memoryImpact", 0)) + 8
				relation["level"] = relation_level(int(relation.get("trust", 0)))
				next_state["relationships"][index] = relation
	next_state = add_message(next_state, "战斗摘要", " / ".join(notes), "COMBAT")
	next_state = add_combat_report(next_state, "舰队交战报告", attacker.get("name", "我方舰队"), defender.get("name", "敌方舰队"), attacker_wins, casualties, kills, remaining_power, notes)
	next_state = refresh_player_visibility(next_state)
	return assess_game_status(ensure_faction_controls(next_state))

static func colonize_for_faction(state: Dictionary, faction_id: String, system_id: String, population: int, title: String, content: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var habitat: Dictionary = {}
	for entry: Dictionary in InitialDataScript.building_catalog():
		if entry.get("type", "") == "HABITAT":
			habitat = entry
			break
	if habitat.is_empty():
		return next_state
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == faction_id:
			faction["resources"] = subtract_resources(faction.get("resources", {}), COLONY_COST)
			next_state["factions"][faction_index] = faction
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") == system_id:
			system["ownerId"] = faction_id
			system["population"] = population
			system["visibilityLevel"] = "FULL"
			system["buildings"] = [InitialDataScript._make_building("colony_%s" % system_id, habitat)]
			system["colonyStage"] = "COLONY"
			system["colonizationProgress"] = 100.0
			system["colonizationTurnsRemaining"] = 0
			system["buildingSlots"] = int(system.get("baseBuildingSlots", system.get("buildingSlots", 3)))
			system["stability"] = max(62, int(system.get("stability", 50)))
			system["supplyLevel"] = max(75, int(system.get("supplyLevel", 60)))
			next_state["starSystems"][system_index] = system
	return add_message(next_state, title, content, "EVENT")

static func consume_colonization_fleet(state: Dictionary, fleet_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for fleet_index: int in range(next_state.get("fleets", []).size()):
		var fleet: Dictionary = next_state["fleets"][fleet_index]
		if fleet.get("id", "") != fleet_id:
			continue
		fleet["mission"] = "COLONIZING"
		fleet["movementCooldown"] = maxi(1, int(fleet.get("movementCooldown", 0)))
		next_state["fleets"][fleet_index] = fleet
		break
	return next_state

static func start_colony_for_faction(state: Dictionary, faction_id: String, system_id: String, mode: String, title: String, content: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var mode_data: Dictionary = colony_mode_data(mode)
	if mode_data.is_empty():
		return next_state
	var habitat: Dictionary = {}
	for entry: Dictionary in InitialDataScript.building_catalog():
		if entry.get("type", "") == "HABITAT":
			habitat = entry
			break
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == faction_id:
			faction["resources"] = subtract_resources(faction.get("resources", {}), mode_data.get("cost", COLONY_COST))
			next_state["factions"][faction_index] = faction
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") != system_id:
			continue
		system["ownerId"] = faction_id
		system["population"] = int(mode_data.get("initial_population", 60))
		system["visibilityLevel"] = "FULL"
		system["buildings"] = [InitialDataScript._make_building("colony_%s" % system_id, habitat)] if not habitat.is_empty() else []
		system["colonyStage"] = "OUTPOST"
		system["colonizationProgress"] = 0.0
		system["colonizationTurnsRemaining"] = int(mode_data.get("turns", 3))
		system["colonizationMode"] = mode
		system["colonizationRisk"] = mode_data.get("risk", "MEDIUM")
		system["stability"] = int(mode_data.get("initial_stability", 50))
		system["supplyLevel"] = int(mode_data.get("initial_supply", 65))
		system["migrationPull"] = int(system.get("habitability", 60)) + 6
		system["buildingSlots"] = min(int(mode_data.get("slot_cap", 2)), int(system.get("baseBuildingSlots", system.get("buildingSlots", 2))))
		next_state["starSystems"][system_index] = system
		break
	return add_message(next_state, title, content, "EVENT")

static func progress_colonies(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("colonyStage", "NONE") != "OUTPOST":
			continue
		var turns_remaining: int = max(0, int(system.get("colonizationTurnsRemaining", 0)) - 1)
		var progress_gain: float = max(12.0, colony_growth_speed(system, next_state) * 28.0)
		var progress: float = min(100.0, float(system.get("colonizationProgress", 0.0)) + progress_gain)
		system["colonizationTurnsRemaining"] = turns_remaining
		system["colonizationProgress"] = progress
		system["stability"] = min(100, int(system.get("stability", 50)) + 2 + (2 if has_research(next_state, "tech_colony_charter") else 0))
		system["supplyLevel"] = min(100, int(system.get("supplyLevel", 60)) + 3)
		system["population"] = int(system.get("population", 0)) + 6 + (4 if has_research(next_state, "tech_expanded_housing") else 0)
		next_state["starSystems"][system_index] = system
		if turns_remaining <= 0 or progress >= 100.0:
			var bonus_population: int = 30 if has_research(next_state, "tech_expanded_housing") else 0
			system["colonyStage"] = "COLONY"
			system["colonizationProgress"] = 100.0
			system["colonizationTurnsRemaining"] = 0
			system["population"] = int(system.get("population", 0)) + 20 + bonus_population
			system["buildingSlots"] = int(system.get("baseBuildingSlots", system.get("buildingSlots", 3)))
			system["stability"] = min(100, int(system.get("stability", 60)) + 12)
			system["supplyLevel"] = min(100, int(system.get("supplyLevel", 70)) + 10)
			next_state["starSystems"][system_index] = system
			for fleet_index: int in range(next_state.get("fleets", []).size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("ownerId", "") == system.get("ownerId", "") and fleet.get("systemId", "") == system.get("id", "") and str(fleet.get("mission", "IDLE")) == "COLONIZING":
					fleet["mission"] = "IDLE"
					fleet["movementCooldown"] = 0
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "殖民地建立", "%s 的前哨殖民阶段已经完成，殖民地正式转入稳定发展。" % system.get("name", ""), "EVENT")
	return next_state

static func apply_player_fleet_missions(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player_id: String = player_faction(next_state).get("id", "f_player")
	var fleet_ids: Array = []
	for fleet: Dictionary in next_state.get("fleets", []):
		if fleet.get("ownerId", "") == player_id:
			fleet_ids.append(fleet.get("id", ""))
	for fleet_id: String in fleet_ids:
		var fleet: Dictionary = {}
		for candidate: Dictionary in next_state.get("fleets", []):
			if candidate.get("id", "") == fleet_id:
				fleet = candidate
				break
		if fleet.is_empty():
			continue
		if int(fleet.get("movementCooldown", 0)) > 0:
			continue
		var mission: String = str(fleet.get("mission", "IDLE"))
		match mission:
			"EXPLORE":
				for target_system_id: String in reachable_systems(next_state, fleet_id):
					var target_system: Dictionary = {}
					for system: Dictionary in next_state.get("starSystems", []):
						if system.get("id", "") == target_system_id:
							target_system = system
							break
					if not target_system.is_empty() and target_system.get("visibilityLevel", "") != "FULL":
						next_state = explore_system(next_state, fleet_id, target_system_id)
						break
			"COLONIZE":
				var current_system_id: String = str(fleet.get("systemId", ""))
				var current_preview: Dictionary = colonization_preview(next_state, fleet_id, current_system_id, "STANDARD")
				if current_preview.get("allowed", false):
					next_state = colonize_system(next_state, fleet_id, current_system_id, "STANDARD")
					continue
				for target_system_id: String in reachable_systems(next_state, fleet_id):
					var target_system: Dictionary = {}
					for system: Dictionary in next_state.get("starSystems", []):
						if system.get("id", "") == target_system_id:
							target_system = system
							break
					if not target_system.is_empty() and target_system.get("ownerId", null) == null and target_system.get("visibilityLevel", "") == "FULL":
						next_state = move_fleet(next_state, fleet_id, target_system_id)
						break
			"STRIKE":
				var current_system_id: String = str(fleet.get("systemId", ""))
				var enemy_in_system: Dictionary = {}
				for enemy_fleet: Dictionary in next_state.get("fleets", []):
					if enemy_fleet.get("systemId", "") == current_system_id and enemy_fleet.get("ownerId", "") != player_id:
						enemy_in_system = enemy_fleet
						break
				if not enemy_in_system.is_empty():
					next_state = initiate_combat_protocol(next_state, fleet_id, "FLEET", enemy_in_system.get("id", ""), "ALL_OUT", "LINE", "BATTLE_LINE")
					continue
				for target_system_id: String in reachable_systems(next_state, fleet_id):
					var hostile_present: bool = false
					for enemy_fleet: Dictionary in next_state.get("fleets", []):
						if enemy_fleet.get("systemId", "") == target_system_id and enemy_fleet.get("ownerId", "") != player_id:
							hostile_present = true
							break
					if hostile_present:
						next_state = move_fleet(next_state, fleet_id, target_system_id)
						break
	return next_state

static func move_fleet(state: Dictionary, fleet_id: String, target_system_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var fleet_index: int = -1
	var fleet: Dictionary = {}
	for index: int in range(next_state.get("fleets", []).size()):
		var item: Dictionary = next_state["fleets"][index]
		if item.get("id", "") == fleet_id:
			fleet_index = index
			fleet = item
			break
	if fleet_index == -1 or fleet.get("ownerId", "") != player.get("id", ""):
		return next_state
	if str(fleet.get("mission", "IDLE")) == "COLONIZING":
		return add_message(next_state, "舰队正在殖民部署", "%s 正在建立殖民据点，部署完成前无法移动。" % str(fleet.get("name", "舰队")), "SYSTEM")
	if int(fleet.get("movementCooldown", 0)) > 0:
		return add_message(next_state, "舰队仍在航行", "%s 仍处于航行冷却中，还需 %s 回合才能再次移动。" % [str(fleet.get("name", "舰队")), str(fleet.get("movementCooldown", 0))], "SYSTEM")
	if not connected_to(next_state, fleet.get("systemId", "")).has(target_system_id):
		return next_state
	var source_system_id: String = str(fleet.get("systemId", ""))
	var cost: int = 1
	var bandwidth: int = 0
	for lane: Dictionary in next_state.get("hyperlanes", []):
		var direct: bool = lane.get("startSystemId", "") == source_system_id and lane.get("endSystemId", "") == target_system_id
		var reverse: bool = lane.get("endSystemId", "") == source_system_id and lane.get("startSystemId", "") == target_system_id
		if direct or reverse:
			cost = int(lane.get("traversalCost", 1))
			bandwidth = int(lane.get("bandwidth", 0))
	if bandwidth > 0 and fleet.get("ships", []).size() > bandwidth:
		return add_message(next_state, "航道容量不足", "%s 当前舰船数为 %s，超过了这条航道的容量上限 %s。" % [str(fleet.get("name", "舰队")), str(fleet.get("ships", []).size()), str(bandwidth)], "SYSTEM")
	if int(player.get("resources", {}).get("energy", 0)) < cost:
		return add_message(next_state, "能源不足", "当前能源储备不足以支付本次舰队移动的航行消耗。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			var resources: Dictionary = faction.get("resources", {}).duplicate(true)
			resources["energy"] = int(resources.get("energy", 0)) - cost
			faction["resources"] = resources
			next_state["factions"][faction_index] = faction
	fleet["systemId"] = target_system_id
	fleet["movementCooldown"] = max(0, cost - 1)
	fleet["lastTraversalCost"] = cost
	next_state["fleets"][fleet_index] = fleet
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") == target_system_id:
			system["visibilityLevel"] = "FULL"
			next_state["starSystems"][system_index] = system
	next_state = add_message(next_state, "舰队已移动", "%s 已完成本次跃迁并抵达目标星系。" % fleet.get("name", ""), "EVENT")
	next_state = resolve_player_system_event(next_state, target_system_id)
	var enemy_fleet_index: int = -1
	var enemy_fleet: Dictionary = {}
	for index: int in range(next_state["fleets"].size()):
		var item: Dictionary = next_state["fleets"][index]
		if item.get("systemId", "") == target_system_id and item.get("ownerId", "") != player.get("id", ""):
			enemy_fleet_index = index
			enemy_fleet = item
			break
	if enemy_fleet_index != -1:
		var moved_fleet: Dictionary = next_state["fleets"][fleet_index]
		var player_wins: bool = fleet_power(moved_fleet) >= fleet_power(enemy_fleet)
		if player_wins:
			next_state["fleets"][fleet_index] = damage_fleet(moved_fleet, 24)
			next_state["fleets"].remove_at(enemy_fleet_index)
			for system_index: int in range(next_state["starSystems"].size()):
				var captured_system: Dictionary = next_state["starSystems"][system_index]
				if captured_system.get("id", "") == target_system_id:
					captured_system["ownerId"] = player.get("id", "")
					captured_system["visibilityLevel"] = "FULL"
					next_state["starSystems"][system_index] = captured_system
			next_state = add_message(next_state, "遭遇战胜利", "%s 在抵达后迅速击溃了驻守敌舰。" % moved_fleet.get("name", "舰队"), "COMBAT")
		else:
			next_state["fleets"].remove_at(fleet_index)
			next_state = add_message(next_state, "遭遇战失利", "%s 在抵达后被敌方守军击溃。" % moved_fleet.get("name", "舰队"), "COMBAT")
	next_state = refresh_player_visibility(next_state)
	return assess_game_status(ensure_faction_controls(next_state))

static func explore_system(state: Dictionary, fleet_id: String, system_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var fleet: Dictionary = {}
	for item: Dictionary in next_state.get("fleets", []):
		if item.get("id", "") == fleet_id:
			fleet = item
			break
	if fleet.is_empty() or fleet.get("ownerId", "") != player.get("id", ""):
		return next_state
	var fleet_at_target: bool = str(fleet.get("systemId", "")) == system_id
	if not fleet_at_target and not connected_to(next_state, str(fleet.get("systemId", ""))).has(system_id):
		return next_state
	if not fleet_at_target:
		return _scout_adjacent_system(next_state, fleet, system_id)
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") != system_id or system.get("visibilityLevel", "") == "FULL":
			continue
		system["visibilityLevel"] = "FULL"
		next_state["starSystems"][system_index] = system
	for adjacent_id: String in connected_to(next_state, system_id):
		for system_index: int in range(next_state["starSystems"].size()):
			var adjacent: Dictionary = next_state["starSystems"][system_index]
			if adjacent.get("id", "") == adjacent_id and adjacent.get("visibilityLevel", "") == "HIDDEN":
				adjacent["visibilityLevel"] = "PARTIAL"
				next_state["starSystems"][system_index] = adjacent
	next_state = add_message(next_state, "完成探索", "%s 已完成对目标星系的侦察，周边情报同步更新。" % fleet.get("name", ""), "EVENT")
	next_state = resolve_player_system_event(next_state, system_id)
	next_state = refresh_player_visibility(next_state)
	return assess_game_status(next_state)

static func _scout_adjacent_system(state: Dictionary, fleet: Dictionary, system_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") == system_id and system.get("visibilityLevel", "") == "HIDDEN":
			system["visibilityLevel"] = "PARTIAL"
			next_state["starSystems"][system_index] = system
			break
	next_state = add_message(next_state, "远程侦察", "%s 已完成相邻星系的远程扫描；事件奖励需要舰队抵达后才能结算。" % fleet.get("name", ""), "EVENT")
	next_state = refresh_player_visibility(next_state)
	return assess_game_status(next_state)

static func refresh_player_visibility(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player_id: String = player_faction(next_state).get("id", "f_player")
	var full_visible: Dictionary = {}
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("ownerId", null) == player_id:
			full_visible[str(system.get("id", ""))] = true
	for fleet: Dictionary in next_state.get("fleets", []):
		if fleet.get("ownerId", "") == player_id:
			full_visible[str(fleet.get("systemId", ""))] = true
	var partial_visible: Dictionary = {}
	for system_id: String in full_visible.keys():
		for adjacent_id: String in connected_to(next_state, system_id):
			if not full_visible.has(adjacent_id):
				partial_visible[adjacent_id] = true
	for index: int in range(next_state.get("starSystems", []).size()):
		var system: Dictionary = next_state["starSystems"][index]
		var system_id: String = str(system.get("id", ""))
		if full_visible.has(system_id):
			system["visibilityLevel"] = "FULL"
		elif partial_visible.has(system_id):
			system["visibilityLevel"] = "PARTIAL"
		else:
			system["visibilityLevel"] = "HIDDEN"
		next_state["starSystems"][index] = system
	return next_state

static func colonize_system(state: Dictionary, fleet_id: String, system_id: String, mode: String = "STANDARD") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var preview: Dictionary = colonization_preview(next_state, fleet_id, system_id, mode)
	if not preview.get("allowed", false):
		return add_message(next_state, "殖民启动失败", str(preview.get("reason", "当前条件不满足殖民要求。")), "SYSTEM")
	var system_name: String = system_id
	for entry: Dictionary in next_state.get("starSystems", []):
		if entry.get("id", "") == system_id:
			system_name = entry.get("name", system_id)
			break
	var mode_name: String = colony_mode_data(mode).get("name", mode)
	next_state = start_colony_for_faction(next_state, player.get("id", ""), system_id, mode, "殖民前哨建立", "%s 已启动 %s 模式殖民，殖民船队正在建立前哨与基础补给网络。" % [system_name, mode_name])
	next_state = consume_colonization_fleet(next_state, fleet_id)
	next_state = refresh_player_visibility(next_state)
	return assess_game_status(ensure_faction_controls(next_state))

static func player_freeform_message(state: Dictionary, target_faction_id: String, message_text: String, visibility_level: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if message_text.strip_edges() == "":
		return next_state
	var player: Dictionary = player_faction(next_state)
	var target: Dictionary = get_faction_by_id(next_state, target_faction_id)
	if target.is_empty():
		return next_state
	var intent: Dictionary = parse_player_diplomatic_intent(message_text)
	var trust_delta: int = int(intent.get("trust_delta", 0))
	var tone: String = str(intent.get("tone", "neutral"))
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == player.get("id", "") and relation.get("factionBId", "") == target_faction_id) or (relation.get("factionAId", "") == target_faction_id and relation.get("factionBId", "") == player.get("id", ""))
		if not touches:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) + trust_delta, -100, 100)
		relation["trust"] = trust
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	var title: String = "外交致函"
	var content_type: String = "PROPOSAL"
	match str(intent.get("type", "MESSAGE")):
		"TREATY":
			title = "条约提案"
			content_type = "PROPOSAL"
		"RESTRICTION":
			title = "限制请求"
			content_type = "PROPOSAL"
		"WARNING":
			title = "强硬警告"
			content_type = "WARNING"
		"TRADE":
			title = "交易提案"
			content_type = "PROPOSAL"
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", visibility_level, content_type, title, message_text.strip_edges(), true)
	next_state = add_diplomatic_memory(next_state, title, "玩家向 %s 发起了新的外交接触。" % target.get("name", target_faction_id), [player.get("id", ""), target_faction_id], "PROPOSAL", 1)
	next_state = update_diplomatic_profile(next_state, target_faction_id, tone, trust_delta, "正在评估玩家最新的外交意图。")
	if str(intent.get("type", "")) == "TREATY":
		next_state = propose_treaty(next_state, target_faction_id, str(intent.get("treaty", "NON_AGGRESSION")))
	return next_state

static func receive_ai_reply(state: Dictionary, sender_faction_id: String, title: String, content: String, visibility_level: String, tone: String = "neutral") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	next_state = add_diplomatic_message(next_state, sender_faction_id, ["f_player"], "SINGLE", visibility_level, "REPLY", title, content, true)
	var trust_delta: int = 3 if tone == "friendly" else -5 if tone == "hostile" else -2 if tone == "firm" else 1
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == "f_player" and relation.get("factionBId", "") == sender_faction_id) or (relation.get("factionAId", "") == sender_faction_id and relation.get("factionBId", "") == "f_player")
		if not touches:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) + trust_delta, -100, 100)
		relation["trust"] = trust
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	next_state = update_diplomatic_profile(next_state, sender_faction_id, tone, trust_delta, "")
	return next_state

static func faction_behavior_bias_report(state: Dictionary, faction_id: String) -> Dictionary:
	var faction: Dictionary = get_faction_by_id(state, faction_id)
	var personality: Dictionary = faction.get("personality", {})
	var aggression: float = float(personality.get("aggression", 5.0))
	var paranoia: float = float(personality.get("paranoia", 5.0))
	var greed: float = float(personality.get("greed", 5.0))
	var loyalty: float = float(personality.get("loyalty", 5.0))
	var rationality: float = float(personality.get("rationality", 5.0))
	return {
		"aggression": aggression,
		"paranoia": paranoia,
		"greed": greed,
		"loyalty": loyalty,
		"rationality": rationality,
		"secret_contact_bias": aggression * 1.5 + paranoia * 6.0 + greed * 2.5,
		"group_council_bias": rationality * 5.0 + loyalty * 4.0 + paranoia * 1.8,
		"coercion_bias": aggression * 6.0 + paranoia * 2.5 - loyalty * 1.5,
		"cooperation_bias": rationality * 4.0 + loyalty * 5.0 + greed * 2.0,
		"expansion_bias": aggression * 4.0 + greed * 3.0 - paranoia * 1.5,
	}

static func _memory_pressure_for_pair(state: Dictionary, faction_a_id: String, faction_b_id: String) -> float:
	var pressure: float = 0.0
	for memory: Dictionary in state.get("recentInteractionMemory", []):
		var participants: Array = memory.get("participants", [])
		if not participants.has(faction_a_id) or not participants.has(faction_b_id):
			continue
		pressure += float(memory.get("importance", 1)) * absf(float(memory.get("emotionalImpact", 0.0)))
	for memory: Dictionary in state.get("archivedInteractionMemory", []):
		var archived_participants: Array = memory.get("participants", [])
		if not archived_participants.has(faction_a_id) or not archived_participants.has(faction_b_id):
			continue
		var age_turns: int = maxi(0, int(state.get("turn", 1)) - int(memory.get("turn", 1)))
		pressure += absf(float(memory.get("emotionalImpact", 0.0)) * pow(float(memory.get("decayFactor", 0.98)), age_turns))
	return pressure

static func _should_schedule_backchannel(turn: int, signature: String, threshold: int, cadence_floor: int = 2) -> bool:
	if turn < cadence_floor:
		return false
	var roll: int = abs(signature.hash()) % 100
	return roll < threshold

static func schedule_secret_contact(state: Dictionary, sender_id: String, target_id: String) -> Dictionary:
	var relation: Dictionary = relation_breakdown(state, sender_id, target_id)
	var sender_bias: Dictionary = faction_behavior_bias_report(state, sender_id)
	var memory_pressure: float = _memory_pressure_for_pair(state, sender_id, target_id)
	var player: Dictionary = player_faction(state)
	var player_power: int = int(player.get("militaryPower", 0))
	var urgency_score: float = float(relation.get("fear", 0)) + float(relation.get("memoryImpact", 0)) + memory_pressure * 12.0 + float(player_power) * 0.08
	var trigger_threshold: int = int(clamp(15.0 + float(sender_bias.get("secret_contact_bias", 0.0)) + urgency_score * 0.35, 20.0, 92.0))
	var signature: String = "SECRET_CONTACT|%s|%s|%s" % [str(state.get("turn", 1)), sender_id, target_id]
	if not _should_schedule_backchannel(int(state.get("turn", 1)), signature, trigger_threshold, 3):
		return {}
	return {
		"mode": "SECRET_CONTACT",
		"sender_id": sender_id,
		"target_ids": [target_id],
		"target_type": "SINGLE",
		"visibility_level": "SECRET",
		"content_type": "PROPOSAL",
		"title": "秘密接触",
		"content": "%s 正在与 %s 私下评估围绕玩家扩张的共同应对方案。" % [get_faction_by_id(state, sender_id).get("name", sender_id), get_faction_by_id(state, target_id).get("name", target_id)],
		"memory_title": "秘密接触",
		"memory_summary": "%s 与 %s 建立了未公开的协调接触。" % [get_faction_by_id(state, sender_id).get("name", sender_id), get_faction_by_id(state, target_id).get("name", target_id)],
		"profile_hint": "正在通过非公开沟通协调区域应对。",
		"trust_shift": 3,
		"attachments": {
			"agenda_type": "SECRET_CONTACT",
			"priority": "HIGH" if urgency_score >= 40.0 else "MEDIUM",
			"focus": ["player_pressure", "border_security", "mutual_positioning"],
		},
	}

static func schedule_group_council(state: Dictionary, sender_id: String, target_ids: Array) -> Dictionary:
	var sender_bias: Dictionary = faction_behavior_bias_report(state, sender_id)
	var combined_pressure: float = 0.0
	for target_id: Variant in target_ids:
		combined_pressure += _memory_pressure_for_pair(state, sender_id, str(target_id))
	combined_pressure += float(player_faction(state).get("militaryPower", 0)) * 0.05
	var trigger_threshold: int = int(clamp(18.0 + float(sender_bias.get("group_council_bias", 0.0)) + combined_pressure * 0.4, 20.0, 94.0))
	var signature: String = "GROUP_COUNCIL|%s|%s|%s" % [str(state.get("turn", 1)), sender_id, ",".join(target_ids)]
	if not _should_schedule_backchannel(int(state.get("turn", 1)), signature, trigger_threshold, 4):
		return {}
	return {
		"mode": "GROUP_COUNCIL",
		"sender_id": sender_id,
		"target_ids": target_ids,
		"target_type": "GROUP",
		"visibility_level": "ENCRYPTED",
		"content_type": "NOTIFICATION",
		"title": "加密群组会议",
		"content": "%s 发起了一场围绕局势升级与区域秩序的加密群组会议。" % get_faction_by_id(state, sender_id).get("name", sender_id),
		"memory_title": "加密群组会议",
		"memory_summary": "%s 正在通过群组会议协调各方对当前局势的立场。" % get_faction_by_id(state, sender_id).get("name", sender_id),
		"profile_hint": "倾向通过多边会议塑造区域共识。",
		"trust_shift": 1,
		"attachments": {
			"agenda_type": "GROUP_COUNCIL",
			"focus": ["regional_balance", "escalation_control", "joint_signal"],
			"priority": "HIGH" if combined_pressure >= 18.0 else "MEDIUM",
		},
	}

static func generate_backchannel_agenda(state: Dictionary) -> Array:
	var agendas: Array = []
	var secret_contact: Dictionary = schedule_secret_contact(state, "f_merchant", "f_orchid")
	if not secret_contact.is_empty():
		agendas.append(secret_contact)
	var group_council: Dictionary = schedule_group_council(state, "f_orchid", ["f_player", "f_merchant"])
	if not group_council.is_empty():
		agendas.append(group_council)
	return agendas

static func simulate_ai_backchannel(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var merchant: Dictionary = get_faction_by_id(next_state, "f_merchant")
	var orchid: Dictionary = get_faction_by_id(next_state, "f_orchid")
	if merchant.is_empty() or orchid.is_empty():
		return next_state
	for agenda: Dictionary in generate_backchannel_agenda(next_state):
		var sender_id: String = str(agenda.get("sender_id", ""))
		var target_ids: Array = agenda.get("target_ids", [])
		var visibility_level: String = str(agenda.get("visibility_level", "SECRET"))
		var intercepted: bool = should_intercept_message(next_state, sender_id, target_ids, visibility_level)
		next_state = add_diplomatic_message(
			next_state,
			sender_id,
			target_ids,
			str(agenda.get("target_type", "SINGLE")),
			visibility_level,
			str(agenda.get("content_type", "NOTIFICATION")),
			str(agenda.get("title", "秘密交流")),
			str(agenda.get("content", "")),
			intercepted,
			agenda.get("attachments", {}),
			{"encryptionLevel": 85 if visibility_level == "ENCRYPTED" else 55, "expiresAfterTurns": 12}
		)
		if intercepted:
			next_state = add_diplomatic_memory(next_state, "截获%s" % str(agenda.get("title", "通信")), str(agenda.get("memory_summary", "")), [sender_id] + target_ids, "INTEL", 3)
		else:
			next_state = add_diplomatic_memory(next_state, str(agenda.get("memory_title", "外交接触")), str(agenda.get("memory_summary", "")), [sender_id] + target_ids, str(agenda.get("mode", "BACKCHANNEL")), 2)
		next_state = update_diplomatic_profile(next_state, sender_id, "firm" if str(agenda.get("mode", "")) == "SECRET_CONTACT" else "neutral", 0, str(agenda.get("profile_hint", "")))
		for target_id: Variant in target_ids:
			for index: int in range(next_state["relationships"].size()):
				var relation: Dictionary = next_state["relationships"][index]
				var touches: bool = (relation.get("factionAId", "") == sender_id and relation.get("factionBId", "") == str(target_id)) or (relation.get("factionAId", "") == str(target_id) and relation.get("factionBId", "") == sender_id)
				if not touches:
					continue
				var trust: int = clamp(int(relation.get("trust", 0)) + int(agenda.get("trust_shift", 0)), -100, 100)
				relation["trust"] = trust
				relation["level"] = relation_level(trust)
				next_state["relationships"][index] = relation
	if int(next_state.get("turn", 1)) % 5 == 0:
		next_state = add_diplomatic_message(next_state, "f_orchid", ["f_player", "f_merchant"], "BROADCAST", "PUBLIC", "NOTIFICATION", "公开局势声明", "兰花共识向周边势力发布了一份公开局势声明。", true)
		next_state = add_diplomatic_memory(next_state, "公开局势声明", "兰花共识正在尝试以公开姿态塑造周边外交氛围。", ["f_orchid", "f_player", "f_merchant"], "PUBLIC", 2)
		next_state = update_diplomatic_profile(next_state, "f_orchid", "friendly", 1, "希望通过公开发言塑造更稳定的局势。")
	return next_state

static func simulate_ai_proposals(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var orchid_relation: Dictionary = relation_breakdown(next_state, "f_player", "f_orchid")
	var merchant_relation: Dictionary = relation_breakdown(next_state, "f_player", "f_merchant")
	var turn: int = int(next_state.get("turn", 1))
	var orchid_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_orchid", 3)
	var merchant_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_merchant", 3)
	if has_treaty(next_state, "f_merchant", "f_player", "WAR_STATE") and turn % 4 == 0 and (int(merchant_relation.get("fear", 0)) >= 35 or int(merchant_relation.get("utility", 0)) >= 20):
		next_state = create_pending_proposal(next_state, "f_merchant", "f_player", "PEACE_TALK", "停火谈判", "商路联盟提议临时停火，并讨论有限和平条款。")
		next_state = update_diplomatic_profile(next_state, "f_merchant", "firm", 1, "战争成本正在上升，希望争取有限停火。")
	if has_treaty(next_state, "f_orchid", "f_player", "WAR_STATE") and turn % 5 == 0 and int(orchid_relation.get("utility", 0)) >= 16:
		next_state = create_pending_proposal(next_state, "f_orchid", "f_player", "PEACE_TALK", "调停停火", "兰花共识提议结束敌对状态，并恢复和平对话。")
		next_state = update_diplomatic_profile(next_state, "f_orchid", "firm", 1, "持续战争正在破坏区域稳定。")
	if turn % 6 == 0 and int(orchid_relation.get("trust", 0)) + int(orchid_relation.get("utility", 0)) / 3 >= 15 and not has_treaty(next_state, "f_orchid", "f_player", "NON_AGGRESSION"):
		next_state = create_pending_proposal(next_state, "f_orchid", "f_player", "NON_AGGRESSION", "互不侵犯条约", "兰花共识希望签署互不侵犯条约，以稳定边境。")
		next_state = update_diplomatic_profile(next_state, "f_orchid", "friendly", 2, "倾向于可预期且稳定的边境政策。")
	elif turn % 8 == 0 and (int(orchid_relation.get("trust", 0)) >= 30 or bool(orchid_trend.get("trust_rising", false))) and int(orchid_relation.get("utility", 0)) >= 18 and has_research(next_state, "tech_diplomatic_protocols") and not has_treaty(next_state, "f_orchid", "f_player", "RESEARCH_ACCORD"):
		next_state = create_pending_proposal(next_state, "f_orchid", "f_player", "RESEARCH_ACCORD", "科研协定", "兰花共识提议围绕战略科技建立联合研究协定。")
		next_state = update_diplomatic_profile(next_state, "f_orchid", "friendly", 3, "科研收益已经超过竞争损耗。")
	if turn % 7 == 0 and (int(merchant_relation.get("trust", 0)) >= 25 or bool(merchant_trend.get("trust_rising", false))) and int(merchant_relation.get("utility", 0)) >= 18 and not has_treaty(next_state, "f_merchant", "f_player", "TRADE_PACT"):
		next_state = create_pending_proposal(next_state, "f_merchant", "f_player", "TRADE_PACT", "贸易协定", "商路联盟提议降低关税并开放新的贸易航路。")
		next_state = update_diplomatic_profile(next_state, "f_merchant", "friendly", 2, "扩展贸易走廊是当前优先事项。")
	elif turn % 5 == 0 and (int(merchant_relation.get("trust", 0)) <= -35 or int(merchant_relation.get("memoryImpact", 0)) >= 12 or bool(merchant_trend.get("pressure_rising", false))):
		next_state = add_diplomatic_message(next_state, "f_merchant", ["f_player"], "SINGLE", "PUBLIC", "WARNING", "市场警告", "商路联盟警告称，制裁与航路管制可能进一步升级。", true)
		next_state = add_diplomatic_memory(next_state, "市场警告", "商路联盟发出了升级警告。", ["f_player", "f_merchant"], "WARNING", 2)
		next_state = update_diplomatic_profile(next_state, "f_merchant", "hostile", -3, "对玩家施加的商业压力正在上升。")
		if not has_treaty(next_state, "f_merchant", "f_player", "WAR_STATE") and int(merchant_relation.get("fear", 0)) + int(merchant_relation.get("utility", 0)) / 2 < 18:
			next_state = create_pending_proposal(next_state, "f_merchant", "f_player", "ULTIMATUM", "最后通牒", "商路联盟要求你立即作出政策让步，否则将走向战争。", 2)
			next_state = update_diplomatic_profile(next_state, "f_merchant", "hostile", -2, "高压态势下已发出最后通牒。")
	elif turn % 6 == 0 and (int(orchid_relation.get("fear", 0)) >= 55 or bool(orchid_trend.get("pressure_rising", false))) and int(orchid_relation.get("trust", 0)) < 10:
		next_state = add_diplomatic_message(next_state, "f_orchid", ["f_player"], "SINGLE", "PUBLIC", "WARNING", "安全警告", "兰花共识警告称，若继续挑衅，可能触发军事回应。", true)
		next_state = add_diplomatic_memory(next_state, "安全警告", "兰花共识发出了高等级威慑警告。", ["f_player", "f_orchid"], "WARNING", 2)
		next_state = update_diplomatic_profile(next_state, "f_orchid", "firm", -2, "安全压力正在逼近临界阈值。")
		if not has_treaty(next_state, "f_orchid", "f_player", "WAR_STATE") and int(orchid_relation.get("fear", 0)) >= 65:
			next_state = create_pending_proposal(next_state, "f_orchid", "f_player", "ULTIMATUM", "威慑通牒", "兰花共识要求你立即降级冲突，否则对抗将不可避免。", 2)
	return next_state

static func merchant_ai_turn(state: Dictionary, decision: Dictionary = {}) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if next_state.get("status", "") != "PLAYING":
		return next_state
	var merchant: Dictionary = {}
	for faction: Dictionary in next_state.get("factions", []):
		if faction.get("id", "") == "f_merchant":
			merchant = faction
			break
	if merchant.is_empty():
		return next_state
	var merchant_fleet: Dictionary = {}
	for fleet: Dictionary in next_state.get("fleets", []):
		if fleet.get("ownerId", "") == "f_merchant":
			merchant_fleet = fleet
			break
	var relation: Dictionary = relation_between(next_state, "f_player", "f_merchant")
	var relation_view: Dictionary = relation_breakdown(next_state, "f_player", "f_merchant")
	var merchant_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_merchant", 4)
	var merchant_posture: Dictionary = strategic_posture_report(next_state, "f_merchant")
	var merchant_bias: Dictionary = faction_behavior_bias_report(next_state, "f_merchant")
	var merchant_home: Dictionary = {}
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("ownerId", null) == "f_merchant":
			merchant_home = system
			break
	var merchant_resources: Dictionary = merchant.get("resources", {})
	if not merchant_home.is_empty():
		var has_shipyard: bool = system_has_or_queued_building(next_state, merchant_home.get("id", ""), "SHIPYARD")
		var merchant_build_priority: String = choose_ai_building_priority(next_state, "f_merchant", merchant_home, "AGGRESSIVE")
		if merchant_build_priority != "":
			var merchant_blueprint: Dictionary = find_building_blueprint(merchant_build_priority)
			if not merchant_blueprint.is_empty() and can_afford(merchant_resources, merchant_blueprint.get("cost", {})):
				next_state = queue_structure_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), merchant_blueprint, "商路联盟安排建设", "商路联盟在本土星系追加了一项基础设施建设计划。")
				merchant = get_faction_by_id(next_state, "f_merchant")
				merchant_resources = merchant.get("resources", {})
				has_shipyard = has_shipyard or merchant_build_priority == "SHIPYARD"
		if has_shipyard:
			var ship_type: String = "CRUISER" if int(next_state.get("turn", 1)) >= 14 else "DESTROYER" if int(next_state.get("turn", 1)) >= 10 else "CORVETTE"
			if can_queue_ship_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), ship_type):
				next_state = queue_ship_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), ship_type, "商路联盟扩编舰队", "商路联盟开始建造 ")
	if not decision.is_empty():
		var action: String = decision.get("action", "WAIT")
		if action == "TRADE" and int(relation_view.get("trust", 0)) + int(relation_view.get("utility", 0)) / 2 >= 0:
			next_state = add_message(next_state, "商路联盟发起贸易接触", "商路联盟希望与你重启资源交换，并测试新的通商配额。", "DIPLOMATIC")
		elif action == "DECLARE_WAR" and int(relation_view.get("fear", 0)) <= 60 and not merchant_posture.get("high_pressure", []).has("兰花共识"):
			next_state = declare_war_on_faction(next_state, "f_merchant", "f_player")
		elif action == "EXPLORE" and not merchant_fleet.is_empty():
			for fleet_index: int in range(next_state["fleets"].size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("id", "") == merchant_fleet.get("id", ""):
					var destination_id: String = str(decision.get("target", fleet.get("systemId", "")))
					if int(fleet.get("movementCooldown", 0)) <= 0 and connected_to(next_state, fleet.get("systemId", "")).has(destination_id):
						var travel_cost: int = lane_traversal_cost(next_state, str(fleet.get("systemId", "")), destination_id)
						fleet["systemId"] = destination_id
						fleet["movementCooldown"] = max(0, travel_cost - 1)
						fleet["lastTraversalCost"] = travel_cost
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "商路联盟舰队调动", "商路联盟将舰队调往 %s 附近执行侦察与护航任务。" % decision.get("target", ""), "EVENT")
		elif action == "BUILD":
			var build_target: String = str(decision.get("target", ""))
			if can_queue_ship_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), build_target):
				next_state = queue_ship_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), build_target, "商路联盟执行建造决策", "商路联盟根据战略评估开始建造 ")
			else:
				var build_blueprint: Dictionary = find_building_blueprint(build_target)
				if can_queue_structure_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), build_blueprint):
					next_state = queue_structure_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), build_blueprint, "商路联盟执行建造决策", "商路联盟根据战略评估安排新的基础设施。")
				else:
					next_state = add_message(next_state, "商路联盟建造决策未执行", "商路联盟的建造目标当前不满足资源、解锁或星系条件。", "EVENT")
	elif not merchant_fleet.is_empty():
		var neutral_target: Dictionary = {}
		for connected_id: String in connected_to(next_state, merchant_fleet.get("systemId", "")):
			var system: Dictionary = {}
			for entry: Dictionary in next_state.get("starSystems", []):
				if entry.get("id", "") == connected_id:
					system = entry
					break
			if system.is_empty() or system.get("ownerId", null) != null:
				continue
			if neutral_target.is_empty():
				neutral_target = system
				continue
			var current_value: int = int(system.get("resources", {}).get("energy", 0)) * 3 + int(system.get("resources", {}).get("minerals", 0)) * 3 + int(system.get("resources", {}).get("industry", 0)) * 2 + int(system.get("resources", {}).get("food", 0))
			var previous_value: int = int(neutral_target.get("resources", {}).get("energy", 0)) * 3 + int(neutral_target.get("resources", {}).get("minerals", 0)) * 3 + int(neutral_target.get("resources", {}).get("industry", 0)) * 2 + int(neutral_target.get("resources", {}).get("food", 0))
			if current_value > previous_value:
				neutral_target = system
		var expansion_threshold: int = maxi(10, 28 - int(round(float(merchant_bias.get("expansion_bias", 0.0)) / 5.0)))
		var should_expand: bool = int(relation_view.get("fear", 0)) >= 50 or int(relation_view.get("utility", 0)) >= expansion_threshold or int(relation_view.get("memoryImpact", 0)) >= 6 or bool(merchant_trend.get("pressure_rising", false))
		if not neutral_target.is_empty() and should_expand:
			for fleet_index: int in range(next_state["fleets"].size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("id", "") == merchant_fleet.get("id", ""):
					var neutral_destination_id: String = str(neutral_target.get("id", ""))
					if int(fleet.get("movementCooldown", 0)) <= 0 and connected_to(next_state, fleet.get("systemId", "")).has(neutral_destination_id):
						var neutral_travel_cost: int = lane_traversal_cost(next_state, str(fleet.get("systemId", "")), neutral_destination_id)
						fleet["systemId"] = neutral_destination_id
						fleet["movementCooldown"] = max(0, neutral_travel_cost - 1)
						fleet["lastTraversalCost"] = neutral_travel_cost
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "商路联盟前出侦察", "商路联盟舰队正在向 %s 推进，尝试抢占新的贸易节点。" % neutral_target.get("name", ""), "EVENT")
	var updated_merchant_fleet: Dictionary = {}
	for fleet: Dictionary in next_state.get("fleets", []):
		if fleet.get("ownerId", "") == "f_merchant":
			updated_merchant_fleet = fleet
			break
	if not updated_merchant_fleet.is_empty():
		var occupied_system: Dictionary = {}
		for system: Dictionary in next_state.get("starSystems", []):
			if system.get("id", "") == updated_merchant_fleet.get("systemId", ""):
				occupied_system = system
				break
		if not occupied_system.is_empty() and occupied_system.get("ownerId", null) == null and int(next_state.get("turn", 1)) >= 4 and can_afford(merchant.get("resources", {}), colony_mode_data("RESOURCE_OUTPOST").get("cost", COLONY_COST)) and int(relation_view.get("fear", 0)) >= 18:
			next_state = start_colony_for_faction(next_state, "f_merchant", occupied_system.get("id", ""), "RESOURCE_OUTPOST", "商路联盟建立资源前哨", "商路联盟在 %s 投入殖民队伍，准备建立新的资源前哨。" % occupied_system.get("name", "未知星系"))
	if (bool(merchant_trend.get("opportunity_rising", false)) or float(merchant_bias.get("cooperation_bias", 0.0)) >= 46.0) and not has_treaty(next_state, "f_merchant", "f_player", "TRADE_PACT") and int(next_state.get("turn", 1)) % 4 == 0:
		next_state = add_diplomatic_message(next_state, "f_merchant", ["f_player"], "SINGLE", "PUBLIC", "PROPOSAL", "商路联盟建议重启通商", "商路联盟认为当前局势适合恢复更大规模的资源交换，希望与你讨论新的贸易协定。", true)
	if (bool(merchant_trend.get("pressure_rising", false)) or float(merchant_bias.get("coercion_bias", 0.0)) >= 42.0) and int(next_state.get("turn", 1)) % 4 == 0:
		next_state = update_diplomatic_profile(next_state, "f_merchant", "guarded", -1, "认为玩家的扩张压力正在上升，需要保持谨慎观察。")
	return ensure_faction_controls(next_state)

static func can_queue_structure_for_ai(state: Dictionary, owner_id: String, system_id: String, blueprint: Dictionary) -> bool:
	if blueprint.is_empty():
		return false
	var faction: Dictionary = get_faction_by_id(state, owner_id)
	if faction.is_empty() or not can_afford(faction.get("resources", {}), blueprint.get("cost", {})):
		return false
	for system: Dictionary in state.get("starSystems", []):
		if system.get("id", "") != system_id:
			continue
		if system.get("ownerId", null) != owner_id:
			return false
		if int(system.get("buildings", []).size()) + queued_building_count_for_system(state, system_id) >= int(system.get("buildingSlots", 0)):
			return false
		return not system_has_or_queued_building(state, system_id, blueprint.get("type", ""))
	return false

static func can_queue_ship_for_ai(state: Dictionary, owner_id: String, system_id: String, ship_type: String) -> bool:
	if not available_ship_types(state).has(ship_type):
		return false
	var faction: Dictionary = get_faction_by_id(state, owner_id)
	if faction.is_empty() or not can_afford(faction.get("resources", {}), ship_cost(ship_type, state, owner_id)):
		return false
	for system: Dictionary in state.get("starSystems", []):
		if system.get("id", "") != system_id:
			continue
		if system.get("ownerId", null) != owner_id:
			return false
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "SHIPYARD":
				return true
		return false
	return false

static func queue_structure_for_ai(state: Dictionary, owner_id: String, system_id: String, blueprint: Dictionary, message_title: String = "AI 安排建设", message_content: String = "AI 势力在其控制星系中安排了一项新的建筑建设。") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if not can_queue_structure_for_ai(next_state, owner_id, system_id, blueprint):
		return next_state
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == owner_id:
			faction["resources"] = subtract_resources(faction.get("resources", {}), blueprint.get("cost", {}))
			next_state["factions"][faction_index] = faction
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append({
		"id": make_state_id(next_state, "queue"),
		"systemId": system_id,
		"ownerId": owner_id,
		"kind": "BUILDING",
		"targetId": blueprint.get("type", ""),
		"displayName": blueprint.get("name", ""),
		"turnsRemaining": InitialDataScript.building_turns().get(blueprint.get("type", ""), 1),
		"totalTurns": InitialDataScript.building_turns().get(blueprint.get("type", ""), 1)
	})
	next_state["constructionQueue"] = queue
	return add_message(next_state, message_title, message_content, "EVENT")

static func queue_ship_for_ai(state: Dictionary, owner_id: String, system_id: String, ship_type: String, message_title: String = "AI 扩编舰队", message_prefix: String = "AI 势力开始建造 ") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if not can_queue_ship_for_ai(next_state, owner_id, system_id, ship_type):
		return next_state
	var cost: Dictionary = ship_cost(ship_type, next_state, owner_id)
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == owner_id:
			faction["resources"] = subtract_resources(faction.get("resources", {}), cost)
			next_state["factions"][faction_index] = faction
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append({
		"id": make_state_id(next_state, "queue"),
		"systemId": system_id,
		"ownerId": owner_id,
		"kind": "SHIP",
		"targetId": ship_type,
		"displayName": InitialDataScript.ship_labels().get(ship_type, ship_type),
		"turnsRemaining": InitialDataScript.ship_turns().get(ship_type, 1),
		"totalTurns": InitialDataScript.ship_turns().get(ship_type, 1)
	})
	next_state["constructionQueue"] = queue
	return add_message(next_state, message_title, "%s%s。" % [message_prefix, InitialDataScript.ship_labels().get(ship_type, ship_type)], "EVENT")

static func choose_ai_building_priority(state: Dictionary, faction_id: String, home_system: Dictionary, profile: String) -> String:
	if home_system.is_empty():
		return ""
	var faction: Dictionary = get_faction_by_id(state, faction_id)
	var rates: Dictionary = faction.get("resourceRates", {})
	var system_id: String = str(home_system.get("id", ""))
	if int(rates.get("energy", 0)) <= 0 and not system_has_or_queued_building(state, system_id, "FUSION_REACTOR"):
		return "FUSION_REACTOR"
	if int(rates.get("food", 0)) <= 0 and not system_has_or_queued_building(state, system_id, "HYDROPONICS"):
		return "HYDROPONICS"
	if profile == "AGGRESSIVE":
		if not system_has_or_queued_building(state, system_id, "SHIPYARD"):
			return "SHIPYARD"
		if not system_has_or_queued_building(state, system_id, "DEFENSE_PLATFORM"):
			return "DEFENSE_PLATFORM"
	elif profile == "DEFENSIVE":
		if not system_has_or_queued_building(state, system_id, "DEFENSE_PLATFORM"):
			return "DEFENSE_PLATFORM"
		if not system_has_or_queued_building(state, system_id, "RESEARCH_LAB"):
			return "RESEARCH_LAB"
	else:
		if not system_has_or_queued_building(state, system_id, "RESEARCH_LAB"):
			return "RESEARCH_LAB"
		if not system_has_or_queued_building(state, system_id, "SHIPYARD"):
			return "SHIPYARD"
	if int(rates.get("minerals", 0)) < int(rates.get("industry", 0)) and not system_has_or_queued_building(state, system_id, "MINING_STATION"):
		return "MINING_STATION"
	if not system_has_or_queued_building(state, system_id, "INTEGRATED_FACTORY"):
		return "INTEGRATED_FACTORY"
	return ""

static func orchid_ai_turn(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if next_state.get("status", "") != "PLAYING":
		return next_state
	var orchid: Dictionary = get_faction_by_id(next_state, "f_orchid")
	if orchid.is_empty():
		return next_state
	var orchid_home: Dictionary = {}
	var orchid_fleet: Dictionary = {}
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("ownerId", null) == "f_orchid":
			orchid_home = system
			break
	for fleet: Dictionary in next_state.get("fleets", []):
		if fleet.get("ownerId", "") == "f_orchid":
			orchid_fleet = fleet
			break
	var orchid_resources: Dictionary = orchid.get("resources", {})
	var orchid_bias: Dictionary = faction_behavior_bias_report(next_state, "f_orchid")
	if not orchid_home.is_empty():
		var has_lab: bool = system_has_or_queued_building(next_state, orchid_home.get("id", ""), "RESEARCH_LAB")
		var has_shipyard: bool = system_has_or_queued_building(next_state, orchid_home.get("id", ""), "SHIPYARD")
		var orchid_build_priority: String = choose_ai_building_priority(next_state, "f_orchid", orchid_home, "DEFENSIVE")
		if orchid_build_priority != "":
			var orchid_blueprint: Dictionary = find_building_blueprint(orchid_build_priority)
			if not orchid_blueprint.is_empty() and can_afford(orchid_resources, orchid_blueprint.get("cost", {})):
				next_state = queue_structure_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), orchid_blueprint, "兰花共识安排建设", "兰花共识在核心星系追加了一项偏研究与防御取向的建设。")
				orchid = get_faction_by_id(next_state, "f_orchid")
				orchid_resources = orchid.get("resources", {})
				has_lab = has_lab or orchid_build_priority == "RESEARCH_LAB"
				has_shipyard = has_shipyard or orchid_build_priority == "SHIPYARD"
		if has_shipyard:
			var orchid_ship_type: String = "DESTROYER" if int(next_state.get("turn", 1)) >= 12 else "CORVETTE"
			if can_queue_ship_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), orchid_ship_type):
				next_state = queue_ship_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), orchid_ship_type, "兰花共识扩编舰队", "兰花共识开始建造 ")
	if not orchid_fleet.is_empty():
		var player_relation: Dictionary = relation_breakdown(next_state, "f_player", "f_orchid")
		var merchant_relation: Dictionary = relation_breakdown(next_state, "f_merchant", "f_orchid")
		var orchid_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_orchid", 4)
		var seek_neutral: bool = ((int(player_relation.get("fear", 0)) >= 50 or int(player_relation.get("trust", 0)) >= 0) and int(merchant_relation.get("trust", 0)) >= -10) or float(orchid_bias.get("cooperation_bias", 0.0)) >= 48.0
		var preferred_target: Dictionary = {}
		for connected_id: String in connected_to(next_state, orchid_fleet.get("systemId", "")):
			var candidate: Dictionary = {}
			for entry: Dictionary in next_state.get("starSystems", []):
				if entry.get("id", "") == connected_id:
					candidate = entry
					break
			if candidate.is_empty():
				continue
			if (seek_neutral or bool(orchid_trend.get("pressure_rising", false))) and candidate.get("ownerId", null) == null:
				if preferred_target.is_empty() or int(candidate.get("habitability", 0)) > int(preferred_target.get("habitability", 0)):
					preferred_target = candidate
			elif not seek_neutral and candidate.get("ownerId", null) == "f_player" and int(player_relation.get("fear", 0)) <= 45 and not bool(orchid_trend.get("opportunity_rising", false)):
				preferred_target = candidate
		if not preferred_target.is_empty() and preferred_target.get("id", "") != orchid_fleet.get("systemId", ""):
			for fleet_index: int in range(next_state["fleets"].size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("id", "") == orchid_fleet.get("id", ""):
					var preferred_destination_id: String = str(preferred_target.get("id", ""))
					if int(fleet.get("movementCooldown", 0)) <= 0 and connected_to(next_state, fleet.get("systemId", "")).has(preferred_destination_id):
						var preferred_travel_cost: int = lane_traversal_cost(next_state, str(fleet.get("systemId", "")), preferred_destination_id)
						fleet["systemId"] = preferred_destination_id
						fleet["movementCooldown"] = max(0, preferred_travel_cost - 1)
						fleet["lastTraversalCost"] = preferred_travel_cost
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "兰花共识前出侦察", "兰花共识舰队正在向 %s 机动，以评估新的扩张机会。" % preferred_target.get("name", "未知星系"), "EVENT")
		var occupied_system: Dictionary = {}
		for system_entry: Dictionary in next_state.get("starSystems", []):
			if system_entry.get("id", "") == orchid_fleet.get("systemId", ""):
				occupied_system = system_entry
				break
		if not occupied_system.is_empty() and occupied_system.get("ownerId", null) == null and int(next_state.get("turn", 1)) >= 5:
			var mode: String = "STANDARD" if int(occupied_system.get("habitability", 0)) >= 70 else "RESOURCE_OUTPOST"
			var mode_cost: Dictionary = colony_mode_data(mode).get("cost", COLONY_COST)
			if can_afford(orchid.get("resources", {}), mode_cost):
				next_state = start_colony_for_faction(next_state, "f_orchid", occupied_system.get("id", ""), mode, "兰花共识启动殖民计划", "兰花共识在 %s 启动了新的殖民行动。" % occupied_system.get("name", "未知星系"))
		if bool(orchid_trend.get("opportunity_rising", false)) and int(next_state.get("turn", 1)) % 5 == 0:
			next_state = update_diplomatic_profile(next_state, "f_orchid", "warm", 1, "认为当前局势正在向有利于自身扩张的方向变化。")
		elif float(orchid_bias.get("coercion_bias", 0.0)) >= 44.0 and int(player_relation.get("fear", 0)) >= 40:
			next_state = update_diplomatic_profile(next_state, "f_orchid", "firm", -1, "在安全压力上升时准备采取更强硬的威慑立场。")
	return next_state

static func process_configured_ai_turns(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = merchant_ai_turn(state)
	next_state = orchid_ai_turn(next_state)
	for faction: Dictionary in next_state.get("factions", []):
		var faction_id: String = str(faction.get("id", ""))
		if faction_id == "f_player":
			continue
		next_state = _process_generic_configured_ai_faction(next_state, faction_id)
	return next_state

static func _process_generic_configured_ai_faction(state: Dictionary, faction_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var faction: Dictionary = get_faction_by_id(next_state, faction_id)
	if faction.is_empty():
		return next_state
	var owned_system: Dictionary = {}
	for system: Dictionary in next_state.get("starSystems", []):
		if str(system.get("ownerId", "")) == faction_id:
			owned_system = system
			break
	if not owned_system.is_empty():
		var profile: String = "AGGRESSIVE" if float(faction.get("personality", {}).get("aggression", 4.0)) >= 6.0 else "DEFENSIVE" if str(faction.get("victoryFocus", "")) == "DIPLOMACY" else "BALANCED"
		var build_type: String = choose_ai_building_priority(next_state, faction_id, owned_system, profile)
		var blueprint: Dictionary = find_building_blueprint(build_type)
		if can_queue_structure_for_ai(next_state, faction_id, str(owned_system.get("id", "")), blueprint):
			next_state = queue_structure_for_ai(next_state, faction_id, str(owned_system.get("id", "")), blueprint, "AI 安排建设", "%s 在 %s 安排 %s，强化长期发展。" % [faction.get("name", faction_id), owned_system.get("name", ""), blueprint.get("name", build_type)])
			next_state = append_ai_action_record(next_state, faction_id, "ECONOMIC_BUILD", str(owned_system.get("id", "")), "%s 开始建设 %s。" % [faction.get("name", faction_id), blueprint.get("name", build_type)])
	var fleet: Dictionary = {}
	for entry: Dictionary in next_state.get("fleets", []):
		if str(entry.get("ownerId", "")) == faction_id:
			fleet = entry
			break
	if not fleet.is_empty():
		var current_system_id: String = str(fleet.get("systemId", ""))
		var target_system: Dictionary = _best_adjacent_ai_target(next_state, faction_id, current_system_id)
		if not target_system.is_empty() and int(fleet.get("movementCooldown", 0)) <= 0:
			var target_id: String = str(target_system.get("id", ""))
			for fleet_index: int in range(next_state.get("fleets", []).size()):
				var movable: Dictionary = next_state["fleets"][fleet_index]
				if str(movable.get("id", "")) != str(fleet.get("id", "")):
					continue
				var travel_cost: int = lane_traversal_cost(next_state, current_system_id, target_id)
				movable["systemId"] = target_id
				movable["movementCooldown"] = max(0, travel_cost - 1)
				movable["lastTraversalCost"] = travel_cost
				next_state["fleets"][fleet_index] = movable
				fleet = movable
				break
			next_state = append_ai_action_record(next_state, faction_id, "FLEET_PRESSURE", target_id, "%s 舰队向 %s 前出，争夺航道主动权。" % [faction.get("name", faction_id), target_system.get("name", target_id)])
		var occupied_system: Dictionary = {}
		for system: Dictionary in next_state.get("starSystems", []):
			if str(system.get("id", "")) == str(fleet.get("systemId", "")):
				occupied_system = system
				break
		if not occupied_system.is_empty() and occupied_system.get("ownerId", null) == null and can_afford(get_faction_by_id(next_state, faction_id).get("resources", {}), colony_mode_data("RESOURCE_OUTPOST").get("cost", COLONY_COST)):
			next_state = start_colony_for_faction(next_state, faction_id, str(occupied_system.get("id", "")), "RESOURCE_OUTPOST", "AI 启动殖民", "%s 在 %s 建立资源前哨。" % [faction.get("name", faction_id), occupied_system.get("name", "")])
			next_state = append_ai_action_record(next_state, faction_id, "COLONY_STARTED", str(occupied_system.get("id", "")), "%s 在 %s 启动殖民前哨。" % [faction.get("name", faction_id), occupied_system.get("name", "")])
	if int(next_state.get("turn", 1)) % 3 == 0:
		next_state = append_ai_action_record(next_state, faction_id, "DIPLOMATIC_SIGNAL", "f_player", "%s 发布新的战略姿态信号，要求周边文明重新评估边境行为。" % faction.get("name", faction_id))
	return next_state

static func _best_adjacent_ai_target(state: Dictionary, faction_id: String, system_id: String) -> Dictionary:
	var best: Dictionary = {}
	for connected_id: String in connected_to(state, system_id):
		var candidate: Dictionary = {}
		for system: Dictionary in state.get("starSystems", []):
			if str(system.get("id", "")) == connected_id:
				candidate = system
				break
		if candidate.is_empty() or str(candidate.get("ownerId", "")) == faction_id:
			continue
		if candidate.get("ownerId", null) != null and str(candidate.get("ownerId", "")) != "f_player":
			continue
		if best.is_empty():
			best = candidate
			continue
		var candidate_value: int = int(candidate.get("habitability", 0)) + int(candidate.get("resources", {}).get("minerals", 0)) * 3 + int(candidate.get("resources", {}).get("energy", 0)) * 2
		var best_value: int = int(best.get("habitability", 0)) + int(best.get("resources", {}).get("minerals", 0)) * 3 + int(best.get("resources", {}).get("energy", 0)) * 2
		if candidate_value > best_value:
			best = candidate
	return best

static func process_turn(state: Dictionary, merchant_decision: Dictionary = {}) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	if next_state.get("status", "") != "PLAYING":
		return next_state
	var research_data: Dictionary = progress_research(next_state)
	next_state["turn"] = int(next_state.get("turn", 1)) + 1
	next_state["era"] = next_era(int(next_state.get("turn", 1)))
	next_state["technologies"] = research_data.get("technologies", next_state.get("technologies", []))
	next_state["currentResearchId"] = research_data.get("currentResearchId", null)
	next_state["researchProgress"] = research_data.get("researchProgress", 0.0)
	if str(research_data.get("completedId", "")) != "":
		next_state = add_researched_tech_to_faction(next_state, "f_player", str(research_data.get("completedId", "")))
	next_state = apply_faction_economy(next_state)
	next_state = progress_colonies(next_state)
	next_state = expire_treaties(next_state)
	next_state = expire_pending_proposals(next_state)
	next_state = apply_passive_repairs(next_state)
	next_state = progress_fleet_movement_cooldowns(next_state)
	next_state = apply_player_fleet_missions(next_state)
	next_state = refresh_player_visibility(next_state)
	next_state = advance_construction_queue(next_state)
	next_state = advance_active_interventions(next_state)
	next_state = update_ascension_progress(next_state)
	if research_data.get("completedName", null) != null:
		next_state = add_message(next_state, "研究完成", "%s 已完成研究并立即生效。" % research_data.get("completedName", ""), "SYSTEM")
	if merchant_decision.is_empty():
		next_state = process_configured_ai_turns(next_state)
	else:
		next_state = merchant_ai_turn(next_state, merchant_decision)
		next_state = orchid_ai_turn(next_state)
	next_state = simulate_ai_backchannel(next_state)
	next_state = simulate_ai_proposals(next_state)
	next_state = append_relationship_snapshots(next_state)
	next_state = update_ai_victory_focuses(next_state)
	next_state = update_galactic_council(next_state)
	next_state = apply_ai_victory_interference(next_state)
	return assess_game_status(ensure_faction_controls(next_state))
