extends CanvasLayer

const TAB_NAMES: Array = ["OBJECTIVES", "TECH", "DIPLOMACY", "ADVISOR"]
const TAB_LABELS: Dictionary = {
	"OBJECTIVES": "閹存ê鐪?,
	"TECH": "缁夋垶濡?,
	"DIPLOMACY": "婢舵牔姘?,
	"ADVISOR": "妞ら箖妫?
}

const RESOURCE_NAMES: Dictionary = {
	"food": "妞嬬喓澧?,
	"minerals": "閻じ楠?,
	"industry": "瀹搞儰绗?,
	"energy": "閼宠姤绨?
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
	next_turn_button.text = "閺佸本鏌熼崘宕囩摜娑?.." if GameState.turn_busy else "閹恒劏绻樻稉瀣╃閸ョ偛鎮?
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
	top_bar.add_child(_make_chip("閸ョ偛鎮?, str(GameState.game_state.get("turn", 1))))
	top_bar.add_child(_make_chip("閺冩湹鍞?, _era_name(GameState.game_state.get("era", "PIONEER"))))
	top_bar.add_child(_make_resource_chip("妞嬬喓澧?, int(resources.get("food", 0)), int(rates.get("food", 0))))
	top_bar.add_child(_make_resource_chip("閻じ楠?, int(resources.get("minerals", 0)), int(rates.get("minerals", 0))))
	top_bar.add_child(_make_resource_chip("瀹搞儰绗?, int(resources.get("industry", 0)), int(rates.get("industry", 0))))
	top_bar.add_child(_make_resource_chip("閼宠姤绨?, int(resources.get("energy", 0)), int(rates.get("energy", 0))))
	var labels_button: Button = _make_action_button("閸︽澘娴橀弬鍥х摟: %s" % ("瀹稿弶妯夌粈? if GameState.labels_visible else "瀹告煡娈ｉ挊?), GameState.toggle_labels)
	labels_button.custom_minimum_size = Vector2(160, 56)
	top_bar.add_child(labels_button)

func _rebuild_drawer() -> void:
	for child: Node in drawer_content.get_children():
		child.queue_free()

	var selected_fleet: Dictionary = GameState.get_fleet_by_id(GameState.selected_fleet_id)
	var selected_system: Dictionary = GameState.get_system_by_id(GameState.selected_system_id)

	if not selected_fleet.is_empty():
		drawer_title.text = "閼镐即妲﹂幐鍥ㄥ皩"
		drawer_subtitle.text = "瑜版挸澧犳稉楦垮煂闂冪喐鎼锋担婊€绗傛稉瀣瀮"
		_build_fleet_panel(selected_fleet)
	elif not selected_system.is_empty():
		drawer_title.text = "閺勭喓閮村楦款啎"
		drawer_subtitle.text = "瑜版挸澧犳稉鐑樻Е缁缂撶拋鍙ョ瑐娑撳鏋?
		_build_system_panel(selected_system)
	else:
		drawer_title.text = TAB_LABELS.get(GameState.active_tab, "閹槒顫?)
		drawer_subtitle.text = "闁俺绻冩惔鏇㈠劥鐎佃壈鍩呴崚鍥ㄥ床缁崵绮洪棃銏℃緲"
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
	drawer_content.add_child(_make_section_title("閹存ê鐪惄顔界垼"))
	drawer_content.add_child(_make_info_card([
		"閻╊喗鐖? %s" % str(GameState.game_state.get("objective", "")),
		"閻樿埖鈧? %s" % str(GameState.game_state.get("status", "PLAYING")),
		"妞嬬偛宕屾潻娑樺: %s/100" % str(GameState.game_state.get("ascension_progress", 0)),
		"閼虫粌鍩勭捄顖氱窞: %s" % str(GameState.game_state.get("victory_path", "閺堫亣鎻幋?))
	]))
	var active_events: Array = GameState.get_active_narrative_events()
	if not active_events.is_empty():
		drawer_content.add_child(_make_section_title("瀵板懎顦╅悶鍡曠皑娴?))
		for event_item: Dictionary in active_events.slice(0, min(4, active_events.size())):
			drawer_content.add_child(_make_info_card([
				"%s 璺?%s" % [str(event_item.get("title", "娴滃娆?)), GameState.get_system_by_id(event_item.get("systemId", "")).get("name", event_item.get("systemId", ""))],
				"娴滃娆㈤柧楣冩▉濞? %s" % str(event_item.get("chainStage", 1)),
				str(event_item.get("summary", "")),
			]))
			var options_row: HBoxContainer = _action_row()
			for option: String in event_item.get("followUpOptions", []):
				options_row.add_child(_make_action_button(option, GameState.resolve_narrative_event.bind(event_item.get("id", ""), option)))
			drawer_content.add_child(options_row)
	var interventions: Array = GameState.get_active_interventions()
	if not interventions.is_empty():
		drawer_content.add_child(_make_section_title("閹镐胶鐢婚獮鏌ヮ暕"))
		for item: Dictionary in interventions.slice(0, min(4, interventions.size())):
			drawer_content.add_child(_make_info_card([
				"%s" % str(item.get("type", "INTERVENTION")),
				"閸撯晙缍戦崶鐐叉値: %s / 瀵搫瀹? %s" % [str(item.get("remainingTurns", 0)), str(item.get("intensity", 0.0))]
			]))
	var messages: Array = GameState.game_state.get("messages", [])
	if not messages.is_empty():
		drawer_content.add_child(_make_section_title("閺堚偓閺傜増鍎忛幎?))
		for message: Dictionary in messages.slice(0, min(6, messages.size())):
			drawer_content.add_child(_make_info_card([
				"T%s 璺?%s" % [str(message.get("turn", 1)), message.get("title", "")],
				message.get("content", "")
			]))
	var combat_reports: Array = GameState.get_recent_combat_reports()
	if not combat_reports.is_empty():
		drawer_content.add_child(_make_section_title("鏉╂垶婀￠幋妯诲Г"))
		for report: Dictionary in combat_reports.slice(0, min(3, combat_reports.size())):
			drawer_content.add_child(_make_info_card([
				"T%s 璺?%s" % [str(report.get("turn", 1)), str(report.get("title", "閹存ɑ鏋熼幎銉ユ啞"))],
				"%s vs %s" % [str(report.get("attackerName", "鏉╂稒鏁鹃弬?)), str(report.get("defenderName", "闂冩彃灏介弬?))],
				"缂佹挻鐏? %s / 閹圭喎銇? %s / 閸戠粯鐦? %s / 閸撯晙缍戦幋妯哄: %s%%" % [
					"閼虫粌鍩? if report.get("victory", false) else "婢跺崬鍩?,
					str(report.get("casualties", 0)),
					str(report.get("kills", 0)),
					str(report.get("remainingPower", 0))
				],
				"閹存ɑ婀? %s" % " / ".join(report.get("tacticalNotes", []))
			]))
	drawer_content.add_child(_make_action_button("闁插秵鏌婂鈧仦鈧?, GameState.reset_state))

func _build_tech_panel() -> void:
	drawer_content.add_child(_make_section_title("缁夋垶濡ч惍鏃傗敀"))
	var current_research_id: Variant = GameState.game_state.get("currentResearchId", null)
	if current_research_id != null:
		for tech: Dictionary in GameState.game_state.get("technologies", []):
			if tech.get("id", "") == str(current_research_id):
				drawer_content.add_child(_make_tech_card(tech, true))
				drawer_content.add_child(_make_action_button("閸欐牗绉疯ぐ鎾冲閻梻鈹?, GameState.cancel_research))
				break
	for tech: Dictionary in GameState.game_state.get("technologies", []):
		if tech.get("status", "") != "AVAILABLE":
			continue
		drawer_content.add_child(_make_tech_card(tech, false))
		var button: Button = _make_action_button("瀵偓婵鐖虹粚?, GameState.start_research.bind(tech.get("id", "")))
		button.disabled = current_research_id != null
		drawer_content.add_child(button)

func _build_diplomacy_panel() -> void:
	drawer_content.add_child(_make_section_title("婢舵牔姘﹂崗宕囬兇"))
	var interception_report: Dictionary = GameState.get_interception_report()
	var diplomacy_report: Dictionary = GameState.get_diplomatic_victory_report()
	drawer_content.add_child(_make_info_card([
		"閹懏濮ら惄鎴濇儔: %s" % interception_report.get("status", "閸╄櫣顢呴惄鎴濇儔"),
		"閸╄櫣顢呴幋顏囧箯閻? %s%%" % str(interception_report.get("base", 0)),
		"閸欐妾洪柅姘愁唵閹搭亣骞忛悳? %s%%" % str(interception_report.get("restricted", 0)),
		"缁夋ê鐦戦柅姘愁唵閹搭亣骞忛悳? %s%%" % str(interception_report.get("secret", 0)),
		"閸旂姴鐦戦柅姘愁唵閹搭亣骞忛悳? %s%%" % str(interception_report.get("encrypted", 0))
	]))
	drawer_content.add_child(_make_info_card([
		"婢舵牔姘﹂懗婊冨焺鏉╂稑瀹?,
		"閸氬瞼娲? %s" % str(diplomacy_report.get("alliances", 0)),
		"缁夋垹鐖洪崡蹇撶暰: %s/%s" % [str(diplomacy_report.get("accords", 0)), str(diplomacy_report.get("total_rivals", 0))],
		"閸滃苯閽╅崗宕囬兇: %s/%s" % [str(diplomacy_report.get("peace_partners", 0)), str(diplomacy_report.get("total_rivals", 0))],
		"閹存ü绨ら悩鑸碘偓? %s" % str(diplomacy_report.get("wars", 0))
	]))
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogic.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		var active_treaties: Array = GameLogic.active_treaties_between(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		drawer_content.add_child(_make_info_card([
			"%s 璺?%s" % [faction.get("name", ""), faction.get("leaderName", "")],
			"閸忓磭閮寸粵澶岄獓: %s" % relation.get("level", "UNKNOWN"),
			"娣団€叉崲: %s / 閸掆晝鏁ゆ禒宄扳偓? %s" % [str(relation.get("trust", 0)), str(relation.get("utility", 0))],
			"韫囧本鍎? %s / 婵傝姤鍔? %s / 鐠佹澘绻傝ぐ鍗炴惙: %s" % [str(relation.get("fear", 0)), str(relation.get("affinity", 0)), str(relation.get("memoryImpact", 0))],
			"閻滄媽顢戦弶锛勫: %s" % _treaty_names_text(active_treaties),
			"婢舵牔姘︽禍楦款啎: %s" % faction.get("diplomaticProfile", {}).get("publicPersona", "閺嗗倹妫?),
			"閺堚偓鏉╂垼顕㈠? %s" % faction.get("diplomaticProfile", {}).get("recentTone", "neutral")
		]))
		var history: Array = GameState.get_relation_history(faction.get("id", ""))
		if not history.is_empty():
			var trend_parts: Array = []
			for snapshot: Dictionary in history:
				trend_parts.append("T%s:%s/%s/%s" % [str(snapshot.get("turn", 0)), str(snapshot.get("trust", 0)), str(snapshot.get("fear", 0)), str(snapshot.get("memoryImpact", 0))])
			drawer_content.add_child(_make_info_card([
				"鐡掑濞嶆潻鍊熼嚋",
				"娣団€叉崲/韫囧本鍎?鐠佹澘绻? %s" % " -> ".join(trend_parts)
			]))
		var row_one: HBoxContainer = _action_row()
		row_one.add_child(_make_action_button("鐠愬憡妲?, GameState.trade_with_faction.bind(faction.get("id", ""))))
		row_one.add_child(_make_action_button("鐠€锕€鎲?, _threat_and_request.bind(faction.get("id", ""))))
		row_one.add_child(_make_action_button("閼锋潙鍤?, GameState.request_diplomatic_message.bind(faction.get("id", ""), "friendly")))
		drawer_content.add_child(row_one)
		var row_two: HBoxContainer = _action_row()
		row_two.add_child(_make_action_button("娴滄帊绗夋笟鐢靛П", GameState.propose_treaty.bind(faction.get("id", ""), "NON_AGGRESSION")))
		row_two.add_child(_make_action_button("缁夋垹鐖洪崡蹇撶暰", GameState.propose_treaty.bind(faction.get("id", ""), "RESEARCH_ACCORD")))
		row_two.add_child(_make_action_button("閸氬瞼娲?, GameState.propose_treaty.bind(faction.get("id", ""), "ALLIANCE")))
		drawer_content.add_child(row_two)
		var row_three: HBoxContainer = _action_row()
		row_three.add_child(_make_action_button("鎼寸喐顒涙禍鎺嶇瑝娓氱數濮?, GameState.revoke_treaty.bind(faction.get("id", ""), "NON_AGGRESSION")))
		row_three.add_child(_make_action_button("鎼寸喐顒涚粔鎴犵埡閸楀繐鐣?, GameState.revoke_treaty.bind(faction.get("id", ""), "RESEARCH_ACCORD")))
		row_three.add_child(_make_action_button("濮濓絽绱＄€癸絾鍨?, GameState.declare_war.bind(faction.get("id", ""))))
		drawer_content.add_child(row_three)
		drawer_content.add_child(_make_section_title("閼奉亞鏁辨禍銈嗙ウ"))
		var draft_box: TextEdit = TextEdit.new()
		draft_box.custom_minimum_size = Vector2(0, 96)
		draft_box.placeholder_text = "鏉堟挸鍙嗘担鐘冲厒鐎电顕?AI 鐠囧娈戠拠婵撶礉娓氬顩ч敍姘灉閹版寧鍓板鈧弨鎹愮珶婢у啳閿ら弰鎿勭礉娴ｅ棜顩﹀Ч鍌欑稑閸嬫粍顒涢崷銊ュ閺嬩焦妲﹂梽鍕箮闂嗗棛绮ㄩ懜浼存Е閵?
		draft_box.text = GameState.get_diplomatic_draft(faction.get("id", ""))
		draft_box.text_changed.connect(_on_draft_text_changed.bind(draft_box, faction.get("id", "")))
		drawer_content.add_child(draft_box)
		var intent_preview: Dictionary = GameState.get_diplomatic_intent_preview(faction.get("id", ""))
		drawer_content.add_child(_make_info_card([
			"閹板繐娴樻０鍕潔: %s" % intent_preview.get("label", "娑撯偓閼割兛姘﹀ù?),
			intent_preview.get("detail", ""),
			"妫板嫪鍙婇崗宕囬兇閸欐ê瀵? %s%s" % ["+" if int(intent_preview.get("trust_delta", 0)) >= 0 else "", str(intent_preview.get("trust_delta", 0))]
		]))
		drawer_content.add_child(_make_info_card([
			"鏉堟挸鍙嗛幓鎰仛: 閺傚洦婀伴柌灞藉毉閻滄壋鈧粈绨版稉宥勯暅閻?/ 缁夋垹鐖洪崡蹇撶暰 / 閸氬瞼娲?/ 鐠愬憡妲?/ 鐠€锕€鎲￠垾婵堢搼閸忔娊鏁拠宥嗘閿涘奔绱扮悮顐ら兇缂佺喕袙閺嬫劖鍨氶弴瀛樻绾喚娈戞径鏍︽唉閹板繐娴橀妴?
		]))
		var compose_row: HBoxContainer = _action_row()
		var visibility_selector: OptionButton = OptionButton.new()
		visibility_selector.add_item("閸忣剙绱?, 0)
		visibility_selector.add_item("閸欐妾?, 1)
		visibility_selector.add_item("缁夋ê鐦?, 2)
		visibility_selector.add_item("閸旂姴鐦?, 3)
		var current_visibility: String = GameState.get_diplomatic_visibility(faction.get("id", ""))
		visibility_selector.selected = 0 if current_visibility == "PUBLIC" else 1 if current_visibility == "RESTRICTED" else 2 if current_visibility == "SECRET" else 3
		visibility_selector.item_selected.connect(_on_visibility_selected.bind(faction.get("id", "")))
		compose_row.add_child(visibility_selector)
		compose_row.add_child(_make_action_button("閸欐垿鈧浇鍤滈悽杈ㄦ降閸?, GameState.send_player_message.bind(faction.get("id", ""))))
		drawer_content.add_child(compose_row)

	drawer_content.add_child(_make_section_title("闁俺顔嗘稉顓炵妇"))
	var visible_messages: Array = GameState.get_visible_diplomatic_messages()
	if visible_messages.is_empty():
		drawer_content.add_child(_make_info_card(["瑜版挸澧犻弳鍌涙￥閸欘垵顫嗘径鏍︽唉闁俺顔嗛妴?]))
	else:
		for message: Dictionary in visible_messages.slice(0, min(10, visible_messages.size())):
			var security: Dictionary = message.get("securitySettings", {})
			drawer_content.add_child(_make_info_card([
				"T%s 璺?%s" % [str(message.get("turn", 1)), message.get("title", "")],
				"閸欐垿鈧焦鏌? %s" % str(message.get("senderName", message.get("senderId", ""))),
				"閻╊喗鐖ｇ猾璇茬€? %s / 閸欘垵顫嗛幀? %s" % [str(message.get("targetType", "SINGLE")), str(message.get("visibilityLevel", "PUBLIC"))],
				"閸旂姴鐦戝鍝勫: %s / 閺冭埖鏅? %s 閸ョ偛鎮? % [str(security.get("encryptionLevel", 0)), str(security.get("expiresAfterTurns", 10))],
				message.get("content", "")
			]))

	drawer_content.add_child(_make_section_title("瀵板懎顦╅悶鍡樺絹濡?))
	var pending_proposals: Array = GameState.get_pending_proposals()
	if pending_proposals.is_empty():
		drawer_content.add_child(_make_info_card(["瑜版挸澧犲▽鈩冩箒缁涘绶熸担鐘差槱閻炲棛娈?AI 婢舵牔姘﹂幓鎰攳閵?]))
	else:
		for proposal: Dictionary in pending_proposals:
			drawer_content.add_child(_make_info_card([
				"%s" % proposal.get("title", "婢舵牔姘﹂幓鎰攳"),
				"閹绘劖顢嶇猾璇茬€? %s" % str(proposal.get("proposalType", "UNKNOWN")),
				"閸掔増婀￠崶鐐叉値: T%s" % str(proposal.get("expiresOnTurn", 0)),
				proposal.get("summary", "")
			]))
			var proposal_row: HBoxContainer = _action_row()
			proposal_row.add_child(_make_action_button("閹恒儱褰堥幓鎰攳", GameState.accept_diplomatic_proposal.bind(proposal.get("id", ""))))
			proposal_row.add_child(_make_action_button("閹锋帞绮烽幓鎰攳", GameState.reject_diplomatic_proposal.bind(proposal.get("id", ""))))
			drawer_content.add_child(proposal_row)

	drawer_content.add_child(_make_section_title("婢舵牔姘︾拋鏉跨箓"))
	var memories: Array = GameState.get_visible_diplomatic_memories()
	if memories.is_empty():
		drawer_content.add_child(_make_info_card(["瑜版挸澧犲▽鈩冩箒閸欘垰娲栭惇瀣畱婢舵牔姘︾拋鏉跨箓閵?]))
	else:
		for memory: Dictionary in memories.slice(0, min(8, memories.size())):
			drawer_content.add_child(_make_info_card([
				"T%s 璺?%s" % [str(memory.get("turn", 1)), memory.get("title", "")],
				"缁鍩? %s / 闁插秷顩︽惔? %s" % [str(memory.get("category", "EVENT")), str(memory.get("importance", 1))],
				memory.get("summary", "")
			]))

	if not GameState.diplomatic_message.is_empty():
		drawer_content.add_child(_make_section_title("婢舵牔姘﹂崙?))
		drawer_content.add_child(_make_info_card([
			GameState.diplomatic_message.get("title", ""),
			GameState.diplomatic_message.get("content", "")
		]))

func _build_advisor_panel() -> void:
	drawer_content.add_child(_make_section_title("AI 妞ら箖妫?))
	drawer_content.add_child(_make_info_card([
		"閸氬海顏悩鑸碘偓? %s" % GameState.backend_status,
		GameState.ai_advice if GameState.ai_advice != "" else "瑜版挸澧犻弳鍌涙￥ AI 瀵ら缚顔呴妴?
	]))
	drawer_content.add_child(_make_section_title("閸忓磭閮撮幀浣稿◢"))
	for faction: Dictionary in GameState.game_state.get("factions", []):
		if faction.get("isPlayer", false):
			continue
		var relation: Dictionary = GameLogic.relation_breakdown(GameState.game_state, GameState.PLAYER_FACTION_ID, faction.get("id", ""))
		drawer_content.add_child(_make_info_card([
			"%s" % faction.get("name", ""),
			"缁涘楠? %s / 娣団€叉崲: %s / 韫囧本鍎? %s" % [str(relation.get("level", "UNKNOWN")), str(relation.get("trust", 0)), str(relation.get("fear", 0))],
			"閸掆晝鏁ゆ禒宄扳偓? %s / 鐠佹澘绻傝ぐ鍗炴惙: %s" % [str(relation.get("utility", 0)), str(relation.get("memoryImpact", 0))]
		]))
	drawer_content.add_child(_make_section_title("缂佺厧鎮庨惍鏂垮灲"))
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
	actions.add_child(_make_action_button("鐠囬攱鐪?AI 瀵ら缚顔?, GameState.request_ai_advice))
	actions.add_child(_make_action_button("娑撴牜鏅弻銉嚄", GameState.request_world_query))
	drawer_content.add_child(actions)
	var scan_actions: HBoxContainer = _action_row()
	scan_actions.add_child(_make_action_button("閹礁濞嶉幍顐ｅ伎", GameState.request_world_state_scan))
	scan_actions.add_child(_make_action_button("閼镐即妲﹂悩鑸碘偓?, GameState.request_selected_fleet_status))
	scan_actions.add_child(_make_action_button("閹存ɑ婀崇拠鍕強", GameState.request_selected_tactical_approach))
	drawer_content.add_child(scan_actions)
	var analysis_actions: HBoxContainer = _action_row()
	analysis_actions.add_child(_make_action_button("鐠у嫭绨拠濠冩焽", GameState.request_resource_diagnosis))
	analysis_actions.add_child(_make_action_button("閹存ɑ鏋熸０鍕灲", GameState.request_combat_preview))
	drawer_content.add_child(analysis_actions)
	var director_actions: HBoxContainer = _action_row()
	director_actions.add_child(_make_action_button("闁鎶楁禍瀣╂", GameState.request_director_event_preview.bind("ANCIENT_RUINS_DISCOVERY")))
	director_actions.add_child(_make_action_button("濞撮娲嶇悮顓熷", GameState.request_director_event_preview.bind("PIRATE_RAID")))
	director_actions.add_child(_make_action_button("鐠哄啳绺兼搴㈡瘹", GameState.request_director_event_preview.bind("WARP_STORM")))
	drawer_content.add_child(director_actions)
	var intervention_actions: HBoxContainer = _action_row()
	intervention_actions.add_child(_make_action_button("濞撮娲嶉獮鏌ヮ暕", GameState.request_director_intervention_preview.bind("SPAWN_PIRATES")))
	intervention_actions.add_child(_make_action_button("AI瀵搫瀵?, GameState.request_director_intervention_preview.bind("BOOST_AI")))
	intervention_actions.add_child(_make_action_button("鐟欙箑褰傞崡杈ㄦ簚", GameState.request_director_intervention_preview.bind("TRIGGER_CRISIS")))
	drawer_content.add_child(intervention_actions)
	if not GameState.world_data.is_empty():
		drawer_content.add_child(_make_info_card([GameState.world_data.get("summary", "")]))
		var visible_systems: Array = GameState.world_data.get("visible_systems", [])
		if not visible_systems.is_empty():
			drawer_content.add_child(_make_section_title("瀹歌尙鐓￠弰鐔风厵"))
			for system_summary: Dictionary in visible_systems:
				drawer_content.add_child(_make_info_card([
					"%s 璺?娴犲嘲鈧?%s" % [system_summary.get("name", "閺堫亞鐓￠弰鐔洪兇"), str(system_summary.get("value", 0))],
					"瑜版帒鐫? %s" % GameState.get_owner_name(system_summary.get("ownerId", null))
				]))
		var treaties: Array = GameState.world_data.get("treaties", [])
		if not treaties.is_empty():
			drawer_content.add_child(_make_section_title("閺夛紕瀹抽悩鑸碘偓?))
			for treaty_summary: Dictionary in treaties:
				drawer_content.add_child(_make_info_card([
					"%s 璺?%s" % [treaty_summary.get("type", "UNKNOWN"), treaty_summary.get("status", "UNKNOWN")],
					"鐎电钖? %s" % GameState.get_owner_name(treaty_summary.get("counterpart", ""))
				]))
		var queue_summary: Array = GameState.world_data.get("queue", [])
		if not queue_summary.is_empty():
			drawer_content.add_child(_make_section_title("瀵ゆ椽鈧姵鎲崇憰?))
			for queue_item: Dictionary in queue_summary:
				drawer_content.add_child(_make_info_card([
					"%s 璺?閸撯晙缍?%s 閸ョ偛鎮? % [queue_item.get("displayName", ""), str(queue_item.get("turnsRemaining", 0))],
					"閹碘偓閸︺劍妲︾化? %s" % GameState.get_system_by_id(queue_item.get("systemId", "")).get("name", queue_item.get("systemId", ""))
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
			drawer_content.add_child(_make_section_title("瀵板懎顦╅悶鍡楊樆娴溿倖褰佸?))
			for proposal: Dictionary in proposal_summary:
				drawer_content.add_child(_make_info_card([
					proposal.get("title", "婢舵牔姘﹂幓鎰攳"),
					"缁鐎? %s / 閻樿埖鈧? %s" % [str(proposal.get("proposalType", "UNKNOWN")), str(proposal.get("status", "PENDING"))],
					"閸掔増婀￠崶鐐叉値: T%s" % str(proposal.get("expiresOnTurn", 0))
				]))
		var memory_summary: Array = GameState.world_data.get("diplomatic_memories", [])
		if not memory_summary.is_empty():
			drawer_content.add_child(_make_section_title("鏉╂垶婀℃径鏍︽唉鐠佹澘绻?))
			for memory: Dictionary in memory_summary:
				drawer_content.add_child(_make_info_card([
					"T%s 璺?%s" % [str(memory.get("turn", 0)), str(memory.get("title", "婢舵牔姘︾拋鏉跨箓"))],
					"缁鍩? %s / 闁插秷顩︽惔? %s" % [str(memory.get("category", "EVENT")), str(memory.get("importance", 1))]
				]))
		var world_state_report: Dictionary = GameState.world_data.get("world_state_report", {})
		if not world_state_report.is_empty():
			var statistics: Dictionary = world_state_report.get("statistics", {})
			var state_posture: Dictionary = world_state_report.get("strategic_posture", {})
			drawer_content.add_child(_make_section_title("閸忋劌鐪幀浣稿◢"))
			drawer_content.add_child(_make_info_card([
				"楠炲疇銆€鐠囧嫪鍙? %s" % str(world_state_report.get("balance_assessment", "UNKNOWN")),
				"閸斿灝濮忛弫? %s / 閼镐即妲﹂弫? %s" % [str(statistics.get("faction_count", 0)), str(statistics.get("fleet_count", 0))],
				"楠炲啿娼庨崘娑樺: %s / 閹存ü绨ら弫? %s" % [str(statistics.get("average_military_power", 0)), str(statistics.get("war_count", 0))],
				"閸欘垵顫嗛弰鐔洪兇: %s / 閺冪姳瀵岄弰鐔洪兇: %s" % [str(statistics.get("visible_system_count", 0)), str(statistics.get("unowned_system_count", 0))],
				"????: %s" % str(state_posture.get("recommended_posture", "CONSOLIDATE"))
			]))
		var fleet_status_report: Dictionary = GameState.world_data.get("fleet_status_report", {})
		if not fleet_status_report.is_empty():
			drawer_content.add_child(_make_section_title("閼镐即妲﹂悩鑸碘偓浣告礀閹?))
			drawer_content.add_child(_make_info_card([
				"娴ｅ秶鐤? %s" % str(fleet_status_report.get("location", "閺堫亞鐓?)),
				"娴犺濮? %s" % str(fleet_status_report.get("mission", "閺堫亞鐓?)),
				"閹存ê濮? %s / 閹存ê顦? %s" % [str(fleet_status_report.get("strength", 0)), str(fleet_status_report.get("readiness", "UNKNOWN"))]
			]))
			for unit: Dictionary in fleet_status_report.get("unit_composition", []):
				drawer_content.add_child(_make_info_card([
					"%s 璺?%s" % [str(unit.get("name", "閼告媽鍩?)), str(unit.get("type", "UNKNOWN"))],
					"HP %s/%s 璺?娴笺倕顔?%s" % [str(unit.get("hp", 0)), str(unit.get("maxHp", 0)), str(unit.get("damage", 0))]
				]))
		var tactical_report: Dictionary = GameState.world_data.get("tactical_report", {})
		if not tactical_report.is_empty():
			drawer_content.add_child(_make_section_title("閹存ɑ婀冲楦款唴"))
			drawer_content.add_child(_make_info_card([
				"閹恒劏宕橀幋妯绘钩: %s" % str(tactical_report.get("recommended_tactics", "LINE"))
			]))
			for line: String in tactical_report.get("expected_outcomes", []):
				drawer_content.add_child(_make_info_card([line]))
			for line: String in tactical_report.get("risk_assessments", []):
				drawer_content.add_child(_make_info_card(["妞嬪酣娅? %s" % line]))
			if not GameState.get_enemy_fleet_for_selected_context().is_empty():
				drawer_content.add_child(_make_action_button("閹笛嗩攽閹存ɑ鏋熼崡蹇氼唴", GameState.execute_selected_combat_protocol))
		var director_report: Dictionary = GameState.world_data.get("director_event_report", {})
		if not director_report.is_empty():
			drawer_content.add_child(_make_section_title("鐎靛吋绱ㄦ禍瀣╂妫板嫯顫?))
			drawer_content.add_child(_make_info_card([
				str(director_report.get("event_id", "娴滃娆?)),
				str(director_report.get("narrative_content", ""))
			]))
			drawer_content.add_child(_make_action_button("鎼存梻鏁ょ拠銉ょ皑娴?, GameState.apply_director_event_to_world.bind(_event_template_from_preview(str(director_report.get("event_id", ""))))))
			for effect: String in director_report.get("immediate_effects", []):
				drawer_content.add_child(_make_info_card(["閸楄櫕妞傞弫鍫熺亯: %s" % effect]))
			for option: String in director_report.get("follow_up_options", []):
				drawer_content.add_child(_make_info_card(["閸氬海鐢婚柅澶愩€? %s" % option]))
		var intervention_report: Dictionary = GameState.world_data.get("director_intervention_report", {})
		if not intervention_report.is_empty():
			drawer_content.add_child(_make_section_title("鐎靛吋绱ㄩ獮鏌ヮ暕妫板嫯顫?))
			drawer_content.add_child(_make_info_card([
				str(intervention_report.get("intervention_id", "director_preview")),
				"閻溾晛顔嶉幇鐔虹叀: %s" % str(intervention_report.get("player_perception", "SUBTLE"))
			]))
			drawer_content.add_child(_make_action_button("鎼存梻鏁ょ拠銉ュ叡妫?, GameState.apply_director_intervention_to_world.bind(_intervention_type_from_preview(str(intervention_report.get("intervention_id", ""))))))
			for effect: String in intervention_report.get("effects_summary", []):
				drawer_content.add_child(_make_info_card(["楠炴煡顣╅弫鍫熺亯: %s" % effect]))
		var resource_report: Dictionary = GameState.world_data.get("resource_status_report", {})
		if not resource_report.is_empty():
			drawer_content.add_child(_make_section_title("鐠у嫭绨拠濠冩焽"))
			drawer_content.add_child(_make_info_card([
				"妞嬬喓澧? %s (%s)" % [str(resource_report.get("food", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("food", {}).get("net", 0)))],
				"閻じ楠? %s (%s)" % [str(resource_report.get("minerals", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("minerals", {}).get("net", 0)))],
				"瀹搞儰绗? %s (%s)" % [str(resource_report.get("industry", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("industry", {}).get("net", 0)))],
				"閼宠姤绨? %s (%s)" % [str(resource_report.get("energy", {}).get("stock", 0)), _signed_int_text(int(resource_report.get("energy", {}).get("net", 0)))]
			]))
			for warning: String in resource_report.get("balance_warning", []):
				drawer_content.add_child(_make_info_card(["鐠€锕€鎲? %s" % warning]))
		var combat_report: Dictionary = GameState.world_data.get("combat_protocol_report", {})
		if not combat_report.is_empty():
			drawer_content.add_child(_make_section_title("閹存ɑ鏋熸０鍕灲"))
			drawer_content.add_child(_make_info_card([
				"閻樿埖鈧? %s" % str(combat_report.get("status", "UNKNOWN")),
				"妫板嫪鍙婇懗婊冨焺: %s" % ("閺? if combat_report.get("victory", false) else "閸?),
				"妫板嫯顓搁幑鐔枫亼閼告媽鍩? %s / 閸戠粯鐦夐弫宀冨煂: %s" % [str(combat_report.get("casualties", 0)), str(combat_report.get("kills", 0))],
				"閸撯晙缍戦幋妯哄: %s%%" % str(combat_report.get("remaining_power", 0))
			]))
			for note: String in combat_report.get("tactical_notes", []):
				drawer_content.add_child(_make_info_card(["閹存ɑ婀虫径鍥ㄦ暈: %s" % note]))

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

	drawer_content.add_child(_make_section_title(system.get("name", "")))
	drawer_content.add_child(_make_info_card([
		"瑜版帒鐫? %s" % GameState.get_owner_name(system.get("ownerId", null)),
		system.get("note", ""),
		"鐠у嫭绨? %s" % _resource_line(system.get("resources", {})),
		"瀵よ櫣鐡氶弽闂寸秴: %s/%s" % [str(system.get("buildings", []).size() + queue_items.size()), str(system.get("buildingSlots", 0))],
		"鐎规粌鐪虫惔? %s" % str(system.get("habitability", 0))
	]))
	if not queue_items.is_empty():
		drawer_content.add_child(_make_info_card([
			"閻㈢喍楠囩憴鍕灊: 瀵よ櫣鐡?%s / 闁姾鍩?%s" % [str(structure_queue_count), str(ship_queue_count)],
			"瑜版挸澧犻柌宥囧仯: %s" % ("閼镐即妲﹂幍鈺佸晽" if ship_queue_count > structure_queue_count else "閸╄櫣顢呭楦款啎" if structure_queue_count > ship_queue_count else "閸у洩銆€閸欐垵鐫?)
		]))
	if system.get("colonyStage", "NONE") != "NONE":
		drawer_content.add_child(_make_info_card([
			"濞堟牗鐨梼鑸殿唽: %s" % _colony_stage_name(system.get("colonyStage", "NONE")),
			"濞堟牗鐨Ο鈥崇础: %s" % InitialData.colonization_modes().get(system.get("colonizationMode", ""), {}).get("name", system.get("colonizationMode", "閺?)),
			"閹存劙鏆辨潻娑樺: %s%%" % str(int(round(float(system.get("colonizationProgress", 0.0))))),
			"閸撯晙缍戦崶鐐叉値: %s" % str(system.get("colonizationTurnsRemaining", 0)),
			"缁嬪啿鐣炬惔? %s" % str(system.get("stability", 0)),
			"鐞涖儳绮板鏉戦挬: %s" % str(system.get("supplyLevel", 0)),
			"妞嬪酣娅撶粵澶岄獓: %s" % str(system.get("colonizationRisk", "閺?))
		]))
	if system.get("eventResolved", true) == false:
		drawer_content.add_child(_make_info_card([
			"瀵倸鐖舵穱鈥冲娇: %s" % str(system.get("eventType", "閺堫亞鐓℃禍瀣╂")),
			"閼镐即妲﹂棃鐘虹箮閸氬骸褰叉潻娑楃濮濄儱顦╅悶鍡氼嚉娴滃娆㈤妴?
		]))

	if not system.get("buildings", []).is_empty():
		drawer_content.add_child(_make_section_title("瑜版挸澧犲铏圭摎"))
		for item: Dictionary in system.get("buildings", []):
			drawer_content.add_child(_make_info_card(["%s" % item.get("name", "")]))

	if not queue_items.is_empty():
		drawer_content.add_child(_make_section_title("瀵ゆ椽鈧娀妲﹂崚?))
		for item: Dictionary in queue_items:
			drawer_content.add_child(_make_info_card(["%s 璺?閸撯晙缍?%s 閸ョ偛鎮? % [item.get("displayName", ""), str(item.get("turnsRemaining", 0))]]))

	if system.get("ownerId", null) == GameState.PLAYER_FACTION_ID:
		drawer_content.add_child(_make_section_title("閸欘垰缂撻柅鐘茬紦缁?))
		for building: Dictionary in GameState.available_buildings():
			drawer_content.add_child(_make_building_card(building))
			drawer_content.add_child(_make_action_button("閸旂姴鍙嗗娲偓鐘绘Е閸?, GameState.queue_structure.bind(system.get("id", ""), building.get("type", ""))))

		var has_shipyard: bool = false
		for building: Dictionary in system.get("buildings", []):
			if building.get("type", "") == "SHIPYARD":
				has_shipyard = true
		if has_shipyard:
			drawer_content.add_child(_make_section_title("閼哥懓娼悽鐔堕獓"))
			drawer_content.add_child(_make_info_card([
				"娴溠呭殠閺佸牏宸? 濮ｅ繐娲栭崥?-1 閸╄櫣顢呭銉︽埂閿涘矂顤傛径鏍у綀瀹搞儱宸舵稉搴ゅ殰閸斻劌瀵茬粔鎴炲Η閸旂姵鍨?,
				"鐟欏嫬鍨濆楦款唴: 閸欘垰宕熼懝妯诲笓闂冪噦绱濇稊鐔峰讲閹靛綊鍣烘０鍕笓娴犮儲鏁幘鎴︽毐閺堢喐澧块崘?
			]))
			for ship_type: String in GameState.available_ship_types():
				var cost: Dictionary = GameLogic.ship_cost(ship_type, GameState.game_state, GameState.PLAYER_FACTION_ID)
				drawer_content.add_child(_make_info_card([
					"%s" % InitialData.ship_labels().get(ship_type, ship_type),
					"濞戝牐鈧? %s" % _resource_line(cost)
				]))
				drawer_content.add_child(_make_action_button("閹烘帡妲?s" % InitialData.ship_labels().get(ship_type, ship_type), GameState.queue_ship.bind(system.get("id", ""), ship_type)))
                drawer_content.add_child(_make_action_button("预排3艘%s" % InitialData.ship_labels().get(ship_type, ship_type), GameState.queue_ship_batch.bind(system.get("id", ""), ship_type, 3)))

	var system_actions: HBoxContainer = _action_row()
	if GameState.selected_fleet_id != "":
		system_actions.add_child(_make_action_button("閹恒垻鍌?, GameState.explore_system.bind(system.get("id", ""))))
		if GameState.get_reachable_system_ids(GameState.selected_fleet_id).has(system.get("id", "")):
			system_actions.add_child(_make_action_button("鐠哄啳绺奸懛铏劃", GameState.move_selected_fleet.bind(system.get("id", ""))))
	if system_actions.get_child_count() > 0:
		drawer_content.add_child(system_actions)
	if GameState.selected_fleet_id != "" and system.get("colonyStage", "NONE") == "NONE":
		drawer_content.add_child(_make_section_title("濞堟牗鐨弬瑙勵攳"))
		for mode_key: String in GameState.colonization_modes().keys():
			var mode_data: Dictionary = GameState.colonization_modes().get(mode_key, {})
			var preview: Dictionary = GameState.colonization_preview(system.get("id", ""), mode_key)
			drawer_content.add_child(_make_info_card([
				"%s 璺?%s 閸ョ偛鎮? % [mode_data.get("name", mode_key), str(preview.get("turns", mode_data.get("turns", 0)))],
				mode_data.get("description", ""),
				"濞戝牐鈧? %s" % _resource_line(preview.get("cost", mode_data.get("cost", {}))),
				"閸掓繂顫愭禍鍝勫經: %s" % str(mode_data.get("initial_population", 0)),
				"閸掓繂顫愮粙鍐茬暰鎼? %s" % str(mode_data.get("initial_stability", 0)),
				"妞嬪酣娅撶粵澶岄獓: %s" % str(mode_data.get("risk", "閺堫亞鐓?)),
				"閻樿埖鈧? %s" % str(preview.get("reason", ""))
			]))
			var colonize_button: Button = _make_action_button("閸欐垼鎹?s" % mode_data.get("name", mode_key), GameState.colonize_system.bind(system.get("id", ""), mode_key))
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
		"妞硅崵鏆€閺勭喓閮? %s" % GameState.get_system_by_id(fleet.get("systemId", "")).get("name", ""),
		"鐎瑰本鏆ｆ惔? %s/%s" % [str(total_hp), str(total_max_hp)],
		"閼镐即妲﹂幋妯哄: %s" % str(total_damage)
	]))
	var local_player_fleets: Array = GameState.get_player_fleets_in_system(fleet.get("systemId", ""))
	drawer_content.add_child(_make_info_card([
		"閺堫剙婀村杈ㄦ煙閼镐即妲﹂弫? %s" % str(local_player_fleets.size()),
		"缂傛牜绮嶉幙宥勭稊: 閸欘垱瀵滅粵鏍у灊濡楀牊澧界悰灞惧閸掑棔绗岄崥鍫濊嫙閵?
	]))
	drawer_content.add_child(_make_info_card([
		"瑜版挸澧犳禒璇插: %s" % GameLogic.fleet_mission_label(str(fleet.get("mission", "IDLE")))
	]))
	var mission_row_one: HBoxContainer = _action_row()
	mission_row_one.add_child(_make_action_button("瀵板懎鎳?, GameState.set_selected_fleet_mission.bind("IDLE")))
	mission_row_one.add_child(_make_action_button("閼奉亜濮╅幒銏㈠偍", GameState.set_selected_fleet_mission.bind("EXPLORE")))
	mission_row_one.add_child(_make_action_button("濞堟牗鐨柈銊ц", GameState.set_selected_fleet_mission.bind("COLONIZE")))
	drawer_content.add_child(mission_row_one)
	var mission_row_two: HBoxContainer = _action_row()
	mission_row_two.add_child(_make_action_button("妞瑰妲荤拃锔藉灊", GameState.set_selected_fleet_mission.bind("GUARD")))
	mission_row_two.add_child(_make_action_button("閸撳秶鍤庨幍鎾冲毊", GameState.set_selected_fleet_mission.bind("STRIKE")))
	drawer_content.add_child(mission_row_two)
	var organization_row: HBoxContainer = _action_row()
	organization_row.add_child(_make_action_button("閹峰棗鍨庨懜浼存Е", GameState.split_selected_fleet))
	organization_row.add_child(_make_action_button("閸氬牆鑻熼張顒€婀撮懜浼存Е", GameState.merge_player_fleets_at_selected_system))
	drawer_content.add_child(organization_row)

	for ship: Dictionary in fleet.get("ships", []):
		drawer_content.add_child(_make_info_card([
			"%s 璺?%s" % [ship.get("name", ""), InitialData.ship_labels().get(ship.get("type", ""), ship.get("type", ""))],
			"HP %s/%s 璺?娴笺倕顔?%s" % [str(ship.get("hp", 0)), str(ship.get("maxHp", 0)), str(ship.get("damage", 0))]
		]))

	drawer_content.add_child(_make_section_title("閸欘垵鎻弰鐔洪兇"))
	for system_id: String in GameState.get_reachable_system_ids(fleet.get("id", "")):
		var system: Dictionary = GameState.get_system_by_id(system_id)
		var row: HBoxContainer = _action_row()
		row.add_child(_make_action_button(system.get("name", system_id), GameState.select_system.bind(system_id)))
		row.add_child(_make_action_button("鐠哄啳绺?, GameState.move_selected_fleet.bind(system_id)))
		if system.get("visibilityLevel", "") != "FULL":
			row.add_child(_make_action_button("閹恒垻鍌?, GameState.explore_system.bind(system_id)))
		drawer_content.add_child(row)

	var enemy_fleet: Dictionary = GameState.get_enemy_fleet_for_selected_context()
	if not enemy_fleet.is_empty():
		drawer_content.add_child(_make_section_title("娴溿倖鍨惄顔界垼"))
		drawer_content.add_child(_make_info_card([
			"%s" % enemy_fleet.get("name", "閺佸本鏌熼懜浼存Е"),
			"瑜版帒鐫? %s" % GameState.get_owner_name(enemy_fleet.get("ownerId", "")),
			"閹碘偓閸︺劍妲︾化? %s" % GameState.get_system_by_id(enemy_fleet.get("systemId", "")).get("name", enemy_fleet.get("systemId", ""))
		]))
		var combat_row: HBoxContainer = _action_row()
		combat_row.add_child(_make_action_button("閹存ɑ鏋熸０鍕灲", GameState.request_combat_preview))
		combat_row.add_child(_make_action_button("閻掞箑婀￠弨璺ㄧ摜", GameState.execute_selected_combat_protocol.bind("ALL_OUT", "WEDGE", "SCORCHED_EARTH")))
		combat_row.add_child(_make_action_button("鏉炪劑浜炬潪鎵仮", GameState.execute_selected_combat_protocol.bind("DEFENSIVE", "LINE", "ORBITAL_BOMBARDMENT")))
		drawer_content.add_child(combat_row)
		var combat_row_two: HBoxContainer = _action_row()
		combat_row_two.add_child(_make_action_button("閻欒偐鍏㈢粣浣筋潹", GameState.execute_selected_combat_protocol.bind("HIT_AND_RUN", "WEDGE", "WOLF_PACK")))
		combat_row_two.add_child(_make_action_button("鐠哄啳绺肩粣浣稿毊", GameState.execute_selected_combat_protocol.bind("ALL_OUT", "WEDGE", "JUMP_ASSAULT")))
		combat_row_two.add_child(_make_action_button("閹存ê鍨痪?, GameState.execute_selected_combat_protocol.bind("DEFENSIVE", "LINE", "BATTLE_LINE")))
		drawer_content.add_child(combat_row_two)

	drawer_content.add_child(_make_action_button("閺佹潙顦懜浼存Е", GameState.repair_fleet.bind(fleet.get("id", ""))))

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
		"%s 璺?%s 閸ョ偛鎮? % [building.get("name", ""), str(InitialData.building_turns().get(building.get("type", ""), 1))],
		building.get("description", ""),
		"瀵ゆ椽鈧姵绉烽懓? %s" % _resource_line(building.get("cost", {})),
		"瀵よ櫣鐡氭禍褍鍤? %s" % _resource_line(building.get("production", {}), true),
		"缂佸瓨濮㈢拹鍦暏: %s" % _resource_line(building.get("maintenance", {})),
		"妫版繂顦绘担蹇斿煣: %s" % str(building.get("housing", 0))
	])

func _make_tech_card(tech: Dictionary, researching: bool) -> PanelContainer:
	var lines: Array = [
		"%s 璺?T%s 璺?%s" % [tech.get("name", ""), str(tech.get("tier", 1)), tech.get("category", "")],
		tech.get("description", ""),
		"閻梻鈹掗弮鍫曟？ %s 閸ョ偛鎮?/ 閼鸿精鍨?%s 瀹搞儰绗? % [str(tech.get("researchTime", 0)), str(tech.get("cost", 0))]
	]
	if researching:
		lines.append("瑜版挸澧犳潻娑樺 %.0f%%" % float(tech.get("progress", 0.0)))
	for effect: String in tech.get("effects", []):
		lines.append("閸旂姵鍨? %s" % effect)
	for unlock_name: String in tech.get("unlocks", []):
		lines.append("鐟欙綁鏀? %s" % unlock_name)
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
	return "閺? if parts.is_empty() else " / ".join(parts)

func _treaty_names_text(treaties: Array) -> String:
	if treaties.is_empty():
		return "閺?
	var names: PackedStringArray = PackedStringArray()
	for treaty: Dictionary in treaties:
		names.append(InitialData.treaty_labels().get(treaty.get("type", ""), treaty.get("type", "")))
	return ", ".join(names)

func _colony_stage_name(stage: String) -> String:
	match stage:
		"OUTPOST":
			return "濞堟牗鐨崜宥呮憼"
		"COLONY":
			return "濮濓絽绱″▓鏍ㄧ毌閸?
		"CORE":
			return "閺嶇绺炬稉鏍櫕"
		_:
			return "閺堫亝鐣哄?

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
			return "閸忓牓鈹嶉弮鏈靛敩"
		"EXPANSION":
			return "閹碘晛绱堕弮鏈靛敩"
		"CONFLICT":
			return "缁捐渹绨ら弮鏈靛敩"
		"UNIFICATION":
			return "缂佺喍绔撮弮鏈靛敩"
		"ASCENSION":
			return "妞嬬偛宕岄弮鏈靛敩"
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