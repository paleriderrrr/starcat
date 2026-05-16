from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


def _read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def _rgba_pixels(image) -> list[tuple[int, int, int, int]]:
    raw_bytes = image.tobytes()
    return [tuple(raw_bytes[index : index + 4]) for index in range(0, len(raw_bytes), 4)]


def _visible_pixels(image) -> list[tuple[int, int, int, int]]:
    return [pixel for pixel in _rgba_pixels(image) if pixel[3] > 8]


def _average_luminance(pixels: list[tuple[int, int, int, int]]) -> float:
    return sum(0.2126 * r + 0.7152 * g + 0.0722 * b for r, g, b, _a in pixels) / max(1, len(pixels))


def _average_alpha(pixels: list[tuple[int, int, int, int]]) -> float:
    return sum(a for _r, _g, _b, a in pixels) / max(1, len(pixels))


def _orange_ratio(pixels: list[tuple[int, int, int, int]]) -> float:
    orange_pixels = [pixel for pixel in pixels if pixel[0] > 185 and 55 <= pixel[1] <= 150 and pixel[2] < 95]
    return len(orange_pixels) / max(1, len(pixels))


def _cool_line_ratio(pixels: list[tuple[int, int, int, int]]) -> float:
    cool_pixels = [pixel for pixel in pixels if pixel[2] > pixel[0] + 16 and pixel[1] > pixel[0] + 8 and pixel[3] > 180]
    return len(cool_pixels) / max(1, len(pixels))


def _visible_component_count(image, alpha_threshold: int = 8, minimum_pixels: int = 8) -> int:
    width, height = image.size
    alpha = image.getchannel("A")
    visited: set[tuple[int, int]] = set()
    count = 0
    for y in range(height):
        for x in range(width):
            if (x, y) in visited or alpha.getpixel((x, y)) <= alpha_threshold:
                continue
            stack = [(x, y)]
            visited.add((x, y))
            component_size = 0
            while stack:
                current_x, current_y = stack.pop()
                component_size += 1
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if next_x < 0 or next_y < 0 or next_x >= width or next_y >= height:
                        continue
                    if (next_x, next_y) in visited or alpha.getpixel((next_x, next_y)) <= alpha_threshold:
                        continue
                    visited.add((next_x, next_y))
                    stack.append((next_x, next_y))
            if component_size >= minimum_pixels:
                count += 1
    return count


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
        self.assertIn('[node name="SafeArea" type="MarginContainer" parent="Root"]', hud_scene)
        self.assertIn('[node name="Layout" type="VBoxContainer" parent="Root/SafeArea"]', hud_scene)
        self.assertIn('[node name="TopBar" type="HBoxContainer" parent="Root/SafeArea/Layout/TopGroup"', hud_scene)
        self.assertIn('[node name="BottomTabs" type="HBoxContainer" parent="Root/SafeArea/Layout/BottomGroup"', hud_scene)
        self.assertNotIn('[node name="Spacer" type="Control" parent="Root/TopBar"', hud_scene)
        self.assertNotIn('[node name="FleetTabsSpacer" type="Control" parent="Root/BottomTabs"', hud_scene)
        self.assertNotIn('[node name="FleetTabs"', hud_scene)

    def test_star_map_labels_are_scaled_for_readability(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")
        self.assertIn("label.pixel_size = 0.012 if compact else 0.014", star_map_source)
        self.assertIn("label.font_size = 34 if compact else 42", star_map_source)
        self.assertIn('_make_label(str(system.get("name", "")), _system_label_offset(false, label_channel))', star_map_source)
        self.assertNotIn('_make_label(GameState.get_owner_name(system.get("ownerId", null))', star_map_source)
        self.assertIn('_make_label(_compact_label_text(str(fleet.get("name", "")), 10), _fleet_label_offset(fleet_slot, fleet_channel), true)', star_map_source)

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
        self.assertIn('[node name="CenterModal" type="PanelContainer" parent="Root/CenterModalOverlay/CenterWrap"', hud_scene)
        self.assertNotIn('custom_minimum_size = Vector2(1216, 700)', hud_scene)
        self.assertIn('func _update_modal_bounds() -> void:', hud_source)
        self.assertIn('root.resized.connect(_update_modal_bounds)', hud_source)
        self.assertIn('minf(1216.0, available_width)', hud_source)
        self.assertIn('minf(700.0, available_height)', hud_source)
        self.assertNotIn("advisor_changed.connect", hud_source)
        self.assertNotIn("func _open_advisor_modal", hud_source)
        self.assertNotIn("func _on_advisor_changed", hud_source)

    def test_top_bar_chip_layout_and_titles_are_initialized(self) -> None:
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")

        self.assertIn("size_flags_horizontal = 3", chip_scene)
        self.assertIn("size_flags_vertical = 3", chip_scene)
        self.assertIn('[node name="Icon" type="TextureRect" parent="Content"]', chip_scene)
        self.assertIn('[node name="TextBox" type="VBoxContainer" parent="Content"]', chip_scene)
        self.assertIn('turn_title.text = "回合"', hud_source)
        self.assertIn('era_title.text = "时代"', hud_source)
        self.assertIn('food_title.text = "食物"', hud_source)
        self.assertIn('_apply_chip_icon(food_chip, "food")', hud_source)
        self.assertIn('_apply_chip_icon(minerals_chip, "minerals")', hud_source)
        self.assertIn('_apply_chip_icon(industry_chip, "industry")', hud_source)
        self.assertIn('_apply_chip_icon(energy_chip, "energy")', hud_source)
        self.assertIn('food_chip.tooltip_text = _resource_tooltip_text("food")', hud_source)
        self.assertIn('func _resource_tooltip_text(resource_key: String) -> String:', hud_source)
        self.assertIn('GameState.get_resource_breakdown(resource_key)', hud_source)
        self.assertNotIn("theme_override_constants/margin_right = 520", hud_scene)
        self.assertIn("func _update_responsive_layout() -> void:", hud_source)
        self.assertIn("var right_margin: int = 24", hud_source)
        self.assertNotIn("right_margin = 520", hud_source)
        self.assertNotIn("right_margin = 320", hud_source)
        self.assertIn("safe_area.add_theme_constant_override(\"margin_right\", right_margin)", hud_source)
        self.assertIn("food_chip.custom_minimum_size = resource_chip_size", hud_source)
        self.assertIn("toggle_labels_button.custom_minimum_size = toggle_size", hud_source)

    def test_bottom_bar_does_not_spawn_dynamic_fleet_buttons(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertNotIn("FleetTabsSpacer", hud_scene)
        self.assertNotIn("FleetTabs", hud_scene)
        self.assertNotIn("fleet_tabs", hud_source)
        self.assertNotIn("GameState.get_player_fleets()", hud_source.split("func _rebuild_bottom_tabs() -> void:", 1)[1].split("func _build_objectives_panel", 1)[0])

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

        self.assertIn('[node name="CategoryAccent" type="ColorRect" parent="Content"]', tech_scene)
        self.assertIn('[node name="StatusRow" type="HBoxContainer" parent="Content"]', tech_scene)
        self.assertIn('[node name="CategoryLabel" type="Label" parent="Content/StatusRow"]', tech_scene)
        self.assertIn('[node name="StatusPill" type="Label" parent="Content/StatusRow"]', tech_scene)
        self.assertIn('[node name="Columns" type="HBoxContainer" parent="Content"]', tech_scene)
        self.assertIn('[node name="EffectsColumn" type="VBoxContainer" parent="Content/Columns"]', tech_scene)
        self.assertIn('[node name="UnlocksColumn" type="VBoxContainer" parent="Content/Columns"]', tech_scene)
        self.assertIn('text = "加成"', tech_scene)
        self.assertIn('text = "解锁"', tech_scene)
        self.assertIn('func _tech_category_color(category_key: String) -> Color:', hud_source)
        self.assertIn('card.get_node("Content/CategoryAccent").color = category_color', hud_source)
        self.assertIn('status_pill.text = _tech_status_label(tech, researching)', hud_source)
        self.assertIn('meta_label.text = _tech_meta_line(tech, researching)', hud_source)
        self.assertIn('TECH_CATEGORY_LABELS.get(str(key), str(key))', hud_source)
        self.assertIn('func _highlight_numeric_segments(text: String, accent_color: Color = Color("B36A00")) -> String:', hud_source)
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
        self.assertIn('"进入外交"', hud_source)
        self.assertIn('"外交态势"', hud_source)
        self.assertIn('var layout: HBoxContainer = _make_two_column_layout()', hud_source)
        self.assertIn('status_column.add_child(_make_section_title("外交态势"))', hud_source)
        self.assertIn('action_column.add_child(_make_section_title("提案"))', hud_source)
        self.assertIn('action_column.add_child(_make_section_title("回应处理"))', hud_source)
        self.assertIn('status_column.add_child(_make_section_title("通信截获"))', hud_source)
        self.assertIn('modal_content.add_child(layout)', hud_source)
        self.assertNotIn('_panel_add(_make_status_card(\n\t\t"外交态势"', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("待处理提案"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("最新回应"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("局势简报"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("外交记忆"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("关系简报"))', hud_source)
        self.assertIn('action_column.add_child(_make_diplomacy_composer(faction.get("id", "")))', hud_source)
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
        self.assertIn('preset_button.pressed.connect(_on_diplomacy_preset_pressed.bind(draft_box, send_button, faction_id, str(preset.get("template", ""))))', hud_source)
        self.assertIn('send_button.disabled = draft_box.text.strip_edges() == ""', hud_source)
        self.assertIn('"舰队距离"', hud_source)
        self.assertIn('"资源停火"', hud_source)
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

    def test_ui_visual_system_uses_generated_transparent_tech_palette(self) -> None:
        from PIL import Image

        palette_readme = _read_text("starcat/assets/ui/bridge/README.md")
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        self.assertIn("generated transparent UI sheet", palette_readme)
        self.assertIn("dark graphite", palette_readme)
        self.assertIn("cyan linework", palette_readme)
        self.assertIn("theme_override_colors/font_color = Color(0.95, 0.36, 0.08, 1)", chip_scene)
        self.assertIn("theme_override_colors/font_color = Color(0.88, 0.96, 0.98, 1)", chip_scene)
        self.assertIn('button.add_theme_color_override("font_pressed_color", Color(0.88, 0.96, 0.98, 1.0))', hud_source)

        scene_paths = list((ROOT / "starcat/scenes").rglob("*.tscn"))
        combined_scene_text = "\n".join(path.read_text(encoding="utf-8") for path in scene_paths)
        self.assertNotIn("main_menu_panel.png", combined_scene_text)
        self.assertNotIn("main_menu_option_row.png", combined_scene_text)
        self.assertIn("Color(0.006, 0.018, 0.036", combined_scene_text)
        self.assertIn("Color(0.95, 0.36, 0.08", combined_scene_text)

        source_alpha = Image.open(ROOT / "starcat/assets/ui/source/generated_ui_sheet_alpha.png").convert("RGBA")
        source_pixels = _rgba_pixels(source_alpha)
        self.assertLess(_average_alpha(source_pixels), 190.0)
        self.assertEqual(source_alpha.getpixel((0, 0))[3], 0)

        for image_path in (ROOT / "starcat/assets/ui/bridge").glob("*.png"):
            image = Image.open(image_path).convert("RGBA")
            pixels = _rgba_pixels(image)
            visible_pixels = [pixel for pixel in pixels if pixel[3] > 8]
            self.assertGreater(len(visible_pixels), 0, image_path.name)
            edge_pixels = []
            for x in range(image.width):
                edge_pixels.append(image.getpixel((x, 0)))
                edge_pixels.append(image.getpixel((x, image.height - 1)))
            for y in range(image.height):
                edge_pixels.append(image.getpixel((0, y)))
                edge_pixels.append(image.getpixel((image.width - 1, y)))
            visible_edge_pixels = [pixel for pixel in edge_pixels if pixel[3] > 8]
            if visible_edge_pixels:
                cyan_edges = [pixel for pixel in visible_edge_pixels if pixel[1] > pixel[0] and pixel[2] > pixel[0]]
                amber_edges = [
                    pixel
                    for pixel in visible_edge_pixels
                    if pixel[0] > pixel[1] and pixel[1] > pixel[2]
                ]
                self.assertGreater(
                    len(cyan_edges) + len(amber_edges),
                    max(2, len(visible_edge_pixels) // 24),
                    image_path.name,
                )

    def test_ui_panels_apply_generated_bridge_border_textures(self) -> None:
        bridge_panel_scenes = [
            "starcat/scenes/ui/ApiReportCard.tscn",
            "starcat/scenes/ui/BuildingCard.tscn",
            "starcat/scenes/ui/Chip.tscn",
            "starcat/scenes/ui/ColonizationOptionCard.tscn",
            "starcat/scenes/ui/DiplomacyComposer.tscn",
            "starcat/scenes/ui/DiplomacyFactionCard.tscn",
            "starcat/scenes/ui/FeedCard.tscn",
            "starcat/scenes/ui/FleetShipCard.tscn",
            "starcat/scenes/ui/InfoCard.tscn",
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

        for scene in bridge_panel_scenes:
            scene_text = _read_text(scene)
            self.assertIn("StyleBoxTexture", scene_text, scene)
            self.assertIn("texture_margin_left", scene_text, scene)
            self.assertNotIn("StyleBoxFlat", scene_text, scene)

    def test_main_menu_keeps_framed_portrait_and_uses_bridge_styles(self) -> None:
        main_scene = _read_text("starcat/scenes/Main.tscn")
        main_source = _read_text("starcat/scripts/Main.gd")
        generator_source = _read_text("starcat/tools/recolor_bridge_ui.py")
        project_config = _read_text("starcat/project.godot")

        self.assertNotIn("TextureBackdrop", main_scene)
        self.assertIn('[node name="PortraitFrame" type="PanelContainer"', main_scene)
        self.assertIn('[node name="CivilizationPortrait" type="TextureRect"', main_scene)
        self.assertIn('theme_override_fonts/font = ExtResource("4_ui_font")', main_scene)
        self.assertNotIn("MAIN_MENU_BACKDROP_PATH", main_source)
        self.assertIn("@onready var civilization_portrait: TextureRect", main_source)
        self.assertIn("InitialData.civilization_visual_bundle", main_source)
        self.assertIn("civilization_portrait.texture = _load_menu_texture", main_source)
        self.assertIn("PANEL_STRONG_TEXTURE_PATH", main_source)
        self.assertIn("func _make_bridge_panel_style(", main_source)
        self.assertIn("StyleBoxTexture.new()", main_source)
        self.assertIn('start_button.add_theme_stylebox_override("normal", _make_bridge_button_style("normal"))', main_source)
        self.assertIn('theme/custom_font="res://assets/fonts/SourceHanSansSC-Regular.otf"', project_config)
        self.assertTrue((ROOT / "starcat/assets/fonts/SourceHanSansSC-Regular.otf").exists())
        self.assertTrue((ROOT / "starcat/assets/fonts/LICENSE_SourceHanSans.txt").exists())
        self.assertIn('"main_menu_backdrop.png"', generator_source)
        self.assertFalse((ROOT / "starcat/assets/ui/menu/main_menu_backdrop.png").exists())
        self.assertFalse((ROOT / "starcat/assets/ui/menu/main_menu_backdrop.png.import").exists())

    def test_ui_texture_assets_have_layered_high_resolution_surfaces(self) -> None:
        from PIL import Image

        expected_bridge_sizes = {
            "button_base.png": (192, 72),
            "button_hover.png": (192, 72),
            "button_pressed.png": (192, 72),
            "button_disabled.png": (192, 72),
            "chip_panel.png": (256, 112),
            "panel_shell.png": (256, 256),
            "panel_shell_strong.png": (256, 256),
            "card_shell.png": (256, 192),
            "card_shell_alert.png": (256, 192),
            "section_title_panel.png": (512, 72),
            "info_line_panel.png": (512, 84),
            "input_panel.png": (640, 240),
            "input_panel_focus.png": (640, 240),
            "tab_active.png": (320, 104),
            "tab_idle.png": (320, 104),
            "divider_glow.png": (1024, 24),
        }

        for name, expected_size in expected_bridge_sizes.items():
            image = Image.open(ROOT / "starcat/assets/ui/bridge" / name).convert("RGBA")
            self.assertEqual(image.size, expected_size, name)
            visible_pixels = [pixel for pixel in _rgba_pixels(image) if pixel[3] > 8]
            self.assertGreaterEqual(len(set(visible_pixels)), 24, name)
            if name.startswith("button_"):
                self.assertEqual(_visible_component_count(image), 1, name)
                blank_safe_columns = [
                    x
                    for x in range(8, image.size[0] - 8)
                    if all(image.getpixel((x, y))[3] <= 8 for y in range(8, image.size[1] - 8))
                ]
                self.assertEqual(blank_safe_columns, [], name)

        menu_divider = Image.open(ROOT / "starcat/assets/ui/menu/main_menu_divider.png").convert("RGBA")
        self.assertEqual(menu_divider.size, (1024, 32))
        self.assertGreaterEqual(len(set(_rgba_pixels(menu_divider))), 48)
        self.assertLess(menu_divider.getpixel((0, 0))[3], 80)

        generator_source = _read_text("starcat/tools/recolor_bridge_ui.py")
        self.assertIn("TARGET_SIZES", generator_source)
        self.assertIn("SOURCE_SHEET_ALPHA", generator_source)
        self.assertIn("def load_generated_sheet(", generator_source)
        self.assertIn("def extract_component(", generator_source)
        self.assertIn("Image.Resampling.LANCZOS", generator_source)

    def test_ui_textures_encode_generated_state_with_transparency_and_depth(self) -> None:
        from PIL import Image

        bridge_dir = ROOT / "starcat/assets/ui/bridge"
        base = _visible_pixels(Image.open(bridge_dir / "button_base.png").convert("RGBA"))
        hover = _visible_pixels(Image.open(bridge_dir / "button_hover.png").convert("RGBA"))
        pressed = _visible_pixels(Image.open(bridge_dir / "button_pressed.png").convert("RGBA"))
        disabled = _visible_pixels(Image.open(bridge_dir / "button_disabled.png").convert("RGBA"))
        tab_active = _visible_pixels(Image.open(bridge_dir / "tab_active.png").convert("RGBA"))
        tab_idle = _visible_pixels(Image.open(bridge_dir / "tab_idle.png").convert("RGBA"))
        card = _visible_pixels(Image.open(bridge_dir / "card_shell.png").convert("RGBA"))
        alert = _visible_pixels(Image.open(bridge_dir / "card_shell_alert.png").convert("RGBA"))
        menu = _visible_pixels(Image.open(ROOT / "starcat/assets/ui/menu/main_menu_divider.png").convert("RGBA"))

        self.assertGreater(_average_alpha(hover), _average_alpha(base) + 2.0)
        self.assertGreater(abs(_average_luminance(pressed) - _average_luminance(base)), 10.0)
        self.assertGreater(_average_alpha(pressed), _average_alpha(base) + 10.0)
        self.assertLess(_average_alpha(disabled), _average_alpha(base) - 40.0)
        self.assertGreater(_orange_ratio(tab_active), 0.010)
        self.assertLess(_orange_ratio(tab_idle), _orange_ratio(tab_active) * 0.80)
        self.assertGreater(_orange_ratio(alert), _orange_ratio(card) + 0.006)
        self.assertGreater(_cool_line_ratio(menu), 0.004)
        self.assertGreater(_orange_ratio(menu), 0.001)

        generator_source = _read_text("starcat/tools/recolor_bridge_ui.py")
        self.assertIn("STATE_TUNING", generator_source)
        self.assertIn("def apply_state_tuning(", generator_source)
        self.assertIn("def write_menu_textures(", generator_source)

    def test_outdated_menu_ui_assets_are_removed(self) -> None:
        removed_assets = [
            "main_menu_panel.png",
            "main_menu_option_row.png",
            "main_menu_start_button.png",
            "main_menu_texture_sheet.png",
        ]
        for name in removed_assets:
            self.assertFalse((ROOT / "starcat/assets/ui/menu" / name).exists(), name)
            self.assertFalse((ROOT / "starcat/assets/ui/menu" / f"{name}.import").exists(), f"{name}.import")

    def test_action_buttons_apply_variant_and_texture_assets(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        action_button_scene = _read_text("starcat/scenes/ui/ActionButton.tscn")

        self.assertIn("_apply_button_variant(button, variant)", hud_source)
        self.assertIn("func _apply_button_variant(button: Button, variant: String) -> void:", hud_source)
        self.assertIn('"primary":', hud_source)
        self.assertIn('"accent":', hud_source)
        self.assertIn('"danger":', hud_source)
        self.assertIn('button.add_theme_color_override("font_color"', hud_source)
        self.assertIn("ResourceLoader.load(texture_path)", hud_source)
        self.assertIn("ResourceLoader.load(texture_path)", _read_text("starcat/scripts/StarMap.gd"))
        self.assertIn('texture = ExtResource("1_base")', action_button_scene)
        self.assertIn('texture = ExtResource("2_hover")', action_button_scene)
        self.assertIn('texture = ExtResource("3_pressed")', action_button_scene)
        self.assertIn('texture = ExtResource("4_disabled")', action_button_scene)
        self.assertIn("texture_margin_left = 12.0", action_button_scene)
        self.assertIn("texture_margin_top = 12.0", action_button_scene)
        self.assertIn("texture_margin_right = 12.0", action_button_scene)
        self.assertIn("texture_margin_bottom = 12.0", action_button_scene)
        self.assertIn("content_margin_top = 9.0", action_button_scene)
        self.assertIn("content_margin_bottom = 5.0", action_button_scene)
        self.assertIn("custom_minimum_size = Vector2(128, 46)", action_button_scene)
        self.assertIn("theme_override_font_sizes/font_size = 15", action_button_scene)

    def test_cat_civilization_assets_are_imported_into_workspace(self) -> None:
        expected_assets = [
            "starcat/assets/factions/cats/portraits/russian_blue_command.png",
            "starcat/assets/factions/cats/portraits/ragdoll_diplomatic.png",
            "starcat/assets/factions/cats/portraits/bengal_tactical.png",
            "starcat/assets/factions/cats/portraits/maine_coon_imperial.png",
            "starcat/assets/factions/cats/portraits/black_cat_stealth.png",
            "starcat/assets/factions/cats/portraits/orange_tabby_industrial.png",
            "starcat/assets/factions/cats/ships/russian_blue_command.png",
            "starcat/assets/factions/cats/ships/ragdoll_diplomatic.png",
            "starcat/assets/factions/cats/ships/bengal_tactical.png",
            "starcat/assets/factions/cats/ships/maine_coon_imperial.png",
            "starcat/assets/factions/cats/ships/black_cat_stealth.png",
            "starcat/assets/factions/cats/ships/orange_tabby_industrial.png",
            "starcat/assets/factions/cats/emblems/russian_blue_command.png",
            "starcat/assets/factions/cats/emblems/ragdoll_diplomatic.png",
            "starcat/assets/factions/cats/emblems/bengal_tactical.png",
            "starcat/assets/factions/cats/emblems/maine_coon_imperial.png",
            "starcat/assets/factions/cats/emblems/black_cat_stealth.png",
            "starcat/assets/factions/cats/emblems/orange_tabby_industrial.png",
        ]

        for relative_path in expected_assets:
            self.assertTrue((ROOT / relative_path).exists(), relative_path)

    def test_cat_civilization_visuals_are_wired_into_data_and_cards(self) -> None:
        initial_data = _read_text("starcat/scripts/data/InitialData.gd")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        diplomacy_scene = _read_text("starcat/scenes/ui/DiplomacyFactionCard.tscn")
        fleet_scene = _read_text("starcat/scenes/ui/FleetShipCard.tscn")
        feed_scene = _read_text("starcat/scenes/ui/FeedCard.tscn")
        proposal_scene = _read_text("starcat/scenes/ui/ProposalCard.tscn")
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('static func civilization_visual_bundle(visual_id: String) -> Dictionary:', initial_data)
        self.assertIn('"visualId": "russian_blue_command"', initial_data)
        self.assertIn('"visualId": "ragdoll_diplomatic"', initial_data)
        self.assertIn('"visualId": "orange_tabby_industrial"', initial_data)
        self.assertIn('"portraitPath"', initial_data)
        self.assertIn('"shipArtPaths"', initial_data)
        self.assertNotIn('猫文明档案', hud_source)
        self.assertIn('func _make_civilization_showcase_card(template: Dictionary) -> PanelContainer:', hud_source)
        self.assertIn('@onready var player_portrait: TextureRect = $Root/PlayerIdentity/Content/Portrait', hud_source)
        self.assertIn('_apply_texture(card.get_node("Content/Header/Portrait"), portrait_path)', hud_source)
        self.assertIn('_apply_texture(card.get_node("Content/ShipPreview"), ship_path)', hud_source)
        self.assertIn('[node name="Portrait" type="TextureRect" parent="Content/Header"]', diplomacy_scene)
        self.assertIn('[node name="Emblem" type="TextureRect" parent="Content/Header"]', diplomacy_scene)
        self.assertIn('[node name="ShipPreview" type="TextureRect" parent="Content"]', diplomacy_scene)
        self.assertIn('[node name="ShipPreview" type="TextureRect" parent="Content"]', fleet_scene)
        self.assertIn('[node name="Thumbnail" type="TextureRect" parent="Content/Header"]', feed_scene)
        self.assertIn('[node name="Portrait" type="TextureRect" parent="Content/Header"]', proposal_scene)
        self.assertIn('[node name="Emblem" type="TextureRect" parent="Content/Header"]', proposal_scene)
        self.assertIn('[node name="PlayerIdentity" type="PanelContainer" parent="Root"]', _read_text("starcat/scenes/HudLayer.tscn"))
        self.assertIn('[node name="Portrait" type="TextureRect" parent="Root/PlayerIdentity/Content"]', _read_text("starcat/scenes/HudLayer.tscn"))
        self.assertNotIn('func _make_faction_emblem_sprite(', star_map_source)
        self.assertNotIn('body.add_child(owner_emblem)', star_map_source)
        self.assertNotIn('marker.add_child(fleet_emblem)', star_map_source)

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

    def test_minimal_monochrome_icons_are_installed_and_wired(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        expected_icons = [
            "objectives",
            "food",
            "minerals",
            "industry",
            "energy",
            "fleet",
            "health",
            "damage",
            "cooldown",
            "route",
            "mission",
            "research",
            "diplomacy",
            "comms",
            "system",
        ]

        self.assertIn("const UI_ICON_PATHS: Dictionary = {", hud_source)
        self.assertIn("func _apply_button_icon(button: Button, icon_key: String) -> void:", hud_source)
        self.assertIn("func _make_icon_texture(icon_key: String, size: Vector2 = Vector2(18, 18)) -> TextureRect:", hud_source)
        self.assertIn("func _make_icon_stat_grid(entries: Array[Dictionary]) -> GridContainer:", hud_source)
        self.assertIn("func _make_icon_stat_entry(icon_key: String, label: String, value: String) -> Dictionary:", hud_source)
        for icon_name in expected_icons:
            icon_path = ROOT / "starcat" / "assets" / "ui" / "icons" / f"{icon_name}.svg"
            icon_text = icon_path.read_text(encoding="utf-8")
            self.assertIn(f'"{icon_name}"', hud_source)
            self.assertIn("<svg", icon_text)
            self.assertIn("#FFFFFF", icon_text)
            sanitized_icon_text = icon_text.replace("#FFFFFF", "").replace("#ffffff", "")
            self.assertNotIn("#", sanitized_icon_text)

    def test_bottom_tabs_and_drawer_use_icon_first_navigation(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        main_scene = _read_text("starcat/scenes/Main.tscn")

        self.assertIn('const TAB_ICON_KEYS: Dictionary = {', hud_source)
        self.assertIn('"OBJECTIVES": "objectives"', hud_source)
        self.assertIn('"TECH": "research"', hud_source)
        self.assertIn('"DIPLOMACY": "diplomacy"', hud_source)
        self.assertIn('"COMMS": "comms"', hud_source)
        self.assertIn('_apply_button_icon(button, str(TAB_ICON_KEYS.get(tab_name, "")))', hud_source)
        self.assertIn('_configure_tab_button(objectives_button, "OBJECTIVES", GameState.active_tab == "OBJECTIVES")', hud_source)
        self.assertIn('_configure_tab_button(communications_button, "COMMS", GameState.active_tab == "COMMS")', hud_source)
        self.assertIn('button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER', hud_source)
        self.assertIn('button.expand_icon = true', hud_source)

        self.assertIn('text = "通信"', hud_scene)
        self.assertNotIn('text = "通讯中心"', hud_scene)
        self.assertIn('visible = false', hud_scene.split('[node name="DrawerSubtitle" type="Label"', 1)[1].split("[node name=", 1)[0])
        self.assertNotIn("通过底部导航切换不同系统面板", hud_scene)
        self.assertNotIn('drawer_subtitle.text = "查看舰队状态、航线与作战选项。"', hud_source)
        self.assertNotIn('drawer_subtitle.text = "查看资源、建筑与殖民状态。"', hud_source)
        self.assertIn('drawer_subtitle.visible = false', hud_source)
        self.assertNotIn("选择文明、星图规模与 AI 压力", main_scene)

    def test_fleet_panel_groups_actions_into_task_movement_and_support(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('_panel_add(_make_section_title("指令"))', hud_source)
        self.assertIn('_panel_add(_make_section_title("航线"))', hud_source)
        self.assertIn('func _make_action_grid(buttons: Array[Button], columns: int = 2) -> GridContainer:', hud_source)
        self.assertIn('button.custom_minimum_size = Vector2(0, 46)', hud_source)
        self.assertIn('_panel_add(_make_icon_stat_grid([', hud_source)
        self.assertIn('_make_icon_stat_entry("fleet", "舰船", str(fleet.get("ships", []).size()))', hud_source)
        self.assertIn('_make_icon_stat_entry("route", "航线", str(reachable_routes.size()))', hud_source)
        self.assertIn('_make_action_button("移动"', hud_source)
        self.assertIn('_make_action_button("取消"', hud_source)
        self.assertIn('_make_action_button("修复"', hud_source)
        self.assertIn('_make_action_button("合并"', hud_source)
        self.assertIn('start_move_button.disabled = move_mode_active', hud_source)
        self.assertIn('cancel_move_button.disabled = not move_mode_active', hud_source)
        self.assertIn('repair_button.disabled = total_hp >= total_max_hp', hud_source)
        self.assertIn('var fleet_is_colonizing: bool = str(fleet.get("mission", "IDLE")) == "COLONIZING"', hud_source)
        self.assertIn('start_move_button.disabled = move_mode_active or fleet_is_colonizing or int(fleet.get("movementCooldown", 0)) > 0 or reachable_routes.is_empty()', hud_source)
        self.assertIn('start_move_button.tooltip_text = "殖民部署中"', hud_source)
        self.assertIn('start_move_button.tooltip_text = "冷却中"', hud_source)
        self.assertIn('start_move_button.tooltip_text = "无航线"', hud_source)
        self.assertIn('cancel_move_button.tooltip_text = "未启用"', hud_source)
        self.assertIn('repair_button.tooltip_text = "满状态"', hud_source)
        self.assertIn('split_button.disabled = fleet_is_colonizing or fleet.get("ships", []).size() < 2', hud_source)
        self.assertIn('split_button.tooltip_text = "舰船不足"', hud_source)
        self.assertIn('merge_button.disabled = fleet_is_colonizing or GameState.get_player_fleets_in_system(str(fleet.get("systemId", ""))).size() < 2', hud_source)
        self.assertIn('merge_button.tooltip_text = "无可合并舰队"', hud_source)
        self.assertNotIn('status_button', hud_source)
        self.assertNotIn('_panel_add(_make_status_card("当前建议"', hud_source)
        self.assertNotIn('func _fleet_action_hint', hud_source)
        self.assertNotIn('_panel_add(_make_info_card([', hud_source.split('func _build_fleet_panel', 1)[1].split('func _make_building_card', 1)[0])
        self.assertNotIn('_panel_add(_make_status_card("任务状态"', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("任务"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("移动"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("后勤维护"))', hud_source)

    def test_runtime_capture_path_opens_real_global_tab_modals(self) -> None:
        main_source = _read_text("starcat/scripts/Main.gd")
        gitignore = _read_text(".gitignore")

        self.assertIn('if hud_layer.has_method("_on_tab_pressed"):', main_source)
        self.assertIn('await _save_capture("runtime_game_overview.png")', main_source)
        self.assertIn('hud_layer.call("_on_tab_pressed", "OBJECTIVES")', main_source)
        self.assertIn('hud_layer.call("_on_tab_pressed", "COMMS")', main_source)
        self.assertNotIn('GameState.set_active_tab("COMMS")', main_source)
        self.assertIn('if DisplayServer.get_name() == "headless":', main_source)
        self.assertIn('await get_tree().process_frame', main_source)
        self.assertIn('await RenderingServer.frame_post_draw', main_source)
        self.assertIn("Image.create(16, 16, false, Image.FORMAT_RGBA8)", main_source)
        self.assertIn("image.fill(Color(0.02, 0.04, 0.08, 1.0))", main_source)
        self.assertIn("runtime_captures/", gitignore)

    def test_star_map_uses_channel_based_label_avoidance(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('var fleet_counts_by_system: Dictionary = {}', star_map_source)
        self.assertIn('var fleet_slot: int = int(fleet_counts_by_system.get(system_id, 0))', star_map_source)
        self.assertIn('const SYSTEM_LABEL_CHANNELS: Array[Vector3] = [', star_map_source)
        self.assertIn('const FLEET_LABEL_CHANNELS: Array[Vector3] = [', star_map_source)
        self.assertIn('var label_channel: int = _label_channel_for_id(str(system.get("id", "")), SYSTEM_LABEL_CHANNELS.size())', star_map_source)
        self.assertIn('var fleet_channel: int = _label_channel_for_id(system_id, FLEET_LABEL_CHANNELS.size())', star_map_source)
        self.assertIn('body.add_child(_make_label(str(system.get("name", "")), _system_label_offset(false, label_channel)))', star_map_source)
        self.assertIn('if GameState.labels_visible and _should_show_fleet_label(fleet):', star_map_source)
        self.assertIn('marker.add_child(_make_label(_compact_label_text(str(fleet.get("name", "")), 10), _fleet_label_offset(fleet_slot, fleet_channel), true))', star_map_source)
        self.assertIn('func _system_label_offset(compact: bool = false, channel: int = 0) -> Vector3:', star_map_source)
        self.assertIn('func _fleet_label_offset(slot: int, channel: int = 0) -> Vector3:', star_map_source)
        self.assertIn('func _should_show_fleet_label(fleet: Dictionary) -> bool:', star_map_source)
        self.assertIn('return str(fleet.get("ownerId", "")) == GameState.PLAYER_FACTION_ID or str(fleet.get("id", "")) == GameState.selected_fleet_id', star_map_source)
        self.assertIn('func _label_channel_for_id(source_id: String, channel_count: int) -> int:', star_map_source)
        self.assertIn('func _compact_label_text(text: String, max_length: int) -> String:', star_map_source)

    def test_star_map_supports_click_to_move_when_fleet_move_mode_is_active(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('if GameState.try_move_selected_fleet_to_system(system_id):', star_map_source)
        self.assertIn('func begin_fleet_move_mode(fleet_id: String = "") -> void:', game_state_source)
        self.assertIn('func cancel_fleet_move_mode() -> void:', game_state_source)
        self.assertIn('func try_move_selected_fleet_to_system(system_id: String) -> bool:', game_state_source)
        self.assertIn('func focus_system(system_id: String) -> void:', game_state_source)
        self.assertIn('var fleet_move_mode: bool = false', game_state_source)
        self.assertIn('func select_system(system_id: String) -> void:\n\tif try_move_selected_fleet_to_system(system_id):\n\t\treturn\n\tselected_system_id = system_id\n\tselected_fleet_id = ""\n\tfleet_move_mode = false', game_state_source)
        self.assertIn('func focus_system(system_id: String) -> void:\n\tselected_system_id = system_id\n\tselected_fleet_id = ""\n\tfleet_move_mode = false', game_state_source)

    def test_fleet_route_buttons_separate_viewing_from_executing_movement(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('_make_action_button("查看%s" % system.get("name", system_id), GameState.focus_system.bind(system_id), "neutral")', hud_source)
        self.assertIn('func focus_system(system_id: String) -> void:\n\tselected_system_id = system_id\n\tselected_fleet_id = ""\n\tfleet_move_mode = false', game_state_source)
        self.assertIn('func _on_action_button_pressed(callable: Callable) -> void:\n\tAudioManager.play_event("ui_tick")\n\tcallable.call()\n\tcall_deferred("_refresh_visible_panels")', hud_source)
        self.assertIn('var route_buttons: Array[Button] = [', hud_source)
        self.assertIn('route_buttons.append(scout_button)', hud_source)
        self.assertIn('_panel_add(_make_action_grid(route_buttons, 2))', hud_source)
        self.assertIn('_make_action_button("跃迁至此", GameState.move_selected_fleet.bind(system_id), "primary")', hud_source)
        self.assertNotIn('GameState.select_system.bind(system_id)', hud_source)
        self.assertIn('var moved_successfully: bool = updated_system_id != "" and updated_system_id != previous_system_id', game_state_source)
        self.assertIn('if moved_successfully:', game_state_source)
        self.assertIn('fleet_move_mode = false', game_state_source)
        self.assertIn('if str(fleet.get("mission", "IDLE")) == "COLONIZING":', game_state_source)
        self.assertIn('var can_jump: bool = not fleet_is_colonizing and fits_bandwidth and int(fleet.get("movementCooldown", 0)) <= 0 and player_energy >= traversal_cost', hud_source)
        self.assertIn('jump_button.disabled = not can_jump', hud_source)
        self.assertIn('jump_button.tooltip_text = "殖民部署中"', hud_source)
        self.assertIn('jump_button.tooltip_text = "当前航道容量不足，舰队规模超出上限。"', hud_source)
        self.assertIn('jump_button.tooltip_text = "舰队仍在移动冷却中。"', hud_source)
        self.assertIn('jump_button.tooltip_text = "能源不足，无法支付本次跃迁消耗。"', hud_source)

    def test_destroyed_selected_fleet_clears_selection_after_actions(self) -> None:
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('func _clear_selected_fleet() -> void:', game_state_source)
        self.assertIn('if selected_fleet.is_empty():\n\t\treturn {}', game_state_source)
        self.assertIn('func select_fleet(fleet_id: String) -> void:\n\tvar fleet: Dictionary = get_fleet_by_id(fleet_id)\n\tif fleet.is_empty():', game_state_source)
        self.assertIn('if selected_fleet.is_empty():\n\t\t_clear_selected_fleet()\n\t\tselection_changed.emit(selected_system_id, selected_fleet_id)\n\t\treturn false', game_state_source)
        self.assertIn('var moving_fleet_id: String = selected_fleet_id', game_state_source)
        self.assertIn('var updated_fleet: Dictionary = get_fleet_by_id(moving_fleet_id)', game_state_source)
        self.assertIn('if updated_fleet.is_empty():', game_state_source)
        self.assertIn('_clear_selected_fleet()\n\t\tstate_changed.emit(game_state)\n\t\tselection_changed.emit(selected_system_id, selected_fleet_id)', game_state_source)
        self.assertIn('var attacking_fleet_id: String = selected_fleet_id', game_state_source)
        self.assertIn('var updated_attacker: Dictionary = get_fleet_by_id(attacking_fleet_id)', game_state_source)
        self.assertIn('if updated_attacker.is_empty():\n\t\t_clear_selected_fleet()\n\telse:\n\t\tselected_system_id = str(updated_attacker.get("systemId", selected_system_id))', game_state_source)

    def test_explore_system_requires_fleet_at_target_before_resolving_rewards(self) -> None:
        game_logic_source = _read_text("starcat/scripts/GameLogic.gd")

        self.assertIn('var fleet_at_target: bool = str(fleet.get("systemId", "")) == system_id', game_logic_source)
        self.assertIn('if not fleet_at_target and not connected_to(next_state, str(fleet.get("systemId", ""))).has(system_id):', game_logic_source)
        self.assertIn('if not fleet_at_target:\n\t\treturn _scout_adjacent_system(next_state, fleet, system_id)', game_logic_source)
        self.assertIn('static func _scout_adjacent_system(state: Dictionary, fleet: Dictionary, system_id: String) -> Dictionary:', game_logic_source)
        explore_body = game_logic_source.split('static func explore_system', 1)[1].split('static func refresh_player_visibility', 1)[0]
        self.assertIn('next_state = resolve_player_system_event(next_state, system_id)', explore_body)
        self.assertIn('if not fleet_at_target:', explore_body)

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
        self.assertIn('"宪章: %s / 支持 %s/%s" % [', hud_source)
        self.assertNotIn('"通信截获状态: %s" % _interception_status_label(str(interception_report.get("status", "UNKNOWN")))', hud_source)
        self.assertIn('"战备状态: %s" % _fleet_readiness_label(str(fleet_status_report.get("readiness", "CRITICAL")))', hud_source)
        self.assertIn('"T%s / %s" % [str(entry.get("turn", GameState.game_state.get("turn", 1))), _message_type_label(str(entry.get("category", "EVENT")))]', hud_source)
        self.assertIn('"fleet_status_fleet_id": fleet_id,', api_source)
        self.assertIn('var fleet_status_fleet_id: String = str(GameState.world_data.get("fleet_status_fleet_id", ""))', hud_source)
        self.assertIn('_panel_add(_make_api_report_card(', hud_source)
        self.assertIn('"状态评估"', hud_source)
        self.assertIn('if GameState.active_tab == "DIPLOMACY" or GameState.active_tab == "COMMS" or GameState.selected_fleet_id != "" or GameState.selected_system_id != "":', hud_source)

    def test_communications_panel_uses_single_chronological_timeline(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertNotIn('"当前摘要"', hud_source)
        self.assertNotIn('"系统消息: %s" % str(GameState.game_state.get("messages", []).size() + recent_reports.size())', hud_source)
        self.assertNotIn('"外交通信: %s" % str(visible_messages.size() + (0 if GameState.diplomatic_message.is_empty() else 1))', hud_source)
        self.assertNotIn('"待处理提案: %s" % str(pending_proposals.size())', hud_source)
        self.assertIn('_panel_add(_make_section_title("重要时间线"))', hud_source)
        self.assertIn('var timeline_entries: Array = GameState.get_recent_intelligence_feed()', hud_source)
        self.assertIn('var seen_timeline_keys: Dictionary = {}', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("系统消息"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("外交通信"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("提案"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("短期记忆"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("长期归档"))', hud_source)
        self.assertNotIn('_panel_add(_make_section_title("通信记录"))', hud_source)

    def test_decision_iteration_service_models_research_artifacts(self) -> None:
        service_source = _read_text("starcat/scripts/services/DecisionIterationService.gd")

        self.assertIn('class_name DecisionIterationService', service_source)
        self.assertIn('const ARTIFACT_TURN_SNAPSHOT := "TurnSnapshot"', service_source)
        self.assertIn('const ARTIFACT_DECISION_RECORD := "DecisionRecord"', service_source)
        self.assertIn('const ARTIFACT_TRIAL_RECORD := "TrialRecord"', service_source)
        self.assertIn('const ARTIFACT_PATCH_RECORD := "PatchRecord"', service_source)
        self.assertIn('const ARTIFACT_TEST_CASE := "TestCase"', service_source)
        self.assertIn('func build_turn_snapshot(game_state: Dictionary, perspective_faction_id: String = "f_player", game_id: String = DEFAULT_GAME_ID) -> Dictionary:', service_source)
        self.assertIn('func build_decision_record(snapshot: Dictionary, decision: Dictionary, provider_payload: Dictionary = {}, playbook_id: String = "strategist_v0", tools_called: Array = []) -> Dictionary:', service_source)
        self.assertIn('func evaluate_transition(before_snapshot: Dictionary, after_snapshot: Dictionary) -> Dictionary:', service_source)
        self.assertIn('func build_patch_record(parent_sha: String, diff: String, root_cause: String, tests_added: Array, metadata: Dictionary = {}) -> Dictionary:', service_source)
        self.assertIn('func build_test_case(test_id: String, savegame: String, assertions: Array, metadata: Dictionary = {}) -> Dictionary:', service_source)
        self.assertIn('func build_trial_record(game_id: String, snapshots: Array, decisions: Array, evaluations: Array, metadata: Dictionary = {}) -> Dictionary:', service_source)
        self.assertIn('func validate_record(record: Dictionary) -> Dictionary:', service_source)
        self.assertIn('func build_artifact_bundle(records: Array, metadata: Dictionary = {}) -> Dictionary:', service_source)
        self.assertIn('func jsonl_line(record: Dictionary) -> String:', service_source)
        self.assertIn('func append_jsonl(record: Dictionary, path: String = DEFAULT_JSONL_PATH) -> Dictionary:', service_source)
        self.assertIn('func append_jsonl_records(records: Array, path: String = DEFAULT_JSONL_PATH) -> Dictionary:', service_source)
        self.assertIn('FileAccess.open(path, FileAccess.READ_WRITE)', service_source)
        self.assertIn('file.seek_end()', service_source)
        self.assertIn('player_victory_progress_report', service_source)
        self.assertIn('strategic_posture_report', service_source)
        self.assertIn('recent_intelligence_feed', service_source)
        self.assertIn('"features23"', service_source)
        self.assertIn('"vp_t"', service_source)
        for feature_key in [
            '"turn"',
            '"owned_systems"',
            '"visible_systems"',
            '"unowned_visible_systems"',
            '"fleets"',
            '"fleet_power"',
            '"food"',
            '"minerals"',
            '"industry"',
            '"energy"',
            '"food_net"',
            '"minerals_net"',
            '"industry_net"',
            '"energy_net"',
            '"active_treaties"',
            '"pending_proposals"',
            '"war_count"',
            '"military_progress"',
            '"diplomacy_votes"',
            '"science_progress"',
            '"high_pressure_count"',
            '"high_opportunity_count"',
            '"status_code"',
        ]:
            self.assertIn(feature_key, service_source)
        self.assertNotIn("OS.execute", service_source)
        self.assertNotIn("remove_absolute", service_source)
        self.assertNotIn("apply_patch", service_source)

    def test_api_client_exposes_decision_iteration_snapshot_without_provider(self) -> None:
        api_source = _read_text("starcat/scripts/autoload/ApiClient.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('preload("res://scripts/services/DecisionIterationService.gd")', api_source)
        self.assertIn('var _iteration_service', api_source)
        self.assertIn('_iteration_service = DecisionIterationServiceScript.new()', api_source)
        self.assertIn('func request_decision_iteration_snapshot(game_state: Dictionary, perspective_faction_id: String = "f_player", game_id: String = "starcat_local") -> void:', api_source)
        self.assertIn('"decision_iteration_snapshot": _iteration_service.build_turn_snapshot(game_state, perspective_faction_id, game_id)', api_source)
        self.assertIn('func request_decision_iteration_record(snapshot: Dictionary, decision: Dictionary, provider_payload: Dictionary = {}, playbook_id: String = "strategist_v0", tools_called: Array = []) -> void:', api_source)
        self.assertIn('"decision_iteration_record": _iteration_service.build_decision_record(snapshot, decision, provider_payload, playbook_id, tools_called)', api_source)
        self.assertIn('func request_decision_transition_evaluation(before_snapshot: Dictionary, after_snapshot: Dictionary) -> void:', api_source)
        self.assertIn('"decision_iteration_evaluation": _iteration_service.evaluate_transition(before_snapshot, after_snapshot)', api_source)
        self.assertIn('func request_decision_artifact_write(record: Dictionary, path: String = "user://decision_iterations/records.jsonl") -> void:', api_source)
        self.assertIn('"decision_iteration_write": _iteration_service.append_jsonl(record, path)', api_source)
        self.assertIn('func request_decision_trial_record(game_id: String, snapshots: Array, decisions: Array, evaluations: Array, metadata: Dictionary = {}) -> void:', api_source)
        self.assertIn('"decision_iteration_trial": _iteration_service.build_trial_record(game_id, snapshots, decisions, evaluations, metadata)', api_source)
        self.assertIn('func request_decision_iteration_snapshot() -> void:', game_state_source)
        self.assertIn('ApiClient.request_decision_iteration_snapshot(game_state, PLAYER_FACTION_ID)', game_state_source)

    def test_decision_iteration_design_doc_maps_report_to_implementation(self) -> None:
        doc_source = _read_text("docs/design/09_llm_decision_iteration_system.md")

        self.assertIn("Game Adapter -> State Briefer -> Router -> Playbook Library", doc_source)
        self.assertIn("TurnSnapshot", doc_source)
        self.assertIn("DecisionRecord", doc_source)
        self.assertIn("PatchRecord", doc_source)
        self.assertIn("TrialRecord", doc_source)
        self.assertIn("Regression Harness", doc_source)
        self.assertIn("DecisionIterationService.gd", doc_source)
        self.assertIn("JSONL", doc_source)

    def test_cat_asset_importer_uses_portable_source_argument(self) -> None:
        importer_source = _read_text("starcat/tools/import_cat_civilization_assets.py")

        self.assertIn("argparse", importer_source)
        self.assertIn("--source-image", importer_source)
        self.assertIn("STARCAT_CAT_SOURCE_IMAGE", importer_source)
        self.assertIn("def _resolve_source_image", importer_source)
        self.assertNotIn("C:\\\\Users\\\\tsc29", importer_source)

    def test_runtime_smoke_test_covers_core_gameplay_loop(self) -> None:
        smoke_source = _read_text("starcat/tools/runtime_smoke_test.gd")

        self.assertIn("InitialDataScript.create_initial_state(configured_options)", smoke_source)
        self.assertIn('GameLogicScript.explore_system(state, "fleet_player_1", "sys_polaris")', smoke_source)
        self.assertIn('GameLogicScript.move_fleet(state, "fleet_player_1", "sys_polaris")', smoke_source)
        self.assertIn('GameLogicScript.start_research(state, "tech_deep_colonization")', smoke_source)
        self.assertIn("GameLogicScript.process_turn(state)", smoke_source)
        self.assertIn('GameLogicScript.colonization_preview(state, "fleet_player_1", "sys_polaris", "STANDARD")', smoke_source)
        self.assertIn('GameLogicScript.colonize_system(state, "fleet_player_1", "sys_polaris", "STANDARD")', smoke_source)
        self.assertIn("DecisionIterationServiceScript.new()", smoke_source)
        self.assertIn("build_turn_snapshot", smoke_source)
        self.assertIn("build_decision_record", smoke_source)
        self.assertIn("evaluate_transition", smoke_source)
        self.assertIn("build_trial_record", smoke_source)
        self.assertIn("player_victory_progress_report", smoke_source)
        self.assertIn("STARCAT_RUNTIME_SMOKE_OK", smoke_source)

    def test_complete_game_loop_setup_and_ai_are_wired(self) -> None:
        initial_data = _read_text("starcat/scripts/data/InitialData.gd")
        game_state = _read_text("starcat/scripts/autoload/GameState.gd")
        game_logic = _read_text("starcat/scripts/GameLogic.gd")
        main_scene = _read_text("starcat/scenes/Main.tscn")
        main_source = _read_text("starcat/scripts/Main.gd")
        smoke_source = _read_text("starcat/tools/runtime_smoke_test.gd")

        self.assertIn("static func default_game_setup_options() -> Dictionary:", initial_data)
        self.assertIn("static func map_scale_presets() -> Dictionary:", initial_data)
        self.assertIn("static func difficulty_presets() -> Dictionary:", initial_data)
        self.assertIn("static func normalize_game_setup_options(options: Dictionary) -> Dictionary:", initial_data)
        self.assertIn("static func create_initial_state(options: Dictionary = {}) -> Dictionary:", initial_data)
        self.assertIn('"SKIRMISH": {"system_count": 10, "hyperlane_count": 10', initial_data)
        self.assertIn('"STANDARD": {"system_count": 18, "hyperlane_count": 22', initial_data)
        self.assertIn('"GRAND": {"system_count": 26, "hyperlane_count": 32', initial_data)
        self.assertIn("_build_configured_star_systems", initial_data)
        self.assertIn("_build_configured_hyperlanes", initial_data)
        self.assertIn("_procedural_outer_system", initial_data)
        self.assertIn("_build_procedural_hyperlane", initial_data)
        self.assertIn("_sorted_nearby_lane_candidates", initial_data)
        self.assertIn("_lane_distance_score", initial_data)
        self.assertIn("start_position.distance_squared_to(end_position)", initial_data)
        self.assertIn("distance_squared *= 2.4", initial_data)
        self.assertIn("_build_configured_ai_factions", initial_data)
        self.assertIn("_apply_difficulty_to_faction", initial_data)
        self.assertIn('"setupOptions"', initial_data)

        self.assertIn("func start_new_game(options: Dictionary) -> void:", game_state)
        self.assertIn("InitialDataScript.normalize_game_setup_options(options)", game_state)
        self.assertIn("InitialDataScript.create_initial_state(normalized_options)", game_state)

        self.assertIn("static func append_ai_action_record(state: Dictionary, faction_id: String, action_type: String, target_id: String, summary: String) -> Dictionary:", game_logic)
        self.assertIn('"aiActionLog"', game_logic)
        self.assertIn('"AI_ACTION"', game_logic)
        self.assertIn("static func process_configured_ai_turns(state: Dictionary) -> Dictionary:", game_logic)
        self.assertIn("next_state = process_configured_ai_turns(next_state)", game_logic)
        self.assertIn('"COLONY_STARTED"', game_logic)
        self.assertIn('"FLEET_PRESSURE"', game_logic)
        self.assertIn('"ECONOMIC_BUILD"', game_logic)
        self.assertIn('"DIPLOMATIC_SIGNAL"', game_logic)

        self.assertIn('[node name="MainMenuLayer" type="CanvasLayer" parent="."]', main_scene)
        self.assertIn('[node name="CivilizationOption" type="OptionButton"', main_scene)
        self.assertIn('[node name="MapScaleOption" type="OptionButton"', main_scene)
        self.assertIn('[node name="DifficultyOption" type="OptionButton"', main_scene)
        self.assertIn('[node name="OpponentCountOption" type="OptionButton"', main_scene)
        self.assertIn('[node name="StartButton" type="Button"', main_scene)
        self.assertIn('[node name="PreviewPanel" type="PanelContainer"', main_scene)
        self.assertIn('[node name="PortraitFrame" type="PanelContainer"', main_scene)
        self.assertIn('[node name="CivilizationPortrait" type="TextureRect"', main_scene)
        self.assertNotIn('[node name="TextureBackdrop" type="TextureRect"', main_scene)
        self.assertIn('[node name="LeaderValue" type="Label"', main_scene)
        self.assertIn('[node name="FocusValue" type="Label"', main_scene)
        self.assertIn('[node name="TraitValue" type="Label"', main_scene)
        self.assertIn('[node name="SetupSummary" type="Label"', main_scene)
        self.assertIn("@onready var main_menu_layer: CanvasLayer = $MainMenuLayer", main_source)
        self.assertIn("func _populate_main_menu_options() -> void:", main_source)
        self.assertIn("func _apply_main_menu_textures() -> void:", main_source)
        self.assertIn("func _update_main_menu_preview() -> void:", main_source)
        self.assertIn("func _refresh_opponent_options_for_scale() -> void:", main_source)
        self.assertIn("civilization_option.item_selected.connect", main_source)
        self.assertIn("map_scale_option.item_selected.connect", main_source)
        self.assertIn("difficulty_option.item_selected.connect", main_source)
        self.assertIn("opponent_count_option.item_selected.connect", main_source)
        self.assertIn("InitialData.civilization_visual_bundle", main_source)
        self.assertIn("civilization_portrait.texture = _load_menu_texture", main_source)
        self.assertIn("setup_summary.text =", main_source)
        self.assertIn("func _load_menu_texture(texture_path: String) -> Texture2D:", main_source)
        self.assertIn('Image.load_from_file(absolute_path)', main_source)
        menu_texture_loader_block = main_source.split("func _load_menu_texture(texture_path: String) -> Texture2D:", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("var texture: Texture2D = ResourceLoader.load(texture_path) as Texture2D", menu_texture_loader_block)
        self.assertIn('if texture == null and texture_path.begins_with("res://") and texture_path.to_lower().ends_with(".png"):', menu_texture_loader_block)
        self.assertLess(
            menu_texture_loader_block.index("ResourceLoader.load(texture_path)"),
            menu_texture_loader_block.index("Image.load_from_file(absolute_path)"),
        )
        self.assertIn("func _make_bridge_panel_style(texture_path: String, texture_margin: float, content_margin: Vector4) -> StyleBoxTexture:", main_source)
        self.assertIn("func _make_bridge_button_style(state: String = \"normal\") -> StyleBoxTexture:", main_source)
        self.assertNotIn("MAIN_MENU_BACKDROP_PATH", main_source)
        self.assertIn('const MAIN_MENU_DIVIDER_PATH: String = "res://assets/ui/menu/main_menu_divider.png"', main_source)
        self.assertIn('const PANEL_STRONG_TEXTURE_PATH: String = "res://assets/ui/bridge/panel_shell_strong.png"', main_source)
        self.assertIn("menu_divider.texture = _load_menu_texture(MAIN_MENU_DIVIDER_PATH)", main_source)
        self.assertIn('start_button.add_theme_stylebox_override("hover", _make_bridge_button_style("hover"))', main_source)
        self.assertIn('start_button.add_theme_stylebox_override("pressed", _make_bridge_button_style("pressed"))', main_source)
        self.assertNotIn("main_menu_panel.png", main_source)
        self.assertNotIn("main_menu_option_row.png", main_source)
        self.assertIn("_set_game_layers_visible(false)", main_source)
        self.assertIn("func _on_start_button_pressed() -> void:", main_source)
        self.assertIn("GameState.start_new_game(options)", main_source)
        self.assertIn('await _save_capture("runtime_main_menu.png")', main_source)
        self.assertIn('"map_scale": "GRAND"', smoke_source)
        self.assertIn('InitialDataScript.create_initial_state(configured_options)', smoke_source)
        self.assertIn('state.get("aiActionLog", []).size() > 0', smoke_source)

    def test_configured_game_spaces_ai_starting_capitals_away_from_player(self) -> None:
        initial_data = _read_text("starcat/scripts/data/InitialData.gd")

        self.assertIn("const MIN_PLAYER_STARTING_CAPITAL_DISTANCE: float = 16.0", initial_data)
        self.assertIn('static func _preferred_ai_capital_ids() -> Array[String]:', initial_data)
        self.assertIn('return ["sys_draco", "sys_orion", "sys_pegasus", "sys_mira", "sys_antares"]', initial_data)
        self.assertIn('static func _spaced_ai_capital_ids(systems: Array, opponent_count: int) -> Array[String]:', initial_data)
        self.assertIn('player_position.distance_to(candidate_position) >= MIN_PLAYER_STARTING_CAPITAL_DISTANCE', initial_data)
        self.assertIn('var capital_ids: Array[String] = _spaced_ai_capital_ids(state.get("starSystems", []), int(options.get("opponent_count", 2)))', initial_data)
        self.assertNotIn('var capital_ids: Array = ["sys_sirius", "sys_orion", "sys_draco", "sys_hydra", "sys_antares"]', initial_data)
        self.assertIn('if _is_ai_runtime_id(str(system.get("ownerId", ""))):', initial_data)
        self.assertIn('system["ownerId"] = null', initial_data)

    def test_audio_assets_are_installed_with_cc0_license(self) -> None:
        expected_assets = [
            "ui_tick.ogg",
            "ui_confirm.ogg",
            "ui_panel.ogg",
            "fleet_select.ogg",
            "fleet_move.ogg",
            "turn_ready.ogg",
            "combat_alert.ogg",
        ]

        for asset_name in expected_assets:
            asset_path = ROOT / "starcat" / "assets" / "audio" / "sfx" / asset_name
            self.assertTrue(asset_path.exists(), f"Missing audio asset: {asset_name}")
            self.assertGreater(asset_path.stat().st_size, 5000, f"Audio asset is unexpectedly tiny: {asset_name}")

        license_text = _read_text("starcat/assets/audio/LICENSES.md")
        self.assertIn("Kenney Sci-Fi Sounds", license_text)
        self.assertIn("Creative Commons Zero", license_text)
        self.assertIn("CC0", license_text)

    def test_audio_manager_autoload_and_ui_hooks_are_wired(self) -> None:
        project_config = _read_text("starcat/project.godot")
        audio_manager = _read_text("starcat/scripts/autoload/AudioManager.gd")
        main_source = _read_text("starcat/scripts/Main.gd")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")
        game_state_source = _read_text("starcat/scripts/autoload/GameState.gd")

        self.assertIn('AudioManager="*res://scripts/autoload/AudioManager.gd"', project_config)
        self.assertIn("const SOUND_PATHS: Dictionary = {", audio_manager)
        for event_name in ["ui_tick", "ui_confirm", "ui_panel", "fleet_select", "fleet_move", "turn_ready", "combat_alert"]:
            self.assertIn(f'"{event_name}"', audio_manager)
        self.assertIn("func play_event(event_name: String) -> void:", audio_manager)
        self.assertIn("AudioStreamPlayer.new()", audio_manager)
        self.assertIn("ResourceLoader.load(sound_path)", audio_manager)
        self.assertIn("_players[event_name] = player", audio_manager)
        self.assertIn("func set_enabled(value: bool) -> void:", audio_manager)

        self.assertIn('AudioManager.play_event("ui_tick")', main_source)
        self.assertIn('AudioManager.play_event("ui_confirm")', main_source)
        self.assertIn('AudioManager.play_event("ui_panel")', hud_source)
        self.assertIn("func _on_action_button_pressed(callable: Callable) -> void:", hud_source)
        self.assertIn('AudioManager.play_event("fleet_select")', game_state_source)
        self.assertIn('AudioManager.play_event("fleet_move")', game_state_source)
        self.assertIn('AudioManager.play_event("turn_ready")', game_state_source)
        self.assertIn('AudioManager.play_event("combat_alert")', game_state_source)

    def test_hud_buttons_route_through_feedback_handlers(self) -> None:
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        direct_connections = [
            "next_turn_button.pressed.connect(GameState.advance_turn)",
            "briefing_next_turn_button.pressed.connect(GameState.advance_turn)",
            "toggle_labels_button.pressed.connect(GameState.toggle_labels)",
            "close_modal_button.pressed.connect(_close_center_modal)",
            "send_button.pressed.connect(GameState.send_player_message.bind(faction_id))",
            "preset_button.pressed.connect(_apply_diplomacy_preset.bind",
        ]
        for direct_connection in direct_connections:
            self.assertNotIn(direct_connection, hud_source)

        expected_handlers = [
            "func _on_next_turn_pressed() -> void:",
            "func _on_toggle_labels_pressed() -> void:",
            "func _on_close_modal_pressed() -> void:",
            "func _on_diplomacy_preset_pressed(",
            "func _on_send_player_message_pressed(",
        ]
        for handler in expected_handlers:
            self.assertIn(handler, hud_source)

        for handler_name in [
            "_on_next_turn_pressed",
            "_on_toggle_labels_pressed",
            "_on_close_modal_pressed",
            "_on_diplomacy_preset_pressed",
            "_on_send_player_message_pressed",
        ]:
            handler_block = hud_source.split(f"func {handler_name}", 1)[1].split("\nfunc ", 1)[0]
            self.assertIn('AudioManager.play_event("ui_tick")', handler_block)

    def test_main_menu_supports_keyboard_and_compact_layout(self) -> None:
        main_source = _read_text("starcat/scripts/Main.gd")

        self.assertIn("@onready var menu_margin: MarginContainer", main_source)
        self.assertIn("@onready var menu_content: HBoxContainer", main_source)
        self.assertIn("@onready var menu_title: Label", main_source)
        self.assertIn("get_viewport().size_changed.connect(_update_main_menu_layout)", main_source)
        self.assertIn("civilization_option.call_deferred(\"grab_focus\")", main_source)
        self.assertIn("start_button.shortcut = _make_key_shortcut(KEY_ENTER)", main_source)
        self.assertIn("start_button.shortcut_in_tooltip = false", main_source)
        self.assertIn("func _update_main_menu_layout() -> void:", main_source)
        self.assertIn("var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 700.0", main_source)
        self.assertIn("preview_panel.visible = not compact", main_source)
        self.assertIn("menu_panel.offset_left = -panel_width * 0.5", main_source)
        self.assertIn("menu_panel.offset_top = -panel_height * 0.5", main_source)
        self.assertIn("controls_column.custom_minimum_size = Vector2(340, 0) if compact else Vector2(420, 0)", main_source)
        self.assertIn("menu_content.add_theme_constant_override(\"separation\", 16 if compact else 26)", main_source)
        self.assertIn("func _make_key_shortcut(keycode: Key) -> Shortcut:", main_source)
        self.assertIn("func _make_bridge_panel_style(texture_path: String, texture_margin: float, content_margin: Vector4) -> StyleBoxTexture:", main_source)
        self.assertIn('option_button.add_theme_stylebox_override("focus", option_hover_style)', main_source)
        self.assertIn('start_button.add_theme_stylebox_override("focus", _make_bridge_button_style("focus"))', main_source)
        self.assertIn("style_box.texture = _load_menu_texture(texture_path)", main_source)
        self.assertIn("style_box.texture_margin_left = texture_margin", main_source)

    def test_hud_exposes_turn_briefing_when_nothing_is_selected(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn('[node name="TurnBriefing" type="PanelContainer" parent="Root"]', hud_scene)
        self.assertIn('[node name="BriefingTitle" type="Label" parent="Root/TurnBriefing/Content"]', hud_scene)
        self.assertIn('[node name="BriefingPrimary" type="Label" parent="Root/TurnBriefing/Content"]', hud_scene)
        self.assertIn('[node name="BriefingSecondary" type="Label" parent="Root/TurnBriefing/Content"]', hud_scene)
        self.assertIn('[node name="BriefingMeta" type="Label" parent="Root/TurnBriefing/Content"]', hud_scene)
        self.assertIn('[node name="BriefingNextTurnButton" parent="Root/TurnBriefing/Content" instance=ExtResource("3_button")]', hud_scene)

        self.assertIn("@onready var turn_briefing: PanelContainer", hud_source)
        self.assertIn("@onready var briefing_primary: Label", hud_source)
        self.assertIn("@onready var briefing_next_turn_button: Button", hud_source)
        self.assertIn("briefing_next_turn_button.pressed.connect(_on_next_turn_pressed)", hud_source)
        self.assertIn("briefing_next_turn_button.disabled = next_turn_button.disabled", hud_source)
        self.assertIn("briefing_next_turn_button.text = next_turn_button.text", hud_source)
        self.assertIn("_rebuild_turn_briefing()", hud_source)
        self.assertIn("func _rebuild_turn_briefing() -> void:", hud_source)
        self.assertIn('turn_briefing.visible = GameState.selected_system_id == "" and GameState.selected_fleet_id == "" and root.size.x >= 1180.0', hud_source)
        self.assertIn("var briefing_lines: Array[String] = _turn_briefing_lines()", hud_source)
        self.assertIn("func _turn_briefing_lines() -> Array[String]:", hud_source)
        self.assertIn('"研究: %s"', hud_source)
        self.assertIn('"舰队: %s"', hud_source)
        self.assertIn('"外交: %s"', hud_source)
        self.assertIn("func _idle_fleet_count() -> int:", hud_source)
        self.assertIn("func _visible_unclaimed_system_count() -> int:", hud_source)

    def test_star_map_adds_readable_strategic_visual_cues(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('const SYSTEM_SOLAR_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_solar.png"', star_map_source)
        self.assertIn('const SYSTEM_BINARY_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_binary.png"', star_map_source)
        self.assertIn('const SYSTEM_NEBULA_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_nebula.png"', star_map_source)
        self.assertIn('const SYSTEM_STORM_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_storm.png"', star_map_source)
        self.assertIn('const SYSTEM_BLACK_HOLE_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_black_hole.png"', star_map_source)
        self.assertIn('const SYSTEM_COLONY_HUB_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_colony_hub.png"', star_map_source)
        self.assertIn('const SYSTEM_SOLAR_DUST_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_solar_dust.png"', star_map_source)
        self.assertIn('const SYSTEM_SOLAR_BLUE_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_solar_blue.png"', star_map_source)
        self.assertIn('const SYSTEM_RED_DWARF_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_red_dwarf.png"', star_map_source)
        self.assertIn('const SYSTEM_BINARY_CLOSE_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_binary_close.png"', star_map_source)
        self.assertIn('const SYSTEM_BINARY_ACCRETION_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_binary_accretion.png"', star_map_source)
        self.assertIn('const SYSTEM_MAGNETAR_STORM_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_magnetar_storm.png"', star_map_source)
        self.assertIn('const SYSTEM_BLACK_HOLE_LENSED_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_black_hole_lensed.png"', star_map_source)
        self.assertIn('const SYSTEM_STAR_CLUSTER_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_star_cluster.png"', star_map_source)
        self.assertIn('const SYSTEM_COLONY_ORBITAL_TEXTURE_PATH: String = "res://assets/vfx/starmap/system_colony_orbital.png"', star_map_source)
        self.assertIn("const SYSTEM_SOLAR_TEXTURE_PATHS: Array[String]", star_map_source)
        self.assertIn("const SYSTEM_BINARY_TEXTURE_PATHS: Array[String]", star_map_source)
        self.assertIn("const SYSTEM_COLONY_TEXTURE_PATHS: Array[String]", star_map_source)
        self.assertIn('const FLEET_MARKER_TEXTURE_PATH: String = "res://assets/vfx/starmap/fleet_marker_chevron.png"', star_map_source)
        self.assertIn("const SYSTEM_TEXTURE_WORLD_SIZE: float = 2.28", star_map_source)
        self.assertIn("const SELECTED_SYSTEM_TEXTURE_WORLD_SIZE: float = 2.56", star_map_source)
        self.assertIn("const SELECTED_SYSTEM_BRACKET_RADIUS: float = 1.08", star_map_source)
        self.assertIn("const FLEET_MARKER_PIXEL_SIZE: float = 0.0046", star_map_source)
        self.assertIn("const CAMERA_HEIGHT_RATIO: float = 1.28", star_map_source)
        self.assertIn("const CAMERA_PITCH_DEGREES: float = -52.0", star_map_source)
        self.assertIn("body.add_child(_make_system_texture_sprite(system, reachable.has(system.get(\"id\", \"\"))))", star_map_source)
        self.assertIn("body.add_child(_make_system_reticle(system))", star_map_source)
        self.assertNotIn("body.add_child(_make_influence_field(system))", star_map_source)
        self.assertNotIn("body.add_child(_make_system_halo(system, reachable.has(system.get(\"id\", \"\"))))", star_map_source)
        self.assertNotIn("body.add_child(_make_system_ring(system, reachable.has(system.get(\"id\", \"\"))))", star_map_source)
        self.assertNotIn("body.add_child(_make_system_marker_sprite(system, reachable.has(system.get(\"id\", \"\"))))", star_map_source)
        self.assertNotIn("sphere.radius = SYSTEM_SCENE_RADIUS", star_map_source)
        self.assertIn("marker.add_child(_make_fleet_readiness_badge(fleet))", star_map_source)
        self.assertIn("marker.add_child(_make_fleet_marker_sprite(fleet))", star_map_source)
        self.assertIn("func _make_system_texture_sprite(system: Dictionary, reachable: bool) -> MeshInstance3D:", star_map_source)
        self.assertIn("var mesh := PlaneMesh.new()", star_map_source)
        self.assertIn("func _make_fleet_marker_sprite(fleet: Dictionary) -> Sprite3D:", star_map_source)
        self.assertIn("func _make_system_reticle(system: Dictionary) -> MeshInstance3D:", star_map_source)
        self.assertIn("func _system_texture_path(system: Dictionary) -> String:", star_map_source)
        self.assertIn("func _stable_system_texture_path(paths: Array[String], system: Dictionary) -> String:", star_map_source)
        self.assertIn('return SYSTEM_STAR_CLUSTER_TEXTURE_PATH', star_map_source)
        self.assertIn("return _stable_system_texture_path(SYSTEM_SOLAR_TEXTURE_PATHS, system)", star_map_source)
        self.assertNotIn("func _make_flat_ring_mesh(", star_map_source)
        self.assertNotIn("func _make_flat_disk_mesh(", star_map_source)
        self.assertIn("func _make_fleet_readiness_badge(fleet: Dictionary) -> Label3D:", star_map_source)
        self.assertIn('badge.text = "待命" if int(fleet.get("movementCooldown", 0)) <= 0 else "冷却"', star_map_source)
        self.assertIn("material.albedo_texture = _load_texture_cached(_system_texture_path(system))", star_map_source)
        self.assertIn("func _system_type_color(system: Dictionary) -> Color:", star_map_source)
        texture_loader_block = star_map_source.split("func _load_texture_cached(texture_path: String) -> Texture2D:", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("var texture_resource: Texture2D = ResourceLoader.load(texture_path) as Texture2D", texture_loader_block)
        self.assertIn('if texture_resource == null and texture_path.to_lower().ends_with(".png"):', texture_loader_block)
        self.assertLess(
            texture_loader_block.index("ResourceLoader.load(texture_path)"),
            texture_loader_block.index("_load_external_png_texture(png_path)"),
        )

    def test_star_map_builds_ambient_space_layers(self) -> None:
        star_map_scene = _read_text("starcat/scenes/StarMap.tscn")
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('[node name="AmbientRoot" type="Node3D" parent="."]', star_map_scene)
        self.assertIn("position = Vector3(0, 16, 18)", star_map_scene)
        self.assertIn("rotation_degrees = Vector3(-52, 0, 0)", star_map_scene)
        self.assertIn("background_color = Color(0.00392157, 0.0117647, 0.0235294, 1)", star_map_scene)
        self.assertIn("@onready var ambient_root: Node3D = $AmbientRoot", star_map_source)
        self.assertIn('const NEBULA_BACKDROP_TEXTURE_PATH: String = "res://assets/vfx/starmap/background_nebula_low_visibility.png"', star_map_source)
        self.assertIn("const STARFIELD_COUNT: int = 120", star_map_source)
        self.assertIn("const BRIGHT_STARFIELD_COUNT: int = 34", star_map_source)
        self.assertIn("const STARFIELD_RADIUS: float = 34.0", star_map_source)
        self.assertIn("const NEBULA_BACKDROP_SIZE: Vector2 = Vector2(76.0, 42.75)", star_map_source)
        self.assertIn("const NEBULA_BACKDROP_ALPHA: float = 0.42", star_map_source)
        self.assertIn("const NEBULA_BACKDROP_HEIGHT: float = -0.47", star_map_source)
        self.assertIn("const DEPTH_GRID_EXTENT: float = 32.0", star_map_source)
        self.assertIn("const DEPTH_GRID_HEIGHT: float = -0.42", star_map_source)
        self.assertIn("func _build_ambient_space() -> void:", star_map_source)
        self.assertNotIn("ambient_root.add_child(_make_nebula_wash())", star_map_source)
        self.assertIn("ambient_root.add_child(_make_nebula_backdrop())", star_map_source)
        self.assertIn("ambient_root.add_child(_make_starfield())", star_map_source)
        self.assertIn("ambient_root.add_child(_make_bright_starfield())", star_map_source)
        self.assertIn("ambient_root.add_child(_make_depth_grid())", star_map_source)
        self.assertNotIn("ambient_root.add_child(_make_holographic_scan_overlay())", star_map_source)
        self.assertNotIn("func _make_nebula_wash() -> Node3D:", star_map_source)
        self.assertNotIn("root.add_child(_make_textured_vfx_plane(", star_map_source)
        self.assertNotIn("NEBULA_TEAL_TEXTURE_PATH", star_map_source)
        self.assertNotIn("STELLAR_HAZE_TEXTURE_PATH", star_map_source)
        self.assertNotIn("cloud.mesh = _make_flat_disk_mesh", star_map_source)
        self.assertNotIn('root.name = "HolographicScanOverlay"', star_map_source)
        self.assertNotIn("func _make_textured_vfx_plane(", star_map_source)
        self.assertIn("func _make_nebula_backdrop() -> MeshInstance3D:", star_map_source)
        self.assertIn("func _make_nebula_backdrop_mesh() -> ArrayMesh:", star_map_source)
        self.assertIn('instance.name = "NebulaBackdrop"', star_map_source)
        self.assertIn("instance.mesh = _make_nebula_backdrop_mesh()", star_map_source)
        self.assertIn("arrays[Mesh.ARRAY_TEX_UV] = uvs", star_map_source)
        self.assertIn("material.albedo_texture = _load_texture_cached(NEBULA_BACKDROP_TEXTURE_PATH)", star_map_source)
        self.assertIn('instance.set_meta("vfx_kind", "nebula_backdrop")', star_map_source)
        self.assertIn("func _make_starfield() -> MultiMeshInstance3D:", star_map_source)
        self.assertIn("func _make_bright_starfield() -> MultiMeshInstance3D:", star_map_source)
        self.assertIn("multimesh.instance_count = STARFIELD_COUNT", star_map_source)
        self.assertIn("multimesh.instance_count = BRIGHT_STARFIELD_COUNT", star_map_source)
        self.assertIn("func _make_depth_grid() -> MeshInstance3D:", star_map_source)
        self.assertIn("Vector3(-DEPTH_GRID_EXTENT, DEPTH_GRID_HEIGHT, offset)", star_map_source)
        self.assertIn('material.albedo_color = Color("24506A", 0.18)', star_map_source)

    def test_star_map_nebula_backdrop_asset_is_dark_and_subtle(self) -> None:
        from PIL import Image

        image_path = ROOT / "starcat/assets/vfx/starmap/background_nebula_low_visibility.png"
        self.assertTrue(image_path.exists())
        self.assertTrue(image_path.with_suffix(".png.import").exists())
        image = Image.open(image_path).convert("RGBA")
        self.assertEqual(image.size, (4096, 2304))
        self.assertEqual(image.mode, "RGBA")
        pixels = _rgba_pixels(image.resize((256, 144)))
        self.assertLess(_average_luminance(pixels), 48.0)
        blue_green_pixels = [pixel for pixel in pixels if pixel[2] >= pixel[0] and pixel[1] >= pixel[0]]
        self.assertGreater(len(blue_green_pixels) / len(pixels), 0.72)

    def test_star_map_uses_holographic_route_bands_and_scan_overlay(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn("const LANE_STRIP_WIDTH: float = 0.032", star_map_source)
        self.assertIn("const HIGHLIGHTED_LANE_STRIP_WIDTH: float = 0.044", star_map_source)
        self.assertIn("const LANE_GLOW_WIDTH_MULTIPLIER: float = 1.45", star_map_source)
        self.assertIn('const HYPERLANE_DASH_TEXTURE_PATH: String = "res://assets/vfx/starmap/hyperlane_dash.png"', star_map_source)
        self.assertIn('const WORMHOLE_ROUTE_TICK_TEXTURE_PATH: String = "res://assets/vfx/starmap/wormhole_route_tick.png"', star_map_source)
        self.assertIn("const LANE_TEXTURE_WIDTH: float = 0.22", star_map_source)
        self.assertIn("const HIGHLIGHTED_LANE_TEXTURE_WIDTH: float = 0.28", star_map_source)
        self.assertIn("const VFX_LANE_FLOW_SPEED: float = 0.075", star_map_source)
        self.assertIn("const VFX_SYSTEM_PULSE_AMOUNT: float = 0.045", star_map_source)
        self.assertIn("const VFX_NEBULA_DRIFT_SPEED: float = 0.006", star_map_source)
        self.assertIn("const VFX_NEBULA_ALPHA_PULSE: float = 0.018", star_map_source)
        self.assertIn("var _vfx_time: float = 0.0", star_map_source)
        self.assertNotIn("const SCAN_RING_ALPHA", star_map_source)
        self.assertNotIn("SCAN_RING_TEXTURE_PATH", star_map_source)
        self.assertIn("HYPERLANE_DASH_TEXTURE_PATH", star_map_source)
        self.assertIn("_animate_star_map_vfx()", star_map_source)
        self.assertIn('lane.add_to_group("starmap_vfx_animated")', star_map_source)
        self.assertIn('sprite.add_to_group("starmap_vfx_animated")', star_map_source)
        self.assertIn('reticle.add_to_group("starmap_vfx_animated")', star_map_source)
        self.assertIn("glow_instance.material_override = _make_lane_glow_material", star_map_source)
        self.assertIn("lanes_root.add_child(_make_textured_lane_overlay(", star_map_source)
        self.assertIn("func _make_lane_mesh(start: Vector3, end: Vector3, width: float) -> ArrayMesh:", star_map_source)
        self.assertIn("func _make_textured_lane_overlay(start: Vector3, end: Vector3, is_wormhole: bool, highlighted: bool) -> MeshInstance3D:", star_map_source)
        self.assertIn("func _make_lane_glow_material(is_wormhole: bool, highlighted: bool) -> StandardMaterial3D:", star_map_source)
        self.assertIn("func _animate_star_map_vfx() -> void:", star_map_source)
        self.assertIn("func _animate_nebula_backdrop(node: Node, wave: float) -> void:", star_map_source)
        self.assertIn("func _animate_lane_flow(node: Node, wave: float) -> void:", star_map_source)
        self.assertIn("func _animate_system_node(node: Node, wave: float) -> void:", star_map_source)
        self.assertIn("func _animate_fleet_marker(node: Node, wave: float) -> void:", star_map_source)
        self.assertIn("material.uv1_offset.x = fmod(_vfx_time * flow_speed, 1.0)", star_map_source)
        self.assertIn("material.uv1_offset.x = fmod(_vfx_time * VFX_NEBULA_DRIFT_SPEED, 1.0)", star_map_source)
        self.assertIn("color.a = clamp(base_alpha + wave * VFX_NEBULA_ALPHA_PULSE, 0.34, 0.48)", star_map_source)
        self.assertIn("var mesh: CylinderMesh = CylinderMesh.new()", star_map_source)
        self.assertIn("mesh.radial_segments = 6", star_map_source)
        self.assertIn('material.albedo_color = Color("9FC7D0") if highlighted else Color("7BBDB6") if is_wormhole else Color("6C8798")', star_map_source)
        self.assertIn('var base_alpha: float = 0.27 if highlighted else (0.22 if is_wormhole else 0.16)', star_map_source)
        self.assertIn('material.albedo_color = Color("A8DCD8", base_alpha)', star_map_source)
        self.assertIn("mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)", star_map_source)
        self.assertNotIn("func _make_lane_mesh(start: Vector3, end: Vector3) -> ImmediateMesh:", star_map_source)
        self.assertNotIn("func _make_holographic_scan_overlay() -> Node3D:", star_map_source)
        self.assertNotIn('Color("F26A1B", SCAN_RING_ALPHA * 0.42)', star_map_source)

    def test_star_map_shows_compact_resource_badges_for_visible_systems(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")

        self.assertIn('const RESOURCE_BADGE_LABELS: Dictionary = {"food": "食", "minerals": "矿", "industry": "工", "energy": "能"}', star_map_source)
        self.assertIn("const MAX_RESOURCE_BADGES: int = 2", star_map_source)
        self.assertIn("body.add_child(_make_system_resource_badges(system))", star_map_source)
        self.assertIn("func _make_system_resource_badges(system: Dictionary) -> Node3D:", star_map_source)
        self.assertIn("func _top_resource_entries(resources: Dictionary) -> Array:", star_map_source)
        self.assertIn("entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:", star_map_source)
        self.assertIn('badge.text = "%s%s" % [RESOURCE_BADGE_LABELS.get(resource_key, resource_key.substr(0, 1)), str(resource_value)]', star_map_source)
        self.assertIn('habitability_badge.text = "宜%s" % str(int(system.get("habitability", 0)))', star_map_source)


if __name__ == "__main__":
    unittest.main()
