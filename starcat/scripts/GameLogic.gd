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
	for blueprint: Dictionary in InitialData.building_catalog():
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
		return {"allowed": false, "reason": "闂備礁鎼悧婊勭閻愮儤鍋傞柍銉︽灱閺嬫棃鏌″鍐ㄥ婵絽鏈穱濠囶敍濡炶浜剧€规洖娲ㄩ、鍛存⒑?, "cost": COLONY_COST, "turns": 0}
	for entry: Dictionary in state.get("fleets", []):
		if entry.get("id", "") == fleet_id:
			fleet = entry
			break
	for entry: Dictionary in state.get("starSystems", []):
		if entry.get("id", "") == system_id:
			system = entry
			break
	if fleet.is_empty() or system.is_empty():
		return {"allowed": false, "reason": "缂傚倸鍊搁崐鎼佸箹椤愶附鍎嶆い鏍仦閸ゅ霉閻撳海鎽犵悮婵嬫⒑閻熸壆鎽犻柣妤侇殔鍗遍柨鏃€鍎崇€垫煡鎮规担鍝ワ紞闁荤喐鍔曢埥澶愬箻閹颁礁鍓遍梺鍝勵儏閸熷瓨淇?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if fleet.get("ownerId", "") != player.get("id", "") or fleet.get("systemId", "") != system_id:
		return {"allowed": false, "reason": "闂傚倸鍊稿ú鐘诲磻閹剧粯鍋￠柡鍥ㄦ皑椤︼妇绱掔拋宕囩獢鐎殿噮鍓涘☉鐢稿川椤撶姴甯撻梻鍌氬€搁崯浼村窗閺嶎厼鐓樻俊銈呮噺閸嬧晜绻涢崱妤冪闂婎剦鍓熼弻锝夊煛婵犲倹鐏嶉梺缁樼壄缂嶄礁顕ｆ导瀛樺亜婵炲樊浜滈崢娆撴⒑?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if system.get("visibilityLevel", "") != "FULL":
		return {"allowed": false, "reason": "闂傚鍋勫ú銈夊箠濮椻偓婵＄绠涘☉妯碱槯闂佸壊鍋呯换鍕汲濮樿埖鐓曢煫鍥ь儏婵′粙鎮介娆忓祮鐎殿喚澧楅幆鏃堝閳辨帗娲滅槐鎺楊敍濞戞碍鑿囬梺?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if system.get("ownerId", null) != null or system.get("colonyStage", "NONE") != "NONE":
		return {"allowed": false, "reason": "闂備胶鍎甸弲鈺呭窗濡ゅ懏鍋夐柨婵嗩槸閸欏﹪鏌ｉ弮鈧浠嬪礂閸モ斁鍋撶憴鍕憙閻忓浚浜敐鐐烘晝閸屾氨顢呴梺缁樕戝鍧楀汲濞嗘挻鐓欓悗娑欘焽婢ь剚銇勯幒鎾剁煉鐎规洜鍏樻俊鎼佹晜閻愵剚鐦掓繝娈垮枟钃遍柛銊﹀▕閹虫瑩骞嬮敃鈧繚?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if not has_research(state, "tech_deep_colonization"):
		return {"allowed": false, "reason": "闂傚倸鍊稿ú鐘诲磻閹剧粯鍋￠柡鍥ㄦ皑椤︼箓鏌涘Ο鑽ゃ€掗柍褜鍓涢幊鎾诲嫉椤掑嫬鍨傛慨妯挎硾閺勩儵鏌ц箛姘煎殐闁衡偓閵婏妇绠鹃柨婵嗙墔閸氼偊鏌嶇憴鍕ⅹ闁崇粯鎹囧浠嬪Ω瑜庨惁婊堟⒑?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	if not can_afford(player.get("resources", {}), mode_data.get("cost", COLONY_COST)):
		return {"allowed": false, "reason": "闂佽崵濮嶉崘顭戜痪缂備緡鐓堥崰妤冪矙婢跺鍚嬮柛顐ｇ箓閺嬫瑩姊洪幐搴ｂ槈闁哄牜鍓欒灋闁靛牆鎳夐弸鏍煛閸モ晛浠滅紒鍙夋そ閹顦归柡鈧柆宥嗗仼闁告繂瀚峰鈺呮煙鐎涙鎲块柛?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}
	return {"allowed": true, "reason": "闂備礁鎲￠悷顖炲垂閹峰被浜归柛灞剧矋鐏忓酣姊洪崹顕呭剳闁哄棭鍋呴幈銊ノ熺拠鑼户闂?, "cost": mode_data.get("cost", COLONY_COST), "turns": int(mode_data.get("turns", 0))}

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
		"status": "濠德板€曢崐纭呮懌闂佸搫鎳岄崕鐢稿箚閸曨垰绠ｆ繝闈涙搐閸撳墎绱? if capability >= 0.65 else "闂佸搫顦悧蹇涘箠閹炬眹鈧倿濡搁埡鍌氬壆闂佺懓鐡ㄧ换鍐磿閺冨牊鈷? if capability >= 0.35 else "闂備胶纭堕弲鐐测枍閿濆鈧線宕ㄧ€涙ê鍓梺鐟扮摠缁诲啴宕?
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
			"title": str(report.get("title", "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍嵁鎼淬劌唯闁靛绠戦弳?)),
			"summary": "%s vs %s / %s / 闂備礁鎲￠幐鎾疾濞嗘垹绀婇柟杈剧畱缁狅絾淇婇姘儓妞?%s%%" % [
				str(report.get("attackerName", "闂佸搫顦弲婊呯矙閹烘鏋佸Δ锝呭暙濡?)),
				str(report.get("defenderName", "闂傚倸鍊搁崯顖濄亹閸愵喗鍋╃憸鏂款嚕?)),
				"闂備浇澹堝▍鏇犲垝瀹€鍕槬? if report.get("victory", false) else "濠电姰鍨煎▔娑樼暦椤掑嫬鏄?,
				str(report.get("remainingPower", 0))
			]
		})
	for event_item: Dictionary in state.get("activeNarrativeEvents", []):
		if event_item.get("status", "ACTIVE") != "ACTIVE":
			continue
		var event_system_name: String = str(event_item.get("systemId", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т閸欏﹪鏌ｉ弮鈧浠嬪礂?))
		for system: Dictionary in state.get("starSystems", []):
			if system.get("id", "") == event_item.get("systemId", ""):
				event_system_name = str(system.get("name", event_system_name))
				break
		feed.append({
			"turn": int(event_item.get("turnCreated", state.get("turn", 1))),
			"priority": 4,
			"category": "EVENT",
			"title": str(event_item.get("title", "闂備礁鎲￠悷锕傛偡閵堝洩濮抽柕濠忓椤╂煡鎮楅敐鍌涙珕妞?)),
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
			"summary": "闂備礁鎲￠幐鎾疾濞嗘垹绀?%s 闂備焦鎮堕崕鎶藉磻濞戙垹绠?/ 闁诲孩顔栭崰鏍箹椤愩倐鍋?%s" % [str(intervention.get("remainingTurns", 0)), str(intervention.get("intensity", 0.0))]
		})
	for memory: Dictionary in visible_memories.slice(0, min(6, visible_memories.size())):
		feed.append({
			"turn": int(memory.get("turn", 0)),
			"priority": 2 + int(memory.get("importance", 1)),
			"category": "DIPLOMACY",
			"title": str(memory.get("title", "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏃傚亾婵ジ鏌℃径搴㈢《缂?)),
			"summary": str(memory.get("summary", ""))
		})
	for message: Dictionary in visible_messages.slice(0, min(6, visible_messages.size())):
		feed.append({
			"turn": int(message.get("turn", 0)),
			"priority": 2,
			"category": "SIGNAL",
			"title": str(message.get("title", "闂傚倷绶￠崑鍛┍濞差亶鏁?)),
			"summary": "%s / %s" % [str(message.get("visibilityLevel", "PUBLIC")), str(message.get("content", ""))]
		})
	for message: Dictionary in state.get("messages", []).slice(0, min(6, state.get("messages", []).size())):
		feed.append({
			"turn": int(message.get("turn", 0)),
			"priority": 1,
			"category": str(message.get("type", "EVENT")),
			"title": str(message.get("title", "闂備浇顕栭崹浼村箠韫囨梹鍙?)),
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
	if "濠电偛鐡ㄧ划宥囨暜婵犲嫮绠斿璺侯儑閻熷綊鏌ｉ姀銈嗘锭鐞? in message_text or "闂備胶顭堥鍡欏垝鎼淬垹顕遍柍? in message_text or "ceasefire" in lowered or "non aggression" in lowered:
		return {"type": "TREATY", "treaty": "NON_AGGRESSION", "tone": "friendly", "trust_delta": 6}
	if "缂傚倷绀侀ˇ浼村垂瑜版帗鍋夋繛宸簻绾偓闂婎偄娲﹂幐楣冨汲? in message_text or "闂備浇澹堟ご鎼佸蓟閵娾晛绠栭幖娣妽閸庢﹢鏌￠崘銊モ偓鐢稿极閳? in message_text or "research" in lowered:
		return {"type": "TREATY", "treaty": "RESEARCH_ACCORD", "tone": "friendly", "trust_delta": 5}
	if "闂備礁鎲￠懝楣冩儔閻撳篃? in message_text or "alliance" in lowered:
		return {"type": "TREATY", "treaty": "ALLIANCE", "tone": "friendly", "trust_delta": 7}
	if "闂佽崵濮甸崝鏇㈠箟閳ユ緞? in message_text or "闂備礁鎲￠懝楣冩偋閸涱垳绀? in message_text or "trade" in lowered or "peace" in lowered or "闂備礁鎲＄划宀勬嚐椤栫偞鐓? in message_text:
		return {"type": "TRADE", "tone": "friendly", "trust_delta": 5}
	if "濠电姷鏁搁崑妯好归崶顒€纾? in message_text or "闂備胶鎳撻悺銊ф箒缂? in message_text or "闂佽娴峰▍銏㈠緤妤ｅ啫鍨? in message_text or "attack" in lowered or "war" in lowered:
		return {"type": "WARNING", "tone": "firm", "trust_delta": -8}
	return {"type": "MESSAGE", "tone": "neutral", "trust_delta": 1}

static func describe_player_diplomatic_intent(message_text: String) -> Dictionary:
	var intent: Dictionary = parse_player_diplomatic_intent(message_text)
	var intent_type: String = str(intent.get("type", "MESSAGE"))
	var label: String = "濠电偞鍨堕幐鎾磻閹剧粯鐓犻柛鎾村絻閸樺憡鎱ㄥ鍫㈢暠闂?
	var detail: String = "濠电偞娼欓崥瀣┍濞差亷缍栭柨鏃傚亾閸犲棝鏌涢埄鍐╃缂佲偓鐎ｎ喗鐓涢柛婊€绀佸▍宥夋煃瑜滈崜姘卞枈瀹ュ鍎楅柨鐔哄У閻掔粯鎱ㄥΟ鍝勨挃缂佲偓婢跺ň妲堥柟鎯х摠椤銇勯埡瀣暢闁靛洦鍔欏畷锟犳倷鐎涙ê鍔岄梺鍝勵槺閸嬬娀顢氳缁傚秹寮撮悢琛℃敵闂佺偨鍎卞璺虹暦閺屻儲鐓?
	if intent_type == "TREATY":
		var treaty_id: String = str(intent.get("treaty", "NON_AGGRESSION"))
		var treaty_label: String = InitialData.treaty_labels().get(treaty_id, treaty_id)
		label = "闂備礁鎼¨鈧紒杈ㄦ礈閳ь剝顫夋繛濠囩嵁閹捐绠涙い鏍电到閺?
		detail = "缂傚倷绶￠崹闈涚暦閻㈤潧鍨濋柣鎴灻杈ㄦ叏濮楀棗骞栭幆鐔兼煛婢跺棙娅嗛柣鐕傜畵椤㈡瑥鐣濋埀顒勫箯閻樻祴鏀藉┑鐘插缂嶅﹥绻?%s 闂備礁婀辩划顖炲礉濮椻偓椤㈡瑩宕ㄧ€涙ɑ娅栭柣蹇曞仜閳ь剛鍠庨悵顖炴煟閻斿摜鎳曠紒鐘冲灱閵囨劙宕掑鍏兼〃闂佹寧绻傞幊鎰兜閳ь剟姊洪崫鍕垫缂佽鲸娲滈埀顒傛嚀绾绢參骞忛悩璇茬妞ゅ繐瀚幐銈夋⒑? % treaty_label
	elif intent_type == "TRADE":
		label = "闂佽崵濮甸崝鏇㈠箟閳ユ緞锝呂旈崨顓⌒曢梺鍓插亝缁海绮?
		detail = "缂傚倷绶￠崹闈涚暦閻㈤潧鍨濋柣鎴灻杈ㄦ叏濮楀棗骞栭幆鐔兼煛婢跺棙娅嗛柣鐕傜畵椤㈡瑥鐣濋埀顒勫箯閻樻祴鏀藉┑鐘插缂嶅﹥绻涢幋鐐村磳缂傚倹宀搁弻銊╁Χ婢跺﹤寮烽梺鍦亾濞兼瑩鎮樺Δ鍛厱婵﹩鍓涙晶鏃傜磽瀹ュ棙鈷愮紒宀勪憾閸ㄩ箖宕橀幓鎺嗘瀼闂備焦瀵х粙鎴﹀嫉椤掑啨浜瑰〒姘ｅ亾鐎规洩绻濆畷鎯邦槻鐟滄壆濮风槐鎺楊敍濠垫劕娈梺閫炲苯澧柛搴㈠▕楠炲啫顭ㄩ崼婢?
	elif intent_type == "WARNING":
		label = "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏃傚亾婵即鏌ㄩ弴妤€浜鹃梺?
		detail = "缂傚倷绶￠崹闈涚暦閻㈤潧鍨濋柣鎴灻杈ㄦ叏濮楀棗骞栭幆鐔兼煛婢跺棙娅嗛柣鐕傜畵椤㈡瑥鐣濋埀顒勫箯閻樻祴鏀藉┑鐘插缂嶅﹥绻涢幋鐐村碍闁圭⒈鍋勯蹇旀綇閳哄倸鍘瑰銈嗗笒閸犳岸宕濋崨瀛樼厱婵炴垶锕╅悡顓犵磼鏉堛劎绠炴慨濠呮椤撳ジ宕熼鐘橈綁姊虹粙璺ㄧ缁剧虎鍙冮弻鍫ュ箻椤旀儳绁﹂梺鍏兼倐濞佳呭緤閻熸嫈鏃堝磼濞戣京鍔烽梺閫涚串缁蹭粙顢氶敐澶嬪亹闁圭粯甯╅崬娲⒑?
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
	next_state = update_diplomatic_profile(next_state, sender_id, "friendly", 6, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦粻鎶芥煏婢跺牆鍔氱紓宥佸亾濠电偛鐡ㄧ划灞轿涘▎鎾冲瀭婵犲﹤鐗嗗Λ姗€鎮峰▎蹇擃仼缂佽尪顫夋穱濠偽旈埀顒勬偋閻愬灚顫曟繝闈涱儏閻銇勯弽銊х煁闁糕晜绋撶槐鎾寸瑹閸パ冪闁汇埄鍨扮紞濠傜暦濠靛惟闁挎梻鏅崙钘夆攽閻戝洨鍒扮€规洦鍓熼獮鍐╂償閵忊€愁€?)
	next_state = add_diplomatic_memory(next_state, "闂備礁婀辩划顖炲礉閺嶎厹鈧礁顓奸崪浣告櫊闂佸憡鐟ラˇ顖涘緞瀹ュ鐓?, "%s 闁诲氦顫夐悺鏇犱焊椤忓牞缍栭柨鏇炲€归崑婵嬫煃鏉炴壆璐伴柛鐔插亾闂備浇顫夋禍浠嬪磿鏉堫偁浜归柛顐犲劚杩? % target_proposal.get("title", "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏇炲€哥粻鐢告煙闁箑寮鹃柡鈧?), [sender_id, target_id], "AGREEMENT", 3)
	return add_message(next_state, "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏇炲€哥粻鐢告煙闁箑寮鹃柡鈧幎鑺ョ厵闁诡厽甯掗崝姘辨喐?, "濠电偠鎻徊鎸庢叏閻㈠灚鏆滈柟缁㈠枛閻淇婇悙鎻掆挃闁?%s闂? % target_proposal.get("title", "濠电偞鍨堕幐鎾磻閹炬剚娓婚柕鍫濈墱濞兼劗鎲告０浣侯槮妞?), "DIPLOMATIC")

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
	next_state = update_diplomatic_profile(next_state, sender_id, "firm", -5, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦粻顖炴煙閻戞ɑ鈷掗柛妤佺矊闇夋繝濠傚暞椤ョ偤鏌涢妸锔剧煉鐎殿噮鍓涢幉鎾礋椤愩倕鈧帒鈹戦埄鍐炬當闁绘鍋熷Σ鎰攽鐎ｎ偒姊块梺閫炲苯澧伴柟鑼缁楃喖鍩€椤掑嫬闂柟闂寸濡﹢鏌熷畡鎵伇婵″弶鍨甸湁闁稿繒鍘ч婊勩亜閺傚搫浜炬繝娈垮枟缁哄潡宕曢幎钘夌厴闁哄稁鍘介埛?)
	next_state = add_diplomatic_memory(next_state, "闂備礁婀辩划顖炲礉閺嶎厹鈧礁顓奸崶銊ヤ粡濡炪倖鍔х徊浠嬫偟閺囩姷纾?, "%s 闂佽崵鍋為崙褰掑磻閸℃瑦鏆滈柧蹇撳帨閸嬫挾娑甸崨顓犲帿闁诲孩鑹惧Λ娑氭閹烘垟鏀介柛鏇樺妼娴? % target_proposal.get("title", "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏇炲€哥粻鐢告煙闁箑寮鹃柡鈧?), [sender_id, target_id], "PROPOSAL", 2)
	return add_message(next_state, "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏇炲€哥粻鐢告煙闁箑寮鹃柡鈧幎鑺ョ厵闂佸灝顑呯粭褏绱?, "濠电偠鎻徊鎸庢叏閻㈢鍋撳顒侇棤缂佽鲸甯掗埞鎴﹀川椤栨碍娅?%s闂? % target_proposal.get("title", "濠电偞鍨堕幐鎾磻閹炬剚娓婚柕鍫濈墱濞兼劗鎲告０浣侯槮妞?), "DIPLOMATIC")

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
		next_state = add_diplomatic_memory(next_state, "闂備礁婀辩划顖炲礉閺嶎厹鈧礁顓奸崱妯规唉闂佹悶鍎崝宥夊春?, "%s 闁诲海鎳撻幉陇銇愰崘顭嬪搫顭ㄩ崨顔藉劚闂佸憡渚楅崰妤吽囪椤潡骞嗘导鏉戞懙闂佸搫鎳岄崕鍨繆? % proposal.get("title", "濠电姰鍨奸崺鏍偋閺傛娼╅柨鏇炲€哥粻鐢告煙闁箑寮鹃柡鈧?), [proposal.get("senderFactionId", ""), proposal.get("targetFactionId", "")], "PROPOSAL", 1)
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

static func fleet_mission_label(mission: String) -> String:
	return str(InitialData.fleet_mission_labels().get(mission, mission))

static func set_fleet_mission(state: Dictionary, fleet_id: String, mission: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var fleet_index: int = find_fleet_index(next_state, fleet_id)
	if fleet_index == -1:
		return next_state
	var fleet: Dictionary = next_state["fleets"][fleet_index]
	if fleet.get("ownerId", "") != "f_player":
		return next_state
	fleet["mission"] = mission
	next_state["fleets"][fleet_index] = fleet
	return add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晜閻ｅ矈娴勯柣鐘叉处瑜板啴锝為妶澶嬬厸闁搞儜鍛喖闂?, "%s 闁诲海鎳撻幉陇銇愰崘顔煎瀭闊洦绋戠粻鍙夈亜椤愵偄寮ㄧ紒鈧?s闂? % [str(fleet.get("name", "闂備礁銈搁弲鏌ュ础閸愬弬?)), fleet_mission_label(mission)], "SYSTEM")

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
	return add_message(next_state, "闁诲孩顔栭崰鎺楀磻閹炬枼鏀芥い鏃傗拡閸庢垿鏌ｉ弽顒侇仩缂?, "闁诲海鎳撻幉陇銇愰崘顏咁潟闁瑰鍋為崣蹇涙倵閿濆骸澧伴柛鈺嬬磿缁?%s闂? % target.get("name", ""), "SYSTEM")

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
		return add_message(next_state, "闂備焦妞块崰妤€顫忔繝姘厴闁圭儤顨呴惌妤呮煛瀹ュ啫濡块崯?, "%s 闁诲海鎳撻幉陇銇愰崘顓滀汗闁搞儜鈧Σ鍫ユ煕椤愵偄澧扮紒鈧径鎰骇闁冲搫鍊归ˉ鍡欑磼?%s 闁诲氦顫夐幃鍫曞磿閹殿喚绠旈柣鏃傚帶杩? % [tech.get("name", ""), str(refund)], "SYSTEM")
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
	var ships: Array = fleet.get("ships", [])
	if ships.size() < 2:
		return add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晝閸屾氨顔嗛梺绯曞墲椤ㄥ懘鎮楃拠宸唵闁诡垱澹嗙花鍧楁偡?, "闂備胶鍘ч崲鏌ュ疮閸ф鍎嶆い鏍仦椤ュ棝鏌嶈閸撴盯骞夐悧鍫熷闁汇値鍨幏锟犳⒑閼归偊娼愭い顓炵墦瀹曞搫鐣濋崟顒€娈濋柣鐔哥懃鐎氼剟路閸涘瓨鐓犻柛鎰ゴ閸嬫捇鎮㈤搹璇″晪闂佽崵鍋炵粙鎴﹀嫉椤掍礁鍨旈柛顐ｆ礀缁€鍡涙煕閳╁啫濮€闁?, "SYSTEM")
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
		"name": "%s-闂備礁鎲＄敮鎺懳涘┑鍥╊浄妞ゆ牜鍋為埛? % str(fleet.get("name", "闂備礁銈搁弲鏌ュ础閸愬弬?)),
		"ownerId": fleet.get("ownerId", ""),
		"systemId": fleet.get("systemId", ""),
		"mission": fleet.get("mission", "IDLE"),
		"ships": detached
	}
	var fleets: Array = next_state.get("fleets", [])
	fleets.append(new_fleet)
	next_state["fleets"] = fleets
	return add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晝閸屾氨顔嗛梺绯曞墲椤ㄥ懘鎮?, "%s 闁诲骸婀遍…鍫濐嚕閼搁潧鍨旈柛顐ｆ礀缁€鍡涙煕閳╁喚娈旀慨锝咁樀閺岋繝宕掑☉姗嗘濠电偛鐗婇崹鍨暦濮樿泛骞㈡繛鎴烆殔鐎垫煡姊婚崒姘殶闁哥姴妫濋崺鈧? % str(fleet.get("name", "闂備礁銈搁弲鏌ュ础閸愬弬?)), "EVENT")

static func merge_player_fleets(state: Dictionary, system_id: String) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player_fleets: Array = player_fleets_in_system(next_state, system_id, "f_player")
	if player_fleets.size() < 2:
		return add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晝閸屾俺袝闂佸壊鍋呯换鍡欌偓姘懃椤潡骞嗛幍顔剧勘闁?, "闂備礁鎲￠懝鐐附閺冨倻鍗氶柟缁㈠枛閸欏﹪鏌ｉ弮鈧浠嬪礂閸ヮ剚鐓曢柟閭﹀墯閸も偓闂佹悶鍊ф俊鍥ㄧ閹间礁绠ｉ柨鏃€鍨濈划顖炴煟閻斿憡纾绘俊鐐村笧閹噣鏌嗗鍛摋濡炪倖鐗楀銊х不閹烘鐓涢柛灞剧矤閺€浼存煕閳轰胶鐒告慨濠傘偢閹垻鍒掗悷棰佸?, "SYSTEM")
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
		keeper["name"] = "%s濠电偞鍨堕幑渚€顢氳閹便劏绠涘☉娆忔疂婵炲鍘ч悺銊杺" % system_name_by_id(next_state, system_id)
		next_state["fleets"][keeper_index] = keeper
	return add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晝閸屾俺袝闂佸壊鍋呯换鍡欌偓?, "%s 闂備礁鎼€氼噣宕伴幘缁樼劸闁圭虎鍠栫粈鍐煕濞戝崬鐏￠柣锝堜含閳ь剝顫夐悺鏇熴仈閹间礁钃熼柣鏂垮悑閸ゅ霉閻撳海鎽犵悮婵嬫倵閻熺増鍟炵憸鏉垮暣閹箖顢楅崟顐ゎ吅闂佸綊鍋婇崜姘跺磹閵堝棭娈介柣鎰硾閻撴劙鏌￠崱顓犳偧缂佽鲸鎹囧浠嬪Ψ閵忕姳澹? % system_name_by_id(next_state, system_id), "EVENT")

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
		return add_message(next_state, "闁诲海鍋ｉ崐鏍ь渻娴犲鐒垫い鎺戝€稿瓭闂侀潧娲﹂崹褰掑箯?, "闂佽崵濮嶉崘顭戜痪缂備緡鐓堥崰妤冪矙婢跺鍚嬮柛顐ｇ箓閺嬫瑩姊洪幐搴ｂ槈闁哄牜鍓欒灋闁靛牆鎳夐弸鏍煛閸モ晛浠х紒鎲嬬畵濮婃椽顢曢妶鍛咁剚銇勯弴鐔诲妞ゆ洘鐟╅幖褰掑捶椤撶喐鍟ｉ梻?, "SYSTEM")
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
	return add_message(next_state, "闂備礁鎲″缁樻叏閹绢喖鐭楅柛鈩冾殢閸ゅ牊绻涘顔荤按闁稿鎹囬幃鈺冪磼濡偞娲熼弻?, "%s 闁诲海鎳撻幉陇銇愰崘顏咁潟闁瑰鍋為崣蹇涙倵閿濆簼绨界紒鎲嬬畵閹?%s闂? % [target_system.get("name", ""), blueprint.get("name", "")], "SYSTEM")

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
		return add_message(next_state, "闂傚倷绶￠崑鍡樻叏妤ｅ啫鏄ラ悘鐐村劤缁剁偤寮堕崼顐函鐞?, "闂佽崵濮嶉崘顭戜痪缂備緡鐓堥崰妤冪矙婢跺鍚嬮柛顐ｇ箓閺嬫瑩姊洪幐搴ｂ槈闁哄牜鍓欒灋闁靛牆鎳夐弸鏍煛閸モ晛浠х紒鎲嬬畵濮婃椽顢曢妶鍛咁剚銇勯弴鐔峰摵闁硅櫕绮撻獮蹇曚沪閻ｅ苯骞嬮梻?, "SYSTEM")
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
	return add_message(next_state, "闂備礁鎲″缁樻叏閹绢喖鐭楅柛鈩冪⊕閻掑鏌ｅΟ鐑樻儓闁绘挸鍊垮濠氬礃椤忓嫭鐎婚梺?, "%s 闁诲海鎳撻幉陇銇愰崘顏咁潟闁瑰鍋為崣蹇涙倵閿濆簼绨界紒鎲嬬畵濮婃椽顢曢妶鍛咃紕绱掗弮鈧幐鎶藉箠?s闂? % [target_system.get("name", ""), InitialData.ship_labels().get(ship_type, ship_type)], "SYSTEM")

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
		return add_message(next_state, "缂傚倸鍊烽懗鍓佹崲濠靛绠為柕濠忕畱缁剁偤寮堕崼顐函鐞?, "闂佽崵濮嶉崘顭戜痪缂備緡鐓堥崰妤冪矙婢跺鍚嬮柛顐ｇ箓閺嬫瑩姊洪幐搴ｂ槈闁哄牜鍓欒灋闁靛牆鎳夐弸鏍煛閸モ晛浠ч柡鍡樺哺閺岀喓鈧稒锚婵矂鏌涢埡浣虹劯婵﹤銈搁幃銏ゆ倻濡儵鏋欏┑鐑囩到濞村倿宕伴幘璇茬劦?, "SYSTEM")
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
	return add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晜閸撗咃紲缂傚倸鐗忔慨鐢稿矗?, "%s 闁诲海鎳撻幉陇銇愰崘顭掕€?%s 闂佽娴烽幊鎾诲嫉椤掑嫬鍨傛慨妯挎硾閺嬩線鏌℃径瀣劸婵¤尙鏁婚弻銊モ槈濡粯鎷遍梺鍓茬厛閸撶喎顕ｉ鈧灃闁逞屽墯閹便劏绠涘☉妯肩暢闂侀潧绻掓刊顓炍ｆ繝姘厪? % [fleet.get("name", ""), system.get("name", "")], "SYSTEM")

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
		return {"accepted": false, "reason": "闂佽绻愮换鎴犲枈瀹ュ拑鑰挎い鎾卞灩缁犳娊鎮橀悙鏉戝姢缂傚秵鍨块弻锟犲礋椤撶偞鐏堝┑锛勮檸閸ㄥ磭鍒掗崼銉﹀亗閹艰揪绱曢崢顒勬⒑閸涘娈旂紒缁橆殜椤㈡瑩宕ㄧ€涙ɑ娅栭柣蹇曞仧閸嬫捇鏁撻妷锔剧濠㈣泛顑嗙粈鍫㈢磼娓氬灝濡跨紒杈ㄥ浮楠炴鈧稒顭囬崙鑺ヤ繆閵堝懎鈧綊鈥﹂崶顭戞闁搞儺鍓欑痪褔鏌ㄥ☉妯侯仼妞ゆ柨锕弻?}
	if treaty_type == "TRADE_PACT" and trust >= -10:
		return {"accepted": true, "reason": "闂佽绨肩徊濠氾綖婢舵劕钃熼柣鏃傚劋婵ジ鏌曢崼婵嗩伂缂佲偓鐎ｎ剛纾藉ù锝呯墕閹虫劙寮ィ鍐╁仯闁归偊鍓氶崯鐐翠繆閸欏娈曠紒鍌涘笒椤撳ジ宕卞Ο鑲╂殺闂備礁鎲″濠氬疾濞戞嚎浜归柡灞诲劚閻愬﹤菐閸ャ劌顣抽柛?}
	if treaty_type == "NON_AGGRESSION" and trust >= 10:
		return {"accepted": true, "reason": "闂佸搫顦悧蹇涘箠閹炬眹鈧倿濡搁敂缁㈡锤闂佺懓鎼粔宕囨崲閸℃稒鍊堕煫鍥ㄦ婢规鎲搁悧鍫㈠弨闁轰礁绉舵禒锕傛寠婢跺孩鎲伴梻浣告惈閸婁粙锝炴径鎰鐟滅増甯掔粻娑㈢叓閸ャ劍灏柡瀣懅缁辨挻鎷呯憴鍕瀺濡炪倖甯為崰鎾诲箟濡ゅ懎宸濇い鏃囨濞呮岸姊洪悷鏉跨殹閻犳劗鍠栭崺鈧?}
	if treaty_type == "RESEARCH_ACCORD" and trust >= 30:
		return {"accepted": true, "reason": "闂佽绨肩徊濠氾綖婢舵劕钃熼柣鏃傚帶缁犳娊鏌曟径鍫濆姎缂傚秮鍋撻梻浣侯焾缁绘劘銇愭径鎰棅闁冲搫鎳忛崕姗€鏌￠崘銊モ偓鐢稿极閳ь剟姊洪悷鎵憼闁告梹鐗犻幃妯诲緞鐎ｎ兘鏋栭柟鑹版彧缁辨洟寮堕挊澹╂棃鎮╅崣澶嬫嫳闂佸搫妫涢崰鏍嵁閹达富鏁婇悶娑掆偓鍏呭?}
	if treaty_type == "ALLIANCE" and trust >= 65:
		return {"accepted": true, "reason": "闂備礁鎲￠悷銉╁嫉椤掑嫬钃熼柣鏂挎憸椤╂煡鏌熼崫鍕＄紒璇叉閳ь剝顫夐悺鏇犱焊椤忓牆绀冪紓浣姑欢鐐烘煟閺傛寧鍟為柡鍡樼矒閺岀喖鎮欓鈧悘锔姐亜閹烘挾鐭婃い鏇秬缁犳盯骞橀弶鎴斿亾闁秵鐓熼柍鍝勫暙閺嬪倿鏌?}
	return {"accepted": false, "reason": "闁荤喐绮庢晶妤呭箰閸涘﹥娅犻柣妯虹－椤╂煡鏌熼崫鍕＄紒璇叉閳藉骞樺畷鍥嗐儵鏌涢幇顒夌吋闁轰礁绉舵禒锔剧驳鐎ｎ亝顔忛梻浣告惈閸婁粙锝炴径灞稿亾濮橆剚顥犵紒杈ㄥ笒閳规垿宕奸銏犘炵紓鍌氬€搁崯宕囦焊椤忓牜鏁嬫慨妯挎硾缁狙囨煥濞戞ê顏╂い鏂匡躬閺?}

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
					return add_message(next_state, "闁诲海鍋ｉ崐鏍ь渻娴犲鐒垫い鎺戝€稿瓭闂佷紮缍嗛崜鐔肩嵁?, "%s 闁诲海鎳撻幉陇銇愰崘顭掕€?%s 闂佽娴烽幊鎾绘嚐椤栨稑顕遍柟鐗堟緲杩? % [item.get("displayName", ""), system.get("name", "")], "EVENT")
	else:
		var ship_type: String = item.get("targetId", "")
		var ship: Dictionary = create_ship(ship_type, "闂備礁鎼崐瑙勭珶閸℃瑦顫?s" % InitialData.ship_labels().get(ship_type, ship_type), next_state, item.get("ownerId", ""))
		for fleet_index: int in range(next_state["fleets"].size()):
			var fleet: Dictionary = next_state["fleets"][fleet_index]
			if fleet.get("ownerId", "") == item.get("ownerId", "") and fleet.get("systemId", "") == item.get("systemId", ""):
				var ships: Array = fleet.get("ships", [])
				ships.append(ship)
				fleet["ships"] = ships
				next_state["fleets"][fleet_index] = fleet
				return add_message(next_state, "闂備胶鍘ч幉鈩冨垔娴犲鏄ラ柣鎰嚟閳绘棃鎮楅敐搴′簼閻?, "%s 闁诲海鎳撻幉陇銇愰崘顭掕€挎い蹇撶墛閸ゅ鏌ｉ悢鍝勵暭濠殿喗绮撻幃妤呮偡閻楀牊鎷遍梺鎼炲妽绾板秶绮欐径灞稿亾閿濆骸浜濋悗鍨矒閺? % item.get("displayName", ""), "EVENT")
		var fleets: Array = next_state.get("fleets", [])
		fleets.append({"id": "fleet_%s" % str(Time.get_ticks_msec()), "ownerId": item.get("ownerId", ""), "systemId": item.get("systemId", ""), "name": "%s 闂佽娴烽幊鎾绘偋閸℃蛋鍥敆閸曨兘鎸€? % item.get("systemId", ""), "ships": [ship]})
		if not fleets.is_empty():
			fleets[fleets.size() - 1]["mission"] = "IDLE"
		next_state["fleets"] = fleets
		return add_message(next_state, "闂備胶鍘ч幉鈩冨垔娴犲鏄ラ柣鎰嚟閳绘棃鎮楅敐搴′簼閻?, "%s 闁诲海鎳撻幉陇銇愰崘顭掕€挎い蹇撶墛閸ゅ鏌ｉ悢鍝勵暭濠殿喗绮撻幃妤呮偡閻楀牊鎷遍梺鎼炲妽绾板秶绮欐径灞稿亾閿濆骸浜濋悗鍨矒閺? % item.get("displayName", ""), "EVENT")
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
		next_state = add_message(next_state, "闂備礁鎼¨鈧紒杈ㄦ礈閳ь剝顫夋繛濠傜暦濮樿埖鍋嬮柛顐ゅ枎閻?, "%s 闁诲骸婀遍…鍫濐嚕閸洦鏁嗘繝濠傚枤閸ゆ洟鐓崶銊﹀碍闁绘挸鍊块弻锟犲醇閵忕姵鐎梺? % treaty.get("name", "濠电偞鍨堕幐鎾磻閹炬剚娓婚柕鍫濈墱濞兼劖绻涚喊鍗炵仯闁?), "DIPLOMATIC")
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
			high_pressure.append(faction.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т缁€澶愭煕椤垵鏋涙い?))
		if opportunity_score >= 40 and not has_treaty(state, source_faction_id, faction_id, "WAR_STATE"):
			high_opportunity.append(faction.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т缁€澶愭煕椤垵鏋涙い?))
		if bool(trend.get("pressure_rising", false)):
			deteriorating.append(faction.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т缁€澶愭煕椤垵鏋涙い?))
		if bool(trend.get("opportunity_rising", false)):
			improving.append(faction.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т缁€澶愭煕椤垵鏋涙い?))
		if has_treaty(state, source_faction_id, faction_id, "WAR_STATE") or pressure_score >= 55:
			flashpoints.append(faction.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т缁€澶愭煕椤垵鏋涙い?))
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
		"summary": "濠德板€曢崐褰掓晪闁?%s / 闂備礁鎲￠懝楣冩偋閸涱垳绀?%s / 闂備浇顕栭崣鈧繛澶嬬〒閳?%s / 闂備礁鎼悧鎰浖閵娧勵潟濞村吋娼欓悙濠囨煟閹邦厼绲荤痪?%s" % [
			", ".join(high_pressure) if not high_pressure.is_empty() else "闂?,
			", ".join(high_opportunity) if not high_opportunity.is_empty() else "闂?,
			", ".join(deteriorating) if not deteriorating.is_empty() else "闂?,
			", ".join(improving) if not improving.is_empty() else "闂?
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
			return {"title": "闂備礁鎲￠悷锝夊磹閹捐鑸规い鎺戝閻掑吋淇婇妶鍛仾濠?, "content": "濠电偠鎻徊鎸庢叏瀹勬壋鏋旈柟杈剧畱缁€瀣繆椤栨繍鍤欓悹褎鎸冲濠氬礃椤忓嫭鐏嗛悶姘懇閹綊宕堕妸銉т化缂備緡鐓夌换婵嗙暦閿濆围闁告洦鍋呴弳鏇熺箾閿濆懏绀岄柛鎾寸箞閹儵鏁愭径濠冪€梺缁橆殔閻楀棛绮婇敃鍌涚叆婵炴垶顭囬悞閿嬵殽閻愯尙绠版い鏇樺劚铻栭柍褜鍓氱€靛ジ骞囬鐘灃濠殿喗锕╅崑鍡涙偡閵忋垻纾煎璺侯儏閻忊晠鏌ｉ弽銊︺仢闁诡啫鍥х厸闁告洦鍘归崑鎺楁⒑?, "reward": {"food": 0, "minerals": 25, "industry": 40, "energy": 10}}
		"RICH_ASTEROIDS":
			return {"title": "闂佽閰ｅ褔鎯夋總鍛婂亜闁糕剝鐟ら悞濠囩叓閸ャ劌鍤柡鈧禒瀣厸闁告洦鍘奸弸鏃堟煕?, "content": "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晝閸屾艾鍞ㄩ梺鎼炲労娴滃爼宕捄濂界懓顭ㄩ崘鈺婃＆闂佺粯绻嶉崰妤冪矉閹烘垹鏆嬮柟闈涘暱娴滈箖鏌ゅù瀣珖闁哥偟鏁婚弻銈夊级閹搭厽顎嗙紓浣介哺缁诲牆鐣烽妷锔藉劅闁炽儱纾ぐ楣冩⒒娓氬洤鏋旈柛鏃€鍨佃灋妞ゆ帒瀚悙濠囨煟閹邦剛鎽犻柡鍡╀簻闇夋繝濠傚暞椤ユ粓鏌曢崶褎鍠橀柡灞界焷缁犳盯寮撮悩鍙夋毄濠电偛鐡ㄧ猾鍌炲磼濠婂懏鍠涢梻浣哄帶閻ゅ洦鎱ㄩ妶鍥С妞ゆ洍鍋撳┑?, "reward": {"food": 0, "minerals": 50, "industry": 0, "energy": 20}}
		"SOLAR_STORM":
			return {"title": "闂備浇顕栭崢鐣屾暜濡も偓鍗遍柨鏃傜摂濡插綊骞栧ǎ顒€鐏柣?, "content": "濠电偠鎻徊鎸庢叏閺夋埊鑰挎い蹇撴媼濡插綊骞栧ǎ顒€鐏柣锕€缍婂鍫曞醇濠靛洩纭€缂備線纭搁崢濂割敋濞嗘挻鎯為柛锔诲幖缂嶅嫭绻涚€涙鐭婃俊顐ｆ⒐瀵板嫬顓兼径濠勭潉闂佸壊鍋呭ú鏍р枍濮樿埖鐓犻柛蹇撴噽閻瑦淇婇妤€浜鹃梻浣告啞鐢銆冮幇顔筋潟婵犻潧顑嗛崵鏃傗偓鐟板婢瑰棛鎹㈡担鑲濇盯鎮ч崼銏㈢暤濡炪倧绠戦…鐑藉箠濡ゅ懏鍤嶉柕澹懎鐓冮梻浣侯焾鐞氼偊宕濆畝鍕婂洭顢楅崟顐?, "reward": {"food": 0, "minerals": 0, "industry": 10, "energy": 45}}
		"PIRATE_RAID":
			return {"title": "婵犵數鍋為幐鎶剿夐幘瓒佸搫顓奸崶銊ヤ粡濡炪倖鎸鹃崰搴ㄋ?, "content": "闂備胶顢婄紙浼村磹濞戙垹鏄ラ柛娑樼摠閸ゅ霉閻撳海鎽犵悮婵嬫⒑閸涘﹤鐏ユい顓犲厴閸┾偓妞ゆ垼妫勬禍鐐箾鐎涙鐭婃俊顐ｇ矒閿濈偤濡搁埡浣侯吋闂佺懓鍢叉径鍥磻閹捐妞介柛鎰典簽椤︻喗绻涙潏鍓у埌婵☆偅顨婇獮鍐ㄎ旈崨顓狀槹闂侀潧鐗嗗ú銈呪枔閻樺眰鈧帒顫濋鐘电暭闂佸憡鏋崶銊у姸濡炪倖鎸鹃崑娑氱礊閳ь剟姊洪悷鐗堣础闁哥姴閰ｆ俊鐢稿箣閿曗偓杩?, "reward": {"food": -8, "minerals": -12, "industry": 0, "energy": -18}}
		"WARP_STORM":
			return {"title": "闂佽崵濮撮幖顐﹀疮瀹曞洨绱﹂柛蹇曗拡濡插綊骞栧ǎ顒€鐏柣?, "content": "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晝閸屾碍宓嶉梺闈浥堥弲鈺佄涢幋锔界厸闁糕剝鐟Λ搴ｇ磼閺冨倸鏋旂紒杈ㄦ尭椤粓鍩€椤掑嫬闂ù鐓庣摠閳锋牠鏌涢埄鍐炬當闁绘挸鍊搁埥澶愬箻瀹曞泦銈夋嚕濞嗘挻鍊甸悷娆忓娴溿垻绱掑畝濠傚婵炶偐绮幏鍛喆閸曨剦鍟€闂備胶顢婇鏍闯椤栨粍顫曟繝闈涙处婵挳鏌涢埄鍐闁绘帒顭峰娲敆娴ｇ懓鏆楅柤鎸庣懇閹鎲撮崟顓ф殹闂侀€炲苯鍔柛灞剧矌閹差噣姊婚崒姘仼缂佸鐓￠崺鈧?, "reward": {"food": 0, "minerals": 0, "industry": 8, "energy": -10}}
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
		system["note"] = "%s 闂備礁鎲″ú妯挎懌闁汇埄鍨辨竟鍡涘焵椤掑倹鍤€闁哄牜鍓熷畷鐟邦潩鐠轰綍? % system.get("note", "")
		next_state["starSystems"][system_index] = system
		for faction_index: int in range(next_state["factions"].size()):
			var faction: Dictionary = next_state["factions"][faction_index]
			if faction.get("id", "") == player.get("id", ""):
				faction["resources"] = add_resources(faction.get("resources", {}), reward_data.get("reward", {}))
				next_state["factions"][faction_index] = faction
		return add_message(next_state, reward_data.get("title", ""), "%s闂?s" % [system.get("name", ""), reward_data.get("content", "")], "EVENT")
	return next_state

static func trigger_narrative_event(state: Dictionary, event_template_id: String, target_system_id: String, affected_factions: Array = [], narrative_override: String = "", outcome_modifiers: Dictionary = {}) -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var event_type: String = "ANCIENT_RUINS"
	var default_note: String = "闂佸搫顦悧蹇涘箠閹炬眹鈧倿濡搁敃鈧閬嶆煟濡搫鏆卞┑鈩冨▕閺屾盯鏁愰崘銊ヮ瀴閻庤娲滈崰鏍嵁閹寸偛绶炲┑鐘插€婚崢鎺楁⒑閸濆嫬鈧绔熼崱妞绘灁闁瑰瓨绻嶉崵鏇㈡煕鐏炵偓鐨戦柛鈺傤殔鑿愰柛銉岛閸嬫捇宕橀幓鎺嗘瀼闂?
	var follow_up_options: Array = ["闂佽崵濮撮鍛村疮椤栫偞鍋?, "闁诲孩顔栭崰鎺楀磻閹剧粯鐓?, "闂佽绻愮换瀣濮樿泛缁?]
	match event_template_id:
		"ANCIENT_RUINS_DISCOVERY":
			event_type = "ANCIENT_RUINS"
			default_note = "闂備礁鎲￠悷锕傚垂瑜版帞宓侀柛銉ｅ妽娴溿倖绻濇繝鍌氭殭缂傚秵妫冨娲敆娓氬洦鐣介梺纭呭煐椤ㄥ棛绮氶柆宥呯伋闁告劖褰冮埢蹇涙⒑閹稿海鈽夐柤娲诲灣缁辨捇骞橀懜闈涱€涘銈嗘婵倝鎮滈敃鍌涒拺妞ゆ帒锕︾粔顒勬煕閳轰胶鐒告慨濠傘偢閹垹鐣￠幍顔肩秹闂備線鈧稖顒熸繛鐓庢健閸┾偓?
			follow_up_options = ["闂佽崵濮撮鍛村疮椤栫偞鍋傞柨鐔哄У閻掑吋淇婇妶鍛仾濠?, "闂備焦鎮堕崕鎶藉磻閻愬搫鏋侀柛锔诲幘閻捇鏌熺€电浠滈摶?, "闂備礁鎲￠崝鏍矙閹邦喛濮抽柕濞у倻鍓ㄦ繛鎾村焹閸嬫捇鏌￠埀?]
		"PIRATE_RAID":
			event_type = "PIRATE_RAID"
			default_note = "婵犵數鍋為幐鎶剿夐幘瓒佸搫顓奸崥銈堟閹风娀骞撻幑顐ｎ殕閹便劌鈹戦幘璺哄煂濠电姭鍋撴い蹇撶墕绾偓闂佹悶鍎崝瀣礆婵犲洦鐓ユ繛鎴烆焾鐎氫即鏌ｉ宥呭⒋闁哄苯鐗撴俊鎼佸Ω鐎ｎ亶妲虹紒杈ㄥ笒閳诲酣骞嬪┑鍥╂瀮闂備礁缍婂褔鎮樺┑鍫熸殰闁搞儺鍓欒繚?
			follow_up_options = ["婵犵數鍋涘璺虹暦濮椻偓瀹曡櫣浠︽慨鎰ㄥ亾閹烘宸濇い鎾跺剱濡?, "闂備礁鎲″缁樻叏閺夋埈鍟呴梺顒€绉寸粻顕€鏌曢崼婵堝闁?, "闂備礁鎼Λ妤呭磹閻熼偊娓婚柛灞剧矋閸犲棝鏌涢弴銊ョ仧缂?]
		"WARP_STORM":
			event_type = "WARP_STORM"
			default_note = "闂佽崵濮撮幖顐﹀疮瀹曞洨绱﹂柛蹇曗拡濡插綊骞栧ǎ顒€鐏柣锕€缍婇弻鐔煎垂椤愶絿鍑℃繝娈垮枓閺呯娀骞婂鍫晜闁割偅绮岄ˉ姘舵⒑閹稿海鈽夐柣顒€銈搁幃锟狀敇閵忕姴鐝橀梺缁樻煥閸㈡煡寮崼鏇熷€垫繛鎴烆仾椤忓嫸鑰挎い蹇撶墕鐎氬鏌涘┑鍡楊仼鐞氱喐淇婇悙宸剰闂佸府绲介埢宥夊箻鐠囧弬?
			follow_up_options = ["缂傚倷绀侀ˇ浼村垂閻㈠壊鏁嗛柣鏃傚劋閸犲棝鏌涚仦鍓с€掗柕?, "闂備胶顭堢换鎴炵箾婵犲伣娑㈠箻椤旇棄娈濆銈呯箰閻楀懏绔?, "闂備礁鎲￠崝鏍暜閳ユ枼鏋嶉柟鎯у閻岸鏌ら幇浣哥仯濡?]
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
	var suffix: String = "" if affected_names.is_empty() else " 闂備礁鎲￠悷锕傘€冮崨顔鹃檮闁哄稁鍘兼导鐘碘偓骞垮劚閹冲酣鍩ｉ姀銈嗙厱? %s闂? % ", ".join(affected_names)
	return add_message(next_state, "闂佽閰ｅ褔宕ョ€ｎ剚顫曢柕濠忓椤╂煡鎮楅敐鍌涙珕妞?, "%s%s" % [default_note if narrative_override == "" else narrative_override, suffix], "EVENT")

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
					return trigger_narrative_event(next_state, "PIRATE_RAID", system.get("id", ""), ["f_player"], "婵犵數鍋為幐鎶剿夐幘瓒佸搫顓奸崶鈺冾槰闂侀潧鐗嗛幊鎰鐠囨祴鏀芥い鏃傗拡閸庢挻銇勯鐘插妤犵偛绉归獮蹇撶暆閳ь剟鎮电捄渚唵鐟滃秹宕幎钘夋槬闁告稑鐡ㄩ悞濂告煙閻愵剙顣抽柛?, {"threat_scale": intensity})
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
			return add_message(next_state, "闂佽閰ｅ褔宕ョ€ｎ剚顫曢柕濞炬櫇瀹撲線鏌＄仦璇插姶闁?, "濠电姰鍨奸崺鏍儗椤曗偓閺?AI 闂備礁鎲￠弻銊╂倶濠靛洦鍙忛煫鍥ㄧ☉閹瑰爼鏌曟繛鍨姢妞ゆ柨閰ｉ弻娑橆潩椤掍礁鏀Δ鐘靛仜缁绘劙顢氶妷銉富闁告挆鍐╂珦濠碘槅鍋嗘晶妤冩崲閸岀倛鍥ㄧ節濮橆厼鍓梺鍛婃处閸撴瑩鎮樺☉姗嗙唵閻犺櫣鍎ゆ径鍕煛娓氬洤娅嶆鐐存尰濞煎繘宕滆椤︻喗淇婇锝嗙凡閻庢凹鍨堕、姗€骞栨担鍝ヮ唶婵炶揪缍€濞咃綁寮?%s 闂備焦鎮堕崕鎶藉磻濞戙垹绠栭幖娣妼杩? % str(duration), "EVENT")
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
			return add_message(next_state, "闂佽閰ｅ褔宕ョ€ｎ剚顫曢柕濞炬櫇瀹撲線鏌＄仦璇插姶闁?, "闂佹眹鍩勯崹杈╂崲閸屾鐟拔旈崨顓⌒曢柟鑲╄ˉ閳ь剙纾ぐ楣冩⒒娓氣偓缁犳牜绮婚弽銊ヮ嚤闁告劦鍠楅悞濂告煕閵夘垰顩柛鐔凤躬閺岋綁顢樿楠炴淇婇悙鎻掆偓鍧楃嵁瀹ュ绾ч柛顭戝暕濡ゅ懏鐓ユ繛鎴烆焽閻掗绱掓笟鍥т簻闁崇懓鍟撮獮鍥敆閳ь剚绂嶇捄渚唵閻犺櫣鍎ら幖鎰版煕閵堝骸寮柟顔藉▕閹囧醇濠靛牊顕涢梻浣告啞閺岋綁宕濇繝鍥х劦?, "EVENT")
		"TRIGGER_CRISIS":
			for system: Dictionary in next_state.get("starSystems", []):
				if system.get("ownerId", null) == "f_player":
					return trigger_narrative_event(next_state, "WARP_STORM", system.get("id", ""), ["f_player"], "闂備礁鎲￠悧鏇㈠箹椤愶附鍋傛繛鍡樺灩濡垳鎲稿鍛殼闁告洦鍨扮€氬鏌ｉ幋鐑囦緵闁告柡鍋撻梻渚€娼荤拹鐔煎礉瀹ュ鍨傛慨妯煎仺娴滆銇勯顐㈡灓缂佲偓婢舵劖鍋ｉ柛婵嗗閺嗐垻绱掗崫鍕倯妞わ妇澧楅幆鏃堝閿涘嫭鈻屾繝鐢靛仜椤︻參宕归悷閭﹀殨濡炲瀛╅弳婊勭節闂堟稒顥炵紒鍌氭喘閺岋綁濡堕崨顕呮闂佺粯鎸婚悷鈺備繆?, {"storm_scale": intensity})
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
		"闂佽崵濮撮鍛村疮椤栫偞鍋傞柨鐔哄У閻掑吋淇婇妶鍛仾濠?, "缂傚倷绀侀ˇ浼村垂閻㈠壊鏁嗛柣鏃傚劋閸犲棝鏌涚仦鍓с€掗柕?:
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
			next_state = add_diplomatic_memory(next_state, "闂佽瀛╅崘濠氭⒔閸曨偓鑰块柧蹇ｅ亜缁剁偤鏌涢弴銊ュ箻闁?, "%s 闂備焦鐪归崝宀€鈧凹鍓涘Σ鎰板箻閼稿灚娈伴梻鍌楀亾闁归偊鍠氬▓銈嗙箾鐎电校闁稿骸銈搁敐鐐烘晝閸屾稑浠洪梺闈涱焾閸婃鎳濋崜褏纾煎璺侯儏閻忊晠鏌ｉ弽顒侇仩闁瑰弶鎸冲畷鎺戔槈濮樸儱浠﹂梻浣瑰缁嬫垿鎳熼婊呯當闁挎繂顦悙濠囨煠閹帒鍔滄繛鍫ｎ嚙闇夐柨婵嗘鐏忕増绻涢幓鎺撳仴鐎规洘鍨肩粻娑㈠箻閺夋垟鍋撴繝姘厽闁绘劕寮堕ˉ鐐烘煃瑜滈崕鎼佸礃閻愵儷鐔兼⒑閼姐倕浠滄俊顐ｎ殔閻ｇ敻宕熼姘彉闂佽鍘藉濠氬磻? % system_name, ["f_player"], "EVENT", 2)
		"闂備焦鎮堕崕鎶藉磻閻愬搫鏋侀柛锔诲幘閻捇鏌熺€电浠滈摶?, "闂備礁鎲″缁樻叏閺夋埈鍟呴梺顒€绉寸粻顕€鏌曢崼婵堝闁?, "闂備胶顭堢换鎴炵箾婵犲伣娑㈠箻椤旇棄娈濆銈呯箰閻楀懏绔?:
			for system_index: int in range(next_state.get("starSystems", []).size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") != system_id:
					continue
				system["stability"] = min(100, int(system.get("stability", 60)) + 8)
				system["supplyLevel"] = min(100, int(system.get("supplyLevel", 60)) + 10)
				system["eventResolved"] = true
				next_state["starSystems"][system_index] = system
				break
			if option_label == "闂備礁鎲″缁樻叏閺夋埈鍟呴梺顒€绉寸粻顕€鏌曢崼婵堝闁?:
				for index: int in range(next_state.get("relationships", []).size()):
					var relation: Dictionary = next_state["relationships"][index]
					var touches_merchant: bool = (relation.get("factionAId", "") == "f_player" and relation.get("factionBId", "") == "f_merchant") or (relation.get("factionAId", "") == "f_merchant" and relation.get("factionBId", "") == "f_player")
					if not touches_merchant:
						continue
					relation["trust"] = clamp(int(relation.get("trust", 0)) + 4, -100, 100)
					relation["utility"] = int(relation.get("utility", 0)) + 4
					relation["level"] = relation_level(int(relation.get("trust", 0)))
					next_state["relationships"][index] = relation
				next_state = update_diplomatic_profile(next_state, "f_merchant", "friendly", 3, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦粻娑㈡煙缁嬪潡顎楀鐟扮墦閺岀喖鎳滈崹顐ゎ槬闂佸憡鐟ュΛ婵嗙暦濠靛棌妲堥柕蹇曞У椤忊剝绻涢敐鍛缂佽鍟幈銊╁閳╁啰绉堕梺鑽ゅ枛閸嬪﹪寮抽弮鍫熺厱闁绘棃鏀遍ˉ锟犳煟椤撱垻鐣洪柡浣哥Ф娴狅妇鎲撮敐鍛闂佺粯鎸稿ù椋庢崲娴ｈ櫣纾藉ù锝呯墕閹虫劙寮ィ鍐╃厱婵﹩鍓涙晶鏃傜磽瀹ュ棙顥堝┑?)
				next_state = add_diplomatic_memory(next_state, "闂備浇澹堟ご鎼佸蓟閵娾晛绠栭幖娣妼缁狀噣鏌曢崼婵堝闁?, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦幑?%s 闂備礁鎲＄粙蹇涘礉韫囨洜鍗氶柣鏃傚帶缁€澶愭煟濡绲荤紒璁崇窔閺岀喖鐓幓鎺嗗亾濞戙垹鏄ラ柛娑樼摠閺咁剟鎮橀悙璺盒撴繛鍛焸閹綊骞囬鐐殿槰婵炲濮撮悧鎾诲箚閸曨垱鍋勫┑鍌氼槸濞堟悂姊洪崨濠呭闁绘鎳愮槐鐐哄籍閸繄鐤€闂婎偄娲﹂弻銊︽叏閽樺妲堥柟鍓ь劜瀹搞儳鈧娲栭惌鍌涗繆? % system_name, ["f_player", "f_merchant"], "AGREEMENT", 2)
		"闂備礁鎲￠崝鏍矙閹邦喛濮抽柕濞у倻鍓ㄦ繛鎾村焹閸嬫捇鏌￠埀?, "婵犵數鍋涘璺虹暦濮椻偓瀹曡櫣浠︽慨鎰ㄥ亾閹烘宸濇い鎾跺剱濡?, "闂備礁鎲￠崝鏍暜閳ユ枼鏋嶉柟鎯у閻岸鏌ら幇浣哥仯濡?:
			for system_index: int in range(next_state.get("starSystems", []).size()):
				var system: Dictionary = next_state["starSystems"][system_index]
				if system.get("id", "") != system_id:
					continue
				system["stability"] = max(25, int(system.get("stability", 60)) - 4)
				system["eventResolved"] = true
				next_state["starSystems"][system_index] = system
				break
			if option_label == "婵犵數鍋涘璺虹暦濮椻偓瀹曡櫣浠︽慨鎰ㄥ亾閹烘宸濇い鎾跺剱濡?:
				for fleet_index: int in range(next_state.get("fleets", []).size()):
					var fleet: Dictionary = next_state["fleets"][fleet_index]
					if fleet.get("ownerId", "") != "f_player":
						continue
					if fleet.get("systemId", "") != system_id:
						continue
					next_state["fleets"][fleet_index] = damage_fleet(fleet, 10)
					break
				next_state = update_diplomatic_profile(next_state, "f_merchant", "firm", 1, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱妫涢埢鏃堟偣閸ャ劌绲荤悮鐔封攽閻愬瓨灏柟铏姍楠炲啯绻濋崑顖濐潐椤︾増鎯旈姀顫穿闂備焦瀵х粙鎴︽儗娓氣偓椤㈡岸鍩￠崨顓炲挤闁硅偐琛ラ埀顒€鍟跨欢顓熺箾鐎电孝缂佸娼欓敃銏ゎ敂閸℃瑧锛滈柣搴㈢⊕閿氱悮姗€鏌℃径濠勫ⅱ闁硅櫕鎹囬妴鍌炲Ω瑜忛惌鎾绘煃鏉炴媽鍏岀痪鏉跨Ч閺?)
				next_state = add_diplomatic_memory(next_state, "婵犵數鍋為幐鎼佸箠鎼淬垻鐝舵繛鍡楃贩鐟欏嫷妲归幖娣灮閿?, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦幑?%s 闂備礁鎲￠悷锕傚垂婵傜绠查柨婵嗘噷閳ь剚甯″畷銊╊敇閻戝棙锛侀梺鑽ゅ仦缁嬫垿鎳熼娑欏弿闁冲搫鎳忛弲顒傗偓鍏夊亾闁告劏鏅╂禒閬嶆⒑閸濆嫮澧曟い锔垮嵆瀹曞綊顢楅崟顐ゎ唹闂佺粯鏌ㄦ晶搴ｇ矙閼姐倗纾奸悗锝庝簻閺嗛亶鏌ｉ敐鍥т壕缂佸倸绉瑰畷鍗炍旈崘鈺傚闂備礁鎲″Λ渚€鏁撻妷鈺佺劦? % system_name, ["f_player", "f_merchant"], "EVENT", 3)
			elif option_label == "闂備礁鎲￠崝鏍暜閳ユ枼鏋嶉柟鎯у閻岸鏌ら幇浣哥仯濡?:
				for index: int in range(next_state.get("factions", []).size()):
					var faction: Dictionary = next_state["factions"][index]
					if not faction.get("isPlayer", false):
						continue
					var resources: Dictionary = faction.get("resources", {}).duplicate(true)
					resources["energy"] = max(0, int(resources.get("energy", 0)) - 16)
					resources["industry"] = int(resources.get("industry", 0)) + 16
					faction["resources"] = resources
					next_state["factions"][index] = faction
				next_state = add_diplomatic_memory(next_state, "闂備礁鎲￠崝鏍暜閳ユ枼鏋嶉柟鎯у閻岸鏌ら幇浣哥仯濡?, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱鎷嬮崵鏇炍旈敂绛嬪劌闁衡偓閻ｅ瞼纾肩€光偓閸愩劌濮风紓?%s 闂備焦鐪归崝宀€鈧凹鍓涘Σ鎰板箻閼稿灚娈板┑顔界箓閼活垶鎮炴繝姘拺妞ゆ帊鐒﹂幆鍫㈢磼鏉堛劎绠橀柡渚囧枛閳规垿宕卞Ο纰辨喘濠碉紕鍋涢鍛偓娑掓櫊閹囧箹娴ｅ摜鐓戝┑鈽嗗灥濞咃絿鎹㈡笟鈧弻锟犲炊閵婏妇绋囨繝娈垮枤閸嬨倕鐣峰鈧獮鎺懳旀担鍝勭稐闂? % system_name, ["f_player"], "EVENT", 2)
		"闁诲孩顔栭崰鎺楀磻閹剧粯鐓?, "闂備礁鎼Λ妤呭磹閻熼偊娓婚柛灞剧矋閸犲棝鏌涢弴銊ョ仧缂?, "闂佽绻愮换瀣濮樿泛缁?:
			next_state = resolve_player_system_event(next_state, system_id)
			if option_label == "闂備礁鎼Λ妤呭磹閻熼偊娓婚柛灞剧矋閸犲棝鏌涢弴銊ョ仧缂?:
				for system_index: int in range(next_state.get("starSystems", []).size()):
					var system: Dictionary = next_state["starSystems"][system_index]
					if system.get("id", "") != system_id:
						continue
					system["supplyLevel"] = max(35, int(system.get("supplyLevel", 60)) - 6)
					system["eventResolved"] = true
					next_state["starSystems"][system_index] = system
					break
				next_state = update_diplomatic_profile(next_state, "f_orchid", "neutral", -1, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦幑鍫曟煏婵炲灝鍔氱紒渚囧亰閺岋繝宕奸敐鍡愨偓鍐煠閸偄鐏撮柡灞芥噺瀵板嫮鈧綆浜舵禒鎾煟閻斿摜鎳冮悗姘卞鐎靛ジ鍩￠崨顔芥珫閻庡厜鍋撻柛鎰劤濞堫垶姊洪崫鍕仼濡ょ姵鎮傚畷锝夊箲閹扳晙姹楅梺瑙勫劤閸熷潡路閸涘瓨鐓涢柛銉戝懏鎲奸梺杞拌兌閸嬨倝寮荤仦绛嬪悑闁告洦鍘鹃鏃堟煟鎼淬垻鈯曢柨姘舵煟閵堝懎顏€规洘绻傞埥澶愬冀閵堝懍澹?)
				next_state = add_diplomatic_memory(next_state, "闂備礁鎼Λ妤呭磹閹稿骸顕遍柍鍝勬噺閻撱儵鎮楅敐搴″箹妞?, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦伴悞璇差熆鐠轰警鍎忔い蹇嬪劤缁辨挻鎷呯憴鍕槬缂?%s 闂備焦鐪归崝宀€鈧矮鍗宠棢闁瑰墽绮埛鏃堟煃鏉炴壆鍔嶉柛鏇㈢畺閹粙顢涢妶鍫悈缂備浇椴哥换鍐嚗閸曨垰鍐€闁挎棁妫勯弨顓熺節濞堝灝鏋熼悗绗涘洤鐒垫い鎴ｆ硶閸斿秵绻涢懠鑸电《闁圭厧澧介埀顒婄秵閸樻儳鈻撻妶澶嬬厵闁告鍋熼弰鍌炴煃? % system_name, ["f_player", "f_orchid"], "EVENT", 1)
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
			event_item["title"] = "%s-濠电偛鐡ㄧ划宀勵敄閸曨偀鏋庨柕蹇嬪€栭悡?s" % [str(event_item.get("title", "濠电偛鐡ㄧ划宀勵敄閸曨偀鏋?)), str(event_item.get("chainStage", 2))]
			next_state["activeNarrativeEvents"][event_index] = event_item
			break
	next_state = add_message(next_state, "濠电偛鐡ㄧ划宀勵敄閸曨偀鏋庨柕蹇嬪€曠粻顔碱熆鐠轰警鍎忔い?, "%s 闂備焦鐪归崝宀€鈧凹浜為懞閬嶅Ω閿旂虎娴勯柣鐘叉惈閹碱偊宕甸幒妤佺厵缂佸顑欏Σ鎾煃?s闂備胶鍋ㄩ崕鑼崲閸岀倛鍥煛閸涱喖浠╅梺绯曞墲閸斿繘宕? % [system_name, option_label], "EVENT")
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
			if option_label == "闂佽崵濮撮鍛村疮椤栫偞鍋傞柨鐔哄У閻掑吋淇婇妶鍛仾濠?:
				return {
					"eventTemplateId": "ANCIENT_RUINS_DISCOVERY",
					"narrative": "闂傚倷绶￠崜姘躲€冩径鎰婵°倐鍋撻懣鎰版煕濡ゅ啫鍓辨俊鏌ヤ憾閺屾稑鈻庤箛鏇烆暫闂佹悶鍊ら崣鍐箖閾忣偓绱ｅù锝呮惈閺呪晝绱撴担璇℃闁稿繑绋撻懞閬嶅煛閸愌勫媰闂佺鏈銊ノｉ弴銏″€堕煫鍥у缁佷即鏌涢埡浣盒ч柡浣哥Ф娴狅箓鎮欓顐畵閺屾稑顫濋幆褜娲梺瑙勬尦椤ユ挾妲愰幒妤婃晣闁绘棁娅ｉ悾鎶芥⒑缁嬭法绠為柛搴ょ簿閵囨劙宕掗悙鑼唺濠殿喗顨呴悧蹇涘触?,
					"options": ["缂傚倷绀侀ˇ浼村垂閻㈠壊鏁嗛柣鏃傚劋閸犲棝鏌涚仦鍓с€掗柕?, "闂備焦鎮堕崕鎶藉磻閻愬搫鏋侀柛锔诲幘閻捇鏌熺€电浠滈摶?, "闂備礁鎲￠崝鏍矙閹邦喛濮抽柕濞у倻鍓ㄦ繛鎾村焹閸嬫捇鏌￠埀?],
					"chainStage": 2
				}
		"PIRATE_RAID":
			if option_label == "婵犵數鍋涘璺虹暦濮椻偓瀹曡櫣浠︽慨鎰ㄥ亾閹烘宸濇い鎾跺剱濡?:
				return {
					"eventTemplateId": "PIRATE_RAID",
					"narrative": "婵犵數鍋為幐鎶剿夐幘瓒佸搫顓奸崱娆屾灃闁荤姴娲﹁ぐ鍐綖閺冨倵鍋撶憴鍕憙閻忓繑鐟ч崚鎺楀灳閺傘儲鏁犻梺鍛婂姀閺呮粌鈻撻悩缁樼叆婵炴垶锚椤ㄦ瑧绱掗幓鎺戔挃闁诡喕鍗虫俊鐤槾闁肩澧庣槐鎺楀箚瑜忔禒銏ゆ煙閸愬弶顥炴繛鐓庣箻閺屽懎鈽夊杈╁幊闂備礁鎼悧鍡浰囨导瀛樺仼妞ゆ劧绲炬刊瀛樼箾閸℃ê淇繛鐓庣秺閺岀喖鎮介崜鍙夋婵烇絽娲ら敃顏勭暦閿濆鍑犳い鎰枎娴?,
					"options": ["闂備礁鎲″缁樻叏閺夋埈鍟呴梺顒€绉寸粻顕€鏌曢崼婵堝闁?, "闂備胶顭堢换鎴炵箾婵犲伣娑㈠箻椤旇棄娈濆銈呯箰閻楀懏绔?, "闂備礁鎲￠崝鏍暜閳ユ枼鏋嶉柟鎯у閻岸鏌ら幇浣哥仯濡?],
					"chainStage": 2
				}
		"WARP_STORM":
			if option_label == "缂傚倷绀侀ˇ浼村垂閻㈠壊鏁嗛柣鏃傚劋閸犲棝鏌涚仦鍓с€掗柕?:
				return {
					"eventTemplateId": "WARP_STORM",
					"narrative": "闂佽崵鍠愰悷銉╁磹閸︻厾鐭堥柟缁㈠枛閺嬩線鏌ｅΔ鈧悧鍡欑矈閿曞倹鐓欐繛鑼额嚙楠炴﹢鏌曢崶銊ь暡缂佸倸绉瑰畷鍗炍熼懡銈呭毐婵犵數鍎戠徊钘夌暦椤掑嫭鍎戝ù鐓庣摠閸庡秹鏌涢弴銊ュ闁哄鍊归幈銊ф喆閸曨偄顫嶆繝銏㈡嚀閻楁挸鐣峰┑瀣р偓锕傚箳閺冨偆妲烽梻浣告惈鐎氱兘宕规导鏉戠畾濞达綀娅ｇ壕鑲╂喐韫囨稒鍋ㄧ紓浣姑欢鐐烘煕閺囥劌骞楅柛濠勫仧閳ь剚顔栭崰鏍磹閹间焦鍋夐柛顐ｆ礃閸ゅ銇勮箛鎾跺濠㈣娲熼弻?,
					"options": ["闂備胶顭堢换鎴炵箾婵犲伣娑㈠箻椤旇棄娈濆銈呯箰閻楀懏绔?, "闂備礁鎲￠崝鏍暜閳ユ枼鏋嶉柟鎯у閻岸鏌ら幇浣哥仯濡?, "闂佽崵濮撮鍛村疮椤栫偞鍋傞柨鐔哄У閻掑吋淇婇妶鍛仾濠?],
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
			return add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ュ┑鐘灪閸庤偐鍒掗崜褎鍠?, "闂備礁鎼悧婊勭濠靛洨鐝舵慨妞诲亾鐎规洘宀搁獮宥夘敊閻ｅ瞼宕堕梻浣告惈缁夋潙煤閳哄懎鏄ョ€光偓閸曨兘鎸€闂佺粯姊荤悰銉╁磻?, "SYSTEM")
		defender = next_state["fleets"][defender_index]
	else:
		return add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ュ┑鐘灪閸庤偐鍒掗崜褎鍠?, "闁荤喐绮庢晶妤呭箰閸涘﹥娅犻柣妯肩帛閸嬪鏌涢銈呮瀾闁瑰嘲宕湁闁绘ê寮堕崳娲煛娓氬洤娅嶆鐐村姈閹峰懘鎸婃径灞藉笓闂傚倸鍊搁崯浼村窗閹捐秮鐑樺閺夋垵鍞ㄩ梺鎼炲劘閸庮噣宕?, "SYSTEM")
	if defender.get("ownerId", "") == attacker_owner:
		return add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ュ┑鐘灪閸庤偐鍒掗崜褎鍠?, "闂備礁鎼崯鐗堟叏閻㈠灚鍏滈柛鎾茶閸嬫捇鎮介崹顐㈡畬缂備浇顔婄欢姘嚕椤掑倹鍏滈柛娑卞幘閸樻帡姊婚崒姘殶闁哥姴姘﹂妵鎰板磼濠婂嫬鐨梻浣哥仢椤戝懘鎮樺☉銏＄厸闁稿本绋忔禒鐘绘煃?, "SYSTEM")
	if not has_treaty(next_state, attacker_owner, defender.get("ownerId", ""), "WAR_STATE"):
		next_state = declare_war_on_faction(next_state, attacker_owner, defender.get("ownerId", ""))
		attacker_index = find_fleet_index(next_state, attacker_fleet_id)
		defender_index = find_fleet_index(next_state, target_id)
		attacker = next_state["fleets"][attacker_index]
		defender = next_state["fleets"][defender_index]
	var attacker_modifier: float = 1.0
	var defender_modifier: float = 1.0
	var notes: Array = ["濠电偛鐡ㄩ崵搴ㄥ磹閺嶎厼鍨傛い鎺戝€归崰鍡涙煕閺囥劌浜滈柣? %s" % engagement_rules, "闂傚倸鍊搁崯鏉戭焽瑜旈幃? %s" % formation, "闂備胶鎳撻悺銊ㄦ懌濠电姭鍋撻柟鎯版绾偓? %s" % tactic_card]
	var attacker_damage_taken: int = 22
	var defender_damage_taken: int = 14
	var rounds: int = 3
	var system_id: String = str(defender.get("systemId", ""))
	var defense_power: int = system_defense_power(next_state, system_id, defender.get("ownerId", ""))
	if engagement_rules == "HIT_AND_RUN":
		attacker_modifier *= 0.88
		notes.append("濠德板€曢崐褰掓晝閵忋倕鐒垫い鎺戝€搁弸鏃堟煟濞戞﹫韬€规洘鐟︾换婵嗩潩椤撗€鍋撻弽顬″綊鏁愰崨顓у妷濡炪倖甯楃划鎾澄涢崘顔碱潊闁宠棄妫楁慨锕傛⒑鐠囧弶绂嬮柛妯圭矙瀵煡濡烽埡鍌氫虎闂佹悶鍎甸ˉ鎾剁矆婢跺⊕褰掓晲閸涱噮妫涚紓浣虹帛瀹€鎼佸箖閹€鏋庨柟閭﹀幘閸戣姤绻濋姀锝呯厫缁炬澘绉归獮鎰枎閹惧鍔甸梺閫炲苯澧扮紒顔借壘鐓ゆい蹇撴嫅缁辩敻姊?)
		attacker_damage_taken = 12
		defender_damage_taken = 10
	elif engagement_rules == "ALL_OUT":
		attacker_modifier *= 1.08
		notes.append("闂備胶顭堢换鍫ュ礉鐏炵偓鍙忛煫鍥ㄦ⒒椤╂煡鏌曢崼婵囶棞闁诲繑绋戦湁闁稿繗鍋愰。鏌ユ煛閸屾瑧鍔嶇€垫澘瀚ˇ鎶芥煕椤垵澧寸€殿喚顭堥…銊╁箛椤旂虎妲峰┑鐐舵彧缁茶棄螞濡ゅ懎绠栭柟鐐墯濞间即鏌曟径娑氱暠缂佽尙鎳撹灃闁稿本鎯幋锕€鍨傛い鎺戝缁犳煡鏌ｉ弮鍌澦夐柛?)
		attacker_damage_taken = 28
		defender_damage_taken = 18
	elif engagement_rules == "DEFENSIVE":
		attacker_modifier *= 0.96
		notes.append("闂傚倸鍊搁崯顖濄亹閸愵亙鐒婇柤鎭掑劤椤╂煡鏌曢崼婵囶棞闁诲繑绋戦湁闁稿繑绁归鍫濆偍婵炴垶鐟ч埞宥嗙節闂堟稒顥犻柟鐣屽█閺屻倝骞栨笟鍥ㄦ缂傚倸绉撮澶愬极瀹ュ洣娌柟顖嗗棗鎮呴梺鍝勵槴閺呮粓鎯勯鐐茬劦妞ゆ帒鍊搁弸搴ㄦ倵绾懏鐝繛鐓庣箻瀹曟﹢鍩℃担鍝ョ潉闂?)
		attacker_damage_taken = 10
		defender_damage_taken = 8
	if formation == "WEDGE":
		attacker_modifier *= 1.12
		notes.append("婵犲痉鏉库偓鏍蓟閵娾晜鍤嬪ù鐓庣摠閳锋捇鏌涢…鎴濅簼缂佺虎鍨跺娲敃閵忕姭鍋撻幖浣哥畺閹兼番鍊楅悿鈧銈嗗姧閼靛綊宕戦幘缁樺亜鐎瑰嫮澧楅惁鏍磽娴ｆ瓕瀚伴柣蹇旂箖閺呭爼鎮╅悽鍨紡闁荤喍闄嶉崐鎰板磻?)
		defender_damage_taken += 6
	elif formation == "SPHERE":
		attacker_modifier *= 0.95
		notes.append("闂備浇宕甸崑娑㈠疮椤愶附鍤嬪ù鐓庣摠閳锋捇鏌涢…鎴濅簼缂佺虎鍨崇槐鎺斺偓锝庝簻閺嗗崬霉閻樿櫕灏﹂柡浣哥Ф娴狅箓鎳栭埡鍏╂垿姊洪崨濞掝亪顢栭崨鏉戞槬婵°倕鎳忛悞濠氭煟閺傚灝妲绘い鏂匡躬瀵爼宕煎┑鍡樻闂佸憡鐟ラ崯瀛樹繆?)
		attacker_damage_taken = max(6, attacker_damage_taken - 8)
	elif formation == "LINE":
		attacker_modifier *= 1.02
		notes.append("婵犵妲呴崹鍏肩濠婂牆鍨傛い蹇撶墛閳锋捇鏌涢…鎴濅簼缂佺姵甯￠弻娑㈠箳閸℃ɑ鐝掔紓渚囩厛閸撴稓鍒掑▎鎾崇闁肩⒈鍓氬В搴ㄦ⒑鐠囧弶绂嬮柛瀣閹便劏绠涢弴鐔锋毇闂佺硶鍓濋悷锔惧娴煎瓨鐓?)
	match tactic_card:
		"SCORCHED_EARTH":
			attacker_modifier *= 1.20
			notes.append("闂備胶绮敮顏嗙不閹存繐鑰块柨鐔哄Т缂佲晠鎮归幁鎺戝闁硅姤绮庨埀顒侇問閸犳牠骞栭銈傚亾閸偆鍙€妤犵偐鍋撶紓鍌欑劍钃遍柡鍡曞嵆閺屻劌鈽夊Ο鑲╁姰闁诲孩鍝庨崹鍝勵嚗閸曨垰浼犻柛鏇ㄥ亞閹ジ姊洪崫鍕伀闁哥姵鎹囬弻鍫⑩偓鐢告櫜閻掑﹪鏌涢埄鍏╂垿宕抽鑺ュ弿闁挎繂瀚ˇ锕傛煕濞嗘挾鐣虹€规洜鍏橀獮蹇曚沪閻戔晛浜鹃柛鎰典簼婵ジ鏌ｉ幇闈涘闁绘挶鍨介弻?)
		"ORBITAL_BOMBARDMENT":
			attacker_modifier *= 0.92
			defense_power = int(round(defense_power * 0.5))
			notes.append("闂佸搫顦遍崑鎴﹀礉閹寸偟顩查柣鎰靛墯婵粓鏌熷▓鍨灈濞寸媭鍠栭埥澶愬箻鐎涙ê闉嶉梺杞拌兌閸嬨倕鐣烽姀鈶╁亾閿濆簼绨婚柣鎾村灴濮婂宕橀埡浣虹シ闁诲繐绻嬬划娆撴偘椤曗偓瀹曟﹢骞撻幒妤€褰欓梻浣瑰缁嬫垶绺介弮鍌氱筏闁告挆鈧崑鎾绘偨濞堟寧鏁梺绯曟櫅閻倸顫忔總鍛婂亜闁告稑锕︾粊閿嬬箾鐎靛壊鍎犻柛濠冪墵瀵煡濡烽埡鍌氫虎闂佹悶鍎绘俊鍥偡閹剧粯鈷掗柛鏇ㄥ亞琚梺?)
		"WOLF_PACK":
			attacker_modifier *= 1.0 + float(ship_type_count(attacker, "CORVETTE")) * 0.05
			defender_modifier *= 0.9
			notes.append("闂備胶绮悷銊╁磻閹版澘绀傞柕蹇嬪灮閻滆霉閿濆洨鎽傛繛鐓庣秺閺岀喓绱掑Ο鍝勵潓閻庤娲栭惌鍌炵嵁鎼淬劌围闁告侗鍙冮崬鍫曟⒑閻撳孩鍟炲鐟版瀹曟濮€閵忊€虫瀭闂佸憡娲﹂崹顖滅磽婢跺ň妲堥柟鐐▕椤庢鏌涢妸銉х鐎规洘绮撻幊鐘垫崉閸濆嫬绠ｉ梻浣告啞濮婂湱绮欒箛娑樼劦?)
		"JUMP_ASSAULT":
			attacker_modifier *= 1.15
			attacker_damage_taken += 6
			notes.append("闂佽崵濮撮幖顐﹀疮瀹曞洨绱﹂柤娴嬫櫇閻滆霉閿濆浂鐒炬慨锝咃躬閺屾盯鏁傞崫鍕潎濡炪倐鏅濈划顖氼焽椤忓牜鏁婇柣鎾虫捣椤忕粯绻涢幋鐐村碍闁挎洏鍊濆畷锝堢疀濞戞瑧鍔搁梺闈浤涢崒婊咃紱闂備礁鎲″褰掑礃閼姐倖顫曟繝闈涙处婵挳鏌涢埄鍏╂垿鎯佽ぐ鎺撯拻闁搞儺浜滅槐锔剧磼椤帞绡€闁硅櫕鐩、鏃堝炊椤掑倸褰侀梻鍌氬€搁崯鏉戭焽瑜旈幃妤呮倻閽樺）?)
		"BATTLE_LINE":
			attacker_modifier *= 1.0 + float(ship_type_count(attacker, "CRUISER") + ship_type_count(attacker, "BATTLESHIP")) * 0.04
			notes.append("闂備胶鎳撻悺銊╂晪闂佸壊鐓堟禍鐐烘儉椤忓牆鍨傛い鏃囧亹缁犳帡姊洪崨濠勫闁绘姊婚埀顒勬涧閻倸鐣峰┑鍡忔婵犲﹤鍟伴崢鎺楁⒑瑜版帗娅滈柤鍐茬埣閹晫绱掑Ο鑽ょФ闂佽鍎抽崯鍨掓径鎰厪?)
	if defense_power > 0:
		notes.append("闂佸搫顦遍崑鎴﹀礉閹寸偟顩插Δ锝呭暞閳锋捇鏌熺紒妯虹瑨闁轰焦鐗楅〃銉╂倷閹绘帗姣愰悷婊呭閹告娊鐛幘璇茬疀妞ゅ繐妫滅换鎴炵箾?%s 闂備胶绮崝鏇犵礊婵犲伣锝囨嫚瀹割喖娈梺鎸庣☉鐎氼亞妲愰幋锔界厱闁哄啠鍋撶紒瀣箻閸┾偓? % str(defense_power))
	var attacker_power: float = fleet_power(attacker) * attacker_modifier
	var defender_power: float = fleet_power(defender) * defender_modifier + float(defense_power)
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
			notes.append("闂備胶鎳撻悺銊┾€﹂崼銏″枂闁挎洖鍊稿Λ姗€鎮峰▎蹇擃伀闁哄棙鐟╅弻銈夊传閵夈儺鏆梺鐟版啞閻熴儵顢氶妷鈺佺劦?%s闂? % defender_retreat_id)
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
				notes.append("闂備胶绮敮顏嗙不閹存繐鑰块柨鐔哄Т缂佲晠鎮归幁鎺戝闁硅姤绮撻弻鐔虹玻閺嵮冾伀婵℃彃鐗嗛湁婵犲﹤鍟ˉ鈩冦亜閺囩喎鍝虹€殿喕鍗抽幃銏犆洪鍕福闂備焦鐪归崝宀€鈧凹鍓欓敃銏⑩偓闈涙啞閸嬫﹢鏌曟繛鍨姢缂佹唻濡囩槐鎺戔槈濞嗗繒浠ч梺?)
			next_state["starSystems"][system_index] = system
			break
		if engagement_rules == "HIT_AND_RUN":
			next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ラ梻浣告贡閻熸娊宕遍埡鍌涙澑", "%s 闂備胶鎳撻悺銊╁礉閺囩喐鍙忔繛鎴炲焹閸嬫捇鎮烽悧鍫熸嫳闂佹悶鍔嶅銊у垝閿濆棙濯寸紒娑橆儐閻掞箑螖閻橀潧浠滈柣鏍с偢瀹曟娊骞栨担鍝ヮ槴濠电偞鍨剁喊宥囩玻濡ゅ懏鐓涚€广儱鎳忕粊顐ょ磼鏉堛劎绠栭柟宄版嚇瀹曞崬螣鐠囪尙澶勯梻浣哄帶閻ゅ洤螞閸曨垱鍋╂い鎺戝缁€鍌炴煏婵犲繒鐣卞璺虹Ф缁辨帡鎮╅銏犫拤闂佸壊鐓堥崜鐔风暦閻樿绠掗柟鍝勬娴? % attacker.get("name", ""), "COMBAT")
		else:
			next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ラ梻浣告贡閻熸娊宕遍埡鍌涙澑", "%s 闂備礁鎲￠崹鍦垝椤栨粏濮虫繝闈涙川椤╂煡鏌涢埄鍐噭缂佹劖顨婇弻鈥愁吋閸涱喚鈹涢梺绯曟櫅閻倸顫忔總鍛婂亜闁汇値鍨伴悵顖涚節閵忥絾纭鹃柟纰卞亯閵囨劙宕堕鈧粻锝嗕繆椤栨碍鎯堥梻鍛耿閺岀喓鎸╂径濠傛殭闁绘挻鍨块弻鈩冨緞婵犲倹娈ч梺? % attacker.get("name", ""), "COMBAT")
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
		next_state = update_diplomatic_profile(next_state, defender.get("ownerId", ""), "hostile", -6, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦幑鍫曟煏婵炲灝濡跨紒鐙€鍣ｉ弻锟犲醇閵忕姵鐎哄┑顔斤公缁犳捇鐛€ｎ€喓娑甸崨顓炵畱闂備礁鎲￠悷锕傛偋閺囩姵顐介弶鍫涘妿閳绘棃鎮归崶銊ョ祷鐞氱喖姊洪幐搴ｂ槈闁兼椿鍨抽幑銏ゅ焵椤掆偓椤啴濡堕崪浣哄悑闂侀潻绲鹃幃鍌氼嚕椤掑嫬绠€光偓閳ь剙危閹存緷褰掑礂閸忚偐鍑￠梺鍛婄懇缁犳牕鐣峰Ο琛℃婵°倕鍟板▓銈嗙節閻㈤潧浠掗柣鎺炵畵瀹曘垽顢楅崟顐?)
		next_state = add_diplomatic_memory(next_state, "闂佸搫顦悧蹇涘箠閹炬眹鈧倿濡搁埡浣侯吅濠碘槅鍨崇划顖炴倶瀹ュ拋鐔嗛悹鍝勬惈閼稿綊鏌?, "%s 闂備線娼荤拹鐔煎礉鐎ｎ剛绠?%s 闂備焦鐪归崝宀€鈧凹浜滈～婵嬫晝閸屾氨顓哄┑鈽嗗灣椤㈠﹪宕㈤鍕拺妞ゆ帒顦顔济瑰鎰ɑ鐎垫澘瀚板畷锟犳倷閼碱剙濮堕梻? % [defender.get("name", "闂備浇妗ㄧ粈渚€鎳熼鐐茬柈?), attacker.get("name", "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦伴崵瀣归悡搴ｆ憼鐞?)], [attacker_owner, defender.get("ownerId", "")], "WAR", 3)
	else:
		next_state["fleets"][defender_index] = damage_fleet(defender, defender_damage_taken)
		if engagement_rules == "DEFENSIVE" or engagement_rules == "HIT_AND_RUN":
			next_state["fleets"][attacker_index] = damage_fleet(attacker, attacker_damage_taken)
			next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ラ梻浣告贡閻熸娊宕遍埡鍌涙澑", "%s 闂備線娼荤拹鐔煎礉鐎ｎ剛绠斿鑸靛姇缁€鍡涙煃閸濆嫬鈧敻宕戦幘瀛樺缂佸绨卞Λ锔界箾閹寸偞灏い鎴濇嚇閹箖顢楅崟顐ゎ吅闂佸綊鍋婇崹鐗堟叏鎼达絿纾奸柛灞剧懅娑撹尙绱掓潏銊х疄鐎殿喚鏁婚、鏃堝炊瑜嶉獮瀣節閵忥絾纭鹃柟纰卞亯閵囨劙宕堕浣稿壆濡炪倖姊婚弲顐﹀垂婵傚憡鐓? % attacker.get("name", ""), "COMBAT")
			next_state = update_diplomatic_profile(next_state, defender.get("ownerId", ""), "firm", 2, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦幑鍫曟煏婵犲繘妾ù鐘筹耿瀵爼鍩￠崒姘变化濠殿喗锕粻鎾荤嵁鐎ｎ€喓娑甸崨顓炵畱闂備礁鎼悧婊勭閿濆绀傛俊顖濆亹閻滆霉閿濆牊顏犲鐟板暣濮婂宕橀鐐垫闂佹悶鍊曢柊锝夊极瀹ュ洣娌柦妯侯槼椤斿绱撻崒娆戠К闁告侗鍨遍弳鐗堢箾閿濆懏澶勭紒璇插暟閳ь剙鐏氬褰掋€冮崶顬喖宕崟顓т紳濠电姵顔栭崰妤冣偓绗涘洤鐒垫い鎴濇健濡剧兘鏌?)
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
				next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ラ梻浣告贡閻熸娊宕遍埡鍌涙澑", "%s 闂備線娼荤拹鐔煎礉鐎ｎ亶娼╅柨鏇炲€哥粻锝嗕繆椤栨粠鏀伴柛姗嗗墮椤法鎹勯崫鍕煘闂佺硶鏅涚€氫即寮鍥︽勃闁告挆鍕唲闂備胶鍘ч幗婊勬櫠濡ゅ懎绠版繛鍡楁禋閸ゆ鏌?%s闂? % [attacker.get("name", ""), retreat_id], "COMBAT")
				notes.append("闂備胶鎳撻悺銊┾€﹂崼銏″枂闁挎洖鍊稿Λ姗€鎮峰▎蹇擃伀闁哄棙鐟╅弻銈夊传閵夈儺鏆梺鐟版啞閻熴儵顢氶妷鈺佺劦?%s闂? % retreat_id)
			else:
				next_state["fleets"].remove_at(attacker_index)
				next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ラ梻浣告贡閻熸娊宕遍埡鍌涙澑", "%s 闂備線娼荤拹鐔煎礉鐎ｎ亶娼╅柨鏇炲€哥粻锝嗕繆椤栨粠鏀伴柛姗嗗墮椤法鎹勯崫鍕煘闂佺硶鏅涚€氫即寮鍛殕闁告劑鍔庨崢鎺楁⒒閸屾艾鏆熼柛鐘虫礋閿濈偤鏁傞懞銉ゆ唉濡炪倖鍔ч懙褰掑磻閹捐鐒垫い鎺戝缁€鍕煟閹寸伝顏堟倶濞戙垺鐓曢柨鏃€鍨濋懜顏堟煃? % attacker.get("name", ""), "COMBAT")
			next_state = add_diplomatic_memory(next_state, "闂佸搫顦弲婊呯矙閹烘鏋佸Δ锝呭暙閻淇婇妶鍕槮闁?, "%s 闂備線娼荤拹鐔煎礉瀹€鍕垫晪?%s 闂備焦鐪归崝宀€鈧凹浜炵槐鐐哄籍閸繄顓哄┑鈽嗗灣椤㈠﹪宕㈤鈧…璺ㄦ崉閸濆嫯鍩為梺绯曟櫅鐎氱増淇? % [attacker.get("name", "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱顦伴崵瀣归悡搴ｆ憼鐞?), defender.get("name", "闂備浇妗ㄧ粈渚€鎳熼鐐茬柈?)], [attacker_owner, defender.get("ownerId", "")], "WAR", 3)
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
	next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌濠电姭鍋撻柛鎰ゴ閺嬫牠鏌曟繝搴ｅ帥闁?, " / ".join(notes), "COMBAT")
	next_state = add_combat_report(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍х暦闄囩粻娑橆潩閻撳孩鏆ラ梻浣烘嚀閻°劏鎽繝?, attacker.get("name", "闂佸搫顦弲婊呯矙閹烘鏋佸Δ锝呭暞閸ゅ霉閻撳海鎽犵悮?), defender.get("name", "闂傚倸鍊搁崯顖濄亹閸愵亙鐒婂ù鐘差儐閸ゅ霉閻撳海鎽犵悮?), attacker_wins, casualties, kills, remaining_power, notes)
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
		system["colonizationRisk"] = mode_data.get("risk", "濠?)
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
			next_state = add_message(next_state, "婵犵數鍋涢悧濠囨偋濡ゅ懏鍎嶆い鏍仜閹瑰爼鏌ｅΔ鈧悧鍡涙倶閸ヮ剚鐓?, "%s 闁诲海鎳撻幉陇銇愰崘顔藉仼妞ゆ帒瀚粻锝夋煙闁箑澧い銈呮嚇閺屾稑鈹戦崟顐㈩瀳缂傚倸鍊归幐楣冨箯鐎ｎ喖绠婚柛娑卞灣椤︻噣姊洪悷鎵憼闁告梹甯為幏褰掓偄婵傚妗ㄩ梺鎸庣箓閹虫劗娑甸埀顒€鈹戦悙鑼闁绘顨婇幆鍐敍閻愬弶宓嶉梺鐓庡閸忔﹢宕? % system.get("name", ""), "EVENT")
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
	if not connected_to(next_state, fleet.get("systemId", "")).has(target_system_id):
		return next_state
	var cost: int = 1
	for lane: Dictionary in next_state.get("hyperlanes", []):
		var direct: bool = lane.get("startSystemId", "") == fleet.get("systemId", "") and lane.get("endSystemId", "") == target_system_id
		var reverse: bool = lane.get("endSystemId", "") == fleet.get("systemId", "") and lane.get("startSystemId", "") == target_system_id
		if direct or reverse:
			cost = int(lane.get("traversalCost", 1))
	if int(player.get("resources", {}).get("energy", 0)) < cost:
		return add_message(next_state, "缂傚倷绀侀ˇ鎶筋敋瑜庨幈銊╁煛閸屾氨绐為柡澶婄墱閸嬪顤?, "闂備胶鍘ч悿鍥ㄦ叏閵堝洩濮虫い鏃傛櫕閳绘梻鈧箍鍎遍悧鍡涘窗閺囥垺鐓ユ繛鎴烆焽閻掔兘鏌涢埡浣虹劯婵﹤銈搁幃銏ゅ川婵犲繘鐛滄繝鐢靛仜椤︽澘煤濠靛牏鐭氭い鎺嶇劍娴溿倕霉閿濆浂鏆柛?, "SYSTEM")
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
	next_state = add_message(next_state, "闂備礁銈搁弲鏌ュ础閸愬弬锝夋晜閸撗呯厠闁荤姴娲﹁ぐ鍐杽", "%s 闁诲氦顫夐悺鏇犱焊椤忓棛鐭氭い鎺嶇劍娴溿倕霉閿濆牊顥夋繛鍫ョ畺閺岋綁鍩℃繝鍌涚亶闂佺粯鐗紞浣割嚕娴煎瓨鍋勬繛宸簻閸樻瑩姊? % fleet.get("name", ""), "EVENT")
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
			next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍嵁鎼淬劌唯闁靛绠戦弳?, "%s 闂備線娼荤拹鐔煎礉鎼粹埗鐑樺閺夋垵鍞ㄩ梺鎼炲劘閸斿秷顤傜紓鍌欑贰閸ㄧ敻顢氳瀹曠敻顢欓悙顒€顏搁梺闈涱檧闂勫嫬鈻嶉弴銏＄厱闁归偊鍘鹃埥澶愭煠閼姐倕鏋戠€垫澘瀚板畷顐﹀礋椤愩倖鍋ч梻浣侯攰閻洭宕橀妸褍骞€闂備礁鎼ˇ顖炲窗濞戞碍顫曟繝闈涱儐閸ゅ霉閻撳海鎽犵悮婵嬫⒑閸涘﹤鐏辨繛鍜冪秮閻涱噣宕堕妸褉鏋栭梺閫炲苯澧伴柍褜鍓濋～澶屽枈瀹ュ鍨傛い鎺戝缁犳煡鏌ｉ弮鍌澦夐柛? % moved_fleet.get("name", ""), "COMBAT")
		else:
			next_state["fleets"].remove_at(fleet_index)
			next_state = add_message(next_state, "闂備胶鎳撻悺銊ㄦ懌闂佸搫顑囬崰鏍嵁鎼淬劌唯闁靛绠戦弳?, "%s 闂備線娼荤拹鐔煎礉鎼粹埗鐑樺閺夋垵鍞ㄩ梺鎼炲劘閸斿秷顤傜紓鍌欑贰閸ㄧ敻顢欐繝鍕闁哄啫鐗嗙粻锝嗕繆椤栨稐鑸ù婊冦偢閺屾盯骞掗崱妯绘緭闂? % moved_fleet.get("name", ""), "COMBAT")
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
	next_state = add_message(next_state, "闂備浇顫夋禍浠嬪垂婵犳艾纾奸柕濞р偓閸嬫捇鎮烽悧鍫熸嫳闂?, "%s 闁诲海鎳撻幉陇銇愰崘顔藉仼妞ゆ帒瀚粻锝夋煙闁箑澧婚柛銈囧█閺岋綁鍩℃繝鍌涚亶闂佺粯鐗紞浣割嚕娴煎瓨鍋勬繛宸簻閸樻瑩姊哄Ч鍥у閻庢凹鍓涢埀顒佽壘妤犳悂婀侀柣搴祷閸斿宕? % fleet.get("name", ""), "EVENT")
	next_state = resolve_player_system_event(next_state, system_id)
	return assess_game_status(next_state)

static func colonize_system(state: Dictionary, fleet_id: String, system_id: String, mode: String = "STANDARD") -> Dictionary:
	var next_state: Dictionary = duplicate_state(state)
	var player: Dictionary = player_faction(next_state)
	var preview: Dictionary = colonization_preview(next_state, fleet_id, system_id, mode)
	if not preview.get("allowed", false):
		return add_message(next_state, "婵犵數鍋涢悧濠囨偋濡ゅ懏鍎嶆い鏍ㄧ☉缁剁偤寮堕崼顐函鐞?, str(preview.get("reason", "闁荤喐绮庢晶妤呭箰閸涘﹥娅犻柣妯款嚙缁秹鏌ｅΟ铏癸紞闁靛棗锕ョ换娑㈠醇閻斿搫顫ч梺娲荤厛閸ㄨ埖淇?)), "SYSTEM")
	var system_name: String = system_id
	for entry: Dictionary in next_state.get("starSystems", []):
		if entry.get("id", "") == system_id:
			system_name = entry.get("name", system_id)
			break
	var mode_name: String = colony_mode_data(mode).get("name", mode)
	next_state = start_colony_for_faction(next_state, player.get("id", ""), system_id, mode, "婵犵數鍋涢悧濠囨偋濡ゅ懏鍎嶆い鏍ㄧ矋婵ジ鏌嶉妷銉ユ毐闁诲繐锕弻娑橆潩閻撳海浠╂繝?, "闁诲海鎳撻幉陇銇愰崘顕呮晪?%s 闂備礁鎲￠悷锕傚垂婵傜绠?s闂備焦瀵х粙鎴︽嚐椤栨稒娅犻柣妯款嚙娴肩娀鏌曟繛鍨姢缂佹唻绠撻幃瑙勬媴閻熸澘濮㈢紓浣介哺閸ㄥ爼骞堥妸褉鍋撻敐鍐ㄥΨ闁? % [system_name, mode_name])
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
		next_state = add_diplomatic_memory(next_state, "闂佸搫顦悧蹇涘箠閹炬眹鈧倿濡搁妸褏鏉搁悷婊勫灥椤?, "闂備胶顭堢换鎴濐熆濡偐绱﹀Δ锝呭暙缁€鍌涖亜閹烘垵鈧悂顢欐繝鍥ㄧ厱闁靛／鍐冦儵鎮介婵囶仩闁逞屽墰椤㈠﹤鈻斿☉銏犵柈婵°倕鎳庣粈澶愭煕椤垵娅橀柡澶婎煼濮婂鍩€椤掑嫭鍤勬い鏍殔娴滈箖鎮橀悙鑸殿棄缂佸弶妞介弻娑㈠箣閻樻彃濡哄銈嗗笚缁矂顢氶敐鍫㈢杸婵鍘ф俊鎶芥⒑閸涘﹦鈽夋い顓炵墦閸┾偓?, ["f_player", "f_orchid"], "WARNING", 2)
		next_state = update_diplomatic_profile(next_state, "f_orchid", "firm", -2, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱妫欐禍銈夋煙鐎电浠﹂柛鈺佸€块弻娑㈠箛椤撶姭妫╃紓浣靛妸閸斿秶鎹㈠☉娆愬闁荤喐婢樼粻鎴濃攽椤旂晫绠扮紒鑼舵閿曘垽顢旈崨顖楁灃婵犵數濮撮崐鍝ュ閹惰姤鐓ユ繛鎴烆焽閻掑憡绻涢幘鍐差暢闁硅尙澧楃粭鐔煎焵椤掑嫬鐒垫い鎺嶆娴溿垻绱掔拠鎻掓殭妞ゎ偁鍨介弫鎰板川椤栨粠鏀ㄦ繝鐢靛仦閹哥偓绻涢埀顒€霉濠婂啫鈷旈柟顔诲嵆婵℃悂濡搁敃鈧☉褔姊虹粙璺ㄧ闁哥喎娼″畷纭呯疀濞戞?)
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
		var has_shipyard: bool = system_has_or_queued_building(next_state, merchant_home.get("id", ""), "SHIPYARD")
		var merchant_build_priority: String = choose_ai_building_priority(next_state, "f_merchant", merchant_home, "AGGRESSIVE")
		if merchant_build_priority != "":
			var merchant_blueprint: Dictionary = find_building_blueprint(merchant_build_priority)
			if not merchant_blueprint.is_empty() and can_afford(merchant_resources, merchant_blueprint.get("cost", {})):
				next_state = queue_structure_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), merchant_blueprint, "闂佸摜鍠庡Λ婊兦庨幎鑺ュ殏闁哄啫鍊圭粈鍐偓瑙勬偠閸庢娊鍩?, "闂佸摜鍠庡Λ婊兦庨幎鑺ュ殏闁哄啫鍊圭粈鍐偓鍦焾瀵爼鎮ч幘顔肩妞ゆ棁鍋愮粔濂告煕閹惧磭啸缂佷緡鍋勯埞鍐箛椤忓棛鎲块梺鐟扮摠椤洭寮抽幇鐗堫梿闁逞屽墮鏁堥柛灞剧箘濞堝爼鏌℃担瑙勭稇缂傚倹鎸鹃幏瀣箲閹伴潧鎮侀梺鍛婂笚鐢洭鍩€?)
				has_shipyard = has_shipyard or merchant_build_priority == "SHIPYARD"
		if has_shipyard:
			var ship_type: String = "CRUISER" if int(next_state.get("turn", 1)) >= 14 else "DESTROYER" if int(next_state.get("turn", 1)) >= 10 else "CORVETTE"
			var cost: Dictionary = ship_cost(ship_type, next_state, "f_merchant")
			if can_afford(merchant_resources, cost):
				next_state = queue_ship_for_ai(next_state, "f_merchant", merchant_home.get("id", ""), ship_type, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵喗鈷戞い鎰╁€曢瀷闂?, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵亖鍋撻悷鐗堝暈鐟滄澘鍟撮幆鍐閿涘嫧鏋栭梺閫炲苯澧撮柟?)
	if not decision.is_empty():
		var action: String = decision.get("action", "WAIT")
		if action == "TRADE" and int(relation_view.get("trust", 0)) + int(relation_view.get("utility", 0)) / 2 >= 0:
			next_state = add_message(next_state, "闂備礁鎽滈崰搴∥涘鍫熷剹闁绘劦鍓涢埞宥嗐亜閺冨倵鎷℃俊?, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愩劉妲堥柟鎹愵嚃閸ゆ瑥鈹戦瑙勬珚妤犵偞鎹囬獮鍥敆閳ь剙袙婢舵劖鐓欐い鎾寸矊閻忊晜銇勯敃鈧璺侯焽韫囨稒鍋￠梺顓ㄩ檮濞堁囨煟閻樺啿澹冮柛鈩冪懅椤撳ジ姊?, "DIPLOMATIC")
		elif action == "DECLARE_WAR" and int(relation_view.get("fear", 0)) <= 60 and not merchant_posture.get("high_pressure", []).has("闂備胶顭堢换鎴濐熆濡偐绱﹀Δ锝呭暙缁€鍌涖亜閹烘垵鈧悂顢?):
			next_state = declare_war_on_faction(next_state, "f_merchant", "f_player")
		elif action == "EXPLORE" and not merchant_fleet.is_empty():
			for fleet_index: int in range(next_state["fleets"].size()):
				var fleet: Dictionary = next_state["fleets"][fleet_index]
				if fleet.get("id", "") == merchant_fleet.get("id", ""):
					fleet["systemId"] = decision.get("target", fleet.get("systemId", ""))
					next_state["fleets"][fleet_index] = fleet
			next_state = add_message(next_state, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵喗鍋ｉ悗锝庝簻閺嗘瑥鈹?, "闂佸搫顦悧蹇涖€佹繝鍥ㄧ叆闁靛牆顦粻顕€鏌曢崼婵堝闁绘帒顭峰濠氬礃椤忓嫭鐎婚梺?%s 闂佽崵濮撮幖顐﹀疮瀹曞洨绱﹀┑鍌滎焾杩? % decision.get("target", ""), "EVENT")
		elif action == "BUILD":
			next_state = add_message(next_state, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵喗鈷戞い鎰╁€曢瀷闂?, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵亖鍋撶憴鍕憙閻忓浚浜幆鍐偄閻撳孩鐎柣搴㈢⊕钃遍柟鐑戒憾閺屾盯濡疯娴犳粓鏌熼濂割€楁い鏇熺懃鐓ゆい蹇庣娴滈箖鏌ｅΟ纭咁劅闁告埃鍋撻梻浣告啞鐢鏁崶顒€鐒?, "EVENT")
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
			next_state = add_message(next_state, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵喗鍋ｉ悗锝庝簻閺嗘瑥鈹?, "闂佸搫顦悧蹇涖€佹繝鍥ㄧ叆闁靛牆顦粻顕€鏌曢崼婵堝闁绘帒顭峰濠氬礃椤忓嫭鐎婚梺?%s 闂佽崵濮撮幖顐﹀疮瀹曞洨绱﹀┑鍌滎焾杩? % neutral_target.get("name", ""), "EVENT")
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
			next_state = start_colony_for_faction(next_state, "f_merchant", occupied_system.get("id", ""), "RESOURCE_OUTPOST", "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愨晝绠鹃柛顐ゅ枔婢ь剟鏌?, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵亖鍋撻悷鐗堝暈鐟滄澘鍟敃?%s 闁诲海鍋ｉ崐娑樷枍閿濆鍋熸繛鎴欏灩缁€鍫⑩偓骞垮劚閻楀繒绮绘繝姘厱闁绘棃鏀遍ˉ鐘绘煟濠垫劕鐏﹀┑? % occupied_system.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т閸欏﹪鏌ｉ弮鈧浠嬪礂?))
	if bool(merchant_trend.get("opportunity_rising", false)) and not has_treaty(next_state, "f_merchant", "f_player", "TRADE_PACT") and int(next_state.get("turn", 1)) % 4 == 0:
		next_state = add_diplomatic_message(next_state, "f_merchant", ["f_player"], "SINGLE", "PUBLIC", "PROPOSAL", "闂備礁鎽滈崰搴∥涘鍫熷剹闁告挆鍕彴闂佸搫娲ㄩ崰搴ｆ導?, "闂備礁鎽滈崰搴∥涘鍏﹀酣骞庨懞銉ユ畯闂佸搫鍟崐鍦矆閸愵喗鍋ｅù锝夋涧閳ь剚鎸鹃幏褰掓偄閸涘﹦绉堕梺鑽ゅ枛閸嬪﹪寮抽弮鍫熷€堕柣鎰ㄦ櫅娴滈箖姊洪崨濠冪叆闁诲繑绻堝畷鐢割敇閵忊€充虎闂佸搫顦扮€笛囧磹閵堝悿褰掓晲閸℃瑧鐓傞梺缁樼◤閸庨潧鐣烽敐澶嬫櫜闊洦娲滈ˇ顕€姊洪崷顓烆暭閻庣瑳鍥х濞寸厧鐡ㄩ悡鍌溾偓骞垮劚濡瑩鎮￠埀顒勬煟閻樺弶鎼愰悗姘间邯瀹曪絾绻濋崘顏佹灃闁圭厧鐡ㄧ换鍕矙閹达附鐓熼柕濞垮劚椤忣剟姊虹憗銈呪偓婵嗩嚕娴兼潙绠荤€规洖娲﹀▓褔姊洪崷顓炲妺閻㈩垰娲崺鈧?, true)
	if bool(merchant_trend.get("pressure_rising", false)) and int(next_state.get("turn", 1)) % 4 == 0:
		next_state = update_diplomatic_profile(next_state, "f_merchant", "guarded", -1, "闂備胶绮竟鏇㈠疾濞戙埄鏁婄€广儱妫欐禍銈夋煙鐎电浠﹂柛鈺佸€块弻锝夊Ω閵夈儺浠奸梺鍝ュ枑椤ㄥ﹤顕ｉ妸鈺佸瀭妞ゆ柨銇欏Δ鍛厱婵﹩鍘奸悘锔姐亜閹烘挾鐭掔€规洜鍏樻俊鎼佹晝閳ь剝鈪靛┑掳鍊曢崐褰掆€﹂崼鐔侯浄闁割偁鍎查崕搴ㄦ煟閺冨倸鍔嬮柣锝呭船椤啰鈧綆浜崣鍕箾閸涱喗灏甸柟椋庡█瀹曠喖顢旈崟顐ｅ皨闂?)
	return ensure_faction_controls(next_state)

static func queue_structure_for_ai(state: Dictionary, owner_id: String, system_id: String, blueprint: Dictionary, message_title: String = "AI闁诲氦顫夐幃鍫曞磿閹惰棄鐓?, message_content: String = "AI 闂備礁鎲￠弻銊╂倶濠靛洦鍙忛煫鍥ㄦ惄閸ゆ洟鏌嶈閸撴岸骞堥妸褉鍋撻敐搴′簻闁抽攱鐗滈埀顒傚仯閸婃宕曢妶鍜冭€垮ù鍏兼綑閹瑰爼鏌ｉ弮鈧鍧楀疮鎼淬劍鐓涢柛灞惧嚬濞肩喖鏌?) -> Dictionary:
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

static func queue_ship_for_ai(state: Dictionary, owner_id: String, system_id: String, ship_type: String, message_title: String = "AI闂傚倷绶￠崑鍡樻叏妤ｅ啫鏄?, message_prefix: String = "AI 闂備礁鎲￠弻銊╂倶濠靛洦鍙忛煫鍥ㄦ惄閸熷懘鏌熺紒妯虹婵炲牆鎼埥澶愬箻椤栨矮澹曢梻?) -> Dictionary:
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
	return add_message(next_state, message_title, "%s%s缂傚倸鍊搁崐褰掓偋閺囥垹鐭楅柛鈩冾殢閸ゅ牊绻涘顔荤按闁稿鎹囬幃鈺冪磼濡偞娲熼弻娑㈠箳閹惧彉绮婚梺? % [message_prefix, InitialData.ship_labels().get(ship_type, ship_type)], "EVENT")

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
	if not orchid_home.is_empty():
		var has_lab: bool = system_has_or_queued_building(next_state, orchid_home.get("id", ""), "RESEARCH_LAB")
		var has_shipyard: bool = system_has_or_queued_building(next_state, orchid_home.get("id", ""), "SHIPYARD")
		var orchid_build_priority: String = choose_ai_building_priority(next_state, "f_orchid", orchid_home, "DEFENSIVE")
		if orchid_build_priority != "":
			var orchid_blueprint: Dictionary = find_building_blueprint(orchid_build_priority)
			if not orchid_blueprint.is_empty() and can_afford(orchid_resources, orchid_blueprint.get("cost", {})):
				next_state = queue_structure_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), orchid_blueprint, "闁稿繑婢樼缓楣冨礂椤掑倸顔婄€规悶鍎抽埢?, "闁稿繑婢樼缓楣冨礂椤掑倸顔婄€规瓕寮撶欢鐑藉箲椤曗偓濡茶顕ラ垾鑼憿缂佸鍨归悥鐑樺濡搫甯ョ紒鐙欏棛娈堕柡浣哥摠濠€浼村捶閻旈绱﹂悹浣峰嫎閳?)
				has_lab = has_lab or orchid_build_priority == "RESEARCH_LAB"
				has_shipyard = has_shipyard or orchid_build_priority == "SHIPYARD"
		if has_shipyard:
			var orchid_ship_type: String = "DESTROYER" if int(next_state.get("turn", 1)) >= 12 else "CORVETTE"
			var orchid_ship_cost: Dictionary = ship_cost(orchid_ship_type, next_state, "f_orchid")
			if can_afford(orchid_resources, orchid_ship_cost):
				next_state = queue_ship_for_ai(next_state, "f_orchid", orchid_home.get("id", ""), orchid_ship_type, "闁稿繑婢樼缓楣冨礂椤掑倸顔婇柡浣割嚟缁?, "闁稿繑婢樼缓楣冨礂椤掑倸顔婄€瑰憡褰冮惃銏＄▔閳ь剟鎳?)
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
			next_state = add_message(next_state, "闂備胶顭堢换鎴濐熆濡偐绱﹀Δ锝呭暙缁€鍌涖亜閹烘垵鈧悂顢欐繝鍥ㄥ仯閻庯綆浜滈弳娆忊攽?, "闂備胶顭堢换鎴濐熆濡偐绱﹂柟顖嗗苯鏅犻梺璺ㄥ枔婵吀绨洪梻浣搞偢閺呮煡宕￠崘鍙傦綁鏁冮崒姘承?%s 闂佽崵濮撮鍛村疮椤愶絾鍙忛柍鍝勬噹杩? % preferred_target.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т閸欏﹪鏌ｉ弮鈧浠嬪礂?), "EVENT")
		var occupied_system: Dictionary = {}
		for system_entry: Dictionary in next_state.get("starSystems", []):
			if system_entry.get("id", "") == orchid_fleet.get("systemId", ""):
				occupied_system = system_entry
				break
		if not occupied_system.is_empty() and occupied_system.get("ownerId", null) == null and int(next_state.get("turn", 1)) >= 5:
			var mode: String = "STANDARD" if int(occupied_system.get("habitability", 0)) >= 70 else "RESOURCE_OUTPOST"
			var mode_cost: Dictionary = colony_mode_data(mode).get("cost", COLONY_COST)
			if can_afford(orchid.get("resources", {}), mode_cost):
				next_state = start_colony_for_faction(next_state, "f_orchid", occupied_system.get("id", ""), mode, "闂備胶顭堢换鎴濐熆濡偐绱﹀Δ锝呭暙缁€鍌涖亜閹烘垵鈧悂顢欐繝鍐闁割偆鍠撴晶顒勬煟?, "闂備胶顭堢换鎴濐熆濡偐绱﹀Δ锝呭暙缁€鍌涖亜閹烘垵鈧悂顢欐繝鍕ㄥ亾閻熺増鍟炵憸鏉垮暙閿?%s 闁诲海鍋ｉ崐娑樷枍閿濆鍋熸繛鎴欏灩濡﹢鏌熷▓鍨灍闁伙綁浜跺鍫曞醇閵忊€虫畬濡炪倧绲婚崝鎴︾嵁閹达富鏁婇柟顖嗗倸瀵查梻? % occupied_system.get("name", "闂備礁鎼悧婊勭閻愮儤鍋傞柨鐔哄Т閸欏﹪鏌ｉ弮鈧浠嬪礂?))
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
	next_state = apply_player_fleet_missions(next_state)
	next_state = advance_construction_queue(next_state)
	next_state = advance_active_interventions(next_state)
	next_state = update_ascension_progress(next_state)
	if research_data.get("completedName", null) != null:
		next_state = add_message(next_state, "缂傚倷绀侀ˇ浼村垂閼稿吀绻嗙憸蹇涘焵椤掑倹鍤€闁哄牜鍓熷畷?, "%s 闂備焦妞块崰妤€顫忔繝姘厴闁圭儤鏌￠崑鎾绘偡閻楀牊鎷遍梺鎼炲妽瀹€鍛婁繆? % research_data.get("completedName", ""), "SYSTEM")
	next_state = merchant_ai_turn(next_state, merchant_decision)
	next_state = orchid_ai_turn(next_state)
	next_state = simulate_ai_backchannel(next_state)
	next_state = simulate_ai_proposals(next_state)
	next_state = append_relationship_snapshots(next_state)
	return assess_game_status(ensure_faction_controls(next_state))