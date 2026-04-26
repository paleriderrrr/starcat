from __future__ import annotations

from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import time
from typing import Any, Literal
from urllib import error, request

BAILIAN_BASE_URL = os.getenv(
    'BAILIAN_BASE_URL',
    'https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1'
)
BAILIAN_MODEL = os.getenv('BAILIAN_MODEL', 'qwen3.5-flash')
FORMAT_VERSION = '1.0'
RETRYABLE_HTTP_STATUS = {408, 409, 425, 429, 500, 502, 503, 504}
MAX_API_RETRIES = 3


def _load_local_env() -> None:
    env_path = Path(__file__).with_name('.env')
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding='utf-8').splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith('#') or '=' not in stripped:
            continue
        key, value = stripped.split('=', 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_local_env()


@dataclass
class Personality:
    aggression: float
    paranoia: float
    greed: float
    loyalty: float
    rationality: float


@dataclass
class AgentDecision:
    action: str
    target: str | None
    reasoning: str
    source: Literal['bailian', 'fallback']
    is_fallback: bool
    structured_text: str
    format_version: str = FORMAT_VERSION


@dataclass
class DiplomaticDraft:
    title: str
    content: str
    source: Literal['bailian', 'fallback']
    is_fallback: bool
    structured_text: str
    format_version: str = FORMAT_VERSION


@dataclass
class ConversationReply:
    title: str
    content: str
    tone: str
    source: Literal['bailian', 'fallback']
    is_fallback: bool
    structured_text: str
    format_version: str = FORMAT_VERSION


class BailianClient:
    def __init__(self) -> None:
        self.api_key = os.getenv('BAILIAN_API_KEY') or os.getenv('DASHSCOPE_API_KEY')
        self.base_url = BAILIAN_BASE_URL.rstrip('/')
        self.model = BAILIAN_MODEL

    @property
    def enabled(self) -> bool:
        return bool(self.api_key)

    def _post(self, payload: dict[str, Any]) -> dict[str, Any]:
        if not self.api_key:
            raise RuntimeError('Missing Bailian API key')
        last_error: Exception | None = None
        for attempt in range(MAX_API_RETRIES):
            req = request.Request(
                url=f'{self.base_url}/responses',
                data=json.dumps(payload).encode('utf-8'),
                headers={
                    'Authorization': f'Bearer {self.api_key}',
                    'Content-Type': 'application/json'
                },
                method='POST'
            )
            try:
                with request.urlopen(req, timeout=45) as resp:
                    body = resp.read().decode('utf-8')
                return json.loads(body)
            except error.HTTPError as exc:
                last_error = exc
                if exc.code not in RETRYABLE_HTTP_STATUS or attempt == MAX_API_RETRIES - 1:
                    raise
            except (error.URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
                last_error = exc
                if attempt == MAX_API_RETRIES - 1:
                    raise
            time.sleep(0.35 * (2 ** attempt))
        if last_error is not None:
            raise last_error
        raise RuntimeError('Bailian request failed without explicit error')

    def generate_text(self, prompt: str, max_output_tokens: int = 256) -> str:
        payload = {
            'model': self.model,
            'input': prompt,
            'max_output_tokens': max_output_tokens,
        }
        response = self._post(payload)
        output_text = response.get('output_text')
        if isinstance(output_text, str) and output_text.strip():
            return output_text.strip()

        output = response.get('output', [])
        parts: list[str] = []
        for item in output:
            for content in item.get('content', []):
                text = content.get('text')
                if isinstance(text, str):
                    parts.append(text)
        return '\n'.join(part for part in parts if part).strip()


class AIAgent:
    def __init__(self, leader_name: str, faction_name: str, personality: Personality) -> None:
        self.leader_name = leader_name
        self.faction_name = faction_name
        self.personality = personality
        self.client = BailianClient()

    def _personality_summary(self) -> str:
        traits: list[str] = []
        if self.personality.aggression >= 7:
            traits.append('高攻击倾向')
        elif self.personality.aggression <= 3:
            traits.append('避免过早开战')
        if self.personality.paranoia >= 7:
            traits.append('高度警惕秘密威胁')
        if self.personality.greed >= 7:
            traits.append('重视贸易和资源收益')
        if self.personality.loyalty >= 7:
            traits.append('重视承诺与盟约稳定')
        elif self.personality.loyalty <= 3:
            traits.append('对盟约承诺较弱')
        if self.personality.rationality >= 7:
            traits.append('偏好可计算且风险受控的行动')
        return '，'.join(traits) if traits else '人格特征均衡'

    def _behavior_biases(self) -> dict[str, str]:
        return {
            'war_posture': 'high' if self.personality.aggression >= 7 else 'guarded' if self.personality.aggression <= 3 else 'balanced',
            'secrecy_preference': 'high' if self.personality.paranoia >= 7 else 'low' if self.personality.paranoia <= 3 else 'medium',
            'trade_preference': 'high' if self.personality.greed >= 7 else 'low' if self.personality.greed <= 3 else 'medium',
            'treaty_commitment': 'high' if self.personality.loyalty >= 7 else 'low' if self.personality.loyalty <= 3 else 'medium',
            'risk_control': 'high' if self.personality.rationality >= 7 else 'low' if self.personality.rationality <= 3 else 'medium',
        }

    def _semantic_tokens(self, text: str, participants: list[str] | None = None) -> list[str]:
        cleaned = re.sub(r'[\W_]+', ' ', str(text).lower())
        tokens = [token for token in cleaned.split() if len(token) >= 2]
        if participants:
            tokens.extend(str(item).lower() for item in participants if str(item).strip())
        seen: list[str] = []
        for token in tokens:
            if token not in seen:
                seen.append(token)
        return seen

    def _recent_memory_digest(self, game_state: dict[str, Any], limit: int = 5) -> list[dict[str, Any]]:
        result: list[dict[str, Any]] = []
        for item in game_state.get('recentInteractionMemory', [])[:limit]:
            result.append({
                'title': str(item.get('title', '未命名交互')),
                'summary': str(item.get('summary', '')),
                'category': str(item.get('category', 'EVENT')),
                'importance': int(item.get('importance', 1)),
            })
        return result

    def _related_long_term_memories(
        self,
        game_state: dict[str, Any],
        query_text: str,
        participants: list[str] | None = None,
        limit: int = 4,
    ) -> list[dict[str, Any]]:
        query_tokens = self._semantic_tokens(query_text, participants)
        ranked: list[tuple[float, dict[str, Any]]] = []
        for item in game_state.get('archivedInteractionMemory', []):
            keywords = [str(keyword).lower() for keyword in item.get('semantic_keywords', [])]
            overlap = sum(1 for token in query_tokens if token in keywords)
            participant_bonus = 0
            if participants:
                archived_participants = {str(value) for value in item.get('participants', [])}
                participant_bonus = sum(1 for participant in participants if participant in archived_participants)
            age_turns = max(0, int(game_state.get('turn', 1)) - int(item.get('turn', 1)))
            current_influence = float(item.get('emotionalImpact', 0.0)) * (float(item.get('decayFactor', 0.98)) ** age_turns)
            score = float(overlap * 2 + participant_bonus) + abs(current_influence)
            if score <= 0:
                continue
            ranked.append((score, {
                'title': str(item.get('title', '长期记忆')),
                'summary': str(item.get('summary', '')),
                'current_influence': round(current_influence, 3),
                'participants': [str(value) for value in item.get('participants', [])],
            }))
        ranked.sort(key=lambda pair: pair[0], reverse=True)
        return [item for _, item in ranked[:limit]]

    def build_prompt_context(
        self,
        game_state: dict[str, Any],
        query_text: str = '',
        participants: list[str] | None = None,
    ) -> dict[str, Any]:
        strategic_posture = game_state.get('strategic_posture', {})
        if not strategic_posture:
            strategic_posture = {
                'flashpoints': game_state.get('flashpoints', []),
                'high_pressure': game_state.get('high_pressure', []),
                'high_opportunity': game_state.get('high_opportunity', []),
            }
        return {
            'leader_name': self.leader_name,
            'faction_name': self.faction_name,
            'turn': game_state.get('turn', 1),
            'era': game_state.get('era', 'PIONEER'),
            'resources': game_state.get('resources', {}),
            'personality': self.personality.__dict__,
            'personality_summary': self._personality_summary(),
            'behavior_biases': self._behavior_biases(),
            'strategic_posture': strategic_posture,
            'recent_memory': self._recent_memory_digest(game_state),
            'related_long_term_memories': self._related_long_term_memories(game_state, query_text or self.faction_name, participants),
        }

    def _extract_json(self, text: str) -> dict[str, Any]:
        match = re.search(r'\{[\s\S]*\}', text)
        if not match:
            raise ValueError('No JSON object found in model output')
        return json.loads(match.group(0))

    def _normalize_text(self, text: str, max_chars: int) -> str:
        cleaned = re.sub(r'[\x00-\x08\x0B-\x1F\x7F]', ' ', str(text))
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        if len(cleaned) > max_chars:
            cleaned = cleaned[:max_chars].rstrip()
        return cleaned

    def _contains_meta_leak(self, text: str) -> bool:
        lowered = text.lower()
        forbidden_markers = [
            'json',
            'schema',
            'system prompt',
            'markdown',
            '模型',
            '提示词',
            '系统提示',
        ]
        return any(marker in lowered for marker in forbidden_markers)

    def _review_text_output(self, text: str, max_chars: int) -> str:
        cleaned = self._normalize_text(text, max_chars)
        if cleaned == '':
            raise ValueError('Model output is empty after normalization')
        if self._contains_meta_leak(cleaned):
            raise ValueError('Model output leaked meta instructions')
        return cleaned

    def _build_structured_prompt(
        self,
        task: str,
        output_schema: dict[str, str],
        hard_rules: list[str],
        input_payload: dict[str, Any],
        example_output: dict[str, Any] | None = None,
    ) -> str:
        sections = [
            'TASK',
            task,
            '',
            'OUTPUT_RULES',
            '- Return exactly one JSON object.',
            '- Do not output Markdown.',
            '- Do not output explanations or extra text.',
            '',
            'OUTPUT_SCHEMA',
            json.dumps(output_schema, ensure_ascii=False),
            '',
            'HARD_RULES',
        ]
        sections.extend(f'- {rule}' for rule in hard_rules)
        sections.extend(['', 'INPUT_JSON', json.dumps(input_payload, ensure_ascii=False)])
        if example_output is not None:
            sections.extend(['', 'EXAMPLE_OUTPUT', json.dumps(example_output, ensure_ascii=False)])
        return '\n'.join(sections)

    def _format_decision_text(self, action: str, target: str | None, reasoning: str, source: str, is_fallback: bool) -> str:
        return '\n'.join([
            '[AI_DECISION]',
            f'format_version: {FORMAT_VERSION}',
            f'source: {source}',
            f'is_fallback: {str(is_fallback).lower()}',
            f'faction: {self.faction_name}',
            f'leader: {self.leader_name}',
            f'action: {action}',
            f'target: {target or "null"}',
            f'reasoning: {reasoning}',
            '[/AI_DECISION]',
        ])

    def _format_diplomatic_text(self, title: str, content: str, recipient_name: str, source: str, is_fallback: bool) -> str:
        return '\n'.join([
            '[AI_DIPLOMATIC_MESSAGE]',
            f'format_version: {FORMAT_VERSION}',
            f'source: {source}',
            f'is_fallback: {str(is_fallback).lower()}',
            f'sender: {self.leader_name}',
            f'recipient: {recipient_name}',
            f'title: {title}',
            f'content: {content}',
            '[/AI_DIPLOMATIC_MESSAGE]',
        ])

    def _format_conversation_text(self, title: str, content: str, recipient_name: str, visibility_level: str, source: str, is_fallback: bool) -> str:
        return '\n'.join([
            '[AI_DIPLOMATIC_CONVERSATION]',
            f'format_version: {FORMAT_VERSION}',
            f'source: {source}',
            f'is_fallback: {str(is_fallback).lower()}',
            f'sender: {self.leader_name}',
            f'recipient: {recipient_name}',
            f'visibility_level: {visibility_level}',
            f'title: {title}',
            f'content: {content}',
            '[/AI_DIPLOMATIC_CONVERSATION]',
        ])

    def _fallback_decide(self, game_state: dict[str, Any]) -> AgentDecision:
        resources = game_state.get('resources', {})
        visible_neutral_systems = game_state.get('visible_neutral_systems', [])
        relation_trust = float(game_state.get('relation_trust', 0))
        relation_utility = float(game_state.get('relation_utility', 0))
        relation_fear = float(game_state.get('relation_fear', 0))
        relation_memory = float(game_state.get('relation_memory_impact', 0))
        home_has_shipyard = bool(game_state.get('home_has_shipyard', False))
        available_build_targets = list(game_state.get('available_build_targets', ['CORVETTE']))
        can_attack_player = bool(game_state.get('can_attack_player', False))
        player_system_id = game_state.get('player_system_id')

        richest_target = None
        if visible_neutral_systems:
            richest_target = max(visible_neutral_systems, key=lambda item: float(item.get('value', 0)))

        if relation_trust <= -25 and relation_fear <= 55 and can_attack_player and player_system_id:
            action, target, reasoning = 'DECLARE_WAR', player_system_id, '边境互信跌破警戒线，先发制人可以迫使喵星舰队回防。'
        elif not home_has_shipyard and resources.get('minerals', 0) >= 60 and resources.get('industry', 0) >= 50:
            action, target, reasoning = 'BUILD', 'SHIPYARD', '先补齐本土造舰能力，后续扩张和护航都会更稳定。'
        elif 'CRUISER' in available_build_targets and resources.get('minerals', 0) >= 100 and resources.get('industry', 0) >= 90:
            action, target, reasoning = 'BUILD', 'CRUISER', '当前储备足够支撑主力舰下水，应尽快建立质量优势。'
        elif 'DESTROYER' in available_build_targets and resources.get('minerals', 0) >= 50 and resources.get('industry', 0) >= 40:
            action, target, reasoning = 'BUILD', 'DESTROYER', '驱逐舰能同时承担护航和威慑任务，性价比最高。'
        elif richest_target is not None:
            action, target, reasoning = 'EXPLORE', richest_target.get('id'), f"{richest_target.get('name', '目标星系')} 资源回报最高，优先抢占能扩大贸易纵深。"
        elif relation_trust + relation_utility * 0.4 + relation_memory * 0.2 >= 45:
            action, target, reasoning = 'TRADE', 'f_player', '关系尚可，短期合作比消耗战更划算。'
        elif relation_fear >= 65 and richest_target is not None:
            action, target, reasoning = 'EXPLORE', richest_target.get('id'), '对玩家军势存在明显忌惮，优先外扩比正面冲突更稳妥。'
        elif 'CORVETTE' in available_build_targets and resources.get('minerals', 0) >= 30 and resources.get('industry', 0) >= 25:
            action, target, reasoning = 'BUILD', 'CORVETTE', '先补轻型护航舰，确保商路不会出现明显空档。'
        else:
            action, target, reasoning = 'WAIT', None, '本回合储备不足或目标不明确，暂时观望并等待更好窗口。'

        return AgentDecision(
            action=action,
            target=target,
            reasoning=reasoning,
            source='fallback',
            is_fallback=True,
            structured_text=self._format_decision_text(action, target, reasoning, 'fallback', True),
        )

    def decide(self, game_state: dict[str, Any]) -> AgentDecision:
        fallback = self._fallback_decide(game_state)
        if not self.client.enabled:
            return fallback

        prompt = self._build_structured_prompt(
            task=f'Select the single best move for faction {self.faction_name} in this 4X strategy turn.',
            output_schema={
                'action': 'BUILD|EXPLORE|TRADE|DECLARE_WAR|WAIT',
                'target': 'string|null',
                'reasoning': 'short Chinese sentence with 18-60 chars',
            },
            hard_rules=[
                'For BUILD, target must be one of SHIPYARD, CORVETTE, DESTROYER, CRUISER.',
                'For EXPLORE, target should be a star-system id from visible_neutral_systems.',
                'For DECLARE_WAR, target must equal player_system_id.',
                'For WAIT, target must be null.',
                'Reasoning must be concise Chinese.',
                'Use relation_utility, relation_fear, and relation_memory_impact when available.',
                'If information is incomplete, still choose the safest best move.',
            ],
            input_payload=self.build_prompt_context(game_state, 'turn decision', [self.faction_name]) | game_state,
            example_output={
                'action': 'EXPLORE',
                'target': 'sys_polaris',
                'reasoning': '优先探索高价值中立星系，扩大资源与战略纵深。',
            },
        )

        try:
            raw = self.client.generate_text(prompt, max_output_tokens=180)
            data = self._extract_json(raw)
            action = str(data.get('action', fallback.action)).upper()
            if action not in {'BUILD', 'EXPLORE', 'TRADE', 'DECLARE_WAR', 'WAIT'}:
                return fallback
            target = data.get('target')
            reasoning = self._review_text_output(str(data.get('reasoning') or fallback.reasoning), 60)
            if action == 'WAIT':
                target = None
            elif target is not None:
                target = str(target)
            return AgentDecision(
                action=action,
                target=target,
                reasoning=reasoning,
                source='bailian',
                is_fallback=False,
                structured_text=self._format_decision_text(action, target, reasoning, 'bailian', False),
            )
        except (ValueError, KeyError, TypeError, RuntimeError, TimeoutError, OSError, error.URLError, error.HTTPError, json.JSONDecodeError):
            return fallback

    def diplomatic_message(
        self,
        recipient_name: str,
        relationship_level: str,
        tone: str,
        game_state: dict[str, Any] | None = None,
    ) -> DiplomaticDraft:
        fallback_title = f'{self.leader_name} 致 {recipient_name} 的照会'
        fallback_content = (
            f'基于当前 {relationship_level} 关系，{self.leader_name} 以 {tone} 立场发出正式回应。'
            '当前已回退到本地外交模板。'
        )
        fallback = DiplomaticDraft(
            title=fallback_title,
            content=fallback_content,
            source='fallback',
            is_fallback=True,
            structured_text=self._format_diplomatic_text(fallback_title, fallback_content, recipient_name, 'fallback', True),
        )
        if not self.client.enabled:
            return fallback

        context = self.build_prompt_context(game_state or {}, f'diplomatic note to {recipient_name}', [recipient_name])
        prompt_variants = [
            (
                self._build_structured_prompt(
                    task='Write one formal diplomatic note for a space strategy game faction leader.',
                    output_schema={
                        'title': 'Chinese title with 8-18 characters',
                        'content': 'single Chinese paragraph with 40-80 characters',
                    },
                    hard_rules=[
                        'Title must be Chinese and should not contain book-title marks.',
                        'Content must be a single paragraph in Chinese.',
                        'Content must reflect relationship_level and tone.',
                        'Do not mention JSON, model, schema, or example.',
                        'Do not return empty strings.',
                    ],
                    input_payload={
                        'sender_name': self.leader_name,
                        'recipient_name': recipient_name,
                        'relationship_level': relationship_level,
                        'tone': tone,
                    } | context,
                    example_output={
                        'title': '边境贸易照会',
                        'content': '请贵方谨慎评估当前局势，并就后续边境安排向我方作出明确答复。',
                    },
                ),
                120,
            ),
            (
                self._build_structured_prompt(
                    task='Return one short diplomatic note.',
                    output_schema={
                        'title': 'short Chinese title',
                        'content': 'single short Chinese paragraph',
                    },
                    hard_rules=[
                        'Keep title within 12 Chinese characters.',
                        'Keep content within 50 Chinese characters.',
                        'Use formal and tense diplomatic tone.',
                        'Output JSON only.',
                    ],
                    input_payload={
                        'sender_name': self.leader_name,
                        'recipient_name': recipient_name,
                        'relationship_level': relationship_level,
                        'tone': tone,
                    } | context,
                    example_output={
                        'title': '正式照会',
                        'content': '请就当前边境与合作议题尽快回复。',
                    },
                ),
                80,
            ),
        ]

        for prompt, max_tokens in prompt_variants:
            try:
                raw = self.client.generate_text(prompt, max_output_tokens=max_tokens)
                data = self._extract_json(raw)
                title = self._review_text_output(str(data.get('title') or ''), 24)
                content = self._review_text_output(str(data.get('content') or ''), 120)
                if not title or not content:
                    continue
                return DiplomaticDraft(
                    title=title,
                    content=content,
                    source='bailian',
                    is_fallback=False,
                    structured_text=self._format_diplomatic_text(title, content, recipient_name, 'bailian', False),
                )
            except (ValueError, KeyError, TypeError, RuntimeError, TimeoutError, OSError, error.URLError, error.HTTPError, json.JSONDecodeError):
                continue

        return fallback

    def reply_to_player_message(
        self,
        recipient_name: str,
        relationship_level: str,
        tone: str,
        player_message: str,
        visibility_level: str,
        intent_type: str = 'MESSAGE',
        intent_detail: str = '',
        game_state: dict[str, Any] | None = None,
    ) -> ConversationReply:
        fallback_title = f'{self.leader_name} 的回函'
        fallback_content = (
            f'我方已收到你关于“{player_message[:24]}”的来信。'
            f'基于当前 {relationship_level} 关系，我方会以 {tone} 立场回应这次 {intent_type} 接触。'
        )
        fallback = ConversationReply(
            title=fallback_title,
            content=fallback_content,
            tone=tone,
            source='fallback',
            is_fallback=True,
            structured_text=self._format_conversation_text(fallback_title, fallback_content, recipient_name, visibility_level, 'fallback', True),
        )
        if not self.client.enabled:
            return fallback

        context = self.build_prompt_context(game_state or {}, player_message, [recipient_name])
        prompt = self._build_structured_prompt(
            task='Reply to a player diplomatic message in a space strategy game. Keep the response in-character and strategically meaningful.',
            output_schema={
                'title': 'Chinese diplomatic reply title',
                'content': 'single Chinese paragraph between 40 and 120 characters',
                'tone': 'friendly|neutral|firm|hostile',
            },
            hard_rules=[
                'Return exactly one JSON object.',
                'Content must be in Chinese.',
                'Use the sender personality and relationship_level to shape the reply.',
                'Use intent_type and intent_detail to decide whether this is trade, treaty, warning, or general contact.',
                'Acknowledge the player message without quoting it verbatim for more than 16 characters.',
                'Do not mention model, schema, JSON, or system prompts.',
            ],
            input_payload={
                'sender_name': self.leader_name,
                'sender_faction': self.faction_name,
                'recipient_name': recipient_name,
                'relationship_level': relationship_level,
                'requested_tone': tone,
                'visibility_level': visibility_level,
                'intent_type': intent_type,
                'intent_detail': intent_detail,
                'player_message': player_message,
            } | context,
            example_output={
                'title': '关于边境局势的回函',
                'content': '我方已收到你的来信。若贵方愿以克制和明确条款推进谈判，我方愿继续评估后续合作空间。',
                'tone': 'neutral',
            },
        )

        try:
            raw = self.client.generate_text(prompt, max_output_tokens=220)
            data = self._extract_json(raw)
            title = self._review_text_output(str(data.get('title') or ''), 24)
            content = self._review_text_output(str(data.get('content') or ''), 160)
            reply_tone = str(data.get('tone') or tone).strip().lower()
            if not title or not content:
                return fallback
            if reply_tone not in {'friendly', 'neutral', 'firm', 'hostile'}:
                reply_tone = tone
            return ConversationReply(
                title=title,
                content=content,
                tone=reply_tone,
                source='bailian',
                is_fallback=False,
                structured_text=self._format_conversation_text(title, content, recipient_name, visibility_level, 'bailian', False),
            )
        except (ValueError, KeyError, TypeError, RuntimeError, TimeoutError, OSError, error.URLError, error.HTTPError, json.JSONDecodeError):
            return fallback
