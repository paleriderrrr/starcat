from __future__ import annotations

import asyncio
from pathlib import Path
import re
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from main import (  # noqa: E402
    ConstructionManageRequest,
    FleetMoveRequest,
    ShipProductionRequest,
    construction_manage,
    fleet_move,
    order_ship_production,
)


def _read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


class StarcatTodoTests(unittest.TestCase):
    def test_key_godot_files_contain_readable_chinese_strings(self) -> None:
        api_client = _read_text("starcat/scripts/autoload/ApiClient.gd")
        game_state = _read_text("starcat/scripts/autoload/GameState.gd")
        initial_data = _read_text("starcat/scripts/data/InitialData.gd")
        self.assertIn("请求未能发起。", api_client)
        self.assertIn("无归属", game_state)
        self.assertIn("喵星文明", initial_data)

    def test_fleet_move_api_exposes_chapter_05_strategic_move_fields(self) -> None:
        payload = {
            "fleet_id": "fleet_player_1",
            "target_system_id": "sys_vega",
            "game_state": {
                "factions": [
                    {
                        "id": "f_player",
                        "isPlayer": True,
                        "resources": {"energy": 100},
                    }
                ],
                "fleets": [
                    {
                        "id": "fleet_player_1",
                        "ownerId": "f_player",
                        "systemId": "sys_cat_home",
                    }
                ],
                "hyperlanes": [
                    {
                        "startSystemId": "sys_cat_home",
                        "endSystemId": "sys_vega",
                        "traversalCost": 2,
                    }
                ],
            },
        }
        body = asyncio.run(fleet_move(FleetMoveRequest(**payload))).model_dump()
        self.assertEqual(body["status"], "SUCCESS")
        self.assertEqual(body["estimated_arrival_turns"], 2)
        self.assertEqual(body["path_segments"], ["sys_cat_home", "sys_vega"])
        self.assertIsInstance(body["warning_messages"], list)

    def test_colonization_preview_exposes_confirmation_fields(self) -> None:
        source = _read_text("starcat/scripts/GameLogic.gd")
        required_fields = [
            '"initial_population"',
            '"initial_stability"',
            '"initial_supply"',
            '"slot_cap"',
            '"maintenance"',
            '"risk"',
        ]
        for field in required_fields:
            self.assertIn(field, source)

    def test_layered_memory_system_fields_exist_in_game_logic(self) -> None:
        source = _read_text("starcat/scripts/GameLogic.gd")
        required_markers = [
            "recentInteractionMemory",
            "archivedInteractionMemory",
            "semantic_keywords",
            "emotionalImpact",
            "decayFactor",
            "relatedLongTermMemories",
        ]
        for marker in required_markers:
            self.assertIn(marker, source)

    def test_communication_center_uses_rich_text_rendering(self) -> None:
        hud_script = _read_text("starcat/scripts/HudLayer.gd")
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        feed_card = _read_text("starcat/scenes/ui/FeedCard.tscn")
        proposal_card = _read_text("starcat/scenes/ui/ProposalCard.tscn")
        api_report_card = _read_text("starcat/scenes/ui/ApiReportCard.tscn")
        self.assertIn('"COMMS"', hud_script)
        self.assertIn("通讯中心", hud_script)
        self.assertIn("CommunicationsButton", hud_scene)
        self.assertIn('type="RichTextLabel"', feed_card)
        self.assertIn('type="RichTextLabel"', proposal_card)
        self.assertIn('type="RichTextLabel"', api_report_card)

    def test_tactic_cards_match_chapter_04_contract(self) -> None:
        source = _read_text("starcat/scripts/GameLogic.gd")
        expected_lines = [
            'notes.append("焦土政策提供了 20% 攻击加成。")',
            'notes.append("轨道轰炸强化了对防御建筑的打击，并降低了对舰队的伤害。")',
            'notes.append("狼群突袭提高了护卫舰闪避，并压低了主力舰命中。")',
            'round_factor = 2.0 if round_index == 0 else 0.7',
            'notes.append("战列线为巡洋舰与战列舰提供了 15% 火力加成。")',
        ]
        for line in expected_lines:
            self.assertIn(line, source)

    def test_ai_native_loop_has_secret_contact_and_group_council_agenda(self) -> None:
        source = _read_text("starcat/scripts/GameLogic.gd")
        required_markers = [
            "SECRET_CONTACT",
            "GROUP_COUNCIL",
            "generate_backchannel_agenda",
            "schedule_secret_contact",
            "schedule_group_council",
        ]
        for marker in required_markers:
            self.assertIn(marker, source)

    def test_personality_bias_is_used_for_active_ai_behavior(self) -> None:
        source = _read_text("starcat/scripts/GameLogic.gd")
        required_markers = [
            "faction_behavior_bias_report",
            'personality.get("aggression"',
            'personality.get("paranoia"',
            'personality.get("greed"',
            'personality.get("loyalty"',
            'personality.get("rationality"',
        ]
        for marker in required_markers:
            self.assertIn(marker, source)

    def test_ai_civilization_pool_defines_at_least_ten_templates(self) -> None:
        source = _read_text("starcat/scripts/data/InitialData.gd")
        self.assertIn("static func civilization_pool()", source)
        template_count = len(re.findall(r'"template_id":', source))
        self.assertGreaterEqual(template_count, 10)

    def test_initial_ai_factions_are_built_from_civilization_templates(self) -> None:
        source = _read_text("starcat/scripts/data/InitialData.gd")
        required_markers = [
            "select_ai_civilization_templates",
            "build_ai_faction_from_template",
            "var ai_templates: Array = select_ai_civilization_templates()",
            'build_ai_faction_from_template("f_merchant", "sys_sirius", ai_templates[0])',
            'build_ai_faction_from_template("f_orchid", "sys_orion", ai_templates[1])',
        ]
        for marker in required_markers:
            self.assertIn(marker, source)

    def test_star_map_supports_middle_drag_and_wasd_pan(self) -> None:
        star_map_script = _read_text("starcat/scripts/StarMap.gd")
        project = _read_text("starcat/project.godot")
        required_markers = [
            "MOUSE_BUTTON_MIDDLE",
            'Input.is_action_pressed("map_pan_left")',
            'Input.is_action_pressed("map_pan_right")',
            'Input.is_action_pressed("map_pan_up")',
            'Input.is_action_pressed("map_pan_down")',
        ]
        for marker in required_markers:
            self.assertIn(marker, star_map_script if marker.startswith("MOUSE_BUTTON") or marker.startswith("Input.") else star_map_script)
        for action_name in ["map_pan_left", "map_pan_right", "map_pan_up", "map_pan_down"]:
            self.assertIn('[input]', project)
            self.assertIn('%s={' % action_name, project)

    def test_star_map_uses_higher_camera_and_black_background(self) -> None:
        star_map_script = _read_text("starcat/scripts/StarMap.gd")
        star_map_scene = _read_text("starcat/scenes/StarMap.tscn")
        self.assertIn("const CAMERA_PITCH_DEGREES: float = -52.0", star_map_script)
        self.assertIn("camera.rotation_degrees.x = CAMERA_PITCH_DEGREES", star_map_script)
        self.assertIn("background_color = Color(0, 0, 0, 1)", star_map_scene)

    def test_right_drawer_uses_original_width_and_dynamic_full_height(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        hud_script = _read_text("starcat/scripts/HudLayer.gd")
        self.assertIn("offset_left = -456.0", hud_scene)
        self.assertIn("theme_override_constants/margin_left = 24", hud_scene)
        self.assertIn("theme_override_constants/margin_right = 24", hud_scene)
        self.assertIn("var top_bar_bottom: float = top_bar.offset_bottom", hud_script)
        self.assertIn("right_drawer.offset_top = top_bar_bottom + (8.0 if not compact else 6.0)", hud_script)
        self.assertIn("right_drawer.offset_bottom = bottom_tabs.offset_top - (8.0 if not compact else 6.0)", hud_script)

    def test_hud_uses_center_modal_for_content_heavy_views(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        hud_script = _read_text("starcat/scripts/HudLayer.gd")
        self.assertIn('node name="CenterModalOverlay"', hud_scene)
        self.assertIn('node name="CenterModal"', hud_scene)
        required_markers = [
            "var _modal_payload: Dictionary = {}",
            "func _open_center_modal(",
            "func _close_center_modal(",
            '查看详情',
            '_open_message_modal.bind(',
            '_open_proposal_modal.bind(',
            '_open_faction_modal.bind(',
            '_open_advisor_modal.bind(',
        ]
        for marker in required_markers:
            self.assertIn(marker, hud_script)

    def test_ui_text_components_enable_wrapping_and_modal_shortcuts(self) -> None:
        hud_script = _read_text("starcat/scripts/HudLayer.gd")
        feed_card = _read_text("starcat/scenes/ui/FeedCard.tscn")
        proposal_card = _read_text("starcat/scenes/ui/ProposalCard.tscn")
        status_card = _read_text("starcat/scenes/ui/StatusCard.tscn")
        summary_card = _read_text("starcat/scenes/ui/SummaryCard.tscn")
        diplomacy_card = _read_text("starcat/scenes/ui/DiplomacyFactionCard.tscn")
        posture_card = _read_text("starcat/scenes/ui/PostureCard.tscn")
        section_title = _read_text("starcat/scenes/ui/SectionTitle.tscn")
        composer_scene = _read_text("starcat/scenes/ui/DiplomacyComposer.tscn")
        self.assertIn("func _unhandled_input(event: InputEvent) -> void:", hud_script)
        self.assertIn("KEY_ESCAPE", hud_script)
        self.assertIn("autowrap_mode = 3", feed_card)
        self.assertIn("autowrap_mode = 3", proposal_card)
        self.assertIn("autowrap_mode = 3", status_card)
        self.assertIn("autowrap_mode = 3", summary_card)
        self.assertIn("autowrap_mode = 3", diplomacy_card)
        self.assertIn("autowrap_mode = 3", posture_card)
        self.assertIn("autowrap_mode = 3", section_title)
        self.assertIn("custom_minimum_size = Vector2(0, 140)", composer_scene)

    def test_remaining_ui_cards_enable_wrapping_for_narrow_layouts(self) -> None:
        chip = _read_text("starcat/scenes/ui/Chip.tscn")
        action_button = _read_text("starcat/scenes/ui/ActionButton.tscn")
        info_line = _read_text("starcat/scenes/ui/InfoLine.tscn")
        tech_card = _read_text("starcat/scenes/ui/TechCard.tscn")
        building_card = _read_text("starcat/scenes/ui/BuildingCard.tscn")
        route_card = _read_text("starcat/scenes/ui/RouteCard.tscn")
        queue_card = _read_text("starcat/scenes/ui/QueueItemCard.tscn")
        trend_card = _read_text("starcat/scenes/ui/TrendCard.tscn")
        colonization_card = _read_text("starcat/scenes/ui/ColonizationOptionCard.tscn")
        fleet_ship_card = _read_text("starcat/scenes/ui/FleetShipCard.tscn")
        for scene_text in [
            chip,
            action_button,
            info_line,
            tech_card,
            building_card,
            route_card,
            queue_card,
            trend_card,
            colonization_card,
            fleet_ship_card,
        ]:
            self.assertIn("autowrap_mode = 3", scene_text)
        self.assertIn('text = "操作"', action_button)
        self.assertIn("text_overrun_behavior = 3", action_button)
        self.assertIn("focus_mode = 2", action_button)
        self.assertIn("mouse_default_cursor_shape = 2", action_button)
        self.assertIn('theme_override_styles/focus = SubResource("2")', action_button)
        self.assertIn('text = "信息行"', info_line)
        self.assertIn("text_overrun_behavior = 3", info_line)

    def test_api_report_card_and_star_map_scene_use_readable_defaults(self) -> None:
        api_report_card = _read_text("starcat/scenes/ui/ApiReportCard.tscn")
        star_map_scene = _read_text("starcat/scenes/StarMap.tscn")
        self.assertIn('text = "API 报告"', api_report_card)
        self.assertIn("autowrap_mode = 3", api_report_card)
        self.assertIn("rotation_degrees = Vector3(-52, 0, 0)", star_map_scene)

    def test_hud_scene_uses_readable_primary_labels(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        required_labels = [
            'text = "文字标记: 显示"',
            'text = "战局"',
            'text = "通过底部导航切换不同系统面板"',
            'text = "推进下一回合"',
            'text = "详情"',
            'text = "查看完整内容"',
            'text = "关闭"',
            'text = "目标"',
            'text = "科技"',
            'text = "外交"',
            'text = "通讯中心"',
            'text = "AI顾问"',
        ]
        for label in required_labels:
            self.assertIn(label, hud_scene)

    def test_diplomacy_composer_uses_roomier_controls(self) -> None:
        composer_scene = _read_text("starcat/scenes/ui/DiplomacyComposer.tscn")
        self.assertIn("size_flags_vertical = 3", composer_scene)
        self.assertIn("custom_minimum_size = Vector2(144, 44)", composer_scene)
        self.assertIn("focus_mode = 2", composer_scene)
        self.assertIn("mouse_default_cursor_shape = 2", composer_scene)
        self.assertIn("size_flags_horizontal = 3", composer_scene)

    def test_hud_layout_has_very_narrow_responsive_tuning(self) -> None:
        hud_script = _read_text("starcat/scripts/HudLayer.gd")
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        required_markers = [
            "var very_narrow: bool = viewport_width < 1120.0",
            'top_bar.add_theme_constant_override("separation", 10 if not compact else 4 if very_narrow else 6)',
            'bottom_tabs.add_theme_constant_override("separation", 8 if not compact else 4 if very_narrow else 6)',
            "var nav_height: float = 52.0 if not compact else 48.0 if very_narrow else 50.0",
            "toggle_labels_button.custom_minimum_size = Vector2(116 if very_narrow else 132 if narrow_desktop else 136 if compact else 160, 52 if very_narrow else 56)",
            "food_chip.custom_minimum_size = Vector2(104 if very_narrow else 112 if narrow_desktop else 120 if compact else 132, 52 if very_narrow else 56)",
            "next_turn_button.custom_minimum_size = Vector2(0, 48 if very_narrow else 50 if compact else 54)",
        ]
        for marker in required_markers:
            self.assertIn(marker, hud_script)
        self.assertIn("text_overrun_behavior = 3", chip_scene)

    def test_ui_cards_use_consistent_text_overrun_behavior(self) -> None:
        for relative_path in [
            "starcat/scenes/ui/ApiReportCard.tscn",
            "starcat/scenes/ui/BuildingCard.tscn",
            "starcat/scenes/ui/ColonizationOptionCard.tscn",
            "starcat/scenes/ui/DiplomacyFactionCard.tscn",
            "starcat/scenes/ui/FeedCard.tscn",
            "starcat/scenes/ui/FleetShipCard.tscn",
            "starcat/scenes/ui/PostureCard.tscn",
            "starcat/scenes/ui/ProposalCard.tscn",
            "starcat/scenes/ui/QueueItemCard.tscn",
            "starcat/scenes/ui/RouteCard.tscn",
            "starcat/scenes/ui/SectionTitle.tscn",
            "starcat/scenes/ui/StatusCard.tscn",
            "starcat/scenes/ui/SummaryCard.tscn",
            "starcat/scenes/ui/TechCard.tscn",
            "starcat/scenes/ui/TrendCard.tscn",
        ]:
            scene_text = _read_text(relative_path)
            self.assertIn("text_overrun_behavior = 3", scene_text)

    def test_star_map_pans_camera_view_instead_of_translating_world_root(self) -> None:
        star_map_script = _read_text("starcat/scripts/StarMap.gd")
        self.assertIn("var _camera_pan: Vector2 = Vector2.ZERO", star_map_script)
        self.assertIn("camera.position = Vector3(", star_map_script)
        self.assertIn("_camera_pan.x", star_map_script)
        self.assertIn("_camera_pan.y + _zoom_distance", star_map_script)
        self.assertIn("_camera_pan += delta", star_map_script)
        self.assertNotIn("translate(Vector3(delta.x, 0.0, delta.y))", star_map_script)

    def test_star_map_disables_keyboard_pan_while_text_input_has_focus(self) -> None:
        star_map_script = _read_text("starcat/scripts/StarMap.gd")
        self.assertIn("func _has_text_input_focus() -> bool:", star_map_script)
        self.assertIn("get_viewport().gui_get_focus_owner()", star_map_script)
        self.assertIn("focus_owner is LineEdit or focus_owner is TextEdit", star_map_script)
        self.assertIn("if _has_text_input_focus():", star_map_script)

    def test_construction_validation_enforces_real_local_constraints(self) -> None:
        full_system_payload = {
            "system_id": "sys_full",
            "target_id": "MINING_STATION",
            "kind": "BUILDING",
            "game_state": {
                "factions": [{"id": "f_player", "isPlayer": True, "resources": {"food": 999, "minerals": 999, "industry": 999, "energy": 999}}],
                "starSystems": [{"id": "sys_full", "ownerId": "f_player", "buildingSlots": 2, "buildings": [{"type": "HABITAT"}]}],
                "constructionQueue": [{"systemId": "sys_full", "kind": "BUILDING", "targetId": "HYDROPONICS"}],
                "technologies": [],
            },
        }
        full_result = asyncio.run(construction_manage(ConstructionManageRequest(**full_system_payload)))
        self.assertFalse(full_result.ok)
        self.assertIn("格位", full_result.reason)

        shipyard_payload = {
            "system_id": "sys_no_yard",
            "target_id": "CORVETTE",
            "kind": "SHIP",
            "game_state": {
                "factions": [{"id": "f_player", "isPlayer": True, "resources": {"food": 999, "minerals": 999, "industry": 999, "energy": 999}}],
                "starSystems": [{"id": "sys_no_yard", "ownerId": "f_player", "buildingSlots": 4, "buildings": []}],
                "constructionQueue": [],
                "technologies": [],
            },
        }
        shipyard_result = asyncio.run(construction_manage(ConstructionManageRequest(**shipyard_payload)))
        self.assertFalse(shipyard_result.ok)
        self.assertIn("船坞", shipyard_result.reason)

    def test_ship_production_backend_uses_same_costs_as_gdscript(self) -> None:
        payload = {
            "system_id": "sys_yard",
            "ship_type": "CORVETTE",
            "quantity": 1,
            "priority": "NORMAL",
            "faction_id": "f_player",
            "game_state": {
                "factions": [{"id": "f_player", "resources": {"food": 10, "minerals": 30, "industry": 25, "energy": 10}}],
                "starSystems": [{"id": "sys_yard", "ownerId": "f_player", "buildings": [{"type": "SHIPYARD"}]}],
                "constructionQueue": [],
                "technologies": [],
            },
        }
        result = asyncio.run(order_ship_production(ShipProductionRequest(**payload))).model_dump()
        self.assertEqual(result["status"], "SUCCESS")
        self.assertEqual(result["resource_cost"], {"food": 10, "minerals": 30, "industry": 25, "energy": 10})

    def test_gdscript_logic_contains_regression_guards_for_review_findings(self) -> None:
        source = _read_text("starcat/scripts/GameLogic.gd")
        required_markers = [
            "static func queued_building_count_for_system(",
            "static func make_state_id(",
            'make_state_id(next_state, "building"',
            "static func consume_colonization_fleet(",
            "next_state = consume_colonization_fleet(next_state, fleet_id)",
            "static func can_queue_ship_for_ai(",
            'action == "BUILD"',
            'queue_ship_for_ai(next_state, "f_merchant"',
            'faction.get("researchedTechIds"',
        ]
        for marker in required_markers:
            self.assertIn(marker, source)


if __name__ == "__main__":
    unittest.main()
