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
        self.assertIn("服务状态:", hud_source)
        self.assertNotIn("后端状态", hud_source)
        self.assertNotIn("backend_status", hud_source)

    def test_hud_drawer_uses_full_height_anchor_layout(self) -> None:
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")
        right_drawer_block = hud_scene.split('[node name="RightDrawer" type="PanelContainer" parent="Root"', 1)[1].split("[node name=", 1)[0]
        self.assertIn("anchor_top = 0.0", right_drawer_block)
        self.assertIn("anchor_bottom = 1.0", right_drawer_block)
        self.assertNotIn("anchor_top = 0.5", right_drawer_block)

    def test_star_map_labels_are_scaled_for_readability(self) -> None:
        star_map_source = _read_text("starcat/scripts/StarMap.gd")
        self.assertIn("label.pixel_size = 0.01 if compact else 0.012", star_map_source)
        self.assertIn("label.font_size = 30 if compact else 38", star_map_source)

    def test_top_bar_chip_layout_and_titles_are_initialized(self) -> None:
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_source = _read_text("starcat/scripts/HudLayer.gd")

        self.assertIn("size_flags_horizontal = 3", chip_scene)
        self.assertIn("size_flags_vertical = 3", chip_scene)
        self.assertIn('turn_title.text = "回合"', hud_source)
        self.assertIn('era_title.text = "时代"', hud_source)
        self.assertIn('food_title.text = "食物"', hud_source)


if __name__ == "__main__":
    unittest.main()
