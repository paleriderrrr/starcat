extends RefCounted

class_name InitialData

const MIN_PLAYER_STARTING_CAPITAL_DISTANCE: float = 16.0

static func empty_resources() -> Dictionary:
	return {"food": 0, "minerals": 0, "industry": 0, "energy": 0}

static func building_catalog() -> Array:
	return [
		{
			"type": "HABITAT",
			"name": "居住舱",
			"description": "提供基础住房与殖民稳定度，属于低门槛民生建筑。",
			"cost": {"food": 20, "minerals": 20, "industry": 0, "energy": 0},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -1},
			"production": {"food": 0, "minerals": 0, "industry": 0, "energy": 0},
			"housing": 6
		},
		{
			"type": "HYDROPONICS",
			"name": "水培农场",
			"description": "将少量矿产与能源转化为稳定食物产出。",
			"cost": {"food": 0, "minerals": 15, "industry": 0, "energy": 0},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -1},
			"production": {"food": 6, "minerals": 0, "industry": 0, "energy": 0},
			"housing": 0
		},
		{
			"type": "MINING_STATION",
			"name": "自动采矿站",
			"description": "最基础的资源建筑，优先补充矿产储备。",
			"cost": {"food": 0, "minerals": 20, "industry": 0, "energy": 0},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -1},
			"production": {"food": 0, "minerals": 6, "industry": 0, "energy": 0},
			"housing": 0
		},
		{
			"type": "INTEGRATED_FACTORY",
			"name": "集成工厂",
			"description": "将矿产冶炼为工业产能，维持运行需要稳定的矿产与能源供应。",
			"cost": {"food": 0, "minerals": 30, "industry": 0, "energy": 10},
			"maintenance": {"food": 0, "minerals": -2, "industry": 0, "energy": -2},
			"production": {"food": 0, "minerals": 0, "industry": 4, "energy": 0},
			"housing": 0
		},
		{
			"type": "FUSION_REACTOR",
			"name": "聚变反应堆",
			"description": "中期关键能源建筑，用较高矿物投入换取持续能源盈余。",
			"cost": {"food": 0, "minerals": 35, "industry": 10, "energy": 0},
			"maintenance": {"food": 0, "minerals": -1, "industry": 0, "energy": 0},
			"production": {"food": 0, "minerals": 0, "industry": 0, "energy": 6},
			"housing": 0
		},
		{
			"type": "SHIPYARD",
			"name": "太空船坞",
			"description": "允许在该星系建造舰船。",
			"cost": {"food": 0, "minerals": 55, "industry": 30, "energy": 15},
			"maintenance": {"food": 0, "minerals": -1, "industry": 0, "energy": -2},
			"production": {"food": 0, "minerals": 0, "industry": 1, "energy": 0},
			"housing": 0,
			"unlock_tech_id": "tech_shipyard"
		},
		{
			"type": "RESEARCH_LAB",
			"name": "科研实验室",
			"description": "提升研究效率，是科技路线的基础设施。",
			"cost": {"food": 0, "minerals": 30, "industry": 25, "energy": 15},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -2},
			"production": {"food": 0, "minerals": 0, "industry": 3, "energy": 0},
			"housing": 0,
			"unlock_tech_id": "tech_research_lab"
		},
		{
			"type": "DEFENSE_PLATFORM",
			"name": "轨道防御平台",
			"description": "为星系提供固定防御火力，是本地防线的重要组成部分。",
			"cost": {"food": 0, "minerals": 45, "industry": 25, "energy": 10},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -2},
			"production": {"food": 0, "minerals": 0, "industry": 0, "energy": 0},
			"housing": 0
		}
	]

static func building_turns() -> Dictionary:
	return {
		"HABITAT": 1,
		"HYDROPONICS": 1,
		"MINING_STATION": 1,
		"INTEGRATED_FACTORY": 2,
		"FUSION_REACTOR": 2,
		"SHIPYARD": 2,
		"RESEARCH_LAB": 2,
		"DEFENSE_PLATFORM": 2
	}

static func ship_turns() -> Dictionary:
	return {
		"CORVETTE": 1,
		"DESTROYER": 2,
		"CRUISER": 3,
		"BATTLESHIP": 4
	}

static func ship_labels() -> Dictionary:
	return {
		"CORVETTE": "护卫舰",
		"DESTROYER": "驱逐舰",
		"CRUISER": "巡洋舰",
		"BATTLESHIP": "战列舰"
	}

static func treaty_labels() -> Dictionary:
	return {
		"TRADE_PACT": "贸易协定",
		"NON_AGGRESSION": "互不侵犯条约",
		"RESEARCH_ACCORD": "科研合作协定",
		"ALLIANCE": "共同防御同盟",
		"WAR_STATE": "战争状态",
		"PEACE_TREATY": "和平条约"
	}

static func fleet_mission_labels() -> Dictionary:
	return {
		"IDLE": "待命",
		"EXPLORE": "自动探索",
		"COLONIZE": "殖民部署",
		"GUARD": "驻防警戒",
		"STRIKE": "前线打击"
	}

static func colonization_modes() -> Dictionary:
	return {
		"STANDARD": {
			"name": "标准殖民",
			"description": "均衡的常规殖民方案，适合大多数中立星系。",
			"cost": {"food": 60, "minerals": 50, "industry": 40, "energy": 20},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -2},
			"turns": 3,
			"initial_population": 70,
			"initial_stability": 52,
			"initial_supply": 68,
			"slot_cap": 2,
			"growth_bonus": 0.0,
			"risk": "中"
		},
		"RESOURCE_OUTPOST": {
			"name": "资源前哨",
			"description": "以快速控矿和抢占资源为目标，成熟较快但人口偏低。",
			"cost": {"food": 45, "minerals": 65, "industry": 35, "energy": 20},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -1},
			"turns": 2,
			"initial_population": 50,
			"initial_stability": 46,
			"initial_supply": 62,
			"slot_cap": 2,
			"growth_bonus": 0.12,
			"risk": "中高"
		},
		"CORE_WORLD": {
			"name": "核心殖民",
			"description": "投入更高，但成熟后拥有最好的长期发展空间。",
			"cost": {"food": 85, "minerals": 70, "industry": 65, "energy": 30},
			"maintenance": {"food": 0, "minerals": -1, "industry": 0, "energy": -3},
			"turns": 4,
			"initial_population": 90,
			"initial_stability": 58,
			"initial_supply": 76,
			"slot_cap": 3,
			"growth_bonus": -0.08,
			"risk": "低"
		},
		"MILITARY_FRONTIER": {
			"name": "军事拓殖",
			"description": "以前线据点为核心，稳定度一般但利于边境控制。",
			"cost": {"food": 55, "minerals": 60, "industry": 55, "energy": 28},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -3},
			"turns": 3,
			"initial_population": 60,
			"initial_stability": 48,
			"initial_supply": 72,
			"slot_cap": 2,
			"growth_bonus": 0.0,
			"risk": "高"
		}
	}

static func default_diplomatic_profile(archetype: String, preferred_visibility: String, public_persona: String, private_agenda: String) -> Dictionary:
	return {
		"archetype": archetype,
		"preferredVisibility": preferred_visibility,
		"publicPersona": public_persona,
		"privateAgenda": private_agenda,
		"recentTone": "neutral",
		"trustBias": 0,
		"lastUpdatedTurn": 1,
	}

static func _cat_ship_paths(slug: String) -> Dictionary:
	var path: String = "res://assets/factions/cats/ships/%s.png" % slug
	return {
		"CORVETTE": path,
		"DESTROYER": path,
		"CRUISER": path,
		"BATTLESHIP": path
	}

static func civilization_visual_bundle(visual_id: String) -> Dictionary:
	var bundles: Dictionary = {
		"russian_blue_command": {
			"visualId": "russian_blue_command",
			"portraitPath": "res://assets/factions/cats/portraits/russian_blue_command.png",
			"emblemPath": "res://assets/factions/cats/emblems/russian_blue_command.png",
			"catalogShipPath": "res://assets/factions/cats/ships/russian_blue_command.png",
			"shipArtPaths": _cat_ship_paths("russian_blue_command"),
			"visualSummary": "冷静旗舰系，擅长稳定指挥与远程统筹。"
		},
		"ragdoll_diplomatic": {
			"visualId": "ragdoll_diplomatic",
			"portraitPath": "res://assets/factions/cats/portraits/ragdoll_diplomatic.png",
			"emblemPath": "res://assets/factions/cats/emblems/ragdoll_diplomatic.png",
			"catalogShipPath": "res://assets/factions/cats/ships/ragdoll_diplomatic.png",
			"shipArtPaths": _cat_ship_paths("ragdoll_diplomatic"),
			"visualSummary": "柔和协约系，偏好中继网络与条约秩序。"
		},
		"bengal_tactical": {
			"visualId": "bengal_tactical",
			"portraitPath": "res://assets/factions/cats/portraits/bengal_tactical.png",
			"emblemPath": "res://assets/factions/cats/emblems/bengal_tactical.png",
			"catalogShipPath": "res://assets/factions/cats/ships/bengal_tactical.png",
			"shipArtPaths": _cat_ship_paths("bengal_tactical"),
			"visualSummary": "高压突击系，强调先手压制与边境推进。"
		},
		"maine_coon_imperial": {
			"visualId": "maine_coon_imperial",
			"portraitPath": "res://assets/factions/cats/portraits/maine_coon_imperial.png",
			"emblemPath": "res://assets/factions/cats/emblems/maine_coon_imperial.png",
			"catalogShipPath": "res://assets/factions/cats/ships/maine_coon_imperial.png",
			"shipArtPaths": _cat_ship_paths("maine_coon_imperial"),
			"visualSummary": "厚重王权系，以大型主力舰与等级秩序见长。"
		},
		"black_cat_stealth": {
			"visualId": "black_cat_stealth",
			"portraitPath": "res://assets/factions/cats/portraits/black_cat_stealth.png",
			"emblemPath": "res://assets/factions/cats/emblems/black_cat_stealth.png",
			"catalogShipPath": "res://assets/factions/cats/ships/black_cat_stealth.png",
			"shipArtPaths": _cat_ship_paths("black_cat_stealth"),
			"visualSummary": "隐秘渗透系，重视情报、伏击与精确切入。"
		},
		"orange_tabby_industrial": {
			"visualId": "orange_tabby_industrial",
			"portraitPath": "res://assets/factions/cats/portraits/orange_tabby_industrial.png",
			"emblemPath": "res://assets/factions/cats/emblems/orange_tabby_industrial.png",
			"catalogShipPath": "res://assets/factions/cats/ships/orange_tabby_industrial.png",
			"shipArtPaths": _cat_ship_paths("orange_tabby_industrial"),
			"visualSummary": "工业后勤系，依赖稳定产线与舰队补给能力。"
		}
	}
	return bundles.get(visual_id, {})

static func civilization_pool() -> Array:
	return [
		{
			"template_id": "blue_command",
			"name": "蓝棱司令部",
			"leaderName": "霜瞳司令",
			"type": "STRATEGIC_COMMAND",
			"color": "3DA9FC",
			"personality": {"aggression": 4.0, "paranoia": 5.0, "greed": 4.0, "loyalty": 7.0, "rationality": 9.0},
			"resourceBias": {"food": 230, "minerals": 210, "industry": 180, "energy": 180},
			"resourceRates": {"food": 4, "minerals": 1, "industry": 1, "energy": -1},
			"population": 300,
			"militaryPower": 92,
			"technologyLevel": 1,
			"diplomaticArchetype": "CAT_SCIENCE",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "理性、克制、重视协作",
			"privateAgenda": "优先建立安全缓冲与科研优势",
			"behaviorTags": ["science", "command", "balanced_response"],
			"victoryFocus": "SCIENCE",
			"visualId": "russian_blue_command"
		},
		{
			"template_id": "ragdoll_accord",
			"name": "白绒议约",
			"leaderName": "澄瞳议长",
			"type": "DIPLOMATIC_LEAGUE",
			"color": "6CD6C3",
			"personality": {"aggression": 2.0, "paranoia": 6.0, "greed": 4.0, "loyalty": 8.0, "rationality": 8.0},
			"resourceBias": {"food": 210, "minerals": 180, "industry": 160, "energy": 170},
			"resourceRates": {"food": 2, "minerals": 2, "industry": 3, "energy": 1},
			"population": 210,
			"militaryPower": 72,
			"technologyLevel": 1,
			"diplomaticArchetype": "RAGDOLL_MEDIATOR",
			"preferredVisibility": "ENCRYPTED",
			"publicPersona": "正式、克制、偏好条约秩序",
			"privateAgenda": "避免战争失控并寻求平衡各方",
			"behaviorTags": ["diplomacy", "mediation", "defense"],
			"victoryFocus": "DIPLOMACY",
			"visualId": "ragdoll_diplomatic"
		},
		{
			"template_id": "bengal_spear",
			"name": "斑曜战线",
			"leaderName": "烬爪统帅",
			"type": "MILITARY_HEGEMONY",
			"color": "E53170",
			"personality": {"aggression": 8.0, "paranoia": 6.0, "greed": 4.0, "loyalty": 7.0, "rationality": 5.0},
			"resourceBias": {"food": 180, "minerals": 230, "industry": 190, "energy": 130},
			"resourceRates": {"food": 1, "minerals": 4, "industry": 3, "energy": -1},
			"population": 240,
			"militaryPower": 96,
			"technologyLevel": 1,
			"diplomaticArchetype": "BENGAL_SPEARHEAD",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "强硬、直白、崇尚先手优势",
			"privateAgenda": "通过高压部署夺取边境主导权",
			"behaviorTags": ["military", "expansion", "ultimatum"],
			"victoryFocus": "DOMINATION",
			"visualId": "bengal_tactical"
		},
		{
			"template_id": "maine_crown",
			"name": "王冠重庭",
			"leaderName": "金鬃摄政",
			"type": "IMPERIAL_COURT",
			"color": "D4B26A",
			"personality": {"aggression": 6.0, "paranoia": 5.0, "greed": 4.0, "loyalty": 9.0, "rationality": 7.0},
			"resourceBias": {"food": 200, "minerals": 210, "industry": 210, "energy": 150},
			"resourceRates": {"food": 1, "minerals": 3, "industry": 4, "energy": 0},
			"population": 260,
			"militaryPower": 100,
			"technologyLevel": 1,
			"diplomaticArchetype": "IMPERIAL_REGENT",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "威严、守序、强调等级与荣誉",
			"privateAgenda": "以主力舰与古老权威重建区域秩序",
			"behaviorTags": ["imperial", "capital_ships", "honor"],
			"victoryFocus": "DOMINATION",
			"visualId": "maine_coon_imperial"
		},
		{
			"template_id": "black_veil",
			"name": "夜幕潜群",
			"leaderName": "深瞳监察者",
			"type": "STEALTH_DIRECTORATE",
			"color": "3A86FF",
			"personality": {"aggression": 4.0, "paranoia": 9.0, "greed": 5.0, "loyalty": 5.0, "rationality": 9.0},
			"resourceBias": {"food": 160, "minerals": 160, "industry": 150, "energy": 220},
			"resourceRates": {"food": -1, "minerals": 1, "industry": 1, "energy": 4},
			"population": 180,
			"militaryPower": 72,
			"technologyLevel": 1,
			"diplomaticArchetype": "BLACK_VEIL",
			"preferredVisibility": "SECRET",
			"publicPersona": "安静、礼貌、极少暴露真实意图",
			"privateAgenda": "通过情报渗透与快速突袭锁定关键节点",
			"behaviorTags": ["stealth", "intelligence", "sabotage"],
			"victoryFocus": "SCIENCE",
			"visualId": "black_cat_stealth"
		},
		{
			"template_id": "orange_ring",
			"name": "齿轮橘环",
			"leaderName": "铜须总管",
			"type": "INDUSTRIAL_RING",
			"color": "F28C38",
			"personality": {"aggression": 3.0, "paranoia": 6.0, "greed": 8.0, "loyalty": 6.0, "rationality": 8.0},
			"resourceBias": {"food": 220, "minerals": 240, "industry": 210, "energy": 150},
			"resourceRates": {"food": 0, "minerals": 5, "industry": 2, "energy": -1},
			"population": 220,
			"militaryPower": 82,
			"technologyLevel": 1,
			"diplomaticArchetype": "INDUSTRIAL_QUARTERMASTER",
			"preferredVisibility": "RESTRICTED",
			"publicPersona": "务实、耐心、重视产线与成交效率",
			"privateAgenda": "通过物流与工业产能掌握边境贸易节奏",
			"behaviorTags": ["trade", "industry", "logistics"],
			"victoryFocus": "ECONOMY",
			"visualId": "orange_tabby_industrial"
		}
	]

static func select_ai_civilization_templates() -> Array:
	var pool: Array = civilization_pool()
	return [pool[5], pool[1]]

static func default_game_setup_options() -> Dictionary:
	return {
		"player_template_id": "blue_command",
		"map_scale": "STANDARD",
		"difficulty": "STANDARD",
		"opponent_count": 3
	}

static func map_scale_presets() -> Dictionary:
	return {
		"SKIRMISH": {"system_count": 10, "hyperlane_count": 10, "max_opponents": 2, "label": "边境冲突"},
		"STANDARD": {"system_count": 18, "hyperlane_count": 22, "max_opponents": 3, "label": "标准星域"},
		"GRAND": {"system_count": 26, "hyperlane_count": 32, "max_opponents": 5, "label": "宏大星图"}
	}

static func difficulty_presets() -> Dictionary:
	return {
		"CASUAL": {"label": "休闲", "ai_resource_multiplier": 0.85, "ai_aggression_bonus": -1.5, "ai_expansion_pressure": 0.75},
		"STANDARD": {"label": "标准", "ai_resource_multiplier": 1.0, "ai_aggression_bonus": 0.0, "ai_expansion_pressure": 1.0},
		"HARD": {"label": "困难", "ai_resource_multiplier": 1.25, "ai_aggression_bonus": 1.5, "ai_expansion_pressure": 1.35}
	}

static func normalize_game_setup_options(options: Dictionary) -> Dictionary:
	var normalized: Dictionary = default_game_setup_options()
	for key: String in options.keys():
		normalized[key] = options.get(key)
	var pool: Array = civilization_pool()
	var template_ids: Array = []
	for template: Dictionary in pool:
		template_ids.append(str(template.get("template_id", "")))
	if not template_ids.has(str(normalized.get("player_template_id", ""))):
		normalized["player_template_id"] = "blue_command"
	var scales: Dictionary = map_scale_presets()
	if not scales.has(str(normalized.get("map_scale", ""))):
		normalized["map_scale"] = "STANDARD"
	var difficulties: Dictionary = difficulty_presets()
	if not difficulties.has(str(normalized.get("difficulty", ""))):
		normalized["difficulty"] = "STANDARD"
	var scale_data: Dictionary = scales.get(str(normalized.get("map_scale", "STANDARD")), scales["STANDARD"])
	var max_opponents: int = min(int(scale_data.get("max_opponents", 3)), max(1, pool.size() - 1))
	normalized["opponent_count"] = clampi(int(normalized.get("opponent_count", 3)), 1, max_opponents)
	return normalized

static func _template_by_id(template_id: String) -> Dictionary:
	for template: Dictionary in civilization_pool():
		if str(template.get("template_id", "")) == template_id:
			return template
	return civilization_pool()[0]

static func _select_ai_civilization_templates_for_setup(options: Dictionary) -> Array:
	var pool: Array = civilization_pool()
	var player_template_id: String = str(options.get("player_template_id", "blue_command"))
	var selected: Array = []
	for template: Dictionary in pool:
		if str(template.get("template_id", "")) == player_template_id:
			continue
		selected.append(template)
		if selected.size() >= int(options.get("opponent_count", 2)):
			break
	return selected

static func _apply_difficulty_to_faction(faction: Dictionary, options: Dictionary) -> Dictionary:
	var difficulty: Dictionary = difficulty_presets().get(str(options.get("difficulty", "STANDARD")), difficulty_presets()["STANDARD"])
	var multiplier: float = float(difficulty.get("ai_resource_multiplier", 1.0))
	var aggression_bonus: float = float(difficulty.get("ai_aggression_bonus", 0.0))
	var adjusted: Dictionary = faction.duplicate(true)
	var resources: Dictionary = adjusted.get("resources", {}).duplicate(true)
	for key: String in resources.keys():
		resources[key] = int(round(float(resources.get(key, 0)) * multiplier))
	adjusted["resources"] = resources
	var personality: Dictionary = adjusted.get("personality", {}).duplicate(true)
	personality["aggression"] = clampf(float(personality.get("aggression", 4.0)) + aggression_bonus, 0.0, 10.0)
	adjusted["personality"] = personality
	adjusted["aiExpansionPressure"] = float(difficulty.get("ai_expansion_pressure", 1.0))
	return adjusted

static func build_ai_faction_from_template(runtime_id: String, capital_system_id: String, template: Dictionary) -> Dictionary:
	var visual_bundle: Dictionary = civilization_visual_bundle(str(template.get("visualId", "")))
	return {
		"id": runtime_id,
		"name": template.get("name", runtime_id),
		"leaderName": template.get("leaderName", ""),
		"type": template.get("type", "AI_FACTION"),
		"capitalSystemId": capital_system_id,
		"color": Color(template.get("color", "FFFFFF")),
		"personality": template.get("personality", {}).duplicate(true),
		"controlledSystems": [capital_system_id],
		"resources": template.get("resourceBias", empty_resources()).duplicate(true),
		"resourceRates": template.get("resourceRates", empty_resources()).duplicate(true),
		"population": int(template.get("population", 200)),
		"militaryPower": int(template.get("militaryPower", 70)),
		"technologyLevel": int(template.get("technologyLevel", 1)),
		"diplomaticProfile": default_diplomatic_profile(
			template.get("diplomaticArchetype", "GENERALIST"),
			template.get("preferredVisibility", "PUBLIC"),
			template.get("publicPersona", "谨慎观察局势"),
			template.get("privateAgenda", "寻找新的战略机会")
		),
		"behaviorTags": template.get("behaviorTags", []).duplicate(true),
		"victoryFocus": template.get("victoryFocus", "BALANCED"),
		"templateId": template.get("template_id", ""),
		"visualId": visual_bundle.get("visualId", ""),
		"portraitPath": visual_bundle.get("portraitPath", ""),
		"emblemPath": visual_bundle.get("emblemPath", ""),
		"shipArtPaths": visual_bundle.get("shipArtPaths", {}),
		"catalogShipPath": visual_bundle.get("catalogShipPath", ""),
		"visualSummary": visual_bundle.get("visualSummary", ""),
		"isPlayer": false
	}

static func create_initial_state(options: Dictionary = {}) -> Dictionary:
	var setup_options: Dictionary = normalize_game_setup_options(options)
	var catalog: Array = building_catalog()
	var player_template: Dictionary = _template_by_id(str(setup_options.get("player_template_id", "blue_command")))
	var player_visual_bundle: Dictionary = civilization_visual_bundle(str(player_template.get("visualId", "")))
	var ai_templates: Array = _select_ai_civilization_templates_for_setup(setup_options)
	var merchant_faction: Dictionary = _apply_difficulty_to_faction(build_ai_faction_from_template("f_merchant", "sys_sirius", ai_templates[0]), setup_options)
	var orchid_faction: Dictionary = _apply_difficulty_to_faction(build_ai_faction_from_template("f_orchid", "sys_orion", ai_templates[1]), setup_options)
	var merchant_name: String = merchant_faction.get("name", "AI 势力")
	var orchid_name: String = orchid_faction.get("name", "AI 势力")
	var state: Dictionary = {
		"turn": 1,
		"era": "PIONEER",
		"status": "PLAYING",
		"setupOptions": setup_options.duplicate(true),
		"objective": "军事 1/3 星系 | 外交 结盟+科研协定 | 科技飞升 未启动",
		"victory_path": null,
		"ascension_progress": 0,
		"ascensionProject": {
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
		},
		"galacticCouncil": {
			"established": false,
			"speakerFactionId": "",
			"speakerTitle": "未设立",
			"charterStatus": "INACTIVE",
			"charterVotesFor": [],
			"charterVotesAgainst": [],
			"lastVoteTurn": 0
		},
		"factions": [
			{
				"id": "f_player",
				"name": player_template.get("name", "喵星文明"),
				"leaderName": player_template.get("leaderName", "喵因斯坦"),
				"type": player_template.get("type", "TECHNOLOGY_ALLIANCE"),
				"capitalSystemId": "sys_cat_home",
				"color": Color(player_template.get("color", "3DA9FC")),
				"personality": player_template.get("personality", {}).duplicate(true),
				"controlledSystems": ["sys_cat_home"],
				"resources": player_template.get("resourceBias", empty_resources()).duplicate(true),
				"resourceRates": player_template.get("resourceRates", empty_resources()).duplicate(true),
				"population": int(player_template.get("population", 300)),
				"militaryPower": int(player_template.get("militaryPower", 90)),
				"technologyLevel": int(player_template.get("technologyLevel", 1)),
				"diplomaticProfile": default_diplomatic_profile(
					player_template.get("diplomaticArchetype", "CAT_SCIENCE"),
					player_template.get("preferredVisibility", "PUBLIC"),
					player_template.get("publicPersona", "理性、克制、重视协作"),
					player_template.get("privateAgenda", "优先建立安全缓冲与科研优势")
				),
				"behaviorTags": player_template.get("behaviorTags", []).duplicate(true),
				"victoryFocus": player_template.get("victoryFocus", "SCIENCE"),
				"templateId": player_template.get("template_id", ""),
				"visualId": player_visual_bundle.get("visualId", ""),
				"portraitPath": player_visual_bundle.get("portraitPath", ""),
				"emblemPath": player_visual_bundle.get("emblemPath", ""),
				"shipArtPaths": player_visual_bundle.get("shipArtPaths", {}),
				"catalogShipPath": player_visual_bundle.get("catalogShipPath", ""),
				"visualSummary": player_visual_bundle.get("visualSummary", ""),
				"isPlayer": true
			},
			merchant_faction,
			orchid_faction
		],
		"starSystems": [
			{
				"id": "sys_cat_home",
				"name": "喵星",
				"type": "SOLAR",
				"position": Vector3(-8.0, 0.0, 1.0),
				"resources": {"food": 6, "minerals": 4, "industry": 4, "energy": 4},
				"buildingSlots": 6,
				"baseBuildingSlots": 6,
				"buildings": [_make_building("b1", catalog[0]), _make_building("b2", catalog[1])],
				"ownerId": "f_player",
				"population": 300,
				"visibilityLevel": "FULL",
				"note": "%s 的母星，拥有完善的工业与科研基础。" % str(player_template.get("name", "喵星文明")),
				"habitability": 94,
				"colonyStage": "CORE",
				"colonizationProgress": 100.0,
				"colonizationTurnsRemaining": 0,
				"colonizationMode": "CORE_WORLD",
				"colonizationRisk": "低",
				"stability": 88,
				"supplyLevel": 100,
				"migrationPull": 95
			},
			{
				"id": "sys_sirius",
				"name": "天狼星",
				"type": "BINARY",
				"position": Vector3(2.0, 0.0, -1.5),
				"resources": {"food": 3, "minerals": 7, "industry": 3, "energy": 5},
				"buildingSlots": 5,
				"baseBuildingSlots": 5,
				"buildings": [_make_building("b3", catalog[2])],
				"ownerId": "f_merchant",
				"population": 220,
				"visibilityLevel": "FULL",
				"note": "%s 的重要边贸枢纽，矿物加工能力较强。" % merchant_name,
				"habitability": 78,
				"colonyStage": "COLONY",
				"colonizationProgress": 100.0,
				"colonizationTurnsRemaining": 0,
				"colonizationMode": "STANDARD",
				"colonizationRisk": "中",
				"stability": 74,
				"supplyLevel": 88,
				"migrationPull": 68
			},
			{
				"id": "sys_vega",
				"name": "织女星",
				"type": "NEBULA",
				"position": Vector3(10.0, 0.0, 6.0),
				"resources": {"food": 2, "minerals": 2, "industry": 3, "energy": 8},
				"buildingSlots": 4,
				"baseBuildingSlots": 4,
				"buildings": [],
				"ownerId": null,
				"population": 0,
				"visibilityLevel": "PARTIAL",
				"eventType": "ANCIENT_RUINS",
				"eventResolved": false,
				"note": "星云深处漂浮着古代信标残骸，可能留下科研数据。",
				"habitability": 71,
				"colonyStage": "NONE",
				"colonizationProgress": 0.0,
				"colonizationTurnsRemaining": 0,
				"colonizationMode": "",
				"colonizationRisk": "中",
				"stability": 0,
				"supplyLevel": 0,
				"migrationPull": 42
			},
			{
				"id": "sys_polaris",
				"name": "北极星",
				"type": "STORM",
				"position": Vector3(-1.0, 0.0, 8.0),
				"resources": {"food": 4, "minerals": 3, "industry": 4, "energy": 6},
				"buildingSlots": 3,
				"baseBuildingSlots": 3,
				"buildings": [],
				"ownerId": null,
				"population": 0,
				"visibilityLevel": "HIDDEN",
				"eventType": "RICH_ASTEROIDS",
				"eventResolved": false,
				"note": "风暴带包裹着高密度小行星群，风险与收益并存。",
				"habitability": 62,
				"colonyStage": "NONE",
				"colonizationProgress": 0.0,
				"colonizationTurnsRemaining": 0,
				"colonizationMode": "",
				"colonizationRisk": "高",
				"stability": 0,
				"supplyLevel": 0,
				"migrationPull": 36
			},
			{
				"id": "sys_orion",
				"name": "参宿",
				"type": "SOLAR",
				"position": Vector3(8.5, 0.0, -7.0),
				"resources": {"food": 5, "minerals": 4, "industry": 5, "energy": 4},
				"buildingSlots": 4,
				"baseBuildingSlots": 4,
				"buildings": [_make_building("b4", catalog[0]), _make_building("b5", catalog[3])],
				"ownerId": "f_orchid",
				"population": 210,
				"visibilityLevel": "PARTIAL",
				"note": "%s 的议会驻地，擅长在战火边缘维持秩序。" % orchid_name,
				"habitability": 82,
				"colonyStage": "COLONY",
				"colonizationProgress": 100.0,
				"colonizationTurnsRemaining": 0,
				"colonizationMode": "STANDARD",
				"colonizationRisk": "低",
				"stability": 80,
				"supplyLevel": 86,
				"migrationPull": 70
			}
		],
		"hyperlanes": [
			{"id": "lane_1", "startSystemId": "sys_cat_home", "endSystemId": "sys_sirius", "type": "LANE", "traversalCost": 1, "bandwidth": 10},
			{"id": "lane_2", "startSystemId": "sys_sirius", "endSystemId": "sys_vega", "type": "WORMHOLE", "traversalCost": 1, "bandwidth": 6},
			{"id": "lane_3", "startSystemId": "sys_cat_home", "endSystemId": "sys_polaris", "type": "LANE", "traversalCost": 1, "bandwidth": 8},
			{"id": "lane_4", "startSystemId": "sys_sirius", "endSystemId": "sys_orion", "type": "LANE", "traversalCost": 1, "bandwidth": 8},
			{"id": "lane_5", "startSystemId": "sys_polaris", "endSystemId": "sys_orion", "type": "LANE", "traversalCost": 1, "bandwidth": 6}
		],
		"fleets": [
			{
				"id": "fleet_player_1",
				"ownerId": "f_player",
				"systemId": "sys_cat_home",
				"mission": "IDLE",
				"name": "第一舰队",
				"ships": [
					{"id": "ship_1", "type": "CORVETTE", "name": "小猫号", "hp": 100, "maxHp": 100, "damage": 20, "evasion": 30, "tracking": 50, "speed": 10},
					{"id": "ship_2", "type": "CORVETTE", "name": "胡须号", "hp": 100, "maxHp": 100, "damage": 20, "evasion": 30, "tracking": 50, "speed": 10}
				]
			},
			{
				"id": "fleet_enemy_1",
				"ownerId": "f_merchant",
				"systemId": "sys_sirius",
				"mission": "GUARD",
				"name": "边贸护航队",
				"ships": [
					{"id": "ship_3", "type": "CORVETTE", "name": "金币号", "hp": 100, "maxHp": 100, "damage": 18, "evasion": 28, "tracking": 48, "speed": 10},
					{"id": "ship_4", "type": "CORVETTE", "name": "商路号", "hp": 100, "maxHp": 100, "damage": 18, "evasion": 28, "tracking": 48, "speed": 10}
				]
			},
			{
				"id": "fleet_orchid_1",
				"ownerId": "f_orchid",
				"systemId": "sys_orion",
				"mission": "GUARD",
				"name": "宪章巡防队",
				"ships": [
					{"id": "ship_5", "type": "CORVETTE", "name": "宪章号", "hp": 100, "maxHp": 100, "damage": 19, "evasion": 29, "tracking": 49, "speed": 10},
					{"id": "ship_6", "type": "CORVETTE", "name": "议和号", "hp": 100, "maxHp": 100, "damage": 19, "evasion": 29, "tracking": 49, "speed": 10}
				]
			}
		],
		"relationships": [
			{
				"factionAId": "f_player",
				"factionBId": "f_merchant",
				"trust": 22,
				"utility": 35,
				"fear": 10,
				"affinity": 12,
				"memoryImpact": 0,
				"level": "NEUTRAL"
			},
			{
				"factionAId": "f_player",
				"factionBId": "f_orchid",
				"trust": 34,
				"utility": 26,
				"fear": 8,
				"affinity": 18,
				"memoryImpact": 0,
				"level": "NEUTRAL"
			},
			{
				"factionAId": "f_merchant",
				"factionBId": "f_orchid",
				"trust": 16,
				"utility": 32,
				"fear": 14,
				"affinity": 4,
				"memoryImpact": 0,
				"level": "COLD"
			}
		],
		"treaties": [
			{
				"id": "treaty_open_trade",
				"sourceFactionId": "f_player",
				"targetFactionId": "f_merchant",
				"type": "TRADE_PACT",
				"status": "ACTIVE",
				"proposedOnTurn": 1,
				"expiresOnTurn": null,
				"summary": "双方维持有限贸易走廊，民用货运尚未中断。"
			}
		],
		"technologies": _technology_nodes(),
		"currentResearchId": null,
		"researchProgress": 0.0,
		"constructionQueue": [],
		"activeNarrativeEvents": [],
		"activeInterventions": [],
		"combatReports": [],
		"relationshipHistory": [
			{"turn": 1, "factionAId": "f_player", "factionBId": "f_merchant", "trust": 22, "utility": 35, "fear": 10, "affinity": 12, "memoryImpact": 0, "level": "NEUTRAL"},
			{"turn": 1, "factionAId": "f_player", "factionBId": "f_orchid", "trust": 34, "utility": 26, "fear": 8, "affinity": 18, "memoryImpact": 0, "level": "NEUTRAL"},
			{"turn": 1, "factionAId": "f_merchant", "factionBId": "f_orchid", "trust": 16, "utility": 32, "fear": 14, "affinity": 4, "memoryImpact": 0, "level": "COLD"}
		],
		"pendingProposals": [],
		"recentInteractionMemory": [
			{
				"id": "imem_1",
				"turn": 1,
				"title": "边境秩序通告",
				"summary": "%s 向周边文明发送公开通告，要求在新航道附近保持克制。" % orchid_name,
				"participants": ["f_player", "f_orchid", "f_merchant"],
				"category": "PUBLIC",
				"importance": 2,
				"semantic_keywords": ["边境", "秩序", "通告", orchid_name, "公开"],
				"emotionalImpact": 0.18,
				"decayFactor": 0.98
			}
		],
		"archivedInteractionMemory": [
			{
				"id": "ltm_1",
				"turn": 1,
				"title": "边境秩序通告归档",
				"summary": "%s 在早期通过公开通告塑造了谨慎的边境秩序预期。" % orchid_name,
				"participants": ["f_player", "f_orchid", "f_merchant"],
				"category": "PUBLIC",
				"importance": 2,
				"semantic_keywords": ["边境", "秩序", "通告", "谨慎", "公开"],
				"emotionalImpact": 0.14,
				"decayFactor": 0.98
			}
		],
		"messages": [
			{
				"id": "msg_1",
				"title": "欢迎来到喵星文明",
				"content": "星图指挥系统已经就绪，科技、外交、建造与舰队调度均可正常运转。本局与你对峙的主要势力为 %s 与 %s。" % [merchant_name, orchid_name],
				"turn": 1,
				"type": "SYSTEM"
			}
		],
		"diplomaticMessages": [
			{
				"id": "dmsg_1",
				"turn": 1,
				"senderId": "f_orchid",
				"senderName": orchid_name,
				"targetType": "BROADCAST",
				"targetIds": ["f_player", "f_merchant"],
				"visibilityLevel": "PUBLIC",
				"contentType": "NOTIFICATION",
				"title": "边境秩序通告",
				"content": "%s 呼吁各方在新航道附近保持克制，避免误判升级。" % orchid_name,
				"summary": "公开秩序声明",
				"visibleToPlayer": true
			}
		],
		"diplomaticMemories": [
			{
				"id": "dmem_1",
				"turn": 1,
				"title": "边境秩序通告",
				"summary": "%s 要求周边文明在新航道周围保持克制。" % orchid_name,
				"participants": ["f_player", "f_orchid", "f_merchant"],
				"category": "PUBLIC",
				"importance": 2
			}
		]
	}
	return _finalize_configured_initial_state(state, setup_options, catalog, ai_templates)

static func _make_building(building_id: String, blueprint: Dictionary) -> Dictionary:
	var entry: Dictionary = blueprint.duplicate(true)
	entry["id"] = building_id
	return entry

static func _finalize_configured_initial_state(state: Dictionary, options: Dictionary, catalog: Array, ai_templates: Array) -> Dictionary:
	state["starSystems"] = _build_configured_star_systems(state.get("starSystems", []), options, catalog)
	state["hyperlanes"] = _build_configured_hyperlanes(state.get("hyperlanes", []), options, state.get("starSystems", []))
	var configured: Dictionary = _build_configured_ai_factions(state, options, ai_templates)
	state["factions"] = configured.get("factions", state.get("factions", []))
	state["fleets"] = configured.get("fleets", state.get("fleets", []))
	state["relationships"] = _build_configured_relationships(state.get("factions", []))
	state["relationshipHistory"] = _initial_relationship_history(state.get("relationships", []))
	state["aiActionLog"] = []
	return state

static func _base_system(system_id: String, name: String, system_type: String, position: Vector3, resources: Dictionary, slots: int, visibility: String, event_type: String, note: String, habitability: int) -> Dictionary:
	return {
		"id": system_id,
		"name": name,
		"type": system_type,
		"position": position,
		"resources": resources,
		"buildingSlots": slots,
		"baseBuildingSlots": slots,
		"buildings": [],
		"ownerId": null,
		"population": 0,
		"visibilityLevel": visibility,
		"eventType": event_type,
		"eventResolved": false,
		"note": note,
		"habitability": habitability,
		"colonyStage": "NONE",
		"colonizationProgress": 0.0,
		"colonizationTurnsRemaining": 0,
		"colonizationMode": "",
		"colonizationRisk": "中",
		"stability": 0,
		"supplyLevel": 0,
		"migrationPull": clampi(habitability - 28, 22, 76)
	}

static func _configured_system_id_order(target_count: int) -> Array[String]:
	var ordered_ids: Array[String] = [
		"sys_cat_home",
		"sys_sirius",
		"sys_vega",
		"sys_polaris",
		"sys_orion",
		"sys_lyra",
		"sys_cygnus",
		"sys_draco",
		"sys_mira",
		"sys_antares",
		"sys_hydra",
		"sys_pegasus",
		"sys_cassiopeia"
	]
	while ordered_ids.size() < target_count:
		ordered_ids.append("sys_outer_%02d" % (ordered_ids.size() - 12))
	return ordered_ids.slice(0, target_count)

static func _procedural_outer_system(index: int) -> Dictionary:
	var names: Array[String] = [
		"鲸背静湾", "灰烬窗", "折跃盐桥", "晨星栈道", "银梭暗井", "远炬环",
		"鸢尾岔口", "雾冠门", "碎晶台", "北冕堤", "蓝砂港", "白昼沟",
		"赤纬站", "幽弦井", "暮潮环", "镜湖尖", "铁雨港", "星穗坞"
	]
	var types: Array[String] = ["SOLAR", "NEBULA", "BINARY", "STORM"]
	var events: Array[String] = ["DERELICT_STATION", "RICH_ASTEROIDS", "ANCIENT_RUINS", "ENERGY_ANOMALY"]
	var angle: float = (float(index) * 137.5 + 18.0) * PI / 180.0
	var radius: float = 20.0 + float(index % 4) * 2.6
	var resources: Dictionary = {
		"food": 2 + ((index * 3) % 5),
		"minerals": 2 + ((index * 5 + 1) % 8),
		"industry": 2 + ((index * 7 + 2) % 5),
		"energy": 2 + ((index * 11 + 3) % 7)
	}
	return _base_system(
		"sys_outer_%02d" % (index + 1),
		str(names[index % names.size()]),
		str(types[index % types.size()]),
		Vector3(cos(angle) * radius, 0.0, sin(angle) * radius),
		resources,
		3 + (index % 3),
		"HIDDEN",
		str(events[index % events.size()]),
		"远环自动星图补全节点，适合在中后期扩张中形成新的侧翼战线。",
		54 + ((index * 7) % 27)
	)

static func _build_configured_star_systems(base_systems: Array, options: Dictionary, catalog: Array) -> Array:
	var systems: Array = base_systems.duplicate(true)
	var scale: String = str(options.get("map_scale", "STANDARD"))
	var extra_systems: Array = [
		_base_system("sys_lyra", "天琴门", "SOLAR", Vector3(-13.0, 0.0, 9.0), {"food": 4, "minerals": 5, "industry": 3, "energy": 4}, 4, "PARTIAL", "DERELICT_STATION", "外缘信标仍在低功率广播，适合建立补给链。", 68),
		_base_system("sys_cygnus", "天鹅湾", "BINARY", Vector3(-3.5, 0.0, 15.0), {"food": 6, "minerals": 2, "industry": 3, "energy": 5}, 4, "HIDDEN", "RICH_ASTEROIDS", "航道尽头的富集尘带包围着宜居卫星。", 74),
		_base_system("sys_draco", "龙脊", "STORM", Vector3(7.0, 0.0, 13.0), {"food": 2, "minerals": 8, "industry": 5, "energy": 3}, 5, "HIDDEN", "ANCIENT_RUINS", "风暴间隙中可见古代船坞轮廓。", 58),
		_base_system("sys_mira", "米拉潮汐", "NEBULA", Vector3(14.0, 0.0, 1.5), {"food": 3, "minerals": 3, "industry": 4, "energy": 8}, 4, "HIDDEN", "ENERGY_ANOMALY", "周期性脉冲让这里成为危险但丰厚的能源节点。", 61),
		_base_system("sys_antares", "心宿熔炉", "BINARY", Vector3(13.0, 0.0, -11.0), {"food": 1, "minerals": 9, "industry": 6, "energy": 2}, 5, "HIDDEN", "RICH_ASTEROIDS", "高温矿脉适合重工业文明长期经营。", 52),
		_base_system("sys_hydra", "长蛇暗湾", "NEBULA", Vector3(-12.5, 0.0, -9.0), {"food": 5, "minerals": 3, "industry": 2, "energy": 6}, 4, "HIDDEN", "ANCIENT_RUINS", "星云遮蔽了多条隐秘支线，是潜航者的理想跳板。", 64),
		_base_system("sys_pegasus", "飞马桥", "SOLAR", Vector3(1.0, 0.0, -14.0), {"food": 4, "minerals": 4, "industry": 5, "energy": 4}, 5, "HIDDEN", "DERELICT_STATION", "旧时代桥头堡仍保留大型居住结构。", 77),
		_base_system("sys_cassiopeia", "仙后冠", "SOLAR", Vector3(-18.0, 0.0, -1.5), {"food": 6, "minerals": 5, "industry": 4, "energy": 3}, 5, "HIDDEN", "RICH_ASTEROIDS", "外环带资源丰厚，但距离主航线较远。", 72)
	]
	var target_count: int = int(map_scale_presets().get(scale, map_scale_presets()["STANDARD"]).get("system_count", 9))
	for system: Dictionary in extra_systems:
		if systems.size() >= target_count:
			break
		systems.append(system)
	var procedural_index: int = 0
	while systems.size() < target_count:
		systems.append(_procedural_outer_system(procedural_index))
		procedural_index += 1
	for index: int in range(systems.size()):
		var system: Dictionary = systems[index]
		if _is_ai_runtime_id(str(system.get("ownerId", ""))):
			system["ownerId"] = null
			system["population"] = 0
			system["visibilityLevel"] = "HIDDEN"
			system["colonyStage"] = "NONE"
			system["colonizationProgress"] = 0.0
			system["colonizationTurnsRemaining"] = 0
			system["colonizationMode"] = ""
			system["stability"] = 0
			system["supplyLevel"] = 0
			system["buildings"] = []
			systems[index] = system
	var runtime_ids: Array[String] = _ai_runtime_ids()
	var capital_ids: Array[String] = _spaced_ai_capital_ids(systems, int(options.get("opponent_count", 2)))
	for capital_index: int in range(min(runtime_ids.size(), capital_ids.size())):
		var faction_id: String = str(runtime_ids[capital_index])
		var capital_id: String = str(capital_ids[capital_index])
		for system_index: int in range(systems.size()):
			var system: Dictionary = systems[system_index]
			if str(system.get("id", "")) != capital_id:
				continue
			system["ownerId"] = faction_id
			system["population"] = 190
			system["visibilityLevel"] = "PARTIAL"
			system["colonyStage"] = "COLONY"
			system["colonizationProgress"] = 100.0
			system["colonizationTurnsRemaining"] = 0
			system["colonizationMode"] = "STANDARD"
			system["stability"] = 70
			system["supplyLevel"] = 84
			system["buildings"] = [_make_building("b_%s_habitat" % capital_id, catalog[0])]
			systems[system_index] = system
	return systems

static func _build_configured_hyperlanes(base_hyperlanes: Array, options: Dictionary, systems: Array = []) -> Array:
	var lanes: Array = base_hyperlanes.duplicate(true)
	var scale: String = str(options.get("map_scale", "STANDARD"))
	var target_system_count: int = int(map_scale_presets().get(scale, map_scale_presets()["STANDARD"]).get("system_count", 18))
	var extra_lanes: Array = [
		{"id": "lane_6", "startSystemId": "sys_cat_home", "endSystemId": "sys_lyra", "type": "LANE", "traversalCost": 1, "bandwidth": 8},
		{"id": "lane_7", "startSystemId": "sys_lyra", "endSystemId": "sys_cygnus", "type": "LANE", "traversalCost": 1, "bandwidth": 7},
		{"id": "lane_8", "startSystemId": "sys_cygnus", "endSystemId": "sys_polaris", "type": "LANE", "traversalCost": 1, "bandwidth": 7},
		{"id": "lane_9", "startSystemId": "sys_polaris", "endSystemId": "sys_draco", "type": "LANE", "traversalCost": 1, "bandwidth": 7},
		{"id": "lane_10", "startSystemId": "sys_draco", "endSystemId": "sys_mira", "type": "WORMHOLE", "traversalCost": 1, "bandwidth": 5},
		{"id": "lane_11", "startSystemId": "sys_mira", "endSystemId": "sys_orion", "type": "LANE", "traversalCost": 1, "bandwidth": 8},
		{"id": "lane_12", "startSystemId": "sys_orion", "endSystemId": "sys_antares", "type": "LANE", "traversalCost": 1, "bandwidth": 8},
		{"id": "lane_13", "startSystemId": "sys_antares", "endSystemId": "sys_pegasus", "type": "LANE", "traversalCost": 1, "bandwidth": 7},
		{"id": "lane_14", "startSystemId": "sys_pegasus", "endSystemId": "sys_sirius", "type": "LANE", "traversalCost": 1, "bandwidth": 7},
		{"id": "lane_15", "startSystemId": "sys_sirius", "endSystemId": "sys_hydra", "type": "WORMHOLE", "traversalCost": 1, "bandwidth": 5},
		{"id": "lane_16", "startSystemId": "sys_hydra", "endSystemId": "sys_cassiopeia", "type": "LANE", "traversalCost": 1, "bandwidth": 7}
	]
	var target_count: int = int(map_scale_presets().get(scale, map_scale_presets()["STANDARD"]).get("hyperlane_count", 11))
	for lane: Dictionary in extra_lanes:
		if lanes.size() >= target_count:
			break
		lanes.append(lane)
	var system_ids: Array[String] = _configured_system_id_order(target_system_count)
	var lane_index: int = 17
	var candidates: Array = _sorted_nearby_lane_candidates(system_ids, systems, lanes)
	var cursor: int = 0
	while lanes.size() < target_count and cursor < candidates.size():
		var candidate: Dictionary = candidates[cursor]
		var start_id: String = str(candidate.get("start_id", ""))
		var end_id: String = str(candidate.get("end_id", ""))
		if start_id != end_id and not _lane_exists(lanes, start_id, end_id):
			lanes.append(_build_procedural_hyperlane(lane_index, start_id, end_id, cursor, float(candidate.get("distance_score", 0.0))))
			lane_index += 1
		cursor += 1
	return lanes

static func _sorted_nearby_lane_candidates(system_ids: Array[String], systems: Array, existing_lanes: Array) -> Array:
	var positions: Dictionary = _system_position_lookup(systems)
	var candidates: Array = []
	for start_index: int in range(system_ids.size()):
		var start_id: String = str(system_ids[start_index])
		for end_index: int in range(start_index + 1, system_ids.size()):
			var end_id: String = str(system_ids[end_index])
			if _lane_exists(existing_lanes, start_id, end_id):
				continue
			candidates.append({
				"start_id": start_id,
				"end_id": end_id,
				"distance_score": _lane_distance_score(positions, start_id, end_id),
				"ring_gap": abs(start_index - end_index)
			})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var distance_a: float = float(a.get("distance_score", 0.0))
		var distance_b: float = float(b.get("distance_score", 0.0))
		if not is_equal_approx(distance_a, distance_b):
			return distance_a < distance_b
		return int(a.get("ring_gap", 0)) < int(b.get("ring_gap", 0))
	)
	return candidates

static func _system_position_lookup(systems: Array) -> Dictionary:
	var positions: Dictionary = {}
	for system: Dictionary in systems:
		positions[str(system.get("id", ""))] = system.get("position", Vector3.ZERO)
	return positions

static func _ai_runtime_ids() -> Array[String]:
	return ["f_merchant", "f_orchid", "f_ai_3", "f_ai_4", "f_ai_5"]

static func _preferred_ai_capital_ids() -> Array[String]:
	return ["sys_draco", "sys_orion", "sys_pegasus", "sys_mira", "sys_antares"]

static func _is_ai_runtime_id(faction_id: String) -> bool:
	return _ai_runtime_ids().has(faction_id)

static func _spaced_ai_capital_ids(systems: Array, opponent_count: int) -> Array[String]:
	var positions: Dictionary = _system_position_lookup(systems)
	var player_position: Vector3 = positions.get("sys_cat_home", Vector3.ZERO)
	var selected: Array[String] = []
	for candidate_id: String in _preferred_ai_capital_ids():
		if selected.size() >= opponent_count:
			break
		if not positions.has(candidate_id):
			continue
		var candidate_position: Vector3 = positions.get(candidate_id, Vector3.ZERO)
		if player_position.distance_to(candidate_position) >= MIN_PLAYER_STARTING_CAPITAL_DISTANCE:
			selected.append(candidate_id)
	for candidate_id: String in _preferred_ai_capital_ids():
		if selected.size() >= opponent_count:
			break
		if positions.has(candidate_id) and not selected.has(candidate_id):
			selected.append(candidate_id)
	return selected

static func _lane_distance_score(positions: Dictionary, start_id: String, end_id: String) -> float:
	var start_position: Vector3 = positions.get(start_id, Vector3.ZERO)
	var end_position: Vector3 = positions.get(end_id, Vector3.ZERO)
	var distance_squared: float = start_position.distance_squared_to(end_position)
	if distance_squared > 360.0:
		distance_squared *= 2.4
	return distance_squared

static func _lane_exists(lanes: Array, start_id: String, end_id: String) -> bool:
	for lane: Dictionary in lanes:
		var lane_start: String = str(lane.get("startSystemId", ""))
		var lane_end: String = str(lane.get("endSystemId", ""))
		if (lane_start == start_id and lane_end == end_id) or (lane_start == end_id and lane_end == start_id):
			return true
	return false

static func _build_procedural_hyperlane(lane_index: int, start_id: String, end_id: String, cursor: int, distance_score: float = 0.0) -> Dictionary:
	return {
		"id": "lane_%s" % str(lane_index),
		"startSystemId": start_id,
		"endSystemId": end_id,
		"type": "LANE",
		"traversalCost": 2 if distance_score > 520.0 else 1,
		"bandwidth": 5 + (cursor % 5)
	}

static func _build_configured_ai_factions(state: Dictionary, options: Dictionary, ai_templates: Array) -> Dictionary:
	var factions: Array = [state.get("factions", [])[0]]
	var fleets: Array = [state.get("fleets", [])[0]]
	var runtime_ids: Array[String] = _ai_runtime_ids()
	var capital_ids: Array[String] = _spaced_ai_capital_ids(state.get("starSystems", []), int(options.get("opponent_count", 2)))
	for index: int in range(min(ai_templates.size(), int(options.get("opponent_count", 2)))):
		var faction: Dictionary = _apply_difficulty_to_faction(build_ai_faction_from_template(str(runtime_ids[index]), str(capital_ids[index]), ai_templates[index]), options)
		factions.append(faction)
		fleets.append(_make_ai_fleet(index, str(runtime_ids[index]), str(capital_ids[index]), str(faction.get("leaderName", ""))))
	return {"factions": factions, "fleets": fleets}

static func _make_ai_fleet(index: int, faction_id: String, system_id: String, leader_name: String) -> Dictionary:
	var ship_number: int = 10 + index * 2
	return {
		"id": "fleet_ai_%s" % str(index + 1),
		"ownerId": faction_id,
		"systemId": system_id,
		"mission": "GUARD",
		"name": "%s 星防队" % leader_name,
		"ships": [
			{"id": "ship_ai_%s_a" % ship_number, "type": "CORVETTE", "name": "前锋%s" % ship_number, "hp": 100, "maxHp": 100, "damage": 18 + index, "evasion": 28, "tracking": 48, "speed": 10},
			{"id": "ship_ai_%s_b" % ship_number, "type": "CORVETTE", "name": "护航%s" % ship_number, "hp": 100, "maxHp": 100, "damage": 18 + index, "evasion": 28, "tracking": 48, "speed": 10}
		]
	}

static func _build_configured_relationships(factions: Array) -> Array:
	var relationships: Array = []
	for i: int in range(factions.size()):
		for j: int in range(i + 1, factions.size()):
			var a: Dictionary = factions[i]
			var b: Dictionary = factions[j]
			relationships.append({
				"factionAId": a.get("id", ""),
				"factionBId": b.get("id", ""),
				"trust": 30 if bool(a.get("isPlayer", false)) else 20,
				"utility": 30,
				"fear": 10,
				"affinity": 12,
				"memoryImpact": 0,
				"level": "NEUTRAL"
			})
	return relationships

static func _initial_relationship_history(relationships: Array) -> Array:
	var history: Array = []
	for relation: Dictionary in relationships:
		var entry: Dictionary = relation.duplicate(true)
		entry["turn"] = 1
		history.append(entry)
	return history

static func _technology_nodes() -> Array:
	return [
		{"id": "tech_trade_net", "name": "贸易网络", "tier": 1, "category": "ECONOMY", "description": "建立基础商路协定，提升星系间物流效率。", "effects": ["每个已控星系 +2 能源", "商路矿产 +1"], "unlocks": ["星际礼制协议"], "status": "AVAILABLE", "cost": 80, "researchTime": 2, "progress": 0.0},
		{"id": "tech_shipyard", "name": "太空船坞", "tier": 1, "category": "MILITARY", "description": "解锁基础船坞建设与舰船标准化生产。", "effects": ["解锁太空船坞", "新造舰船 +15 生命 / +1 速度"], "unlocks": ["驱逐舰船体", "舰队后勤"], "status": "AVAILABLE", "cost": 80, "researchTime": 2, "progress": 0.0},
		{"id": "tech_research_lab", "name": "科研实验室", "tier": 1, "category": "SCIENCE", "description": "建立标准实验室体系，加速科研流程。", "effects": ["解锁科研实验室", "研究速度 +35%"], "unlocks": ["应用机器人", "恒星谐振工程"], "status": "AVAILABLE", "cost": 100, "researchTime": 3, "progress": 0.0},
		{"id": "tech_deep_colonization", "name": "基础深空殖民", "tier": 1, "category": "EXPANSION", "description": "解锁正式殖民行动、前哨建设与跨星系定居流程。", "effects": ["解锁正式殖民", "开放 4 类殖民方案"], "unlocks": ["扩展居住", "殖民章程"], "status": "AVAILABLE", "cost": 70, "researchTime": 2, "progress": 0.0},
		{"id": "tech_expanded_housing", "name": "扩展居住", "tier": 1, "category": "EXPANSION", "description": "提高新殖民地的初始承载人口。", "effects": ["殖民地额外 +30 人口", "前哨稳定度 +6"], "unlocks": ["殖民章程", "深空侦测"], "status": "LOCKED", "cost": 60, "researchTime": 2, "progress": 0.0, "prerequisites": ["tech_deep_colonization"]},
		{"id": "tech_diplomatic_protocols", "name": "星际礼制协议", "tier": 2, "category": "ECONOMY", "description": "确立正式条约缔结流程与外交规范。", "effects": ["解锁正式条约", "条约接受判定 +25 信任权重"], "unlocks": ["自动装配线", "联邦议会"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_trade_net"]},
		{"id": "tech_destroyer_hulls", "name": "驱逐舰船体", "tier": 2, "category": "MILITARY", "description": "扩展护航舰船至中型战舰标准。", "effects": ["解锁驱逐舰建造"], "unlocks": ["巡洋舰学说", "舰队后勤"], "status": "LOCKED", "cost": 140, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_shipyard"]},
		{"id": "tech_fleet_logistics", "name": "舰队后勤", "tier": 2, "category": "MILITARY", "description": "改善舰队补给效率与维修流程。", "effects": ["解锁战术指挥核心前置体系", "舰队整编效率 +1"], "unlocks": ["战术指挥核心"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_shipyard"]},
		{"id": "tech_applied_robotics", "name": "应用机器人", "tier": 2, "category": "SCIENCE", "description": "让自动化单元进入工业与科研岗位。", "effects": ["工业自动化 +1", "科研辅助位 +2"], "unlocks": ["量子建模"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_research_lab"]},
		{"id": "tech_colony_charter", "name": "殖民章程", "tier": 2, "category": "EXPANSION", "description": "为远星殖民制定统一治理范本。", "effects": ["殖民成长系数 +0.25", "殖民地稳定度 +2"], "unlocks": ["地貌改造"], "status": "LOCKED", "cost": 100, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_deep_colonization"]},
		{"id": "tech_deep_space_scans", "name": "深空侦测", "tier": 2, "category": "EXPANSION", "description": "提升远距离星图扫描与异常信号识别能力。", "effects": ["通信截获能力 +40%", "异常信号识别 +1"], "unlocks": ["边境灯塔"], "status": "LOCKED", "cost": 110, "researchTime": 2, "progress": 0.0, "prerequisites": ["tech_expanded_housing"]},
		{"id": "tech_auto_assembly", "name": "自动装配线", "tier": 3, "category": "ECONOMY", "description": "建立矿产到工业的自动装配流程。", "effects": ["建筑队列每回合额外推进 +1", "工业装配效率 +1 级"], "unlocks": ["行星协调网"], "status": "LOCKED", "cost": 180, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_diplomatic_protocols"]},
		{"id": "tech_cruiser_doctrine", "name": "巡洋舰学说", "tier": 3, "category": "MILITARY", "description": "确立主力舰火力与编队学说。", "effects": ["解锁巡洋舰建造"], "unlocks": ["旗舰系统"], "status": "LOCKED", "cost": 220, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_destroyer_hulls", "tech_research_lab"]},
		{"id": "tech_tactical_core", "name": "战术指挥核心", "tier": 3, "category": "MILITARY", "description": "通过战术 AI 提升舰队联合作战能力。", "effects": ["舰队战术协同等级 +1", "主力舰编队伤害 +10%"], "unlocks": ["旗舰系统"], "status": "LOCKED", "cost": 210, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_destroyer_hulls", "tech_fleet_logistics"]},
		{"id": "tech_star_harmonics", "name": "恒星谐振工程", "tier": 3, "category": "SCIENCE", "description": "利用恒星谐振原理推动高阶能源与飞升技术。", "effects": ["每回合飞升进度 +10"], "unlocks": ["量子建模", "奇点格构"], "status": "LOCKED", "cost": 220, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_research_lab"]},
		{"id": "tech_terraforming", "name": "地貌改造", "tier": 3, "category": "EXPANSION", "description": "改善殖民星环境并扩大长期产能。", "effects": ["宜居度 +10", "殖民地资源开发位 +1"], "unlocks": ["边境星域长期控制"], "status": "LOCKED", "cost": 180, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_colony_charter"]},
		{"id": "tech_planetary_grid", "name": "行星协调网", "tier": 4, "category": "ECONOMY", "description": "把产业、能源、物流与治理统一进协调网络。", "effects": ["通信截获能力 +20%", "全域统筹产出 +10%"], "unlocks": ["联邦议会"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_auto_assembly", "tech_deep_space_scans"]},
		{"id": "tech_flagship_systems", "name": "旗舰系统", "tier": 4, "category": "MILITARY", "description": "重型旗舰系统为后期舰队提供绝对核心。", "effects": ["解锁战列舰建造"], "unlocks": ["战列舰"], "status": "LOCKED", "cost": 280, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_tactical_core", "tech_cruiser_doctrine"]},
		{"id": "tech_quantum_modeling", "name": "量子建模", "tier": 4, "category": "SCIENCE", "description": "用量子模拟缩短复杂工程与科研周期。", "effects": ["复杂课题研究时间 -20%", "复杂课题拆解位 +2"], "unlocks": ["奇点格构"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_applied_robotics", "tech_star_harmonics"]},
		{"id": "tech_federal_council", "name": "联邦议会", "tier": 4, "category": "ECONOMY", "description": "建立统一议会以完成跨文明协调治理。", "effects": ["银河议会成立条件解锁", "宪章表决席位 +1"], "unlocks": ["外交胜利"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_diplomatic_protocols", "tech_planetary_grid"]},
		{"id": "tech_singularity_lattice", "name": "奇点格构", "tier": 4, "category": "SCIENCE", "description": "构建飞升所需的终极物理骨架。", "effects": ["每回合飞升进度 +18"], "unlocks": ["飞升胜利"], "status": "LOCKED", "cost": 320, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_quantum_modeling", "tech_star_harmonics"]}
	]
