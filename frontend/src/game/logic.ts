
import { buildingCatalog } from './data';
import type {
  BackendAIDecision,
  Building,
  BuildingBlueprint,
  BuildingType,
  ConstructionQueueItem,
  Faction,
  Fleet,
  GameEra,
  GameState,
  Message,
  Relationship,
  RelationshipLevel,
  ResourceBundle,
  Ship,
  ShipType,
  SystemEventType,
  Technology,
  Treaty,
  TreatyType,
  VictoryPath
} from './types';

const COLONY_COST: ResourceBundle = { food: 60, minerals: 50, industry: 40, energy: 20 };
const emptyResources = (): ResourceBundle => ({ food: 0, minerals: 0, industry: 0, energy: 0 });
const shipTurns: Record<ShipType, number> = { CORVETTE: 1, DESTROYER: 2, CRUISER: 3, BATTLESHIP: 4 };
const buildingTurns: Record<BuildingType, number> = {
  HABITAT: 1,
  HYDROPONICS: 1,
  MINING_STATION: 1,
  INTEGRATED_FACTORY: 2,
  FUSION_REACTOR: 2,
  SHIPYARD: 2,
  RESEARCH_LAB: 2
};
const treatyLabels: Record<TreatyType, string> = {
  TRADE_PACT: '贸易协定',
  NON_AGGRESSION: '互不侵犯条约',
  RESEARCH_ACCORD: '科研合作协议',
  ALLIANCE: '共同防御同盟'
};
const shipLabels: Record<ShipType, string> = {
  CORVETTE: '护卫舰',
  DESTROYER: '驱逐舰',
  CRUISER: '巡洋舰',
  BATTLESHIP: '战列舰'
};

const nextEra = (turn: number): GameEra => {
  if (turn < 20) return 'PIONEER';
  if (turn < 50) return 'EXPANSION';
  if (turn < 100) return 'CONFLICT';
  if (turn < 150) return 'UNIFICATION';
  return 'ASCENSION';
};

const playerFaction = (state: GameState): Faction => state.factions.find((faction) => faction.isPlayer) ?? state.factions[0];
const addResources = (base: ResourceBundle, delta: ResourceBundle): ResourceBundle => ({ food: base.food + delta.food, minerals: base.minerals + delta.minerals, industry: base.industry + delta.industry, energy: base.energy + delta.energy });
const subtractResources = (base: ResourceBundle, delta: ResourceBundle): ResourceBundle => ({ food: base.food - delta.food, minerals: base.minerals - delta.minerals, industry: base.industry - delta.industry, energy: base.energy - delta.energy });
const canAfford = (stock: ResourceBundle, cost: ResourceBundle) => stock.food >= cost.food && stock.minerals >= cost.minerals && stock.industry >= cost.industry && stock.energy >= cost.energy;
const addMessage = (state: GameState, title: string, content: string, type: Message['type'] = 'EVENT'): GameState => ({ ...state, messages: [{ id: `msg_${state.turn}_${state.messages.length + 1}`, title, content, turn: state.turn, type }, ...state.messages] });
const hasResearch = (state: GameState, techId: string) => state.technologies.some((tech) => tech.id === techId && tech.status === 'RESEARCHED');
const connectedTo = (state: GameState, systemId: string): string[] => state.hyperlanes.flatMap((lane) => lane.startSystemId === systemId ? [lane.endSystemId] : lane.endSystemId === systemId ? [lane.startSystemId] : []);
const relationBetween = (state: GameState, factionAId: string, factionBId: string): Relationship | undefined => state.relationships.find((item) => (item.factionAId === factionAId && item.factionBId === factionBId) || (item.factionAId === factionBId && item.factionBId === factionAId));
const activeTreatiesBetween = (state: GameState, factionAId: string, factionBId: string): Treaty[] => state.treaties.filter((item) => item.status === 'ACTIVE' && ((item.sourceFactionId === factionAId && item.targetFactionId === factionBId) || (item.sourceFactionId === factionBId && item.targetFactionId === factionAId)));
const hasTreaty = (state: GameState, factionAId: string, factionBId: string, treatyType: TreatyType) => activeTreatiesBetween(state, factionAId, factionBId).some((item) => item.type === treatyType);
const ownedSystems = (state: GameState, factionId: string) => state.starSystems.filter((system) => system.ownerId === factionId);

const relationLevel = (trust: number): RelationshipLevel => {
  if (trust >= 80) return 'SUPREME_ALLIANCE';
  if (trust >= 60) return 'ALLIED';
  if (trust >= 20) return 'NEUTRAL';
  if (trust >= -19) return 'COLD';
  if (trust >= -59) return 'TENSE';
  if (trust >= -79) return 'HOSTILE';
  return 'BITTER_ENEMY';
};

const makeBuildingInstance = (blueprint: BuildingBlueprint): Building => ({ id: `${blueprint.type}_${Math.random().toString(36).slice(2, 8)}`, ...blueprint });
const shipStats = (type: ShipType, state: GameState, ownerId: string) => {
  const playerBonus = ownerId === 'f_player' && hasResearch(state, 'tech_shipyard');
  switch (type) {
    case 'DESTROYER': return { hp: 165, maxHp: 165, damage: 34, evasion: 20, tracking: 58, speed: 8 + (playerBonus ? 1 : 0) };
    case 'CRUISER': return { hp: 250, maxHp: 250, damage: 52, evasion: 14, tracking: 62, speed: 7 + (playerBonus ? 1 : 0) };
    case 'BATTLESHIP': return { hp: 360, maxHp: 360, damage: 74, evasion: 10, tracking: 70, speed: 6 + (playerBonus ? 1 : 0) };
    default: return { hp: playerBonus ? 115 : 100, maxHp: playerBonus ? 115 : 100, damage: playerBonus ? 24 : 20, evasion: 30, tracking: 50, speed: 10 };
  }
};
const createShip = (type: ShipType, name: string, state: GameState, ownerId: string): Ship => ({ id: `ship_${Math.random().toString(36).slice(2, 8)}`, type, name, ...shipStats(type, state, ownerId) });
const shipCost = (type: ShipType, state: GameState, ownerId: string): ResourceBundle => {
  const playerDiscount = ownerId === 'f_player' && hasResearch(state, 'tech_shipyard');
  if (type === 'BATTLESHIP') return { food: 45, minerals: playerDiscount ? 128 : 145, industry: playerDiscount ? 118 : 132, energy: 40 };
  if (type === 'CRUISER') return { food: 30, minerals: playerDiscount ? 88 : 100, industry: playerDiscount ? 80 : 90, energy: 28 };
  if (type === 'DESTROYER') return { food: 18, minerals: playerDiscount ? 44 : 50, industry: playerDiscount ? 36 : 40, energy: 16 };
  return { food: 10, minerals: playerDiscount ? 24 : 30, industry: playerDiscount ? 20 : 25, energy: 10 };
};
const fleetPower = (fleet: Fleet) => fleet.ships.reduce((sum, ship) => sum + ship.damage + ship.hp / 10, 0);
const fleetNeedsRepair = (fleet: Fleet) => fleet.ships.some((ship) => ship.hp < ship.maxHp);
const repairCostForFleet = (fleet: Fleet): ResourceBundle => {
  const missingHp = fleet.ships.reduce((sum, ship) => sum + (ship.maxHp - ship.hp), 0);
  return { food: 0, minerals: Math.ceil(missingHp / 12), industry: Math.ceil(missingHp / 14), energy: Math.ceil(missingHp / 18) };
};
const damageFleet = (fleet: Fleet, amount: number): Fleet => ({ ...fleet, ships: fleet.ships.map((ship) => ({ ...ship, hp: Math.max(20, ship.hp - amount) })) });
const factionYield = (state: GameState, factionId: string): ResourceBundle => {
  const systems = ownedSystems(state, factionId);
  const bundle = systems.reduce((acc, system) => {
    acc.food += system.resources.food;
    acc.minerals += system.resources.minerals;
    acc.industry += system.resources.industry;
    acc.energy += system.resources.energy;
    system.buildings.forEach((building) => {
      acc.food += building.production.food + building.maintenance.food;
      acc.minerals += building.production.minerals + building.maintenance.minerals;
      acc.industry += building.production.industry + building.maintenance.industry;
      acc.energy += building.production.energy + building.maintenance.energy;
    });
    return acc;
  }, emptyResources());
  if (hasResearch(state, 'tech_trade_net')) {
    bundle.energy += systems.length * 2;
    bundle.minerals += systems.length;
  }
  if (factionId === 'f_player' && hasTreaty(state, 'f_player', 'f_merchant', 'TRADE_PACT')) {
    bundle.energy += 3;
    bundle.minerals += 2;
  }
  if (factionId === 'f_player' && hasTreaty(state, 'f_player', 'f_merchant', 'RESEARCH_ACCORD')) bundle.industry += 2;
  return bundle;
};

const playerResearchSpeed = (state: GameState) => {
  const labs = ownedSystems(state, 'f_player').reduce((sum, system) => sum + system.buildings.filter((building) => building.type === 'RESEARCH_LAB').length, 0);
  let speed = 1 + labs * 0.4 + (hasResearch(state, 'tech_research_lab') ? 0.35 : 0);
  if (hasTreaty(state, 'f_player', 'f_merchant', 'RESEARCH_ACCORD')) speed += 0.4;
  return speed;
};

const unlockTechnologies = (technologies: Technology[]) => technologies.map((technology) => {
  if (technology.status !== 'LOCKED' || !technology.prerequisites?.length) return technology;
  const unlocked = technology.prerequisites.every((id) => technologies.some((item) => item.id === id && item.status === 'RESEARCHED'));
  return unlocked ? { ...technology, status: 'AVAILABLE' as const } : technology;
});

const progressResearch = (state: GameState): { technologies: Technology[]; currentResearchId: string | null; researchProgress: number; completedName: string | null } => {
  if (!state.currentResearchId) return { technologies: unlockTechnologies(state.technologies), currentResearchId: null, researchProgress: 0, completedName: null };
  const target = state.technologies.find((technology) => technology.id === state.currentResearchId);
  if (!target) return { technologies: unlockTechnologies(state.technologies), currentResearchId: null, researchProgress: 0, completedName: null };
  const progressGain = (100 / target.researchTime) * playerResearchSpeed(state);
  const progress = Math.min(100, target.progress + progressGain);
  const completed = progress >= 100;
  const updated: Technology[] = state.technologies.map((technology): Technology => technology.id === target.id ? { ...technology, progress, status: completed ? 'RESEARCHED' : 'RESEARCHING' } : technology);
  return { technologies: unlockTechnologies(updated), currentResearchId: completed ? null : target.id, researchProgress: completed ? 0 : progress, completedName: completed ? target.name : null };
};

const eventReward = (eventType?: SystemEventType): { title: string; content: string; reward: ResourceBundle } | null => {
  switch (eventType) {
    case 'ANCIENT_RUINS': return { title: '古代遗迹', content: '你的勘探队解译了古代信标数据，获得工业与科研物资。', reward: { food: 0, minerals: 25, industry: 40, energy: 10 } };
    case 'RICH_ASTEROIDS': return { title: '富矿小行星群', content: '舰队标记了高价值矿脉，后勤部门回收了大量矿产与能源。', reward: { food: 0, minerals: 50, industry: 0, energy: 20 } };
    case 'SOLAR_STORM': return { title: '恒星风暴', content: '你在风暴边缘建立了临时采能阵列，获得额外能源储备。', reward: { food: 0, minerals: 0, industry: 10, energy: 45 } };
    default: return null;
  }
};

const revealSystem = (state: GameState, systemId: string) => ({ ...state, starSystems: state.starSystems.map((item) => item.id === systemId ? { ...item, visibilityLevel: 'FULL' as const } : item) });
const resolvePlayerSystemEvent = (state: GameState, systemId: string): GameState => {
  const system = state.starSystems.find((item) => item.id === systemId);
  const player = playerFaction(state);
  const rewardData = eventReward(system?.eventType);
  if (!system || system.eventResolved || !rewardData) return state;
  const nextState: GameState = {
    ...state,
    starSystems: state.starSystems.map((item) => item.id === systemId ? { ...item, eventResolved: true, note: `${item.note ?? ''} 勘探完成。` } : item),
    factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: addResources(faction.resources, rewardData.reward) } : faction)
  };
  return addMessage(nextState, rewardData.title, `${system.name}：${rewardData.content}`, 'EVENT');
};

const applyFactionEconomy = (state: GameState): GameState => ({ ...state, factions: state.factions.map((faction) => {
  const yieldBundle = factionYield(state, faction.id);
  return { ...faction, resources: addResources(faction.resources, yieldBundle), resourceRates: yieldBundle, militaryPower: 0 };
}) });

const applyPassiveRepairs = (state: GameState): GameState => ({ ...state, fleets: state.fleets.map((fleet) => {
  const system = state.starSystems.find((item) => item.id === fleet.systemId);
  if (!system || system.ownerId !== fleet.ownerId) return fleet;
  const repairAmount = system.buildings.some((building) => building.type === 'SHIPYARD') ? 12 : 5;
  return { ...fleet, ships: fleet.ships.map((ship) => ({ ...ship, hp: Math.min(ship.maxHp, ship.hp + repairAmount) })) };
}) });

const ensureFactionControls = (state: GameState): GameState => ({ ...state, factions: state.factions.map((faction) => ({
  ...faction,
  controlledSystems: state.starSystems.filter((system) => system.ownerId === faction.id).map((system) => system.id),
  population: state.starSystems.filter((system) => system.ownerId === faction.id).reduce((sum, system) => sum + system.population, 0),
  militaryPower: state.fleets.filter((fleet) => fleet.ownerId === faction.id).reduce((sum, fleet) => sum + fleetPower(fleet), 0),
  technologyLevel: state.technologies.filter((tech) => tech.status === 'RESEARCHED').length
})) });

const treatyAcceptance = (state: GameState, treatyType: TreatyType, targetFactionId: string) => {
  const player = playerFaction(state);
  const relation = relationBetween(state, player.id, targetFactionId);
  const trust = relation?.trust ?? 0;
  const requiresTech = treatyType === 'TRADE_PACT' ? true : hasResearch(state, 'tech_diplomatic_protocols');
  if (!requiresTech) return { accepted: false, reason: '尚未掌握星际礼制协议，无法缔结更高级条约。' };
  if (treatyType === 'TRADE_PACT' && trust >= -10) return { accepted: true, reason: '对方认为继续贸易仍有利可图。' };
  if (treatyType === 'NON_AGGRESSION' && trust >= 10) return { accepted: true, reason: '边境互信尚可，双方愿意冻结武装摩擦。' };
  if (treatyType === 'RESEARCH_ACCORD' && trust >= 30) return { accepted: true, reason: '对方接受共享研究成果与实验数据。' };
  if (treatyType === 'ALLIANCE' && trust >= 65) return { accepted: true, reason: '双方互信已足够支撑正式同盟。' };
  return { accepted: false, reason: '当前互信不足，对方拒绝签署该条约。' };
};

const queueTurnBonus = (state: GameState, systemId: string) => {
  const system = state.starSystems.find((item) => item.id === systemId);
  if (!system) return 0;
  let bonus = system.buildings.some((building) => building.type === 'SHIPYARD') ? 1 : 0;
  if (system.buildings.some((building) => building.type === 'INTEGRATED_FACTORY')) bonus += 1;
  return bonus;
};
const completeQueueItem = (state: GameState, item: ConstructionQueueItem): GameState => {
  if (item.kind === 'BUILDING') {
    const blueprint = buildingCatalog.find((entry) => entry.type === item.targetId);
    if (!blueprint) return state;
    return addMessage({ ...state, starSystems: state.starSystems.map((system) => system.id === item.systemId ? { ...system, buildings: [...system.buildings, makeBuildingInstance(blueprint)] } : system) }, '建造完成', `${item.displayName} 已在 ${state.starSystems.find((system) => system.id === item.systemId)?.name ?? item.systemId} 完工。`);
  }
  const shipType = item.targetId as ShipType;
  const ship = createShip(shipType, `新编${shipLabels[shipType]}`, state, item.ownerId);
  const existingFleet = state.fleets.find((fleet) => fleet.ownerId === item.ownerId && fleet.systemId === item.systemId);
  return addMessage({ ...state, fleets: existingFleet ? state.fleets.map((fleet) => fleet.id === existingFleet.id ? { ...fleet, ships: [...fleet.ships, ship] } : fleet) : [...state.fleets, { id: `fleet_${Math.random().toString(36).slice(2, 8)}`, ownerId: item.ownerId, systemId: item.systemId, name: `${item.systemId} 守备队`, ships: [ship] }] }, '舰船下水', `${item.displayName} 已在船坞完成下水。`);
};

const advanceConstructionQueue = (state: GameState): GameState => {
  let nextState = { ...state };
  const updatedQueue: ConstructionQueueItem[] = [];
  for (const item of state.constructionQueue) {
    const reduced = Math.max(0, item.turnsRemaining - 1 - queueTurnBonus(nextState, item.systemId));
    if (reduced <= 0) nextState = completeQueueItem(nextState, item);
    else updatedQueue.push({ ...item, turnsRemaining: reduced });
  }
  return { ...nextState, constructionQueue: updatedQueue };
};

const updateAscensionProgress = (state: GameState): GameState => {
  let delta = 0;
  if (hasResearch(state, 'tech_star_harmonics')) delta += 10;
  if (hasResearch(state, 'tech_singularity_lattice')) delta += 18;
  if (hasTreaty(state, 'f_player', 'f_merchant', 'RESEARCH_ACCORD')) delta += 6;
  delta += ownedSystems(state, 'f_player').reduce((sum, system) => sum + system.buildings.filter((building) => building.type === 'RESEARCH_LAB').length * 2, 0);
  return { ...state, ascensionProgress: Math.min(100, state.ascensionProgress + delta) };
};

const assessGameStatus = (state: GameState): GameState => {
  const player = playerFaction(state);
  const rivals = state.factions.filter((faction) => !faction.isPlayer);
  const playerSystems = state.starSystems.filter((system) => system.ownerId === player.id);
  const rivalSystems = state.starSystems.filter((system) => rivals.some((faction) => faction.id === system.ownerId));
  const allianceVictory = hasTreaty(state, 'f_player', 'f_merchant', 'ALLIANCE') && hasTreaty(state, 'f_player', 'f_merchant', 'RESEARCH_ACCORD');
  const objective = `军事 ${playerSystems.length}/3 星系 · 外交 ${allianceVictory ? '已达成联邦条约' : '需同盟+科研协定'} · 飞升 ${state.ascensionProgress}/100`;
  const conclude = (status: GameState['status'], victoryPath: VictoryPath, title: string, content: string) => addMessage({ ...state, status, victoryPath, objective }, title, content, 'SYSTEM');
  if (playerSystems.length === 0) return conclude('DEFEAT', null, '帝国崩溃', '你已失去全部控制星系，本局失败。');
  if (state.ascensionProgress >= 100 && hasResearch(state, 'tech_singularity_lattice')) return conclude('VICTORY', 'ASCENSION', '奇点飞升', '你已完成飞升矩阵，文明跃迁至更高维秩序。');
  if (allianceVictory) return conclude('VICTORY', 'DIPLOMATIC', '星际联邦', '你通过正式同盟与科研协定赢得了外交胜利。');
  if (playerSystems.length >= 3 || rivalSystems.length === 0) return conclude('VICTORY', 'MILITARY', '喵星崛起', '你已完成第一阶段扩张目标，取得军事胜利。');
  return { ...state, status: 'PLAYING', victoryPath: null, objective };
};

const colonizeForFaction = (state: GameState, factionId: string, systemId: string, population: number, title: string, content: string): GameState => {
  const habitat = buildingCatalog.find((item) => item.type === 'HABITAT');
  if (!habitat) return state;
  return addMessage({ ...state, factions: state.factions.map((item) => item.id === factionId ? { ...item, resources: subtractResources(item.resources, COLONY_COST) } : item), starSystems: state.starSystems.map((item) => item.id === systemId ? { ...item, ownerId: factionId, population, buildings: [makeBuildingInstance(habitat)], visibilityLevel: 'FULL' } : item) }, title, content);
};

const aiDiplomaticResponse = (state: GameState): GameState => {
  const player = playerFaction(state);
  const merchant = state.factions.find((item) => item.id === 'f_merchant');
  const relation = merchant ? relationBetween(state, player.id, merchant.id) : undefined;
  if (!merchant || !relation) return state;
  if (relation.trust >= 55 && state.turn % 3 === 0) return addMessage({ ...state, factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: addResources(faction.resources, { food: 0, minerals: 15, industry: 0, energy: 20 }) } : faction) }, '商路来讯', '商贾联盟因关系回暖，向你转交了一批补给与能源。', 'DIPLOMATIC');
  if (relation.trust <= -45 && state.turn % 2 === 0) return addMessage({ ...state, relationships: state.relationships.map((item) => {
    const touches = (item.factionAId === player.id && item.factionBId === merchant.id) || (item.factionAId === merchant.id && item.factionBId === player.id);
    if (!touches) return item;
    const trust = Math.max(-100, item.trust - 5);
    return { ...item, trust, fear: item.fear + 5, level: relationLevel(trust) };
  }) }, '外交回函', '商贾联盟公开谴责你的强硬姿态，边境局势持续恶化。', 'DIPLOMATIC');
  return state;
};

const bestNeutralTarget = (state: GameState, fleetSystemId: string) => state.starSystems.filter((system) => !system.ownerId && connectedTo(state, fleetSystemId).includes(system.id)).sort((a, b) => {
  const aValue = a.resources.energy * 3 + a.resources.minerals * 3 + a.resources.industry * 2 + a.resources.food;
  const bValue = b.resources.energy * 3 + b.resources.minerals * 3 + b.resources.industry * 2 + b.resources.food;
  return bValue - aValue;
})[0];

const merchantAiTurn = (state: GameState, decision?: BackendAIDecision): GameState => {
  const merchant = state.factions.find((faction) => faction.id === 'f_merchant');
  const player = playerFaction(state);
  if (!merchant) return state;
  const relation = relationBetween(state, player.id, merchant.id);
  const shipyardBlueprint = buildingCatalog.find((building) => building.type === 'SHIPYARD');
  let nextState = state;
  let merchantHome = nextState.starSystems.find((system) => system.ownerId === merchant.id);
  if (!merchantHome) return nextState;
  let merchantFaction = nextState.factions.find((faction) => faction.id === merchant.id) ?? merchant;
  let merchantFleet = nextState.fleets.find((fleet) => fleet.ownerId === merchant.id);
  let decisionApplied = false;
  const refreshMerchantState = () => {
    merchantHome = nextState.starSystems.find((system) => system.ownerId === merchant.id) ?? merchantHome;
    merchantFaction = nextState.factions.find((faction) => faction.id === merchant.id) ?? merchantFaction;
    merchantFleet = nextState.fleets.find((fleet) => fleet.ownerId === merchant.id) ?? merchantFleet;
  };
  const queueShipyard = () => {
    const homeSystem = merchantHome;
    if (!shipyardBlueprint || !homeSystem || homeSystem.buildings.some((building) => building.type === 'SHIPYARD')) return false;
    if (homeSystem.buildings.length >= homeSystem.buildingSlots || !canAfford(merchantFaction.resources, shipyardBlueprint.cost)) return false;
    nextState = { ...nextState, factions: nextState.factions.map((faction) => faction.id === merchant.id ? { ...faction, resources: subtractResources(faction.resources, shipyardBlueprint.cost) } : faction), constructionQueue: [...nextState.constructionQueue, { id: `queue_${Math.random().toString(36).slice(2, 8)}`, systemId: homeSystem.id, ownerId: merchant.id, kind: 'BUILDING', targetId: 'SHIPYARD', displayName: '太空船坞', turnsRemaining: 2, totalTurns: 2 }] };
    nextState = addMessage(nextState, '商贾联盟工程', '商贾联盟开始扩建本土船坞。', 'EVENT');
    refreshMerchantState();
    return true;
  };
  const queueShip = (type: ShipType) => {
    const homeSystem = merchantHome;
    if (!homeSystem || !homeSystem.buildings.some((building) => building.type === 'SHIPYARD')) return false;
    if (type === 'CRUISER' && nextState.turn < 14) return false;
    if (type === 'DESTROYER' && nextState.turn < 10) return false;
    const cost = shipCost(type, nextState, merchant.id);
    if (!canAfford(merchantFaction.resources, cost)) return false;
    nextState = { ...nextState, factions: nextState.factions.map((faction) => faction.id === merchant.id ? { ...faction, resources: subtractResources(faction.resources, cost) } : faction), constructionQueue: [...nextState.constructionQueue, { id: `queue_${Math.random().toString(36).slice(2, 8)}`, systemId: homeSystem.id, ownerId: merchant.id, kind: 'SHIP', targetId: type, displayName: shipLabels[type], turnsRemaining: shipTurns[type], totalTurns: shipTurns[type] }] };
    nextState = addMessage(nextState, '商贾联盟造舰', `商贾联盟已将一艘${shipLabels[type]}编入建造队列。`, 'EVENT');
    refreshMerchantState();
    return true;
  };
  const moveFleetTo = (targetSystemId: string) => {
    const activeFleet = merchantFleet;
    if (!activeFleet || !connectedTo(nextState, activeFleet.systemId).includes(targetSystemId)) return false;
    const targetSystem = nextState.starSystems.find((system) => system.id === targetSystemId);
    if (!targetSystem) return false;
    nextState = { ...nextState, fleets: nextState.fleets.map((fleet) => fleet.id === activeFleet.id ? { ...fleet, systemId: targetSystemId } : fleet), starSystems: nextState.starSystems.map((system) => system.id === targetSystemId ? { ...system, visibilityLevel: 'FULL' as const } : system) };
    nextState = addMessage(nextState, '商贾联盟调动', `边贸护航队向 ${targetSystem.name} 跃迁。`, 'EVENT');
    refreshMerchantState();
    return true;
  };
  const declareWarStrike = (targetSystemId: string) => {
    const activeFleet = merchantFleet;
    if (!activeFleet || !relation || !connectedTo(nextState, activeFleet.systemId).includes(targetSystemId)) return false;
    const targetSystem = nextState.starSystems.find((system) => system.id === targetSystemId);
    if (!targetSystem) return false;
    const playerFleet = nextState.fleets.find((fleet) => fleet.ownerId === player.id && fleet.systemId === targetSystemId);
    const merchantWins = playerFleet ? fleetPower(activeFleet) > fleetPower(playerFleet) : true;
    nextState = {
      ...nextState,
      fleets: nextState.fleets.map((fleet) => fleet.id === activeFleet.id ? merchantWins ? damageFleet({ ...fleet, systemId: targetSystemId }, 22) : { ...fleet, systemId: targetSystemId } : fleet).filter((fleet) => {
        if (merchantWins && playerFleet && fleet.id === playerFleet.id) return false;
        if (!merchantWins && fleet.id === activeFleet.id) return false;
        return true;
      }),
      starSystems: nextState.starSystems.map((system) => system.id === targetSystemId && merchantWins ? { ...system, ownerId: merchant.id, visibilityLevel: 'FULL' as const } : system),
      relationships: nextState.relationships.map((item) => {
        const touches = (item.factionAId === player.id && item.factionBId === merchant.id) || (item.factionAId === merchant.id && item.factionBId === player.id);
        if (!touches) return item;
        const trust = Math.max(-100, item.trust - 18);
        return { ...item, trust, fear: item.fear + 12, level: relationLevel(trust) };
      }),
      treaties: nextState.treaties.map((item) => {
        const touches = (item.sourceFactionId === player.id && item.targetFactionId === merchant.id) || (item.sourceFactionId === merchant.id && item.targetFactionId === player.id);
        if (!touches || item.status !== 'ACTIVE') return item;
        return { ...item, status: 'BROKEN', summary: `${item.summary} 已因武装冲突终止。` };
      })
    };
    nextState = addMessage(nextState, '边境交火', merchantWins ? '商贾联盟突袭成功并夺取了边境控制权。' : '商贾联盟试图突袭，但攻势被成功击退。', 'COMBAT');
    refreshMerchantState();
    return true;
  };
  const improveTrade = () => {
    if (!relation) return false;
    nextState = { ...nextState, relationships: nextState.relationships.map((item) => {
      const touches = (item.factionAId === player.id && item.factionBId === merchant.id) || (item.factionAId === merchant.id && item.factionBId === player.id);
      if (!touches) return item;
      const trust = Math.min(100, item.trust + 10);
      return { ...item, trust, utility: item.utility + 8, level: relationLevel(trust) };
    }), factions: nextState.factions.map((faction) => faction.id === player.id ? { ...faction, resources: addResources(faction.resources, { food: 0, minerals: 10, industry: 0, energy: 12 }) } : faction) };
    nextState = addMessage(nextState, '商路修复', '商贾联盟主动提出恢复边境货运。', 'DIPLOMATIC');
    return true;
  };
  const colonizeIfPossible = () => {
    const activeFleet = merchantFleet;
    if (!activeFleet) return false;
    const fleetSystem = nextState.starSystems.find((system) => system.id === activeFleet.systemId);
    if (fleetSystem && !fleetSystem.ownerId && canAfford(merchantFaction.resources, COLONY_COST)) {
      nextState = colonizeForFaction(nextState, merchant.id, fleetSystem.id, 70, '商贾联盟殖民', `商贾联盟已在 ${fleetSystem.name} 建立贸易殖民地。`);
      refreshMerchantState();
      return true;
    }
    return false;
  };
  if (decision) {
    switch (decision.action) {
      case 'BUILD': { const target = decision.target ?? ''; if (target === 'SHIPYARD') decisionApplied = queueShipyard(); else if (target === 'DESTROYER' || target === 'CRUISER' || target === 'CORVETTE') decisionApplied = queueShip(target); break; }
      case 'EXPLORE': if (decision.target) { decisionApplied = moveFleetTo(decision.target); if (decisionApplied) colonizeIfPossible(); } break;
      case 'TRADE': decisionApplied = improveTrade(); break;
      case 'DECLARE_WAR': if (decision.target) decisionApplied = declareWarStrike(decision.target); break;
      case 'WAIT': decisionApplied = true; nextState = addMessage(nextState, '商贾联盟观望', `本回合敌方选择保守观望。${decision.reasoning}`, 'EVENT'); break;
    }
  }
  if (!decisionApplied) {
    if (shipyardBlueprint && nextState.turn >= 3) queueShipyard();
    const merchantType: ShipType = nextState.turn >= 14 ? 'CRUISER' : nextState.turn >= 10 ? 'DESTROYER' : 'CORVETTE';
    queueShip(merchantType);
    if (!colonizeIfPossible() && merchantFleet && nextState.turn >= 4) {
      const neutralTarget = bestNeutralTarget(nextState, merchantFleet.systemId);
      if (neutralTarget) moveFleetTo(neutralTarget.id);
    }
    const playerHomeId = player.controlledSystems[0] ?? 'sys_cat_home';
    const canAttackPlayer = !!merchantFleet && !!relation && relation.trust <= -20 && connectedTo(nextState, merchantFleet.systemId).includes(playerHomeId);
    if (canAttackPlayer) declareWarStrike(playerHomeId);
  }
  return ensureFactionControls(aiDiplomaticResponse(nextState));
};

export const reachableSystems = (state: GameState, fleetId: string | null): string[] => {
  if (!fleetId) return [];
  const fleet = state.fleets.find((item) => item.id === fleetId);
  return fleet ? connectedTo(state, fleet.systemId) : [];
};

export const availableBuildings = (state: GameState) => buildingCatalog.filter((building) => !building.unlockTechId || hasResearch(state, building.unlockTechId));
export const availableShipTypes = (state: GameState): ShipType[] => {
  const ships: ShipType[] = ['CORVETTE'];
  if (hasResearch(state, 'tech_destroyer_hulls')) ships.push('DESTROYER');
  if (hasResearch(state, 'tech_cruiser_doctrine')) ships.push('CRUISER');
  if (hasResearch(state, 'tech_flagship_systems')) ships.push('BATTLESHIP');
  return ships;
};
export const startResearch = (state: GameState, techId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const target = state.technologies.find((technology) => technology.id === techId);
  const player = playerFaction(state);
  if (!target || target.status !== 'AVAILABLE' || player.resources.industry < target.cost || state.currentResearchId) return state;
  return addMessage({ ...state, factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: { ...faction.resources, industry: faction.resources.industry - target.cost } } : faction), technologies: state.technologies.map((technology) => technology.id === techId ? { ...technology, status: 'RESEARCHING', progress: 0 } : technology), currentResearchId: techId, researchProgress: 0 }, '开始研究', `已开始研究 ${target.name}。`);
};
export const cancelResearch = (state: GameState): GameState => {
  if (state.status !== 'PLAYING' || !state.currentResearchId) return state;
  const player = playerFaction(state);
  const target = state.technologies.find((technology) => technology.id === state.currentResearchId);
  if (!target) return { ...state, currentResearchId: null, researchProgress: 0 };
  const refund = Math.ceil(target.cost * 0.5);
  return addMessage({
    ...state,
    factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: { ...faction.resources, industry: faction.resources.industry + refund } } : faction),
    technologies: unlockTechnologies(state.technologies.map((technology) => technology.id === target.id ? { ...technology, status: 'AVAILABLE', progress: 0 } : technology)),
    currentResearchId: null,
    researchProgress: 0
  }, '研究取消', `${target.name} 已取消，返还 ${refund} 工业。`);
};

export const processTurn = (state: GameState, merchantDecision?: BackendAIDecision): GameState => {
  if (state.status !== 'PLAYING') return state;
  const nextTurn = state.turn + 1;
  const research = progressResearch(state);
  let nextState: GameState = { ...state, turn: nextTurn, era: nextEra(nextTurn), technologies: research.technologies, currentResearchId: research.currentResearchId, researchProgress: research.researchProgress };
  nextState = applyFactionEconomy(nextState);
  nextState = applyPassiveRepairs(nextState);
  nextState = advanceConstructionQueue(nextState);
  nextState = updateAscensionProgress(nextState);
  if (research.completedName) nextState = addMessage(nextState, '科技完成', `${research.completedName} 研究完成。`);
  nextState = merchantAiTurn(nextState, merchantDecision);
  return assessGameStatus(ensureFactionControls(nextState));
};

export const moveFleet = (state: GameState, fleetId: string, targetSystemId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const fleet = state.fleets.find((item) => item.id === fleetId);
  const player = playerFaction(state);
  if (!fleet || fleet.ownerId !== player.id || !connectedTo(state, fleet.systemId).includes(targetSystemId)) return state;
  const lane = state.hyperlanes.find((item) => (item.startSystemId === fleet.systemId && item.endSystemId === targetSystemId) || (item.endSystemId === fleet.systemId && item.startSystemId === targetSystemId));
  const cost = lane?.traversalCost ?? 1;
  if (player.resources.energy < cost) return addMessage(state, '移动失败', '能源不足，舰队无法跃迁。');
  let nextState: GameState = { ...state, factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: { ...faction.resources, energy: faction.resources.energy - cost } } : faction), fleets: state.fleets.map((item) => item.id === fleetId ? { ...item, systemId: targetSystemId } : item), starSystems: state.starSystems.map((item) => item.id === targetSystemId ? { ...item, visibilityLevel: 'FULL' as const } : item) };
  nextState = addMessage(nextState, '舰队移动', `${fleet.name} 已跃迁至目标星系。`);
  nextState = resolvePlayerSystemEvent(nextState, targetSystemId);
  const enemyFleet = nextState.fleets.find((item) => item.systemId === targetSystemId && item.ownerId !== player.id);
  if (!enemyFleet) return assessGameStatus(ensureFactionControls(nextState));
  const movedFleet = nextState.fleets.find((item) => item.id === fleetId) ?? fleet;
  const playerWins = fleetPower(movedFleet) >= fleetPower(enemyFleet);
  const targetSystem = nextState.starSystems.find((system) => system.id === targetSystemId);
  const battleState: GameState = { ...nextState, fleets: nextState.fleets.map((item) => item.id === movedFleet.id && playerWins ? damageFleet(item, 24) : item).filter((item) => item.id !== (playerWins ? enemyFleet.id : movedFleet.id)), starSystems: nextState.starSystems.map((system) => system.id === targetSystemId && playerWins ? { ...system, ownerId: player.id, visibilityLevel: 'FULL' as const } : system), relationships: nextState.relationships.map((item) => {
    if (item.factionAId !== player.id && item.factionBId !== player.id) return item;
    const trust = Math.max(-100, item.trust - 10);
    return { ...item, trust, fear: item.fear + 10, level: relationLevel(trust) };
  }), treaties: nextState.treaties.map((item) => {
    const touches = (item.sourceFactionId === 'f_player' && item.targetFactionId !== 'f_player') || (item.targetFactionId === 'f_player' && item.sourceFactionId !== 'f_player');
    if (!touches || item.status !== 'ACTIVE' || item.type === 'TRADE_PACT') return item;
    return { ...item, status: 'BROKEN', summary: `${item.summary} 已因战斗接触破裂。` };
  }) };
  return assessGameStatus(ensureFactionControls(addMessage(battleState, '战斗报告', playerWins ? `${movedFleet.name} 在 ${targetSystem?.name ?? '目标星系'} 击败敌军并夺取控制权，舰队出现一定战损。` : `${movedFleet.name} 在 ${targetSystem?.name ?? '目标星系'} 作战失利。`, 'COMBAT')));
};

export const exploreSystem = (state: GameState, fleetId: string, systemId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const fleet = state.fleets.find((item) => item.id === fleetId);
  const player = playerFaction(state);
  if (!fleet || fleet.ownerId !== player.id || (fleet.systemId !== systemId && !connectedTo(state, fleet.systemId).includes(systemId))) return state;
  const system = state.starSystems.find((item) => item.id === systemId);
  if (!system || system.visibilityLevel === 'FULL') return state;
  let nextState: GameState = revealSystem(state, systemId);
  connectedTo(state, systemId).forEach((adjacentId) => { nextState = { ...nextState, starSystems: nextState.starSystems.map((item) => item.id === adjacentId && item.visibilityLevel === 'HIDDEN' ? { ...item, visibilityLevel: 'PARTIAL' as const } : item) }; });
  nextState = addMessage(nextState, '探索完成', `${fleet.name} 已完成对 ${system.name} 的勘测。`);
  return assessGameStatus(resolvePlayerSystemEvent(nextState, systemId));
};

export const colonizeSystem = (state: GameState, fleetId: string, systemId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const fleet = state.fleets.find((item) => item.id === fleetId);
  const player = playerFaction(state);
  const system = state.starSystems.find((item) => item.id === systemId);
  if (!fleet || fleet.ownerId !== player.id || !system || fleet.systemId !== systemId || system.ownerId || system.visibilityLevel !== 'FULL') return state;
  if (!canAfford(player.resources, COLONY_COST)) return addMessage(state, '殖民失败', '资源不足，无法建立殖民地。');
  const population = hasResearch(state, 'tech_expanded_housing') ? 120 : 80;
  return assessGameStatus(ensureFactionControls(colonizeForFaction(state, player.id, systemId, population, '殖民成功', `已在 ${system.name} 建立新的喵星殖民地。`)));
};

export const queueStructure = (state: GameState, systemId: string, buildingType: BuildingBlueprint['type']): GameState => {
  if (state.status !== 'PLAYING') return state;
  const player = playerFaction(state);
  const system = state.starSystems.find((item) => item.id === systemId);
  const blueprint = availableBuildings(state).find((item) => item.type === buildingType);
  if (!system || !blueprint || system.ownerId !== player.id || system.buildings.length >= system.buildingSlots) return state;
  if (system.buildings.some((item) => item.type === buildingType && buildingType === 'SHIPYARD')) return state;
  if (state.constructionQueue.some((item) => item.systemId === systemId && item.targetId === buildingType)) return state;
  if (!canAfford(player.resources, blueprint.cost)) return addMessage(state, '建造失败', '资源不足，无法建造该建筑。');
  return addMessage({ ...state, factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: subtractResources(faction.resources, blueprint.cost) } : faction), constructionQueue: [...state.constructionQueue, { id: `queue_${Math.random().toString(36).slice(2, 8)}`, systemId, ownerId: player.id, kind: 'BUILDING', targetId: buildingType, displayName: blueprint.name, turnsRemaining: buildingTurns[buildingType], totalTurns: buildingTurns[buildingType] }] }, '加入建造队列', `${system.name} 已开始建设 ${blueprint.name}。`);
};

export const queueShipConstruction = (state: GameState, systemId: string, shipType: ShipType): GameState => {
  if (state.status !== 'PLAYING') return state;
  const player = playerFaction(state);
  const system = state.starSystems.find((item) => item.id === systemId);
  if (!system || system.ownerId !== player.id || !system.buildings.some((building) => building.type === 'SHIPYARD')) return state;
  if (!availableShipTypes(state).includes(shipType)) return state;
  const cost = shipCost(shipType, state, player.id);
  if (!canAfford(player.resources, cost)) return addMessage(state, '造舰失败', '资源不足，无法建造该舰船。');
  return addMessage({ ...state, factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: subtractResources(faction.resources, cost) } : faction), constructionQueue: [...state.constructionQueue, { id: `queue_${Math.random().toString(36).slice(2, 8)}`, systemId, ownerId: player.id, kind: 'SHIP', targetId: shipType, displayName: shipLabels[shipType], turnsRemaining: shipTurns[shipType], totalTurns: shipTurns[shipType] }] }, '加入造舰队列', `${system.name} 已开始建造一艘${shipLabels[shipType]}。`);
};
export const repairFleet = (state: GameState, fleetId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const player = playerFaction(state);
  const fleet = state.fleets.find((item) => item.id === fleetId && item.ownerId === player.id);
  if (!fleet || !fleetNeedsRepair(fleet)) return state;
  const system = state.starSystems.find((item) => item.id === fleet.systemId);
  if (!system || system.ownerId !== player.id) return state;
  const cost = repairCostForFleet(fleet);
  if (!canAfford(player.resources, cost)) return addMessage(state, '维修失败', '资源不足，无法完成舰队维修。');
  return addMessage({ ...state, factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: subtractResources(faction.resources, cost) } : faction), fleets: state.fleets.map((item) => item.id === fleet.id ? { ...item, ships: item.ships.map((ship) => ({ ...ship, hp: ship.maxHp })) } : item) }, '舰队维修', `${fleet.name} 已在 ${system.name} 完成整备，战斗力恢复。`);
};

export const tradeWithFaction = (state: GameState, targetFactionId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const player = playerFaction(state);
  const relation = relationBetween(state, player.id, targetFactionId);
  const target = state.factions.find((item) => item.id === targetFactionId);
  if (!relation || !target) return state;
  const trust = Math.min(100, relation.trust + 15);
  let nextState = { ...state, relationships: state.relationships.map((item) => item === relation ? { ...item, trust, utility: item.utility + 10, level: relationLevel(trust) } : item), factions: state.factions.map((faction) => faction.id === player.id ? { ...faction, resources: { ...faction.resources, minerals: faction.resources.minerals + 20, energy: faction.resources.energy + 10 } } : faction) };
  if (!hasTreaty(nextState, player.id, targetFactionId, 'TRADE_PACT')) nextState = { ...nextState, treaties: [...nextState.treaties, { id: `treaty_${Math.random().toString(36).slice(2, 8)}`, sourceFactionId: player.id, targetFactionId, type: 'TRADE_PACT', status: 'ACTIVE', proposedOnTurn: state.turn, expiresOnTurn: null, summary: '双方开放稳定的边贸航道。' }] };
  return addMessage(nextState, '贸易协定', `你与 ${target.name} 完成了一次互利贸易，关系提升。`, 'DIPLOMATIC');
};

export const threatenFaction = (state: GameState, targetFactionId: string): GameState => {
  if (state.status !== 'PLAYING') return state;
  const player = playerFaction(state);
  const target = state.factions.find((item) => item.id === targetFactionId);
  if (!target) return state;
  return addMessage({ ...state, relationships: state.relationships.map((item) => {
    const touches = (item.factionAId === player.id && item.factionBId === targetFactionId) || (item.factionBId === player.id && item.factionAId === targetFactionId);
    if (!touches) return item;
    const trust = Math.max(-100, item.trust - 20);
    return { ...item, trust, fear: item.fear + 15, level: relationLevel(trust) };
  }), treaties: state.treaties.map((item) => {
    const touches = (item.sourceFactionId === player.id && item.targetFactionId === targetFactionId) || (item.sourceFactionId === targetFactionId && item.targetFactionId === player.id);
    if (!touches || item.status !== 'ACTIVE' || item.type === 'TRADE_PACT') return item;
    return { ...item, status: 'BROKEN', summary: `${item.summary} 已被单方面警告破坏。` };
  }) }, '外交警告', `你已向 ${target.name} 发出警告，对方关系恶化。`, 'DIPLOMATIC');
};

export const proposeTreaty = (state: GameState, targetFactionId: string, treatyType: TreatyType): GameState => {
  if (state.status !== 'PLAYING') return state;
  const player = playerFaction(state);
  const target = state.factions.find((item) => item.id === targetFactionId);
  if (!target || hasTreaty(state, player.id, targetFactionId, treatyType)) return state;
  const verdict = treatyAcceptance(state, treatyType, targetFactionId);
  const treatyRecord: Treaty = { id: `treaty_${Math.random().toString(36).slice(2, 8)}`, sourceFactionId: player.id, targetFactionId, type: treatyType, status: verdict.accepted ? 'ACTIVE' : 'REJECTED', proposedOnTurn: state.turn, expiresOnTurn: treatyType === 'ALLIANCE' ? null : state.turn + 12, summary: verdict.reason };
  const trustDelta = verdict.accepted ? (treatyType === 'ALLIANCE' ? 18 : 10) : -6;
  const nextState = { ...state, treaties: [...state.treaties, treatyRecord], relationships: state.relationships.map((item) => {
    const touches = (item.factionAId === player.id && item.factionBId === targetFactionId) || (item.factionAId === targetFactionId && item.factionBId === player.id);
    if (!touches) return item;
    const trust = Math.max(-100, Math.min(100, item.trust + trustDelta));
    return { ...item, trust, utility: item.utility + (verdict.accepted ? 8 : -2), level: relationLevel(trust) };
  }) };
  return addMessage(nextState, verdict.accepted ? treatyLabels[treatyType] : '条约遭拒', verdict.accepted ? `${target.name} 已接受${treatyLabels[treatyType]}。${verdict.reason}` : `${target.name} 拒绝了你的${treatyLabels[treatyType]}提议。${verdict.reason}`, 'DIPLOMATIC');
};
