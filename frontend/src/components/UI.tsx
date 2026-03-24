import { useMemo, useState } from 'react';
import { availableBuildings, availableShipTypes } from '../game/logic';
import type {
  BackendDiplomaticMessage,
  BackendWorldQueryResponse,
  BuildingBlueprint,
  BuildingType,
  Faction,
  Fleet,
  GameState,
  ResourceBundle,
  ShipType,
  StarSystem,
  Technology,
  TreatyType
} from '../game/types';

type DrawerTab = 'OBJECTIVES' | 'TECH' | 'DIPLOMACY' | 'ADVISOR';

const eraName = {
  PIONEER: '先驱时代',
  EXPANSION: '扩张时代',
  CONFLICT: '纷争时代',
  UNIFICATION: '统一时代',
  ASCENSION: '飞升时代'
} as const;
const statusName = { PLAYING: '进行中', VICTORY: '胜利', DEFEAT: '失败' } as const;
const eventName = { ANCIENT_RUINS: '古代遗迹', RICH_ASTEROIDS: '富矿带', SOLAR_STORM: '恒星风暴' } as const;
const shipName = { CORVETTE: '护卫舰', DESTROYER: '驱逐舰', CRUISER: '巡洋舰', BATTLESHIP: '战列舰' } as const;
const treatyName: Record<TreatyType, string> = { TRADE_PACT: '贸易协定', NON_AGGRESSION: '互不侵犯', RESEARCH_ACCORD: '科研协定', ALLIANCE: '共同同盟' };
const tabIcon: Record<DrawerTab, string> = { OBJECTIVES: '🎯', TECH: '🔬', DIPLOMACY: '🤝', ADVISOR: '🤖' };
const tabLabel: Record<DrawerTab, string> = { OBJECTIVES: '战局', TECH: '科技', DIPLOMACY: '外交', ADVISOR: '顾问' };
const buildingTurns: Record<BuildingType, number> = { HABITAT: 1, HYDROPONICS: 1, MINING_STATION: 1, INTEGRATED_FACTORY: 2, FUSION_REACTOR: 2, SHIPYARD: 2, RESEARCH_LAB: 2 };

const formatResourceLine = (bundle: ResourceBundle, positivePrefix = '') => {
  const items = [
    bundle.food ? `${positivePrefix}${bundle.food} 食物` : null,
    bundle.minerals ? `${positivePrefix}${bundle.minerals} 矿产` : null,
    bundle.industry ? `${positivePrefix}${bundle.industry} 工业` : null,
    bundle.energy ? `${positivePrefix}${bundle.energy} 能源` : null
  ].filter(Boolean);
  return items.length ? items.join(' / ') : '无';
};

function TopBar({ faction, turn, era, labelsVisible, onToggleLabels }: { faction: Faction; turn: number; era: GameState['era']; labelsVisible: boolean; onToggleLabels: () => void }) {
  return <header className="hud-topbar"><div className="hud-chip compact"><span>回合</span><strong>{turn}</strong></div><div className="hud-chip compact"><span>时代</span><strong>{eraName[era]}</strong></div><div className="hud-chip"><span>食物</span><strong>{faction.resources.food}</strong><em>{faction.resourceRates.food >= 0 ? '+' : ''}{faction.resourceRates.food}</em></div><div className="hud-chip"><span>矿产</span><strong>{faction.resources.minerals}</strong><em>{faction.resourceRates.minerals >= 0 ? '+' : ''}{faction.resourceRates.minerals}</em></div><div className="hud-chip"><span>工业</span><strong>{faction.resources.industry}</strong><em>{faction.resourceRates.industry >= 0 ? '+' : ''}{faction.resourceRates.industry}</em></div><div className="hud-chip"><span>能源</span><strong>{faction.resources.energy}</strong><em>{faction.resourceRates.energy >= 0 ? '+' : ''}{faction.resourceRates.energy}</em></div><button className="hud-chip hud-toggle-chip" onClick={onToggleLabels}><span>地图文字</span><strong>{labelsVisible ? '已显示' : '已隐藏'}</strong></button></header>;
}

function ContextBanner({ selectedSystem, selectedFleet, onClear }: { selectedSystem?: StarSystem; selectedFleet?: Fleet; onClear: () => void }) {
  if (!selectedSystem && !selectedFleet) return null;
  return <div className="context-banner"><div className="context-banner-copy"><span>{selectedFleet ? '舰队上下文' : '星系上下文'}</span><strong>{selectedFleet?.name ?? selectedSystem?.name}</strong></div><button className="ghost-button" onClick={onClear}>返回总览</button></div>;
}

function ObjectivesPanel({ state, onReset }: { state: GameState; onReset: () => void }) {
  return <div className="drawer-section"><div className="section-title">战局目标</div><h2>{statusName[state.status]}</h2><p>{state.objective}</p><p className="status-tip">当前胜利路径：{state.victoryPath ?? '进行中'} · 飞升进度 {state.ascensionProgress}/100</p><button className="secondary-button" onClick={onReset}>重新开局</button></div>;
}

function AdvisorPanel({ backendStatus, aiAdvice, aiLoading, worldLoading, worldData, onRequestAiAdvice, onRequestWorldQuery }: { backendStatus: 'checking' | 'online' | 'offline'; aiAdvice: string; aiLoading: boolean; worldLoading: boolean; worldData: BackendWorldQueryResponse | null; onRequestAiAdvice: () => void; onRequestWorldQuery: () => void }) {
  const statusLabel = backendStatus === 'online' ? '在线' : backendStatus === 'offline' ? '离线' : '检查中';
  return <><div className="drawer-section"><div className="section-title">AI 顾问</div><div className="status-row"><strong>后端状态</strong><span className="relation-badge">{statusLabel}</span></div><p className="ai-structured-text">{aiAdvice || '可请求 AI 建议或世界情报摘要。'}</p><div className="inline-actions"><button className="secondary-button" onClick={onRequestAiAdvice} disabled={aiLoading}>{aiLoading ? '请求中...' : '请求 AI 建议'}</button><button className="secondary-button" onClick={onRequestWorldQuery} disabled={worldLoading}>{worldLoading ? '同步中...' : '世界查询'}</button></div></div><div className="drawer-section"><div className="section-title">世界查询</div>{worldData ? <><p>{worldData.summary}</p><div className="subsection"><h3>条约</h3>{worldData.treaties.length === 0 ? <p>暂无条约</p> : <ul>{worldData.treaties.map((item) => <li key={item.id}>{item.type} · {item.status} · {item.counterpart}</li>)}</ul>}</div><div className="subsection"><h3>建造队列</h3>{worldData.queue.length === 0 ? <p>暂无排队项目</p> : <ul>{worldData.queue.map((item) => <li key={item.id}>{item.displayName} · {item.turnsRemaining} 回合</li>)}</ul>}</div></> : <p>点击“世界查询”同步当前星域、条约和建造队列摘要。</p>}</div></>;
}

function TechPanel({ technologies, currentResearchId, onResearch, onCancelResearch }: { technologies: Technology[]; currentResearchId: string | null; onResearch: (techId: string) => void; onCancelResearch: () => void; }) {
  const techNameMap = useMemo(() => Object.fromEntries(technologies.map((tech) => [tech.id, tech.name])), [technologies]);
  const currentResearch = technologies.find((tech) => tech.id === currentResearchId) ?? null;
  const researchableTechs = technologies.filter((tech) => tech.status === 'AVAILABLE');

  return <div className="drawer-section"><div className="section-title">科技研究</div><p className="status-tip">仅显示当前可研究科技。研究会消耗工业，取消研究返还 50% 工业。</p>{currentResearch && <article className="tech-current"><div className="build-option-head"><div><strong>{currentResearch.name}</strong><p>{currentResearch.description}</p></div><span className="relation-badge">进行中</span></div><div className="tech-meta"><span>T{currentResearch.tier} · {currentResearch.category}</span><span>研究时间 {currentResearch.researchTime} 回合</span><span>进度 {Math.round(currentResearch.progress)}%</span><span>花费 {currentResearch.cost} 工业</span></div><div className="subsection"><h3>科技加成</h3><div className="info-chip-group">{currentResearch.effects.map((effect) => <span key={effect} className="info-chip">{effect}</span>)}</div></div><div className="subsection"><h3>解锁内容</h3><div className="info-chip-group">{currentResearch.unlocks.map((unlock) => <span key={unlock} className="info-chip">{unlock}</span>)}</div></div><button className="secondary-button danger" onClick={onCancelResearch}>取消当前研究</button></article>}{researchableTechs.length === 0 ? <p>当前没有新的可研究科技，请先完成正在进行的研究或推进前置科技链。</p> : <div className="tech-list">{researchableTechs.map((tech) => <article key={tech.id} className={`tech-item tech-${tech.status.toLowerCase()}`}><div className="build-option-head"><div><strong>{tech.name}</strong><p>{tech.description}</p></div><span className="relation-badge">T{tech.tier}</span></div><div className="tech-meta"><span>{tech.category}</span><span>研究时间 {tech.researchTime} 回合</span><span>花费 {tech.cost} 工业</span><span>{tech.prerequisites?.length ? `前置：${tech.prerequisites.map((id) => techNameMap[id] ?? id).join(' / ')}` : '无前置要求'}</span></div><div className="subsection"><h3>科技加成</h3><div className="info-chip-group">{tech.effects.map((effect) => <span key={effect} className="info-chip">{effect}</span>)}</div></div><div className="subsection"><h3>解锁内容</h3><div className="info-chip-group">{tech.unlocks.map((unlock) => <span key={unlock} className="info-chip">{unlock}</span>)}</div></div><button className="secondary-button" onClick={() => onResearch(tech.id)} disabled={!!currentResearchId}>开始研究</button></article>)}</div>}</div>;
}

function DiplomacyPanel({ state, player, diplomacyLoading, diplomaticMessage, onTrade, onThreaten, onRequestDiplomaticMessage, onProposeTreaty }: { state: GameState; player: Faction; diplomacyLoading: boolean; diplomaticMessage: BackendDiplomaticMessage | null; onTrade: (factionId: string) => void; onThreaten: (factionId: string) => void; onRequestDiplomaticMessage: (factionId: string, tone: 'friendly' | 'firm') => void; onProposeTreaty: (factionId: string, treatyType: TreatyType) => void; }) {
  return <><div className="drawer-section"><div className="section-title">外交关系</div><div className="diplomacy-list">{state.factions.filter((faction) => !faction.isPlayer).map((faction) => { const relation = state.relationships.find((item) => (item.factionAId === player.id && item.factionBId === faction.id) || (item.factionAId === faction.id && item.factionBId === player.id)); const activeTreaties = state.treaties.filter((item) => item.status === 'ACTIVE' && ((item.sourceFactionId === player.id && item.targetFactionId === faction.id) || (item.sourceFactionId === faction.id && item.targetFactionId === player.id))); return <div key={faction.id} className="diplomacy-item card-stack"><div className="diplomacy-head"><strong>{faction.name}</strong><span>{faction.leaderName}</span></div><div className="relation-badge">{relation?.level ?? 'UNKNOWN'}</div><p className="status-tip">{activeTreaties.length === 0 ? '暂无正式条约' : activeTreaties.map((item) => treatyName[item.type]).join(' / ')}</p><div className="inline-actions wrap"><button className="secondary-button" onClick={() => onTrade(faction.id)}>贸易</button><button className="secondary-button" onClick={() => onProposeTreaty(faction.id, 'NON_AGGRESSION')}>互不侵犯</button><button className="secondary-button" onClick={() => onProposeTreaty(faction.id, 'RESEARCH_ACCORD')}>科研协定</button><button className="secondary-button" onClick={() => onProposeTreaty(faction.id, 'ALLIANCE')}>同盟</button><button className="secondary-button" onClick={() => onRequestDiplomaticMessage(faction.id, 'friendly')} disabled={diplomacyLoading}>致函</button><button className="secondary-button danger" onClick={() => { onThreaten(faction.id); onRequestDiplomaticMessage(faction.id, 'firm'); }} disabled={diplomacyLoading}>警告</button></div></div>; })}</div></div><div className="drawer-section"><div className="section-title">外交函</div>{diplomaticMessage ? <><h2>{diplomaticMessage.title}</h2><p>{diplomaticMessage.content}</p><p className="ai-structured-text">{diplomaticMessage.structured_text}</p></> : <p>执行外交动作后，这里会显示百炼生成的外交函。</p>}</div></>;
}

function BuildingOptionCards({ options, onBuild }: { options: BuildingBlueprint[]; onBuild: (type: BuildingBlueprint['type']) => void; }) {
  const [selectedType, setSelectedType] = useState<BuildingType | null>(options[0]?.type ?? null);
  const selected = options.find((option) => option.type === selectedType) ?? options[0];
  if (!selected) return <p>当前没有可建造的新建筑。</p>;
  return <div className="build-option-picker"><div className="build-option-tabs">{options.map((option) => <button key={option.type} className={`build-tab ${selected.type === option.type ? 'selected' : ''}`} onClick={() => setSelectedType(option.type)}><strong>{option.name}</strong><span>{buildingTurns[option.type]} 回合</span></button>)}</div><article className="build-option-card"><div className="build-option-head"><div><strong>{selected.name}</strong><p>{selected.description}</p></div><span className="relation-badge">{buildingTurns[selected.type]} 回合</span></div><div className="build-option-grid"><div><span>建造消耗</span><strong>{formatResourceLine(selected.cost)}</strong></div><div><span>建筑产出</span><strong>{formatResourceLine(selected.production, '+')}</strong></div><div><span>维护费用</span><strong>{formatResourceLine(selected.maintenance)}</strong></div><div><span>额外住房</span><strong>{selected.housing > 0 ? `+${selected.housing}` : '无'}</strong></div></div><button className="secondary-button" onClick={() => onBuild(selected.type)}>加入建造队列</button></article></div>;
}

function SystemPanel({ state, system, owner, selectedFleet, reachableSystemIds, onExplore, onColonize, onMoveFleet, onBuild, onConstructShip }: { state: GameState; system: StarSystem | undefined; owner: Faction | undefined; selectedFleet: Fleet | undefined; reachableSystemIds: string[]; onExplore: (systemId: string) => void; onColonize: (systemId: string) => void; onMoveFleet: (systemId: string) => void; onBuild: (type: BuildingBlueprint['type'], systemId: string) => void; onConstructShip: (systemId: string, type: ShipType) => void; }) {
  if (!system) return <div className="drawer-section"><div className="section-title">星系建设</div><p>在星图上选择一个星系查看建设信息。</p></div>;
  const player = state.factions.find((faction) => faction.isPlayer) ?? state.factions[0];
  const isOwned = system.ownerId === player.id;
  const hasShipyard = system.buildings.some((building) => building.type === 'SHIPYARD');
  const buildable = availableBuildings(state).filter((item) => !system.buildings.some((building) => building.type === item.type && item.type === 'SHIPYARD'));
  const canMoveHere = !!selectedFleet && reachableSystemIds.includes(system.id) && selectedFleet.systemId !== system.id;
  const shipTypes = availableShipTypes(state);
  const queueItems = state.constructionQueue.filter((item) => item.systemId === system.id);
  return <div className="drawer-section"><div className="section-title">星系建设</div><h2>{system.name}</h2><p>归属：{owner?.name ?? '无归属'} · 可见性：{system.visibilityLevel}</p>{system.note && <p className="system-note">{system.note}</p>}{system.eventType && !system.eventResolved && <p className="event-tag">异常信号：{eventName[system.eventType]}</p>}<div className="stat-grid"><div><span>食物</span><strong>{system.resources.food}</strong></div><div><span>矿产</span><strong>{system.resources.minerals}</strong></div><div><span>工业</span><strong>{system.resources.industry}</strong></div><div><span>能源</span><strong>{system.resources.energy}</strong></div></div><p className="status-tip">建筑格位：{system.buildings.length + queueItems.filter((item) => item.kind === 'BUILDING').length}/{system.buildingSlots}</p><div className="subsection"><h3>当前建筑</h3>{system.buildings.length === 0 ? <p>暂无建筑</p> : <ul>{system.buildings.map((building) => <li key={building.id}>{building.name}</li>)}</ul>}</div><div className="subsection"><h3>建造队列</h3>{queueItems.length === 0 ? <p>暂无排队</p> : <ul>{queueItems.map((item) => <li key={item.id}>{item.displayName} · 剩余 {item.turnsRemaining} 回合</li>)}</ul>}</div><div className="subsection"><h3>舰队行动</h3>{selectedFleet ? <><p className="status-tip">已选舰队：{selectedFleet.name} · 当前驻留 {state.starSystems.find((item) => item.id === selectedFleet.systemId)?.name ?? selectedFleet.systemId}</p><div className="inline-actions">{system.visibilityLevel !== 'FULL' && <button className="secondary-button" onClick={() => onExplore(system.id)}>探索星系</button>}{!system.ownerId && system.visibilityLevel === 'FULL' && selectedFleet.systemId === system.id && <button className="secondary-button" onClick={() => onColonize(system.id)}>建立殖民地</button>}{canMoveHere && <button className="secondary-button" onClick={() => onMoveFleet(system.id)}>舰队跃迁至此</button>}</div>{!canMoveHere && selectedFleet.systemId !== system.id && <p className="status-tip">该星系当前不在选中舰队的单跳跃迁范围内。</p>}</> : <p className="status-tip">先选择一支舰队，再对当前星系下达探索、殖民或跃迁指令。</p>}{isOwned && hasShipyard && <div className="inline-actions wrap">{shipTypes.map((type) => <button key={type} className="secondary-button" onClick={() => onConstructShip(system.id, type)}>排队{shipName[type]}</button>)}</div>}</div>{isOwned && system.buildings.length < system.buildingSlots && <div className="subsection"><h3>可建造建筑</h3><BuildingOptionCards options={buildable} onBuild={(type) => onBuild(type, system.id)} /></div>}</div>;
}

function FleetPanel({ fleet, state, reachableSystemIds, onRepair, onSelectFleet, onSelectSystem, onMoveFleet, onExplore, onColonize }: { fleet: Fleet | undefined; state: GameState; reachableSystemIds: string[]; onRepair: (fleetId: string) => void; onSelectFleet: (fleetId: string) => void; onSelectSystem: (systemId: string) => void; onMoveFleet: (systemId: string) => void; onExplore: (systemId: string) => void; onColonize: (systemId: string) => void; }) {
  const playerFleets = state.fleets.filter((item) => item.ownerId === 'f_player');
  if (!fleet) return <div className="drawer-section"><div className="section-title">舰队指挥</div><div className="fleet-list">{playerFleets.map((item) => <button key={item.id} className="list-item" onClick={() => onSelectFleet(item.id)}><strong>{item.name}</strong><span>{item.ships.length} 艘舰船</span></button>)}</div></div>;
  const totalHp = fleet.ships.reduce((sum, ship) => sum + ship.hp, 0);
  const totalMaxHp = fleet.ships.reduce((sum, ship) => sum + ship.maxHp, 0);
  const repairNeed = fleet.ships.reduce((sum, ship) => sum + (ship.maxHp - ship.hp), 0);
  const system = state.starSystems.find((item) => item.id === fleet.systemId);
  const canRepair = !!system && system.ownerId === 'f_player' && fleet.ships.some((ship) => ship.hp < ship.maxHp);
  const fleetPower = fleet.ships.reduce((sum, ship) => sum + ship.damage + ship.hp / 10, 0);
  const reachableSystems = reachableSystemIds.map((systemId) => {
    const target = state.starSystems.find((item) => item.id === systemId);
    const lane = state.hyperlanes.find((item) => (item.startSystemId === fleet.systemId && item.endSystemId === systemId) || (item.endSystemId === fleet.systemId && item.startSystemId === systemId));
    return target ? { target, energyCost: lane?.traversalCost ?? 1 } : null;
  }).filter(Boolean) as Array<{ target: StarSystem; energyCost: number }>;

  return <div className="drawer-section"><div className="section-title">舰队指挥</div><h2>{fleet.name}</h2><p>驻留星系：{system?.name ?? fleet.systemId}</p><div className="stat-grid"><div><span>舰船数</span><strong>{fleet.ships.length}</strong></div><div><span>完整度</span><strong>{totalHp}/{totalMaxHp}</strong></div><div><span>舰队战力</span><strong>{Math.round(fleetPower)}</strong></div><div><span>当前能源</span><strong>{state.factions.find((item) => item.isPlayer)?.resources.energy ?? 0}</strong></div></div><p className="status-tip">维修资源预估：约 {Math.ceil(repairNeed / 12)} 矿产 / {Math.ceil(repairNeed / 14)} 工业 / {Math.ceil(repairNeed / 18)} 能源</p><div className="subsection"><h3>舰船构成</h3><ul>{fleet.ships.map((ship) => <li key={ship.id}>{ship.name} · {shipName[ship.type]} · {ship.hp}/{ship.maxHp} 生命 · {ship.damage} 伤害</li>)}</ul></div><div className="subsection"><h3>可达星系</h3>{reachableSystems.length === 0 ? <p>当前没有可直接跃迁的相邻星系。</p> : <div className="fleet-list">{reachableSystems.map(({ target, energyCost }) => <div key={target.id} className="list-item"><strong>{target.name}</strong><span>跃迁消耗 {energyCost} 能源 · 可见性 {target.visibilityLevel}</span><div className="inline-actions"><button className="secondary-button" onClick={() => onSelectSystem(target.id)}>查看星系</button><button className="secondary-button" onClick={() => onMoveFleet(target.id)}>跃迁</button>{target.visibilityLevel !== 'FULL' && <button className="secondary-button" onClick={() => onExplore(target.id)}>探索</button>}</div></div>)}</div>}</div><div className="subsection"><h3>驻留指令</h3><div className="inline-actions">{system && !system.ownerId && system.visibilityLevel === 'FULL' && <button className="secondary-button" onClick={() => onColonize(system.id)}>在当前星系建立殖民地</button>}{canRepair && <button className="secondary-button" onClick={() => onRepair(fleet.id)}>整备舰队</button>}</div>{!canRepair && fleet.ships.some((ship) => ship.hp < ship.maxHp) && <p className="status-tip">舰队只能在己方控制星系内整备维修。</p>}</div><div className="subsection"><h3>编队</h3><div className="fleet-list">{playerFleets.map((item) => <button key={item.id} className={`list-item ${item.id === fleet.id ? 'selected' : ''}`} onClick={() => onSelectFleet(item.id)}><strong>{item.name}</strong><span>{item.ships.length} 艘舰船</span></button>)}</div></div></div>;
}

function BottomTabs({ activeTab, onSelect }: { activeTab: DrawerTab; onSelect: (tab: DrawerTab) => void }) {
  return <nav className="hud-bottom-tabs">{(Object.keys(tabLabel) as DrawerTab[]).map((tab) => <button key={tab} className={`hud-tab ${activeTab === tab ? 'active' : ''}`} onClick={() => onSelect(tab)}><span className="hud-tab-icon">{tabIcon[tab]}</span><span>{tabLabel[tab]}</span></button>)}</nav>;
}

export default function UI({ state, selectedSystemId, selectedFleetId, reachableSystemIds, labelsVisible, backendStatus, aiAdvice, aiLoading, turnBusy, diplomacyLoading, diplomaticMessage, worldData, worldLoading, onRequestAiAdvice, onRequestWorldQuery, onRequestDiplomaticMessage, onProposeTreaty, onSelectFleet, onSelectSystem, onResearch, onCancelResearch, onNextTurn, onExplore, onColonize, onMoveFleet, onBuild, onConstructShip, onRepairFleet, onTrade, onThreaten, onReset, onToggleLabels, onClearContextSelection }: { state: GameState; selectedSystemId: string | null; selectedFleetId: string | null; reachableSystemIds: string[]; labelsVisible: boolean; backendStatus: 'checking' | 'online' | 'offline'; aiAdvice: string; aiLoading: boolean; turnBusy: boolean; diplomacyLoading: boolean; diplomaticMessage: BackendDiplomaticMessage | null; worldData: BackendWorldQueryResponse | null; worldLoading: boolean; onRequestAiAdvice: () => void; onRequestWorldQuery: () => void; onRequestDiplomaticMessage: (factionId: string, tone: 'friendly' | 'firm') => void; onProposeTreaty: (factionId: string, treatyType: TreatyType) => void; onSelectFleet: (fleetId: string) => void; onSelectSystem: (systemId: string) => void; onResearch: (techId: string) => void; onCancelResearch: () => void; onNextTurn: () => void; onExplore: (systemId: string) => void; onColonize: (systemId: string) => void; onMoveFleet: (systemId: string) => void; onBuild: (type: BuildingBlueprint['type'], systemId: string) => void; onConstructShip: (systemId: string, type: ShipType) => void; onRepairFleet: (fleetId: string) => void; onTrade: (factionId: string) => void; onThreaten: (factionId: string) => void; onReset: () => void; onToggleLabels: () => void; onClearContextSelection: () => void; }) {
  const player = state.factions.find((faction) => faction.isPlayer) ?? state.factions[0];
  const [activeTab, setActiveTab] = useState<DrawerTab>('OBJECTIVES');
  const selectedSystem = state.starSystems.find((system) => system.id === selectedSystemId);
  const selectedOwner = state.factions.find((faction) => faction.id === selectedSystem?.ownerId);
  const selectedFleet = state.fleets.find((fleet) => fleet.id === selectedFleetId);
  const showSystemContext = !!selectedSystem && (!selectedFleet || selectedFleet.systemId !== selectedSystem.id);
  const drawerTitle = selectedFleet && !showSystemContext ? '舰队指挥' : selectedSystem ? '星系建设' : tabLabel[activeTab];

  let drawerContent = null;
  if (showSystemContext && selectedSystem) drawerContent = <SystemPanel state={state} system={selectedSystem} owner={selectedOwner} selectedFleet={selectedFleet} reachableSystemIds={reachableSystemIds} onExplore={onExplore} onColonize={onColonize} onMoveFleet={onMoveFleet} onBuild={onBuild} onConstructShip={onConstructShip} />;
  else if (selectedFleet) drawerContent = <FleetPanel fleet={selectedFleet} state={state} reachableSystemIds={reachableSystemIds} onRepair={onRepairFleet} onSelectFleet={onSelectFleet} onSelectSystem={onSelectSystem} onMoveFleet={onMoveFleet} onExplore={onExplore} onColonize={onColonize} />;
  else if (activeTab === 'TECH') drawerContent = <TechPanel technologies={state.technologies} currentResearchId={state.currentResearchId} onResearch={onResearch} onCancelResearch={onCancelResearch} />;
  else if (activeTab === 'DIPLOMACY') drawerContent = <DiplomacyPanel state={state} player={player} diplomacyLoading={diplomacyLoading} diplomaticMessage={diplomaticMessage} onTrade={onTrade} onThreaten={onThreaten} onRequestDiplomaticMessage={onRequestDiplomaticMessage} onProposeTreaty={onProposeTreaty} />;
  else if (activeTab === 'ADVISOR') drawerContent = <AdvisorPanel backendStatus={backendStatus} aiAdvice={aiAdvice} aiLoading={aiLoading} worldLoading={worldLoading} worldData={worldData} onRequestAiAdvice={onRequestAiAdvice} onRequestWorldQuery={onRequestWorldQuery} />;
  else drawerContent = <ObjectivesPanel state={state} onReset={onReset} />;

  return <div className="hud-layer"><TopBar faction={player} turn={state.turn} era={state.era} labelsVisible={labelsVisible} onToggleLabels={onToggleLabels} /><ContextBanner selectedSystem={showSystemContext ? selectedSystem : undefined} selectedFleet={!showSystemContext ? selectedFleet : undefined} onClear={onClearContextSelection} /><aside className="right-drawer"><div className="drawer-header"><div><div className="section-title">{drawerTitle}</div><p className="drawer-subtitle">{!showSystemContext && selectedFleet ? '当前为舰队指挥上下文' : selectedSystem ? '当前为星系建设上下文' : '可通过底部栏切换系统面板'}</p></div>{(selectedFleet || selectedSystem) && <button className="ghost-button" onClick={onClearContextSelection}>关闭</button>}</div><div className="drawer-body">{drawerContent}</div><button className="turn-button drawer-turn" onClick={onNextTurn} disabled={state.status !== 'PLAYING' || turnBusy}>{turnBusy ? '敌方决策中...' : '推进下一回合'}</button></aside><BottomTabs activeTab={activeTab} onSelect={(tab) => { onClearContextSelection(); setActiveTab(tab); }} /></div>;
}
