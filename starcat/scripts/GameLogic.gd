extends RefCounted

class_name GameLogic

const COLONY_COST: Dictionary = {"food": 60, "minerals": 50, "industry": 40, "energy": 20}

static func empty_resources() -> Dictionary:
	return {"food": 0, "minerals": 0, "industry": 0, "energy": 0}

static func duplicate_state(state: Dictionary) -> Dictionary:
	return state.duplicate(true)

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

static func has_research(state: Dictionary, tech_id: String) -> bool:
	for tech: Dictionary in state.get("technologies", []):
		if tech.get("id", "") == tech_id and tech.get("status", "") == "RESEARCHED":
			return true
	return false

static func colony_mode_data(mode: String) -> Dictionary:
	return InitialData.colonization_modes().get(mode, {})

static func system_yield_multiplier(system: Dictionary) -> float:
	var colony_stage: String = system.get("colonyStage", "NONE")
	match colony_stage:
		"OUTPOST":
			return 0.45
		"COLONY":
			return 1.0
		"CORE":
			return 1.1
		_:
			return 1.0

static func scale_resources(bundle: Dictionary, multiplier: float) -> Dictionary:
	return {
		"food": int(round(float(bundle.get("food", 0)) * multiplier)),
		"minerals": int(round(float(bundle.get("minerals", 0)) * multiplier)),
		"industry": int(round(float(bundle.get("industry", 0)) * multiplier)),
		"energy": int(round(float(bundle.get("energy", 0)) * multiplier))
	}

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

static func colonization_preview(state: Dictionary, fleet_id: String, system_id: String, mode: String) -> Dictionary:
	var player: Dictionary = player_faction(state)
	var fleet: Dictionary = {}
	var system: Dictionary = {}
	var mode_data: Dictionary = colony_mode_data(mode)
	if mode_data.is_empty():
		return {"allowed": false, "reason": "未知殖民模式。", "cost": COLONY_COST, "turns": 0}
	for entry: Dictionary in state.get("fleets", []):
		if entry.get("id", "") == fleet_id:
			fleet = entry
			break
	for entry: Dictionary in state.get("starSystems", []):
		if entry.get("id", "") == system_id:
			system = entry
			break
	if fleet.is_empty() or system.is_empty():
		return {"allowed": false, "reason": "缺少舰队或星系上下文。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if fleet.get("ownerId", "") != player.get("id", "") or fleet.get("systemId", "") != system_id:
		return {"allowed": false, "reason": "需要己方舰队驻留在目标星系。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if system.get("visibilityLevel", "") != "FULL":
		return {"allowed": false, "reason": "必须先完全探明星系。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if system.get("ownerId", null) != null or system.get("colonyStage", "NONE") != "NONE":
		return {"allowed": false, "reason": "目标星系已被占领或正在殖民中。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if not has_research(state, "tech_deep_colonization"):
		return {"allowed": false, "reason": "需要先完成基础深空殖民。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if not can_afford(player.get("resources", {}), mode_data.get("cost", COLONY_COST)):
		return {"allowed": false, "reason": "资源不足，无法发起殖民。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	return {"allowed": true, "reason": "可发起殖民。", "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}

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
	var next_state: Dictionary = duplicate_state(state)
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
	var next_state: Dictionary = duplicate_state(state)
	var memories: Array = next_state.get("diplomaticMemories", [])
	memories.push_front({
		"id": "dmem_%s_%s" % [str(next_state.get("turn", 1)), str(memories.size() + 1)],
		"turn": next_state.get("turn", 1),
		"title": title,
		"summary": summary,
		"participants": participants,
		"category": category,
		"importance": importance,
	})
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
		if participants.has("f_player") or memory.get("category", "") == "PUBLIC":
			result.append(memory)
			continue
		if int(memory.get("importance", 1)) >= 3:
			result.append(memory)
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
		"status": "高效监听网" if capability >= 0.65 else "边境监听链" if capability >= 0.35 else "基础监听"
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
				"胜利" if report.get("victory", false) else "失利",
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
			"title": str(event_item.get("title", "叙事事件")),
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
			"summary": "剩余 %s 回合 / 强度 %s" % [str(intervention.get("remainingTurns", 0)), str(intervention.get("intensity", 0.0))]
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
			"title": str(message.get("title", "通讯")),
			"summary": "%s / %s" % [str(message.get("visibilityLevel", "PUBLIC")), str(message.get("content", ""))]
		})
	for message: Dictionary in state.get("messages", []).slice(0, min(6, state.get("messages", []).size())):
		feed.append({
			"turn": int(message.get("turn", 0)),
			"priority": 1,
			"category": str(message.get("type", "EVENT")),
			"title": str(message.get("title", "情报")),
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
	if "互不侵犯" in message_text or "停火" in message_text or "ceasefire" in lowered or "non aggression" in lowered:
		return {"type": "TREATY", "treaty": "NON_AGGRESSION", "tone": "friendly", "trust_delta": 6}
	if "科研协定" in message_text or "联合研究" in message_text or "research" in lowered:
		return {"type": "TREATY", "treaty": "RESEARCH_ACCORD", "tone": "friendly", "trust_delta": 5}
	if "同盟" in message_text or "alliance" in lowered:
		return {"type": "TREATY", "treaty": "ALLIANCE", "tone": "friendly", "trust_delta": 7}
	if "贸易" in message_text or "合作" in message_text or "trade" in lowered or "peace" in lowered or "和平" in message_text:
		return {"type": "TRADE", "tone": "friendly", "trust_delta": 5}
	if "威胁" in message_text or "战争" in message_text or "宣战" in message_text or "attack" in lowered or "war" in lowered:
		return {"type": "WARNING", "tone": "firm", "trust_delta": -8}
	return {"type": "MESSAGE", "tone": "neutral", "trust_delta": 1}

static func describe_player_diplomatic_intent(message_text: String) -> Dictionary:
	var intent: Dictionary = parse_player_diplomatic_intent(message_text)
	var intent_type: String = str(intent.get("type", "MESSAGE"))
	var label: String = "一般交流"
	var detail: String = "会被视为普通沟通，主要影响轻微信任。"
	if intent_type == "TREATY":
		var treaty_id: String = str(intent.get("treaty", "NON_AGGRESSION"))
		var treaty_label: String = InitialData.treaty_labels().get(treaty_id, treaty_id)
		label = "条约提议"
		detail = "系统会把这段话视为 %s 提议，并触发正式条约评估。" % treaty_label
	elif intent_type == "TRADE":
		label = "贸易合作"
		detail = "系统会把这段话视为贸易或合作信号，提升关系倾向。"
	elif intent_type == "WARNING":
		label = "外交警告"
		detail = "系统会把这段话视为强硬警告，降低关系并提高紧张度。"
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
	next_state = update_diplomatic_profile(next_state, sender_id, "friendly", 6, "玩家接受了我方提案，可继续推动更深合作")
	next_state = add_diplomatic_memory(next_state, "提案已接受", "%s 已被玩家接受。" % target_proposal.get("title", "外交提案"), [sender_id, target_id], "AGREEMENT", 3)
	return add_message(next_state, "外交提案接受", "你接受了 %s。" % target_proposal.get("title", "一项提案"), "DIPLOMATIC")

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
	for index: int in range(next_state["relationships"].size()):
		var relation: Dictionary = next_state["relationships"][index]
		var touches: bool = (relation.get("factionAId", "") == sender_id and relation.get("factionBId", "") == target_id) or (relation.get("factionAId", "") == target_id and relation.get("factionBId", "") == sender_id)
		if not touches:
			continue
		var trust: int = clamp(int(relation.get("trust", 0)) - 8, -100, 100)
		relation["trust"] = trust
		relation["level"] = relation_level(trust)
		next_state["relationships"][index] = relation
	next_state = update_diplomatic_profile(next_state, sender_id, "firm", -5, "玩家拒绝了我方提案，需要重新评估让步空间")
	next_state = add_diplomatic_memory(next_state, "提案被拒绝", "%s 被玩家拒绝。" % target_proposal.get("title", "外交提案"), [sender_id, target_id], "PROPOSAL", 2)
	return add_message(next_state, "外交提案拒绝", "你拒绝了 %s。" % target_proposal.get("title", "一项提案"), "DIPLOMATIC")

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
		next_state = add_diplomatic_memory(next_state, "提案过期", "%s 已因超时失效。" % proposal.get("title", "外交提案"), [proposal.get("senderFactionId", ""), proposal.get("targetFactionId", "")], "PROPOSAL", 1)
	if changed:
		next_state["pendingProposals"] = proposals
	return next_state

static func available_buildings(state: Dictionary) -> Array:
	var result: Array = []
	for building: Dictionary in InitialData.building_catalog():
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
	return add_message(next_state, "开始研究", "已开始研究 %s。" % target.get("name", ""), "SYSTEM")

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
		return add_message(next_state, "研究取消", "%s 已取消，返还 %s 工业。" % [tech.get("name", ""), str(refund)], "SYSTEM")
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
		"id": "ship_%s" % str(Time.get_ticks_msec()),
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

static func find_fleet_index(state: Dictionary, fleet_id: String) -> int:
	for index: int in range(state.get("fleets", []).size()):
		if state["fleets"][index].get("id", "") == fleet_id:
			return index
	return -1

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
	if int(target_system.get("buildings", []).size()) >= int(target_system.get("buildingSlots", 0)):
		return next_state
	for building: Dictionary in target_system.get("buildings", []):
		if building.get("type", "") == building_type and building_type == "SHIPYARD":
			return next_state
	for item: Dictionary in next_state.get("constructionQueue", []):
		if item.get("systemId", "") == system_id and item.get("targetId", "") == building_type:
			return next_state
	if not can_afford(player.get("resources", {}), blueprint.get("cost", {})):
		return add_message(next_state, "建造失败", "资源不足，无法建造该建筑。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			faction["resources"] = subtract_resources(faction.get("resources", {}), blueprint.get("cost", {}))
			next_state["factions"][faction_index] = faction
	var queue_item: Dictionary = {
		"id": "queue_%s" % str(Time.get_ticks_msec()),
		"systemId": system_id,
		"ownerId": player.get("id", ""),
		"kind": "BUILDING",
		"targetId": building_type,
		"displayName": blueprint.get("name", ""),
		"turnsRemaining": InitialData.building_turns().get(building_type, 1),
		"totalTurns": InitialData.building_turns().get(building_type, 1)
	}
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append(queue_item)
	next_state["constructionQueue"] = queue
	return add_message(next_state, "加入建造队列", "%s 已开始建设 %s。" % [target_system.get("name", ""), blueprint.get("name", "")], "SYSTEM")

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
		return next_state
	if not available_ship_types(next_state).has(ship_type):
		return next_state
	var cost: Dictionary = ship_cost(ship_type, next_state, player.get("id", ""))
	if not can_afford(player.get("resources", {}), cost):
		return add_message(next_state, "造舰失败", "资源不足，无法建造该舰船。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			faction["resources"] = subtract_resources(faction.get("resources", {}), cost)
			next_state["factions"][faction_index] = faction
	var queue_item: Dictionary = {
		"id": "queue_%s" % str(Time.get_ticks_msec()),
		"systemId": system_id,
		"ownerId": player.get("id", ""),
		"kind": "SHIP",
		"targetId": ship_type,
		"displayName": InitialData.ship_labels().get(ship_type, ship_type),
		"turnsRemaining": InitialData.ship_turns().get(ship_type, 1),
		"totalTurns": InitialData.ship_turns().get(ship_type, 1)
	}
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append(queue_item)
	next_state["constructionQueue"] = queue
	return add_message(next_state, "加入造舰队列", "%s 已开始建造一艘%s。" % [target_system.get("name", ""), InitialData.ship_labels().get(ship_type, ship_type)], "SYSTEM")

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
		return add_message(next_state, "维修失败", "资源不足，无法完成舰队维修。", "SYSTEM")
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
	return add_message(next_state, "舰队维修", "%s 已在 %s 完成整备，战斗力恢复。" % [fleet.get("name", ""), system.get("name", "")], "SYSTEM")

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
			"summary": "????????????"
		})
		next_state["treaties"] = treaties
	next_state = update_diplomatic_profile(next_state, target_faction_id, "friendly", 6, "?????????????????")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "PROPOSAL", "??????", "??????????????????", true)
	next_state = add_diplomatic_memory(next_state, "????", "???????????????????", [player.get("id", ""), target_faction_id], "AGREEMENT", 2)
	return add_message(next_state, "????", "?? %s ???????????????" % target.get("name", ""), "DIPLOMATIC")

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
		treaty["summary"] = "%s ??????????" % treaty.get("summary", "")
		next_state["treaties"][index] = treaty
	next_state = update_diplomatic_profile(next_state, target_faction_id, "firm", -8, "???????????????")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "WARNING", "????", "?????????????????", true)
	next_state = add_diplomatic_memory(next_state, "????", "????????????????", [player.get("id", ""), target_faction_id], "WARNING", 2)
	return add_message(next_state, "????", "??? %s ????????????" % target_name, "DIPLOMATIC")

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
		treaty["summary"] = "?????????????"
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
	var treaty_label: String = InitialData.treaty_labels().get(treaty_type, treaty_type)
	next_state = update_diplomatic_profile(next_state, target_faction_id, "hostile", -6, "?????????????????")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "NOTIFICATION", "??????", "????????? %s?" % treaty_label, true)
	next_state = add_diplomatic_memory(next_state, "????", "????????????????", [player.get("id", ""), target_faction_id], "TREATY", 2)
	return add_message(next_state, "????", "?????????? %s?" % treaty_label, "DIPLOMATIC")

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
		treaty["summary"] = "?????????????"
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
			"summary": "????????????"
		})
		next_state["treaties"] = treaties
	next_state = update_diplomatic_profile(next_state, source_faction_id, "hostile", -10, "???????????????????")
	next_state = update_diplomatic_profile(next_state, target_faction_id, "hostile", -10, "???????????????????")
	next_state = add_diplomatic_message(next_state, source_faction_id, [target_faction_id], "BROADCAST", "PUBLIC", "WARNING", "?????", "%s ?? %s ???????" % [source_name, target_name], true)
	next_state = add_diplomatic_memory(next_state, "????", "%s ? %s ?????????" % [source_name, target_name], [source_faction_id, target_faction_id], "WAR", 4)
	return add_message(next_state, "????", "%s ?? %s ???????" % [source_name, target_name], "DIPLOMATIC")

static func treaty_acceptance(state: Dictionary, treaty_type: String, target_faction_id: String) -> Dictionary:
	var player: Dictionary = player_faction(state)
	var relation: Dictionary = relation_between(state, player.get("id", ""), target_faction_id)
	var trust: int = int(relation.get("trust", 0))
	var requires_tech: bool = treaty_type == "TRADE_PACT" or has_research(state, "tech_diplomatic_protocols")
	if not requires_tech:
		return {"accepted": false, "reason": "尚未掌握星际礼制协议，无法缔结更高级条约。"}
	if treaty_type == "TRADE_PACT" and trust >= -10:
		return {"accepted": true, "reason": "对方认为继续贸易仍有利可图。"}
	if treaty_type == "NON_AGGRESSION" and trust >= 10:
		return {"accepted": true, "reason": "边境互信尚可，双方愿意冻结武装摩擦。"}
	if treaty_type == "RESEARCH_ACCORD" and trust >= 30:
		return {"accepted": true, "reason": "对方接受共享研究成果与实验数据。"}
	if treaty_type == "ALLIANCE" and trust >= 65:
		return {"accepted": true, "reason": "双方互信已足够支撑正式同盟。"}
	return {"accepted": false, "reason": "当前互信不足，对方拒绝签署该条约。"}

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
	var treaty_label: String = InitialData.treaty_labels().get(treaty_type, treaty_type)
	next_state = update_diplomatic_profile(next_state, target_faction_id, "friendly" if accepted else "firm", 4 if accepted else -4, "????????????????")
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", "PUBLIC", "PROPOSAL", treaty_label, "????????? %s?" % treaty_label, true)
	next_state = add_diplomatic_memory(next_state, "????", "?????????? %s?" % treaty_label, [player.get("id", ""), target_faction_id], "PROPOSAL", 2)
	if accepted:
		return add_message(next_state, treaty_label, "%s ??? %s?%s" % [target_name, treaty_label, verdict.get("reason", "")], "DIPLOMATIC")
	return add_message(next_state, "????", "%s ????? %s ???%s" % [target_name, treaty_label, verdict.get("reason", "")], "DIPLOMATIC")

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
		return {"technologies": unlock_technologies(technologies), "currentResearchId": null if completed else tech.get("id", ""), "researchProgress": 0.0 if completed else progress, "completedName": tech.get("name", "") if completed else null}
	return {"technologies": unlock_technologies(technologies), "currentResearchId": null, "researchProgress": 0.0, "completedName": null}

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
	return bundle

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
		for blueprint: Dictionary in InitialData.building_catalog():
			if blueprint.get("type", "") != item.get("targetId", ""):
				continue
			for system_index: int in range(next_state["starSystems"].size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") == item.get("systemId", ""):
					var building: Dictionary = blueprint.duplicate(true)
					building["id"] = "building_%s" % str(Time.get_ticks_msec())
					var buildings: Array = system.get("buildings", [])
					buildings.append(building)
					system["buildings"] = buildings
					next_state["starSystems"][system_index] = system
					return add_message(next_state, "建造完成", "%s 已在 %s 完工。" % [item.get("displayName", ""), system.get("name", "")], "EVENT")
	else:
		var ship_type: String = item.get("targetId", "")
		var ship: Dictionary = create_ship(ship_type, "新编%s" % InitialData.ship_labels().get(ship_type, ship_type), next_state, item.get("ownerId", ""))
		for fleet_index: int in range(next_state["fleets"].size()):
			var fleet: Dictionary = next_state["fleets"][fleet_index]
			if fleet.get("ownerId", "") == item.get("ownerId", "") and fleet.get("systemId", "") == item.get("systemId", ""):
				var ships: Array = fleet.get("ships", [])
				ships.append(ship)
				fleet["ships"] = ships
				next_state["fleets"][fleet_index] = fleet
				return add_message(next_state, "舰船下水", "%s 已在船坞完成下水。" % item.get("displayName", ""), "EVENT")
		var fleets: Array = next_state.get("fleets", [])
		fleets.append({"id": "fleet_%s" % str(Time.get_ticks_msec()), "ownerId": item.get("ownerId", ""), "systemId": item.get("systemId", ""), "name": "%s 守备队" % item.get("systemId", ""), "ships": [ship]})
		next_state["fleets"] = fleets
		return add_message(next_state, "舰船下水", "%s 已在船坞完成下水。" % item.get("displayName", ""), "EVENT")
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

static func update_ascension_progress(state: Dictionary) -> Dictionary:
	var delta: int = 0
	if has_research(state, "tech_star_harmonics"):
		delta += 10
	if has_research(state, "tech_singularity_lattice"):
		delta += 18
	if has_treaty(state, "f_player", "f_merchant", "RESEARCH_ACCORD"):
		delta += 6
	for system: Dictionary in owned_systems(state, "f_player"):
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "RESEARCH_LAB":
				delta += 2
	var next_state: Dictionary = duplicate_state(state)
	next_state["ascension_progress"] = min(100, int(next_state.get("ascension_progress", 0)) + delta)
	return next_state

static func expire_treaties(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var treaties: Array = next_state.get("treaties", [])
	var changed: bool = false
	for index: int in range(treaties.size()):
		var treaty: Dictionary = treaties[index]
		if treaty.get("status", "") != "ACTIVE":
			continue
		var expires_on: int = int(treaty.get("expiresOnTurn", 0))
		if expires_on <= 0 or expires_on > int(next_state.get("turn", 1)):
			continue
		treaty["status"] = "EXPIRED"
		treaties[index] = treaty
		changed = true
		next_state = add_message(next_state, "条约到期", "%s 已正式到期。" % treaty.get("name", "一项条约"), "DIPLOMATIC")
	if changed:
		next_state["treaties"] = treaties
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
		for tech: Dictionary in next_state.get("technologies", []):
			if tech.get("status", "") == "RESEARCHED":
				technology_level += 1
		faction["controlledSystems"] = controlled_systems
		faction["population"] = population
		faction["militaryPower"] = int(round(military_power))
		faction["technologyLevel"] = technology_level
		next_state["factions"][faction_index] = faction
	return next_state

static func player_diplomatic_victory_report(state: Dictionary) -> Dictionary:
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
	var achieved: bool = total_rivals > 0 and war_count == 0 and alliance_count >= 1 and accord_count >= total_rivals and peace_count >= total_rivals
	return {
		"achieved": achieved,
		"total_rivals": total_rivals,
		"alliances": alliance_count,
		"accords": accord_count,
		"peace_partners": peace_count,
		"wars": war_count
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
		"summary": "高压:%s / 合作:%s / 恶化:%s / 机会回升:%s" % [
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
	var diplomacy_report: Dictionary = player_diplomatic_victory_report(next_state)
	var diplomacy_status: String = "???????" if diplomacy_report.get("achieved", false) else "?? %s / ?? %s / ?? %s" % [str(diplomacy_report.get("alliances", 0)), str(diplomacy_report.get("accords", 0)), str(diplomacy_report.get("peace_partners", 0))]
	next_state["objective"] = "?? %s/3 ?? ? ?? %s ? ?? %s/100" % [str(player_system_count), diplomacy_status, str(next_state.get("ascension_progress", 0))]
	if player_system_count == 0:
		next_state["status"] = "DEFEAT"
		return add_message(next_state, "????", "????????????????", "SYSTEM")
	if int(next_state.get("ascension_progress", 0)) >= 100 and has_research(next_state, "tech_singularity_lattice"):
		next_state["status"] = "VICTORY"
		next_state["victory_path"] = "ASCENSION"
		return add_message(next_state, "????", "????????????????????", "SYSTEM")
	if diplomacy_report.get("achieved", false):
		next_state["status"] = "VICTORY"
		next_state["victory_path"] = "DIPLOMATIC"
		return add_message(next_state, "????", "??????????????????????????????????", "SYSTEM")
	if player_system_count >= 3 or rival_system_count == 0:
		next_state["status"] = "VICTORY"
		next_state["victory_path"] = "MILITARY"
		return add_message(next_state, "????", "????????????????????", "SYSTEM")
	next_state["status"] = "PLAYING"
	next_state["victory_path"] = null
	return next_state

static func event_reward(event_type: Variant) -> Dictionary:
	match str(event_type):
		"ANCIENT_RUINS":
			return {"title": "古代遗迹", "content": "你的勘探队解译了古代信标数据，获得工业与科研物资。", "reward": {"food": 0, "minerals": 25, "industry": 40, "energy": 10}}
		"RICH_ASTEROIDS":
			return {"title": "富矿小行星群", "content": "舰队标记了高价值矿脉，后勤部门回收了大量矿产与能源。", "reward": {"food": 0, "minerals": 50, "industry": 0, "energy": 20}}
		"SOLAR_STORM":
			return {"title": "恒星风暴", "content": "你在风暴边缘建立了临时采能阵列，获得额外能源储备。", "reward": {"food": 0, "minerals": 0, "industry": 10, "energy": 45}}
		"PIRATE_RAID":
			return {"title": "海盗袭扰", "content": "护航舰队击退了袭扰者，但后勤线依然遭受损失。", "reward": {"food": -8, "minerals": -12, "industry": 0, "energy": -18}}
		"WARP_STORM":
			return {"title": "跃迁风暴", "content": "舰队在风暴边缘采集到不稳定跃迁数据，但航道稳定性下降。", "reward": {"food": 0, "minerals": 0, "industry": 8, "energy": -10}}
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
		system["note"] = "%s 勘探完成。" % system.get("note", "")
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
	var default_note: String = "边境传感器捕捉到新的异常信号。"
	var follow_up_options: Array = ["调查", "开发", "封锁"]
	match event_template_id:
		"ANCIENT_RUINS_DISCOVERY":
			event_type = "ANCIENT_RUINS"
			default_note = "发现远古遗迹信号，建议派遣舰队勘探。"
			follow_up_options = ["调查遗迹", "回收科技", "军事封锁"]
		"PIRATE_RAID":
			event_type = "PIRATE_RAID"
			default_note = "海盗活动正在升温，局部补给线承压。"
			follow_up_options = ["派舰清剿", "加强护航", "暂时规避"]
		"WARP_STORM":
			event_type = "WARP_STORM"
			default_note = "跃迁风暴扰动航道，短期内存在机动风险。"
			follow_up_options = ["科学观测", "关闭航道", "冒险穿越"]
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
	})
	next_state["activeNarrativeEvents"] = active_events
	var affected_names: Array = []
	for faction_id: String in affected_factions:
		affected_names.append(get_faction_by_id(next_state, faction_id).get("name", faction_id))
	var suffix: String = "" if affected_names.is_empty() else " 受影响势力: %s。" % ", ".join(affected_names)
	return add_message(next_state, "导演事件", "%s%s" % [default_note if narrative_override == "" else narrative_override, suffix], "EVENT")

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
					return trigger_narrative_event(next_state, "PIRATE_RAID", system.get("id", ""), ["f_player"], "海盗群开始袭扰边境航道。", {"threat_scale": intensity})
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
			return add_message(next_state, "导演干预", "多个 AI 势力在幕后获得了额外的战备支援，预计持续 %s 回合。" % str(duration), "EVENT")
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
			return add_message(next_state, "导演干预", "帝国后勤链遭遇了短时扰动，资源储备出现波动。", "EVENT")
		"TRIGGER_CRISIS":
			for system: Dictionary in next_state.get("starSystems", []):
				if system.get("ownerId", null) == "f_player":
					return trigger_narrative_event(next_state, "WARP_STORM", system.get("id", ""), ["f_player"], "区域级危机正在成形，跃迁风暴波及帝国疆域。", {"storm_scale": intensity})
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
		"调查遗迹", "科学观测":
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
			next_state = add_diplomatic_memory(next_state, "学术处置", "%s 的异常事件被用于科研观测，帝国整体更偏向理性处理危机。" % system_name, ["f_player"], "EVENT", 2)
		"回收科技", "加强护航", "关闭航道":
			for system_index: int in range(next_state.get("starSystems", []).size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") != system_id:
					continue
				system["stability"] = min(100, int(system.get("stability", 60)) + 8)
				system["supplyLevel"] = min(100, int(system.get("supplyLevel", 60)) + 10)
				system["eventResolved"] = true
				next_state["starSystems"][system_index] = system
				break
			if option_label == "加强护航":
				for index: int in range(next_state.get("relationships", []).size()):
					var relation: Dictionary = next_state["relationships"][index]
					var touches_merchant: bool = (relation.get("factionAId", "") == "f_player" and relation.get("factionBId", "") == "f_merchant") or (relation.get("factionAId", "") == "f_merchant" and relation.get("factionBId", "") == "f_player")
					if not touches_merchant:
						continue
					relation["trust"] = clamp(int(relation.get("trust", 0)) + 4, -100, 100)
					relation["utility"] = int(relation.get("utility", 0)) + 4
					relation["level"] = relation_level(int(relation.get("trust", 0)))
					next_state["relationships"][index] = relation
				next_state = update_diplomatic_profile(next_state, "f_merchant", "friendly", 3, "玩家愿意投入力量保护边境商路，值得继续合作。")
				next_state = add_diplomatic_memory(next_state, "联合护航", "玩家在 %s 周边加强护航，商贾联盟对合作意愿上升。" % system_name, ["f_player", "f_merchant"], "AGREEMENT", 2)
		"军事封锁", "派舰清剿", "冒险穿越":
			for system_index: int in range(next_state.get("starSystems", []).size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") != system_id:
					continue
				system["stability"] = max(25, int(system.get("stability", 60)) - 4)
				system["eventResolved"] = true
				next_state["starSystems"][system_index] = system
				break
			if option_label == "派舰清剿":
				for fleet_index: int in range(next_state.get("fleets", []).size()):
					var fleet: Dictionary = next_state["fleets"][fleet_index]
					if fleet.get("ownerId", "") != "f_player":
						continue
					if fleet.get("systemId", "") != system_id:
						continue
					next_state["fleets"][fleet_index] = damage_fleet(fleet, 10)
					break
				next_state = update_diplomatic_profile(next_state, "f_merchant", "firm", 1, "玩家主动清理海盗，说明其仍在维护边境秩序。")
				next_state = add_diplomatic_memory(next_state, "清剿海盗", "玩家在 %s 发起清剿行动，虽有战损但稳定了局势。" % system_name, ["f_player", "f_merchant"], "EVENT", 3)
			elif option_label == "冒险穿越":
				for index: int in range(next_state.get("factions", []).size()):
					var faction: Dictionary = next_state["factions"][index]
					if not faction.get("isPlayer", false):
						continue
					var resources: Dictionary = faction.get("resources", {}).duplicate(true)
					resources["energy"] = max(0, int(resources.get("energy", 0)) - 16)
					resources["industry"] = int(resources.get("industry", 0)) + 16
					faction["resources"] = resources
					next_state["factions"][index] = faction
				next_state = add_diplomatic_memory(next_state, "冒险穿越", "玩家强行穿越 %s 的异常航道，帝国风格变得更加冒险。" % system_name, ["f_player"], "EVENT", 2)
		"开发", "暂时规避", "封锁":
			next_state = resolve_player_system_event(next_state, system_id)
			if option_label == "暂时规避":
				for system_index: int in range(next_state.get("starSystems", []).size()):
					var system: Dictionary = next_state["starSystems"][system_index]
					if system.get("id", "") != system_id:
						continue
					system["supplyLevel"] = max(35, int(system.get("supplyLevel", 60)) - 6)
					system["eventResolved"] = true
					next_state["starSystems"][system_index] = system
					break
				next_state = update_diplomatic_profile(next_state, "f_orchid", "neutral", -1, "玩家在危机中选择规避，说明其当前更注重保存实力。")
				next_state = add_diplomatic_memory(next_state, "暂避锋芒", "玩家选择绕开 %s 的风险地带，外交姿态更趋谨慎。" % system_name, ["f_player", "f_orchid"], "EVENT", 1)
	next_state = add_message(next_state, "事件抉择", "%s 的事件已按“%s”处理。" % [system_name, option_label], "EVENT")
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

static func initiate_combat_protocol(state: Dictionary, attacker_fleet_id: String, target_type: String, target_id: String, engagement_rules: String = "ALL_OUT", formation: String = "LINE") -> Dictionary:
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
			return add_message(next_state, "战斗协议失败", "未找到目标舰队。", "SYSTEM")
		defender = next_state["fleets"][defender_index]
	else:
		return add_message(next_state, "战斗协议失败", "当前版本仅支持舰队目标。", "SYSTEM")
	if defender.get("ownerId", "") == attacker_owner:
		return add_message(next_state, "战斗协议失败", "无法对己方舰队发起战斗。", "SYSTEM")
	if not has_treaty(next_state, attacker_owner, defender.get("ownerId", ""), "WAR_STATE"):
		next_state = declare_war_on_faction(next_state, attacker_owner, defender.get("ownerId", ""))
		attacker_index = find_fleet_index(next_state, attacker_fleet_id)
		defender_index = find_fleet_index(next_state, target_id)
		attacker = next_state["fleets"][attacker_index]
		defender = next_state["fleets"][defender_index]
	var modifier: float = 1.0
	var notes: Array = ["交战规则: %s" % engagement_rules, "阵型: %s" % formation]
	var attacker_damage_taken: int = 22
	var defender_damage_taken: int = 14
	if engagement_rules == "HIT_AND_RUN":
		modifier *= 0.88
		notes.append("高速突击降低正面歼灭效率，但保留更多撤退空间。")
		attacker_damage_taken = 12
		defender_damage_taken = 10
	elif engagement_rules == "ALL_OUT":
		modifier *= 1.08
		notes.append("全力交战会放大战果，但同步提高战损。")
		attacker_damage_taken = 28
		defender_damage_taken = 18
	elif engagement_rules == "DEFENSIVE":
		modifier *= 0.96
		notes.append("防御交战优先保存舰体，推进速度较慢。")
		attacker_damage_taken = 10
		defender_damage_taken = 8
	if formation == "WEDGE":
		modifier *= 1.12
		notes.append("楔形阵更适合快速击穿前线。")
		defender_damage_taken += 6
	elif formation == "SPHERE":
		modifier *= 0.95
		notes.append("球形阵更稳健，但压制速度较慢。")
		attacker_damage_taken = max(6, attacker_damage_taken - 8)
	elif formation == "LINE":
		modifier *= 1.02
		notes.append("横列阵有利于稳定火力覆盖。")
	var attacker_power: float = fleet_power(attacker) * modifier
	var defender_power: float = fleet_power(defender)
	var attacker_wins: bool = attacker_power >= defender_power
	var casualties: int = max(1, int(attacker.get("ships", []).size() * (0.2 if attacker_wins else 0.5 if engagement_rules == "ALL_OUT" else 0.25)))
	var kills: int = defender.get("ships", []).size() if attacker_wins and engagement_rules != "HIT_AND_RUN" else max(1, int(defender.get("ships", []).size() * 0.5)) if attacker_wins else max(0, int(defender.get("ships", []).size() * 0.25))
	var remaining_power: int = max(8, int((attacker_power - defender_power) / max(1.0, attacker_power) * 100.0)) if attacker_wins else max(0, int((fleet_power(attacker) - defender_power) / max(1.0, fleet_power(attacker)) * 100.0))
	if attacker_wins:
		next_state["fleets"][attacker_index] = damage_fleet(attacker, attacker_damage_taken)
		if defender_index > attacker_index:
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
			next_state["starSystems"][system_index] = system
			break
		if engagement_rules == "HIT_AND_RUN":
			next_state = add_message(next_state, "战斗协议执行", "%s 成功完成突袭并重创目标，但未能完全接管战区。" % attacker.get("name", ""), "COMBAT")
		else:
			next_state = add_message(next_state, "战斗协议执行", "%s 击溃了目标舰队并夺取战区控制权。" % attacker.get("name", ""), "COMBAT")
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
		next_state = update_diplomatic_profile(next_state, defender.get("ownerId", ""), "hostile", -6, "玩家在近期交战中取得主动，必须重新评估其军事威慑。")
		next_state = add_diplomatic_memory(next_state, "边境战斗失利", "%s 在与 %s 的交战中遭遇失利。" % [defender.get("name", "敌军"), attacker.get("name", "玩家舰队")], [attacker_owner, defender.get("ownerId", "")], "WAR", 3)
	else:
		next_state["fleets"][defender_index] = damage_fleet(defender, defender_damage_taken)
		if engagement_rules == "DEFENSIVE" or engagement_rules == "HIT_AND_RUN":
			next_state["fleets"][attacker_index] = damage_fleet(attacker, attacker_damage_taken)
			next_state = add_message(next_state, "战斗协议执行", "%s 在不利态势下完成脱离，未能夺取目标。" % attacker.get("name", ""), "COMBAT")
			next_state = update_diplomatic_profile(next_state, defender.get("ownerId", ""), "firm", 2, "玩家在最近交战中未能突破防线，可继续保持高压姿态。")
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
			next_state["fleets"].remove_at(attacker_index)
			next_state = add_message(next_state, "战斗协议执行", "%s 在交战中失利，舰队被迫退出战场。" % attacker.get("name", ""), "COMBAT")
			next_state = add_diplomatic_memory(next_state, "进攻受挫", "%s 在对 %s 的作战中失利。" % [attacker.get("name", "玩家舰队"), defender.get("name", "敌军")], [attacker_owner, defender.get("ownerId", "")], "WAR", 3)
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
	next_state = add_message(next_state, "战术注记", " / ".join(notes), "COMBAT")
	next_state = add_combat_report(next_state, "战斗协议战报", attacker.get("name", "进攻舰队"), defender.get("name", "防御舰队"), attacker_wins, casualties, kills, remaining_power, notes)
	return assess_game_status(ensure_faction_controls(next_state))

static func colonize_for_faction(state: Dictionary, faction_id: String, system_id: String, population: int, title: String, content: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var habitat: Dictionary = {}
	for entry: Dictionary in InitialData.building_catalog():
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
			system["buildings"] = [InitialData._make_building("colony_%s" % system_id, habitat)]
			system["colonyStage"] = "COLONY"
			system["colonizationProgress"] = 100.0
			system["colonizationTurnsRemaining"] = 0
			system["buildingSlots"] = int(system.get("baseBuildingSlots", system.get("buildingSlots", 3)))
			system["stability"] = max(62, int(system.get("stability", 50)))
			system["supplyLevel"] = max(75, int(system.get("supplyLevel", 60)))
			next_state["starSystems"][system_index] = system
	return add_message(next_state, title, content, "EVENT")

static func start_colony_for_faction(state: Dictionary, faction_id: String, system_id: String, mode: String, title: String, content: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var mode_data: Dictionary = colony_mode_data(mode)
	if mode_data.is_empty():
		return next_state
	var habitat: Dictionary = {}
	for entry: Dictionary in InitialData.building_catalog():
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
		system["buildings"] = [InitialData._make_building("colony_%s" % system_id, habitat)] if not habitat.is_empty() else []
		system["colonyStage"] = "OUTPOST"
		system["colonizationProgress"] = 0.0
		system["colonizationTurnsRemaining"] = int(mode_data.get("turns", 3))
		system["colonizationMode"] = mode
		system["colonizationRisk"] = mode_data.get("risk", "中")
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
			next_state = add_message(next_state, "殖民地成熟", "%s 已完成前哨建设，成为正式殖民地。" % system.get("name", ""), "EVENT")
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
	if not connected_to(next_state, fleet.get("systemId", "")).has(target_system_id):
		return next_state
	var cost: int = 1
	for lane: Dictionary in next_state.get("hyperlanes", []):
		var direct: bool = lane.get("startSystemId", "") == fleet.get("systemId", "") and lane.get("endSystemId", "") == target_system_id
		var reverse: bool = lane.get("endSystemId", "") == fleet.get("systemId", "") and lane.get("startSystemId", "") == target_system_id
		if direct or reverse:
			cost = int(lane.get("traversalCost", 1))
	if int(player.get("resources", {}).get("energy", 0)) < cost:
		return add_message(next_state, "移动失败", "能源不足，舰队无法跃迁。", "SYSTEM")
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == player.get("id", ""):
			var resources: Dictionary = faction.get("resources", {}).duplicate(true)
			resources["energy"] = int(resources.get("energy", 0)) - cost
			faction["resources"] = resources
			next_state["factions"][faction_index] = faction
	fleet["systemId"] = target_system_id
	next_state["fleets"][fleet_index] = fleet
	for system_index: int in range(next_state["starSystems"].size()):
		var system: Dictionary = next_state["starSystems"][system_index]
		if system.get("id", "") == target_system_id:
			system["visibilityLevel"] = "FULL"
			next_state["starSystems"][system_index] = system
	next_state = add_message(next_state, "舰队移动", "%s 已跃迁至目标星系。" % fleet.get("name", ""), "EVENT")
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
			next_state = add_message(next_state, "战斗报告", "%s 在目标星系击败敌军并夺取控制权，舰队出现一定战损。" % moved_fleet.get("name", ""), "COMBAT")
		else:
			next_state["fleets"].remove_at(fleet_index)
			next_state = add_message(next_state, "战斗报告", "%s 在目标星系作战失利。" % moved_fleet.get("name", ""), "COMBAT")
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
	if fleet.get("systemId", "") != system_id and not connected_to(next_state, fleet.get("systemId", "")).has(system_id):
		return next_state
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
	next_state = add_message(next_state, "探索完成", "%s 已完成对目标星系的勘测。" % fleet.get("name", ""), "EVENT")
	next_state = resolve_player_system_event(next_state, system_id)
	return assess_game_status(next_state)

static func colonize_system(state: Dictionary, fleet_id: String, system_id: String, mode: String = "STANDARD") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var preview: Dictionary = colonization_preview(next_state, fleet_id, system_id, mode)
	if not preview.get("allowed", false):
		return add_message(next_state, "殖民失败", str(preview.get("reason", "当前无法殖民。")), "SYSTEM")
	var system_name: String = system_id
	for entry: Dictionary in next_state.get("starSystems", []):
		if entry.get("id", "") == system_id:
			system_name = entry.get("name", system_id)
			break
	var mode_name: String = colony_mode_data(mode).get("name", mode)
	next_state = start_colony_for_faction(next_state, player.get("id", ""), system_id, mode, "殖民计划启动", "已对 %s 发起%s，前哨建设开始。" % [system_name, mode_name])
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
	var title: String = "????"
	var content_type: String = "PROPOSAL"
	match str(intent.get("type", "MESSAGE")):
		"TREATY":
			title = "??????"
			content_type = "PROPOSAL"
		"WARNING":
			title = "????"
			content_type = "WARNING"
		"TRADE":
			title = "??????"
			content_type = "PROPOSAL"
	next_state = add_diplomatic_message(next_state, player.get("id", ""), [target_faction_id], "SINGLE", visibility_level, content_type, title, message_text.strip_edges(), true)
	next_state = add_diplomatic_memory(next_state, title, "??? %s ??????????" % target.get("name", target_faction_id), [player.get("id", ""), target_faction_id], "PROPOSAL", 1)
	next_state = update_diplomatic_profile(next_state, target_faction_id, tone, trust_delta, "????????????????")
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

static func simulate_ai_backchannel(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var merchant: Dictionary = get_faction_by_id(next_state, "f_merchant")
	var orchid: Dictionary = get_faction_by_id(next_state, "f_orchid")
	if merchant.is_empty() or orchid.is_empty():
		return next_state
	var player: Dictionary = player_faction(next_state)
	var player_power: int = int(player.get("militaryPower", 0))
	if int(next_state.get("turn", 1)) % 3 == 0 and player_power >= 90:
		var intercepted_secret: bool = should_intercept_message(next_state, "f_merchant", ["f_orchid"], "SECRET")
		next_state = add_diplomatic_message(next_state, "f_merchant", ["f_orchid"], "SINGLE", "SECRET", "PROPOSAL", "????", "???????????????????????????", intercepted_secret)
		if intercepted_secret:
			next_state = add_diplomatic_memory(next_state, "??????", "???????????????????", ["f_merchant", "f_orchid"], "INTEL", 3)
		next_state = update_diplomatic_profile(next_state, "f_merchant", "firm", 0, "????????????????")
		next_state = update_diplomatic_profile(next_state, "f_orchid", "neutral", 1, "??????????????????")
		for index: int in range(next_state["relationships"].size()):
			var relation: Dictionary = next_state["relationships"][index]
			var touches: bool = (relation.get("factionAId", "") == "f_merchant" and relation.get("factionBId", "") == "f_orchid") or (relation.get("factionAId", "") == "f_orchid" and relation.get("factionBId", "") == "f_merchant")
			if not touches:
				continue
			var trust: int = clamp(int(relation.get("trust", 0)) + 3, -100, 100)
			relation["trust"] = trust
			relation["level"] = relation_level(trust)
			next_state["relationships"][index] = relation
	if int(next_state.get("turn", 1)) % 4 == 0:
		var intercepted_group: bool = should_intercept_message(next_state, "f_orchid", ["f_player", "f_merchant"], "ENCRYPTED")
		next_state = add_diplomatic_message(next_state, "f_orchid", ["f_player", "f_merchant"], "GROUP", "ENCRYPTED", "NOTIFICATION", "??????", "????????????????????????????????", intercepted_group)
		if intercepted_group:
			next_state = add_diplomatic_memory(next_state, "??????", "??????????????????", ["f_orchid", "f_player", "f_merchant"], "INTEL", 3)
		next_state = update_diplomatic_profile(next_state, "f_orchid", "neutral", 0, "???????????????")
	if int(next_state.get("turn", 1)) % 5 == 0:
		next_state = add_diplomatic_message(next_state, "f_orchid", ["f_player", "f_merchant"], "BROADCAST", "PUBLIC", "NOTIFICATION", "??????", "????????????????????????????", true)
		next_state = add_diplomatic_memory(next_state, "??????", "??????????????????", ["f_orchid", "f_player", "f_merchant"], "PUBLIC", 2)
		next_state = update_diplomatic_profile(next_state, "f_orchid", "friendly", 1, "???????????????")
	return next_state

static func simulate_ai_proposals(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var orchid_relation: Dictionary = relation_breakdown(next_state, "f_player", "f_orchid")
	var merchant_relation: Dictionary = relation_breakdown(next_state, "f_player", "f_merchant")
	var turn: int = int(next_state.get("turn", 1))
	var orchid_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_orchid", 3)
	var merchant_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_merchant", 3)
	if turn % 6 == 0 and int(orchid_relation.get("trust", 0)) + int(orchid_relation.get("utility", 0)) / 3 >= 15 and not has_treaty(next_state, "f_orchid", "f_player", "NON_AGGRESSION"):
		next_state = create_pending_proposal(next_state, "f_orchid", "f_player", "NON_AGGRESSION", "????????", "????????????????????????????")
		next_state = update_diplomatic_profile(next_state, "f_orchid", "friendly", 2, "?????????????????")
	elif turn % 8 == 0 and (int(orchid_relation.get("trust", 0)) >= 30 or bool(orchid_trend.get("trust_rising", false))) and int(orchid_relation.get("utility", 0)) >= 18 and has_research(next_state, "tech_diplomatic_protocols") and not has_treaty(next_state, "f_orchid", "f_player", "RESEARCH_ACCORD"):
		next_state = create_pending_proposal(next_state, "f_orchid", "f_player", "RESEARCH_ACCORD", "??????", "??????????????????????????????")
		next_state = update_diplomatic_profile(next_state, "f_orchid", "friendly", 3, "??????????????")
	if turn % 7 == 0 and (int(merchant_relation.get("trust", 0)) >= 25 or bool(merchant_trend.get("trust_rising", false))) and int(merchant_relation.get("utility", 0)) >= 18 and not has_treaty(next_state, "f_merchant", "f_player", "TRADE_PACT"):
		next_state = create_pending_proposal(next_state, "f_merchant", "f_player", "TRADE_PACT", "??????", "??????????????????????????")
		next_state = update_diplomatic_profile(next_state, "f_merchant", "friendly", 2, "????????????????????")
	elif turn % 5 == 0 and (int(merchant_relation.get("trust", 0)) <= -35 or int(merchant_relation.get("memoryImpact", 0)) >= 12 or bool(merchant_trend.get("pressure_rising", false))):
		next_state = add_diplomatic_message(next_state, "f_merchant", ["f_player"], "SINGLE", "PUBLIC", "WARNING", "????", "????????????????????????????????", true)
		next_state = add_diplomatic_memory(next_state, "????", "???????????????????", ["f_player", "f_merchant"], "WARNING", 2)
		next_state = update_diplomatic_profile(next_state, "f_merchant", "hostile", -3, "??????????????")
	elif turn % 6 == 0 and (int(orchid_relation.get("fear", 0)) >= 55 or bool(orchid_trend.get("pressure_rising", false))) and int(orchid_relation.get("trust", 0)) < 10:
		next_state = add_diplomatic_message(next_state, "f_orchid", ["f_player"], "SINGLE", "PUBLIC", "WARNING", "????", "????????????????????????????", true)
		next_state = add_diplomatic_memory(next_state, "边境忧虑", "兰心公约因玩家军势增长而发出正式警告。", ["f_player", "f_orchid"], "WARNING", 2)
		next_state = update_diplomatic_profile(next_state, "f_orchid", "firm", -2, "玩家近期军事威慑正在上升，需要通过正式渠道表达关切。")
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
	var merchant_home: Dictionary = {}
	for system: Dictionary in next_state.get("starSystems", []):
		if system.get("ownerId", null) == "f_merchant":
			merchant_home = system
			break
	var merchant_resources: Dictionary = merchant.get("resources", {})
	if not merchant_home.is_empty():
		var has_shipyard: bool = false
		for building: Dictionary in merchant_home.get("buildings", []):
			if building.get("type", "") == "SHIPYARD":
				has_shipyard = true
		if int(next_state.get("turn", 1)) >= 3 and not has_shipyard:
			for blueprint: Dictionary in InitialData.building_catalog():
				if blueprint.get("type", "") == "SHIPYARD" and can_afford(merchant_resources, blueprint.get("cost", {})):
					next_state = queue_structure_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), blueprint, "商贾联盟工程", "商贾联盟开始扩建本土船坞。")
					break
		if has_shipyard:
			var ship_type: String = "CRUISER" if int(next_state.get("turn", 1)) >= 14 else "DESTROYER" if int(next_state.get("turn", 1)) >= 10 else "CORVETTE"
			var cost: Dictionary = ship_cost(ship_type, next_state, "f_merchant")
			if can_afford(merchant_resources, cost):
				next_state = queue_ship_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), ship_type, "商贾联盟造舰", "商贾联盟已将一艘")
	if not decision.is_empty():
		var action: String = decision.get("action", "WAIT")
		if action == "TRADE" and int(relation_view.get("trust", 0)) + int(relation_view.get("utility", 0)) / 2 >= 0:
			next_state = add_message(next_state, "商路修复", "商贾联盟主动提出恢复边境货运。", "DIPLOMATIC")
		elif action == "DECLARE_WAR" and int(relation_view.get("fear", 0)) <= 60 and not merchant_posture.get("high_pressure", []).has("兰心公约"):
			next_state = declare_war_on_faction(next_state, "f_merchant", "f_player")
		elif action == "EXPLORE" and not merchant_fleet.is_empty():
			for fleet_index: int in range(next_state["fleets"].size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("id", "") == merchant_fleet.get("id", ""):
					fleet["systemId"] = decision.get("target", fleet.get("systemId", ""))
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "商贾联盟调动", "边贸护航队向 %s 跃迁。" % decision.get("target", ""), "EVENT")
		elif action == "BUILD":
			next_state = add_message(next_state, "商贾联盟造舰", "商贾联盟已调整本回合建造计划。", "EVENT")
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
		var should_expand: bool = int(relation_view.get("fear", 0)) >= 50 or int(relation_view.get("utility", 0)) >= 20 or int(relation_view.get("memoryImpact", 0)) >= 6 or bool(merchant_trend.get("pressure_rising", false))
		if not neutral_target.is_empty() and should_expand:
			for fleet_index: int in range(next_state["fleets"].size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("id", "") == merchant_fleet.get("id", ""):
					fleet["systemId"] = neutral_target.get("id", "")
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "商贾联盟调动", "边贸护航队向 %s 跃迁。" % neutral_target.get("name", ""), "EVENT")
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
			next_state = start_colony_for_faction(next_state, "f_merchant", occupied_system.get("id", ""), "RESOURCE_OUTPOST", "商贾联盟殖民", "商贾联盟已在 %s 建立前进商站。" % occupied_system.get("name", "未知星系"))
	if bool(merchant_trend.get("opportunity_rising", false)) and not has_treaty(next_state, "f_merchant", "f_player", "TRADE_PACT") and int(next_state.get("turn", 1)) % 4 == 0:
		next_state = add_diplomatic_message(next_state, "f_merchant", ["f_player"], "SINGLE", "PUBLIC", "PROPOSAL", "商路试探", "商贾联盟认为边境局势出现合作窗口，愿意重新评估与你的贸易安排。", true)
	if bool(merchant_trend.get("pressure_rising", false)) and int(next_state.get("turn", 1)) % 4 == 0:
		next_state = update_diplomatic_profile(next_state, "f_merchant", "guarded", -1, "玩家近期的军政动向正在抬高联盟的风险评估。")
	return ensure_faction_controls(next_state)

static func queue_structure_for_ai(state: Dictionary, owner_id: String, system_id: String, blueprint: Dictionary, message_title: String = "AI工程", message_content: String = "AI 势力开始扩建本土设施。") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == owner_id:
			faction["resources"] = subtract_resources(faction.get("resources", {}), blueprint.get("cost", {}))
			next_state["factions"][faction_index] = faction
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append({
		"id": "queue_%s" % str(Time.get_ticks_msec()),
		"systemId": system_id,
		"ownerId": owner_id,
		"kind": "BUILDING",
		"targetId": blueprint.get("type", ""),
		"displayName": blueprint.get("name", ""),
		"turnsRemaining": InitialData.building_turns().get(blueprint.get("type", ""), 1),
		"totalTurns": InitialData.building_turns().get(blueprint.get("type", ""), 1)
	})
	next_state["constructionQueue"] = queue
	return add_message(next_state, message_title, message_content, "EVENT")

static func queue_ship_for_ai(state: Dictionary, owner_id: String, system_id: String, ship_type: String, message_title: String = "AI造舰", message_prefix: String = "AI 势力已将一艘") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var cost: Dictionary = ship_cost(ship_type, next_state, owner_id)
	for faction_index: int in range(next_state["factions"].size()):
		var faction: Dictionary = next_state["factions"][faction_index]
		if faction.get("id", "") == owner_id:
			faction["resources"] = subtract_resources(faction.get("resources", {}), cost)
			next_state["factions"][faction_index] = faction
	var queue: Array = next_state.get("constructionQueue", [])
	queue.append({
		"id": "queue_%s" % str(Time.get_ticks_msec()),
		"systemId": system_id,
		"ownerId": owner_id,
		"kind": "SHIP",
		"targetId": ship_type,
		"displayName": InitialData.ship_labels().get(ship_type, ship_type),
		"turnsRemaining": InitialData.ship_turns().get(ship_type, 1),
		"totalTurns": InitialData.ship_turns().get(ship_type, 1)
	})
	next_state["constructionQueue"] = queue
	return add_message(next_state, message_title, "%s%s编入建造队列。" % [message_prefix, InitialData.ship_labels().get(ship_type, ship_type)], "EVENT")

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
	if not orchid_home.is_empty():
		var has_lab: bool = false
		var has_shipyard: bool = false
		for building: Dictionary in orchid_home.get("buildings", []):
			if building.get("type", "") == "RESEARCH_LAB":
				has_lab = true
			elif building.get("type", "") == "SHIPYARD":
				has_shipyard = true
		if int(next_state.get("turn", 1)) >= 3 and not has_lab:
			for blueprint: Dictionary in InitialData.building_catalog():
				if blueprint.get("type", "") == "RESEARCH_LAB" and can_afford(orchid_resources, blueprint.get("cost", {})):
					next_state = queue_structure_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), blueprint, "兰心公约科研", "兰心公约开始扩建轨道科研设施。")
					has_lab = true
					break
		if int(next_state.get("turn", 1)) >= 6 and not has_shipyard:
			for shipyard_blueprint: Dictionary in InitialData.building_catalog():
				if shipyard_blueprint.get("type", "") == "SHIPYARD" and can_afford(orchid_resources, shipyard_blueprint.get("cost", {})):
					next_state = queue_structure_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), shipyard_blueprint, "兰心公约防务", "兰心公约开始建设防御性船坞。")
					has_shipyard = true
					break
		if has_shipyard:
			var orchid_ship_type: String = "DESTROYER" if int(next_state.get("turn", 1)) >= 12 else "CORVETTE"
			var orchid_ship_cost: Dictionary = ship_cost(orchid_ship_type, next_state, "f_orchid")
			if can_afford(orchid_resources, orchid_ship_cost):
				next_state = queue_ship_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), orchid_ship_type, "兰心公约整编", "兰心公约已将一艘")
	if not orchid_fleet.is_empty():
		var player_relation: Dictionary = relation_breakdown(next_state, "f_player", "f_orchid")
		var merchant_relation: Dictionary = relation_breakdown(next_state, "f_merchant", "f_orchid")
		var orchid_trend: Dictionary = relationship_trend_report(next_state, "f_player", "f_orchid", 4)
		var seek_neutral: bool = (int(player_relation.get("fear", 0)) >= 50 or int(player_relation.get("trust", 0)) >= 0) and int(merchant_relation.get("trust", 0)) >= -10
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
					fleet["systemId"] = preferred_target.get("id", "")
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "兰心公约调动", "兰心巡防舰队向 %s 调动。" % preferred_target.get("name", "未知星系"), "EVENT")
		var occupied_system: Dictionary = {}
		for system_entry: Dictionary in next_state.get("starSystems", []):
			if system_entry.get("id", "") == orchid_fleet.get("systemId", ""):
				occupied_system = system_entry
				break
		if not occupied_system.is_empty() and occupied_system.get("ownerId", null) == null and int(next_state.get("turn", 1)) >= 5:
			var mode: String = "STANDARD" if int(occupied_system.get("habitability", 0)) >= 70 else "RESOURCE_OUTPOST"
			var mode_cost: Dictionary = colony_mode_data(mode).get("cost", COLONY_COST)
			if can_afford(orchid.get("resources", {}), mode_cost):
				next_state = start_colony_for_faction(next_state, "f_orchid", occupied_system.get("id", ""), mode, "兰心公约殖民", "兰心公约已在 %s 建立新的边境据点。" % occupied_system.get("name", "未知星系"))
		if bool(orchid_trend.get("opportunity_rising", false)) and int(next_state.get("turn", 1)) % 5 == 0:
			next_state = update_diplomatic_profile(next_state, "f_orchid", "warm", 1, "???????????????????????????")
	return next_state

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
	next_state = apply_faction_economy(next_state)
	next_state = progress_colonies(next_state)
	next_state = expire_treaties(next_state)
	next_state = expire_pending_proposals(next_state)
	next_state = apply_passive_repairs(next_state)
	next_state = advance_construction_queue(next_state)
	next_state = advance_active_interventions(next_state)
	next_state = update_ascension_progress(next_state)
	if research_data.get("completedName", null) != null:
		next_state = add_message(next_state, "科技完成", "%s 研究完成。" % research_data.get("completedName", ""), "SYSTEM")
	next_state = merchant_ai_turn(next_state, merchant_decision)
	next_state = orchid_ai_turn(next_state)
	next_state = simulate_ai_backchannel(next_state)
	next_state = simulate_ai_proposals(next_state)
	next_state = append_relationship_snapshots(next_state)
	return assess_game_status(ensure_faction_controls(next_state))
