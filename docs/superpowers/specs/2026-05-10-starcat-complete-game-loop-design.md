# Starcat Complete Game Loop Design

## Goal

Turn the current playable prototype into a complete local game loop: launch to main menu, configure a new match, start with a selected civilization, play on a larger map, and observe AI factions taking expansion, fleet, construction, and diplomacy actions over multiple turns.

## Scope

This milestone is a complete vertical slice, not an infinite-content final commercial release. It must be verifiable in the current Godot project with automated tests and runtime smoke checks.

## Player Flow

1. The game launches into a main menu overlay.
2. The player chooses a civilization, map scale, difficulty, and opponent count.
3. Starting a match creates a fresh game state from those settings.
4. The overlay hides and the existing star map plus HUD become active.
5. The player can continue using the existing 4X panels while AI factions act each turn.

## Setup Options

- Player civilization: any entry in `InitialData.civilization_pool()`.
- Map scale: `SKIRMISH`, `STANDARD`, `GRAND`.
- Difficulty: `CASUAL`, `STANDARD`, `HARD`.
- Opponent count: clamped by available civilization templates and map scale.

## Map Requirements

The default game must no longer feel like a five-node prototype. `STANDARD` should provide at least 9 systems and 11 hyperlanes. `GRAND` should provide at least 13 systems and 16 hyperlanes. Each AI faction gets a capital, a fleet, and valid relationships with the player and other AI factions.

## AI Requirements

AI turns must be visible and consequential. Every full AI turn should be able to:

- Choose a research direction if none is active for that faction metadata.
- Build economically useful structures on owned systems.
- Move fleets toward expansion or pressure targets.
- Start colonies when legal and affordable.
- Send diplomatic or intelligence messages that appear in the player-visible timeline.

Difficulty affects AI resources, aggression, and expansion pressure.

## UI Requirements

The main menu must be a real Control overlay in `Main.tscn`, not a separate static mock. It should use existing bridge UI texture language and keep the actual game as the first running scene after start. It must support runtime capture so screenshots prove both the menu and in-game views render.

## Testing Requirements

Tests must verify:

- Setup presets and option creation exist.
- `create_initial_state(options)` applies player civilization, difficulty, map scale, and opponent count.
- Standard and grand maps meet minimum topology counts.
- AI turn processing appends observable AI action records.
- Main scene contains the menu overlay and start controls.
- Runtime smoke covers configured match startup and several AI turns.
