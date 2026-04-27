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
	"COMMS": "通讯中心"
}

const RESOURCE_NAMES: Dictionary = {
	"food": "食物",
	"minerals": "矿产",
	"industry": "工业",
	"energy": "能源"
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

@onready var root: Control = $Root
@onready var top_bar: HBoxContainer = $Root/TopBar
@onready var turn_chip: PanelContainer = $Root/TopBar/TurnChip
@onready var turn_title: Label = $Root/TopBar/TurnChip/Content/Title
@onready var turn_value: Label = $Root/TopBar/TurnChip/Content/Value
@onready var era_chip: PanelContainer = $Root/TopBar/EraChip
@onready var era_title: Label = $Root/TopBar/EraChip/Content/Title
@onready var era_value: Label = $Root/TopBar/EraChip/Content/Value
@onready var food_chip: PanelContainer = $Root/TopBar/FoodChip
@onready var food_title: Label = $Root/TopBar/FoodChip/Content/Title
@onready var food_value: Label = $Root/TopBar/FoodChip/Content/Value
@onready var minerals_chip: PanelContainer = $Root/TopBar/MineralsChip
@onready var minerals_title: Label = $Root/TopBar/MineralsChip/Content/Title
@onready var minerals_value: Label = $Root/TopBar/MineralsChip/Content/Value
@onready var industry_chip: PanelContainer = $Root/TopBar/IndustryChip
@onready var industry_title: Label = $Root/TopBar/IndustryChip/Content/Title
@onready var industry_value: Label = $Root/TopBar/IndustryChip/Content/Value
@onready var energy_chip: PanelContainer = $Root/TopBar/EnergyChip
@onready var energy_title: Label = $Root/TopBar/EnergyChip/Content/Title
@onready var energy_value: Label = $Root/TopBar/EnergyChip/Content/Value
@onready var toggle_labels_button: Button = $Root/TopBar/ToggleLabelsButton
@onready var right_drawer: PanelContainer = $Root/RightDrawer
@onready var drawer_title: Label = $Root/RightDrawer/Margin/DrawerVBox/DrawerHeader/TitleBox/DrawerTitle
@onready var drawer_subtitle: Label = $Root/RightDrawer/Margin/DrawerVBox/DrawerHeader/TitleBox/DrawerSubtitle
@onready var drawer_content: VBoxContainer = $Root/RightDrawer/Margin/DrawerVBox/DrawerBody/DrawerContent
@onready var next_turn_button: Button = $Root/RightDrawer/Margin/DrawerVBox/NextTurnButton
@onready var center_modal_overlay: ColorRect = $Root/CenterModalOverlay
@onready var center_modal: PanelContainer = $Root/CenterModalOverlay/CenterModal
@onready var modal_title: Label = $Root/CenterModalOverlay/CenterModal/Margin/ModalVBox/Header/TitleBox/ModalTitle
@onready var modal_subtitle: Label = $Root/CenterModalOverlay/CenterModal/Margin/ModalVBox/Header/TitleBox/ModalSubtitle
@onready var modal_content: VBoxContainer = $Root/CenterModalOverlay/CenterModal/Margin/ModalVBox/Body/ModalContent
@onready var close_modal_button: Button = $Root/CenterModalOverlay/CenterModal/Margin/ModalVBox/Header/CloseButton
@onready var bottom_tabs: HBoxContainer = $Root/BottomTabs
@onready var objectives_button: Button = $Root/BottomTabs/ObjectivesButton
@onready var tech_button: Button = $Root/BottomTabs/TechButton
@onready var diplomacy_button: Button = $Root/BottomTabs/DiplomacyButton
@onready var communications_button: Button = $Root/BottomTabs/CommunicationsButton
@onready var fleet_tabs_spacer: Control = $Root/BottomTabs/FleetTabsSpacer
@onready var fleet_tabs: HBoxContainer = $Root/BottomTabs/FleetTabs

var _modal_payload: Dictionary = {}
var _panel_content: VBoxContainer

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.tab_changed.connect(_on_tab_changed)
	GameState.labels_visibility_changed.connect(_on_labels_visibility_changed)
	GameState.service_status_changed.connect(_on_service_status_changed)
	GameState.diplomacy_changed.connect(_on_diplomacy_changed)
	next_turn_button.pressed.connect(GameState.advance_turn)
	toggle_labels_button.pressed.connect(GameState.toggle_labels)
	objectives_button.pressed.connect(_on_tab_pressed.bind("OBJECTIVES"))
	tech_button.pressed.connect(_on_tab_pressed.bind("TECH"))
	diplomacy_button.pressed.connect(_on_tab_pressed.bind("DIPLOMACY"))
	communications_button.pressed.connect(_on_tab_pressed.bind("COMMS"))
	close_modal_button.pressed.connect(_close_center_modal)
	center_modal_overlay.gui_input.connect(_on_center_modal_overlay_input)
	root.resized.connect(_update_responsive_layout)
	_apply_theme()
	_panel_content = drawer_content
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not center_modal_overlay.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_center_modal()

func refresh() -> void:
	_update_responsive_layout()
	next_turn_button.disabled = GameState.turn_busy or GameState.game_state.get("status", "") != "PLAYING"
	next_turn_button.text = "处理中..." if GameState.turn_busy else "下一回合"
	_rebuild_top_bar()
	_rebuild_drawer()
	_rebuild_bottom_tabs()

func _apply_theme() -> void:
	pass

func _update_responsive_layout() -> void:
	var viewport_size: Vector2 = root.size
	if viewport_size.x <= 0.0:
		return
	var viewport_width: float = viewport_size.x
	var compact: bool = viewport_width < 1440.0
	var narrow_desktop: bool = viewport_width < 1280.0
	var very_narrow: bool = viewport_width < 1120.0
	var drawer_width: float = clampf(viewport_width * (0.29 if narrow_desktop else 0.27), 340.0, 440.0)
	var side_margin: float = 24.0 if not compact else 12.0 if very_narrow else 16.0
	var top_bar_bottom: float = top_bar.offset_bottom
	right_drawer.offset_left = -drawer_width - side_margin
	right_drawer.offset_right = -side_margin
	top_bar.offset_left = side_margin
	top_bar.offset_right = -side_margin
	top_bar.add_theme_constant_override("separation", 10 if not compact else 4 if very_narrow else 6)
	bottom_tabs.offset_left = side_margin
	bottom_tabs.offset_right = -side_margin
	bottom_tabs.offset_top = -82.0 if not compact else -74.0 if very_narrow else -78.0
	bottom_tabs.offset_bottom = -24.0 if not compact else -16.0 if very_narrow else -20.0
	bottom_tabs.add_theme_constant_override("separation", 8 if not compact else 4 if very_narrow else 6)
	right_drawer.offset_top = top_bar_bottom + (8.0 if not compact else 6.0)
	right_drawer.offset_bottom = bottom_tabs.offset_top - (8.0 if not compact else 6.0)
	var modal_half_width: float = clampf(viewport_width * 0.42, 520.0, 760.0)
	var modal_half_height: float = clampf(viewport_size.y * 0.42, 300.0, 460.0)
	center_modal.offset_left = -modal_half_width
	center_modal.offset_right = modal_half_width
	center_modal.offset_top = -modal_half_height
	center_modal.offset_bottom = modal_half_height
	var nav_width: float = 128.0 if not compact else 96.0 if very_narrow else 108.0 if narrow_desktop else 112.0
	var nav_height: float = 52.0 if not compact else 48.0 if very_narrow else 50.0
	objectives_button.custom_minimum_size = Vector2(nav_width, nav_height)
	tech_button.custom_minimum_size = Vector2(nav_width, nav_height)
	diplomacy_button.custom_minimum_size = Vector2(nav_width, nav_height)
	communications_button.custom_minimum_size = Vector2(nav_width, nav_height)
	toggle_labels_button.custom_minimum_size = Vector2(116 if very_narrow else 132 if narrow_desktop else 136 if compact else 160, 52 if very_narrow else 56)
	food_chip.custom_minimum_size = Vector2(104 if very_narrow else 112 if narrow_desktop else 120 if compact else 132, 52 if very_narrow else 56)
	minerals_chip.custom_minimum_size = Vector2(104 if very_narrow else 112 if narrow_desktop else 120 if compact else 132, 52 if very_narrow else 56)
	industry_chip.custom_minimum_size = Vector2(104 if very_narrow else 112 if narrow_desktop else 120 if compact else 132, 52 if very_narrow else 56)
	energy_chip.custom_minimum_size = Vector2(104 if very_narrow else 112 if narrow_desktop else 120 if compact else 132, 52 if very_narrow else 56)
	next_turn_button.custom_minimum_size = Vector2(0, 48 if very_narrow else 50 if compact else 54)

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
	toggle_labels_button.text = "文字标记: %s" % ("显示" if GameState.labels_visible else "隐藏")

func _rebuild_drawer() -> void:
	for child: Node in drawer_content.get_children():
		child.queue_free()

	var selected_fleet: Dictionary = GameState.get_fleet_by_id(GameState.selected_fleet_id)
	var selected_system: Dictionary = GameState.get_system_by_id(GameState.selected_system_id)
	right_drawer.visible = not selected_fleet.is_empty() or not selected_system.is_empty()
	_panel_content = drawer_content

	if not selected_fleet.is_empty():
		drawer_title.text = "舰队指挥"
		drawer_subtitle.text = "查看舰队状态、航线与作战选项。"
		_build_fleet_panel(selected_fleet)
	elif not selected_system.is_empty():
		drawer_title.text = "星系建设"
		drawer_subtitle.text = "查看资源、建筑与殖民状态。"
		_build_system_panel(selected_system)

func _rebuild_bottom_tabs() -> void:
	for child: Node in fleet_tabs.get_children():
		child.queue_free()
	_configure_tab_button(objectives_button, GameState.active_tab == "OBJECTIVES")
	_configure_tab_button(tech_button, GameState.active_tab == "TECH")
	_configure_tab_button(diplomacy_button, GameState.active_tab == "DIPLOMACY")
	_configure_tab_button(communications_button, GameState.active_tab == "COMMS")
	var fleets: Array = GameState.get_player_fleets()
	fleet_tabs_spacer.visible = not fleets.is_empty()
	fleet_tabs.visible = not fleets.is_empty()
	for fleet: Dictionary in fleets:
		var fleet_button: Button = _make_action_button(str(fleet.get("name", "舰队")), GameState.select_fleet.bind(fleet.get("id", "")))
		fleet_button.custom_minimum_size = Vector2(132 if root.size.x < 1440.0 else 144, 52)
		if GameState.selected_fleet_id == str(fleet.get("id", "")):
			fleet_button.add_theme_color_override("font_color", Color("0B0C15"))
			fleet_button.add_theme_stylebox_override("normal", _button_style(Color("8BE9FD"), Color("8BE9FD"), 16))
		fleet_tabs.add_child(fleet_button)

func _build_objectives_panel() -> void:
	var victory_report: Dictionary = GameState.get_victory_progress_report()
	var military_report: Dictionary = victory_report.get("military", {})
	var diplomatic_report: Dictionary = victory_report.get("diplomatic", {})
	var science_report: Dictionary = victory_report.get("science", {})
	_panel_add(_make_section_title("当前目标"))
	_panel_add(_make_status_card(
		"当前目标",
		[
			"目标: %s" % str(GameState.game_state.get("objective", "")),
			"状态: %s" % str(GameState.game_state.get("status", "PLAYING")),
			"飞升进度: %s/100" % str(GameState.game_state.get("ascension_progress", 0)),
			"胜利路径: %s" % str(GameState.game_state.get("victory_path", "未达成"))
		]
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
				str(diplomatic_report.get("charter_status", "INACTIVE")),
				str(diplomatic_report.get("votes_for", 0)),
				str(diplomatic_report.get("required_votes", 0))
			],
			"外交胜利就绪: %s" % ("是" if bool(diplomatic_report.get("achieved", false)) else "否")
		]
	))
	_panel_add(_make_status_card(
		"科技飞升",
		[
			"飞升阶段: %s" % str(science_report.get("phase_label", "未启动")),
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
	_panel_add(_make_section_title("科技研究"))
	var current_research_id: Variant = GameState.game_state.get("currentResearchId", null)
	if current_research_id != null:
		for tech: Dictionary in GameState.game_state.get("technologies", []):
			if tech.get("id", "") == str(current_research_id):
				_panel_add(_make_tech_card(tech, true))
				var cancel_button: Button = _make_action_button("取消当前研究", GameState.cancel_research, "danger")
				cancel_button.pressed.connect(_refresh_visible_panels)
				_panel_add(cancel_button)
				break
	_panel_add(_make_section_title("可研究项目"))
	for tech: Dictionary in GameState.game_state.get("technologies", []):
		if tech.get("status", "") != "AVAILABLE":
			continue
		_panel_add(_make_tech_card(tech, false))
		var button: Button = _make_action_button("开始研究", GameState.start_research.bind(tech.get("id", "")), "primary")
		button.disabled = current_research_id != null
		button.pressed.connect(_refresh_visible_panels)
		_panel_add(button)

func _build_diplomacy_panel() -> void:
	_panel_add(_make_section_title("局势简报"))
	var interception_report: Dictionary = GameState.get_interception_report()
	var diplomacy_report: Dictionary = GameState.get_diplomatic_victory_report()
	_panel_add(_make_status_card(
		"通信截获状态",
		[
			"通信截获状态: %s" % interception_report.get("status", "未知"),
			"公开通信基础截获率: %s%%" % str(interception_report.get("base", 0)),
			"限制级通信截获率: %s%%" % str(interception_report.get("restricted", 0)),
			"秘密通信截获率: %s%%" % str(interception_report.get("secret", 0)),
			"加密通信截获率: %s%%" % str(interception_report.get("encrypted", 0))
		]
	))
	_panel_add(_make_status_card(
		"外交胜利进度",
		[
			"联合国: %s" % ("已成立" if bool(diplomacy_report.get("council_established", false)) else "未成立"),
			"议长: %s" % str(diplomacy_report.get("speaker_title", "未设立")),
			"宪章表决: %s" % str(diplomacy_report.get("charter_status", "INACTIVE")),
			"支持票: %s/%s" % [str(diplomacy_report.get("votes_for", 0)), str(diplomacy_report.get("required_votes", 0))]
		]
	))
	_panel_add(_make_section_title("外交对象"))
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogicScript.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var active_treaties: Array = GameLogicScript.active_treaties_between(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		_panel_add(_make_diplomacy_faction_card(faction, relation, active_treaties))
		var history: Array = GameState.get_relation_history(faction.get("id", ""))
		var detail_row: HBoxContainer = _action_row()
		detail_row.add_child(_make_action_button("查看关系详情", _open_faction_modal.bind(faction, relation, active_treaties, history), "primary"))
		detail_row.add_child(_make_action_button("关系扫描", GameState.request_relationship_scan.bind(faction.get("id", "")), "neutral"))
		detail_row.add_child(_make_action_button("发送友好照会", GameState.request_diplomatic_message.bind(faction.get("id", ""), "friendly"), "accent"))
		_panel_add(detail_row)

	_panel_add(_make_section_title("可见通信"))
	var visible_messages: Array = GameState.get_visible_diplomatic_messages()
	if visible_messages.is_empty():
		_panel_add(_make_status_card("可见通信", ["当前没有可见的外交通信记录。"]))
	else:
		for message: Dictionary in visible_messages.slice(0, min(10, visible_messages.size())):
			var security: Dictionary = message.get("securitySettings", {})
			_panel_add(_make_feed_card(
				"T%s / %s" % [str(message.get("turn", 1)), message.get("title", "")],
				"发送者: %s / 目标类型: %s / 可见级别: %s" % [
					str(message.get("senderName", message.get("senderId", ""))),
					_target_type_label(str(message.get("targetType", "SINGLE"))),
					VISIBILITY_LABELS.get(str(message.get("visibilityLevel", "PUBLIC")), str(message.get("visibilityLevel", "PUBLIC")))
				],
				_truncate_text(str(message.get("content", ""))),
				"加密等级: %s / 预计保留: %s 回合" % [str(security.get("encryptionLevel", 0)), str(security.get("expiresAfterTurns", 10))]
			))
			var message_row: HBoxContainer = _action_row()
			message_row.add_child(_make_action_button("查看详情", _open_message_modal.bind(message)))
			_panel_add(message_row)

	_panel_add(_make_section_title("待处理提案"))
	var pending_proposals: Array = GameState.get_pending_proposals()
	if pending_proposals.is_empty():
		_panel_add(_make_status_card("待处理提案", ["当前没有待处理的外交提案。"]))
	else:
		for proposal: Dictionary in pending_proposals:
			_panel_add(_make_proposal_card(proposal))
			var proposal_row: HBoxContainer = _action_row()
			proposal_row.add_child(_make_action_button("查看详情", _open_proposal_modal.bind(proposal), "neutral"))
			proposal_row.add_child(_make_action_button("接受提案", GameState.accept_diplomatic_proposal.bind(proposal.get("id", "")), "primary"))
			proposal_row.add_child(_make_action_button("拒绝提案", GameState.reject_diplomatic_proposal.bind(proposal.get("id", "")), "danger"))
			proposal_row.add_child(_make_action_button("战略评估", GameState.request_proposal_evaluation.bind(proposal.get("id", "")), "accent"))
			_panel_add(proposal_row)

	var relationship_report: Dictionary = GameState.world_data.get("relationship_report", {})
	if not relationship_report.is_empty():
		_panel_add(_make_section_title("关系简报"))
		_panel_add(_make_api_report_card(
			"关系简报",
			"信任 %s / 利益 %s / 恐惧 %s / 好感 %s / 记忆 %s / 关系等级: %s" % [
				str(relationship_report.get("trust_score", 0)),
				str(relationship_report.get("utility_score", 0)),
				str(relationship_report.get("fear_score", 0)),
				str(relationship_report.get("affection_score", 0)),
				str(relationship_report.get("memory_impact", 0)),
				RELATION_LEVEL_NAMES.get(str(relationship_report.get("relationship_level", "UNKNOWN")), str(relationship_report.get("relationship_level", "UNKNOWN")))
			],
			relationship_report.get("recent_events", [])
		))

	var proposal_evaluation_report: Dictionary = GameState.world_data.get("proposal_evaluation_report", {})
	if not proposal_evaluation_report.is_empty():
		_panel_add(_make_section_title("战略评估"))
		var detail_lines: Array = []
		for item: String in proposal_evaluation_report.get("key_concerns", []):
			detail_lines.append("关注点: %s" % item)
		var counter: Dictionary = proposal_evaluation_report.get("counter_proposal", {})
		if not counter.is_empty():
			detail_lines.append("反提案: %s" % PROPOSAL_TYPE_LABELS.get(str(counter.get("preferred_type", "")), str(counter.get("preferred_type", ""))))
			detail_lines.append(str(counter.get("summary", "")))
		_panel_add(_make_api_report_card(
			"战略评估",
			"接受评分: %s / 建议动作: %s" % [
				str(proposal_evaluation_report.get("acceptance_score", 0)),
				_recommended_action_label(str(proposal_evaluation_report.get("recommended_action", "REJECT")))
			],
			detail_lines
		))

	_panel_add(_make_section_title("外交记忆"))
	var memories: Array = GameState.get_visible_diplomatic_memories()
	if memories.is_empty():
		_panel_add(_make_status_card("外交记忆", ["当前没有可见的外交记忆。"]))
	else:
		for memory: Dictionary in memories.slice(0, min(8, memories.size())):
			var related_titles: Array = []
			for item: Dictionary in memory.get("relatedLongTermMemories", []):
				related_titles.append(str(item.get("title", "长期记忆")))
			_panel_add(_make_feed_card(
				"T%s / %s" % [str(memory.get("turn", 1)), memory.get("title", "")],
				"类别: %s / 重要度: %s" % [str(memory.get("category", "EVENT")), str(memory.get("importance", 1))],
				str(memory.get("summary", "")),
				"相关长期记忆: %s" % (", ".join(related_titles) if not related_titles.is_empty() else "无")
			))

	if not GameState.diplomatic_message.is_empty():
		_panel_add(_make_section_title("最新外交回应"))
		_panel_add(_make_feed_card(
			str(GameState.diplomatic_message.get("title", "")),
			"",
			_truncate_text(str(GameState.diplomatic_message.get("content", ""))),
			""
		))
		_panel_add(_make_action_button("查看详情", _open_message_modal.bind(GameState.diplomatic_message), "primary"))

func _build_communications_panel() -> void:
	_panel_add(_make_section_title("通讯中心"))
	_panel_add(_make_status_card(
		"通讯中心",
		[
			"收录玩家可见的系统消息、外交通信与待处理提案。",
			"列表只保留摘要，完整正文统一通过详情查看。"
		]
	))
	_panel_add(_make_section_title("系统消息"))
	var system_entries: Array = []
	for message: Dictionary in GameState.game_state.get("messages", []).slice(0, 6):
		system_entries.append({
			"title": "T%s / %s" % [str(message.get("turn", 1)), str(message.get("title", "系统消息"))],
			"meta": str(message.get("type", "SYSTEM")),
			"summary": _truncate_text(str(message.get("content", "")), 96)
		})
	for report: Dictionary in GameState.get_recent_combat_reports().slice(0, 3):
		system_entries.append({
			"title": "T%s / %s" % [str(report.get("turn", 1)), str(report.get("title", "战斗结果"))],
			"meta": "%s vs %s" % [str(report.get("attackerName", "进攻方")), str(report.get("defenderName", "防守方"))],
			"summary": "结果: %s / 损失 %s / 击毁 %s" % ["胜利" if report.get("victory", false) else "失利", str(report.get("casualties", 0)), str(report.get("kills", 0))]
		})
	if system_entries.is_empty():
		_panel_add(_make_status_card("系统消息", ["当前没有新的系统消息。"]))
	else:
		for entry: Dictionary in system_entries:
			_panel_add(_make_feed_card(str(entry.get("title", "")), str(entry.get("meta", "")), str(entry.get("summary", "")), ""))
	_panel_add(_make_section_title("外交通信"))
	var visible_messages: Array = GameState.get_visible_diplomatic_messages()
	var diplomacy_entries: Array = visible_messages.slice(0, min(8, visible_messages.size()))
	if not GameState.diplomatic_message.is_empty():
		var already_listed: bool = false
		for message: Dictionary in diplomacy_entries:
			if str(message.get("title", "")) == str(GameState.diplomatic_message.get("title", "")) and str(message.get("content", "")) == str(GameState.diplomatic_message.get("content", "")):
				already_listed = true
				break
		if not already_listed:
			diplomacy_entries.push_front(GameState.diplomatic_message)
	if diplomacy_entries.is_empty():
		_panel_add(_make_status_card("外交通信", ["当前没有可见的外交通信记录。"]))
	else:
		for message: Dictionary in diplomacy_entries:
			var security: Dictionary = message.get("securitySettings", {})
			_panel_add(_make_feed_card(
				"T%s / %s" % [str(message.get("turn", 1)), str(message.get("title", "通信"))],
				"%s / %s" % [
					str(message.get("senderName", message.get("senderId", ""))),
					VISIBILITY_LABELS.get(str(message.get("visibilityLevel", "PUBLIC")), str(message.get("visibilityLevel", "PUBLIC")))
				],
				_truncate_text(str(message.get("content", "")), 96),
				"目标: %s / 保留: %s 回合" % [_target_type_label(str(message.get("targetType", "SINGLE"))), str(security.get("expiresAfterTurns", 10))]
			))
			_panel_add(_make_action_button("查看详情", _open_message_modal.bind(message)))
	_panel_add(_make_section_title("提案"))
	var pending_proposals: Array = GameState.get_pending_proposals()
	if pending_proposals.is_empty():
		_panel_add(_make_status_card("提案", ["当前没有待处理的外交提案。"]))
	else:
		for proposal: Dictionary in pending_proposals:
			_panel_add(_make_proposal_card(proposal))
			var proposal_row: HBoxContainer = _action_row()
			proposal_row.add_child(_make_action_button("查看详情", _open_proposal_modal.bind(proposal)))
			proposal_row.add_child(_make_action_button("接受提案", GameState.accept_diplomatic_proposal.bind(proposal.get("id", ""))))
			proposal_row.add_child(_make_action_button("拒绝提案", GameState.reject_diplomatic_proposal.bind(proposal.get("id", ""))))
			_panel_add(proposal_row)

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
			building_actions.add_child(_make_action_button("加入队列", GameState.queue_structure.bind(system.get("id", ""), building.get("type", ""))))
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
				ship_actions.add_child(_make_action_button("建造%s" % InitialDataScript.ship_labels().get(ship_type, ship_type), GameState.queue_ship.bind(system.get("id", ""), ship_type)))
				ship_actions.add_child(_make_action_button("排队3艘%s" % InitialDataScript.ship_labels().get(ship_type, ship_type), GameState.queue_ship_batch.bind(system.get("id", ""), ship_type, 3)))
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
	for ship: Dictionary in fleet.get("ships", []):
		total_hp += int(ship.get("hp", 0))
		total_max_hp += int(ship.get("maxHp", 0))
		total_damage += int(ship.get("damage", 0))
	_panel_add(_make_section_title(fleet.get("name", "")))
	_panel_add(_make_status_card(
		"舰队概览",
		[
			"所在星系: %s" % GameState.get_system_by_id(fleet.get("systemId", "")).get("name", ""),
			"总生命: %s/%s" % [str(total_hp), str(total_max_hp)],
			"总伤害: %s" % str(total_damage),
			"移动冷却: %s" % str(int(fleet.get("movementCooldown", 0))),
			"当前任务: %s" % GameLogicScript.fleet_mission_label(str(fleet.get("mission", "IDLE")))
		]
	))
	_panel_add(_make_section_title("任务"))
	var mission_row_one: HBoxContainer = _action_row()
	mission_row_one.add_child(_make_action_button("待命", GameState.set_selected_fleet_mission.bind("IDLE"), "neutral"))
	mission_row_one.add_child(_make_action_button("探索", GameState.set_selected_fleet_mission.bind("EXPLORE"), "primary"))
	mission_row_one.add_child(_make_action_button("殖民", GameState.set_selected_fleet_mission.bind("COLONIZE"), "accent"))
	mission_row_one.add_child(_make_action_button("驻防", GameState.set_selected_fleet_mission.bind("GUARD"), "neutral"))
	_panel_add(mission_row_one)
	var mission_row_two: HBoxContainer = _action_row()
	mission_row_two.add_child(_make_action_button("打击", GameState.set_selected_fleet_mission.bind("STRIKE"), "danger"))
	mission_row_two.add_child(_make_action_button("进入移动模式", GameState.begin_fleet_move_mode.bind(fleet.get("id", "")), "primary"))
	mission_row_two.add_child(_make_action_button("退出移动模式", GameState.cancel_fleet_move_mode, "neutral"))
	mission_row_two.add_child(_make_action_button("修复舰队", GameState.repair_fleet.bind(fleet.get("id", "")), "accent"))
	_panel_add(mission_row_two)
	_panel_add(_make_status_card("任务状态", [
		"移动模式: %s" % ("已开启，点击星图中的可达星系即可跃迁。" if GameState.fleet_move_mode else "未开启"),
		"可达星系: %s" % str(GameState.get_reachable_system_ids(fleet.get("id", "")).size()),
		"当前驻留: %s" % GameState.get_system_by_id(fleet.get("systemId", "")).get("name", "")
	]))
	var mission_row_three: HBoxContainer = _action_row()
	mission_row_three.add_child(_make_action_button("拆分舰队", GameState.split_selected_fleet, "neutral"))
	mission_row_three.add_child(_make_action_button("合并本星系舰队", GameState.merge_player_fleets_at_selected_system, "accent"))
	mission_row_three.add_child(_make_action_button("状态评估", GameState.request_selected_fleet_status, "accent"))
	_panel_add(mission_row_three)
	for ship: Dictionary in fleet.get("ships", []):
		_panel_add(_make_fleet_ship_card(ship))
	for route: Dictionary in GameState.get_reachable_system_details(fleet.get("id", "")):
		var system_id: String = str(route.get("systemId", ""))
		var system: Dictionary = GameState.get_system_by_id(system_id)
		var fits_bandwidth: bool = bool(route.get("fitsBandwidth", true))
		_panel_add(_make_route_card(route, system, fits_bandwidth))
		var row: HBoxContainer = _action_row()
		row.add_child(_make_action_button(system.get("name", system_id), GameState.select_system.bind(system_id), "neutral"))
		_panel_add(row)

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
	card.get_node("Content/Title").text = "%s / T%s / %s" % [tech.get("name", ""), str(tech.get("tier", 1)), tech.get("category", "")]
	card.get_node("Content/Description").text = str(tech.get("description", ""))
	var meta_label: Label = card.get_node("Content/Meta")
	meta_label.text = "研究时间: %s 回合 / 研究成本: %s" % [str(tech.get("researchTime", 0)), str(tech.get("cost", 0))]
	var effects_list: VBoxContainer = card.get_node("Content/Columns/EffectsColumn/EffectsList")
	var unlocks_list: VBoxContainer = card.get_node("Content/Columns/UnlocksColumn/UnlocksList")
	if researching:
		effects_list.add_child(_make_rich_info_line("当前进度: %.0f%%" % float(tech.get("progress", 0.0))))
	for effect: String in tech.get("effects", []):
		effects_list.add_child(_make_rich_info_line("• %s" % effect))
	for unlock_name: String in tech.get("unlocks", []):
		unlocks_list.add_child(_make_rich_info_line("• %s" % unlock_name, Color("8BE9FD")))
	if effects_list.get_child_count() == 0:
		effects_list.add_child(_make_rich_info_line("• 无直接加成"))
	if unlocks_list.get_child_count() == 0:
		unlocks_list.add_child(_make_rich_info_line("• 无新增解锁", Color("8BE9FD")))
	return card


func _action_row() -> HBoxContainer:
	return ACTION_ROW_SCENE.instantiate()

func _make_chip(title: String, value: String) -> PanelContainer:
	var panel: PanelContainer = CHIP_SCENE.instantiate()
	var content: VBoxContainer = panel.get_node("Content")
	var title_label: Label = content.get_node("Title")
	title_label.text = title
	var value_label: Label = content.get_node("Value")
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

func _make_action_button(label: String, callable: Callable, variant: String = "default") -> Button:
	var button: Button = ACTION_BUTTON_SCENE.instantiate()
	button.text = label
	_apply_button_variant(button, variant)
	if callable.is_valid():
		button.pressed.connect(callable)
	return button

func _make_rich_info_line(text: String, accent_color: Color = Color("FFD989")) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", 14)
	label.add_theme_color_override("default_color", Color("E8EEFF"))
	label.text = _highlight_numeric_segments(text, accent_color)
	return label

func _highlight_numeric_segments(text: String, accent_color: Color = Color("FFD989")) -> String:
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

func _apply_button_variant(button: Button, variant: String) -> void:
	var normal_color: Color = Color("27304A")
	var hover_color: Color = Color("324064")
	var pressed_color: Color = Color("5B6FB2")
	var border_color: Color = Color("6278B8")
	match variant:
		"primary":
			normal_color = Color("335CFF")
			hover_color = Color("4B70FF")
			pressed_color = Color("2749CC")
			border_color = Color("9DB1FF")
		"accent":
			normal_color = Color("145B61")
			hover_color = Color("1A7880")
			pressed_color = Color("0F4449")
			border_color = Color("7EE7F2")
		"danger":
			normal_color = Color("6E2736")
			hover_color = Color("8A3244")
			pressed_color = Color("541C28")
			border_color = Color("FF9AAE")
		"neutral":
			normal_color = Color("202839")
			hover_color = Color("2A3448")
			pressed_color = Color("18202D")
			border_color = Color("7484A8")
	var normal_style: StyleBoxFlat = _button_style(normal_color, border_color, 14)
	var hover_style: StyleBoxFlat = _button_style(hover_color, border_color.lightened(0.12), 14)
	var pressed_style: StyleBoxFlat = _button_style(pressed_color, border_color, 14)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)

func _open_center_modal(title: String, subtitle: String, builder: Callable) -> void:
	_modal_payload = {
		"title": title,
		"subtitle": subtitle,
	}
	modal_title.text = title
	modal_subtitle.text = subtitle
	for child: Node in modal_content.get_children():
		child.queue_free()
	if builder.is_valid():
		builder.call()
	center_modal_overlay.visible = true

func _open_global_tab_modal(tab_name: String) -> void:
	_open_center_modal(
		TAB_LABELS.get(tab_name, "面板"),
		"查看全局信息与操作入口。",
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
		"完整通信记录",
		func() -> void:
			var security: Dictionary = message.get("securitySettings", {})
			modal_content.add_child(_make_feed_card(
				"T%s / %s" % [str(message.get("turn", 1)), str(message.get("title", "通信"))],
				"发送者: %s / 目标类型: %s / 可见级别: %s" % [
					str(message.get("senderName", message.get("senderId", ""))),
					_target_type_label(str(message.get("targetType", "SINGLE"))),
					VISIBILITY_LABELS.get(str(message.get("visibilityLevel", "PUBLIC")), str(message.get("visibilityLevel", "PUBLIC")))
				],
				str(message.get("content", "")),
				"加密等级: %s / 保留: %s 回合" % [str(security.get("encryptionLevel", 0)), str(security.get("expiresAfterTurns", 10))]
			))
	)

func _open_proposal_modal(proposal: Dictionary) -> void:
	_open_center_modal(
		str(proposal.get("title", "外交提案")),
		"提案详情与处理",
		func() -> void:
			modal_content.add_child(_make_proposal_card(proposal))
			var action_row: HBoxContainer = _action_row()
			action_row.add_child(_make_action_button("接受提案", GameState.accept_diplomatic_proposal.bind(proposal.get("id", "")), "primary"))
			action_row.add_child(_make_action_button("拒绝提案", GameState.reject_diplomatic_proposal.bind(proposal.get("id", "")), "danger"))
			action_row.add_child(_make_action_button("战略评估", GameState.request_proposal_evaluation.bind(proposal.get("id", "")), "accent"))
			modal_content.add_child(action_row)
	)

func _open_faction_modal(faction: Dictionary, relation: Dictionary, active_treaties: Array, history: Array) -> void:
	_open_center_modal(
		"%s / %s" % [str(faction.get("name", "")), str(faction.get("leaderName", ""))],
		"外交详情与关系历史",
		func() -> void:
			modal_content.add_child(_make_diplomacy_faction_card(faction, relation, active_treaties))
			if not history.is_empty():
				var trend_parts: Array = []
				for snapshot: Dictionary in history:
					trend_parts.append("T%s:%s/%s/%s" % [str(snapshot.get("turn", 0)), str(snapshot.get("trust", 0)), str(snapshot.get("fear", 0)), str(snapshot.get("memoryImpact", 0))])
				modal_content.add_child(_make_trend_card("关系趋势", "信任/恐惧/记忆: %s" % " -> ".join(trend_parts)))
			modal_content.add_child(_make_section_title("常用外交文本"))
			modal_content.add_child(_make_info_card([
				"点击下方预设会先填入草稿框，你可以再微调措辞后发送。",
				"公开适合表态，限制或加密更适合交换条件与试探底线。"
			]))
			modal_content.add_child(_make_section_title("限制与交易 API"))
			var action_row: HBoxContainer = _action_row()
			action_row.add_child(_make_action_button("限制边境扩张", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_BORDER_LIMIT", {"scope": "border_expansion"}), "neutral"))
			action_row.add_child(_make_action_button("限制舰队逼近", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_FLEET_DISTANCE", {"distance": "two_jumps"}), "neutral"))
			modal_content.add_child(action_row)
			var trade_row: HBoxContainer = _action_row()
			trade_row.add_child(_make_action_button("资源交换评估", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_RESOURCE_TRADE", {"offer": "minerals_for_energy"}), "accent"))
			trade_row.add_child(_make_action_button("科研互换评估", GameState.request_diplomatic_action.bind(faction.get("id", ""), "REQUEST_RESEARCH_EXCHANGE", {"scope": "civilian_science"}), "primary"))
			modal_content.add_child(trade_row)
			var diplomatic_action_report: Dictionary = GameState.world_data.get("diplomatic_action_report", {})
			if not diplomatic_action_report.is_empty() and str(diplomatic_action_report.get("target_faction_id", "")) == str(faction.get("id", "")):
				modal_content.add_child(_make_api_report_card(
					"外交动作评估",
					"%s / 关系 %s / 声望变化 %s" % [
						str(diplomatic_action_report.get("summary", "暂无结果")),
						RELATION_LEVEL_NAMES.get(str(diplomatic_action_report.get("relationship_level", "UNKNOWN")), str(diplomatic_action_report.get("relationship_level", "UNKNOWN"))),
						_signed_int_text(int(diplomatic_action_report.get("reputation_change", 0)))
					],
					diplomatic_action_report.get("detail_lines", [])
				))
			modal_content.add_child(_make_section_title("拟定外交照会"))
			modal_content.add_child(_make_diplomacy_composer(faction.get("id", "")))
	)

func _make_section_title(text: String) -> Label:
	var label: Label = SECTION_TITLE_SCENE.instantiate()
	label.text = text
	return label

func _make_info_card(lines: Array) -> PanelContainer:
	var panel: PanelContainer = INFO_CARD_SCENE.instantiate()
	var content: VBoxContainer = panel.get_node("Content")
	for raw_line: Variant in lines:
		var line: String = str(raw_line)
		if line == "":
			continue
		var label: Label = INFO_LINE_SCENE.instantiate()
		label.text = line
		content.add_child(label)
	return panel

func _make_status_card(title: String, lines: Array) -> PanelContainer:
	var card: PanelContainer = STATUS_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	var details: VBoxContainer = card.get_node("Content/Details")
	for raw_line: Variant in lines:
		var line: String = str(raw_line)
		if line != "":
			var label: Label = INFO_LINE_SCENE.instantiate()
			label.text = line
			details.add_child(label)
	return card

func _make_diplomacy_composer(faction_id: String) -> VBoxContainer:
	var composer: VBoxContainer = DIPLOMACY_COMPOSER_SCENE.instantiate()
	var draft_box: TextEdit = composer.get_node("DraftBox")
	var preset_wrap: FlowContainer = composer.get_node("PresetWrap")
	for preset: Dictionary in _diplomacy_presets(faction_id):
		var preset_button: Button = _make_action_button(str(preset.get("label", "预设")), Callable(), str(preset.get("variant", "neutral")))
		preset_button.pressed.connect(_apply_diplomacy_preset.bind(draft_box, faction_id, str(preset.get("template", ""))))
		preset_wrap.add_child(preset_button)
	draft_box.text = GameState.get_diplomatic_draft(faction_id)
	draft_box.text_changed.connect(_on_draft_text_changed.bind(draft_box, faction_id))
	var visibility_selector: OptionButton = composer.get_node("Controls/VisibilitySelector")
	visibility_selector.clear()
	visibility_selector.add_item("公开", 0)
	visibility_selector.add_item("限制", 1)
	visibility_selector.add_item("秘密", 2)
	visibility_selector.add_item("加密", 3)
	var current_visibility: String = GameState.get_diplomatic_visibility(faction_id)
	visibility_selector.selected = 0 if current_visibility == "PUBLIC" else 1 if current_visibility == "RESTRICTED" else 2 if current_visibility == "SECRET" else 3
	visibility_selector.item_selected.connect(_on_visibility_selected.bind(faction_id))
	var send_button: Button = composer.get_node("Controls/SendButton")
	send_button.pressed.connect(GameState.send_player_message.bind(faction_id))
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
			"label": "资源换停火",
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
			"template": "致 %s：边境紧张对双方都没有益处。我方建议先降低前沿对抗强度，并建立一次性风险通报渠道，避免误判升级。" % faction_name
		},
		{
			"label": "限制边境扩张",
			"variant": "neutral",
			"template": "致 %s：我方要求贵方暂停边境扩张与前沿前哨建设，并在观察期内维持现有边界安排，以免局势失控。" % faction_name
		},
		{
			"label": "限制舰队逼近",
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

func _make_route_card(route: Dictionary, system: Dictionary, fits_bandwidth: bool) -> PanelContainer:
	var card: PanelContainer = ROUTE_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = str(route.get("systemName", system.get("name", route.get("systemId", ""))))
	card.get_node("Content/Meta").text = "通道: %s / 消耗: %s / 带宽: %s" % [
		"虫洞" if str(route.get("laneType", "LANE")) == "WORMHOLE" else "航道",
		str(route.get("traversalCost", 1)),
		str(route.get("bandwidth", 0))
	]
	card.get_node("Content/Status").text = "通行状态: %s" % ("可通行" if fits_bandwidth else "带宽不足")
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

func _make_fleet_ship_card(ship: Dictionary) -> PanelContainer:
	var card: PanelContainer = FLEET_SHIP_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = "%s / %s" % [ship.get("name", ""), InitialDataScript.ship_labels().get(ship.get("type", ""), ship.get("type", ""))]
	card.get_node("Content/Stats").text = "HP %s/%s / 伤害 %s" % [str(ship.get("hp", 0)), str(ship.get("maxHp", 0)), str(ship.get("damage", 0))]
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

func _make_feed_card(title: String, meta: String, body: String, footnote: String) -> PanelContainer:
	var card: PanelContainer = FEED_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = title
	var meta_label: Label = card.get_node("Content/Meta")
	meta_label.text = meta
	meta_label.visible = meta != ""
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
	card.get_node("Content/Title").text = "%s / %s" % [faction.get("name", ""), faction.get("leaderName", "")]
	card.get_node("Content/Relation").text = "关系等级: %s" % RELATION_LEVEL_NAMES.get(str(relation.get("level", "UNKNOWN")), str(relation.get("level", "UNKNOWN")))
	card.get_node("Content/Stats").text = "信任: %s / 利益: %s / 恐惧: %s / 好感: %s / 记忆影响: %s" % [
		str(relation.get("trust", 0)),
		str(relation.get("utility", 0)),
		str(relation.get("fear", 0)),
		str(relation.get("affinity", 0)),
		str(relation.get("memoryImpact", 0))
	]
	card.get_node("Content/Traits").text = "现行条约: %s" % _treaty_names_text(active_treaties)
	card.get_node("Content/Persona").text = "公开外交人设: %s / 近期语气: %s" % [
		str(faction.get("diplomaticProfile", {}).get("publicPersona", "未知")),
		_tone_label(str(faction.get("diplomaticProfile", {}).get("recentTone", "neutral")))
	]
	return card

func _make_colonization_option_card(mode_key: String, mode_data: Dictionary, preview: Dictionary) -> PanelContainer:
	var card: PanelContainer = COLONIZATION_OPTION_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = "%s / %s 回合" % [mode_data.get("name", mode_key), str(preview.get("turns", mode_data.get("turns", 0)))]
	card.get_node("Content/Description").text = str(mode_data.get("description", ""))
	card.get_node("Content/Cost").text = "花费: %s" % _resource_line(preview.get("cost", mode_data.get("cost", {})))
	card.get_node("Content/Stats").text = "初始人口: %s / 初始稳定度: %s / 初始补给: %s / 前哨格位: %s" % [str(preview.get("initial_population", mode_data.get("initial_population", 0))), str(preview.get("initial_stability", mode_data.get("initial_stability", 0))), str(preview.get("initial_supply", mode_data.get("initial_supply", 0))), str(preview.get("slot_cap", mode_data.get("slot_cap", 0)))]
	card.get_node("Content/Risk").text = "维护: %s / 风险: %s / 说明: %s" % [_resource_line(preview.get("maintenance", mode_data.get("maintenance", {}))), str(preview.get("risk", mode_data.get("risk", "未知"))), str(preview.get("reason", ""))]
	return card

func _make_proposal_card(proposal: Dictionary) -> PanelContainer:
	var card: PanelContainer = PROPOSAL_CARD_SCENE.instantiate()
	card.get_node("Content/Title").text = str(proposal.get("title", "外交提案"))
	card.get_node("Content/Type").text = "提案类型: %s" % PROPOSAL_TYPE_LABELS.get(str(proposal.get("proposalType", "UNKNOWN")), str(proposal.get("proposalType", "UNKNOWN")))
	card.get_node("Content/Deadline").text = "截止回合: T%s" % str(proposal.get("expiresOnTurn", 0))
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
		var label: Label = INFO_LINE_SCENE.instantiate()
		label.text = line
		details.add_child(label)
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
	card.get_node("Content/Posture").text = "建议姿态: %s" % POSTURE_LABELS.get(str(posture.get("recommended_posture", "CONSOLIDATE")), str(posture.get("recommended_posture", "CONSOLIDATE")))
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

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style

func _button_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel_style(fill, border, radius)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style

func _configure_tab_button(button: Button, active: bool) -> void:
	button.button_pressed = active
	if active:
		var active_style: StyleBoxFlat = _button_style(Color("C8B7FF"), Color("C8B7FF"), 16)
		var active_hover_style: StyleBoxFlat = _button_style(Color("DDD3FF"), Color("E8E0FF"), 16)
		var active_pressed_style: StyleBoxFlat = _button_style(Color("A891F7"), Color("C8B7FF"), 16)
		button.add_theme_color_override("font_color", Color("0B0C15"))
		button.add_theme_stylebox_override("normal", active_style)
		button.add_theme_stylebox_override("hover", active_hover_style)
		button.add_theme_stylebox_override("pressed", active_pressed_style)
		button.add_theme_stylebox_override("focus", active_hover_style)
	else:
		button.remove_theme_stylebox_override("normal")
		button.remove_theme_stylebox_override("hover")
		button.remove_theme_stylebox_override("pressed")
		button.remove_theme_stylebox_override("focus")
		button.remove_theme_color_override("font_color")

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

func _on_draft_text_changed(editor: TextEdit, faction_id: String) -> void:
	GameState.set_diplomatic_draft(faction_id, editor.text)

func _on_visibility_selected(index: int, faction_id: String) -> void:
	var value: String = "PUBLIC"
	if index == 1:
		value = "RESTRICTED"
	elif index == 2:
		value = "SECRET"
	elif index == 3:
		value = "ENCRYPTED"
	GameState.set_diplomatic_visibility(faction_id, value)

func _on_diplomacy_changed() -> void:
	if GameState.active_tab == "DIPLOMACY" or GameState.active_tab == "COMMS":
		refresh()
		_refresh_visible_panels()
