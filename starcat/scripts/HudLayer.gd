extends CanvasLayer

const TAB_NAMES: Array = ["OBJECTIVES", "TECH", "DIPLOMACY", "ADVISOR"]
const TAB_LABELS: Dictionary = {
	"OBJECTIVES": "战局",
	"TECH": "科技",
	"DIPLOMACY": "外交",
	"ADVISOR": "顾问"
}

const RESOURCE_NAMES: Dictionary = {
	"food": "食物",
	"minerals": "矿产",
	"industry": "工业",
	"energy": "能源"
}

@onready var root: Control = $Root
@onready var top_bar: HBoxContainer = $Root/TopBar
@onready var right_drawer: PanelContainer = $Root/RightDrawer
@onready var drawer_title: Label = $Root/RightDrawer/Margin/DrawerVBox/DrawerHeader/TitleBox/DrawerTitle
@onready var drawer_subtitle: Label = $Root/RightDrawer/Margin/DrawerVBox/DrawerHeader/TitleBox/DrawerSubtitle
@onready var drawer_content: VBoxContainer = $Root/RightDrawer/Margin/DrawerVBox/DrawerBody/DrawerContent
@onready var next_turn_button: Button = $Root/RightDrawer/Margin/DrawerVBox/NextTurnButton
@onready var bottom_tabs: HBoxContainer = $Root/BottomTabs

func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.tab_changed.connect(_on_tab_changed)
	GameState.labels_visibility_changed.connect(_on_labels_visibility_changed)
	GameState.backend_status_changed.connect(_on_backend_status_changed)
	GameState.advisor_changed.connect(_on_advisor_changed)
	GameState.diplomacy_changed.connect(_on_diplomacy_changed)
	next_turn_button.pressed.connect(GameState.advance_turn)
	_apply_theme()
	refresh()

func refresh() -> void:
	next_turn_button.disabled = GameState.turn_busy or GameState.game_state.get("status", "") != "PLAYING"
	next_turn_button.text = "敌方决策中..." if GameState.turn_busy else "推进下一回合"
	_rebuild_top_bar()
	_rebuild_drawer()
	_rebuild_bottom_tabs()

func _apply_theme() -> void:
	var drawer_style: StyleBoxFlat = StyleBoxFlat.new()
	drawer_style.bg_color = Color(0.07, 0.08, 0.13, 0.94)
	drawer_style.border_width_left = 1
	drawer_style.border_width_top = 1
	drawer_style.border_width_right = 1
	drawer_style.border_width_bottom = 1
	drawer_style.border_color = Color("5C6B9C")
	drawer_style.corner_radius_top_left = 18
	drawer_style.corner_radius_top_right = 18
	drawer_style.corner_radius_bottom_left = 18
	drawer_style.corner_radius_bottom_right = 18
	right_drawer.add_theme_stylebox_override("panel", drawer_style)

func _rebuild_top_bar() -> void:
	for child: Node in top_bar.get_children():
		child.queue_free()
	var player: Dictionary = GameState.get_player_faction()
	var resources: Dictionary = player.get("resources", {})
	var rates: Dictionary = player.get("resourceRates", {})
	top_bar.add_child(_make_chip("回合", str(GameState.game_state.get("turn", 1))))
	top_bar.add_child(_make_chip("时代", _era_name(GameState.game_state.get("era", "PIONEER"))))
	top_bar.add_child(_make_resource_chip("食物", int(resources.get("food", 0)), int(rates.get("food", 0))))
	top_bar.add_child(_make_resource_chip("矿产", int(resources.get("minerals", 0)), int(rates.get("minerals", 0))))
	top_bar.add_child(_make_resource_chip("工业", int(resources.get("industry", 0)), int(rates.get("industry", 0))))
	top_bar.add_child(_make_resource_chip("能源", int(resources.get("energy", 0)), int(rates.get("energy", 0))))
	var labels_button: Button = _make_action_button("地图文字: %s" % ("已显示" if GameState.labels_visible else "已隐藏"), GameState.toggle_labels)
	labels_button.custom_minimum_size = Vector2(160, 56)
	top_bar.add_child(labels_button)

func _rebuild_drawer() -> void:
	for child: Node in drawer_content.get_children():
		child.queue_free()

	var selected_fleet: Dictionary = GameState.get_fleet_by_id(GameState.selected_fleet_id)
	var selected_system: Dictionary = GameState.get_system_by_id(GameState.selected_system_id)

	if not selected_fleet.is_empty():
		drawer_title.text = "舰队指挥"
		drawer_subtitle.text = "当前为舰队操作上下文"
		_build_fleet_panel(selected_fleet)
	elif not selected_system.is_empty():
		drawer_title.text = "星系建设"
		drawer_subtitle.text = "当前为星系建设上下文"
		_build_system_panel(selected_system)
	else:
		drawer_title.text = TAB_LABELS.get(GameState.active_tab, "总览")
		drawer_subtitle.text = "通过底部导航切换系统面板"
		match GameState.active_tab:
			"TECH":
				_build_tech_panel()
			"DIPLOMACY":
				_build_diplomacy_panel()
			"ADVISOR":
				_build_advisor_panel()
			_:
				_build_objectives_panel()

func _rebuild_bottom_tabs() -> void:
	for child: Node in bottom_tabs.get_children():
		child.queue_free()
	for tab_name: String in TAB_NAMES:
		var button: Button = _make_action_button(TAB_LABELS.get(tab_name, tab_name), _on_tab_pressed.bind(tab_name))
		button.toggle_mode = true
		button.button_pressed = GameState.active_tab == tab_name
		button.custom_minimum_size = Vector2(128, 52)
		if button.button_pressed:
			button.add_theme_color_override("font_color", Color("0B0C15"))
			button.add_theme_stylebox_override("normal", _button_style(Color("C8B7FF"), Color("C8B7FF"), 16))
		bottom_tabs.add_child(button)

func _build_objectives_panel() -> void:
	drawer_content.add_child(_make_section_title("战局目标"))
	drawer_content.add_child(_make_info_card([
		"目标: %s" % str(GameState.game_state.get("objective", "")),
		"状态: %s" % str(GameState.game_state.get("status", "PLAYING")),
		"飞升进度: %s/100" % str(GameState.game_state.get("ascension_progress", 0)),
		"胜利路径: %s" % str(GameState.game_state.get("victory_path", "未达成"))
	]))
	var active_events: Array = GameState.get_active_narrative_events()
	if not active_events.is_empty():
		drawer_content.add_child(_make_section_title("待处理事件"))
		for event_item: Dictionary in active_events.slice(0, min(4, active_events.size())):
			drawer_content.add_child(_make_info_card([
				"%s · %s" % [str(event_item.get("title", "事件")), GameState.get_system_by_id(event_item.get("systemId", "")).get("name", event_item.get("systemId", ""))],
				str(event_item.get("summary", "")),
			]))
			var options_row: HBoxContainer = _action_row()
			for option: String in event_item.get("followUpOptions", []):
				options_row.add_child(_make_action_button(option, GameState.resolve_narrative_event.bind(event_item.get("id", ""), option)))
			drawer_content.add_child(options_row)
	var interventions: Array = GameState.get_active_interventions()
	if not interventions.is_empty():
		drawer_content.add_child(_make_section_title("持续干预"))
		for item: Dictionary in interventions.slice(0, min(4, interventions.size())):
			drawer_content.add_child(_make_info_card([
				"%s" % str(item.get("type", "INTERVENTION")),
				"剩余回合: %s / 强度: %s" % [str(item.get("remainingTurns", 0)), str(item.get("intensity", 0.0))]
			]))
	var messages: Array = GameState.game_state.get("messages", [])
	if not messages.is_empty():
		drawer_content.add_child(_make_section_title("最新情报"))
		for message: Dictionary in messages.slice(0, min(6, messages.size())):
			drawer_content.add_child(_make_info_card([
				"T%s · %s" % [str(message.get("turn", 1)), message.get("title", "")],
				message.get("content", "")
			]))
	var combat_reports: Array = GameState.get_recent_combat_reports()
	if not combat_reports.is_empty():
		drawer_content.add_child(_make_section_title("近期战报"))
		for report: Dictionary in combat_reports.slice(0, min(3, combat_reports.size())):
			drawer_content.add_child(_make_info_card([
				"T%s · %s" % [str(report.get("turn", 1)), str(report.get("title", "战斗报告"))],
				"%s vs %s" % [str(report.get("attackerName", "进攻方")), str(report.get("defenderName", "防御方"))],
				"结果: %s / 损失: %s / 击毁: %s / 剩余战力: %s%%" % [
					"胜利" if report.get("victory", false) else "失利",
					str(report.get("casualties", 0)),
					str(report.get("kills", 0)),
					str(report.get("remainingPower", 0))
				],
				"战术: %s" % " / ".join(report.get("tacticalNotes", []))
			]))
	drawer_content.add_child(_make_action_button("重新开局", GameState.reset_state))

func _build_tech_panel() -> void:
	drawer_content.add_child(_make_section_title("科技研究"))
	var current_research_id: Variant = GameState.game_state.get("currentResearchId", null)
	if current_research_id != null:
		for tech: Dictionary in GameState.game_state.get("technologies", []):
			if tech.get("id", "") == str(current_research_id):
				drawer_content.add_child(_make_tech_card(tech, true))
				drawer_content.add_child(_make_action_button("取消当前研究", GameState.cancel_research))
				break
	for tech: Dictionary in GameState.game_state.get("technologies", []):
		if tech.get("status", "") != "AVAILABLE":
			continue
		drawer_content.add_child(_make_tech_card(tech, false))
		var button: Button = _make_action_button("开始研究", GameState.start_research.bind(tech.get("id", "")))
		button.disabled = current_research_id != null
		drawer_content.add_child(button)

func _build_diplomacy_panel() -> void:
	drawer_content.add_child(_make_section_title("外交关系"))
	var interception_report: Dictionary = GameState.get_interception_report()
	var diplomacy_report: Dictionary = GameState.get_diplomatic_victory_report()
	drawer_content.add_child(_make_info_card([
		"情报监听: %s" % interception_report.get("status", "基础监听"),
		"基础截获率: %s%%" % str(interception_report.get("base", 0)),
		"受限通讯截获率: %s%%" % str(interception_report.get("restricted", 0)),
		"秘密通讯截获率: %s%%" % str(interception_report.get("secret", 0)),
		"加密通讯截获率: %s%%" % str(interception_report.get("encrypted", 0))
	]))
	drawer_content.add_child(_make_info_card([
		"外交胜利进度",
		"同盟: %s" % str(diplomacy_report.get("alliances", 0)),
		"科研协定: %s/%s" % [str(diplomacy_report.get("accords", 0)), str(diplomacy_report.get("total_rivals", 0))],
		"和平关系: %s/%s" % [str(diplomacy_report.get("peace_partners", 0)), str(diplomacy_report.get("total_rivals", 0))],
		"战争状态: %s" % str(diplomacy_report.get("wars", 0))
	]))
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogic.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var active_treaties: Array = GameLogic.active_treaties_between(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		drawer_content.add_child(_make_info_card([
			"%s · %s" % [faction.get("name", ""), faction.get("leaderName", "")],
			"关系等级: %s" % relation.get("level", "UNKNOWN"),
			"信任: %s / 利用价值: %s" % [str(relation.get("trust", 0)), str(relation.get("utility", 0))],
			"忌惮: %s / 好感: %s / 记忆影响: %s" % [str(relation.get("fear", 0)), str(relation.get("affinity", 0)), str(relation.get("memoryImpact", 0))],
			"现行条约: %s" % _treaty_names_text(active_treaties),
			"外交人设: %s" % faction.get("diplomaticProfile", {}).get("publicPersona", "暂无"),
			"最近语气: %s" % faction.get("diplomaticProfile", {}).get("recentTone", "neutral")
		]))
		var history: Array = GameState.get_relation_history(faction.get("id", ""))
		if not history.is_empty():
			var trend_parts: Array = []
			for snapshot: Dictionary in history:
				trend_parts.append("T%s:%s/%s/%s" % [str(snapshot.get("turn", 0)), str(snapshot.get("trust", 0)), str(snapshot.get("fear", 0)), str(snapshot.get("memoryImpact", 0))])
			drawer_content.add_child(_make_info_card([
				"趋势追踪",
				"信任/忌惮/记忆: %s" % " -> ".join(trend_parts)
			]))
		var row_one: HBoxContainer = _action_row()
		row_one.add_child(_make_action_button("贸易", GameState.trade_with_faction.bind(faction.get("id", ""))))
		row_one.add_child(_make_action_button("警告", _threat_and_request.bind(faction.get("id", ""))))
		row_one.add_child(_make_action_button("致函", GameState.request_diplomatic_message.bind(faction.get("id", ""), "friendly")))
		drawer_content.add_child(row_one)
		var row_two: HBoxContainer = _action_row()
		row_two.add_child(_make_action_button("互不侵犯", GameState.propose_treaty.bind(faction.get("id", ""), "NON_AGGRESSION")))
		row_two.add_child(_make_action_button("科研协定", GameState.propose_treaty.bind(faction.get("id", ""), "RESEARCH_ACCORD")))
		row_two.add_child(_make_action_button("同盟", GameState.propose_treaty.bind(faction.get("id", ""), "ALLIANCE")))
		drawer_content.add_child(row_two)
		var row_three: HBoxContainer = _action_row()
		row_three.add_child(_make_action_button("废止互不侵犯", GameState.revoke_treaty.bind(faction.get("id", ""), "NON_AGGRESSION")))
		row_three.add_child(_make_action_button("废止科研协定", GameState.revoke_treaty.bind(faction.get("id", ""), "RESEARCH_ACCORD")))
		row_three.add_child(_make_action_button("正式宣战", GameState.declare_war.bind(faction.get("id", ""))))
		drawer_content.add_child(row_three)
		drawer_content.add_child(_make_section_title("自由交流"))
		var draft_box: TextEdit = TextEdit.new()
		draft_box.custom_minimum_size = Vector2(0, 96)
		draft_box.placeholder_text = "输入你想对该 AI 说的话，例如：我愿意开放边境贸易，但要求你停止在北极星附近集结舰队。"
		draft_box.text = GameState.get_diplomatic_draft(faction.get("id", ""))
		draft_box.text_changed.connect(_on_draft_text_changed.bind(draft_box, faction.get("id", "")))
		drawer_content.add_child(draft_box)
		var intent_preview: Dictionary = GameState.get_diplomatic_intent_preview(faction.get("id", ""))
		drawer_content.add_child(_make_info_card([
			"意图预览: %s" % intent_preview.get("label", "一般交流"),
			intent_preview.get("detail", ""),
			"预估关系变化: %s%s" % ["+" if int(intent_preview.get("trust_delta", 0)) >= 0 else "", str(intent_preview.get("trust_delta", 0))]
		]))
		drawer_content.add_child(_make_info_card([
			"输入提示: 文本里出现“互不侵犯 / 科研协定 / 同盟 / 贸易 / 警告”等关键词时，会被系统解析成更明确的外交意图。"
		]))
		var compose_row: HBoxContainer = _action_row()
		var visibility_selector: OptionButton = OptionButton.new()
		visibility_selector.add_item("公开", 0)
		visibility_selector.add_item("受限", 1)
		visibility_selector.add_item("秘密", 2)
		visibility_selector.add_item("加密", 3)
		var current_visibility: String = GameState.get_diplomatic_visibility(faction.get("id", ""))
		visibility_selector.selected = 0 if current_visibility == "PUBLIC" else 1 if current_visibility == "RESTRICTED" else 2 if current_visibility == "SECRET" else 3
		visibility_selector.item_selected.connect(_on_visibility_selected.bind(faction.get("id", "")))
		compose_row.add_child(visibility_selector)
		compose_row.add_child(_make_action_button("发送自由来函", GameState.send_player_message.bind(faction.get("id", ""))))
		drawer_content.add_child(compose_row)

	drawer_content.add_child(_make_section_title("通讯中心"))
	var visible_messages: Array = GameState.get_visible_diplomatic_messages()
	if visible_messages.is_empty():
		drawer_content.add_child(_make_info_card(["当前暂无可见外交通讯。"]))
	else:
		for message: Dictionary in visible_messages.slice(0, min(10, visible_messages.size())):
			var security: Dictionary = message.get("securitySettings", {})
			drawer_content.add_child(_make_info_card([
				"T%s · %s" % [str(message.get("turn", 1)), message.get("title", "")],
				"发送方: %s" % str(message.get("senderName", message.get("senderId", ""))),
				"目标类型: %s / 可见性: %s" % [str(message.get("targetType", "SINGLE")), str(message.get("visibilityLevel", "PUBLIC"))],
				"加密强度: %s / 时效: %s 回合" % [str(security.get("encryptionLevel", 0)), str(security.get("expiresAfterTurns", 10))],
				message.get("content", "")
			]))

	drawer_content.add_child(_make_section_title("待处理提案"))
	var pending_proposals: Array = GameState.get_pending_proposals()
	if pending_proposals.is_empty():
		drawer_content.add_child(_make_info_card(["当前没有等待你处理的 AI 外交提案。"]))
	else:
		for proposal: Dictionary in pending_proposals:
			drawer_content.add_child(_make_info_card([
				"%s" % proposal.get("title", "外交提案"),
				"提案类型: %s" % str(proposal.get("proposalType", "UNKNOWN")),
				"到期回合: T%s" % str(proposal.get("expiresOnTurn", 0)),
				proposal.get("summary", "")
			]))
			var proposal_row: HBoxContainer = _action_row()
			proposal_row.add_child(_make_action_button("接受提案", GameState.accept_diplomatic_proposal.bind(proposal.get("id", ""))))
			proposal_row.add_child(_make_action_button("拒绝提案", GameState.reject_diplomatic_proposal.bind(proposal.get("id", ""))))
			drawer_content.add_child(proposal_row)

	drawer_content.add_child(_make_section_title("外交记忆"))
	var memories: Array = GameState.get_visible_diplomatic_memories()
	if memories.is_empty():
		drawer_content.add_child(_make_info_card(["当前没有可回看的外交记忆。"]))
	else:
		for memory: Dictionary in memories.slice(0, min(8, memories.size())):
			drawer_content.add_child(_make_info_card([
				"T%s · %s" % [str(memory.get("turn", 1)), memory.get("title", "")],
				"类别: %s / 重要度: %s" % [str(memory.get("category", "EVENT")), str(memory.get("importance", 1))],
				memory.get("summary", "")
			]))

	if not GameState.diplomatic_message.is_empty():
		drawer_content.add_child(_make_section_title("外交函"))
		drawer_content.add_child(_make_info_card([
			GameState.diplomatic_message.get("title", ""),
			GameState.diplomatic_message.get("content", "")
		]))

func _build_advisor_panel() -> void:
	drawer_content.add_child(_make_section_title("AI 顾问"))
	drawer_content.add_child(_make_info_card([
		"后端状态: %s" % GameState.backend_status,
		GameState.ai_advice if GameState.ai_advice != "" else "当前暂无 AI 建议。"
	]))
	drawer_content.add_child(_make_section_title("关系态势"))
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogic.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		drawer_content.add_child(_make_info_card([
			"%s" % faction.get("name", ""),
			"等级: %s / 信任: %s / 忌惮: %s" % [str(relation.get("level", "UNKNOWN")), str(relation.get("trust", 0)), str(relation.get("fear", 0))],
			"利用价值: %s / 记忆影响: %s" % [str(relation.get("utility", 0)), str(relation.get("memoryImpact", 0))]
		]))
	drawer_content.add_child(_make_section_title("综合研判"))
	var posture: Dictionary = GameState.get_strategic_posture_report()
	var high_pressure: Array = posture.get("high_pressure", [])
	var high_opportunity: Array = posture.get("high_opportunity", [])
	var deteriorating: Array = posture.get("deteriorating", [])
	var improving: Array = posture.get("improving", [])
	var flashpoints: Array = posture.get("flashpoints", [])
	drawer_content.add_child(_make_info_card([
		"????: %s" % (", ".join(high_pressure) if not high_pressure.is_empty() else "??"),
		"????: %s" % (", ".join(high_opportunity) if not high_opportunity.is_empty() else "??"),
		"????: %s" % (", ".join(deteriorating) if not deteriorating.is_empty() else "??"),
		"????: %s" % (", ".join(improving) if not improving.is_empty() else "??"),
		"????: %s" % (", ".join(flashpoints) if not flashpoints.is_empty() else "??"),
		"????: %s" % str(posture.get("recommended_posture", "CONSOLIDATE")),
		"????: %s" % (
			"????????????????" if not high_pressure.is_empty() and not high_opportunity.is_empty()
			else "??????????????" if not deteriorating.is_empty()
			else "???????????" if high_pressure.is_empty() and not high_opportunity.is_empty()
			else "????????????" if not high_pressure.is_empty()
			else "???????????"
		)
	]))
	var intelligence_feed: Array = GameState.get_recent_intelligence_feed()
	if not intelligence_feed.is_empty():
		drawer_content.add_child(_make_section_title("??????"))
		for item: Dictionary in intelligence_feed.slice(0, min(8, intelligence_feed.size())):
			drawer_content.add_child(_make_info_card([
				"T%s / %s / %s" % [str(item.get("turn", 0)), str(item.get("category", "INFO")), str(item.get("title", "??"))],
				str(item.get("summary", ""))
			]))
	var actions: HBoxContainer = _action_row()
	actions.add_child(_make_action_button("请求 AI 建议", GameState.request_ai_advice))
	actions.add_child(_make_action_button("世界查询", GameState.request_world_query))
	drawer_content.add_child(actions)
	var scan_actions: HBoxContainer = _action_row()
	scan_actions.add_child(_make_action_button("态势扫描", GameState.request_world_state_scan))
	scan_actions.add_child(_make_action_button("舰队状态", GameState.request_selected_fleet_status))
	scan_actions.add_child(_make_action_button("战术评估", GameState.request_selected_tactical_approach))
	drawer_content.add_child(scan_actions)
	var analysis_actions: HBoxContainer = _action_row()
	analysis_actions.add_child(_make_action_button("资源诊断", GameState.request_resource_diagnosis))
	analysis_actions.add_child(_make_action_button("战斗预判", GameState.request_combat_preview))
	drawer_content.add_child(analysis_actions)
	var director_actions: HBoxContainer = _action_row()
	director_actions.add_child(_make_action_button("遗迹事件", GameState.request_director_event_preview.bind("ANCIENT_RUINS_DISCOVERY")))
	director_actions.add_child(_make_action_button("海盗袭扰", GameState.request_director_event_preview.bind("PIRATE_RAID")))
	director_actions.add_child(_make_action_button("跃迁风暴", GameState.request_director_event_preview.bind("WARP_STORM")))
	drawer_content.add_child(director_actions)
	var intervention_actions: HBoxContainer = _action_row()
	intervention_actions.add_child(_make_action_button("海盗干预", GameState.request_director_intervention_preview.bind("SPAWN_PIRATES")))
	intervention_actions.add_child(_make_action_button("AI强化", GameState.request_director_intervention_preview.bind("BOOST_AI")))
	intervention_actions.add_child(_make_action_button("触发危机", GameState.request_director_intervention_preview.bind("TRIGGER_CRISIS")))
	drawer_content.add_child(intervention_actions)
	if not GameState.world_data.is_empty():
		drawer_content.add_child(_make_info_card([GameState.world_data.get("summary", "")]))
		var visible_systems: Array = GameState.world_data.get("visible_systems", [])
		if not visible_systems.is_empty():
			drawer_content.add_child(_make_section_title("已知星域"))
			for system_summary: Dictionary in visible_systems:
				drawer_content.add_child(_make_info_card([
					"%s · 价值 %s" % [system_summary.get("name", "未知星系"), str(system_summary.get("value", 0))],
					"归属: %s" % GameState.get_owner_name(system_summary.get("ownerId", null))
				]))
		var treaties: Array = GameState.world_data.get("treaties", [])
		if not treaties.is_empty():
			drawer_content.add_child(_make_section_title("条约状态"))
			for treaty_summary: Dictionary in treaties:
				drawer_content.add_child(_make_info_card([
					"%s · %s" % [treaty_summary.get("type", "UNKNOWN"), treaty_summary.get("status", "UNKNOWN")],
					"对象: %s" % GameState.get_owner_name(treaty_summary.get("counterpart", ""))
				]))
		var queue_summary: Array = GameState.world_data.get("queue", [])
		if not queue_summary.is_empty():
			drawer_content.add_child(_make_section_title("建造摘要"))
			for queue_item: Dictionary in queue_summary:
				drawer_content.add_child(_make_info_card([
					"%s · 剩余 %s 回合" % [queue_item.get("displayName", ""), str(queue_item.get("turnsRemaining", 0))],
					"所在星系: %s" % GameState.get_system_by_id(queue_item.get("systemId", "")).get("name", queue_item.get("systemId", ""))
				]))
		var backend_posture: Dictionary = GameState.world_data.get("strategic_posture", {})
		if not backend_posture.is_empty():
			drawer_content.add_child(_make_section_title("??????"))
			drawer_content.add_child(_make_info_card([
				"????: %s" % (", ".join(backend_posture.get("flashpoints", [])) if not backend_posture.get("flashpoints", []).is_empty() else "??"),
				"????: %s" % (", ".join(backend_posture.get("high_opportunity", [])) if not backend_posture.get("high_opportunity", []).is_empty() else "??"),
				"????: %s" % (", ".join(backend_posture.get("deteriorating", [])) if not backend_posture.get("deteriorating", []).is_empty() else "??"),
				"????: %s" % str(backend_posture.get("recommended_posture", "CONSOLIDATE"))
			]))
		var backend_feed: Array = GameState.world_data.get("intelligence_feed", [])
		if not backend_feed.is_empty():
			drawer_content.add_child(_make_section_title("?????"))
			for item: Dictionary in backend_feed.slice(0, min(6, backend_feed.size())):
				drawer_content.add_child(_make_info_card([
					"T%s / %s / %s" % [str(item.get("turn", 0)), str(item.get("category", "INFO")), str(item.get("title", "??"))],
					str(item.get("summary", ""))
				]))
		var proposal_summary: Array = GameState.world_data.get("pending_proposals", [])
		if not proposal_summary.is_empty():
			drawer_content.add_child(_make_section_title("待处理外交提案"))
			for proposal: Dictionary in proposal_summary:
				drawer_content.add_child(_make_info_card([
					proposal.get("title", "外交提案"),
					"类型: %s / 状态: %s" % [str(proposal.get("proposalType", "UNKNOWN")), str(proposal.get("status", "PENDING"))],
					"到期回合: T%s" % str(proposal.get("expiresOnTurn", 0))
				]))
		var memory_summary: Array = GameState.world_data.get("diplomatic_memories", [])
		if not memory_summary.is_empty():
			drawer_content.add_child(_make_section_title("近期外交记忆"))
			for memory: Dictionary in memory_summary:
				drawer_content.add_child(_make_info_card([
					"T%s · %s" % [str(memory.get("turn", 0)), str(memory.get("title", "外交记忆"))],
					"类别: %s / 重要度: %s" % [str(memory.get("category", "EVENT")), str(memory.get("importance", 1))]
				]))
		var world_state_report: Dictionary = GameState.world_data.get("world_state_report", {})
		if not world_state_report.is_empty():
			var statistics: Dictionary = world_state_report.get("statistics", {})
			var state_posture: Dictionary = world_state_report.get("strategic_posture", {})
			drawer_content.add_child(_make_section_title("全局态势"))
			drawer_content.add_child(_make_info_card([
				"平衡评估: %s" % str(world_state_report.get("balance_assessment", "UNKNOWN")),
				"势力数: %s / 舰队数: %s" % [str(statistics.get("faction_count", 0)), str(statistics.get("fleet_count", 0))],
				"平均军力: %s / 战争数: %s" % [str(statistics.get("average_military_power", 0)), str(statistics.get("war_count", 0))],
				"可见星系: %s / 无主星系: %s" % [str(statistics.get("visible_system_count", 0)), str(statistics.get("unowned_system_count", 0))],
				"????: %s" % str(state_posture.get("recommended_posture", "CONSOLIDATE"))
			]))
		var fleet_status_report: Dictionary = GameState.world_data.get("fleet_status_report", {})
		if not fleet_status_report.is_empty():
			drawer_content.add_child(_make_section_title("舰队状态回报"))
			drawer_content.add_child(_make_info_card([
				"位置: %s" % str(fleet_status_report.get("location", "未知")),
				"任务: %s" % str(fleet_status_report.get("mission", "未知")),
				"战力: %s / 战备: %s" % [str(fleet_status_report.get("strength", 0)), str(fleet_status_report.get("readiness", "UNKNOWN"))]
			]))
			for unit: Dictionary in fleet_status_report.get("unit_composition", []):
				drawer_content.add_child(_make_info_card([
					"%s · %s" % [str(unit.get("name", "舰船")), str(unit.get("type", "UNKNOWN"))],
					"HP %s/%s · 伤害 %s" % [str(unit.get("hp", 0)), str(unit.get("maxHp", 0)), str(unit.get("damage", 0))]
				]))
		var tactical_report: Dictionary = GameState.world_data.get("tactical_report", {})
		if not tactical_report.is_empty():
			drawer_content.add_child(_make_section_title("战术建议"))
			drawer_content.add_child(_make_info_card([
				"推荐战术: %s" % str(tactical_report.get("recommended_tactics", "LINE"))
			]))
			for line: String in tactical_report.get("expected_outcomes", []):
				drawer_content.add_child(_make_info_card([line]))
			for line: String in tactical_report.get("risk_assessments", []):
				drawer_content.add_child(_make_info_card(["风险: %s" % line]))
			if not GameState.get_enemy_fleet_for_selected_context().is_empty():
				drawer_content.add_child(_make_action_button("执行战斗协议", GameState.execute_selected_combat_protocol))
		var director_report: Dictionary = GameState.world_data.get("director_event_report", {})
		if not director_report.is_empty():
			drawer_content.add_child(_make_section_title("导演事件预览"))
			drawer_content.add_child(_make_info_card([
				str(director_report.get("event_id", "事件")),
				str(director_report.get("narrative_content", ""))
			]))
			drawer_content.add_child(_make_action_button("应用该事件", GameState.apply_director_event_to_world.bind(_event_template_from_preview(str(director_report.get("event_id", ""))))))
			for effect: String in director_report.get("immediate_effects", []):
				drawer_content.add_child(_make_info_card(["即时效果: %s" % effect]))
			for option: String in director_report.get("follow_up_options", []):
				drawer_content.add_child(_make_info_card(["后续选项: %s" % option]))
		var intervention_report: Dictionary = GameState.world_data.get("director_intervention_report", {})
		if not intervention_report.is_empty():
			drawer_content.add_child(_make_section_title("导演干预预览"))
			drawer_content.add_child(_make_info_card([
				str(intervention_report.get("intervention_id", "director_preview")),
				"玩家感知: %s" % str(intervention_report.get("player_perception", "SUBTLE"))
			]))
			drawer_content.add_child(_make_action_button("应用该干预", GameState.apply_director_intervention_to_world.bind(_intervention_type_from_preview(str(intervention_report.get("intervention_id", ""))))))
			for effect: String in intervention_report.get("effects_summary", []):
				drawer_content.add_child(_make_info_card(["干预效果: %s" % effect]))
		var resource_report: Dictionary = GameState.world_data.get("resource_status_report", {})
		if not resource_report.is_empty():
			drawer_content.add_child(_make_section_title("资源诊断"))
			drawer_content.add_child(_make_info_card([
				"食物: %s (%s)" % [str(resource_report.get("food", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("food", {}).get("net", 0)))],
				"矿产: %s (%s)" % [str(resource_report.get("minerals", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("minerals", {}).get("net", 0)))],
				"工业: %s (%s)" % [str(resource_report.get("industry", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("industry", {}).get("net", 0)))],
				"能源: %s (%s)" % [str(resource_report.get("energy", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("energy", {}).get("net", 0)))]
			]))
			for warning: String in resource_report.get("balance_warning", []):
				drawer_content.add_child(_make_info_card(["警告: %s" % warning]))
		var combat_report: Dictionary = GameState.world_data.get("combat_protocol_report", {})
		if not combat_report.is_empty():
			drawer_content.add_child(_make_section_title("战斗预判"))
			drawer_content.add_child(_make_info_card([
				"状态: %s" % str(combat_report.get("status", "UNKNOWN")),
				"预估胜利: %s" % ("是" if combat_report.get("victory", false) else "否"),
				"预计损失舰船: %s / 击毁敌舰: %s" % [str(combat_report.get("casualties", 0)), str(combat_report.get("kills", 0))],
				"剩余战力: %s%%" % str(combat_report.get("remaining_power", 0))
			]))
			for note: String in combat_report.get("tactical_notes", []):
				drawer_content.add_child(_make_info_card(["战术备注: %s" % note]))

func _build_system_panel(system: Dictionary) -> void:
	var queue_items: Array = []
	for item: Dictionary in GameState.game_state.get("constructionQueue", []):
		if item.get("systemId", "") == system.get("id", ""):
			queue_items.append(item)

	drawer_content.add_child(_make_section_title(system.get("name", "")))
	drawer_content.add_child(_make_info_card([
		"归属: %s" % GameState.get_owner_name(system.get("ownerId", null)),
		system.get("note", ""),
		"资源: %s" % _resource_line(system.get("resources", {})),
		"建筑格位: %s/%s" % [str(system.get("buildings", []).size() + queue_items.size()), str(system.get("buildingSlots", 0))],
		"宜居度: %s" % str(system.get("habitability", 0))
	]))
	if system.get("colonyStage", "NONE") != "NONE":
		drawer_content.add_child(_make_info_card([
			"殖民阶段: %s" % _colony_stage_name(system.get("colonyStage", "NONE")),
			"殖民模式: %s" % InitialData.colonization_modes().get(system.get("colonizationMode", ""), {}).get("name", system.get("colonizationMode", "无")),
			"成长进度: %s%%" % str(int(round(float(system.get("colonizationProgress", 0.0))))),
			"剩余回合: %s" % str(system.get("colonizationTurnsRemaining", 0)),
			"稳定度: %s" % str(system.get("stability", 0)),
			"补给水平: %s" % str(system.get("supplyLevel", 0)),
			"风险等级: %s" % str(system.get("colonizationRisk", "无"))
		]))
	if system.get("eventResolved", true) == false:
		drawer_content.add_child(_make_info_card([
			"异常信号: %s" % str(system.get("eventType", "未知事件")),
			"舰队靠近后可进一步处理该事件。"
		]))

	if not system.get("buildings", []).is_empty():
		drawer_content.add_child(_make_section_title("当前建筑"))
		for item: Dictionary in system.get("buildings", []):
			drawer_content.add_child(_make_info_card(["%s" % item.get("name", "")]))

	if not queue_items.is_empty():
		drawer_content.add_child(_make_section_title("建造队列"))
		for item: Dictionary in queue_items:
			drawer_content.add_child(_make_info_card(["%s · 剩余 %s 回合" % [item.get("displayName", ""), str(item.get("turnsRemaining", 0))]]))

	if system.get("ownerId", null) == GameState.PLAYER_FACTION_ID:
		drawer_content.add_child(_make_section_title("可建造建筑"))
		for building: Dictionary in GameState.available_buildings():
			drawer_content.add_child(_make_building_card(building))
			drawer_content.add_child(_make_action_button("加入建造队列", GameState.queue_structure.bind(system.get("id", ""), building.get("type", ""))))

		var has_shipyard: bool = false
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "SHIPYARD":
				has_shipyard = true
		if has_shipyard:
			drawer_content.add_child(_make_section_title("船坞生产"))
			for ship_type: String in GameState.available_ship_types():
				var cost: Dictionary = GameLogic.ship_cost(ship_type, GameState.game_state, GameState.PLAYER_FACTION_ID)
				drawer_content.add_child(_make_info_card([
					"%s" % InitialData.ship_labels().get(ship_type, ship_type),
					"消耗: %s" % _resource_line(cost)
				]))
				drawer_content.add_child(_make_action_button("排队%s" % InitialData.ship_labels().get(ship_type, ship_type), GameState.queue_ship.bind(system.get("id", ""), ship_type)))

	var system_actions: HBoxContainer = _action_row()
	if GameState.selected_fleet_id != "":
		system_actions.add_child(_make_action_button("探索", GameState.explore_system.bind(system.get("id", ""))))
		if GameState.get_reachable_system_ids(GameState.selected_fleet_id).has(system.get("id", "")):
			system_actions.add_child(_make_action_button("跃迁至此", GameState.move_selected_fleet.bind(system.get("id", ""))))
	if system_actions.get_child_count() > 0:
		drawer_content.add_child(system_actions)
	if GameState.selected_fleet_id != "" and system.get("colonyStage", "NONE") == "NONE":
		drawer_content.add_child(_make_section_title("殖民方案"))
		for mode_key: String in GameState.colonization_modes().keys():
			var mode_data: Dictionary = GameState.colonization_modes().get(mode_key, {})
			var preview: Dictionary = GameState.colonization_preview(system.get("id", ""), mode_key)
			drawer_content.add_child(_make_info_card([
				"%s · %s 回合" % [mode_data.get("name", mode_key), str(preview.get("turns", mode_data.get("turns", 0)))],
				mode_data.get("description", ""),
				"消耗: %s" % _resource_line(preview.get("cost", mode_data.get("cost", {}))),
				"初始人口: %s" % str(mode_data.get("initial_population", 0)),
				"初始稳定度: %s" % str(mode_data.get("initial_stability", 0)),
				"风险等级: %s" % str(mode_data.get("risk", "未知")),
				"状态: %s" % str(preview.get("reason", ""))
			]))
			var colonize_button: Button = _make_action_button("发起%s" % mode_data.get("name", mode_key), GameState.colonize_system.bind(system.get("id", ""), mode_key))
			colonize_button.disabled = not preview.get("allowed", false)
			drawer_content.add_child(colonize_button)

func _build_fleet_panel(fleet: Dictionary) -> void:
	var total_hp: int = 0
	var total_max_hp: int = 0
	var total_damage: int = 0
	for ship: Dictionary in fleet.get("ships", []):
		total_hp += int(ship.get("hp", 0))
		total_max_hp += int(ship.get("maxHp", 0))
		total_damage += int(ship.get("damage", 0))

	drawer_content.add_child(_make_section_title(fleet.get("name", "")))
	drawer_content.add_child(_make_info_card([
		"驻留星系: %s" % GameState.get_system_by_id(fleet.get("systemId", "")).get("name", ""),
		"完整度: %s/%s" % [str(total_hp), str(total_max_hp)],
		"舰队战力: %s" % str(total_damage)
	]))

	for ship: Dictionary in fleet.get("ships", []):
		drawer_content.add_child(_make_info_card([
			"%s · %s" % [ship.get("name", ""), InitialData.ship_labels().get(ship.get("type", ""), ship.get("type", ""))],
			"HP %s/%s · 伤害 %s" % [str(ship.get("hp", 0)), str(ship.get("maxHp", 0)), str(ship.get("damage", 0))]
		]))

	drawer_content.add_child(_make_section_title("可达星系"))
	for system_id: String in GameState.get_reachable_system_ids(fleet.get("id", "")):
		var system: Dictionary = GameState.get_system_by_id(system_id)
		var row: HBoxContainer = _action_row()
		row.add_child(_make_action_button(system.get("name", system_id), GameState.select_system.bind(system_id)))
		row.add_child(_make_action_button("跃迁", GameState.move_selected_fleet.bind(system_id)))
		if system.get("visibilityLevel", "") != "FULL":
			row.add_child(_make_action_button("探索", GameState.explore_system.bind(system_id)))
		drawer_content.add_child(row)

	var enemy_fleet: Dictionary = GameState.get_enemy_fleet_for_selected_context()
	if not enemy_fleet.is_empty():
		drawer_content.add_child(_make_section_title("交战目标"))
		drawer_content.add_child(_make_info_card([
			"%s" % enemy_fleet.get("name", "敌方舰队"),
			"归属: %s" % GameState.get_owner_name(enemy_fleet.get("ownerId", "")),
			"所在星系: %s" % GameState.get_system_by_id(enemy_fleet.get("systemId", "")).get("name", enemy_fleet.get("systemId", ""))
		]))
		var combat_row: HBoxContainer = _action_row()
		combat_row.add_child(_make_action_button("战斗预判", GameState.request_combat_preview))
		combat_row.add_child(_make_action_button("全力突击", GameState.execute_selected_combat_protocol.bind("ALL_OUT", "WEDGE")))
		combat_row.add_child(_make_action_button("游击脱离", GameState.execute_selected_combat_protocol.bind("HIT_AND_RUN", "LINE")))
		combat_row.add_child(_make_action_button("防御交战", GameState.execute_selected_combat_protocol.bind("DEFENSIVE", "SPHERE")))
		drawer_content.add_child(combat_row)

	drawer_content.add_child(_make_action_button("整备舰队", GameState.repair_fleet.bind(fleet.get("id", ""))))

func _make_chip(title: String, value: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 56)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.08, 0.13, 0.88), Color("516089"), 14))
	var box: VBoxContainer = VBoxContainer.new()
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color("AAB6D3"))
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color("F5F7FF"))
	box.add_child(title_label)
	box.add_child(value_label)
	panel.add_child(box)
	return panel

func _make_resource_chip(title: String, value: int, rate: int) -> PanelContainer:
	var panel: PanelContainer = _make_chip(title, str(value))
	var rate_label: Label = Label.new()
	rate_label.text = "%s%s" % ["+" if rate >= 0 else "", str(rate)]
	rate_label.add_theme_color_override("font_color", Color("93E1C0") if rate >= 0 else Color("F38BA8"))
	panel.get_child(0).add_child(rate_label)
	return panel

func _make_section_title(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("F5F7FF"))
	return label

func _make_headline(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("F5F7FF"))
	return label

func _make_body_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("D3DAED"))
	return label

func _make_action_button(text: String, callable: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_stylebox_override("normal", _button_style(Color(0.13, 0.17, 0.28, 0.96), Color("6B7CAF"), 12))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.19, 0.24, 0.38, 0.98), Color("9DB1FF"), 12))
	button.add_theme_stylebox_override("pressed", _button_style(Color("C8B7FF"), Color("C8B7FF"), 12))
	button.add_theme_color_override("font_color", Color("F5F7FF"))
	button.add_theme_color_override("font_pressed_color", Color("0B0C15"))
	button.pressed.connect(callable)
	return button

func _make_info_card(lines: Array) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.16, 0.92), Color("425073"), 16))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for line: String in lines:
		box.add_child(_make_body_label(line))
	panel.add_child(box)
	return panel

func _make_building_card(building: Dictionary) -> PanelContainer:
	return _make_info_card([
		"%s · %s 回合" % [building.get("name", ""), str(InitialData.building_turns().get(building.get("type", ""), 1))],
		building.get("description", ""),
		"建造消耗: %s" % _resource_line(building.get("cost", {})),
		"建筑产出: %s" % _resource_line(building.get("production", {}), true),
		"维护费用: %s" % _resource_line(building.get("maintenance", {})),
		"额外住房: %s" % str(building.get("housing", 0))
	])

func _make_tech_card(tech: Dictionary, researching: bool) -> PanelContainer:
	var lines: Array = [
		"%s · T%s · %s" % [tech.get("name", ""), str(tech.get("tier", 1)), tech.get("category", "")],
		tech.get("description", ""),
		"研究时间 %s 回合 / 花费 %s 工业" % [str(tech.get("researchTime", 0)), str(tech.get("cost", 0))]
	]
	if researching:
		lines.append("当前进度 %.0f%%" % float(tech.get("progress", 0.0)))
	for effect: String in tech.get("effects", []):
		lines.append("加成: %s" % effect)
	for unlock_name: String in tech.get("unlocks", []):
		lines.append("解锁: %s" % unlock_name)
	return _make_info_card(lines)

func _action_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	return row

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
		names.append(InitialData.treaty_labels().get(treaty.get("type", ""), treaty.get("type", "")))
	return ", ".join(names)

func _colony_stage_name(stage: String) -> String:
	match stage:
		"OUTPOST":
			return "殖民前哨"
		"COLONY":
			return "正式殖民地"
		"CORE":
			return "核心世界"
		_:
			return "未殖民"

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

func _on_state_changed(_state: Dictionary) -> void:
	refresh()

func _on_selection_changed(_system_id: String, _fleet_id: String) -> void:
	refresh()

func _on_tab_changed(_tab_name: String) -> void:
	refresh()

func _on_labels_visibility_changed(_visible: bool) -> void:
	refresh()

func _on_backend_status_changed(_status: String) -> void:
	refresh()

func _on_advisor_changed(_ai_advice: String, _world_data: Dictionary, _diplomatic_message: Dictionary) -> void:
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
	if GameState.active_tab == "DIPLOMACY":
		refresh()
