extends CanvasLayer

const GameLogicScript = preload("res://scripts/GameLogic.gd")
const InitialDataScript = preload("res://scripts/data/InitialData.gd")
const CHIP_SCENE: PackedScene = preload("res://scenes/ui/Chip.tscn")
const ACTION_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/ActionButton.tscn")
const ACTION_ROW_SCENE: PackedScene = preload("res://scenes/ui/ActionRow.tscn")
const DIPLOMACY_COMPOSER_SCENE: PackedScene = preload("res://scenes/ui/DiplomacyComposer.tscn")
const TECH_CARD_SCENE: PackedScene = preload("res://scenes/ui/TechCard.tscn")
const BUILDING_CARD_SCENE: PackedScene = preload("res://scenes/ui/BuildingCard.tscn")
const ROUTE_CARD_SCENE: PackedScene = preload("res://scenes/ui/RouteCard.tscn")
const SUMMARY_CARD_SCENE: PackedScene = preload("res://scenes/ui/SummaryCard.tscn")
const FLEET_SHIP_CARD_SCENE: PackedScene = preload("res://scenes/ui/FleetShipCard.tscn")
const QUEUE_ITEM_CARD_SCENE: PackedScene = preload("res://scenes/ui/QueueItemCard.tscn")
const FEED_CARD_SCENE: PackedScene = preload("res://scenes/ui/FeedCard.tscn")
const DIPLOMACY_FACTION_CARD_SCENE: PackedScene = preload("res://scenes/ui/DiplomacyFactionCard.tscn")
const COLONIZATION_OPTION_CARD_SCENE: PackedScene = preload("res://scenes/ui/ColonizationOptionCard.tscn")
const PROPOSAL_CARD_SCENE: PackedScene = preload("res://scenes/ui/ProposalCard.tscn")
const TREND_CARD_SCENE: PackedScene = preload("res://scenes/ui/TrendCard.tscn")
const API_REPORT_CARD_SCENE: PackedScene = preload("res://scenes/ui/ApiReportCard.tscn")
const POSTURE_CARD_SCENE: PackedScene = preload("res://scenes/ui/PostureCard.tscn")
const STATUS_CARD_SCENE: PackedScene = preload("res://scenes/ui/StatusCard.tscn")
const INFO_CARD_SCENE: PackedScene = preload("res://scenes/ui/InfoCard.tscn")
const INFO_LINE_SCENE: PackedScene = preload("res://scenes/ui/InfoLine.tscn")
const SECTION_TITLE_SCENE: PackedScene = preload("res://scenes/ui/SectionTitle.tscn")

const TAB_NAMES: Array = ["OBJECTIVES", "TECH", "DIPLOMACY", "COMMS"]
const TAB_LABELS: Dictionary = {
	"OBJECTIVES": "目标",
	"TECH": "科技",
	"DIPLOMACY": "外交",
	"COMMS": "通信"
}

const TAB_ICON_KEYS: Dictionary = {
	"OBJECTIVES": "objectives",
	"TECH": "research",
	"DIPLOMACY": "diplomacy",
	"COMMS": "comms",
}

const RESOURCE_NAMES: Dictionary = {
	"food": "食物",
	"minerals": "矿产",
	"industry": "工业",
	"energy": "能源"
}

const UI_ICON_PATHS: Dictionary = {
	"objectives": "res://assets/ui/icons/objectives.svg",
	"food": "res://assets/ui/icons/food.svg",
	"minerals": "res://assets/ui/icons/minerals.svg",
	"industry": "res://assets/ui/icons/industry.svg",
	"energy": "res://assets/ui/icons/energy.svg",
	"fleet": "res://assets/ui/icons/fleet.svg",
	"health": "res://assets/ui/icons/health.svg",
	"damage": "res://assets/ui/icons/damage.svg",
	"cooldown": "res://assets/ui/icons/cooldown.svg",
	"route": "res://assets/ui/icons/route.svg",
	"mission": "res://assets/ui/icons/mission.svg",
	"research": "res://assets/ui/icons/research.svg",
	"diplomacy": "res://assets/ui/icons/diplomacy.svg",
	"comms": "res://assets/ui/icons/comms.svg",
	"system": "res://assets/ui/icons/system.svg",
}

const RELATION_LEVEL_NAMES: Dictionary = {
	"ALLY": "同盟",
	"FRIENDLY": "友好",
	"NEUTRAL": "中立",
	"COLD": "冷淡",
	"HOSTILE": "敌对",
	"UNKNOWN": "未知"
}

const VISIBILITY_LABELS: Dictionary = {
	"PUBLIC": "公开",
	"RESTRICTED": "限制",
	"SECRET": "秘密",
	"ENCRYPTED": "加密"
}

const PROPOSAL_TYPE_LABELS: Dictionary = {
	"TRADE_PACT": "贸易协定",
	"NON_AGGRESSION": "互不侵犯",
	"RESEARCH_ACCORD": "科研协定",
	"ALLIANCE": "同盟提案",
	"PEACE_TALK": "和平谈判",
	"ULTIMATUM": "最后通牒",
	"UNKNOWN": "未知提案"
}

const POSTURE_LABELS: Dictionary = {
	"CONSOLIDATE": "巩固内政",
	"CONTAIN": "遏制威胁",
	"EXPAND_DIPLOMACY": "扩张外交",
	"STABILIZE": "稳定局势"
}

const VICTORY_FOCUS_LABELS: Dictionary = {
	"MILITARY": "军事征服",
	"DIPLOMATIC": "外交主导",
	"SCIENCE": "科技飞升"
}

const TECH_CATEGORY_LABELS: Dictionary = {
	"ECONOMY": "经济",
	"MILITARY": "军事",
	"SCIENCE": "科学",
	"EXPANSION": "扩张",
	"UNKNOWN": "未知"
}

@onready var root: Control = $Root
@onready var safe_area: MarginContainer = $Root/SafeArea
@onready var top_bar: HBoxContainer = $Root/SafeArea/Layout/TopGroup/TopBar
@onready var turn_chip: PanelContainer = $Root/SafeArea/Layout/TopGroup/TopBar/TurnChip
@onready var turn_title: Label = $Root/SafeArea/Layout/TopGroup/TopBar/TurnChip/Content/TextBox/Title
@onready var turn_value: Label = $Root/SafeArea/Layout/TopGroup/TopBar/TurnChip/Content/TextBox/Value
@onready var era_chip: PanelContainer = $Root/SafeArea/Layout/TopGroup/TopBar/EraChip
@onready var era_title: Label = $Root/SafeArea/Layout/TopGroup/TopBar/EraChip/Content/TextBox/Title
@onready var era_value: Label = $Root/SafeArea/Layout/TopGroup/TopBar/EraChip/Content/TextBox/Value
@onready var food_chip: PanelContainer = $Root/SafeArea/Layout/TopGroup/TopBar/FoodChip
@onready var food_title: Label = $Root/SafeArea/Layout/TopGroup/TopBar/FoodChip/Content/TextBox/Title
@onready var food_value: Label = $Root/SafeArea/Layout/TopGroup/TopBar/FoodChip/Content/TextBox/Value
@onready var minerals_chip: PanelContainer = $Root/SafeArea/Layout/TopGroup/TopBar/MineralsChip
@onready var minerals_title: Label = $Root/SafeArea/Layout/TopGroup/TopBar/MineralsChip/Content/TextBox/Title
@onready var minerals_value: Label = $Root/SafeArea/Layout/TopGroup/TopBar/MineralsChip/Content/TextBox/Value
@onready var industry_chip: PanelContainer = $Root/SafeArea/Layout/TopGroup/TopBar/IndustryChip
@onready var industry_title: Label = $Root/SafeArea/Layout/TopGroup/TopBar/IndustryChip/Content/TextBox/Title
@onready var industry_value: Label = $Root/SafeArea/Layout/TopGroup/TopBar/IndustryChip/Content/TextBox/Value
@onready var energy_chip: PanelContainer = $Root/SafeArea/Layout/TopGroup/TopBar/EnergyChip
@onready var energy_title: Label = $Root/SafeArea/Layout/TopGroup/TopBar/EnergyChip/Content/TextBox/Title
@onready var energy_value: Label = $Root/SafeArea/Layout/TopGroup/TopBar/EnergyChip/Content/TextBox/Value
@onready var toggle_labels_button: Button = $Root/SafeArea/Layout/TopGroup/TopBar/ToggleLabelsButton
@onready var turn_briefing: PanelContainer = $Root/TurnBriefing
@onready var briefing_primary: Label = $Root/TurnBriefing/Content/BriefingPrimary
@onready var briefing_secondary: Label = $Root/TurnBriefing/Content/BriefingSecondary
@onready var briefing_meta: Label = $Root/TurnBriefing/Content/BriefingMeta
@onready var briefing_next_turn_button: Button = $Root/TurnBriefing/Content/BriefingNextTurnButton
@onready var player_identity: PanelContainer = $Root/PlayerIdentity
@onready var player_portrait: TextureRect = $Root/PlayerIdentity/Content/Portrait
@onready var player_name: Label = $Root/PlayerIdentity/Content/TextBox/Name
@onready var player_focus: Label = $Root/PlayerIdentity/Content/TextBox/Focus
@onready var right_drawer: PanelContainer = $Root/RightDrawer
@onready var drawer_title: Label = $Root/RightDrawer/Margin/DrawerVBox/DrawerHeader/TitleBox/DrawerTitle
@onready var drawer_subtitle: Label = $Root/RightDrawer/Margin/DrawerVBox/DrawerHeader/TitleBox/DrawerSubtitle
@onready var drawer_content: VBoxContainer = $Root/RightDrawer/Margin/DrawerVBox/DrawerBody/DrawerContent
@onready var next_turn_button: Button = $Root/RightDrawer/Margin/DrawerVBox/NextTurnButton
@onready var center_modal_overlay: ColorRect = $Root/CenterModalOverlay
@onready var center_modal: PanelContainer = $Root/CenterModalOverlay/CenterWrap/CenterModal
@onready var modal_title: Label = $Root/CenterModalOverlay/CenterWrap/CenterModal/Margin/ModalVBox/Header/TitleBox/ModalTitle
@onready var modal_subtitle: Label = $Root/CenterModalOverlay/CenterWrap/CenterModal/Margin/ModalVBox/Header/TitleBox/ModalSubtitle
@onready var modal_content: VBoxContainer = $Root/CenterModalOverlay/CenterWrap/CenterModal/Margin/ModalVBox/Body/ModalContent
@onready var close_modal_button: Button = $Root/CenterModalOverlay/CenterWrap/CenterModal/Margin/ModalVBox/Header/CloseButton
@onready var bottom_tabs: HBoxContainer = $Root/SafeArea/Layout/BottomGroup/BottomTabs
@onready var objectives_button: Button = $Root/SafeArea/Layout/BottomGroup/BottomTabs/ObjectivesButton
@onready var tech_button: Button = $Root/SafeArea/Layout/BottomGroup/BottomTabs/TechButton
@onready var diplomacy_button: Button = $Root/SafeArea/Layout/BottomGroup/BottomTabs/DiplomacyButton
@onready var communications_button: Button = $Root/SafeArea/Layout/BottomGroup/BottomTabs/CommunicationsButton
var _modal_payload: Dictionary = {}
var _panel_content: VBoxContainer
var _texture_cache: Dictionary = {}

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.tab_changed.connect(_on_tab_changed)
	GameState.labels_visibility_changed.connect(_on_labels_visibility_changed)
	GameState.service_status_changed.connect(_on_service_status_changed)
	GameState.diplomacy_changed.connect(_on_diplomacy_changed)
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	toggle_labels_button.pressed.connect(_on_toggle_labels_pressed)
	objectives_button.pressed.connect(_on_tab_pressed.bind("OBJECTIVES"))
	tech_button.pressed.connect(_on_tab_pressed.bind("TECH"))
	diplomacy_button.pressed.connect(_on_tab_pressed.bind("DIPLOMACY"))
	communications_button.pressed.connect(_on_tab_pressed.bind("COMMS"))
	close_modal_button.pressed.connect(_on_close_modal_pressed)
	center_modal_overlay.gui_input.connect(_on_center_modal_overlay_input)
	briefing_next_turn_button.pressed.connect(_on_next_turn_pressed)
	root.resized.connect(_update_modal_bounds)
	root.resized.connect(_update_responsive_layout)
	_apply_theme()
	_apply_button_variant(next_turn_button, "default")
	_apply_button_variant(briefing_next_turn_button, "default")
	_apply_button_variant(toggle_labels_button, "default")
	_apply_button_variant(close_modal_button, "default")
	drawer_subtitle.visible = false
	drawer_subtitle.text = ""
	_apply_top_bar_icons()
	_panel_content = drawer_content
	_update_responsive_layout()
	_update_modal_bounds()
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not center_modal_overlay.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_center_modal()

func refresh() -> void:
	next_turn_button.disabled = GameState.turn_busy or GameState.game_state.get("status", "") != "PLAYING"
	next_turn_button.text = "处理中..." if GameState.turn_busy else "下一回合"
	_rebuild_top_bar()
	_rebuild_player_identity()
	_rebuild_drawer()
	_rebuild_turn_briefing()
	_rebuild_bottom_tabs()

func _apply_theme() -> void:
	pass

func _apply_top_bar_icons() -> void:
	_apply_chip_icon(turn_chip, "mission")
	_apply_chip_icon(era_chip, "research")
	_apply_chip_icon(food_chip, "food")
	_apply_chip_icon(minerals_chip, "minerals")
	_apply_chip_icon(industry_chip, "industry")
	_apply_chip_icon(energy_chip, "energy")

func _update_modal_bounds() -> void:
	var viewport_size: Vector2 = root.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var available_width: float = maxf(320.0, viewport_size.x - 64.0)
	var available_height: float = maxf(280.0, viewport_size.y - 64.0)
	center_modal.custom_minimum_size = Vector2(
		minf(1216.0, available_width),
		minf(700.0, available_height)
	)

func _update_responsive_layout() -> void:
	var viewport_width: float = root.size.x
	var compact: bool = viewport_width > 0.0 and viewport_width < 1360.0
	var right_margin: int = 24
	safe_area.add_theme_constant_override("margin_right", right_margin)
	var resource_chip_size: Vector2 = Vector2(104, 52) if compact else Vector2(132, 56)
	food_chip.custom_minimum_size = resource_chip_size
	minerals_chip.custom_minimum_size = resource_chip_size
	industry_chip.custom_minimum_size = resource_chip_size
	energy_chip.custom_minimum_size = resource_chip_size
	turn_chip.custom_minimum_size = Vector2(76, 52) if compact else Vector2(96, 56)
	era_chip.custom_minimum_size = Vector2(92, 52) if compact else Vector2(112, 56)
	var toggle_size: Vector2 = Vector2(116, 52) if compact else Vector2(160, 56)
	toggle_labels_button.custom_minimum_size = toggle_size
	top_bar.add_theme_constant_override("separation", 6 if compact else 8)

func _rebuild_top_bar() -> void:
	var player: Dictionary = GameState.get_player_faction()
	var resources: Dictionary = player.get("resources", {})
	var rates: Dictionary = player.get("resourceRates", {})
	turn_title.text = "回合"
	era_title.text = "时代"
	food_title.text = "食物"
	minerals_title.text = "矿产"
	industry_title.text = "工业"
	energy_title.text = "能源"
	turn_value.text = str(GameState.game_state.get("turn", 1))
	era_value.text = _era_name(GameState.game_state.get("era", "PIONEER"))
	food_value.text = "%s (%s)" % [str(int(resources.get("food", 0))), _signed_int_text(int(rates.get("food", 0)))]
	minerals_value.text = "%s (%s)" % [str(int(resources.get("minerals", 0))), _signed_int_text(int(rates.get("minerals", 0)))]
	industry_value.text = "%s (%s)" % [str(int(resources.get("industry", 0))), _signed_int_text(int(rates.get("industry", 0)))]
	energy_value.text = "%s (%s)" % [str(int(resources.get("energy", 0))), _signed_int_text(int(rates.get("energy", 0)))]
	food_chip.tooltip_text = _resource_tooltip_text("food")
	minerals_chip.tooltip_text = _resource_tooltip_text("minerals")
	industry_chip.tooltip_text = _resource_tooltip_text("industry")
	energy_chip.tooltip_text = _resource_tooltip_text("energy")
	var drawer_condensed: bool = (GameState.selected_system_id != "" or GameState.selected_fleet_id != "") and root.size.x < 1760.0
	if drawer_condensed:
		toggle_labels_button.text = "标记"
		toggle_labels_button.tooltip_text = "星图文字标记: %s" % ("显示" if GameState.labels_visible else "隐藏")
	else:
		toggle_labels_button.text = "文字标记: %s" % ("显示" if GameState.labels_visible else "隐藏")
		toggle_labels_button.tooltip_text = ""

func _rebuild_player_identity() -> void:
	var player: Dictionary = GameState.get_player_faction()
	player_identity.visible = not player.is_empty()
	if player.is_empty():
		return
	player_name.text = str(player.get("name", "玩家文明"))
	player_focus.text = _victory_path_label(player.get("victoryFocus", GameState.game_state.get("victory_path", null)))
	_apply_texture(player_portrait, str(player.get("portraitPath", "")))

func _rebuild_turn_briefing() -> void:
	turn_briefing.visible = GameState.selected_system_id == "" and GameState.selected_fleet_id == "" and root.size.x >= 1180.0
	if not turn_briefing.visible:
		return
	var briefing_lines: Array[String] = _turn_briefing_lines()
	briefing_primary.text = briefing_lines[0]
	briefing_secondary.text = briefing_lines[1]
	briefing_meta.text = briefing_lines[2]
	briefing_next_turn_button.disabled = next_turn_button.disabled
	briefing_next_turn_button.text = next_turn_button.text

func _turn_briefing_lines() -> Array[String]:
	var research_line: String = "研究: %s" % _current_research_summary()
	var fleet_line: String = "舰队: %s" % _fleet_readiness_summary()
	var diplomacy_line: String = "外交: %s" % _diplomacy_briefing_summary()
	return [research_line, fleet_line, diplomacy_line]

func _current_research_summary() -> String:
	var current_research_id: Variant = GameState.game_state.get("currentResearchId", null)
	if current_research_id == null or str(current_research_id) == "":
		return "未指定"
	for tech: Dictionary in GameState.game_state.get("technologies", []):
		if str(tech.get("id", "")) == str(current_research_id):
			return "%s %.0f/%s" % [
				str(tech.get("name", current_research_id)),
				float(GameState.game_state.get("researchProgress", tech.get("progress", 0.0))),
				str(tech.get("cost", "?"))
			]
	return "进行中"

func _fleet_readiness_summary() -> String:
	var idle_count: int = _idle_fleet_count()
	var unclaimed_count: int = _visible_unclaimed_system_count()
	if idle_count > 0 and unclaimed_count > 0:
		return "待命 %s / 未占 %s" % [str(idle_count), str(unclaimed_count)]
	if idle_count > 0:
		return "待命 %s" % str(idle_count)
	return "执行中"

func _diplomacy_briefing_summary() -> String:
	var pending_count: int = GameState.game_state.get("pendingProposals", []).size()
	var visible_messages: Array = GameState.get_visible_diplomatic_messages()
	if pending_count > 0:
		return "%s 个提案待处理" % str(pending_count)
	if visible_messages.size() > 0:
		return "%s 条近期信号可读" % str(visible_messages.size())
	return "暂无紧急事项"

func _idle_fleet_count() -> int:
	var count: int = 0
	for fleet: Dictionary in GameState.get_player_fleets():
		if str(fleet.get("mission", "IDLE")) == "IDLE":
			count += 1
	return count

func _visible_unclaimed_system_count() -> int:
	var count: int = 0
	for system: Dictionary in GameState.game_state.get("starSystems", []):
		if system.get("ownerId", null) == null and str(system.get("visibilityLevel", "HIDDEN")) != "HIDDEN":
			count += 1
	return count

func _rebuild_drawer() -> void:
	for child: Node in drawer_content.get_children():
		child.queue_free()

	var selected_fleet: Dictionary = GameState.get_fleet_by_id(GameState.selected_fleet_id)
	var selected_system: Dictionary = GameState.get_system_by_id(GameState.selected_system_id)
	right_drawer.visible = not selected_fleet.is_empty() or not selected_system.is_empty()
	_panel_content = drawer_content

	if not selected_fleet.is_empty():
		drawer_title.text = "舰队指挥"
		drawer_subtitle.text = ""
		drawer_subtitle.visible = false
		_build_fleet_panel(selected_fleet)
	elif not selected_system.is_empty():
		drawer_title.text = "星系建设"
		drawer_subtitle.text = ""
		drawer_subtitle.visible = false
		_build_system_panel(selected_system)

func _rebuild_bottom_tabs() -> void:
	_configure_tab_button(objectives_button, "OBJECTIVES", GameState.active_tab == "OBJECTIVES")
	_configure_tab_button(tech_button, "TECH", GameState.active_tab == "TECH")
	_configure_tab_button(diplomacy_button, "DIPLOMACY", GameState.active_tab == "DIPLOMACY")
	_configure_tab_button(communications_button, "COMMS", GameState.active_tab == "COMMS")

func _build_objectives_panel() -> void:
	var victory_report: Dictionary = GameState.get_victory_progress_report()
	var military_report: Dictionary = victory_report.get("military", {})
	var diplomatic_report: Dictionary = victory_report.get("diplomatic", {})
	var science_report: Dictionary = victory_report.get("science", {})
	_panel_add(_make_section_title("当前目标"))
	_panel_add(_make_status_card(
		"当前目标",
		_objective_summary_lines()
	))
	_panel_add(_make_section_title("胜利进度"))
	_panel_add(_make_status_card(
		"军事胜利",
		[
			"军事控制: %s/%s 可居住星系" % [str(military_report.get("controlled_habitable_systems", 0)), str(military_report.get("required_control", 0))],
			"敌方首都: %s/%s" % [str(military_report.get("captured_capitals", 0)), str(military_report.get("rival_capitals", 0))],
			"军事胜利就绪: %s" % ("是" if bool(military_report.get("achieved", false)) else "否")
		]
	))
	_panel_add(_make_status_card(
		"外交胜利",
		[
			"外交网络: 同盟 %s / 协定 %s / 和平 %s" % [
				str(diplomatic_report.get("alliances", 0)),
				str(diplomatic_report.get("accords", 0)),
				str(diplomatic_report.get("peace_partners", 0))
			],
			"联合国: %s / %s" % [
				"已成立" if bool(diplomatic_report.get("council_established", false)) else "未成立",
				str(diplomatic_report.get("speaker_title", "未设立"))
			],
			"宪章表决: %s (%s/%s)" % [
				_charter_status_label(str(diplomatic_report.get("charter_status", "INACTIVE"))),
				str(diplomatic_report.get("votes_for", 0)),
				str(diplomatic_report.get("required_votes", 0))
			],
			"外交胜利就绪: %s" % ("是" if bool(diplomatic_report.get("achieved", false)) else "否")
		]
	))
	_panel_add(_make_status_card(
		"科技飞升",
		[
			"飞升阶段: %s" % _ascension_phase_label(str(science_report.get("phase_label", "INACTIVE"))),
			"飞升进度: %s/100" % str(science_report.get("progress", 0)),
			"阶段摘要: %s" % str(science_report.get("status_summary", "-")),
			"奇观选址: %s" % str(science_report.get("best_site_name", "-"))
		]
	))
	var owned_systems: Array = GameLogicScript.owned_systems(GameState.game_state, GameState.PLAYER_FACTION_ID)
	var player_fleets: Array = GameState.get_player_fleets()
	var player_queue_count: int = 0
	for queue_item: Dictionary in GameState.game_state.get("constructionQueue", []):
		if queue_item.get("ownerId", "") == GameState.PLAYER_FACTION_ID:
			player_queue_count += 1
	var player_queue_items: Array = GameState.get_player_queue_items()
	var active_events: Array = GameState.get_active_narrative_events()
	_panel_add(_make_summary_card(
		"帝国总览",
		[
			"控制星系: %s" % str(owned_systems.size()),
			"现役舰队: %s" % str(player_fleets.size()),
			"在建项目: %s" % str(player_queue_count),
			"待处理事件: %s" % str(active_events.size())
		]
	))
	if not owned_systems.is_empty():
		_panel_add(_make_section_title("控制星系"))
		for system: Dictionary in owned_systems.slice(0, min(4, owned_systems.size())):
			_panel_add(_make_status_card(
				str(system.get("name", "未知星系")),
				[
					"资源: %s" % _resource_line(system.get("resources", {}))
				]
			))
	if not player_fleets.is_empty():
		_panel_add(_make_section_title("现役舰队"))
		for fleet: Dictionary in player_fleets.slice(0, min(4, player_fleets.size())):
			_panel_add(_make_status_card(
				str(fleet.get("name", "舰队")),
				[
					"位置: %s / 任务: %s" % [
						str(GameState.get_system_by_id(fleet.get("systemId", "")).get("name", fleet.get("systemId", ""))),
						GameLogicScript.fleet_mission_label(str(fleet.get("mission", "IDLE")))
					]
				]
			))
	if not player_queue_items.is_empty():
		_panel_add(_make_section_title("在建项目"))
		for queue_item: Dictionary in player_queue_items.slice(0, min(5, player_queue_items.size())):
			var queue_system: Dictionary = GameState.get_system_by_id(queue_item.get("systemId", ""))
			var queue_kind: String = "舰船" if queue_item.get("kind", "") == "SHIP" else "建筑"
			_panel_add(_make_queue_item_card(
				str(queue_item.get("displayName", "未命名项目")),
				"类型: %s / 星系: %s" % [queue_kind, str(queue_system.get("name", queue_item.get("systemId", "")))],
				"剩余回合: %s/%s" % [str(queue_item.get("turnsRemaining", 0)), str(queue_item.get("totalTurns", 0))]
			))
	if not active_events.is_empty():
		_panel_add(_make_section_title("当前事件"))
		for event_item: Dictionary in active_events.slice(0, min(4, active_events.size())):
			_panel_add(_make_feed_card(
				"%s @ %s" % [str(event_item.get("title", "未知事件")), GameState.get_system_by_id(event_item.get("systemId", "")).get("name", event_item.get("systemId", ""))],
				"阶段: %s" % str(event_item.get("chainStage", 1)),
				str(event_item.get("summary", "")),
				""
			))
			var options_row: HBoxContainer = _action_row()
			for option: String in event_item.get("followUpOptions", []):
				options_row.add_child(_make_action_button(option, GameState.resolve_narrative_event.bind(event_item.get("id", ""), option)))
			_panel_add(options_row)
	var interventions: Array = GameState.get_active_interventions()
	if not interventions.is_empty():
		_panel_add(_make_section_title("导演干预"))
		for item: Dictionary in interventions.slice(0, min(4, interventions.size())):
			_panel_add(_make_status_card(
				str(item.get("type", "INTERVENTION")),
				[
					"剩余回合: %s / 强度: %s" % [str(item.get("remainingTurns", 0)), str(item.get("intensity", 0.0))]
				]
			))
	var messages: Array = GameState.game_state.get("messages", [])
	if not messages.is_empty():
		_panel_add(_make_section_title("消息"))
		for message: Dictionary in messages.slice(0, min(6, messages.size())):
			_panel_add(_make_feed_card(
				"T%s | %s" % [str(message.get("turn", 1)), message.get("title", "")],
				"",
				str(message.get("content", "")),
				""
			))
	var combat_reports: Array = GameState.get_recent_combat_reports()
	if not combat_reports.is_empty():
		_panel_add(_make_section_title("战斗报告"))
		for report: Dictionary in combat_reports.slice(0, min(3, combat_reports.size())):
			_panel_add(_make_feed_card(
				"T%s | %s" % [str(report.get("turn", 1)), str(report.get("title", "战斗结果"))],
				"%s vs %s" % [str(report.get("attackerName", "进攻方")), str(report.get("defenderName", "防守方"))],
				"结果: %s / 损失: %s / 击毁: %s / 剩余战力: %s%%" % [
					"胜利" if report.get("victory", false) else "失利",
					str(report.get("casualties", 0)),
					str(report.get("kills", 0)),
					str(report.get("remainingPower", 0))
				],
				"备注: %s" % " / ".join(report.get("tacticalNotes", []))
			))
	_panel_add(_make_action_button("重置游戏", GameState.reset_state))

func _build_tech_panel() -> void:
	var current_research_id: Variant = GameState.game_state.get("currentResearchId", null)
	var layout: HBoxContainer = _make_two_column_layout()
	var current_column: VBoxContainer = _make_layout_column()
	var available_column: VBoxContainer = _make_layout_column()
	current_column.size_flags_stretch_ratio = 0.82
	available_column.size_flags_stretch_ratio = 1.45
	layout.add_child(current_column)
	layout.add_child(available_column)
	current_column.add_child(_make_section_title("当前研究"))
	var has_current_research: bool = false
	var available_count: int = 0
	var available_categories: Dictionary = {}
	for tech: Dictionary in GameState.game_state.get("technologies", []):
		if tech.get("status", "") != "AVAILABLE":
			continue
		available_count += 1
		var category_key: String = str(tech.get("category", "UNKNOWN"))
		available_categories[category_key] = int(available_categories.get(category_key, 0)) + 1
	if current_research_id != null:
		for tech: Dictionary in GameState.game_state.get("technologies", []):
			if tech.get("id", "") == str(current_research_id):
				current_column.add_child(_make_tech_card(tech, true))
				var cancel_button: Button = _make_action_button("取消当前研究", GameState.cancel_research, "danger")
				cancel_button.pressed.connect(_refresh_visible_panels)
				current_column.add_child(cancel_button)
				has_current_research = true
				break
	if not has_current_research:
		current_column.add_child(_make_status_card("当前研究", ["尚未选择研究项目。"]))
	current_column.add_child(_make_section_title("研究概览"))
	current_column.add_child(_make_status_card(
		"研究概览",
		[
			"可研究项目: %s" % str(available_count),
			"科技方向: %s" % _tech_category_counts_text(available_categories)
		]
	))
	available_column.add_child(_make_section_title("可研究项目"))
	var available_grid: GridContainer = GridContainer.new()
	available_grid.columns = 1
	available_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	available_grid.add_theme_constant_override("h_separation", 12)
	available_grid.add_theme_constant_override("v_separation", 12)
	for tech: Dictionary in GameState.game_state.get("technologies", []):
		if tech.get("status", "") != "AVAILABLE":
			continue
		var tech_bundle: VBoxContainer = VBoxContainer.new()
		tech_bundle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tech_bundle.add_theme_constant_override("separation", 6)
		tech_bundle.add_child(_make_tech_card(tech, false))
		var button: Button = _make_action_button("开始研究", GameState.start_research.bind(tech.get("id", "")), "primary")
		button.custom_minimum_size = Vector2(0, 46)
		button.disabled = current_research_id != null
		button.pressed.connect(_refresh_visible_panels)
		tech_bundle.add_child(button)
		available_grid.add_child(tech_bundle)
	if available_count == 0:
		available_column.add_child(_make_status_card("可研究项目", ["当前没有可选科技。"]))
	else:
		available_column.add_child(_make_local_scroll(available_grid, 480.0))
	_panel_add(layout)

func _build_diplomacy_panel() -> void:
	_panel_add(_make_section_title("外交对象"))
	var target_grid: GridContainer = GridContainer.new()
	target_grid.columns = 2
	target_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_grid.add_theme_constant_override("h_separation", 12)
	target_grid.add_theme_constant_override("v_separation", 12)
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogicScript.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var active_treaties: Array = GameLogicScript.active_treaties_between(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var history: Array = GameState.get_relation_history(faction.get("id", ""))
		var target_tile: VBoxContainer = VBoxContainer.new()
		target_tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_tile.add_theme_constant_override("separation", 8)
		target_tile.add_child(_make_feed_card(
			"%s / %s" % [str(faction.get("name", "")), str(faction.get("leaderName", ""))],
			"关系: %s" % RELATION_LEVEL_NAMES.get(str(relation.get("level", "UNKNOWN")), str(relation.get("level", "UNKNOWN"))),
			"信任 %s / 好感 %s / 威胁 %s\n条约: %s\n语气: %s" % [
				str(relation.get("trust", 0)),
				str(relation.get("affinity", 0)),
				str(relation.get("fear", 0)),
				_treaty_names_text(active_treaties),
				_tone_label(str(faction.get("diplomaticProfile", {}).get("recentTone", "neutral")))
			],
			"",
			str(faction.get("portraitPath", ""))
		))
		var detail_row: HBoxContainer = _action_row()
		detail_row.add_child(_make_action_button("进入外交", _open_faction_modal.bind(faction, relation, active_treaties, history), "primary"))
		detail_row.add_child(_make_action_button("发送照会", GameState.request_diplomatic_message.bind(faction.get("id", ""), "friendly"), "accent"))
		target_tile.add_child(detail_row)
		target_grid.add_child(target_tile)
	_panel_add(target_grid)

func _build_communications_panel() -> void:
	_panel_add(_make_section_title("重要时间线"))
	var timeline_entries: Array = GameState.get_recent_intelligence_feed()
	if timeline_entries.is_empty():
		_panel_add(_make_status_card("重要时间线", ["当前没有需要处理的重要信息。"]))
	else:
		var seen_timeline_keys: Dictionary = {}
		for entry: Dictionary in timeline_entries:
			var timeline_key: String = "%s:%s" % [str(entry.get("turn", GameState.game_state.get("turn", 1))), str(entry.get("title", "重要信息"))]
			if seen_timeline_keys.has(timeline_key):
				continue
			seen_timeline_keys[timeline_key] = true
			_panel_add(_make_feed_card(
				str(entry.get("title", "重要信息")),
				"T%s / %s" % [str(entry.get("turn", GameState.game_state.get("turn", 1))), _message_type_label(str(entry.get("category", "EVENT")))],
				_truncate_text(str(entry.get("summary", "")), 112),
				"",
				_faction_emblem_path(GameState.PLAYER_FACTION_ID)
			))

func _build_system_panel(system: Dictionary) -> void:
	var queue_items: Array = []
	var structure_queue_count: int = 0
	var ship_queue_count: int = 0
	for item: Dictionary in GameState.game_state.get("constructionQueue", []):
		if item.get("systemId", "") == system.get("id", ""):
			queue_items.append(item)
			if item.get("kind", "") == "BUILDING":
				structure_queue_count += 1
			else:
				ship_queue_count += 1

	_panel_add(_make_section_title(system.get("name", "")))
	_panel_add(_make_summary_card(
		"星系概览",
		[
			"归属: %s" % GameState.get_owner_name(system.get("ownerId", null)),
			str(system.get("note", "")),
			"资源: %s" % _resource_line(system.get("resources", {})),
			"建筑格位: %s/%s" % [str(system.get("buildings", []).size() + queue_items.size()), str(system.get("buildingSlots", 0))],
			"宜居度: %s" % str(system.get("habitability", 0))
		]
	))
	if not queue_items.is_empty():
		_panel_add(_make_summary_card(
			"队列摘要",
			[
				"队列摘要: 建筑 %s / 舰船 %s" % [str(structure_queue_count), str(ship_queue_count)],
				"当前重心: %s" % ("舰队扩张" if ship_queue_count > structure_queue_count else "基础建设" if structure_queue_count > ship_queue_count else "均衡发展")
			]
		))
	if system.get("colonyStage", "NONE") != "NONE":
		_panel_add(_make_status_card(
			"殖民状态",
			[
				"殖民阶段: %s" % _colony_stage_name(system.get("colonyStage", "NONE")),
				"殖民模式: %s" % InitialDataScript.colonization_modes().get(system.get("colonizationMode", ""), {}).get("name", system.get("colonizationMode", "未知")),
				"殖民进度: %s%%" % str(int(round(float(system.get("colonizationProgress", 0.0))))),
				"剩余回合: %s" % str(system.get("colonizationTurnsRemaining", 0)),
				"稳定度: %s" % str(system.get("stability", 0)),
				"补给等级: %s" % str(system.get("supplyLevel", 0)),
				"殖民风险: %s" % str(system.get("colonizationRisk", "未知"))
			]
		))
	if not system.get("buildings", []).is_empty():
		_panel_add(_make_section_title("已建成建筑"))
		for item: Dictionary in system.get("buildings", []):
			_panel_add(_make_built_building_card(item))
	if not queue_items.is_empty():
		_panel_add(_make_section_title("当前队列"))
		for item: Dictionary in queue_items:
			var queue_kind_label: String = "建筑" if item.get("kind", "") == "BUILDING" else "舰船"
			_panel_add(_make_queue_item_card(
				str(item.get("displayName", "")),
				"类型: %s" % queue_kind_label,
				"剩余回合: %s/%s" % [str(item.get("turnsRemaining", 0)), str(item.get("totalTurns", 0))]
			))
	if system.get("ownerId", null) == GameState.PLAYER_FACTION_ID:
		_panel_add(_make_section_title("可建造建筑"))
		for building: Dictionary in GameState.available_buildings():
			_panel_add(_make_building_card(building))
			var building_actions: HBoxContainer = _action_row()
			var building_button: Button = _make_action_button("加入队列", GameState.queue_structure.bind(system.get("id", ""), building.get("type", "")))
			var building_block_reason: String = _building_queue_block_reason(system, building)
			building_button.disabled = building_block_reason != ""
			building_button.tooltip_text = building_block_reason
			building_actions.add_child(building_button)
			_panel_add(building_actions)
		var has_shipyard: bool = false
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "SHIPYARD":
				has_shipyard = true
		if has_shipyard:
			_panel_add(_make_section_title("可建造舰船"))
			for ship_type: String in GameState.available_ship_types():
				var cost: Dictionary = GameLogicScript.ship_cost(ship_type, GameState.game_state, GameState.PLAYER_FACTION_ID)
				_panel_add(_make_status_card(
					"%s" % InitialDataScript.ship_labels().get(ship_type, ship_type),
					[
						"花费: %s" % _resource_line(cost),
						"建造时间: %s 回合" % str(InitialDataScript.ship_turns().get(ship_type, 1))
					]
				))
				var ship_actions: HBoxContainer = _action_row()
				var ship_button: Button = _make_action_button("建造%s" % InitialDataScript.ship_labels().get(ship_type, ship_type), GameState.queue_ship.bind(system.get("id", ""), ship_type))
				var ship_block_reason: String = _ship_queue_block_reason(ship_type, 1)
				ship_button.disabled = ship_block_reason != ""
				ship_button.tooltip_text = ship_block_reason
				ship_actions.add_child(ship_button)
				var ship_batch_button: Button = _make_action_button("排队3艘%s" % InitialDataScript.ship_labels().get(ship_type, ship_type), GameState.queue_ship_batch.bind(system.get("id", ""), ship_type, 3))
				var ship_batch_block_reason: String = _ship_queue_block_reason(ship_type, 3)
				ship_batch_button.disabled = ship_batch_block_reason != ""
				ship_batch_button.tooltip_text = ship_batch_block_reason
				ship_actions.add_child(ship_batch_button)
				_panel_add(ship_actions)
	var system_actions: HBoxContainer = _action_row()
	if GameState.selected_fleet_id != "":
		system_actions.add_child(_make_action_button("探索星系", GameState.explore_system.bind(system.get("id", ""))))
	if system_actions.get_child_count() > 0:
		_panel_add(system_actions)
	if GameState.selected_fleet_id != "" and system.get("colonyStage", "NONE") == "NONE":
		_panel_add(_make_section_title("殖民方案"))
		for mode_key: String in GameState.colonization_modes().keys():
			var mode_data: Dictionary = GameState.colonization_modes().get(mode_key, {})
			var preview: Dictionary = GameState.colonization_preview(system.get("id", ""), mode_key)
			_panel_add(_make_colonization_option_card(mode_key, mode_data, preview))
			var colonize_button: Button = _make_action_button("殖民%s" % mode_data.get("name", mode_key), GameState.colonize_system.bind(system.get("id", ""), mode_key))
			colonize_button.disabled = not preview.get("allowed", false)
			_panel_add(colonize_button)

func _build_fleet_panel(fleet: Dictionary) -> void:
	var total_hp: int = 0
	var total_max_hp: int = 0
	var total_damage: int = 0
	var owner_faction: Dictionary = GameState.get_faction_by_id(fleet.get("ownerId", ""))
	var reachable_routes: Array = GameState.get_reachable_system_details(fleet.get("id", ""))
	var player_energy: int = int(GameState.get_player_faction().get("resources", {}).get("energy", 0))
	var fleet_is_colonizing: bool = str(fleet.get("mission", "IDLE")) == "COLONIZING"
	for ship: Dictionary in fleet.get("ships", []):
		total_hp += int(ship.get("hp", 0))
		total_max_hp += int(ship.get("maxHp", 0))
		total_damage += int(ship.get("damage", 0))
	_panel_add(_make_section_title(fleet.get("name", "")))
	_panel_add(_make_icon_stat_grid([
		_make_icon_stat_entry("fleet", "舰船", str(fleet.get("ships", []).size())),
		_make_icon_stat_entry("mission", "任务", GameLogicScript.fleet_mission_label(str(fleet.get("mission", "IDLE")))),
		_make_icon_stat_entry("health", "生命", "%s/%s" % [str(total_hp), str(total_max_hp)]),
		_make_icon_stat_entry("damage", "火力", str(total_damage)),
		_make_icon_stat_entry("cooldown", "冷却", str(int(fleet.get("movementCooldown", 0)))),
		_make_icon_stat_entry("route", "航线", str(reachable_routes.size())),
	]))
	_panel_add(_make_section_title("指令"))
	var mission_buttons: Array[Button] = [
		_make_action_button("待命", GameState.set_selected_fleet_mission.bind("IDLE"), "neutral"),
		_make_action_button("探索", GameState.set_selected_fleet_mission.bind("EXPLORE"), "primary"),
		_make_action_button("殖民", GameState.set_selected_fleet_mission.bind("COLONIZE"), "accent"),
		_make_action_button("驻防", GameState.set_selected_fleet_mission.bind("GUARD"), "neutral"),
		_make_action_button("打击", GameState.set_selected_fleet_mission.bind("STRIKE"), "danger")
	]
	if fleet_is_colonizing:
		for button: Button in mission_buttons:
			button.disabled = true
			button.tooltip_text = "殖民部署中"
	_panel_add(_make_action_grid(mission_buttons, 2))
	var move_mode_active: bool = GameState.fleet_move_mode and GameState.selected_fleet_id == str(fleet.get("id", ""))
	var start_move_button: Button = _make_action_button("移动", GameState.begin_fleet_move_mode.bind(fleet.get("id", "")), "primary")
	start_move_button.disabled = move_mode_active or fleet_is_colonizing or int(fleet.get("movementCooldown", 0)) > 0 or reachable_routes.is_empty()
	if fleet_is_colonizing:
		start_move_button.tooltip_text = "殖民部署中"
	elif move_mode_active:
		start_move_button.tooltip_text = "已启用"
	elif int(fleet.get("movementCooldown", 0)) > 0:
		start_move_button.tooltip_text = "冷却中"
	elif reachable_routes.is_empty():
		start_move_button.tooltip_text = "无航线"
	var cancel_move_button: Button = _make_action_button("取消", GameState.cancel_fleet_move_mode, "neutral")
	cancel_move_button.disabled = not move_mode_active
	if not move_mode_active:
		cancel_move_button.tooltip_text = "未启用"
	var repair_button: Button = _make_action_button("修复", GameState.repair_fleet.bind(fleet.get("id", "")), "accent")
	repair_button.disabled = total_hp >= total_max_hp
	if repair_button.disabled:
		repair_button.tooltip_text = "满状态"
	var split_button: Button = _make_action_button("拆分", GameState.split_selected_fleet, "neutral")
	split_button.disabled = fleet_is_colonizing or fleet.get("ships", []).size() < 2
	if fleet_is_colonizing:
		split_button.tooltip_text = "殖民部署中"
	elif split_button.disabled:
		split_button.tooltip_text = "舰船不足"
	var merge_button: Button = _make_action_button("合并", GameState.merge_player_fleets_at_selected_system, "accent")
	merge_button.disabled = fleet_is_colonizing or GameState.get_player_fleets_in_system(str(fleet.get("systemId", ""))).size() < 2
	if fleet_is_colonizing:
		merge_button.tooltip_text = "殖民部署中"
	elif merge_button.disabled:
		merge_button.tooltip_text = "无可合并舰队"
	_panel_add(_make_action_grid([
		start_move_button,
		cancel_move_button,
		repair_button,
		split_button,
		merge_button
	], 2))
	var current_system: Dictionary = GameState.get_system_by_id(str(fleet.get("systemId", "")))
	if not current_system.is_empty():
		_add_current_fleet_system_actions(current_system)
	var fleet_status_fleet_id: String = str(GameState.world_data.get("fleet_status_fleet_id", ""))
	var fleet_status_report: Dictionary = GameState.world_data.get("fleet_status_report", {})
	if not fleet_status_report.is_empty() and fleet_status_fleet_id == str(fleet.get("id", "")):
		var detail_lines: Array = [
			"位置: %s" % str(fleet_status_report.get("location", "未知")),
			"战备状态: %s" % _fleet_readiness_label(str(fleet_status_report.get("readiness", "CRITICAL")))
		]
		for ship_entry: Dictionary in fleet_status_report.get("unit_composition", []).slice(0, 4):
			detail_lines.append("%s / %s / %s/%s 生命 / %s 伤害" % [
				str(ship_entry.get("name", "舰船")),
				str(ship_entry.get("type", "UNKNOWN")),
				str(ship_entry.get("hp", 0)),
				str(ship_entry.get("maxHp", 0)),
				str(ship_entry.get("damage", 0))
			])
		_panel_add(_make_api_report_card(
			"状态评估",
			"任务: %s / 舰队强度: %s" % [
				str(fleet_status_report.get("mission", "未知")),
				str(fleet_status_report.get("strength", 0))
			],
			detail_lines
		))
	_panel_add(_make_section_title("航线"))
	if reachable_routes.is_empty():
		_panel_add(_make_status_card("航线", ["无直接航线"]))
	for ship: Dictionary in fleet.get("ships", []):
		_panel_add(_make_fleet_ship_card(ship, owner_faction))
	for route: Dictionary in reachable_routes:
		var system_id: String = str(route.get("systemId", ""))
		var system: Dictionary = GameState.get_system_by_id(system_id)
		var fits_bandwidth: bool = bool(route.get("fitsBandwidth", true))
		_panel_add(_make_route_card(route, system, fits_bandwidth))
		var route_buttons: Array[Button] = [
			_make_action_button("查看%s" % system.get("name", system_id), GameState.focus_system.bind(system_id), "neutral")
		]
		var scout_button: Button = _make_action_button("侦察", GameState.explore_system.bind(system_id), "neutral")
		scout_button.disabled = fleet_is_colonizing or str(system.get("visibilityLevel", "HIDDEN")) != "HIDDEN"
		if fleet_is_colonizing:
			scout_button.tooltip_text = "殖民部署中"
		elif scout_button.disabled:
			scout_button.tooltip_text = "该星系已完成远程侦察，抵达后可完整探索。"
		route_buttons.append(scout_button)
		var jump_button: Button = _make_action_button("跃迁至此", GameState.move_selected_fleet.bind(system_id), "primary")
		var traversal_cost: int = int(route.get("traversalCost", 1))
		var can_jump: bool = not fleet_is_colonizing and fits_bandwidth and int(fleet.get("movementCooldown", 0)) <= 0 and player_energy >= traversal_cost
		jump_button.disabled = not can_jump
		if fleet_is_colonizing:
			jump_button.tooltip_text = "殖民部署中"
		elif not fits_bandwidth:
			jump_button.tooltip_text = "当前航道容量不足，舰队规模超出上限。"
		elif int(fleet.get("movementCooldown", 0)) > 0:
			jump_button.tooltip_text = "舰队仍在移动冷却中。"
		elif player_energy < traversal_cost:
			jump_button.tooltip_text = "能源不足，无法支付本次跃迁消耗。"
		route_buttons.append(jump_button)
		_panel_add(_make_action_grid(route_buttons, 2))

func _add_current_fleet_system_actions(system: Dictionary) -> void:
	var rows: Array[Button] = []
	if str(system.get("visibilityLevel", "HIDDEN")) != "FULL":
		rows.append(_make_action_button("探索当前星系", GameState.explore_system.bind(system.get("id", "")), "primary"))
	if system.get("ownerId", null) == null and system.get("colonyStage", "NONE") == "NONE":
		for mode_key: String in GameState.colonization_modes().keys():
			var mode_data: Dictionary = GameState.colonization_modes().get(mode_key, {})
			var preview: Dictionary = GameState.colonization_preview(system.get("id", ""), mode_key)
			var colonize_button: Button = _make_action_button(str(mode_data.get("name", mode_key)), GameState.colonize_system.bind(system.get("id", ""), mode_key), "accent")
			colonize_button.disabled = not bool(preview.get("allowed", false))
			colonize_button.tooltip_text = "%s / 花费 %s" % [
				str(preview.get("reason", "")),
				_resource_line(preview.get("cost", mode_data.get("cost", {})))
			]
			rows.append(colonize_button)
	if rows.is_empty():
		return
	_panel_add(_make_section_title("当前星系"))
	_panel_add(_make_action_grid(rows, 2))

func _building_queue_block_reason(system: Dictionary, building: Dictionary) -> String:
	var system_id: String = str(system.get("id", ""))
	var building_type: String = str(building.get("type", ""))
	var queued_buildings: int = GameLogicScript.queued_building_count_for_system(GameState.game_state, system_id)
	if int(system.get("buildings", []).size()) + queued_buildings >= int(system.get("buildingSlots", 0)):
		return "建筑格位已满"
	if building_type == "SHIPYARD":
		for built: Dictionary in system.get("buildings", []):
			if str(built.get("type", "")) == "SHIPYARD":
				return "已建成"
	for item: Dictionary in GameState.game_state.get("constructionQueue", []):
		if str(item.get("systemId", "")) == system_id and str(item.get("kind", "")) == "BUILDING" and str(item.get("targetId", "")) == building_type:
			return "已在队列中"
	if not GameLogicScript.can_afford(GameState.get_player_faction().get("resources", {}), building.get("cost", {})):
		return "资源不足"
	return ""

func _ship_queue_block_reason(ship_type: String, count: int = 1) -> String:
	var cost: Dictionary = GameLogicScript.ship_cost(ship_type, GameState.game_state, GameState.PLAYER_FACTION_ID)
	var total_cost: Dictionary = _scaled_resource_bundle(cost, count)
	if not GameLogicScript.can_afford(GameState.get_player_faction().get("resources", {}), total_cost):
		return "资源不足"
	return ""

func _scaled_resource_bundle(bundle: Dictionary, multiplier: int) -> Dictionary:
	var result: Dictionary = {}
	for key: String in RESOURCE_NAMES.keys():
		result[key] = int(bundle.get(key, 0)) * maxi(1, multiplier)
	return result

func _make_building_card(building: Dictionary) -> PanelContainer:
	var card: PanelContainer = BUILDING_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = "%s / %s 回合" % [building.get("name", ""), str(InitialDataScript.building_turns().get(building.get("type", ""), 1))]
	card.get_node("Content/Description").text = str(building.get("description", ""))
	card.get_node("Content/Cost").text = "建造成本: %s" % _resource_line(building.get("cost", {}))
	card.get_node("Content/Production").text = "产出: %s" % _resource_line(building.get("production", {}), true)
	card.get_node("Content/Maintenance").text = "维护费: %s" % _resource_line(building.get("maintenance", {}))
	card.get_node("Content/Housing").text = "住房: %s" % str(building.get("housing", 0))
	return card

func _make_built_building_card(building: Dictionary) -> PanelContainer:
	var card: PanelContainer = BUILDING_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = str(building.get("name", ""))
	card.get_node("Content/Description").text = "已建成建筑"
	card.get_node("Content/Cost").text = "产出: %s" % _resource_line(building.get("production", {}), true)
	card.get_node("Content/Production").text = "维护费: %s" % _resource_line(building.get("maintenance", {}))
	card.get_node("Content/Maintenance").text = "住房: %s" % str(building.get("housing", 0))
	card.get_node("Content/Housing").text = "类型: %s" % str(building.get("type", "UNKNOWN"))
	return card

func _make_tech_card(tech: Dictionary, researching: bool) -> PanelContainer:
	var card: PanelContainer = TECH_CARD_SCENE.instantiate()
	var category_key: String = str(tech.get("category", "UNKNOWN"))
	var category_color: Color = _tech_category_color(category_key)
	card.get_node("Content/CategoryAccent").color = category_color
	var category_label: Label = card.get_node("Content/StatusRow/CategoryLabel")
	category_label.text = "方向: %s / T%s" % [TECH_CATEGORY_LABELS.get(category_key, category_key), str(tech.get("tier", 1))]
	category_label.add_theme_color_override("font_color", category_color)
	var status_pill: Label = card.get_node("Content/StatusRow/StatusPill")
	status_pill.text = _tech_status_label(tech, researching)
	status_pill.add_theme_color_override("font_color", _tech_status_color(tech, researching))
	card.get_node("Content/Title").text = str(tech.get("name", ""))
	card.get_node("Content/Description").text = str(tech.get("description", ""))
	var meta_label: Label = card.get_node("Content/Meta")
	meta_label.text = _tech_meta_line(tech, researching)
	var effects_list: VBoxContainer = card.get_node("Content/Columns/EffectsColumn/EffectsList")
	var unlocks_list: VBoxContainer = card.get_node("Content/Columns/UnlocksColumn/UnlocksList")
	if researching:
		effects_list.add_child(_make_rich_info_line("当前进度: %.0f/%s" % [_tech_research_progress_value(tech, researching), str(tech.get("cost", 0))], category_color))
	for effect: String in tech.get("effects", []):
		effects_list.add_child(_make_rich_info_line("• %s" % effect))
	for unlock_name: String in tech.get("unlocks", []):
		unlocks_list.add_child(_make_rich_info_line("• %s" % unlock_name, Color("2F6672")))
	if effects_list.get_child_count() == 0:
		effects_list.add_child(_make_rich_info_line("• 无直接加成"))
	if unlocks_list.get_child_count() == 0:
		unlocks_list.add_child(_make_rich_info_line("• 无新增解锁", Color("2F6672")))
	return card

func _tech_category_color(category_key: String) -> Color:
	match category_key:
		"ECONOMY":
			return Color("B36A00")
		"MILITARY":
			return Color("B83325")
		"SCIENCE":
			return Color("2F6672")
		"EXPANSION":
			return Color("3A6D4B")
		_:
			return Color("2C3438")

func _tech_status_label(tech: Dictionary, researching: bool) -> String:
	if researching:
		return "进行中"
	match str(tech.get("status", "UNKNOWN")):
		"AVAILABLE":
			return "可研究"
		"RESEARCHED":
			return "已完成"
		"LOCKED":
			return "锁定"
		_:
			return "待评估"

func _tech_status_color(tech: Dictionary, researching: bool) -> Color:
	if researching:
		return Color("B36A00")
	match str(tech.get("status", "UNKNOWN")):
		"AVAILABLE":
			return Color("2F6672")
		"RESEARCHED":
			return Color("3A6D4B")
		"LOCKED":
			return Color("69757A")
		_:
			return Color("2C3438")

func _tech_meta_line(tech: Dictionary, researching: bool) -> String:
	var progress_value: float = _tech_research_progress_value(tech, researching)
	if researching:
		return "进度: %.0f/%s / 周期: %s 回合 / 成本: %s" % [
			progress_value,
			str(tech.get("cost", 0)),
			str(tech.get("researchTime", 0)),
			str(tech.get("cost", 0))
		]
	var prerequisites: Array = tech.get("prerequisites", [])
	var prerequisite_text: String = "无" if prerequisites.is_empty() else str(prerequisites.size()) + " 项"
	return "周期: %s 回合 / 成本: %s / 前置: %s" % [
		str(tech.get("researchTime", 0)),
		str(tech.get("cost", 0)),
		prerequisite_text
	]

func _tech_research_progress_value(tech: Dictionary, researching: bool) -> float:
	if researching:
		return float(GameState.game_state.get("researchProgress", tech.get("progress", 0.0)))
	return float(tech.get("progress", 0.0))


func _action_row() -> HBoxContainer:
	return ACTION_ROW_SCENE.instantiate()

func _make_action_grid(buttons: Array[Button], columns: int = 2) -> GridContainer:
	var flow: GridContainer = GridContainer.new()
	flow.columns = max(columns, 1)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for button: Button in buttons:
		button.custom_minimum_size = Vector2(0, 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_child(button)
	return flow

func _make_chip(title: String, value: String) -> PanelContainer:
	var panel: PanelContainer = CHIP_SCENE.instantiate()
	var content: HBoxContainer = panel.get_node("Content")
	var title_label: Label = content.get_node("TextBox/Title")
	title_label.text = title
	var value_label: Label = content.get_node("TextBox/Value")
	value_label.text = value
	return panel

func _make_resource_chip(title: String, amount: int, rate: int) -> PanelContainer:
	var rate_text: String = _signed_int_text(rate)
	return _make_chip(title, "%s (%s)" % [str(amount), rate_text])

func _resource_tooltip_text(resource_key: String) -> String:
	var labels: Dictionary = {
		"base_production": "基础产出",
		"building_maintenance": "建筑维护",
		"fleet_maintenance": "舰队维护",
		"treaty_modifier": "条约修正",
		"net": "本回合净变化"
	}
	var breakdown: Dictionary = GameState.get_resource_breakdown(resource_key)
	var lines: Array[String] = ["%s 明细" % RESOURCE_NAMES.get(resource_key, resource_key)]
	for key: String in ["base_production", "building_maintenance", "fleet_maintenance", "treaty_modifier", "net"]:
		lines.append("%s: %s" % [labels.get(key, key), _signed_int_text(int(breakdown.get(key, 0)))])
	return "\n".join(lines)

func _apply_chip_icon(panel: PanelContainer, icon_key: String) -> void:
	var icon: TextureRect = panel.get_node("Content/Icon")
	icon.texture = _load_texture_cached(str(UI_ICON_PATHS.get(icon_key, "")))
	icon.modulate = Color(0.95, 0.36, 0.08, 0.96)
	icon.visible = icon.texture != null

func _apply_button_icon(button: Button, icon_key: String) -> void:
	button.icon = _load_texture_cached(str(UI_ICON_PATHS.get(icon_key, "")))
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _make_icon_texture(icon_key: String, size: Vector2 = Vector2(18, 18)) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = size
	icon.texture = _load_texture_cached(str(UI_ICON_PATHS.get(icon_key, "")))
	icon.modulate = Color(0.95, 0.36, 0.08, 0.96)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon

func _make_icon_stat_entry(icon_key: String, label: String, value: String) -> Dictionary:
	return {"icon": icon_key, "label": label, "value": value}

func _make_icon_stat_grid(entries: Array[Dictionary]) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for entry: Dictionary in entries:
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 42)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		row.add_child(_make_icon_texture(str(entry.get("icon", "")), Vector2(20, 20)))
		var text_box: VBoxContainer = VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.add_theme_constant_override("separation", 0)
		var label_node: Label = Label.new()
		label_node.text = str(entry.get("label", ""))
		label_node.add_theme_font_size_override("font_size", 11)
		label_node.add_theme_color_override("font_color", Color(0.95, 0.36, 0.08, 0.88))
		var value_node: Label = Label.new()
		value_node.text = str(entry.get("value", ""))
		value_node.add_theme_font_size_override("font_size", 15)
		value_node.add_theme_color_override("font_color", Color(0.88, 0.96, 0.98, 1.0))
		value_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text_box.add_child(label_node)
		text_box.add_child(value_node)
		row.add_child(text_box)
		grid.add_child(row)
	return grid

func _make_action_button(label: String, callable: Callable, variant: String = "default") -> Button:
	var button: Button = ACTION_BUTTON_SCENE.instantiate()
	button.text = label
	_apply_button_variant(button, variant)
	if callable.is_valid():
		button.pressed.connect(_on_action_button_pressed.bind(callable))
	return button

func _on_action_button_pressed(callable: Callable) -> void:
	AudioManager.play_event("ui_tick")
	callable.call()
	call_deferred("_refresh_visible_panels")

func _on_next_turn_pressed() -> void:
	AudioManager.play_event("ui_tick")
	GameState.advance_turn()

func _on_toggle_labels_pressed() -> void:
	AudioManager.play_event("ui_tick")
	GameState.toggle_labels()

func _on_close_modal_pressed() -> void:
	AudioManager.play_event("ui_tick")
	_close_center_modal()

func _apply_button_variant(button: Button, variant: String) -> void:
	match variant:
		"primary":
			button.add_theme_color_override("font_color", Color(0.88, 0.96, 0.98, 1.0))
			button.add_theme_color_override("font_hover_color", Color(0.95, 0.36, 0.08, 1.0))
			button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))
		"accent":
			button.add_theme_color_override("font_color", Color(0.95, 0.36, 0.08, 1.0))
			button.add_theme_color_override("font_hover_color", Color(0.74, 0.23, 0.05, 1.0))
			button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))
		"danger":
			button.add_theme_color_override("font_color", Color(0.65, 0.12, 0.10, 1.0))
			button.add_theme_color_override("font_hover_color", Color(0.95, 0.36, 0.08, 1.0))
			button.add_theme_color_override("font_pressed_color", Color(0.45, 0.08, 0.07, 1.0))
		"neutral":
			button.add_theme_color_override("font_color", Color(0.62, 0.78, 0.82, 1.0))
			button.add_theme_color_override("font_hover_color", Color(0.88, 0.96, 0.98, 1.0))
			button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))
		_:
			button.add_theme_color_override("font_color", Color(0.62, 0.78, 0.82, 1.0))
			button.add_theme_color_override("font_hover_color", Color(0.95, 0.36, 0.08, 1.0))
			button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))

func _make_rich_info_line(text: String, accent_color: Color = Color("B36A00")) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", 14)
	label.add_theme_color_override("default_color", Color("1D2528"))
	label.text = _highlight_numeric_segments(text, accent_color)
	return label

func _highlight_numeric_segments(text: String, accent_color: Color = Color("B36A00")) -> String:
	var regex := RegEx.new()
	regex.compile("([+-]?\\d+(?:\\.\\d+)?(?:%| 回合| 生命| 伤害| 速度| 人口| 稳定度| 矿产| 工业| 能源| 级)?)")
	var color_code: String = accent_color.to_html(false)
	var result: String = text
	var matches: Array[RegExMatch] = regex.search_all(text)
	for index: int in range(matches.size() - 1, -1, -1):
		var match: RegExMatch = matches[index]
		var start: int = match.get_start()
		var finish: int = match.get_end()
		var segment: String = result.substr(start, finish - start)
		result = "%s[color=#%s]%s[/color]%s" % [result.substr(0, start), color_code, segment, result.substr(finish)]
	return result

func _open_center_modal(title: String, subtitle: String, builder: Callable) -> void:
	_update_modal_bounds()
	_modal_payload = {
		"title": title,
		"subtitle": subtitle,
	}
	modal_title.text = title
	modal_subtitle.text = subtitle
	modal_subtitle.visible = subtitle != ""
	for child: Node in modal_content.get_children():
		child.queue_free()
	if builder.is_valid():
		builder.call()
	center_modal_overlay.visible = true

func _open_global_tab_modal(tab_name: String) -> void:
	_open_center_modal(
		TAB_LABELS.get(tab_name, "面板"),
		"",
		func() -> void:
			var previous_content: VBoxContainer = _panel_content
			_panel_content = modal_content
			_build_global_panel(tab_name)
			_panel_content = previous_content
	)

func _close_center_modal() -> void:
	center_modal_overlay.visible = false
	_modal_payload = {}
	for child: Node in modal_content.get_children():
		child.queue_free()
	_panel_content = drawer_content

func _build_global_panel(tab_name: String) -> void:
	match tab_name:
		"TECH":
			_build_tech_panel()
		"DIPLOMACY":
			_build_diplomacy_panel()
		"COMMS":
			_build_communications_panel()
		_:
			_build_objectives_panel()

func _panel_add(node: Node) -> void:
	if _panel_content != null:
		_panel_content.add_child(node)

func _on_center_modal_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.x < center_modal.position.x or event.position.x > center_modal.position.x + center_modal.size.x or event.position.y < center_modal.position.y or event.position.y > center_modal.position.y + center_modal.size.y:
			_close_center_modal()

func _truncate_text(text: String, limit: int = 140) -> String:
	var normalized: String = text.strip_edges()
	if normalized.length() <= limit:
		return normalized
	return "%s..." % normalized.substr(0, limit)

func _open_message_modal(message: Dictionary) -> void:
	_open_center_modal(
		str(message.get("title", "通信详情")),
		"",
		func() -> void:
			modal_content.add_child(_make_feed_card(
				str(message.get("title", "通信")),
				"发送者: %s / T%s" % [str(message.get("senderName", message.get("senderId", ""))), str(message.get("turn", 1))],
				str(message.get("content", "")),
				""
			))
	)

func _open_proposal_modal(proposal: Dictionary) -> void:
	_open_center_modal(
		str(proposal.get("title", "外交提案")),
		"",
		func() -> void:
			modal_content.add_child(_make_proposal_card(proposal))
			var action_row: HBoxContainer = _action_row()
			action_row.add_child(_make_action_button("接受", GameState.accept_diplomatic_proposal.bind(proposal.get("id", "")), "primary"))
			action_row.add_child(_make_action_button("拒绝", GameState.reject_diplomatic_proposal.bind(proposal.get("id", "")), "danger"))
			modal_content.add_child(action_row)
	)

func _proposal_involves_faction(proposal: Dictionary, faction_id: String) -> bool:
	return str(proposal.get("senderFactionId", "")) == faction_id or str(proposal.get("targetFactionId", "")) == faction_id

func _message_involves_faction(message: Dictionary, faction_id: String) -> bool:
	if str(message.get("senderId", "")) == faction_id:
		return true
	for target_id: Variant in message.get("targetIds", []):
		if str(target_id) == faction_id:
			return true
	return false

func _open_faction_modal(faction: Dictionary, relation: Dictionary, active_treaties: Array, history: Array) -> void:
	_open_center_modal(
		"%s / %s" % [str(faction.get("name", "")), str(faction.get("leaderName", ""))],
		"",
		func() -> void:
			var layout: HBoxContainer = _make_two_column_layout()
			var status_column: VBoxContainer = _make_layout_column()
			var action_column: VBoxContainer = _make_layout_column()
			layout.add_child(_make_local_scroll(status_column, 500.0))
			layout.add_child(_make_local_scroll(action_column, 500.0))
			status_column.add_child(_make_feed_card(
				"%s / %s" % [str(faction.get("name", "")), str(faction.get("leaderName", ""))],
				"关系等级: %s" % RELATION_LEVEL_NAMES.get(str(relation.get("level", "UNKNOWN")), str(relation.get("level", "UNKNOWN"))),
				"信任 %s / 好感 %s / 威胁 %s\n条约: %s\n语气: %s" % [
					str(relation.get("trust", 0)),
					str(relation.get("affinity", 0)),
					str(relation.get("fear", 0)),
					_treaty_names_text(active_treaties),
					_tone_label(str(faction.get("diplomaticProfile", {}).get("recentTone", "neutral")))
				],
				"",
				str(faction.get("portraitPath", ""))
			))
			var diplomacy_report: Dictionary = GameState.get_diplomatic_victory_report()
			status_column.add_child(_make_section_title("外交态势"))
			status_column.add_child(_make_status_card(
				"外交态势",
				[
					"联合国: %s" % ("已成立" if bool(diplomacy_report.get("council_established", false)) else "未成立"),
					"宪章: %s / 支持 %s/%s" % [
						_charter_status_label(str(diplomacy_report.get("charter_status", "INACTIVE"))),
						str(diplomacy_report.get("votes_for", 0)),
						str(diplomacy_report.get("required_votes", 0))
					],
					"关系: %s / 信任 %s / 威胁 %s" % [
						RELATION_LEVEL_NAMES.get(str(relation.get("level", "UNKNOWN")), str(relation.get("level", "UNKNOWN"))),
						str(relation.get("trust", 0)),
						str(relation.get("fear", 0))
					]
				]
			))
			status_column.add_child(_make_section_title("通信截获"))
			var interception_report: Dictionary = GameState.get_interception_report()
			status_column.add_child(_make_status_card(
				"通信截获",
				[
					"状态: %s" % str(interception_report.get("status", "未知")),
					"公开/限制/秘密/加密: %s%% / %s%% / %s%% / %s%%" % [
						str(interception_report.get("base", 0)),
						str(interception_report.get("restricted", 0)),
						str(interception_report.get("secret", 0)),
						str(interception_report.get("encrypted", 0))
					]
				]
			))
			action_column.add_child(_make_section_title("提案"))
			var faction_proposals: Array = []
			for proposal: Dictionary in GameState.get_pending_proposals():
				if _proposal_involves_faction(proposal, str(faction.get("id", ""))):
					faction_proposals.append(proposal)
			if faction_proposals.is_empty():
				action_column.add_child(_make_status_card("提案", ["当前没有来自该对象的待处理提案。"]))
			else:
				for proposal: Dictionary in faction_proposals:
					action_column.add_child(_make_proposal_card(proposal))
					var proposal_row: HBoxContainer = _action_row()
					proposal_row.add_child(_make_action_button("详情", _open_proposal_modal.bind(proposal), "neutral"))
					proposal_row.add_child(_make_action_button("接受", GameState.accept_diplomatic_proposal.bind(proposal.get("id", "")), "primary"))
					proposal_row.add_child(_make_action_button("拒绝", GameState.reject_diplomatic_proposal.bind(proposal.get("id", "")), "danger"))
					action_column.add_child(proposal_row)
			action_column.add_child(_make_section_title("回应处理"))
			var faction_messages: Array = []
			for message: Dictionary in GameState.get_visible_diplomatic_messages():
				if _message_involves_faction(message, str(faction.get("id", ""))):
					faction_messages.append(message)
			if not GameState.diplomatic_message.is_empty() and _message_involves_faction(GameState.diplomatic_message, str(faction.get("id", ""))):
				faction_messages.push_front(GameState.diplomatic_message)
			if faction_messages.is_empty():
				action_column.add_child(_make_status_card("回应处理", ["当前没有该对象的新回应。"]))
			else:
				for message: Dictionary in faction_messages.slice(0, min(4, faction_messages.size())):
					action_column.add_child(_make_feed_card(
						str(message.get("title", "通信")),
						"T%s / %s" % [str(message.get("turn", GameState.game_state.get("turn", 1))), str(message.get("senderName", message.get("senderId", "")))],
						_truncate_text(str(message.get("content", "")), 96),
						"",
						_faction_portrait_path(str(message.get("senderId", "")))
					))
					action_column.add_child(_make_action_button("查看详情", _open_message_modal.bind(message), "primary"))
			status_column.add_child(_make_section_title("限制与交易"))
			var action_row: HBoxContainer = _action_row()
			action_row.add_child(_make_action_button("边境限制", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_BORDER_LIMIT", {"scope": "border_expansion"}), "neutral"))
			action_row.add_child(_make_action_button("舰队距离", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_FLEET_DISTANCE", {"distance": "two_jumps"}), "neutral"))
			status_column.add_child(action_row)
			var trade_row: HBoxContainer = _action_row()
			trade_row.add_child(_make_action_button("资源交易", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_RESOURCE_TRADE", {"offer": "minerals_for_energy"}), "accent"))
			trade_row.add_child(_make_action_button("科研互换", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_RESEARCH_EXCHANGE", {"scope": "civilian_science"}), "primary"))
			status_column.add_child(trade_row)
			var diplomatic_action_report: Dictionary = GameState.world_data.get("diplomatic_action_report", {})
			if not diplomatic_action_report.is_empty() and str(diplomatic_action_report.get("target_faction_id", "")) == str(faction.get("id", "")):
				status_column.add_child(_make_api_report_card(
					"外交动作评估",
					"%s / 关系 %s / 声望变化 %s" % [
						str(diplomatic_action_report.get("summary", "暂无结果")),
						RELATION_LEVEL_NAMES.get(str(diplomatic_action_report.get("relationship_level", "UNKNOWN")), str(diplomatic_action_report.get("relationship_level", "UNKNOWN"))),
						_signed_int_text(int(diplomatic_action_report.get("reputation_change", 0)))
					],
					diplomatic_action_report.get("detail_lines", [])
				))
			action_column.add_child(_make_section_title("拟定外交照会"))
			action_column.add_child(_make_diplomacy_composer(faction.get("id", "")))
			modal_content.add_child(layout)
	)

func _make_section_title(text: String) -> Control:
	var section: Control = SECTION_TITLE_SCENE.instantiate()
	var text_label: Label = section.get_node("Margin/Text")
	text_label.text = text
	return section

func _make_info_line(text: String) -> Control:
	var line_panel: Control = INFO_LINE_SCENE.instantiate()
	var text_label: Label = line_panel.get_node("Margin/Text")
	text_label.text = text
	return line_panel

func _make_info_card(lines: Array) -> PanelContainer:
	var panel: PanelContainer = INFO_CARD_SCENE.instantiate()
	var content: VBoxContainer = panel.get_node("Content")
	for raw_line: Variant in lines:
		var line: String = str(raw_line)
		if line == "":
			continue
		content.add_child(_make_info_line(line))
	return panel

func _make_two_column_layout() -> HBoxContainer:
	var layout: HBoxContainer = HBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 16)
	return layout

func _make_layout_column() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	return column

func _make_local_scroll(content: Control, min_height: float = 500.0) -> ScrollContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, min_height)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll

func _load_texture_cached(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if _texture_cache.has(texture_path):
		return _texture_cache.get(texture_path)
	var texture_resource: Texture2D = null
	if texture_path.begins_with("res://"):
		texture_resource = ResourceLoader.load(texture_path) as Texture2D
	elif texture_path.to_lower().ends_with(".png") and FileAccess.file_exists(texture_path):
		var image: Image = Image.load_from_file(texture_path)
		if image != null and not image.is_empty():
			texture_resource = ImageTexture.create_from_image(image)
	else:
		texture_resource = ResourceLoader.load(texture_path) as Texture2D
	_texture_cache[texture_path] = texture_resource
	return texture_resource

func _apply_texture(node: TextureRect, texture_path: String) -> void:
	var texture_resource: Texture2D = _load_texture_cached(texture_path)
	node.texture = texture_resource
	node.visible = texture_resource != null

func _ship_art_path_from_paths(ship_paths: Dictionary, ship_type: String) -> String:
	if ship_paths.has(ship_type):
		return str(ship_paths.get(ship_type, ""))
	if ship_paths.has("CORVETTE"):
		return str(ship_paths.get("CORVETTE", ""))
	return ""

func _catalog_focus_label(value: String) -> String:
	match value:
		"SCIENCE", "ASCENSION":
			return "科技"
		"DIPLOMACY":
			return "外交"
		"DOMINATION":
			return "军事"
		"ECONOMY":
			return "经济"
		"EXPANSION":
			return "扩张"
		_:
			return value

func _faction_portrait_path(faction_id: String) -> String:
	var faction: Dictionary = GameState.get_faction_by_id(faction_id)
	return str(faction.get("portraitPath", ""))

func _faction_emblem_path(faction_id: String) -> String:
	var faction: Dictionary = GameState.get_faction_by_id(faction_id)
	return str(faction.get("emblemPath", ""))

func _configure_diplomacy_card(card: PanelContainer, title: String, subtitle: String, portrait_path: String, emblem_path: String, ship_path: String, stats_text: String, traits_text: String, persona_text: String) -> PanelContainer:
	card.get_node("Content/Header/TitleBox/Title").text = title
	card.get_node("Content/Header/TitleBox/Relation").text = subtitle
	card.get_node("Content/Stats").text = stats_text
	card.get_node("Content/Traits").text = traits_text
	card.get_node("Content/Persona").text = persona_text
	_apply_texture(card.get_node("Content/Header/Portrait"), portrait_path)
	_apply_texture(card.get_node("Content/Header/Emblem"), emblem_path)
	_apply_texture(card.get_node("Content/ShipPreview"), ship_path)
	return card

func _make_status_card(title: String, lines: Array) -> PanelContainer:
	var card: PanelContainer = STATUS_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	var details: VBoxContainer = card.get_node("Content/Details")
	for raw_line: Variant in lines:
		var line: String = str(raw_line)
		if line != "":
			details.add_child(_make_info_line(line))
	return card

func _make_diplomacy_composer(faction_id: String) -> VBoxContainer:
	var composer: VBoxContainer = DIPLOMACY_COMPOSER_SCENE.instantiate()
	var draft_box: TextEdit = composer.get_node("DraftBox")
	var preset_wrap: FlowContainer = composer.get_node("PresetWrap")
	var send_button: Button = composer.get_node("Controls/SendButton")
	for preset: Dictionary in _diplomacy_presets(faction_id):
		var preset_button: Button = _make_action_button(str(preset.get("label", "预设")), Callable(), str(preset.get("variant", "neutral")))
		preset_button.pressed.connect(_on_diplomacy_preset_pressed.bind(draft_box, send_button, faction_id, str(preset.get("template", ""))))
		preset_wrap.add_child(preset_button)
	draft_box.text = GameState.get_diplomatic_draft(faction_id)
	draft_box.text_changed.connect(_on_draft_text_changed.bind(draft_box, faction_id, send_button))
	var visibility_selector: OptionButton = composer.get_node("Controls/VisibilitySelector")
	visibility_selector.clear()
	visibility_selector.add_item("公开", 0)
	visibility_selector.add_item("限制", 1)
	visibility_selector.add_item("秘密", 2)
	visibility_selector.add_item("加密", 3)
	var current_visibility: String = GameState.get_diplomatic_visibility(faction_id)
	visibility_selector.selected = 0 if current_visibility == "PUBLIC" else 1 if current_visibility == "RESTRICTED" else 2 if current_visibility == "SECRET" else 3
	visibility_selector.item_selected.connect(_on_visibility_selected.bind(faction_id))
	send_button.disabled = draft_box.text.strip_edges() == ""
	send_button.tooltip_text = "先输入照会内容" if send_button.disabled else ""
	send_button.pressed.connect(_on_send_player_message_pressed.bind(draft_box, send_button, faction_id))
	return composer

func _diplomacy_presets(faction_id: String) -> Array[Dictionary]:
	var faction: Dictionary = GameState.get_faction_by_id(faction_id)
	var faction_name: String = str(faction.get("name", "贵方"))
	return [
		{
			"label": "友好试探",
			"variant": "accent",
			"template": "致 %s：我们希望先就边境局势与近期动向交换看法，若贵方愿意，也可安排一次更稳定的常态沟通。" % faction_name
		},
		{
			"label": "贸易互利",
			"variant": "primary",
			"template": "致 %s：我方希望推动一轮互利贸易，愿以稳定资源交换为基础，讨论一份对双方都可持续的合作安排。" % faction_name
		},
		{
			"label": "资源停火",
			"variant": "primary",
			"template": "致 %s：我方愿以一批矿产与能源换取边境停火，并在执行期间暂停前沿施压，避免局势进一步升级。" % faction_name
		},
		{
			"label": "科研互换",
			"variant": "accent",
			"template": "致 %s：我方提议进行一轮科研互换，优先交换民用与后勤相关成果，以建立可验证的合作基础。" % faction_name
		},
		{
			"label": "科研合作",
			"variant": "neutral",
			"template": "致 %s：若贵方认可，我们愿讨论阶段性科研协作，先从低敏感领域开始，逐步建立互信与成果共享机制。" % faction_name
		},
		{
			"label": "边境降温",
			"variant": "neutral",
			"template": "致 %s：边境紧张对双方都没有益处。我方提议降低前沿对抗强度，并建立一次性风险通报渠道，避免误判升级。" % faction_name
		},
		{
			"label": "边境限制",
			"variant": "neutral",
			"template": "致 %s：我方要求贵方暂停边境扩张与前沿前哨建设，并在观察期内维持现有边界安排，以免局势失控。" % faction_name
		},
		{
			"label": "舰队距离",
			"variant": "danger",
			"template": "致 %s：我方要求贵方限制前线舰队继续逼近我方控制星域，至少保持两跳安全距离，并提前通报大规模调动。" % faction_name
		},
		{
			"label": "强硬警告",
			"variant": "danger",
			"template": "致 %s：贵方近期举动已明显触及我方安全底线。若局势继续恶化，我方将采取对等反制措施，但仍保留通过谈判降温的空间。" % faction_name
		}
	]

func _apply_diplomacy_preset(editor: TextEdit, faction_id: String, template: String) -> void:
	editor.text = template
	editor.grab_focus()
	editor.set_caret_line(editor.get_line_count() - 1)
	editor.set_caret_column(editor.get_line(editor.get_caret_line()).length())
	GameState.set_diplomatic_draft(faction_id, template)

func _on_diplomacy_preset_pressed(editor: TextEdit, send_button: Button, faction_id: String, template: String) -> void:
	AudioManager.play_event("ui_tick")
	_apply_diplomacy_preset(editor, faction_id, template)
	send_button.disabled = editor.text.strip_edges() == ""
	send_button.tooltip_text = "先输入照会内容" if send_button.disabled else ""

func _make_route_card(route: Dictionary, system: Dictionary, fits_bandwidth: bool) -> PanelContainer:
	var card: PanelContainer = ROUTE_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = str(route.get("systemName", system.get("name", route.get("systemId", ""))))
	card.get_node("Content/Meta").text = "通道: %s / 消耗: %s / 带宽: %s" % [
		"虫洞" if str(route.get("laneType", "LANE")) == "WORMHOLE" else "航道",
		str(route.get("traversalCost", 1)),
		str(route.get("bandwidth", 0))
	]
	card.get_node("Content/Status").text = "状态: %s" % ("可通行" if fits_bandwidth else "带宽不足")
	return card

func _make_summary_card(title: String, lines: Array) -> PanelContainer:
	var card: PanelContainer = SUMMARY_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	var slots: Array[String] = ["Line1", "Line2", "Line3", "Line4"]
	for i: int in range(slots.size()):
		var label: Label = card.get_node("Content/%s" % slots[i])
		if i < lines.size() and str(lines[i]) != "":
			label.text = str(lines[i])
			label.visible = true
		else:
			label.visible = false
	return card

func _make_fleet_ship_card(ship: Dictionary, owner_faction: Dictionary = {}) -> PanelContainer:
	var card: PanelContainer = FLEET_SHIP_CARD_SCENE.instantiate()
	_apply_texture(card.get_node("Content/ShipPreview"), _ship_art_path_from_paths(owner_faction.get("shipArtPaths", {}), str(ship.get("type", ""))))
	card.get_node("Content/Title").text = "%s / %s" % [ship.get("name", ""), InitialDataScript.ship_labels().get(ship.get("type", ""), ship.get("type", ""))]
	card.get_node("Content/Stats").text = "HP %s/%s / 伤害 %s / 闪避 %s / 速度 %s" % [str(ship.get("hp", 0)), str(ship.get("maxHp", 0)), str(ship.get("damage", 0)), str(ship.get("evasion", 0)), str(ship.get("speed", 0))]
	return card

func _make_queue_item_card(title: String, meta: String, progress: String) -> PanelContainer:
	var card: PanelContainer = QUEUE_ITEM_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	card.get_node("Content/Meta").text = meta
	card.get_node("Content/Progress").text = progress
	return card

func _format_rich_text(text: String) -> String:
	var normalized: String = text.replace("\r\n", "\n")
	var lines: Array = normalized.split("\n")
	var converted: Array = []
	for raw_line: String in lines:
		var line: String = raw_line.strip_edges()
		if line.begins_with("- "):
			converted.append("• %s" % _format_inline_rich_text(line.substr(2)))
		else:
			converted.append(_format_inline_rich_text(raw_line))
	return "\n".join(converted)

func _format_inline_rich_text(text: String) -> String:
	var result: String = text
	var bold_regex := RegEx.new()
	bold_regex.compile("\\*\\*(.+?)\\*\\*")
	result = bold_regex.sub(result, "[b]$1[/b]", true)
	var italic_regex := RegEx.new()
	italic_regex.compile("(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)")
	result = italic_regex.sub(result, "[i]$1[/i]", true)
	var code_regex := RegEx.new()
	code_regex.compile("`([^`]+)`")
	result = code_regex.sub(result, "[code]$1[/code]", true)
	return result

func _make_feed_card(title: String, meta: String, body: String, footnote: String, thumbnail_path: String = "") -> PanelContainer:
	var card: PanelContainer = FEED_CARD_SCENE.instantiate()
	card.get_node("Content/Header/TextBox/Title").text = title
	var meta_label: Label = card.get_node("Content/Header/TextBox/Meta")
	meta_label.text = meta
	meta_label.visible = meta != ""
	_apply_texture(card.get_node("Content/Header/Thumbnail"), thumbnail_path)
	var body_label: RichTextLabel = card.get_node("Content/Body")
	body_label.bbcode_enabled = true
	body_label.text = _format_rich_text(body)
	body_label.visible = body != ""
	var footnote_label: RichTextLabel = card.get_node("Content/Footnote")
	footnote_label.bbcode_enabled = true
	footnote_label.text = _format_rich_text(footnote)
	footnote_label.visible = footnote != ""
	return card

func _make_diplomacy_faction_card(faction: Dictionary, relation: Dictionary, active_treaties: Array) -> PanelContainer:
	var card: PanelContainer = DIPLOMACY_FACTION_CARD_SCENE.instantiate()
	return _configure_diplomacy_card(
		card,
		"%s / %s" % [faction.get("name", ""), faction.get("leaderName", "")],
		"关系等级: %s" % RELATION_LEVEL_NAMES.get(str(relation.get("level", "UNKNOWN")), str(relation.get("level", "UNKNOWN"))),
		str(faction.get("portraitPath", "")),
		str(faction.get("emblemPath", "")),
		_ship_art_path_from_paths(faction.get("shipArtPaths", {}), "CORVETTE"),
		"信任: %s / 好感: %s / 威胁: %s" % [
			str(relation.get("trust", 0)),
			str(relation.get("affinity", 0)),
			str(relation.get("fear", 0))
		],
		"条约: %s" % _treaty_names_text(active_treaties),
		"语气: %s" % _tone_label(str(faction.get("diplomaticProfile", {}).get("recentTone", "neutral")))
	)

func _make_civilization_showcase_card(template: Dictionary) -> PanelContainer:
	var visual_bundle: Dictionary = InitialDataScript.civilization_visual_bundle(str(template.get("visualId", "")))
	var tag_labels: Array[String] = []
	for tag_value: Variant in template.get("behaviorTags", []):
		tag_labels.append(str(tag_value))
	var card: PanelContainer = DIPLOMACY_FACTION_CARD_SCENE.instantiate()
	return _configure_diplomacy_card(
		card,
		"%s / %s" % [str(template.get("name", "")), str(template.get("leaderName", ""))],
		"候选文明 / 取向: %s" % _catalog_focus_label(str(template.get("victoryFocus", "BALANCED"))),
		str(visual_bundle.get("portraitPath", "")),
		str(visual_bundle.get("emblemPath", "")),
		str(visual_bundle.get("catalogShipPath", "")),
		"人口: %s / 军事: %s / 科技等级: %s" % [
			str(template.get("population", 0)),
			str(template.get("militaryPower", 0)),
			str(template.get("technologyLevel", 1))
		],
		"标签: %s" % (", ".join(tag_labels) if not tag_labels.is_empty() else "无"),
		"公开人设: %s / 视觉: %s" % [
			str(template.get("publicPersona", "未知")),
			str(visual_bundle.get("visualSummary", ""))
		]
	)

func _make_colonization_option_card(mode_key: String, mode_data: Dictionary, preview: Dictionary) -> PanelContainer:
	var card: PanelContainer = COLONIZATION_OPTION_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = "%s / %s 回合" % [mode_data.get("name", mode_key), str(preview.get("turns", mode_data.get("turns", 0)))]
	card.get_node("Content/Description").text = str(mode_data.get("description", ""))
	card.get_node("Content/Cost").text = "花费: %s" % _resource_line(preview.get("cost", mode_data.get("cost", {})))
	card.get_node("Content/Stats").text = "初始人口: %s / 初始稳定度: %s / 初始补给: %s / 前哨格位: %s" % [str(preview.get("initial_population", mode_data.get("initial_population", 0))), str(preview.get("initial_stability", mode_data.get("initial_stability", 0))), str(preview.get("initial_supply", mode_data.get("initial_supply", 0))), str(preview.get("slot_cap", mode_data.get("slot_cap", 0)))]
	card.get_node("Content/Risk").text = "维护: %s / 风险: %s" % [_resource_line(preview.get("maintenance", mode_data.get("maintenance", {}))), str(preview.get("risk", mode_data.get("risk", "未知")))]
	return card

func _make_proposal_card(proposal: Dictionary) -> PanelContainer:
	var card: PanelContainer = PROPOSAL_CARD_SCENE.instantiate()
	var sender_faction: Dictionary = GameState.get_faction_by_id(str(proposal.get("senderFactionId", "")))
	card.get_node("Content/Header/TextBox/Title").text = str(proposal.get("title", "外交提案"))
	card.get_node("Content/Header/TextBox/Type").text = "提案类型: %s / 发送方: %s" % [
		PROPOSAL_TYPE_LABELS.get(str(proposal.get("proposalType", "UNKNOWN")), str(proposal.get("proposalType", "UNKNOWN"))),
		str(sender_faction.get("name", proposal.get("senderFactionId", "未知势力")))
	]
	card.get_node("Content/Header/TextBox/Deadline").text = "截止回合: T%s" % str(proposal.get("expiresOnTurn", 0))
	_apply_texture(card.get_node("Content/Header/Portrait"), str(sender_faction.get("portraitPath", "")))
	_apply_texture(card.get_node("Content/Header/Emblem"), str(sender_faction.get("emblemPath", "")))
	var summary: RichTextLabel = card.get_node("Content/Summary")
	summary.bbcode_enabled = true
	summary.text = _format_rich_text(str(proposal.get("summary", "")))
	return card

func _make_trend_card(title: String, body: String) -> PanelContainer:
	var card: PanelContainer = TREND_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	card.get_node("Content/Body").text = body
	return card

func _make_api_report_card(title: String, summary: String, details_lines: Array) -> PanelContainer:
	var card: PanelContainer = API_REPORT_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	var summary_label: RichTextLabel = card.get_node("Content/Summary")
	summary_label.bbcode_enabled = true
	summary_label.text = _format_rich_text(summary)
	var details: VBoxContainer = card.get_node("Content/Details")
	for line_value: Variant in details_lines:
		var line: String = str(line_value)
		if line == "":
			continue
		details.add_child(_make_info_line(line))
	return card

func _make_posture_card(posture: Dictionary) -> PanelContainer:
	var card: PanelContainer = POSTURE_CARD_SCENE.instantiate()
	var high_pressure: Array = posture.get("high_pressure", [])
	var high_opportunity: Array = posture.get("high_opportunity", [])
	var deteriorating: Array = posture.get("deteriorating", [])
	var improving: Array = posture.get("improving", [])
	var flashpoints: Array = posture.get("flashpoints", [])
	card.get_node("Content/HighPressure").text = "高压对象: %s" % (", ".join(high_pressure) if not high_pressure.is_empty() else "无")
	card.get_node("Content/HighOpportunity").text = "高机会对象: %s" % (", ".join(high_opportunity) if not high_opportunity.is_empty() else "无")
	card.get_node("Content/Deteriorating").text = "关系恶化对象: %s" % (", ".join(deteriorating) if not deteriorating.is_empty() else "无")
	card.get_node("Content/Improving").text = "关系改善对象: %s" % (", ".join(improving) if not improving.is_empty() else "无")
	card.get_node("Content/Flashpoints").text = "潜在爆点: %s" % (", ".join(flashpoints) if not flashpoints.is_empty() else "无")
	card.get_node("Content/Posture").text = "姿态: %s" % POSTURE_LABELS.get(str(posture.get("recommended_posture", "CONSOLIDATE")), str(posture.get("recommended_posture", "CONSOLIDATE")))
	return card

func _resource_line(bundle: Dictionary, positive_prefix: bool = false) -> String:
	var parts: Array = []
	for key: String in ["food", "minerals", "industry", "energy"]:
		var value: int = int(bundle.get(key, 0))
		if value == 0:
			continue
		var prefix: String = "+" if positive_prefix and value > 0 else ""
		parts.append("%s%s %s" % [prefix, str(value), RESOURCE_NAMES.get(key, key)])
	return "无" if parts.is_empty() else " / ".join(parts)

func _tech_category_counts_text(counts: Dictionary) -> String:
	if counts.is_empty():
		return "无"
	var labels: Array[String] = []
	for key: Variant in counts.keys():
		labels.append("%s %s" % [TECH_CATEGORY_LABELS.get(str(key), str(key)), str(counts.get(key, 0))])
	return " / ".join(labels)

func _objective_summary_lines() -> Array:
	var objective_text: String = str(GameState.game_state.get("objective", ""))
	var segments: PackedStringArray = objective_text.split(" | ") if objective_text != "" else PackedStringArray()
	var lines: Array = []
	lines.append("当前战略: %s" % (segments[0] if segments.size() > 0 else "未设定"))
	if segments.size() > 1:
		lines.append("阶段推进: %s" % segments[1])
	if segments.size() > 2:
		lines.append("长期目标: %s" % segments[2])
	lines.append("状态: %s" % _game_status_label(str(GameState.game_state.get("status", "PLAYING"))))
	lines.append("飞升进度: %s/100" % str(GameState.game_state.get("ascension_progress", 0)))
	lines.append("胜利路径: %s" % _victory_path_label(GameState.game_state.get("victory_path", null)))
	return lines

func _treaty_names_text(treaties: Array) -> String:
	if treaties.is_empty():
		return "无"
	var names: PackedStringArray = PackedStringArray()
	for treaty: Dictionary in treaties:
		names.append(InitialDataScript.treaty_labels().get(treaty.get("type", ""), treaty.get("type", "")))
	return ", ".join(names)

func _colony_stage_name(stage: String) -> String:
	match stage:
		"OUTPOST":
			return "前哨"
		"COLONY":
			return "殖民地"
		"CORE":
			return "核心世界"
		_:
			return "未殖民"

func _tone_label(tone: String) -> String:
	match tone:
		"friendly":
			return "友好"
		"warm":
			return "温和"
		"neutral":
			return "中性"
		"firm":
			return "强硬"
		"guarded":
			return "戒备"
		"scheming":
			return "算计"
		"hostile":
			return "敌对"
		_:
			return tone

func _target_type_label(target_type: String) -> String:
	match target_type:
		"SINGLE":
			return "单边"
		"BILATERAL":
			return "双边"
		"MULTILATERAL":
			return "多边"
		_:
			return target_type

func _recommended_action_label(action: String) -> String:
	match action:
		"ACCEPT":
			return "接受"
		"REJECT":
			return "拒绝"
		"COUNTER":
			return "反提案"
		"DELAY":
			return "暂缓"
		_:
			return action

func _game_status_label(status: String) -> String:
	match status:
		"PLAYING":
			return "进行中"
		"PAUSED":
			return "暂停"
		"VICTORY":
			return "已胜利"
		"DEFEAT":
			return "已失败"
		_:
			return status

func _charter_status_label(status: String) -> String:
	match status:
		"INACTIVE":
			return "未启动"
		"PROPOSED":
			return "提案中"
		"VOTING":
			return "表决中"
		"RATIFIED":
			return "已通过"
		"REJECTED":
			return "已否决"
		_:
			return status

func _interception_status_label(status: String) -> String:
	match status:
		"FULL":
			return "全域监控"
		"PARTIAL":
			return "部分可见"
		"LIMITED":
			return "能力受限"
		"UNKNOWN":
			return "未知"
		_:
			return status

func _fleet_readiness_label(readiness: String) -> String:
	match readiness:
		"FULL":
			return "完备"
		"DEGRADED":
			return "受损"
		"CRITICAL":
			return "危急"
		_:
			return readiness

func _message_type_label(message_type: String) -> String:
	match message_type:
		"SYSTEM":
			return "系统播报"
		"EVENT":
			return "事件更新"
		"COMBAT":
			return "战斗通报"
		"DIPLOMACY":
			return "外交动态"
		"SIGNAL":
			return "截获通信"
		"INTERVENTION":
			return "干预记录"
		_:
			return message_type

func _ascension_phase_label(phase: String) -> String:
	match phase:
		"INACTIVE":
			return "未启动"
		"FOUNDATION":
			return "基座铺设"
		"CORE_CHARGING":
			return "核心充能"
		"FINAL_LAUNCH":
			return "最终启动"
		"COMPLETED":
			return "飞升完成"
		_:
			return phase

func _signed_int_text(value: int) -> String:
	return "%s%s" % ["+" if value >= 0 else "", str(value)]

func _victory_path_label(value: Variant) -> String:
	if value == null or str(value) == "":
		return "未设定"
	return VICTORY_FOCUS_LABELS.get(str(value), str(value))

func _event_template_from_preview(event_id: String) -> String:
	var lowered: String = event_id.to_lower()
	if "pirate_raid" in lowered:
		return "PIRATE_RAID"
	if "warp_storm" in lowered:
		return "WARP_STORM"
	return "ANCIENT_RUINS_DISCOVERY"

func _intervention_type_from_preview(intervention_id: String) -> String:
	var lowered: String = intervention_id.to_lower()
	if "spawn_pirates" in lowered:
		return "SPAWN_PIRATES"
	if "boost_ai" in lowered:
		return "BOOST_AI"
	if "reduce_resources" in lowered:
		return "REDUCE_RESOURCES"
	return "TRIGGER_CRISIS"

func _configure_tab_button(button: Button, tab_name: String, active: bool) -> void:
	button.text = str(TAB_LABELS.get(tab_name, tab_name))
	_apply_button_icon(button, str(TAB_ICON_KEYS.get(tab_name, "")))
	button.button_pressed = active
	button.add_theme_color_override("font_color", Color(0.88, 0.96, 0.98, 1.0) if active else Color(0.62, 0.78, 0.82, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.95, 0.36, 0.08, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))

func _era_name(era_key: String) -> String:
	match era_key:
		"PIONEER":
			return "先驱时代"
		"EXPANSION":
			return "扩张时代"
		"CONFLICT":
			return "纷争时代"
		"UNIFICATION":
			return "统一时代"
		"ASCENSION":
			return "飞升时代"
		_:
			return era_key

func _threat_and_request(faction_id: String) -> void:
	GameState.threaten_faction(faction_id)
	GameState.request_diplomatic_message(faction_id, "firm")

func _on_tab_pressed(tab_name: String) -> void:
	AudioManager.play_event("ui_panel")
	GameState.clear_selection()
	GameState.set_active_tab(tab_name)
	_open_global_tab_modal(tab_name)

func _refresh_visible_panels() -> void:
	if center_modal_overlay.visible and GameState.selected_system_id == "" and GameState.selected_fleet_id == "":
		_open_global_tab_modal(GameState.active_tab)
		return
	refresh()

func _on_state_changed(_state: Dictionary) -> void:
	refresh()
	_refresh_visible_panels()

func _on_selection_changed(_system_id: String, _fleet_id: String) -> void:
	if GameState.selected_system_id != "" or GameState.selected_fleet_id != "":
		_close_center_modal()
	refresh()

func _on_tab_changed(_tab_name: String) -> void:
	if center_modal_overlay.visible and GameState.selected_system_id == "" and GameState.selected_fleet_id == "":
		_open_global_tab_modal(_tab_name)
		return
	refresh()

func _on_labels_visibility_changed(_visible: bool) -> void:
	refresh()

func _on_service_status_changed(_status: String) -> void:
	refresh()

func _on_draft_text_changed(editor: TextEdit, faction_id: String, send_button: Button = null) -> void:
	GameState.set_diplomatic_draft(faction_id, editor.text)
	if send_button != null:
		send_button.disabled = editor.text.strip_edges() == ""
		send_button.tooltip_text = "先输入照会内容" if send_button.disabled else ""

func _on_visibility_selected(index: int, faction_id: String) -> void:
	AudioManager.play_event("ui_tick")
	var value: String = "PUBLIC"
	if index == 1:
		value = "RESTRICTED"
	elif index == 2:
		value = "SECRET"
	elif index == 3:
		value = "ENCRYPTED"
	GameState.set_diplomatic_visibility(faction_id, value)

func _on_send_player_message_pressed(editor: TextEdit, send_button: Button, faction_id: String) -> void:
	AudioManager.play_event("ui_tick")
	GameState.send_player_message(faction_id)
	editor.text = GameState.get_diplomatic_draft(faction_id)
	send_button.disabled = editor.text.strip_edges() == ""
	send_button.tooltip_text = "先输入照会内容" if send_button.disabled else ""

func _on_diplomacy_changed() -> void:
	if GameState.active_tab == "DIPLOMACY" or GameState.active_tab == "COMMS" or GameState.selected_fleet_id != "" or GameState.selected_system_id != "":
		refresh()
		_refresh_visible_panels()
