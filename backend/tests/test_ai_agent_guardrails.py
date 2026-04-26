from __future__ import annotations

from pathlib import Path
import sys
import unittest
from unittest import mock
from urllib import error


ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from ai_agent import AIAgent, BailianClient, Personality  # noqa: E402


class _FakeResponse:
    def __init__(self, body: str) -> None:
        self._body = body.encode("utf-8")

    def read(self) -> bytes:
        return self._body

    def __enter__(self) -> "_FakeResponse":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        return None


class AIAgentGuardrailTests(unittest.TestCase):
    def test_build_prompt_context_includes_memory_and_personality_sections(self) -> None:
        agent = AIAgent(
            leader_name="测试领袖",
            faction_name="测试文明",
            personality=Personality(7, 8, 4, 3, 9),
        )
        context = agent.build_prompt_context(
            {
                "turn": 12,
                "era": "CONFLICT",
                "resources": {"energy": 120},
                "strategic_posture": {"flashpoints": ["织女星"]},
                "recentInteractionMemory": [{"title": "边境争端", "summary": "边境发生摩擦。"}],
                "archivedInteractionMemory": [{"title": "旧怨", "summary": "曾经的贸易纠纷。", "participants": ["f_player"], "semantic_keywords": ["贸易", "纠纷"], "emotionalImpact": -0.6, "decayFactor": 0.98, "turn": 3}],
            }
        )
        self.assertIn("personality_summary", context)
        self.assertIn("behavior_biases", context)
        self.assertIn("recent_memory", context)
        self.assertIn("related_long_term_memories", context)
        self.assertIn("strategic_posture", context)

    def test_decide_prompt_explicitly_contains_memory_and_biases(self) -> None:
        agent = AIAgent(
            leader_name="测试领袖",
            faction_name="测试文明",
            personality=Personality(8, 7, 4, 3, 9),
        )
        agent.client.api_key = "test-key"
        captured: dict[str, str] = {}

        def _fake_generate_text(prompt: str, max_output_tokens: int = 0) -> str:
            captured["prompt"] = prompt
            return '{"action":"WAIT","target":null,"reasoning":"维持观望，等待更有利窗口。"}'

        with mock.patch.object(agent.client, "generate_text", side_effect=_fake_generate_text):
            decision = agent.decide(
                {
                    "turn": 12,
                    "era": "CONFLICT",
                    "resources": {"energy": 120},
                    "strategic_posture": {"flashpoints": ["织女星"]},
                    "recentInteractionMemory": [{"title": "边境争端", "summary": "边境发生摩擦。"}],
                    "archivedInteractionMemory": [{"title": "旧怨", "summary": "曾经的贸易纠纷。", "participants": ["f_player"], "semantic_keywords": ["贸易", "纠纷"], "emotionalImpact": -0.6, "decayFactor": 0.98, "turn": 3}],
                }
            )
        self.assertFalse(decision.is_fallback)
        self.assertIn("recent_memory", captured["prompt"])
        self.assertIn("related_long_term_memories", captured["prompt"])
        self.assertIn("behavior_biases", captured["prompt"])
        self.assertIn("personality_summary", captured["prompt"])

    def test_bailian_client_retries_retryable_http_errors(self) -> None:
        client = BailianClient()
        client.api_key = "test-key"
        side_effects = [
            error.HTTPError("http://example.com", 503, "busy", None, None),
            error.HTTPError("http://example.com", 502, "gateway", None, None),
            _FakeResponse('{"output_text":"ok"}'),
        ]
        with mock.patch("ai_agent.request.urlopen", side_effect=side_effects) as mocked_urlopen:
            with mock.patch("ai_agent.time.sleep") as mocked_sleep:
                result = client.generate_text("ping")
        self.assertEqual(result, "ok")
        self.assertEqual(mocked_urlopen.call_count, 3)
        self.assertEqual(mocked_sleep.call_count, 2)

    def test_reply_falls_back_when_model_leaks_meta_text(self) -> None:
        agent = AIAgent(
            leader_name="测试领袖",
            faction_name="测试文明",
            personality=Personality(4, 5, 5, 6, 8),
        )
        agent.client.api_key = "test-key"
        with mock.patch.object(agent.client, "generate_text", return_value='{"title":"系统提示","content":"这是 JSON schema 的回答","tone":"neutral"}'):
            reply = agent.reply_to_player_message(
                recipient_name="玩家",
                relationship_level="NEUTRAL",
                tone="neutral",
                player_message="我们想讨论贸易",
                visibility_level="PUBLIC",
                intent_type="MESSAGE",
                intent_detail="",
            )
        self.assertTrue(reply.is_fallback)
        self.assertEqual(reply.source, "fallback")
        self.assertNotIn("JSON", reply.content)


if __name__ == "__main__":
    unittest.main()
