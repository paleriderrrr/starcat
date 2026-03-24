import { useEffect, useState } from 'react';
import StarMap from './components/StarMap';
import UI from './components/UI';
import { initialState } from './game/data';
import { cancelResearch, colonizeSystem, exploreSystem, moveFleet, processTurn, proposeTreaty, queueShipConstruction, queueStructure, reachableSystems, repairFleet, startResearch, tradeWithFaction, threatenFaction } from './game/logic';
import type { BackendAIDecision, BackendConstructionResponse, BackendDiplomaticMessage, BackendFleetMoveResponse, BackendWorldQueryResponse, BuildingBlueprint, GameState, Relationship, ShipType, StarSystem, TreatyType } from './game/types';

const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://127.0.0.1:8000';
const systemValue = (system: StarSystem) => system.resources.food + system.resources.minerals * 3 + system.resources.industry * 2 + system.resources.energy * 3;
const relationWithPlayer = (state: GameState): Relationship | undefined => state.relationships.find((item) => (item.factionAId === 'f_player' && item.factionBId === 'f_merchant') || (item.factionAId === 'f_merchant' && item.factionBId === 'f_player'));
const postJson = async <T,>(path: string, payload: Record<string, unknown>): Promise<T> => {
  const response = await fetch(`${API_BASE}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
  if (!response.ok) throw new Error(`API error: ${response.status}`);
  return response.json();
};

export default function App() {
  const [gameState, setGameState] = useState(initialState);
  const [selectedSystemId, setSelectedSystemId] = useState<string | null>(null);
  const [selectedFleetId, setSelectedFleetId] = useState<string | null>(null);
  const [labelsVisible, setLabelsVisible] = useState(true);
  const [backendStatus, setBackendStatus] = useState<'checking' | 'online' | 'offline'>('checking');
  const [aiAdvice, setAiAdvice] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [turnLoading, setTurnLoading] = useState(false);
  const [diplomacyLoading, setDiplomacyLoading] = useState(false);
  const [diplomaticMessage, setDiplomaticMessage] = useState<BackendDiplomaticMessage | null>(null);
  const [worldData, setWorldData] = useState<BackendWorldQueryResponse | null>(null);
  const [worldLoading, setWorldLoading] = useState(false);

  const isPlaying = gameState.status === 'PLAYING';
  const reachableSystemIds = reachableSystems(gameState, selectedFleetId);

  useEffect(() => {
    fetch(`${API_BASE}/api/health`).then((response) => response.json()).then(() => setBackendStatus('online')).catch(() => setBackendStatus('offline'));
  }, []);

  const resetGame = () => {
    setGameState(initialState);
    setSelectedSystemId(null);
    setSelectedFleetId(null);
    setAiAdvice('');
    setDiplomaticMessage(null);
    setWorldData(null);
  };

  const clearContextSelection = () => {
    setSelectedSystemId(null);
    setSelectedFleetId(null);
  };

  const requestWorldQuery = async (focusSystemId?: string | null) => {
    setWorldLoading(true);
    try {
      const result = await postJson<BackendWorldQueryResponse>('/api/world/query', { focus_system_id: focusSystemId ?? selectedSystemId, game_state: gameState });
      setWorldData(result);
      setBackendStatus('online');
    } catch {
      setBackendStatus('offline');
    } finally {
      setWorldLoading(false);
    }
  };

  const requestAiAdvice = async () => {
    const player = gameState.factions.find((faction) => faction.isPlayer);
    if (!player) return;
    setAiLoading(true);
    try {
      const result = await postJson<BackendAIDecision>('/api/ai/decide', { leader_name: player.leaderName, faction_name: player.name, personality: player.personality, game_state: { turn: gameState.turn, era: gameState.era, resources: player.resources, owned_systems: player.controlledSystems, visible_neutral_systems: gameState.starSystems.filter((system) => !system.ownerId && system.visibilityLevel === 'FULL').map((system) => ({ id: system.id, name: system.name, value: systemValue(system) })), relation_trust: relationWithPlayer(gameState)?.trust ?? 0, rival_relations: gameState.relationships } });
      setAiAdvice(result.structured_text);
      setBackendStatus('online');
    } catch {
      setAiAdvice('后端未响应，当前无法获取 AI 建议。');
      setBackendStatus('offline');
    } finally {
      setAiLoading(false);
    }
  };

  const requestMerchantTurnDecision = async (state: GameState): Promise<BackendAIDecision | null> => {
    const merchant = state.factions.find((faction) => faction.id === 'f_merchant');
    const merchantFleet = state.fleets.find((fleet) => fleet.ownerId === 'f_merchant');
    const merchantHome = state.starSystems.find((system) => system.ownerId === 'f_merchant');
    if (!merchant || !merchantHome) return null;
    const connectedIds = merchantFleet ? state.hyperlanes.flatMap((lane) => lane.startSystemId === merchantFleet.systemId ? [lane.endSystemId] : lane.endSystemId === merchantFleet.systemId ? [lane.startSystemId] : []) : [];
    const visibleNeutralSystems = state.starSystems.filter((system) => !system.ownerId && (system.visibilityLevel === 'FULL' || connectedIds.includes(system.id))).map((system) => ({ id: system.id, name: system.name, value: systemValue(system) }));
    const relation = relationWithPlayer(state);
    const availableBuildTargets = ['CORVETTE'];
    if (state.turn >= 9) availableBuildTargets.push('DESTROYER');
    if (state.turn >= 13) availableBuildTargets.push('CRUISER');
    try {
      const result = await postJson<BackendAIDecision>('/api/ai/decide', { leader_name: merchant.leaderName, faction_name: merchant.name, personality: merchant.personality, game_state: { turn: state.turn, era: state.era, resources: merchant.resources, owned_systems: merchant.controlledSystems, visible_neutral_systems: visibleNeutralSystems, relation_trust: relation?.trust ?? 0, home_system_id: merchantHome.id, home_has_shipyard: merchantHome.buildings.some((building) => building.type === 'SHIPYARD'), available_build_targets: availableBuildTargets, can_attack_player: !!merchantFleet && connectedIds.includes('sys_cat_home'), player_system_id: 'sys_cat_home' } });
      setBackendStatus('online');
      setAiAdvice(result.structured_text);
      return result;
    } catch {
      setBackendStatus('offline');
      setAiAdvice('后端离线，本回合已回退为本地 AI 逻辑。');
      return null;
    }
  };

  const requestDiplomaticMessage = async (factionId: string, tone: 'friendly' | 'firm') => {
    const player = gameState.factions.find((faction) => faction.isPlayer);
    const target = gameState.factions.find((faction) => faction.id === factionId);
    const relation = player ? gameState.relationships.find((item) => (item.factionAId === player.id && item.factionBId === factionId) || (item.factionAId === factionId && item.factionBId === player.id)) : undefined;
    if (!player || !target) return;
    setDiplomacyLoading(true);
    try {
      const result = await postJson<BackendDiplomaticMessage>('/api/ai/diplomatic-message', { sender_name: player.leaderName, recipient_name: target.name, relationship_level: relation?.level ?? 'NEUTRAL', tone, personality: player.personality });
      setDiplomaticMessage(result);
      setAiAdvice(result.structured_text);
      setBackendStatus('online');
    } catch {
      setBackendStatus('offline');
    } finally {
      setDiplomacyLoading(false);
    }
  };

  const handleNextTurn = async () => {
    if (!isPlaying || turnLoading) return;
    setTurnLoading(true);
    const decision = await requestMerchantTurnDecision(gameState);
    setGameState((state) => processTurn(state, decision ?? undefined));
    setTurnLoading(false);
  };

  const handleMoveFleet = async (systemId: string) => {
    if (!isPlaying || !selectedFleetId) return;
    try {
      const result = await postJson<BackendFleetMoveResponse>('/api/fleet/move', { fleet_id: selectedFleetId, target_system_id: systemId, game_state: gameState });
      if (!result.ok) {
        setAiAdvice(result.reason);
        return;
      }
    } catch {}
    setGameState((state) => moveFleet(state, selectedFleetId, systemId));
    setSelectedSystemId(systemId);
  };

  const handleQueueBuild = async (type: BuildingBlueprint['type'], systemId: string) => {
    try {
      const result = await postJson<BackendConstructionResponse>('/api/construction/manage', { system_id: systemId, target_id: type, kind: 'BUILDING', game_state: gameState });
      if (!result.ok) {
        setAiAdvice(result.reason);
        return;
      }
    } catch {}
    setGameState((state) => queueStructure(state, systemId, type));
  };

  const handleQueueShip = async (systemId: string, type: ShipType) => {
    try {
      const result = await postJson<BackendConstructionResponse>('/api/construction/manage', { system_id: systemId, target_id: type, kind: 'SHIP', game_state: gameState });
      if (!result.ok) {
        setAiAdvice(result.reason);
        return;
      }
    } catch {}
    setGameState((state) => queueShipConstruction(state, systemId, type));
  };

  const handleTreaty = (factionId: string, treatyType: TreatyType) => {
    setGameState((state) => proposeTreaty(state, factionId, treatyType));
    requestDiplomaticMessage(factionId, 'friendly');
  };

  const handleSelectSystem = (systemId: string) => {
    setSelectedSystemId(systemId);
  };

  const handleSelectFleet = (fleetId: string) => {
    const fleet = gameState.fleets.find((item) => item.id === fleetId);
    setSelectedFleetId(fleetId);
    setSelectedSystemId(fleet?.systemId ?? null);
  };

  return (
    <div className="app-shell">
      <section className="map-panel">
        <StarMap systems={gameState.starSystems} hyperlanes={gameState.hyperlanes} fleets={gameState.fleets} factions={gameState.factions} selectedSystemId={selectedSystemId} selectedFleetId={selectedFleetId} reachableSystemIds={reachableSystemIds} labelsVisible={labelsVisible} onSelectSystem={handleSelectSystem} onSelectFleet={handleSelectFleet} />
      </section>
      <UI state={gameState} selectedSystemId={selectedSystemId} selectedFleetId={selectedFleetId} reachableSystemIds={reachableSystemIds} labelsVisible={labelsVisible} backendStatus={backendStatus} aiAdvice={aiAdvice} aiLoading={aiLoading} turnBusy={turnLoading} diplomacyLoading={diplomacyLoading} diplomaticMessage={diplomaticMessage} worldData={worldData} worldLoading={worldLoading} onRequestAiAdvice={requestAiAdvice} onRequestWorldQuery={() => requestWorldQuery(selectedSystemId)} onRequestDiplomaticMessage={requestDiplomaticMessage} onProposeTreaty={handleTreaty} onSelectFleet={handleSelectFleet} onSelectSystem={handleSelectSystem} onResearch={(techId) => isPlaying && setGameState((state) => startResearch(state, techId))} onCancelResearch={() => isPlaying && setGameState((state) => cancelResearch(state))} onNextTurn={handleNextTurn} onExplore={(systemId) => isPlaying && selectedFleetId && setGameState((state) => exploreSystem(state, selectedFleetId, systemId))} onColonize={(systemId) => isPlaying && selectedFleetId && setGameState((state) => colonizeSystem(state, selectedFleetId, systemId))} onMoveFleet={handleMoveFleet} onBuild={handleQueueBuild} onConstructShip={handleQueueShip} onRepairFleet={(fleetId) => isPlaying && setGameState((state) => repairFleet(state, fleetId))} onTrade={(factionId) => isPlaying && setGameState((state) => tradeWithFaction(state, factionId))} onThreaten={(factionId) => isPlaying && setGameState((state) => threatenFaction(state, factionId))} onReset={resetGame} onToggleLabels={() => setLabelsVisible((visible) => !visible)} onClearContextSelection={clearContextSelection} />
    </div>
  );
}
