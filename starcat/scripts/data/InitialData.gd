extends RefCounted

class_name InitialData

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

static func civilization_pool() -> Array:
	return [
		{
			"template_id": "merchant_compact",
			"name": "商路联盟",
			"leaderName": "金须阁下",
			"type": "COMMERCIAL_FEDERATION",
			"color": "2CB67D",
			"personality": {"aggression": 3.0, "paranoia": 7.0, "greed": 8.0, "loyalty": 6.0, "rationality": 8.0},
			"resourceBias": {"food": 220, "minerals": 240, "industry": 140, "energy": 140},
			"resourceRates": {"food": 0, "minerals": 5, "industry": 0, "energy": -1},
			"population": 220,
			"militaryPower": 80,
			"technologyLevel": 1,
			"diplomaticArchetype": "MERCHANT_PRAGMATIST",
			"preferredVisibility": "SECRET",
			"publicPersona": "礼貌、精明、重视利益",
			"privateAgenda": "通过秘密交易建立边境影响力",
			"behaviorTags": ["trade", "smuggling", "commercial_pressure"],
			"victoryFocus": "ECONOMY"
		},
		{
			"template_id": "orchid_consensus",
			"name": "兰心公约",
			"leaderName": "兰枢议长",
			"type": "DIPLOMATIC_LEAGUE",
			"color": "F4B860",
			"personality": {"aggression": 2.0, "paranoia": 6.0, "greed": 4.0, "loyalty": 8.0, "rationality": 8.0},
			"resourceBias": {"food": 210, "minerals": 180, "industry": 160, "energy": 170},
			"resourceRates": {"food": 2, "minerals": 2, "industry": 3, "energy": 1},
			"population": 210,
			"militaryPower": 72,
			"technologyLevel": 1,
			"diplomaticArchetype": "ORCHID_MEDIATOR",
			"preferredVisibility": "ENCRYPTED",
			"publicPersona": "正式、克制、偏好条约秩序",
			"privateAgenda": "避免战争失控并寻求平衡各方",
			"behaviorTags": ["diplomacy", "mediation", "defense"],
			"victoryFocus": "DIPLOMACY"
		},
		{
			"template_id": "frontier_legion",
			"name": "边炬军团",
			"leaderName": "铁烬统帅",
			"type": "MILITARY_HEGEMONY",
			"color": "E53170",
			"personality": {"aggression": 8.0, "paranoia": 6.0, "greed": 4.0, "loyalty": 7.0, "rationality": 5.0},
			"resourceBias": {"food": 180, "minerals": 230, "industry": 190, "energy": 130},
			"resourceRates": {"food": 1, "minerals": 4, "industry": 3, "energy": -1},
			"population": 240,
			"militaryPower": 96,
			"technologyLevel": 1,
			"diplomaticArchetype": "FRONTIER_GENERAL",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "强硬、直白、崇尚先手优势",
			"privateAgenda": "通过高压部署夺取边境主导权",
			"behaviorTags": ["military", "expansion", "ultimatum"],
			"victoryFocus": "DOMINATION"
		},
		{
			"template_id": "helios_synod",
			"name": "赫利俄斯神议庭",
			"leaderName": "圣焰执灯者",
			"type": "THEOCRATIC_ORDER",
			"color": "FF8906",
			"personality": {"aggression": 5.0, "paranoia": 5.0, "greed": 3.0, "loyalty": 9.0, "rationality": 6.0},
			"resourceBias": {"food": 200, "minerals": 170, "industry": 150, "energy": 210},
			"resourceRates": {"food": 2, "minerals": 1, "industry": 2, "energy": 4},
			"population": 215,
			"militaryPower": 78,
			"technologyLevel": 1,
			"diplomaticArchetype": "ZEALOTIC_DIPLOMAT",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "庄严、克己、强调信念共同体",
			"privateAgenda": "借助价值同盟塑造星域秩序",
			"behaviorTags": ["faith", "unity", "soft_power"],
			"victoryFocus": "ASCENSION"
		},
		{
			"template_id": "cinder_brokerage",
			"name": "烬湾经纪团",
			"leaderName": "灰羽总经纪",
			"type": "CORPORATE_CARTEL",
			"color": "3DA9FC",
			"personality": {"aggression": 4.0, "paranoia": 8.0, "greed": 9.0, "loyalty": 4.0, "rationality": 8.0},
			"resourceBias": {"food": 170, "minerals": 250, "industry": 150, "energy": 160},
			"resourceRates": {"food": -1, "minerals": 6, "industry": 1, "energy": 1},
			"population": 205,
			"militaryPower": 74,
			"technologyLevel": 1,
			"diplomaticArchetype": "BLACK_MARKET_BROKER",
			"preferredVisibility": "SECRET",
			"publicPersona": "客套、冷静、把一切都当作筹码",
			"privateAgenda": "操纵黑市与航道保险垄断利润",
			"behaviorTags": ["trade", "intel", "sanctions"],
			"victoryFocus": "ECONOMY"
		},
		{
			"template_id": "verdant_wardens",
			"name": "青穹守林者",
			"leaderName": "叶冠护民官",
			"type": "ECOLOGICAL_COMMONWEALTH",
			"color": "7FBA00",
			"personality": {"aggression": 2.0, "paranoia": 4.0, "greed": 2.0, "loyalty": 8.0, "rationality": 8.0},
			"resourceBias": {"food": 250, "minerals": 150, "industry": 120, "energy": 170},
			"resourceRates": {"food": 6, "minerals": 0, "industry": 1, "energy": 1},
			"population": 235,
			"militaryPower": 66,
			"technologyLevel": 1,
			"diplomaticArchetype": "ECO_STEWARD",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "温和、耐心、强调长期平衡",
			"privateAgenda": "通过生态依赖网络绑定周边势力",
			"behaviorTags": ["growth", "colonization", "stability"],
			"victoryFocus": "EXPANSION"
		},
		{
			"template_id": "mirror_directorate",
			"name": "镜潮总署",
			"leaderName": "深帷执政官",
			"type": "INTELLIGENCE_DIRECTORATE",
			"color": "6246EA",
			"personality": {"aggression": 4.0, "paranoia": 9.0, "greed": 5.0, "loyalty": 7.0, "rationality": 9.0},
			"resourceBias": {"food": 180, "minerals": 160, "industry": 150, "energy": 220},
			"resourceRates": {"food": 0, "minerals": 1, "industry": 2, "energy": 5},
			"population": 190,
			"militaryPower": 70,
			"technologyLevel": 1,
			"diplomaticArchetype": "INTEL_COORDINATOR",
			"preferredVisibility": "ENCRYPTED",
			"publicPersona": "克制、模糊、善于保留余地",
			"privateAgenda": "用截获、误导和内线塑造可控危机",
			"behaviorTags": ["intel", "encryption", "backchannel"],
			"victoryFocus": "DIPLOMACY"
		},
		{
			"template_id": "aurora_collective",
			"name": "极光共同体",
			"leaderName": "序列发言人",
			"type": "SCIENCE_COLLECTIVE",
			"color": "00B5D8",
			"personality": {"aggression": 2.0, "paranoia": 5.0, "greed": 4.0, "loyalty": 7.0, "rationality": 10.0},
			"resourceBias": {"food": 190, "minerals": 170, "industry": 150, "energy": 210},
			"resourceRates": {"food": 1, "minerals": 1, "industry": 2, "energy": 4},
			"population": 225,
			"militaryPower": 68,
			"technologyLevel": 1,
			"diplomaticArchetype": "RESEARCH_COORDINATOR",
			"preferredVisibility": "ENCRYPTED",
			"publicPersona": "理性、开放、偏好可验证承诺",
			"privateAgenda": "优先建立技术优势与联合研究网络",
			"behaviorTags": ["research", "treaty", "forecasting"],
			"victoryFocus": "ASCENSION"
		},
		{
			"template_id": "ashen_nomads",
			"name": "灰烬流亡舰群",
			"leaderName": "漂泊女王",
			"type": "EXILE_FLEET",
			"color": "94A1B2",
			"personality": {"aggression": 6.0, "paranoia": 8.0, "greed": 5.0, "loyalty": 8.0, "rationality": 6.0},
			"resourceBias": {"food": 160, "minerals": 180, "industry": 180, "energy": 170},
			"resourceRates": {"food": 0, "minerals": 2, "industry": 3, "energy": 1},
			"population": 200,
			"militaryPower": 88,
			"technologyLevel": 1,
			"diplomaticArchetype": "REFUGEE_COMMAND",
			"preferredVisibility": "SECRET",
			"publicPersona": "警惕、坚韧、以生存优先",
			"privateAgenda": "为舰群寻找长期停泊地并排除威胁",
			"behaviorTags": ["fleet", "pressure", "migration"],
			"victoryFocus": "DOMINATION"
		},
		{
			"template_id": "opal_assembly",
			"name": "欧泊议约会",
			"leaderName": "多席协调官",
			"type": "FEDERAL_ASSEMBLY",
			"color": "C97BFB",
			"personality": {"aggression": 3.0, "paranoia": 4.0, "greed": 4.0, "loyalty": 9.0, "rationality": 8.0},
			"resourceBias": {"food": 210, "minerals": 170, "industry": 170, "energy": 170},
			"resourceRates": {"food": 2, "minerals": 1, "industry": 3, "energy": 1},
			"population": 230,
			"militaryPower": 70,
			"technologyLevel": 1,
			"diplomaticArchetype": "CHARTER_BUILDER",
			"preferredVisibility": "PUBLIC",
			"publicPersona": "稳健、程序化、强调共同章程",
			"privateAgenda": "把区域协定逐步固化成长期制度",
			"behaviorTags": ["diplomacy", "charter", "council"],
			"victoryFocus": "DIPLOMACY"
		}
	]

static func select_ai_civilization_templates() -> Array:
	var pool: Array = civilization_pool()
	return [pool[0], pool[1]]

static func build_ai_faction_from_template(runtime_id: String, capital_system_id: String, template: Dictionary) -> Dictionary:
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
		"isPlayer": false
	}

static func create_initial_state() -> Dictionary:
	var catalog: Array = building_catalog()
	var ai_templates: Array = select_ai_civilization_templates()
	var merchant_faction: Dictionary = build_ai_faction_from_template("f_merchant", "sys_sirius", ai_templates[0])
	var orchid_faction: Dictionary = build_ai_faction_from_template("f_orchid", "sys_orion", ai_templates[1])
	var merchant_name: String = merchant_faction.get("name", "AI 势力")
	var orchid_name: String = orchid_faction.get("name", "AI 势力")
	return {
		"turn": 1,
		"era": "PIONEER",
		"status": "PLAYING",
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
				"name": "喵星文明",
				"leaderName": "喵因斯坦",
				"type": "TECHNOLOGY_ALLIANCE",
				"capitalSystemId": "sys_cat_home",
				"color": Color("7F5AF0"),
				"personality": {"aggression": 4.0, "paranoia": 5.0, "greed": 5.0, "loyalty": 6.0, "rationality": 9.0},
				"controlledSystems": ["sys_cat_home"],
				"resources": {"food": 240, "minerals": 220, "industry": 180, "energy": 180},
				"resourceRates": {"food": 5, "minerals": 0, "industry": 0, "energy": -2},
				"population": 300,
				"militaryPower": 90,
				"technologyLevel": 1,
				"diplomaticProfile": default_diplomatic_profile("CAT_SCIENCE", "PUBLIC", "理性、克制、重视协作", "优先建立安全缓冲与科研优势"),
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
				"note": "喵星文明的母星，拥有完善的工业与科研基础。",
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
				"content": "Godot 迁移版已接入星图、HUD、科技、外交、建造、舰队与回合逻辑骨架。本局 AI 势力为 %s 与 %s。" % [merchant_name, orchid_name],
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

static func _make_building(building_id: String, blueprint: Dictionary) -> Dictionary:
	var entry: Dictionary = blueprint.duplicate(true)
	entry["id"] = building_id
	return entry

static func _technology_nodes() -> Array:
	return [
		{"id": "tech_trade_net", "name": "贸易网络", "tier": 1, "category": "ECONOMY", "description": "建立基础商路协定，提升星系间物流效率。", "effects": ["每个已控星系 +2 能源 / +1 矿产"], "unlocks": ["星际礼制协议"], "status": "AVAILABLE", "cost": 80, "researchTime": 2, "progress": 0.0},
		{"id": "tech_shipyard", "name": "太空船坞", "tier": 1, "category": "MILITARY", "description": "解锁基础船坞建设与舰船标准化生产。", "effects": ["解锁太空船坞建筑", "新造护卫舰 +15 生命 / +4 伤害", "所有新造舰船 +1 速度", "新造舰船矿产与工业成本降低约 10%~20%"], "unlocks": ["驱逐舰船体", "舰队后勤"], "status": "AVAILABLE", "cost": 80, "researchTime": 2, "progress": 0.0},
		{"id": "tech_research_lab", "name": "科研实验室", "tier": 1, "category": "SCIENCE", "description": "建立标准实验室体系，加速科研流程。", "effects": ["解锁科研实验室建筑", "全局研究速度 +35%"], "unlocks": ["应用机器人", "恒星谐振工程"], "status": "AVAILABLE", "cost": 100, "researchTime": 3, "progress": 0.0},
		{"id": "tech_deep_colonization", "name": "基础深空殖民", "tier": 1, "category": "EXPANSION", "description": "解锁正式殖民行动、前哨建设与跨星系定居流程。", "effects": ["允许对完全探明的无主星系发起殖民", "解锁标准 / 资源 / 核心 / 军事四类殖民模式"], "unlocks": ["扩展居住", "殖民章程"], "status": "AVAILABLE", "cost": 70, "researchTime": 2, "progress": 0.0},
		{"id": "tech_expanded_housing", "name": "扩展居住", "tier": 1, "category": "EXPANSION", "description": "提高新殖民地的初始承载人口。", "effects": ["殖民地成熟时额外 +30 人口", "前哨稳定度 +6"], "unlocks": ["殖民章程", "深空侦测"], "status": "LOCKED", "cost": 60, "researchTime": 2, "progress": 0.0, "prerequisites": ["tech_deep_colonization"]},
		{"id": "tech_diplomatic_protocols", "name": "星际礼制协议", "tier": 2, "category": "ECONOMY", "description": "确立正式条约缔结流程与外交规范。", "effects": ["解锁互不侵犯 / 科研协定 / 同盟", "当前版本主要提供条约功能解锁"], "unlocks": ["自动装配线", "联邦议会"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_trade_net"]},
		{"id": "tech_destroyer_hulls", "name": "驱逐舰船体", "tier": 2, "category": "MILITARY", "description": "扩展护航舰船至中型战舰标准。", "effects": ["解锁驱逐舰建造"], "unlocks": ["巡洋舰学说", "舰队后勤"], "status": "LOCKED", "cost": 140, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_shipyard"]},
		{"id": "tech_fleet_logistics", "name": "舰队后勤", "tier": 2, "category": "MILITARY", "description": "改善舰队补给效率与维修流程。", "effects": ["当前版本主要作为前置科技", "后续会接入维修与补给数值加成"], "unlocks": ["战术指挥核心"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_shipyard"]},
		{"id": "tech_applied_robotics", "name": "应用机器人", "tier": 2, "category": "SCIENCE", "description": "让自动化单元进入工业与科研岗位。", "effects": ["当前版本主要作为前置科技", "后续会接入工业与研究效率加成"], "unlocks": ["量子建模"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_research_lab"]},
		{"id": "tech_colony_charter", "name": "殖民章程", "tier": 2, "category": "EXPANSION", "description": "为远星殖民制定统一治理范本。", "effects": ["前哨成长速度提升", "殖民地成熟后的稳定度更高"], "unlocks": ["地貌改造"], "status": "LOCKED", "cost": 100, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_deep_colonization"]},
		{"id": "tech_deep_space_scans", "name": "深空侦测", "tier": 2, "category": "EXPANSION", "description": "提升远距离星图扫描与异常信号识别能力。", "effects": ["当前版本主要作为前置科技", "后续会接入探索收益与侦测范围加成"], "unlocks": ["边境灯塔"], "status": "LOCKED", "cost": 110, "researchTime": 2, "progress": 0.0, "prerequisites": ["tech_expanded_housing"]},
		{"id": "tech_auto_assembly", "name": "自动装配线", "tier": 3, "category": "ECONOMY", "description": "建立矿产到工业的自动装配流程。", "effects": ["当前版本主要作为前置科技", "后续会接入工厂效率与队列速度加成"], "unlocks": ["行星协调网"], "status": "LOCKED", "cost": 180, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_diplomatic_protocols"]},
		{"id": "tech_cruiser_doctrine", "name": "巡洋舰学说", "tier": 3, "category": "MILITARY", "description": "确立主力舰火力与编队学说。", "effects": ["解锁巡洋舰建造"], "unlocks": ["旗舰系统"], "status": "LOCKED", "cost": 220, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_destroyer_hulls", "tech_research_lab"]},
		{"id": "tech_tactical_core", "name": "战术指挥核心", "tier": 3, "category": "MILITARY", "description": "通过战术 AI 提升舰队联合作战能力。", "effects": ["当前版本主要作为前置科技", "后续会接入命中 / 伤害等战斗加成"], "unlocks": ["旗舰系统"], "status": "LOCKED", "cost": 210, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_destroyer_hulls", "tech_fleet_logistics"]},
		{"id": "tech_star_harmonics", "name": "恒星谐振工程", "tier": 3, "category": "SCIENCE", "description": "利用恒星谐振原理推动高阶能源与飞升技术。", "effects": ["每回合飞升进度 +10"], "unlocks": ["量子建模", "奇点格构"], "status": "LOCKED", "cost": 220, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_research_lab"]},
		{"id": "tech_terraforming", "name": "地貌改造", "tier": 3, "category": "EXPANSION", "description": "改善殖民星环境并扩大长期产能。", "effects": ["当前版本主要作为前置科技", "后续会接入殖民地人口与资源产出加成"], "unlocks": ["边境星域长期控制"], "status": "LOCKED", "cost": 180, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_colony_charter"]},
		{"id": "tech_planetary_grid", "name": "行星协调网", "tier": 4, "category": "ECONOMY", "description": "把产业、能源、物流与治理统一进协调网络。", "effects": ["当前版本主要作为前置科技", "后续会接入整体经济效率加成"], "unlocks": ["联邦议会"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_auto_assembly", "tech_deep_space_scans"]},
		{"id": "tech_flagship_systems", "name": "旗舰系统", "tier": 4, "category": "MILITARY", "description": "重型旗舰系统为后期舰队提供绝对核心。", "effects": ["解锁战列舰建造"], "unlocks": ["战列舰"], "status": "LOCKED", "cost": 280, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_tactical_core", "tech_cruiser_doctrine"]},
		{"id": "tech_quantum_modeling", "name": "量子建模", "tier": 4, "category": "SCIENCE", "description": "用量子模拟缩短复杂工程与科研周期。", "effects": ["当前版本主要作为前置科技", "后续会接入研究耗时缩减"], "unlocks": ["奇点格构"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_applied_robotics", "tech_star_harmonics"]},
		{"id": "tech_federal_council", "name": "联邦议会", "tier": 4, "category": "ECONOMY", "description": "建立统一议会以完成跨文明协调治理。", "effects": ["当前版本主要作为外交胜利前置", "暂不提供额外数值加成"], "unlocks": ["外交胜利"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_diplomatic_protocols", "tech_planetary_grid"]},
		{"id": "tech_singularity_lattice", "name": "奇点格构", "tier": 4, "category": "SCIENCE", "description": "构建飞升所需的终极物理骨架。", "effects": ["每回合飞升进度 +18"], "unlocks": ["飞升胜利"], "status": "LOCKED", "cost": 320, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_quantum_modeling", "tech_star_harmonics"]}
	]
