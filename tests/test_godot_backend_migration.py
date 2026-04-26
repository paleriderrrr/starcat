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


if __name__ == "__main__":
    unittest.main()
