from __future__ import annotations

from typing import Any, Literal

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from ai_agent import AIAgent, Personality


app = FastAPI(title='MeowStellar Backend', version='0.2.0')
app.add_middleware(
    CORSMiddleware,
    allow_origins=['http://127.0.0.1:4173', 'http://localhost:4173', 'http://127.0.0.1:5173', 'http://localhost:5173'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)


class AIDecisionRequest(BaseModel):
    leader_name: str
    faction_name: str
    personality: dict[str, float]
    game_state: dict = Field(default_factory=dict)


class StructuredAIResponse(BaseModel):
    format_version: str
    source: Literal['bailian', 'fallback']
    is_fallback: bool
    structured_text: str


class AIDecisionResponse(StructuredAIResponse):
    action: Literal['BUILD', 'EXPLORE', 'TRADE', 'DECLARE_WAR', 'WAIT']
    target: str | None = None
    reasoning: str


class DiplomaticMessageRequest(BaseModel):
    sender_name: str
    recipient_name: str
    relationship_level: str
    tone: str = 'neutral'
    personality: dict[str, float] | None = None


class DiplomaticMessageResponse(StructuredAIResponse):
    title: str
    content: str


class ConversationRequest(BaseModel):
    sender_name: str
    recipient_name: str
    relationship_level: str
    tone: str = 'neutral'
    visibility_level: Literal['PUBLIC', 'RESTRICTED', 'SECRET', 'ENCRYPTED'] = 'PUBLIC'
    player_message: str
    intent_type: str = 'MESSAGE'
    intent_detail: str = ''
    personality: dict[str, float] | None = None


class ConversationResponse(StructuredAIResponse):
    title: str
    content: str
    tone: str


class FleetMoveRequest(BaseModel):
    fleet_id: str
    target_system_id: str
    game_state: dict[str, Any]


class FleetMoveResponse(BaseModel):
    ok: bool
    reason: str
    energy_cost: int
    reachable_targets: list[str]


class ConstructionManageRequest(BaseModel):
    system_id: str
    target_id: str
    kind: Literal['BUILDING', 'SHIP']
    game_state: dict[str, Any]


class ConstructionManageResponse(BaseModel):
    ok: bool
    reason: str
    projected_turns: int
    queue_depth: int


class WorldQueryRequest(BaseModel):
    focus_system_id: str | None = None
    game_state: dict[str, Any]


class TreatySummary(BaseModel):
    id: str
    type: str
    status: str
    counterpart: str


class QueueSummary(BaseModel):
    id: str
    systemId: str
    displayName: str
    turnsRemaining: int


class VisibleSystemSummary(BaseModel):
    id: str
    name: str
    ownerId: str | None = None
    value: int


class WorldQueryResponse(BaseModel):
    summary: str
    visible_systems: list[VisibleSystemSummary]
    treaties: list[TreatySummary]
    queue: list[QueueSummary]
    pending_proposals: list[dict[str, Any]] = Field(default_factory=list)
    diplomatic_memories: list[dict[str, Any]] = Field(default_factory=list)
    strategic_posture: dict[str, Any] = Field(default_factory=dict)
    intelligence_feed: list[dict[str, Any]] = Field(default_factory=list)


class RelationshipQueryRequest(BaseModel):
    faction_a_id: str
    faction_b_id: str
    game_state: dict[str, Any]


class RelationshipQueryResponse(BaseModel):
    trust_score: int
    utility_score: int
    fear_score: int
    affection_score: int
    memory_impact: int
    relationship_level: str
    recent_events: list[str] = Field(default_factory=list)


class ProposalEvaluateRequest(BaseModel):
    proposal_id: str
    evaluator_faction_id: str
    game_state: dict[str, Any]


class ProposalEvaluateResponse(BaseModel):
    acceptance_score: int
    key_concerns: list[str] = Field(default_factory=list)
    counter_proposal: dict[str, Any] | None = None
    recommended_action: Literal['ACCEPT', 'REJECT', 'COUNTER']


class FleetStatusRequest(BaseModel):
    fleet_id: str
    include_units: bool = True
    game_state: dict[str, Any]


class FleetStatusResponse(BaseModel):
    location: str
    mission: str
    strength: int
    unit_composition: list[dict[str, Any]] = Field(default_factory=list)
    readiness: Literal['FULL', 'DEGRADED', 'CRITICAL']


class TacticalApproachRequest(BaseModel):
    attacker_fleet_id: str
    defender_fleet_id: str | None = None
    target_system_id: str
    attack_objective: Literal['DESTROY_ENEMY', 'OCCUPY', 'RAID'] = 'OCCUPY'
    game_state: dict[str, Any]


class TacticalApproachResponse(BaseModel):
    recommended_tactics: str
    expected_outcomes: list[str] = Field(default_factory=list)
    risk_assessments: list[str] = Field(default_factory=list)


class WorldStateQueryRequest(BaseModel):
    query_filter: str = 'ALL'
    metrics: list[str] = Field(default_factory=list)
    game_state: dict[str, Any]


class WorldStateQueryResponse(BaseModel):
    matching_entities: list[dict[str, Any]] = Field(default_factory=list)
    statistics: dict[str, Any] = Field(default_factory=dict)
    balance_assessment: Literal['BALANCED', 'SLIGHTLY_UNBALANCED', 'UNBALANCED', 'CRITICAL']
    strategic_posture: dict[str, Any] = Field(default_factory=dict)


class NarrativeEventRequest(BaseModel):
    event_template_id: str
    target_location: str
    affected_factions: list[str] = Field(default_factory=list)
    narrative_override: str | None = None
    outcome_modifiers: dict[str, float] = Field(default_factory=dict)
    game_state: dict[str, Any]


class NarrativeEventResponse(BaseModel):
    event_id: str
    narrative_content: str
    immediate_effects: list[str] = Field(default_factory=list)
    follow_up_options: list[str] = Field(default_factory=list)


class ResourceStatusRequest(BaseModel):
    faction_id: str
    scope: str = 'GLOBAL'
    system_id: str | None = None
    game_state: dict[str, Any]


class ResourceStatusResponse(BaseModel):
    food: dict[str, int]
    minerals: dict[str, int]
    industry: dict[str, int]
    energy: dict[str, int]
    balance_warning: list[str] = Field(default_factory=list)


class CombatProtocolRequest(BaseModel):
    fleet_id: str
    target_type: Literal['FLEET', 'PLANET', 'STATION'] = 'FLEET'
    target_id: str
    engagement_rules: Literal['ALL_OUT', 'HIT_AND_RUN', 'DEFENSIVE'] = 'ALL_OUT'
    formation: Literal['WEDGE', 'LINE', 'SPHERE'] = 'LINE'
    game_state: dict[str, Any]


class CombatProtocolResponse(BaseModel):
    status: Literal['READY', 'INVALID', 'AUTO_DECLARE_WAR']
    victory: bool | None = None
    casualties: int = 0
    kills: int = 0
    remaining_power: int = 0
    tactical_notes: list[str] = Field(default_factory=list)


class DirectorInterventionRequest(BaseModel):
    intervention_type: Literal['SPAWN_PIRATES', 'BOOST_AI', 'REDUCE_RESOURCES', 'TRIGGER_CRISIS']
    intensity: float = 0.5
    target_scope: str = 'GLOBAL'
    duration: int = 3
    game_state: dict[str, Any]


class DirectorInterventionResponse(BaseModel):
    intervention_id: str
    effects_summary: list[str] = Field(default_factory=list)
    player_perception: Literal['VISIBLE', 'SUBTLE', 'HIDDEN']


def _find_player(game_state: dict[str, Any]) -> dict[str, Any] | None:
    for faction in game_state.get('factions', []):
        if faction.get('isPlayer'):
            return faction
    return None


def _connected_to(game_state: dict[str, Any], system_id: str) -> list[str]:
    result: list[str] = []
    for lane in game_state.get('hyperlanes', []):
        if lane.get('startSystemId') == system_id:
            result.append(str(lane.get('endSystemId')))
        elif lane.get('endSystemId') == system_id:
            result.append(str(lane.get('startSystemId')))
    return result


def _system_value(system: dict[str, Any]) -> int:
    resources = system.get('resources', {})
    return int(resources.get('food', 0) + resources.get('minerals', 0) * 3 + resources.get('industry', 0) * 2 + resources.get('energy', 0) * 3)


def _find_relation(game_state: dict[str, Any], faction_a_id: str, faction_b_id: str) -> dict[str, Any] | None:
    for relation in game_state.get('relationships', []):
        a_matches = relation.get('factionAId') == faction_a_id and relation.get('factionBId') == faction_b_id
        b_matches = relation.get('factionAId') == faction_b_id and relation.get('factionBId') == faction_a_id
        if a_matches or b_matches:
            return relation
    return None


def _relation_breakdown(game_state: dict[str, Any], faction_a_id: str, faction_b_id: str) -> dict[str, Any]:
    relation = _find_relation(game_state, faction_a_id, faction_b_id) or {}
    return {
        'trust': int(relation.get('trust', 0)),
        'utility': int(relation.get('utility', 0)),
        'fear': int(relation.get('fear', 0)),
        'affinity': int(relation.get('affinity', 0)),
        'memoryImpact': int(relation.get('memoryImpact', 0)),
        'level': str(relation.get('level', 'UNKNOWN')),
    }


def _relation_history(game_state: dict[str, Any], faction_a_id: str, faction_b_id: str, limit: int = 4) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for snapshot in game_state.get('relationshipHistory', []):
        a_matches = snapshot.get('factionAId') == faction_a_id and snapshot.get('factionBId') == faction_b_id
        b_matches = snapshot.get('factionAId') == faction_b_id and snapshot.get('factionBId') == faction_a_id
        if a_matches or b_matches:
            results.append(snapshot)
    results = list(reversed(results))
    return results[-limit:] if len(results) > limit else results


def _strategic_posture(game_state: dict[str, Any], source_faction_id: str = 'f_player') -> dict[str, Any]:
    high_pressure: list[str] = []
    high_opportunity: list[str] = []
    deteriorating: list[str] = []
    improving: list[str] = []
    flashpoints: list[str] = []
    for faction in game_state.get('factions', []):
        faction_id = str(faction.get('id', ''))
        if faction_id == source_faction_id:
            continue
        relation = _relation_breakdown(game_state, source_faction_id, faction_id)
        history = _relation_history(game_state, source_faction_id, faction_id, 3)
        previous = history[-2] if len(history) >= 2 else {}
        trust_delta = int(relation.get('trust', 0)) - int(previous.get('trust', relation.get('trust', 0)))
        fear_delta = int(relation.get('fear', 0)) - int(previous.get('fear', relation.get('fear', 0)))
        memory_delta = int(relation.get('memoryImpact', 0)) - int(previous.get('memoryImpact', relation.get('memoryImpact', 0)))
        pressure_score = max(int(relation.get('fear', 0)), -int(relation.get('trust', 0))) + max(fear_delta, memory_delta, 0)
        opportunity_score = int(relation.get('trust', 0)) + int(relation.get('utility', 0)) + max(trust_delta, 0)
        faction_name = str(faction.get('name', faction_id))
        if pressure_score >= 45:
            high_pressure.append(faction_name)
        if opportunity_score >= 40:
            high_opportunity.append(faction_name)
        if fear_delta > 0 or trust_delta < 0 or memory_delta > 0:
            deteriorating.append(faction_name)
        if trust_delta > 0 and int(relation.get('utility', 0)) >= 15:
            improving.append(faction_name)
        if pressure_score >= 55:
            flashpoints.append(faction_name)
    recommended_posture = 'CONSOLIDATE'
    if flashpoints:
        recommended_posture = 'CONTAIN'
    elif high_opportunity and not high_pressure:
        recommended_posture = 'EXPAND_DIPLOMACY'
    elif deteriorating:
        recommended_posture = 'STABILIZE'
    return {
        'high_pressure': high_pressure,
        'high_opportunity': high_opportunity,
        'deteriorating': deteriorating,
        'improving': improving,
        'flashpoints': flashpoints,
        'recommended_posture': recommended_posture,
    }


def _recent_intelligence_feed(game_state: dict[str, Any], limit: int = 8) -> list[dict[str, Any]]:
    feed: list[dict[str, Any]] = []
    for report in game_state.get('combatReports', [])[:6]:
        feed.append({
            'turn': int(report.get('turn', 0)),
            'priority': 5,
            'category': 'COMBAT',
            'title': str(report.get('title', '战斗报告')),
            'summary': f"{report.get('attackerName', '进攻方')} vs {report.get('defenderName', '防守方')} / {'胜利' if report.get('victory') else '失利'} / 剩余战力 {report.get('remainingPower', 0)}%",
        })
    for event_item in game_state.get('activeNarrativeEvents', [])[:6]:
        if event_item.get('status', 'ACTIVE') != 'ACTIVE':
            continue
        feed.append({
            'turn': int(event_item.get('turnCreated', game_state.get('turn', 1))),
            'priority': 4,
            'category': 'EVENT',
            'title': str(event_item.get('title', '叙事事件')),
            'summary': str(event_item.get('summary', '')),
        })
    for memory in game_state.get('diplomaticMemories', [])[:6]:
        feed.append({
            'turn': int(memory.get('turn', 0)),
            'priority': 3 + int(memory.get('importance', 1)),
            'category': 'DIPLOMACY',
            'title': str(memory.get('title', '外交记忆')),
            'summary': str(memory.get('summary', memory.get('title', '外交记忆'))),
        })
    for message in game_state.get('messages', [])[:6]:
        feed.append({
            'turn': int(message.get('turn', 0)),
            'priority': 2,
            'category': str(message.get('type', 'EVENT')),
            'title': str(message.get('title', '情报')),
            'summary': str(message.get('content', '')),
        })
    feed.sort(key=lambda item: (int(item.get('turn', 0)), int(item.get('priority', 0))), reverse=True)
    return feed[:limit]


def _faction_name(game_state: dict[str, Any], faction_id: str) -> str:
    for faction in game_state.get('factions', []):
        if faction.get('id') == faction_id:
            return str(faction.get('name', faction_id))
    return faction_id


def _system_name(game_state: dict[str, Any], system_id: str) -> str:
    for system in game_state.get('starSystems', []):
        if system.get('id') == system_id:
            return str(system.get('name', system_id))
    return system_id


def _fleet_strength(fleet: dict[str, Any]) -> int:
    return int(sum(int(ship.get('hp', 0)) + int(ship.get('damage', 0)) * 3 for ship in fleet.get('ships', [])))

def _fleet_mission_label(mission: str) -> str:
    return {
        'IDLE': '待命',
        'EXPLORE': '自动探索',
        'COLONIZE': '殖民部署',
        'GUARD': '驻防警戒',
        'STRIKE': '前线打击',
    }.get(mission, mission)



def _resource_rates(game_state: dict[str, Any], faction_id: str) -> dict[str, int]:
    rates = {'food': 0, 'minerals': 0, 'industry': 0, 'energy': 0}
    for system in game_state.get('starSystems', []):
        if system.get('ownerId') != faction_id:
            continue
        resources = system.get('resources', {})
        rates['food'] += int(resources.get('food', 0))
        rates['minerals'] += int(resources.get('minerals', 0))
        rates['industry'] += int(resources.get('industry', 0))
        rates['energy'] += int(resources.get('energy', 0))
        for building in system.get('buildings', []):
            output = building.get('output', {})
            upkeep = building.get('upkeep', {})
            for key in rates:
                rates[key] += int(output.get(key, 0))
                rates[key] -= int(upkeep.get(key, 0))
    return rates


@app.get('/api/health')
async def health() -> dict[str, str]:
    return {'status': 'ok'}


@app.post('/api/ai/decide', response_model=AIDecisionResponse)
async def decide(payload: AIDecisionRequest) -> AIDecisionResponse:
    personality = Personality(**payload.personality)
    agent = AIAgent(payload.leader_name, payload.faction_name, personality)
    result = agent.decide(payload.game_state)
    return AIDecisionResponse(
        format_version=result.format_version,
        source=result.source,
        is_fallback=result.is_fallback,
        structured_text=result.structured_text,
        action=result.action,
        target=result.target,
        reasoning=result.reasoning,
    )


@app.post('/api/ai/diplomatic-message', response_model=DiplomaticMessageResponse)
async def diplomatic_message(payload: DiplomaticMessageRequest) -> DiplomaticMessageResponse:
    default_personality = payload.personality or {
        'aggression': 4,
        'paranoia': 5,
        'greed': 5,
        'loyalty': 6,
        'rationality': 8,
    }
    personality = Personality(**default_personality)
    agent = AIAgent(payload.sender_name, payload.sender_name, personality)
    draft = agent.diplomatic_message(payload.recipient_name, payload.relationship_level, payload.tone)
    return DiplomaticMessageResponse(
        format_version=draft.format_version,
        source=draft.source,
        is_fallback=draft.is_fallback,
        structured_text=draft.structured_text,
        title=draft.title,
        content=draft.content,
    )


@app.post('/api/ai/conversation', response_model=ConversationResponse)
async def ai_conversation(payload: ConversationRequest) -> ConversationResponse:
    default_personality = payload.personality or {
        'aggression': 4,
        'paranoia': 5,
        'greed': 5,
        'loyalty': 6,
        'rationality': 8,
    }
    personality = Personality(**default_personality)
    agent = AIAgent(payload.recipient_name, payload.recipient_name, personality)
    reply = agent.reply_to_player_message(
        payload.sender_name,
        payload.relationship_level,
        payload.tone,
        payload.player_message,
        payload.visibility_level,
        payload.intent_type,
        payload.intent_detail,
    )
    return ConversationResponse(
        format_version=reply.format_version,
        source=reply.source,
        is_fallback=reply.is_fallback,
        structured_text=reply.structured_text,
        title=reply.title,
        content=reply.content,
        tone=reply.tone,
    )


@app.post('/api/fleet/move', response_model=FleetMoveResponse)
async def fleet_move(payload: FleetMoveRequest) -> FleetMoveResponse:
    player = _find_player(payload.game_state)
    fleet = next((item for item in payload.game_state.get('fleets', []) if item.get('id') == payload.fleet_id), None)
    if not player or not fleet:
        return FleetMoveResponse(ok=False, reason='未找到舰队或玩家状态。', energy_cost=0, reachable_targets=[])
    if fleet.get('ownerId') != player.get('id'):
        return FleetMoveResponse(ok=False, reason='仅允许玩家舰队执行跃迁。', energy_cost=0, reachable_targets=[])
    reachable_targets = _connected_to(payload.game_state, str(fleet.get('systemId')))
    lane = next((item for item in payload.game_state.get('hyperlanes', []) if {item.get('startSystemId'), item.get('endSystemId')} == {fleet.get('systemId'), payload.target_system_id}), None)
    energy_cost = int((lane or {}).get('traversalCost', 1))
    if payload.target_system_id not in reachable_targets:
        return FleetMoveResponse(ok=False, reason='目标星系不在可跃迁范围内。', energy_cost=energy_cost, reachable_targets=reachable_targets)
    if player.get('resources', {}).get('energy', 0) < energy_cost:
        return FleetMoveResponse(ok=False, reason='能源不足，无法通过跃迁校验。', energy_cost=energy_cost, reachable_targets=reachable_targets)
    return FleetMoveResponse(ok=True, reason='跃迁校验通过。', energy_cost=energy_cost, reachable_targets=reachable_targets)


@app.post('/api/construction/manage', response_model=ConstructionManageResponse)
async def construction_manage(payload: ConstructionManageRequest) -> ConstructionManageResponse:
    queue = payload.game_state.get('constructionQueue', [])
    same_system = [item for item in queue if item.get('systemId') == payload.system_id]
    projected_turns = 1 if payload.kind == 'SHIP' and payload.target_id == 'CORVETTE' else 2
    if payload.kind == 'SHIP' and payload.target_id == 'CRUISER':
        projected_turns = 3
    if payload.kind == 'SHIP' and payload.target_id == 'BATTLESHIP':
        projected_turns = 4
    if any(item.get('systemId') == payload.system_id and str(item.get('targetId')) == payload.target_id for item in queue):
        return ConstructionManageResponse(ok=False, reason='该项目已在当前星系的建造队列中。', projected_turns=projected_turns, queue_depth=len(same_system))
    return ConstructionManageResponse(ok=True, reason='建造请求已通过校验。', projected_turns=projected_turns, queue_depth=len(same_system) + 1)


@app.post('/api/world/query', response_model=WorldQueryResponse)
async def world_query(payload: WorldQueryRequest) -> WorldQueryResponse:
    game_state = payload.game_state
    player = _find_player(game_state)
    visible_systems = [
        VisibleSystemSummary(
            id=str(system.get('id')),
            name=str(system.get('name')),
            ownerId=system.get('ownerId'),
            value=_system_value(system),
        )
        for system in game_state.get('starSystems', [])
        if system.get('visibilityLevel') in {'FULL', 'PARTIAL'}
    ]
    treaties = []
    for treaty in game_state.get('treaties', []):
        if not player:
            continue
        if treaty.get('sourceFactionId') != player.get('id') and treaty.get('targetFactionId') != player.get('id'):
            continue
        counterpart = treaty.get('targetFactionId') if treaty.get('sourceFactionId') == player.get('id') else treaty.get('sourceFactionId')
        treaties.append(TreatySummary(id=str(treaty.get('id')), type=str(treaty.get('type')), status=str(treaty.get('status')), counterpart=str(counterpart)))
    queue = [QueueSummary(id=str(item.get('id')), systemId=str(item.get('systemId')), displayName=str(item.get('displayName')), turnsRemaining=int(item.get('turnsRemaining', 0))) for item in game_state.get('constructionQueue', [])]
    pending_proposals = [
        {
            'id': str(item.get('id')),
            'title': str(item.get('title', '外交提案')),
            'proposalType': str(item.get('proposalType', 'UNKNOWN')),
            'status': str(item.get('status', 'PENDING')),
            'expiresOnTurn': int(item.get('expiresOnTurn', 0)),
        }
        for item in game_state.get('pendingProposals', [])
        if item.get('targetFactionId') == (player or {}).get('id')
    ]
    diplomatic_memories = [
        {
            'turn': int(item.get('turn', 0)),
            'title': str(item.get('title', '外交记忆')),
            'category': str(item.get('category', 'EVENT')),
            'importance': int(item.get('importance', 1)),
        }
        for item in game_state.get('diplomaticMemories', [])[:8]
    ]
    focus_name = payload.focus_system_id or '当前星域'
    controlled = len((player or {}).get('controlledSystems', []))
    ascension = int(game_state.get('ascension_progress', game_state.get('ascensionProgress', 0)))
    strategic_posture = _strategic_posture(game_state, (player or {}).get('id', 'f_player'))
    intelligence_feed = _recent_intelligence_feed(game_state, 8)
    summary = (
        f'{focus_name} 情报已同步：可见星系 {len(visible_systems)} 个，活跃条约 {len([item for item in treaties if item.status == "ACTIVE"])} 份，'
        f'建造队列 {len(queue)} 项，待处理提案 {len([item for item in pending_proposals if item["status"] == "PENDING"])} 个，'
        f'控制星系 {controlled} 个，飞升进度 {ascension}/100，热点前线 {len(strategic_posture.get("flashpoints", []))} 处。'
    )
    return WorldQueryResponse(
        summary=summary,
        visible_systems=visible_systems,
        treaties=treaties,
        queue=queue,
        pending_proposals=pending_proposals,
        diplomatic_memories=diplomatic_memories,
        strategic_posture=strategic_posture,
        intelligence_feed=intelligence_feed,
    )


@app.post('/api/diplomacy/relationship', response_model=RelationshipQueryResponse)
async def query_relationship_status(payload: RelationshipQueryRequest) -> RelationshipQueryResponse:
    relation = _find_relation(payload.game_state, payload.faction_a_id, payload.faction_b_id) or {}
    recent_events: list[str] = []
    for item in payload.game_state.get('diplomaticMemories', [])[:12]:
        participants = item.get('participants', [])
        if payload.faction_a_id in participants and payload.faction_b_id in participants:
            recent_events.append(str(item.get('summary', item.get('title', '外交记忆'))))
        if len(recent_events) >= 4:
            break
    return RelationshipQueryResponse(
        trust_score=int(relation.get('trust', 0)),
        utility_score=int(relation.get('utility', 0)),
        fear_score=int(relation.get('fear', 0)),
        affection_score=int(relation.get('affinity', 0)),
        memory_impact=int(relation.get('memoryImpact', 0)),
        relationship_level=str(relation.get('level', 'UNKNOWN')),
        recent_events=recent_events,
    )


@app.post('/api/diplomacy/evaluate-proposal', response_model=ProposalEvaluateResponse)
async def evaluate_diplomatic_proposal(payload: ProposalEvaluateRequest) -> ProposalEvaluateResponse:
    proposal = next((item for item in payload.game_state.get('pendingProposals', []) if item.get('id') == payload.proposal_id), None)
    if not proposal:
        return ProposalEvaluateResponse(
            acceptance_score=-100,
            key_concerns=['未找到对应外交提案。'],
            counter_proposal=None,
            recommended_action='REJECT',
        )

    relation = _find_relation(payload.game_state, proposal.get('senderFactionId', ''), payload.evaluator_faction_id) or {}
    trust = int(relation.get('trust', 0))
    utility = int(relation.get('utility', 0))
    fear = int(relation.get('fear', 0))
    proposal_type = str(proposal.get('proposalType', 'UNKNOWN'))
    concerns: list[str] = []
    score = trust + utility // 2 - fear // 3

    if proposal_type == 'ALLIANCE':
        score -= 10
        if trust < 60:
            concerns.append('当前互信仍不足以支撑正式同盟。')
    elif proposal_type == 'RESEARCH_ACCORD':
        score += 6
        if utility < 20:
            concerns.append('双方科研互补性尚不明显。')
    elif proposal_type == 'NON_AGGRESSION':
        score += 4
        if fear > 55:
            concerns.append('对方边境兵力仍然过强，停战承诺可信度不足。')
    elif proposal_type == 'TRADE_PACT':
        score += 8
        if utility < 10:
            concerns.append('当前贸易回报仍然偏低。')

    if trust <= -30:
        concerns.append('历史摩擦过多，近期关系不稳定。')
        score -= 18
    if fear >= 70:
        concerns.append('对方军事威慑过强，存在被迫接受条款的风险。')
        score -= 12

    recommended_action: Literal['ACCEPT', 'REJECT', 'COUNTER']
    counter_proposal: dict[str, Any] | None = None
    if score >= 25:
        recommended_action = 'ACCEPT'
    elif score <= -5:
        recommended_action = 'REJECT'
    else:
        recommended_action = 'COUNTER'
        counter_proposal = {
            'summary': f'建议先与 {_faction_name(payload.game_state, proposal.get("senderFactionId", ""))} 签订较温和的合作条款。',
            'preferred_type': 'NON_AGGRESSION' if proposal_type == 'ALLIANCE' else 'TRADE_PACT',
        }
        concerns.append('可先从较低承诺强度的协议开始试探。')

    return ProposalEvaluateResponse(
        acceptance_score=max(-100, min(100, score)),
        key_concerns=concerns,
        counter_proposal=counter_proposal,
        recommended_action=recommended_action,
    )


@app.post('/api/fleet/status', response_model=FleetStatusResponse)
async def query_fleet_status(payload: FleetStatusRequest) -> FleetStatusResponse:
    fleet = next((item for item in payload.game_state.get('fleets', []) if item.get('id') == payload.fleet_id), None)
    if not fleet:
        return FleetStatusResponse(location='未知', mission='未找到舰队', strength=0, unit_composition=[], readiness='CRITICAL')

    ships = list(fleet.get('ships', []))
    total_hp = sum(int(ship.get('hp', 0)) for ship in ships)
    total_max_hp = max(1, sum(int(ship.get('maxHp', 0)) for ship in ships))
    ratio = total_hp / total_max_hp
    readiness: Literal['FULL', 'DEGRADED', 'CRITICAL']
    if ratio >= 0.8:
        readiness = 'FULL'
    elif ratio >= 0.45:
        readiness = 'DEGRADED'
    else:
        readiness = 'CRITICAL'

    composition = []
    if payload.include_units:
        for ship in ships:
            composition.append({
                'name': str(ship.get('name', '未知舰船')),
                'type': str(ship.get('type', 'UNKNOWN')),
                'hp': int(ship.get('hp', 0)),
                'maxHp': int(ship.get('maxHp', 0)),
                'damage': int(ship.get('damage', 0)),
            })

    return FleetStatusResponse(
        location=_system_name(payload.game_state, str(fleet.get('systemId', '未知星系'))),
        mission=_fleet_mission_label(str(fleet.get('mission', 'IDLE'))),
        strength=_fleet_strength(fleet),
        unit_composition=composition,
        readiness=readiness,
    )


@app.post('/api/combat/tactical-approach', response_model=TacticalApproachResponse)
async def recommend_tactical_approach(payload: TacticalApproachRequest) -> TacticalApproachResponse:
    attacker = next((item for item in payload.game_state.get('fleets', []) if item.get('id') == payload.attacker_fleet_id), None)
    defender = next((item for item in payload.game_state.get('fleets', []) if item.get('id') == payload.defender_fleet_id), None) if payload.defender_fleet_id else None
    attacker_strength = _fleet_strength(attacker or {})
    defender_strength = _fleet_strength(defender or {})

    tactic = 'LINE'
    expected = ['以标准火力投送压制目标轨道。']
    risks = ['若敌方存在高闪避护卫舰，前排可能承受额外损失。']

    if payload.attack_objective == 'RAID':
        tactic = 'HIT_AND_RUN'
        expected = ['优先打击补给节点后迅速脱离。']
        risks = ['若撤离航线被封锁，轻舰损失会明显上升。']
    elif defender and attacker_strength < defender_strength:
        tactic = 'SPHERE'
        expected = ['建议保持防御阵型，拉长交战时间等待援军。']
        risks = ['正面歼灭能力不足，占领效率偏低。']
    elif payload.attack_objective == 'OCCUPY':
        tactic = 'WEDGE'
        expected = ['集中突击星系要害，有机会快速夺取控制权。']
        risks = ['前锋舰船会承受更高战损。']

    if defender and defender_strength > 0:
        expected.append(f'敌方当前估算战力约为 {defender_strength}。')
    expected.append(f'我方当前估算战力约为 {attacker_strength}。')

    return TacticalApproachResponse(
        recommended_tactics=tactic,
        expected_outcomes=expected,
        risk_assessments=risks,
    )


@app.post('/api/world/state', response_model=WorldStateQueryResponse)
async def query_world_state(payload: WorldStateQueryRequest) -> WorldStateQueryResponse:
    systems = payload.game_state.get('starSystems', [])
    factions = payload.game_state.get('factions', [])
    fleets = payload.game_state.get('fleets', [])
    militaries = [int(faction.get('militaryPower', 0)) for faction in factions]
    strongest = max(militaries) if militaries else 0
    weakest = min(militaries) if militaries else 0
    spread = strongest - weakest
    balance: Literal['BALANCED', 'SLIGHTLY_UNBALANCED', 'UNBALANCED', 'CRITICAL']
    if spread <= 60:
        balance = 'BALANCED'
    elif spread <= 140:
        balance = 'SLIGHTLY_UNBALANCED'
    elif spread <= 260:
        balance = 'UNBALANCED'
    else:
        balance = 'CRITICAL'

    matching_entities: list[dict[str, Any]] = []
    query = payload.query_filter.upper().strip()
    if query in {'ALL', '', 'SYSTEMS'}:
        matching_entities = [{'id': str(system.get('id')), 'name': str(system.get('name')), 'ownerId': system.get('ownerId'), 'value': _system_value(system)} for system in systems[:8]]
    elif 'UNOWNED' in query or 'NULL' in query:
        matching_entities = [{'id': str(system.get('id')), 'name': str(system.get('name')), 'value': _system_value(system)} for system in systems if system.get('ownerId') is None]
    elif 'FACTIONS' in query:
        matching_entities = [{'id': str(faction.get('id')), 'name': str(faction.get('name')), 'militaryPower': int(faction.get('militaryPower', 0)), 'population': int(faction.get('population', 0))} for faction in factions]
    elif 'FLEETS' in query:
        matching_entities = [{'id': str(fleet.get('id')), 'ownerId': str(fleet.get('ownerId')), 'location': _system_name(payload.game_state, str(fleet.get('systemId', ''))), 'strength': _fleet_strength(fleet)} for fleet in fleets]

    statistics = {
        'faction_count': len(factions),
        'fleet_count': len(fleets),
        'visible_system_count': len([system for system in systems if system.get('visibilityLevel') in {'FULL', 'PARTIAL'}]),
        'unowned_system_count': len([system for system in systems if system.get('ownerId') is None]),
        'average_military_power': int(sum(militaries) / len(militaries)) if militaries else 0,
        'war_count': len([treaty for treaty in payload.game_state.get('treaties', []) if treaty.get('type') == 'WAR_STATE' and treaty.get('status') == 'ACTIVE']),
    }
    return WorldStateQueryResponse(
        matching_entities=matching_entities,
        statistics=statistics,
        balance_assessment=balance,
        strategic_posture=_strategic_posture(payload.game_state),
    )


@app.post('/api/director/trigger-event', response_model=NarrativeEventResponse)
async def trigger_narrative_event(payload: NarrativeEventRequest) -> NarrativeEventResponse:
    system_name = _system_name(payload.game_state, payload.target_location)
    event_id = f'evt_{payload.event_template_id.lower()}_{payload.target_location}'

    default_narrative = {
        'ANCIENT_RUINS_DISCOVERY': f'{system_name} 的远古遗迹被重新激活，沉寂数据库开始吐出碎片化星图。',
        'PIRATE_RAID': f'{system_name} 周边出现海盗袭扰迹象，多支走私舰队正试图切断补给线。',
        'WARP_STORM': f'{system_name} 附近爆发跃迁风暴，局部航道稳定性明显下降。',
    }.get(payload.event_template_id, f'{system_name} 出现新的星际异象。')

    narrative = payload.narrative_override or default_narrative
    effects = []
    if payload.event_template_id == 'ANCIENT_RUINS_DISCOVERY':
        science_bonus = payload.outcome_modifiers.get('science_bonus', 1.0)
        effects.append(f'科研收益修正 x{science_bonus:.1f}')
        effects.append('可触发一次遗迹勘探奖励')
    elif payload.event_template_id == 'PIRATE_RAID':
        effects.append('目标星系周边安全度下降')
        effects.append('商路可能受到拦截')
    elif payload.event_template_id == 'WARP_STORM':
        effects.append('跃迁风险上升')
        effects.append('战术机动效率下降')

    follow_ups = ['派遣舰队调查', '发布公开通告', '保持观望']
    return NarrativeEventResponse(
        event_id=event_id,
        narrative_content=narrative,
        immediate_effects=effects,
        follow_up_options=follow_ups,
    )


@app.post('/api/resources/status', response_model=ResourceStatusResponse)
async def query_resource_status(payload: ResourceStatusRequest) -> ResourceStatusResponse:
    faction = next((item for item in payload.game_state.get('factions', []) if item.get('id') == payload.faction_id), None) or {}
    stock = faction.get('resources', {})
    rates = _resource_rates(payload.game_state, payload.faction_id)
    warnings: list[str] = []
    for key, label in [('food', '食物'), ('minerals', '矿产'), ('industry', '工业'), ('energy', '能源')]:
        if int(rates.get(key, 0)) < 0:
            warnings.append(f'{label}净产出为负，需尽快调整。')
    return ResourceStatusResponse(
        food={'stock': int(stock.get('food', 0)), 'net': int(rates.get('food', 0))},
        minerals={'stock': int(stock.get('minerals', 0)), 'net': int(rates.get('minerals', 0))},
        industry={'stock': int(stock.get('industry', 0)), 'net': int(rates.get('industry', 0))},
        energy={'stock': int(stock.get('energy', 0)), 'net': int(rates.get('energy', 0))},
        balance_warning=warnings,
    )


@app.post('/api/combat/initiate', response_model=CombatProtocolResponse)
async def initiate_combat_protocol(payload: CombatProtocolRequest) -> CombatProtocolResponse:
    attacker = next((item for item in payload.game_state.get('fleets', []) if item.get('id') == payload.fleet_id), None)
    if not attacker:
        return CombatProtocolResponse(status='INVALID', tactical_notes=['未找到进攻舰队。'])

    defender = None
    if payload.target_type == 'FLEET':
        defender = next((item for item in payload.game_state.get('fleets', []) if item.get('id') == payload.target_id), None)
    attacker_strength = _fleet_strength(attacker)
    defender_strength = _fleet_strength(defender or {})
    if payload.target_type == 'FLEET' and defender is None:
        return CombatProtocolResponse(status='INVALID', tactical_notes=['目标舰队不存在。'])

    modifier = 1.0
    notes = [f'交战规则: {payload.engagement_rules}', f'阵型: {payload.formation}']
    if payload.engagement_rules == 'HIT_AND_RUN':
        modifier *= 0.88
        notes.append('机动规避优先，歼灭效率下降。')
    elif payload.engagement_rules == 'ALL_OUT':
        modifier *= 1.08
        notes.append('全力突击，战损风险同步上升。')

    if payload.formation == 'WEDGE':
        modifier *= 1.12
        notes.append('楔形突击有利于快速撕开防线。')
    elif payload.formation == 'SPHERE':
        modifier *= 0.94
        notes.append('球形防御阵型提升生存能力。')

    adjusted_strength = int(attacker_strength * modifier)
    victory = adjusted_strength >= max(1, defender_strength)
    remaining_power = max(5, int((adjusted_strength - defender_strength) / max(1, adjusted_strength) * 100)) if victory else max(0, int((attacker_strength - defender_strength) / max(1, attacker_strength) * 100))
    casualties = max(1, int(len(attacker.get('ships', [])) * (0.2 if victory else 0.6)))
    kills = len((defender or {}).get('ships', [])) if victory else max(0, int(len((defender or {}).get('ships', [])) * 0.3))

    return CombatProtocolResponse(
        status='READY',
        victory=victory,
        casualties=casualties,
        kills=kills,
        remaining_power=remaining_power,
        tactical_notes=notes,
    )


@app.post('/api/director/intervention', response_model=DirectorInterventionResponse)
async def inject_director_intervention(payload: DirectorInterventionRequest) -> DirectorInterventionResponse:
    intervention_id = f"director_{payload.intervention_type.lower()}_{int(payload.intensity * 100)}"
    effects: list[str] = []
    perception: Literal['VISIBLE', 'SUBTLE', 'HIDDEN'] = 'SUBTLE'

    if payload.intervention_type == 'SPAWN_PIRATES':
        effects = [
            '将在边境生成海盗威胁点',
            f'持续 {payload.duration} 回合干扰补给线',
        ]
        perception = 'VISIBLE'
    elif payload.intervention_type == 'BOOST_AI':
        effects = [
            '目标 AI 获得临时产能与战备加成',
            f'强度系数 {payload.intensity:.2f}',
        ]
        perception = 'HIDDEN'
    elif payload.intervention_type == 'REDUCE_RESOURCES':
        effects = [
            '目标范围资源净产出将被压制',
            f'预计持续 {payload.duration} 回合',
        ]
        perception = 'SUBTLE'
    elif payload.intervention_type == 'TRIGGER_CRISIS':
        effects = [
            '将触发区域级危机链条',
            '多势力会被迫重新调整战略目标',
        ]
        perception = 'VISIBLE'

    return DirectorInterventionResponse(
        intervention_id=intervention_id,
        effects_summary=effects,
        player_perception=perception,
    )


