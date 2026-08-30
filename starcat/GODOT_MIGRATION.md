# Starcat Godot Client

`starcat/` is the current product implementation of MeowStellar. It is a Godot 4.6 strategy-game client, not a web migration skeleton.

## Current Product Implementation

- `project.godot` starts `scenes/Main.tscn` and registers `GameState`, `ApiClient`, and `AudioManager` as AutoLoads.
- `scenes/Main.tscn`, `StarMap.tscn`, and `HudLayer.tscn` provide the menu, interactive 3D strategic map, and game HUD.
- `scripts/GameLogic.gd` owns the deterministic 4X rules: research, construction, ship production, fleets, exploration, colonization, diplomacy, combat, turn processing, and victory checks.
- `scripts/services/` provides local analysis, AI decisions, narrative fallback, and decision-iteration artifacts. Remote LLM use remains optional.
- `scripts/autoload/GameState.gd` writes a decision snapshot, decision record, transition evaluation, and resulting snapshot for every processed AI turn.
- `tools/runtime_smoke_test.gd` exercises the playable loop in Godot headless mode, including persisted JSONL decision artifacts.

## Architecture Boundary

The Godot client is the authoritative runtime. GDScript owns state transitions and rule validation. The LLM may propose strategic intent or narrative text, but it never mutates game state directly.

The earlier Rust/Wasm, React, Three.js, and independent Python service proposals are retired as current implementation targets. A GDExtension can be considered later only if profiling identifies a real performance bottleneck.

## Local LLM Configuration

Copy `starcat.local.cfg.example` to `starcat.local.cfg` to enable an optional provider. With `remote_enabled=false`, the project remains fully playable using deterministic local AI and narrative fallbacks.

## Verification

From the repository root, run the complete Godot verification flow with an installed Godot executable:

```powershell
.\starcat\tools\run_godot_checks.ps1 -GodotPath "C:\path\to\Godot.exe"
```

Set `GODOT_PATH` instead of passing `-GodotPath` to use the same command in CI. Add `-IncludeMimo` only when `MIMO_API_KEY` is available and an external provider smoke test is intended.

## Development Constraints

- Prefer `.tscn` scenes for user-visible UI structure and styling.
- Keep gameplay rules deterministic and centralized in `GameLogic.gd`.
- Use signals for scene communication and AutoLoads for cross-scene state.
- Treat `user://decision_iterations/records.jsonl` as research telemetry, not as a player save file.
