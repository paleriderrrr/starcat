extends RefCounted

class_name InitialData

static func empty_resources() -> Dictionary:
	return {"food": 0, "minerals": 0, "industry": 0, "energy": 0}

static func building_catalog() -> Array:
	return [
		{
			"type": "HABITAT",
			"name": "居住站",
			"description": "提供基础住房与殖民稳定度，属于低门槛民生建筑。",
			"cost": {"food": 20, "minerals": 20, "industry": 0, "energy": 0},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -1},
			"production": {"food": 0, "minerals": 0, "industry": 0, "energy": 0},
			"housing": 6
		},
		{
			"type": "HYDROPONICS",
			"name": "水培农场",
			"description": "将少量矿物与能源转化为稳定食物产出。",
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
			"description": "将矿产冶炼为工业产能，维持需要稳定矿物与能源供应。",
			"cost": {"food": 0, "minerals": 30, "industry": 0, "energy": 10},
			"maintenance": {"food": 0, "minerals": -2, "industry": 0, "energy": -2},
			"production": {"food": 0, "minerals": 0, "industry": 4, "energy": 0},
			"housing": 0
		},
		{
			"type": "FUSION_REACTOR",
			"name": "聚变反应堆",
			"description": "中期关键建筑，用较高矿物投入换取持续能源盈余。",
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
			"description": "提升研究产能。",
			"cost": {"food": 0, "minerals": 30, "industry": 25, "energy": 15},
			"maintenance": {"food": 0, "minerals": 0, "industry": 0, "energy": -2},
			"production": {"food": 0, "minerals": 0, "industry": 3, "energy": 0},
			"housing": 0,
			"unlock_tech_id": "tech_research_lab"
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
		"RESEARCH_LAB": 2
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
		"RESEARCH_ACCORD": "科研合作协议",
		"ALLIANCE": "共同防御同盟",
		"WAR_STATE": "战争状态"
	}

static func colonization_modes() -> Dictionary:
	return {
		"STANDARD": {
			"name": "标准殖民",
			"description": "均衡的常规殖民方案，适合大多数中立星系。",
			"cost": {"food": 60, "minerals": 50, "industry": 40, "energy": 20},
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
			"description": "以边境据点为核心，稳定度一般但利于前线控制。",
			"cost": {"food": 55, "minerals": 60, "industry": 55, "energy": 28},
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

static func create_initial_state() -> Dictionary:
	var catalog: Array = building_catalog()
	return {
		"turn": 1,
		"era": "PIONEER",
		"status": "PLAYING",
		"objective": "军事 1/3 星系 · 外交 需同盟+科研协定 · 飞升 0/100",
		"victory_path": null,
		"ascension_progress": 0,
		"factions": [
			{
				"id": "f_player",
				"name": "喵星文明",
				"leaderName": "喵因斯坦",
				"type": "TECHNOLOGY_ALLIANCE",
				"color": Color("7F5AF0"),
				"personality": {"aggression": 4.0, "paranoia": 5.0, "greed": 5.0, "loyalty": 6.0, "rationality": 9.0},
				"controlledSystems": ["sys_cat_home"],
				"resources": {"food": 240, "minerals": 220, "industry": 180, "energy": 180},
				"resourceRates": {"food": 5, "minerals": 0, "industry": 0, "energy": -2},
				"population": 300,
				"militaryPower": 90,
				"technologyLevel": 1,
				"diplomaticProfile": default_diplomatic_profile("CAT_SCIENCE", "PUBLIC", "理性、克制、重视协商", "优先建立安全缓冲与科研优势"),
				"isPlayer": true
			},
			{
				"id": "f_merchant",
				"name": "商贾联盟",
				"leaderName": "金须阁下",
				"type": "COMMERCIAL_FEDERATION",
				"color": Color("2CB67D"),
				"personality": {"aggression": 3.0, "paranoia": 7.0, "greed": 8.0, "loyalty": 6.0, "rationality": 8.0},
				"controlledSystems": ["sys_sirius"],
				"resources": {"food": 220, "minerals": 240, "industry": 140, "energy": 140},
				"resourceRates": {"food": 0, "minerals": 5, "industry": 0, "energy": -1},
				"population": 220,
				"militaryPower": 80,
				"technologyLevel": 1,
				"diplomaticProfile": default_diplomatic_profile("MERCHANT_PRAGMATIST", "SECRET", "礼貌、精明、重视利润", "通过秘密交易建立边境影响力"),
				"isPlayer": false
			},
			{
				"id": "f_orchid",
				"name": "兰心公约",
				"leaderName": "兰枢议长",
				"type": "DIPLOMATIC_LEAGUE",
				"color": Color("F4B860"),
				"personality": {"aggression": 2.0, "paranoia": 6.0, "greed": 4.0, "loyalty": 8.0, "rationality": 8.0},
				"controlledSystems": ["sys_orion"],
				"resources": {"food": 210, "minerals": 180, "industry": 160, "energy": 170},
				"resourceRates": {"food": 2, "minerals": 2, "industry": 3, "energy": 1},
				"population": 210,
				"militaryPower": 72,
				"technologyLevel": 1,
				"diplomaticProfile": default_diplomatic_profile("ORCHID_MEDIATOR", "ENCRYPTED", "正式、克制、偏好条约秩序", "避免战争失控并寻求平衡各方"),
				"isPlayer": false
			}
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
				"note": "商贾联盟的重要边贸枢纽，矿物加工能力较强。",
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
				"name": "参宿四",
				"type": "SOLAR",
				"position": Vector3(8.5, 0.0, -7.0),
				"resources": {"food": 5, "minerals": 4, "industry": 5, "energy": 4},
				"buildingSlots": 4,
				"baseBuildingSlots": 4,
				"buildings": [_make_building("b4", catalog[0]), _make_building("b5", catalog[3])],
				"ownerId": "f_orchid",
				"population": 210,
				"visibilityLevel": "PARTIAL",
				"note": "兰心公约的议会驻地，擅长在战火边缘维持秩序。",
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
		"messages": [
			{
				"id": "msg_1",
				"title": "欢迎来到喵星文明",
				"content": "Godot 迁移版已接入星图、HUD、科技、外交、建造、舰队与回合逻辑骨架。",
				"turn": 1,
				"type": "SYSTEM"
			}
		],
		"diplomaticMessages": [
			{
				"id": "dmsg_1",
				"turn": 1,
				"senderId": "f_orchid",
				"senderName": "兰心公约",
				"targetType": "BROADCAST",
				"targetIds": ["f_player", "f_merchant"],
				"visibilityLevel": "PUBLIC",
				"contentType": "NOTIFICATION",
				"title": "边境秩序通告",
				"content": "兰心公约呼吁各方在新航道附近维持克制，避免误判升级。",
				"summary": "公开秩序声明",
				"visibleToPlayer": true
			}
		],
		"diplomaticMemories": [
			{
				"id": "dmem_1",
				"turn": 1,
				"title": "边境秩序通告",
				"summary": "兰心公约要求周边文明在新航道周围保持克制。",
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
		{"id": "tech_trade_net", "name": "贸易网络", "tier": 1, "category": "ECONOMY", "description": "建立基础商路协议，提升星系间物流效率。", "effects": ["每个已控星系 +2 能源 / +1 矿产"], "unlocks": ["星际礼制协议"], "status": "AVAILABLE", "cost": 80, "researchTime": 2, "progress": 0.0},
		{"id": "tech_shipyard", "name": "太空船坞", "tier": 1, "category": "MILITARY", "description": "解锁基础船坞建设与舰船标准化生产。", "effects": ["解锁太空船坞建筑", "新造护卫舰 +15 生命 / +4 伤害", "所有新造舰船 +1 速度", "新造舰船矿产与工业成本降低约 10%~20%"], "unlocks": ["驱逐舰船体", "舰队后勤"], "status": "AVAILABLE", "cost": 80, "researchTime": 2, "progress": 0.0},
		{"id": "tech_research_lab", "name": "科研实验室", "tier": 1, "category": "SCIENCE", "description": "建立标准实验室体系，加速科研流程。", "effects": ["解锁科研实验室建筑", "全局研究速度 +35%"], "unlocks": ["应用机器人", "恒星谐振工程"], "status": "AVAILABLE", "cost": 100, "researchTime": 3, "progress": 0.0},
		{"id": "tech_deep_colonization", "name": "基础深空殖民", "tier": 1, "category": "EXPANSION", "description": "解锁正式殖民行动、前哨建设与跨星系定居流程。", "effects": ["允许对完全探明的无主星系发起殖民", "解锁标准 / 资源 / 核心 / 军事四类殖民模式"], "unlocks": ["扩展居住", "殖民章程"], "status": "AVAILABLE", "cost": 70, "researchTime": 2, "progress": 0.0},
		{"id": "tech_expanded_housing", "name": "扩展居住", "tier": 1, "category": "EXPANSION", "description": "提高新殖民地的初始承载人口。", "effects": ["殖民地成熟时额外 +30 人口", "前哨稳定度 +6"], "unlocks": ["殖民章程", "深空侦测"], "status": "LOCKED", "cost": 60, "researchTime": 2, "progress": 0.0, "prerequisites": ["tech_deep_colonization"]},
		{"id": "tech_diplomatic_protocols", "name": "星际礼制协议", "tier": 2, "category": "ECONOMY", "description": "确立正式条约缔结流程与外交规范。", "effects": ["解锁互不侵犯 / 科研协定 / 同盟", "当前版本主要提供条约功能解锁"], "unlocks": ["自动装配线", "联邦议会"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_trade_net"]},
		{"id": "tech_destroyer_hulls", "name": "驱逐舰船体", "tier": 2, "category": "MILITARY", "description": "扩展护航舰至中型战舰标准。", "effects": ["解锁驱逐舰建造"], "unlocks": ["巡洋舰学说", "舰队后勤"], "status": "LOCKED", "cost": 140, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_shipyard"]},
		{"id": "tech_fleet_logistics", "name": "舰队后勤", "tier": 2, "category": "MILITARY", "description": "改善舰队补给效率与维修流程。", "effects": ["当前版本主要作为前置科技", "后续会接入维修与补给数值加成"], "unlocks": ["战术指挥核心"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_shipyard"]},
		{"id": "tech_applied_robotics", "name": "应用机器人", "tier": 2, "category": "SCIENCE", "description": "让自动化单元进入工业与科研岗位。", "effects": ["当前版本主要作为前置科技", "后续会接入工业与研究效率加成"], "unlocks": ["量子建模"], "status": "LOCKED", "cost": 120, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_research_lab"]},
		{"id": "tech_colony_charter", "name": "殖民章程", "tier": 2, "category": "EXPANSION", "description": "为远星殖民制定统一治理范本。", "effects": ["前哨成长速度提升", "殖民地成熟后的稳定度更高"], "unlocks": ["地貌改造"], "status": "LOCKED", "cost": 100, "researchTime": 3, "progress": 0.0, "prerequisites": ["tech_deep_colonization"]},
		{"id": "tech_deep_space_scans", "name": "深空侦测", "tier": 2, "category": "EXPANSION", "description": "提升远距星图扫描与异常信号识别能力。", "effects": ["当前版本主要作为前置科技", "后续会接入探索收益与侦测范围加成"], "unlocks": ["边疆灯塔"], "status": "LOCKED", "cost": 110, "researchTime": 2, "progress": 0.0, "prerequisites": ["tech_expanded_housing"]},
		{"id": "tech_auto_assembly", "name": "自动装配线", "tier": 3, "category": "ECONOMY", "description": "建立矿产到工业的自动装配流程。", "effects": ["当前版本主要作为前置科技", "后续会接入工厂效率与队列速度加成"], "unlocks": ["行星协调网"], "status": "LOCKED", "cost": 180, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_diplomatic_protocols"]},
		{"id": "tech_cruiser_doctrine", "name": "巡洋舰学说", "tier": 3, "category": "MILITARY", "description": "确立主力舰火力与编队学说。", "effects": ["解锁巡洋舰建造"], "unlocks": ["旗舰系统"], "status": "LOCKED", "cost": 220, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_destroyer_hulls", "tech_research_lab"]},
		{"id": "tech_tactical_core", "name": "战术指挥核心", "tier": 3, "category": "MILITARY", "description": "通过战术 AI 提升舰队联合作战能力。", "effects": ["当前版本主要作为前置科技", "后续会接入命中 / 伤害等战斗加成"], "unlocks": ["旗舰系统"], "status": "LOCKED", "cost": 210, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_destroyer_hulls", "tech_fleet_logistics"]},
		{"id": "tech_star_harmonics", "name": "恒星谐振工程", "tier": 3, "category": "SCIENCE", "description": "利用恒星谐振原理推动高阶能源与飞升技术。", "effects": ["每回合飞升进度 +10"], "unlocks": ["量子建模", "奇点格构"], "status": "LOCKED", "cost": 220, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_research_lab"]},
		{"id": "tech_terraforming", "name": "地貌改造", "tier": 3, "category": "EXPANSION", "description": "改善殖民星环境并扩大长期产能。", "effects": ["当前版本主要作为前置科技", "后续会接入殖民地人口与资源产出加成"], "unlocks": ["边境星域长期控制"], "status": "LOCKED", "cost": 180, "researchTime": 4, "progress": 0.0, "prerequisites": ["tech_colony_charter"]},
		{"id": "tech_planetary_grid", "name": "行星协调网", "tier": 4, "category": "ECONOMY", "description": "把产业、能源、物流与治理统一进协调网络。", "effects": ["当前版本主要作为前置科技", "后续会接入整体经济效率加成"], "unlocks": ["联邦议会"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_auto_assembly", "tech_deep_space_scans"]},
		{"id": "tech_flagship_systems", "name": "旗舰系统", "tier": 4, "category": "MILITARY", "description": "重型旗舰系统为后期舰队提供绝对核心。", "effects": ["解锁战列舰建造"], "unlocks": ["战列舰"], "status": "LOCKED", "cost": 280, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_tactical_core", "tech_cruiser_doctrine"]},
		{"id": "tech_quantum_modeling", "name": "量子建模", "tier": 4, "category": "SCIENCE", "description": "用量子模拟缩短复杂工程与科研周期。", "effects": ["当前版本主要作为前置科技", "后续会接入研究耗时缩减"], "unlocks": ["奇点格构"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_applied_robotics", "tech_star_harmonics"]},
		{"id": "tech_federal_council", "name": "联邦议会", "tier": 4, "category": "ECONOMY", "description": "建立统一议会以完成跨文明协调治理。", "effects": ["当前版本主要作为外交胜利前置", "无额外数值加成"], "unlocks": ["外交胜利"], "status": "LOCKED", "cost": 260, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_diplomatic_protocols", "tech_planetary_grid"]},
		{"id": "tech_singularity_lattice", "name": "奇点格构", "tier": 4, "category": "SCIENCE", "description": "构建飞升所需的终极物理骨架。", "effects": ["每回合飞升进度 +18"], "unlocks": ["飞升胜利"], "status": "LOCKED", "cost": 320, "researchTime": 5, "progress": 0.0, "prerequisites": ["tech_quantum_modeling", "tech_star_harmonics"]}
	]
