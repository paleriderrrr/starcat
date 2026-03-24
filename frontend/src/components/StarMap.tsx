import { Canvas } from '@react-three/fiber';
import { Html, Line, OrbitControls, Stars } from '@react-three/drei';
import type { Fleet, Faction, Hyperlane, StarSystem } from '../game/types';

function SystemNode({ system, owner, selected, reachable, labelsVisible, onSelect }: { system: StarSystem; owner?: Faction; selected: boolean; reachable: boolean; labelsVisible: boolean; onSelect: () => void; }) {
  const color = reachable ? '#bfa5ff' : owner?.color ?? (system.ownerId ? '#6B7280' : '#9CA3AF');
  const size = system.type === 'NEBULA' ? 0.9 : system.type === 'BINARY' ? 0.75 : 0.65;
  const opacity = system.visibilityLevel === 'FULL' ? 1 : system.visibilityLevel === 'PARTIAL' ? 0.65 : 0.18;

  return (
    <group position={[system.position.x / 80, 0, system.position.z / 80]}>
      <mesh onClick={onSelect}>
        <sphereGeometry args={[size, 32, 32]} />
        <meshStandardMaterial color={color} emissive={color} emissiveIntensity={selected ? 1.6 : reachable ? 1.15 : 0.8} transparent opacity={opacity} />
      </mesh>
      <mesh scale={selected ? 1.7 : reachable ? 1.55 : 1.35}>
        <sphereGeometry args={[size, 20, 20]} />
        <meshBasicMaterial color={color} transparent opacity={selected ? 0.2 : reachable ? 0.16 : 0.1} />
      </mesh>
      {labelsVisible && system.visibilityLevel !== 'HIDDEN' && (
        <Html center distanceFactor={18} position={[0, 1.6, 0]}>
          <div className={`star-label ${reachable ? 'reachable' : ''}`}>
            <strong>{system.name}</strong>
            <span>{owner?.name ?? '中立星系'}</span>
          </div>
        </Html>
      )}
    </group>
  );
}

function FleetMarker({ fleet, systems, factions, selected, labelsVisible, onSelect }: { fleet: Fleet; systems: StarSystem[]; factions: Faction[]; selected: boolean; labelsVisible: boolean; onSelect: () => void; }) {
  const system = systems.find((item) => item.id === fleet.systemId);
  const owner = factions.find((item) => item.id === fleet.ownerId);
  if (!system || system.visibilityLevel === 'HIDDEN') return null;

  return (
    <group position={[system.position.x / 80, selected ? 2.4 : 1.8, system.position.z / 80]}>
      <mesh onClick={onSelect}>
        <octahedronGeometry args={[selected ? 0.42 : 0.34, 0]} />
        <meshStandardMaterial color={owner?.color ?? '#ffffff'} emissive={owner?.color ?? '#ffffff'} emissiveIntensity={selected ? 1.4 : 1} />
      </mesh>
      <mesh rotation={[Math.PI / 2, 0, 0]} scale={selected ? 1.2 : 1}>
        <torusGeometry args={[0.58, 0.05, 12, 24]} />
        <meshBasicMaterial color={owner?.color ?? '#ffffff'} transparent opacity={selected ? 0.95 : 0.75} />
      </mesh>
      {labelsVisible && <Html center distanceFactor={20} position={[0, 0.9, 0]}>
        <div className={`fleet-badge ${selected ? 'selected' : ''}`}>
          {fleet.name}
        </div>
      </Html>}
    </group>
  );
}

function HyperlaneLines({ hyperlanes, systems, reachableSystemIds, selectedFleetSystemId }: { hyperlanes: Hyperlane[]; systems: StarSystem[]; reachableSystemIds: string[]; selectedFleetSystemId: string | null }) {
  return (
    <>
      {hyperlanes.map((lane) => {
        const start = systems.find((item) => item.id === lane.startSystemId);
        const end = systems.find((item) => item.id === lane.endSystemId);
        if (!start || !end || (start.visibilityLevel === 'HIDDEN' && end.visibilityLevel === 'HIDDEN')) return null;

        const highlighted =
          !!selectedFleetSystemId &&
          ((lane.startSystemId === selectedFleetSystemId && reachableSystemIds.includes(lane.endSystemId)) ||
            (lane.endSystemId === selectedFleetSystemId && reachableSystemIds.includes(lane.startSystemId)));

        return (
          <Line
            key={lane.id}
            points={[[start.position.x / 80, 0, start.position.z / 80], [end.position.x / 80, 0, end.position.z / 80]]}
            color={highlighted ? '#c8b7ff' : lane.type === 'WORMHOLE' ? '#4ECDC4' : '#7A8AB7'}
            lineWidth={highlighted ? 2.2 : 1.2}
            transparent
            opacity={highlighted ? 0.95 : 0.6}
          />
        );
      })}
    </>
  );
}

export default function StarMap({ systems, hyperlanes, fleets, factions, selectedSystemId, selectedFleetId, reachableSystemIds, labelsVisible, onSelectSystem, onSelectFleet }: { systems: StarSystem[]; hyperlanes: Hyperlane[]; fleets: Fleet[]; factions: Faction[]; selectedSystemId: string | null; selectedFleetId: string | null; reachableSystemIds: string[]; labelsVisible: boolean; onSelectSystem: (systemId: string) => void; onSelectFleet: (fleetId: string) => void; }) {
  const selectedFleet = fleets.find((fleet) => fleet.id === selectedFleetId) ?? null;

  return (
    <Canvas camera={{ position: [0, 12, 18], fov: 45 }}>
      <color attach="background" args={['#0B0C15']} />
      <ambientLight intensity={1.4} />
      <pointLight position={[8, 10, 6]} intensity={80} />
      <Stars radius={80} depth={30} count={3000} factor={4} saturation={0} fade speed={0.3} />
      <HyperlaneLines hyperlanes={hyperlanes} systems={systems} reachableSystemIds={reachableSystemIds} selectedFleetSystemId={selectedFleet?.systemId ?? null} />
      {systems.map((system) => (
        <SystemNode
          key={system.id}
          system={system}
          owner={factions.find((faction) => faction.id === system.ownerId)}
          selected={selectedSystemId === system.id}
          reachable={reachableSystemIds.includes(system.id)}
          labelsVisible={labelsVisible}
          onSelect={() => onSelectSystem(system.id)}
        />
      ))}
      {fleets.map((fleet) => (
        <FleetMarker key={fleet.id} fleet={fleet} systems={systems} factions={factions} selected={selectedFleetId === fleet.id} labelsVisible={labelsVisible} onSelect={() => onSelectFleet(fleet.id)} />
      ))}
      <OrbitControls enablePan enableZoom enableRotate={false} />
    </Canvas>
  );
}
