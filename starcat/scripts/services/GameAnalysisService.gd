extends RefCounted

class_name GameAnalysisService

const GameLogicScript = preload("res://scripts/GameLogic.gd")
const InitialDataScript = preload("res://scripts/data/InitialData.gd")

func check_health() -> bool:
	return true

func query_world(game_state: Dictionary, focus_system_id: Variant) -> Dictionary:
	var visible_systems: Array = []
	for system: Dictionary in game_state.get("starSystems", []):
		if system.get("visibilityLevel", "HIDDEN") == "HIDDEN":
			continue
		visible_systems.append({
			"id": str(system.get("id", "")),
			"name": str(system.get("name", "")),
			"ownerId": system.get("ownerId", null),
			"value": _system_value(system),
		})
	var treaties: Array = []
	for treaty: Dictionary in game_state.get("treaties", []):
		if treaty.get("status", "") != "ACTIVE":
			continue
		treaties.append({
			"id": str(treaty.get("id", "")),
			"type": str(treaty.get("type", "")),
			"status": str(treaty.get("status", "")),
			"counterpart": _faction_name(game_state, str(treaty.get("targetFactionId", treaty.get("sourceFactionId", "")))),
		})
	var queue: Array = []
	for item: Dictionary in game_state.get("constructionQueue", []):
		queue.append({
			"id": str(item.get("id", "")),
			"systemId": str(item.get("systemId", "")),
			"displayName": str(item.get("displayName", item.get("targetId", ""))),
			"turnsRemaining": int(item.get("turnsRemaining", 0)),
		})
	var focus_name: String = ""
	if focus_system_id != null:
		focus_name = _system_name(game_state, str(focus_system_id))
	var summary: String = "当前可见星系 %s 个，待建项目 %s 个。%s" % [
		str(visible_systems.size()),
		str(queue.size()),
		"焦点星系: %s。" % focus_name if focus_name != "" else "当前未指定焦点星系。",
	]
	return {
		"summary": summary,
		"visible_systems": visible_systems,
		"treaties": treaties,
		"queue": queue,
		"pending_proposals": GameLogicScript.pending_proposals_for_player(game_state),
		"diplomatic_memories": GameLogicScript.visible_diplomatic_memories_for_player(game_state),
		"strategic_posture": GameLogicScript.strategic_posture_report(game_state),
		"intelligence_feed": GameLogicScript.recent_intelligence_feed(game_state, 10),
	}

func query_world_state(game_state: Dictionary, query_filter: String, _metrics: Array) -> Dictionary:
	var factions: Array = game_state.get("factions", [])
	var fleets: Array = game_state.get("fleets", [])
	var systems: Array = game_state.get("starSystems", [])
	var militaries: Array[int] = []
	for faction: Dictionary in factions:
		militaries.append(int(faction.get("militaryPower", 0)))
	var matching_entities: Array = []
	var normalized_filter: String = query_filter.to_upper().strip_edges()
	if normalized_filter == "" or normalized_filter == "ALL" or normalized_filter == "SYSTEMS":
		for system: Dictionary in systems.slice(0, min(8, systems.size())):
			matching_entities.append({
				"id": str(system.get("id", "")),
				"name": str(system.get("name", "")),
				"ownerId": system.get("ownerId", null),
				"value": _system_value(system),
			})
	elif "UNOWNED" in normalized_filter or "NULL" in normalized_filter:
		for system: Dictionary in systems:
			if system.get("ownerId", null) == null:
				matching_entities.append({
					"id": str(system.get("id", "")),
					"name": str(system.get("name", "")),
					"value": _system_value(system),
				})
	elif "FACTIONS" in normalized_filter:
		for faction: Dictionary in factions:
			matching_entities.append({
				"id": str(faction.get("id", "")),
				"name": str(faction.get("name", "")),
				"militaryPower": int(faction.get("militaryPower", 0)),
				"population": int(faction.get("population", 0)),
			})
	elif "FLEETS" in normalized_filter:
		for fleet: Dictionary in fleets:
			matching_entities.append({
				"id": str(fleet.get("id", "")),
				"ownerId": str(fleet.get("ownerId", "")),
				"location": _system_name(game_state, str(fleet.get("systemId", ""))),
				"strength": _fleet_strength(fleet),
			})
	return {
		"matching_entities": matching_entities,
		"statistics": {
			"faction_count": factions.size(),
			"fleet_count": fleets.size(),
			"visible_system_count": _visible_system_count(systems),
			"unowned_system_count": _unowned_system_count(systems),
			"average_military_power": _average_int(militaries),
			"war_count": _war_count(game_state),
		},
		"balance_assessment": _balance_assessment(militaries),
		"strategic_posture": GameLogicScript.strategic_posture_report(game_state),
	}

func validate_fleet_move(game_state: Dictionary, fleet_id: String, target_system_id: String, movement_mode: String = "NORMAL") -> Dictionary:
	var fleet: Dictionary = _fleet_by_id(game_state, fleet_id)
	if fleet.is_empty():
		return {
			"status": "INVALID_REQUEST",
			"ok": false,
			"reason": "未找到目标舰队。",
			"energy_cost": 0,
			"reachable_targets": [],
			"estimated_arrival_turns": 0,
			"path_segments": [],
			"warning_messages": [],
			"movement_mode": movement_mode,
		}
	var reachable_details: Array = GameLogicScript.reachable_system_details(game_state, fleet_id)
	var reachable_targets: Array = []
	var turns: int = 0
	for item: Dictionary in reachable_details:
		reachable_targets.append(str(item.get("systemId", "")))
		if str(item.get("systemId", "")) == target_system_id:
			turns = int(item.get("traversalCost", 0))
	var ok: bool = reachable_targets.has(target_system_id)
	return {
		"status": "SUCCESS" if ok else "INVALID_REQUEST",
		"ok": ok,
		"reason": "航线已确认。" if ok else "当前舰队无法到达目标星系。",
		"energy_cost": maxi(0, turns * 5),
		"reachable_targets": reachable_targets,
		"estimated_arrival_turns": turns,
		"path_segments": [str(fleet.get("systemId", "")), target_system_id] if ok else [],
		"warning_messages": [] if ok else ["目标超出当前跃迁范围。"],
		"movement_mode": movement_mode,
	}

func query_relationship_status(game_state: Dictionary, faction_a_id: String, faction_b_id: String) -> Dictionary:
	var relation: Dictionary = GameLogicScript.relation_breakdown(game_state, faction_a_id, faction_b_id)
	var recent_events: Array = []
	for item: Dictionary in GameLogicScript.relation_history_for_pair(game_state, faction_a_id, faction_b_id, 4):
		recent_events.append("T%s: 信任 %s / 恐惧 %s" % [str(item.get("turn", 0)), str(item.get("trust", 0)), str(item.get("fear", 0))])
	return {
		"trust_score": int(relation.get("trust", 0)),
		"utility_score": int(relation.get("utility", 0)),
		"fear_score": int(relation.get("fear", 0)),
		"affection_score": int(relation.get("affinity", 0)),
		"memory_impact": int(relation.get("memoryImpact", 0)),
		"relationship_level": str(relation.get("level", "UNKNOWN")),
		"recent_events": recent_events,
	}

func evaluate_proposal(game_state: Dictionary, proposal_id: String, evaluator_faction_id: String) -> Dictionary:
	var proposal: Dictionary = {}
	for item: Dictionary in game_state.get("pendingProposals", []):
		if str(item.get("id", "")) == proposal_id:
			proposal = item
			break
	if proposal.is_empty():
		return {
			"acceptance_score": 0,
			"key_concerns": ["未找到指定提案。"],
			"counter_proposal": null,
			"recommended_action": "REJECT",
		}
	var relation: Dictionary = GameLogicScript.relation_breakdown(game_state, evaluator_faction_id, str(proposal.get("sourceFactionId", "")))
	var score: int = int(relation.get("trust", 0)) + int(relation.get("utility", 0)) - int(relation.get("fear", 0)) / 2
	var action: String = "ACCEPT" if score >= 35 else "COUNTER" if score >= 10 else "REJECT"
	var concerns: Array = []
	if int(relation.get("fear", 0)) >= 40:
		concerns.append("对方军事实力带来的安全顾虑仍然较高。")
	if int(relation.get("trust", 0)) < 15:
		concerns.append("当前互信不足，建议先观察其履约意愿。")
	if concerns.is_empty():
		concerns.append("提案总体可控，但仍需关注后续执行细节。")
	return {
		"acceptance_score": score,
		"key_concerns": concerns,
		"counter_proposal": {
			"type": str(proposal.get("proposalType", "UNKNOWN")),
			"summary": "建议降低承诺强度并缩短观察周期。",
		} if action == "COUNTER" else null,
		"recommended_action": action,
	}

func execute_diplomatic_action(game_state: Dictionary, source_faction_id: String, target_faction_id: String, action_type: String, payload: Dictionary = {}) -> Dictionary:
	var relation: Dictionary = GameLogicScript.relation_breakdown(game_state, source_faction_id, target_faction_id)
	var response: Dictionary = {
		"status": "SUCCESS",
		"new_relation_state": relation,
		"reputation_change": 0,
		"rejection_reason": null,
	}
	match action_type:
		"DECLARE_WAR":
			response["new_relation_state"] = {"level": "HOSTILE", "trust": -100, "fear": int(relation.get("fear", 0)) + 15}
			response["reputation_change"] = -15
		"PROPOSE_ALLIANCE", "PROPOSE_NON_AGGRESSION", "PROPOSE_TRADE":
			response["new_relation_state"] = relation
			response["reputation_change"] = 2
		_:
			response["status"] = "INVALID_REQUEST"
			response["rejection_reason"] = "当前未支持该外交动作。"
	response["payload_echo"] = payload
	return response

func validate_construction(game_state: Dictionary, system_id: String, target_id: String, kind: String) -> Dictionary:
	var player: Dictionary = GameLogicScript.player_faction(game_state)
	var system: Dictionary = _system_by_id(game_state, system_id)
	if system.is_empty():
		return {"ok": false, "reason": "目标星系不存在。", "projected_turns": 0, "queue_depth": 0}
	var queue_depth: int = 0
	for item: Dictionary in game_state.get("constructionQueue", []):
		if str(item.get("systemId", "")) == system_id:
			queue_depth += 1
	if kind == "BUILDING":
		var blueprint: Dictionary = GameLogicScript.find_building_blueprint(target_id)
		if blueprint.is_empty():
			return {"ok": false, "reason": "未找到对应建筑蓝图。", "projected_turns": 0, "queue_depth": queue_depth}
		if int(system.get("buildings", []).size()) + GameLogicScript.queued_building_count_for_system(game_state, system_id) >= int(system.get("buildingSlots", 0)):
			return {"ok": false, "reason": "当前星系已没有可用建筑格位。", "projected_turns": 0, "queue_depth": queue_depth}
		if not GameLogicScript.can_afford(player.get("resources", {}), blueprint.get("cost", {})):
			return {"ok": false, "reason": "资源不足，无法安排该建筑。", "projected_turns": 0, "queue_depth": queue_depth}
		return {"ok": true, "reason": "可以安排该建筑。", "projected_turns": int(InitialDataScript.building_turns().get(target_id, 1)), "queue_depth": queue_depth}
	var has_shipyard: bool = _system_has_shipyard(system)
	if not has_shipyard:
		return {"ok": false, "reason": "目标星系缺少轨道船坞。", "projected_turns": 0, "queue_depth": queue_depth}
	var ship_cost: Dictionary = GameLogicScript.ship_cost(target_id, game_state, str(player.get("id", "f_player")))
	if not GameLogicScript.can_afford(player.get("resources", {}), ship_cost):
		return {"ok": false, "reason": "资源不足，无法建造该舰船。", "projected_turns": 0, "queue_depth": queue_depth}
	return {"ok": true, "reason": "可开始排产舰船。", "projected_turns": int(InitialDataScript.ship_turns().get(target_id, 1)), "queue_depth": queue_depth}

func query_fleet_status(game_state: Dictionary, fleet_id: String, include_units: bool = true) -> Dictionary:
	var fleet: Dictionary = _fleet_by_id(game_state, fleet_id)
	if fleet.is_empty():
		return {"location": "未知", "mission": "未找到舰队", "strength": 0, "unit_composition": [], "readiness": "CRITICAL"}
	var ships: Array = fleet.get("ships", [])
	var total_hp: int = 0
	var total_max_hp: int = 1
	for ship: Dictionary in ships:
		total_hp += int(ship.get("hp", 0))
		total_max_hp += int(ship.get("maxHp", 0))
	var ratio: float = float(total_hp) / float(total_max_hp)
	var readiness: String = "FULL" if ratio >= 0.8 else "DEGRADED" if ratio >= 0.45 else "CRITICAL"
	var composition: Array = []
	if include_units:
		for ship: Dictionary in ships:
			composition.append({
				"name": str(ship.get("name", "未知舰船")),
				"type": str(ship.get("type", "UNKNOWN")),
				"hp": int(ship.get("hp", 0)),
				"maxHp": int(ship.get("maxHp", 0)),
				"damage": int(ship.get("damage", 0)),
			})
	return {
		"location": _system_name(game_state, str(fleet.get("systemId", ""))),
		"mission": GameLogicScript.fleet_mission_label(str(fleet.get("mission", "IDLE"))),
		"strength": _fleet_strength(fleet),
		"unit_composition": composition,
		"readiness": readiness,
	}

func recommend_tactical_approach(game_state: Dictionary, attacker_fleet_id: String, target_system_id: String, defender_fleet_id: String = "", attack_objective: String = "OCCUPY") -> Dictionary:
	var attacker: Dictionary = _fleet_by_id(game_state, attacker_fleet_id)
	var defender: Dictionary = _fleet_by_id(game_state, defender_fleet_id)
	var attacker_strength: int = _fleet_strength(attacker)
	var defender_strength: int = _fleet_strength(defender)
	var tactic: String = "LINE"
	var expected: Array = ["以标准火力投送压制目标轨道。"]
	var risks: Array = ["若敌方存在高闪避护卫舰，前排可能承受额外损失。"]
	if attack_objective == "RAID":
		tactic = "HIT_AND_RUN"
		expected = ["优先打击补给节点后迅速脱离。"]
		risks = ["若撤离航线被封锁，轻舰损失会明显上升。"]
	elif defender_strength > 0 and attacker_strength < defender_strength:
		tactic = "SPHERE"
		expected = ["建议保持防御阵型，拉长交战时间等待援军。"]
		risks = ["正面歼灭能力不足，占领效率偏低。"]
	elif attack_objective == "OCCUPY":
		tactic = "WEDGE"
		expected = ["集中突击星系要害，有机会快速夺取控制权。"]
		risks = ["前锋舰船会承受更高战损。"]
	expected.append("目标星系: %s" % _system_name(game_state, target_system_id))
	expected.append("我方当前估算战力约为 %s。" % str(attacker_strength))
	if defender_strength > 0:
		expected.append("敌方当前估算战力约为 %s。" % str(defender_strength))
	return {
		"recommended_tactics": tactic,
		"expected_outcomes": expected,
		"risk_assessments": risks,
	}

func preview_director_event(game_state: Dictionary, event_template_id: String, target_location: String, affected_factions: Array) -> Dictionary:
	var system_name: String = _system_name(game_state, target_location)
	var narrative: String = "%s 出现新的星际异象。" % system_name
	match event_template_id:
		"ANCIENT_RUINS_DISCOVERY":
			narrative = "%s 的远古遗迹被重新激活，沉寂数据库开始吐出碎片化星图。" % system_name
		"PIRATE_RAID":
			narrative = "%s 周边出现海盗袭扰迹象，多支走私舰队正试图切断补给线。" % system_name
		"WARP_STORM":
			narrative = "%s 附近爆发跃迁风暴，局部航道稳定性明显下降。" % system_name
	return {
		"event_id": "evt_%s_%s" % [event_template_id.to_lower(), target_location],
		"narrative_content": narrative,
		"immediate_effects": ["影响势力: %s" % ", ".join(affected_factions)],
		"follow_up_options": ["派遣舰队调查", "发布公开通告", "保持观望"],
	}

func query_resource_status(game_state: Dictionary, faction_id: String, _scope: String = "GLOBAL", _system_id: Variant = null) -> Dictionary:
	var faction: Dictionary = _faction_by_id(game_state, faction_id)
	var stock: Dictionary = faction.get("resources", {})
	var rates: Dictionary = faction.get("resourceRates", {})
	var warnings: Array = []
	for key: String in ["food", "minerals", "industry", "energy"]:
		if int(rates.get(key, 0)) < 0:
			warnings.append("%s 净产出为负，需尽快调整。" % _resource_label(key))
	return {
		"food": {"stock": int(stock.get("food", 0)), "net": int(rates.get("food", 0))},
		"minerals": {"stock": int(stock.get("minerals", 0)), "net": int(rates.get("minerals", 0))},
		"industry": {"stock": int(stock.get("industry", 0)), "net": int(rates.get("industry", 0))},
		"energy": {"stock": int(stock.get("energy", 0)), "net": int(rates.get("energy", 0))},
		"balance_warning": warnings,
	}

func apply_resource_policy(game_state: Dictionary, _faction_id: String, policy_name: String, value: float, priority_focus: String = "BALANCED", scope: String = "GLOBAL", system_id: Variant = null) -> Dictionary:
	if policy_name == "TAX_RATE" and (value < 0.0 or value > 0.5):
		return {
			"status": "INVALID_REQUEST",
			"scope": scope,
			"updated_policies": {},
			"applied_on_turn": int(game_state.get("turn", 1)),
			"warning_messages": ["税率必须位于 0.0 到 0.5 之间。"],
		}
	return {
		"status": "SUCCESS",
		"scope": scope,
		"updated_policies": {
			"system_id": system_id,
			"policy_name": policy_name,
			"value": maxf(0.0, value),
			"priority_focus": priority_focus,
		},
		"applied_on_turn": int(game_state.get("turn", 1)) + 1,
		"warning_messages": [],
	}

func query_research_priority(game_state: Dictionary, faction_id: String, tech_id: String, allocation: float = 1.0) -> Dictionary:
	var target: Dictionary = {}
	for tech: Dictionary in game_state.get("technologies", []):
		if str(tech.get("id", "")) == tech_id:
			target = tech
			break
	if target.is_empty():
		return {"current_research": null, "progress": 0.0, "estimated_completion_turns": null, "prerequisites_met": false}
	var researched_ids: Array = []
	for tech: Dictionary in game_state.get("technologies", []):
		if tech.get("status", "") == "RESEARCHED":
			researched_ids.append(tech.get("id", ""))
	var prerequisites_met: bool = true
	for tech_id_required: String in target.get("prerequisites", []):
		if not researched_ids.has(tech_id_required):
			prerequisites_met = false
			break
	var progress: float = float(game_state.get("researchProgress", 0.0))
	var cost: float = maxf(1.0, float(target.get("cost", 100.0)))
	var faction: Dictionary = _faction_by_id(game_state, faction_id)
	var research_income: float = maxf(1.0, float(faction.get("resourceRates", {}).get("research", 12)))
	var remaining: float = maxf(0.0, cost - progress)
	return {
		"current_research": tech_id,
		"progress": progress,
		"estimated_completion_turns": ceili(remaining / maxf(1.0, research_income * maxf(0.1, allocation))) if prerequisites_met else null,
		"prerequisites_met": prerequisites_met,
	}

func order_ship_production(game_state: Dictionary, faction_id: String, system_id: String, ship_type: String, quantity: int = 1, priority: String = "NORMAL") -> Dictionary:
	var system: Dictionary = _system_by_id(game_state, system_id)
	if system.is_empty():
		return {"status": "INVALID_REQUEST", "production_queue": [], "estimated_completion": 0, "resource_cost": {}, "rejection_reason": "目标星系不存在。"}
	if system.get("ownerId", null) != faction_id:
		return {"status": "INVALID_REQUEST", "production_queue": [], "estimated_completion": 0, "resource_cost": {}, "rejection_reason": "不能在非己方星系下达舰船生产。"}
	if not _system_has_shipyard(system):
		return {"status": "INVALID_REQUEST", "production_queue": [], "estimated_completion": 0, "resource_cost": {}, "rejection_reason": "目标星系缺少轨道船坞。"}
	if not GameLogicScript.available_ship_types(game_state).has(ship_type):
		return {"status": "INVALID_REQUEST", "production_queue": [], "estimated_completion": 0, "resource_cost": {}, "rejection_reason": "尚未解锁该舰船。"}
	var unit_cost: Dictionary = GameLogicScript.ship_cost(ship_type, game_state, faction_id)
	var total_cost: Dictionary = {}
	for key: String in unit_cost.keys():
		total_cost[key] = int(unit_cost.get(key, 0)) * maxi(1, quantity)
	var faction: Dictionary = _faction_by_id(game_state, faction_id)
	if not GameLogicScript.can_afford(faction.get("resources", {}), total_cost):
		return {"status": "INVALID_REQUEST", "production_queue": [], "estimated_completion": 0, "resource_cost": total_cost, "rejection_reason": "资源储备不足。"}
	var queue: Array = []
	for item: Dictionary in game_state.get("constructionQueue", []):
		if str(item.get("systemId", "")) == system_id:
			queue.append({
				"systemId": item.get("systemId", ""),
				"targetId": item.get("targetId", ""),
				"turnsRemaining": int(item.get("turnsRemaining", 0)),
				"kind": item.get("kind", ""),
			})
	queue.append({
		"systemId": system_id,
		"targetId": ship_type,
		"turnsRemaining": int(InitialDataScript.ship_turns().get(ship_type, 1)) * maxi(1, quantity),
		"kind": "SHIP",
		"priority": priority,
	})
	return {
		"status": "SUCCESS",
		"production_queue": queue,
		"estimated_completion": int(InitialDataScript.ship_turns().get(ship_type, 1)) * maxi(1, quantity),
		"resource_cost": total_cost,
		"rejection_reason": null,
	}

func preview_combat_protocol(game_state: Dictionary, fleet_id: String, target_type: String, target_id: String, engagement_rules: String = "ALL_OUT", formation: String = "LINE") -> Dictionary:
	var attacker: Dictionary = _fleet_by_id(game_state, fleet_id)
	if attacker.is_empty():
		return {"status": "INVALID", "tactical_notes": ["未找到进攻舰队。"]}
	var defender: Dictionary = {}
	if target_type == "FLEET":
		defender = _fleet_by_id(game_state, target_id)
	if target_type == "FLEET" and defender.is_empty():
		return {"status": "INVALID", "tactical_notes": ["目标舰队不存在。"]}
	var attacker_strength: int = _fleet_strength(attacker)
	var defender_strength: int = _fleet_strength(defender)
	var modifier: float = 1.0
	var notes: Array = ["交战规则: %s" % engagement_rules, "阵型: %s" % formation]
	if engagement_rules == "HIT_AND_RUN":
		modifier *= 0.88
		notes.append("机动规避优先，歼灭效率下降。")
	elif engagement_rules == "ALL_OUT":
		modifier *= 1.08
		notes.append("全力突击，战损风险同步上升。")
	if formation == "WEDGE":
		modifier *= 1.12
		notes.append("楔形突击有利于快速撕开防线。")
	elif formation == "SPHERE":
		modifier *= 0.94
		notes.append("球形防御阵型提升生存能力。")
	var adjusted_strength: int = int(round(float(attacker_strength) * modifier))
	var victory: bool = adjusted_strength >= maxi(1, defender_strength)
	return {
		"status": "READY",
		"victory": victory,
		"casualties": maxi(1, int(attacker.get("ships", []).size() * (0.2 if victory else 0.6))),
		"kills": defender.get("ships", []).size() if victory else maxi(0, int(defender.get("ships", []).size() * 0.3)),
		"remaining_power": maxi(0, int((adjusted_strength - defender_strength) / maxf(1.0, float(adjusted_strength)) * 100.0)),
		"tactical_notes": notes,
	}

func preview_director_intervention(intervention_type: String, intensity: float = 0.5, duration: int = 3) -> Dictionary:
	var effects: Array = []
	var perception: String = "SUBTLE"
	match intervention_type:
		"SPAWN_PIRATES":
			effects = ["将在边境生成海盗威胁点", "持续 %s 回合干扰补给线" % str(duration)]
			perception = "VISIBLE"
		"BOOST_AI":
			effects = ["目标 AI 获得临时产能与战备加成", "强度系数 %.2f" % intensity]
			perception = "HIDDEN"
		"REDUCE_RESOURCES":
			effects = ["目标范围资源净产出将被压制", "预计持续 %s 回合" % str(duration)]
		"TRIGGER_CRISIS":
			effects = ["将触发区域级危机链条", "多势力会被迫重新调整战略目标"]
			perception = "VISIBLE"
		_:
			effects = ["未知导演干预类型。"]
	return {
		"intervention_id": "director_%s_%s" % [intervention_type.to_lower(), str(int(round(intensity * 100.0)))],
		"effects_summary": effects,
		"player_perception": perception,
	}

func _system_by_id(game_state: Dictionary, system_id: String) -> Dictionary:
	for system: Dictionary in game_state.get("starSystems", []):
		if str(system.get("id", "")) == system_id:
			return system
	return {}

func _fleet_by_id(game_state: Dictionary, fleet_id: String) -> Dictionary:
	for fleet: Dictionary in game_state.get("fleets", []):
		if str(fleet.get("id", "")) == fleet_id:
			return fleet
	return {}

func _faction_by_id(game_state: Dictionary, faction_id: String) -> Dictionary:
	for faction: Dictionary in game_state.get("factions", []):
		if str(faction.get("id", "")) == faction_id:
			return faction
	return {}

func _faction_name(game_state: Dictionary, faction_id: String) -> String:
	var faction: Dictionary = _faction_by_id(game_state, faction_id)
	return str(faction.get("name", faction_id))

func _system_name(game_state: Dictionary, system_id: String) -> String:
	var system: Dictionary = _system_by_id(game_state, system_id)
	return str(system.get("name", system_id))

func _system_value(system: Dictionary) -> int:
	var resources: Dictionary = system.get("resources", {})
	return int(resources.get("food", 0)) + int(resources.get("minerals", 0)) * 3 + int(resources.get("industry", 0)) * 2 + int(resources.get("energy", 0)) * 3

func _fleet_strength(fleet: Dictionary) -> int:
	var strength: int = 0
	for ship: Dictionary in fleet.get("ships", []):
		strength += int(ship.get("hp", 0)) + int(ship.get("damage", 0)) * 4
	return strength

func _visible_system_count(systems: Array) -> int:
	var count: int = 0
	for system: Dictionary in systems:
		if ["FULL", "PARTIAL"].has(str(system.get("visibilityLevel", "HIDDEN"))):
			count += 1
	return count

func _unowned_system_count(systems: Array) -> int:
	var count: int = 0
	for system: Dictionary in systems:
		if system.get("ownerId", null) == null:
			count += 1
	return count

func _average_int(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var total: int = 0
	for value: int in values:
		total += value
	return int(round(float(total) / float(values.size())))

func _war_count(game_state: Dictionary) -> int:
	var count: int = 0
	for treaty: Dictionary in game_state.get("treaties", []):
		if treaty.get("type", "") == "WAR_STATE" and treaty.get("status", "") == "ACTIVE":
			count += 1
	return count

func _balance_assessment(militaries: Array[int]) -> String:
	if militaries.is_empty():
		return "BALANCED"
	var strongest: int = militaries.max()
	var weakest: int = militaries.min()
	var spread: int = strongest - weakest
	if spread <= 60:
		return "BALANCED"
	if spread <= 140:
		return "SLIGHTLY_UNBALANCED"
	if spread <= 260:
		return "UNBALANCED"
	return "CRITICAL"

func _system_has_shipyard(system: Dictionary) -> bool:
	for building: Dictionary in system.get("buildings", []):
		if str(building.get("type", "")) == "SHIPYARD":
			return true
	return false

func _resource_label(key: String) -> String:
	match key:
		"food":
			return "食物"
		"minerals":
			return "矿产"
		"industry":
			return "工业"
		"energy":
			return "能源"
		_:
			return key

