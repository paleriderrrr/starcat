export type GameEra =
  | 'PIONEER'
  | 'EXPANSION'
  | 'CONFLICT'
  | 'UNIFICATION'
  | 'ASCENSION';

export type FactionType =
  | 'MILITARY_EMPIRE'
  | 'COMMERCIAL_FEDERATION'
  | 'TECHNOLOGY_ALLIANCE'
  | 'PACIFIST_CONFEDERACY'
  | 'NOMAD_ALLIANCE'
  | 'FEUDAL_KINGDOM'
  | 'VOID_OBSERVERS';

export type StarSystemType = 'SOLAR' | 'BINARY' | 'NEBULA' | 'STORM';
export type HyperlaneType = 'LANE' | 'WORMHOLE';
export type SystemEventType = 'ANCIENT_RUINS' | 'RICH_ASTEROIDS' | 'SOLAR_STORM';
export type RelationshipLevel =
  | 'SUPREME_ALLIANCE'
  | 'ALLIED'
  | 'NEUTRAL'
  | 'COLD'
  | 'TENSE'
  | 'HOSTILE'
  | 'BITTER_ENEMY';

export type BuildingType =
  | 'HABITAT'
  | 'HYDROPONICS'
  | 'MINING_STATION'
  | 'INTEGRATED_FACTORY'
  | 'FUSION_REACTOR'
  | 'SHIPYARD'
  | 'RESEARCH_LAB';

export type ShipType = 'CORVETTE' | 'DESTROYER' | 'CRUISER' | 'BATTLESHIP';
export type GameStatus = 'PLAYING' | 'VICTORY' | 'DEFEAT';
export type VictoryPath = 'MILITARY' | 'DIPLOMATIC' | 'ASCENSION' | null;
export type TreatyType = 'TRADE_PACT' | 'NON_AGGRESSION' | 'RESEARCH_ACCORD' | 'ALLIANCE';
export type TreatyStatus = 'PROPOSED' | 'ACTIVE' | 'REJECTED' | 'BROKEN' | 'EXPIRED';
export type ConstructionKind = 'BUILDING' | 'SHIP';

export interface ResourceBundle {
  food: number;
  minerals: number;
  industry: number;
  energy: number;
}

export interface Position {
  x: number;
  y: number;
  z: number;
}

export interface LeaderPersonality {
  aggression: number;
  paranoia: number;
  greed: number;
  loyalty: number;
  rationality: number;
}

export interface Faction {
  id: string;
  name: string;
  leaderName: string;
  type: FactionType;
  color: string;
  personality: LeaderPersonality;
  controlledSystems: string[];
  resources: ResourceBundle;
  resourceRates: ResourceBundle;
  population: number;
  militaryPower: number;
  technologyLevel: number;
  isPlayer: boolean;
}

export interface BuildingBlueprint {
  type: BuildingType;
  name: string;
  description: string;
  cost: ResourceBundle;
  maintenance: ResourceBundle;
  production: ResourceBundle;
  housing: number;
  unlockTechId?: string;
}

export interface Building extends BuildingBlueprint {
  id: string;
}

export interface Ship {
  id: string;
  type: ShipType;
  name: string;
  hp: number;
  maxHp: number;
  damage: number;
  evasion: number;
  tracking: number;
  speed: number;
}

export interface Fleet {
  id: string;
  ownerId: string;
  systemId: string;
  name: string;
  ships: Ship[];
}

export interface StarSystem {
  id: string;
  name: string;
  type: StarSystemType;
  position: Position;
  resources: ResourceBundle;
  buildingSlots: number;
  buildings: Building[];
  ownerId: string | null;
  population: number;
  visibilityLevel: 'FULL' | 'PARTIAL' | 'HIDDEN';
  eventType?: SystemEventType;
  eventResolved?: boolean;
  note?: string;
}

export interface Hyperlane {
  id: string;
  startSystemId: string;
  endSystemId: string;
  type: HyperlaneType;
  traversalCost: number;
  bandwidth: number;
}

export interface Relationship {
  factionAId: string;
  factionBId: string;
  trust: number;
  utility: number;
  fear: number;
  affinity: number;
  memoryImpact: number;
  level: RelationshipLevel;
}

export interface Treaty {
  id: string;
  sourceFactionId: string;
  targetFactionId: string;
  type: TreatyType;
  status: TreatyStatus;
  proposedOnTurn: number;
  expiresOnTurn: number | null;
  summary: string;
}

export interface Technology {
  id: string;
  name: string;
  tier: number;
  category: 'MILITARY' | 'ECONOMY' | 'SCIENCE' | 'EXPANSION';
  description: string;
  effects: string[];
  unlocks: string[];
  status: 'LOCKED' | 'AVAILABLE' | 'RESEARCHING' | 'RESEARCHED';
  cost: number;
  researchTime: number;
  progress: number;
  prerequisites?: string[];
}

export interface ConstructionQueueItem {
  id: string;
  systemId: string;
  ownerId: string;
  kind: ConstructionKind;
  targetId: BuildingType | ShipType;
  displayName: string;
  turnsRemaining: number;
  totalTurns: number;
}

export interface Message {
  id: string;
  title: string;
  content: string;
  turn: number;
  type: 'SYSTEM' | 'DIPLOMATIC' | 'EVENT' | 'COMBAT';
}

export interface BackendAIEnvelope {
  format_version: string;
  source: 'bailian' | 'fallback';
  is_fallback: boolean;
  structured_text: string;
}

export interface BackendAIDecision extends BackendAIEnvelope {
  action: 'BUILD' | 'EXPLORE' | 'TRADE' | 'DECLARE_WAR' | 'WAIT';
  target: string | null;
  reasoning: string;
}

export interface BackendDiplomaticMessage extends BackendAIEnvelope {
  title: string;
  content: string;
}

export interface BackendFleetMoveResponse {
  ok: boolean;
  reason: string;
  energy_cost: number;
  reachable_targets: string[];
}

export interface BackendConstructionResponse {
  ok: boolean;
  reason: string;
  projected_turns: number;
  queue_depth: number;
}

export interface BackendWorldQueryResponse {
  summary: string;
  visible_systems: Array<{ id: string; name: string; ownerId: string | null; value: number }>;
  treaties: Array<{ id: string; type: TreatyType; status: TreatyStatus; counterpart: string }>;
  queue: Array<{ id: string; systemId: string; displayName: string; turnsRemaining: number }>;
}

export interface GameState {
  turn: number;
  era: GameEra;
  status: GameStatus;
  objective: string;
  victoryPath: VictoryPath;
  ascensionProgress: number;
  factions: Faction[];
  starSystems: StarSystem[];
  hyperlanes: Hyperlane[];
  fleets: Fleet[];
  relationships: Relationship[];
  treaties: Treaty[];
  technologies: Technology[];
  currentResearchId: string | null;
  researchProgress: number;
  constructionQueue: ConstructionQueueItem[];
  messages: Message[];
}
