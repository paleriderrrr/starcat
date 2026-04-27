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
        self.assertIn('"服务状态: %s" % GameState.service_status', hud_source)
        self.assertNotIn("backend_status", hud_source)

    def test_hud_drawer_uses_full_height_anchor_layout(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        right_drawer_block = hud_scene.split('[node name="RightDrawer" type="PanelContainer" parent="Root"', 1)[1].split("[node name=", 1)[0]
        self.assertIn("anchor_top = 0.0", right_drawer_block)
        self.assertIn("anchor_bottom = 1.0", right_drawer_block)
        self.assertNotIn("anchor_top = 0.5", right_drawer_block)

    def test_star_map_labels_are_scaled_for_readability(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")
        self.assertIn("label.pixel_size = 0.02 if compact else 0.024", star_map_source)
        self.assertIn("label.font_size = 60 if compact else 76", star_map_source)
        self.assertIn('_make_label(str(system.get("name", "")), _system_label_offset(false))', star_map_source)
        self.assertIn('_make_label(GameState.get_owner_name(system.get("ownerId", null)), _system_label_offset(true), true)', star_map_source)
        self.assertIn('_make_label(str(fleet.get("name", "")), _fleet_label_offset(fleet_slot), true)', star_map_source)

    def test_top_bar_chip_layout_and_titles_are_initialized(self) -> None:
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn("size_flags_horizontal = 3", chip_scene)
        self.assertIn("size_flags_vertical = 3", chip_scene)
        self.assertIn('turn_title.text = "回合"', hud_source)
        self.assertIn('era_title.text = "时代"', hud_source)
        self.assertIn('food_title.text = "食物"', hud_source)

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

    def test_diplomacy_panel_uses_grouped_action_sections_and_humanized_labels(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('drawer_content.add_child(_make_section_title("外交对象"))', hud_source)
        self.assertIn('drawer_content.add_child(_make_section_title("局势简报"))', hud_source)
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
        self.assertIn('var preset_wrap: FlowContainer = composer.get_node("PresetWrap")', hud_source)
        self.assertIn('preset_button.pressed.connect(_apply_diplomacy_preset.bind(draft_box, faction_id, str(preset.get("template", ""))))', hud_source)
        self.assertIn('[node name="PresetWrap" type="FlowContainer" parent="."]', composer_scene)
        self.assertIn('custom_minimum_size = Vector2(0, 96)', composer_scene)

    def test_fleet_panel_groups_actions_into_task_movement_and_support(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('drawer_content.add_child(_make_section_title("任务"))', hud_source)
        self.assertIn('drawer_content.add_child(_make_section_title("移动"))', hud_source)
        self.assertIn('drawer_content.add_child(_make_section_title("后勤维护"))', hud_source)
        self.assertNotIn('row.add_child(_make_action_button("探索", GameState.explore_system.bind(system_id)))', hud_source)
        self.assertIn('support_row.add_child(_make_action_button("修复舰队", GameState.repair_fleet.bind(fleet.get("id", "")), "primary"))', hud_source)

    def test_star_map_uses_channel_based_label_avoidance(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('var fleet_counts_by_system: Dictionary = {}', star_map_source)
        self.assertIn('var fleet_slot: int = int(fleet_counts_by_system.get(system_id, 0))', star_map_source)
        self.assertIn('body.add_child(_make_label(str(system.get("name", "")), _system_label_offset(false)))', star_map_source)
        self.assertIn('body.add_child(_make_label(GameState.get_owner_name(system.get("ownerId", null)), _system_label_offset(true), true))', star_map_source)
        self.assertIn('marker.add_child(_make_label(str(fleet.get("name", "")), _fleet_label_offset(fleet_slot), true))', star_map_source)
        self.assertIn('func _system_label_offset(compact: bool = false) -> Vector3:', star_map_source)
        self.assertIn('func _fleet_label_offset(slot: int) -> Vector3:', star_map_source)


if __name__ == "__main__":
    unittest.main()
