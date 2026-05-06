from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


def _read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


class GodotBackendMigrationTests(unittest.TestCase):
    def test_api_client_routes_through_local_services_instead_of_http(self) -> None:
        source = _read_text("starcat/scripts/autoload/ApiClient.gd")
        self.assertNotIn("HTTPRequest", source)
        self.assertNotIn("API_BASE", source)
        self.assertIn('preload("res://scripts/services/GameAnalysisService.gd")', source)
        self.assertIn('preload("res://scripts/services/LocalAIService.gd")', source)
        self.assertIn('preload("res://scripts/services/NarrativeService.gd")', source)
        self.assertIn('preload("res://scripts/llm/BailianProvider.gd")', source)

    def test_local_service_layer_and_optional_provider_exist(self) -> None:
        expected_files = [
            "starcat/scripts/services/GameAnalysisService.gd",
            "starcat/scripts/services/LocalAIService.gd",
            "starcat/scripts/services/NarrativeService.gd",
            "starcat/scripts/config/LocalConfig.gd",
            "starcat/scripts/llm/BailianProvider.gd",
        ]
        for relative_path in expected_files:
            self.assertTrue((ROOT / relative_path).exists(), relative_path)

    def test_local_config_supports_godot_local_settings_file(self) -> None:
        source = _read_text("starcat/scripts/config/LocalConfig.gd")
        self.assertIn("ConfigFile", source)
        self.assertIn("starcat.local.cfg", source)
        self.assertIn("BAILIAN_API_KEY", source)
        self.assertIn("BAILIAN_MODEL", source)
        self.assertIn("BAILIAN_BASE_URL", source)

    def test_runtime_status_language_matches_godot_service_architecture(self) -> None:
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")
        api_client_source = _read_text("starcat/scripts/autoload/ApiClient.gd")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn("signal service_status_changed", game_state_source)
        self.assertIn("var service_status: String = ", game_state_source)
        self.assertNotIn("backend_status", game_state_source)
        self.assertIn("signal service_health_checked", api_client_source)
        self.assertIn("func check_service_health()", api_client_source)
        self.assertNotIn("signal health_checked(", api_client_source)
        self.assertNotIn("func check_health()", api_client_source)
        self.assertNotIn("backend_status", hud_source)

    def test_hud_drawer_uses_full_height_anchor_layout(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        right_drawer_block = hud_scene.split('[node name="RightDrawer" type="PanelContainer" parent="Root"', 1)[1].split("[node name=", 1)[0]
        self.assertIn("anchor_top = 0.0", right_drawer_block)
        self.assertIn("anchor_bottom = 1.0", right_drawer_block)
        self.assertNotIn("anchor_top = 0.5", right_drawer_block)

    def test_star_map_labels_are_scaled_for_readability(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")
        self.assertIn("label.pixel_size = 0.012 if compact else 0.014", star_map_source)
        self.assertIn("label.font_size = 34 if compact else 42", star_map_source)
        self.assertIn('_make_label(str(system.get("name", "")), _system_label_offset(false))', star_map_source)
        self.assertIn('_make_label(GameState.get_owner_name(system.get("ownerId", null)), _system_label_offset(true), true)', star_map_source)
        self.assertIn('_make_label(str(fleet.get("name", "")), _fleet_label_offset(fleet_slot), true)', star_map_source)

    def test_bottom_tabs_open_large_center_modal_and_remove_advisor_entry(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")

        self.assertNotIn('"ADVISOR"', hud_source)
        self.assertNotIn('"AI顾问"', hud_source)
        self.assertNotIn("advisor_button", hud_source)
        self.assertNotIn("AdvisorButton", hud_scene)
        self.assertIn('func _open_global_tab_modal(tab_name: String) -> void:', hud_source)
        self.assertIn("_open_global_tab_modal(tab_name)", hud_source)
        self.assertIn('right_drawer.visible = not selected_fleet.is_empty() or not selected_system.is_empty()', hud_source)
        self.assertIn('var modal_half_width: float = clampf(viewport_width * 0.42, 520.0, 760.0)', hud_source)
        self.assertIn('var modal_half_height: float = clampf(viewport_size.y * 0.42, 300.0, 460.0)', hud_source)
        self.assertNotIn("advisor_changed.connect", hud_source)
        self.assertNotIn("func _open_advisor_modal", hud_source)
        self.assertNotIn("func _on_advisor_changed", hud_source)

    def test_top_bar_chip_layout_and_titles_are_initialized(self) -> None:
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn("size_flags_horizontal = 3", chip_scene)
        self.assertIn("size_flags_vertical = 3", chip_scene)
        self.assertIn('turn_title.text = "回合"', hud_source)
        self.assertIn('era_title.text = "时代"', hud_source)
        self.assertIn('food_title.text = "食物"', hud_source)
        self.assertIn('food_chip.tooltip_text = _resource_tooltip_text("food")', hud_source)
        self.assertIn('func _resource_tooltip_text(resource_key: String) -> String:', hud_source)
        self.assertIn('GameState.get_resource_breakdown(resource_key)', hud_source)

    def test_hud_static_labels_define_explicit_font_colors(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        label_names = [
            "DrawerTitle",
            "DrawerSubtitle",
            "ModalTitle",
            "ModalSubtitle",
        ]

        for label_name in label_names:
            block = hud_scene.split('[node name="%s" type="Label"' % label_name, 1)[1].split("[node name=", 1)[0]
            self.assertIn("theme_override_colors/font_color", block, label_name)

    def test_non_button_ui_text_scenes_do_not_force_label_overrun_trimming(self) -> None:
        non_button_scenes = [
            "starcat/scenes/ui/ApiReportCard.tscn",
            "starcat/scenes/ui/BuildingCard.tscn",
            "starcat/scenes/ui/Chip.tscn",
            "starcat/scenes/ui/ColonizationOptionCard.tscn",
            "starcat/scenes/ui/DiplomacyFactionCard.tscn",
            "starcat/scenes/ui/FeedCard.tscn",
            "starcat/scenes/ui/FleetShipCard.tscn",
            "starcat/scenes/ui/InfoLine.tscn",
            "starcat/scenes/ui/PostureCard.tscn",
            "starcat/scenes/ui/ProposalCard.tscn",
            "starcat/scenes/ui/QueueItemCard.tscn",
            "starcat/scenes/ui/RouteCard.tscn",
            "starcat/scenes/ui/SectionTitle.tscn",
            "starcat/scenes/ui/StatusCard.tscn",
            "starcat/scenes/ui/SummaryCard.tscn",
            "starcat/scenes/ui/TechCard.tscn",
            "starcat/scenes/ui/TrendCard.tscn",
        ]

        for relative_path in non_button_scenes:
            scene_text = _read_text(relative_path)
            self.assertNotIn("text_overrun_behavior = 3", scene_text, relative_path)

    def test_ui_scene_default_text_lines_remain_valid_quoted_strings(self) -> None:
        for scene_path in (ROOT / "starcat/scenes/ui").glob("*.tscn"):
            scene_text = scene_path.read_text(encoding="utf-8")
            for line in scene_text.splitlines():
                stripped = line.strip()
                if stripped.startswith('text = "'):
                    self.assertTrue(stripped.endswith('"'), f"{scene_path}: {stripped}")

    def test_info_card_scene_is_a_valid_panel_container_shell(self) -> None:
        scene_text = _read_text("starcat/scenes/ui/InfoCard.tscn")

        self.assertIn('[ext_resource type="Texture2D" path="res://assets/ui/bridge/panel_shell.png"', scene_text)
        self.assertIn('[node name="InfoCard" type="PanelContainer"]', scene_text)
        self.assertIn('[node name="Content" type="VBoxContainer" parent="."]', scene_text)

    def test_tech_card_splits_effects_and_unlocks_into_separate_columns(self) -> None:
        tech_scene = _read_text("starcat/scenes/ui/TechCard.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('[node name="Columns" type="HBoxContainer" parent="Content"]', tech_scene)
        self.assertIn('[node name="EffectsColumn" type="VBoxContainer" parent="Content/Columns"]', tech_scene)
        self.assertIn('[node name="UnlocksColumn" type="VBoxContainer" parent="Content/Columns"]', tech_scene)
        self.assertIn('text = "加成"', tech_scene)
        self.assertIn('text = "解锁"', tech_scene)
        self.assertIn('func _highlight_numeric_segments(text: String, accent_color: Color = Color("FFD989")) -> String:', hud_source)
        self.assertIn('for effect: String in tech.get("effects", []):', hud_source)
        self.assertIn('for unlock_name: String in tech.get("unlocks", []):', hud_source)

    def test_technology_copy_uses_fixed_values_and_avoids_engineering_placeholders(self) -> None:
        initial_data = _read_text("starcat/scripts/data/InitialData.gd")

        self.assertNotIn("10%~20%", initial_data)
        self.assertNotIn("当前版本主要", initial_data)
        self.assertNotIn("后续会接入", initial_data)
        self.assertNotIn("暂不提供额外数值加成", initial_data)
        self.assertIn('["每个已控星系 +2 能源", "商路矿产 +1"]', initial_data)
        self.assertIn('["解锁太空船坞", "新造舰船 +15 生命 / +1 速度"]', initial_data)
        self.assertIn('["解锁科研实验室", "研究速度 +35%"]', initial_data)
        self.assertIn('["解锁正式殖民", "开放 4 类殖民方案"]', initial_data)
        self.assertIn('["解锁正式条约", "条约接受判定 +25 信任权重"]', initial_data)
        self.assertNotIn("更快更耐打", initial_data)
        self.assertNotIn("更容易被接受", initial_data)
        self.assertNotIn("成长更快", initial_data)

    def test_diplomacy_panel_uses_grouped_action_sections_and_humanized_labels(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('_panel_add(_make_section_title("外交对象"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("局势简报"))', hud_source)
        self.assertIn('modal_content.add_child(_make_section_title("常用外交文本"))', hud_source)
        self.assertIn('modal_content.add_child(_make_diplomacy_composer(faction.get("id", "")))', hud_source)
        self.assertNotIn('modal_content.add_child(_make_section_title("关系操作"))', hud_source)
        self.assertNotIn('modal_content.add_child(_make_section_title("条约操作"))', hud_source)
        self.assertNotIn("关系查询 API", hud_source)
        self.assertNotIn("提案评估 API", hud_source)

    def test_fleet_panel_removes_backend_validation_button(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")
        api_client_source = _read_text("starcat/scripts/autoload/ApiClient.gd")

        self.assertNotIn("后端校验", hud_source)
        self.assertNotIn("request_fleet_move_validation", hud_source)
        self.assertNotIn("fleet_move_report", hud_source)
        self.assertIn("func request_construction_validation", game_state_source)
        self.assertIn("func request_construction_validation", api_client_source)
        self.assertIn("func request_fleet_move_validation", game_state_source)
        self.assertIn("func request_fleet_move_validation", api_client_source)

    def test_turn_processing_handles_non_numeric_treaty_expiry_values(self) -> None:
        game_logic_source = _read_text("starcat/scripts/GameLogic.gd")

        self.assertIn('var expires_raw: Variant = treaty.get("expiresOnTurn", 0)', game_logic_source)
        self.assertIn('var expires_on: int = int(expires_raw) if expires_raw != null else 0', game_logic_source)

    def test_diplomacy_composer_uses_presets_to_fill_short_draft(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        composer_scene = _read_text("starcat/scenes/ui/DiplomacyComposer.tscn")

        self.assertIn('func _diplomacy_presets(faction_id: String) -> Array[Dictionary]:', hud_source)
        self.assertIn('func _apply_diplomacy_preset(editor: TextEdit, faction_id: String, template: String) -> void:', hud_source)
        self.assertIn('func _make_info_line(text: String) -> Control:', hud_source)
        self.assertIn('section.get_node("Margin/Text")', hud_source)
        self.assertIn('line_panel.get_node("Margin/Text")', hud_source)
        self.assertIn('var preset_wrap: FlowContainer = composer.get_node("PresetWrap")', hud_source)
        self.assertIn('preset_button.pressed.connect(_apply_diplomacy_preset.bind(draft_box, faction_id, str(preset.get("template", ""))))', hud_source)
        self.assertIn('"限制舰队逼近"', hud_source)
        self.assertIn('"资源换停火"', hud_source)
        self.assertIn('"科研互换"', hud_source)
        self.assertIn('[node name="PresetWrap" type="FlowContainer" parent="."]', composer_scene)
        self.assertIn('custom_minimum_size = Vector2(0, 96)', composer_scene)
        self.assertIn('theme_override_styles/normal = SubResource("1")', composer_scene)
        self.assertIn('theme_override_styles/focus = SubResource("2")', composer_scene)

    def test_hud_rebuilds_open_global_modal_immediately_after_state_changes(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('func _refresh_visible_panels() -> void:', hud_source)
        self.assertIn('if center_modal_overlay.visible and GameState.selected_system_id == "" and GameState.selected_fleet_id == "":', hud_source)
        self.assertIn('_open_global_tab_modal(GameState.active_tab)', hud_source)
        self.assertIn('refresh()\n\t_refresh_visible_panels()', hud_source)

    def test_bridge_ui_assets_are_installed_into_hud_shell_and_shared_controls(self) -> None:
        expected_assets = [
            "starcat/assets/ui/bridge/button_base.png",
            "starcat/assets/ui/bridge/button_hover.png",
            "starcat/assets/ui/bridge/button_pressed.png",
            "starcat/assets/ui/bridge/button_disabled.png",
            "starcat/assets/ui/bridge/chip_panel.png",
            "starcat/assets/ui/bridge/panel_shell.png",
            "starcat/assets/ui/bridge/panel_shell_strong.png",
            "starcat/assets/ui/bridge/card_shell.png",
            "starcat/assets/ui/bridge/card_shell_alert.png",
            "starcat/assets/ui/bridge/section_title_panel.png",
            "starcat/assets/ui/bridge/info_line_panel.png",
            "starcat/assets/ui/bridge/input_panel.png",
            "starcat/assets/ui/bridge/input_panel_focus.png",
            "starcat/assets/ui/bridge/tab_active.png",
            "starcat/assets/ui/bridge/tab_idle.png",
            "starcat/assets/ui/bridge/divider_glow.png",
        ]

        for relative_path in expected_assets:
            self.assertTrue((ROOT / relative_path).exists(), relative_path)

        action_button_scene = _read_text("starcat/scenes/ui/ActionButton.tscn")
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        section_title_scene = _read_text("starcat/scenes/ui/SectionTitle.tscn")
        info_line_scene = _read_text("starcat/scenes/ui/InfoLine.tscn")
        composer_scene = _read_text("starcat/scenes/ui/DiplomacyComposer.tscn")

        self.assertIn("assets/ui/bridge/button_base.png", action_button_scene)
        self.assertIn("assets/ui/bridge/chip_panel.png", chip_scene)
        self.assertIn("assets/ui/bridge/panel_shell_strong.png", hud_scene)
        self.assertIn("assets/ui/bridge/divider_glow.png", hud_scene)
        self.assertIn("assets/ui/bridge/section_title_panel.png", section_title_scene)
        self.assertIn("assets/ui/bridge/info_line_panel.png", info_line_scene)
        self.assertIn("assets/ui/bridge/input_panel.png", composer_scene)
        self.assertIn("assets/ui/bridge/input_panel_focus.png", composer_scene)

    def test_diplomatic_actions_flow_through_game_state_and_local_analysis_service(self) -> None:
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        analysis_source = _read_text("starcat/scripts/services/GameAnalysisService.gd")

        self.assertIn('func request_diplomatic_action(target_faction_id: String, action_type: String, action_payload: Dictionary = {}) -> void:', game_state_source)
        self.assertIn('ApiClient.request_diplomatic_action(game_state, PLAYER_FACTION_ID, target_faction_id, action_type, action_payload)', game_state_source)
        self.assertIn('GameState.request_diplomatic_action.bind(', hud_source)
        self.assertIn('"REQUEST_BORDER_LIMIT"', analysis_source)
        self.assertIn('"REQUEST_FLEET_DISTANCE"', analysis_source)
        self.assertIn('"REQUEST_RESOURCE_TRADE"', analysis_source)
        self.assertIn('"REQUEST_RESEARCH_EXCHANGE"', analysis_source)

    def test_player_message_intent_parsing_supports_restrictions_and_trades(self) -> None:
        game_logic_source = _read_text("starcat/scripts/GameLogic.gd")

        self.assertIn('"RESTRICTION"', game_logic_source)
        self.assertIn('"trade_kind"', game_logic_source)
        self.assertIn('label = "限制请求"', game_logic_source)
        self.assertIn('label = "交易提案"', game_logic_source)

    def test_fleet_panel_groups_actions_into_task_movement_and_support(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('_panel_add(_make_section_title("任务"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("行动指令"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("机动与维护"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("编组与评估"))', hud_source)
        self.assertIn('func _make_action_grid(buttons: Array[Button], columns: int = 2) -> GridContainer:', hud_source)
        self.assertIn('button.custom_minimum_size = Vector2(0, 44)', hud_source)
        self.assertIn('_panel_add(_make_status_card("任务状态"', hud_source)
        self.assertIn('_make_action_button("开始移动"', hud_source)
        self.assertIn('_make_action_button("取消移动"', hud_source)
        self.assertIn('_make_action_button("修复舰队"', hud_source)
        self.assertIn('_make_action_button("合并本地舰队"', hud_source)
        self.assertIn('start_move_button.disabled = move_mode_active', hud_source)
        self.assertIn('cancel_move_button.disabled = not move_mode_active', hud_source)
        self.assertIn('repair_button.disabled = total_hp >= total_max_hp', hud_source)
        self.assertIn('start_move_button.disabled = move_mode_active or int(fleet.get("movementCooldown", 0)) > 0 or reachable_routes.is_empty()', hud_source)
        self.assertIn('start_move_button.tooltip_text = "舰队仍在移动冷却中，暂时不能再次规划跃迁。"', hud_source)
        self.assertIn('start_move_button.tooltip_text = "当前没有可达航线，无法进入移动选择。"', hud_source)
        self.assertIn('cancel_move_button.tooltip_text = "当前未处于移动模式。"', hud_source)
        self.assertIn('repair_button.tooltip_text = "舰队已处于满状态，无需修理。"', hud_source)
        self.assertIn('split_button.disabled = fleet.get("ships", []).size() < 2', hud_source)
        self.assertIn('split_button.tooltip_text = "至少需要 2 艘舰船才能拆分舰队。"', hud_source)
        self.assertIn('merge_button.disabled = GameState.get_player_fleets_in_system(str(fleet.get("systemId", ""))).size() < 2', hud_source)
        self.assertIn('merge_button.tooltip_text = "本星系至少需要 2 支己方舰队才能合并。"', hud_source)
        self.assertIn('status_button.tooltip_text = "刷新舰队分析，查看战备与编组评估。"', hud_source)
        self.assertIn('_panel_add(_make_status_card("当前建议"', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("移动"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("后勤维护"))', hud_source)

    def test_runtime_capture_path_opens_real_global_tab_modals(self) -> None:
        main_source = _read_text("starcat/scripts/Main.gd")

        self.assertIn('if hud_layer.has_method("_on_tab_pressed"):', main_source)
        self.assertIn('hud_layer.call("_on_tab_pressed", "OBJECTIVES")', main_source)
        self.assertIn('hud_layer.call("_on_tab_pressed", "COMMS")', main_source)
        self.assertNotIn('GameState.set_active_tab("COMMS")', main_source)

    def test_star_map_uses_channel_based_label_avoidance(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('var fleet_counts_by_system: Dictionary = {}', star_map_source)
        self.assertIn('var fleet_slot: int = int(fleet_counts_by_system.get(system_id, 0))', star_map_source)
        self.assertIn('body.add_child(_make_label(str(system.get("name", "")), _system_label_offset(false)))', star_map_source)
        self.assertIn('body.add_child(_make_label(GameState.get_owner_name(system.get("ownerId", null)), _system_label_offset(true), true))', star_map_source)
        self.assertIn('marker.add_child(_make_label(str(fleet.get("name", "")), _fleet_label_offset(fleet_slot), true))', star_map_source)
        self.assertIn('func _system_label_offset(compact: bool = false) -> Vector3:', star_map_source)
        self.assertIn('func _fleet_label_offset(slot: int) -> Vector3:', star_map_source)
        self.assertIn('return Vector3(0.0, 1.5 if compact else 2.1, 0.0)', star_map_source)
        self.assertIn('return Vector3(0.0, 2.55 + 0.62 * float(slot), 0.0)', star_map_source)
        self.assertNotIn('var side: float = 1.0 if slot % 2 == 0 else -1.0', star_map_source)
        self.assertNotIn('2.3 + side * 0.45 * float(row)', star_map_source)

    def test_star_map_supports_click_to_move_when_fleet_move_mode_is_active(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('if GameState.try_move_selected_fleet_to_system(system_id):', star_map_source)
        self.assertIn('func begin_fleet_move_mode(fleet_id: String = "") -> void:', game_state_source)
        self.assertIn('func cancel_fleet_move_mode() -> void:', game_state_source)
        self.assertIn('func try_move_selected_fleet_to_system(system_id: String) -> bool:', game_state_source)
        self.assertIn('func focus_system(system_id: String) -> void:', game_state_source)
        self.assertIn('var fleet_move_mode: bool = false', game_state_source)

    def test_fleet_route_buttons_separate_viewing_from_executing_movement(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('_make_action_button("查看%s" % system.get("name", system_id), GameState.focus_system.bind(system_id), "neutral")', hud_source)
        self.assertIn('if GameState.fleet_move_mode:', hud_source)
        self.assertIn('_make_action_button("跃迁至此", GameState.move_selected_fleet.bind(system_id), "primary")', hud_source)
        self.assertNotIn('GameState.select_system.bind(system_id)', hud_source)
        self.assertIn('var moved_successfully: bool = updated_system_id != "" and updated_system_id != previous_system_id', game_state_source)
        self.assertIn('if moved_successfully:', game_state_source)
        self.assertIn('fleet_move_mode = false', game_state_source)
        self.assertIn('jump_button.disabled = not can_jump', hud_source)
        self.assertIn('jump_button.tooltip_text = "当前航道容量不足，舰队规模超出上限。"', hud_source)
        self.assertIn('jump_button.tooltip_text = "舰队仍在移动冷却中。"', hud_source)
        self.assertIn('jump_button.tooltip_text = "能源不足，无法支付本次跃迁消耗。"', hud_source)

    def test_objectives_and_fleet_panels_render_humanized_status_values(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        api_source = _read_text("starcat/scripts/autoload/ApiClient.gd")

        self.assertIn('func _objective_summary_lines() -> Array:', hud_source)
        self.assertIn('lines.append("当前战略: %s" % (segments[0] if segments.size() > 0 else "未设定"))', hud_source)
        self.assertIn('lines.append("阶段推进: %s" % segments[1])', hud_source)
        self.assertIn('lines.append("长期目标: %s" % segments[2])', hud_source)
        self.assertIn('"胜利路径: %s" % _victory_path_label(GameState.game_state.get("victory_path", null))', hud_source)
        self.assertIn('func _victory_path_label(value: Variant) -> String:', hud_source)
        self.assertIn('func _game_status_label(status: String) -> String:', hud_source)
        self.assertIn('func _charter_status_label(status: String) -> String:', hud_source)
        self.assertIn('func _interception_status_label(status: String) -> String:', hud_source)
        self.assertIn('func _fleet_readiness_label(readiness: String) -> String:', hud_source)
        self.assertIn('func _message_type_label(message_type: String) -> String:', hud_source)
        self.assertIn('return "未设定"', hud_source)
        self.assertIn('"宪章表决: %s" % _charter_status_label(str(diplomacy_report.get("charter_status", "INACTIVE")))', hud_source)
        self.assertIn('"通信截获状态: %s" % _interception_status_label(str(interception_report.get("status", "UNKNOWN")))', hud_source)
        self.assertIn('"战备状态: %s" % _fleet_readiness_label(str(fleet_status_report.get("readiness", "CRITICAL")))', hud_source)
        self.assertIn('"meta": _message_type_label(str(message.get("type", "SYSTEM"))),', hud_source)
        self.assertIn('"fleet_status_fleet_id": fleet_id,', api_source)
        self.assertIn('var fleet_status_fleet_id: String = str(GameState.world_data.get("fleet_status_fleet_id", ""))', hud_source)
        self.assertIn('_panel_add(_make_api_report_card(', hud_source)
        self.assertIn('"状态评估"', hud_source)
        self.assertIn('if GameState.active_tab == "DIPLOMACY" or GameState.active_tab == "COMMS" or GameState.selected_fleet_id != "" or GameState.selected_system_id != "":', hud_source)

    def test_communications_panel_is_grouped_into_system_diplomatic_and_proposals(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('_panel_add(_make_summary_card(', hud_source)
        self.assertIn('"当前摘要"', hud_source)
        self.assertIn('"系统消息: %s" % str(GameState.game_state.get("messages", []).size() + recent_reports.size())', hud_source)
        self.assertIn('"外交通信: %s" % str(visible_messages.size() + (0 if GameState.diplomatic_message.is_empty() else 1))', hud_source)
        self.assertIn('"待处理提案: %s" % str(pending_proposals.size())', hud_source)
        self.assertIn('_panel_add(_make_section_title("系统消息"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("外交通信"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("提案"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("短期记忆"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("长期归档"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("通信记录"))', hud_source)


if __name__ == "__main__":
    unittest.main()
