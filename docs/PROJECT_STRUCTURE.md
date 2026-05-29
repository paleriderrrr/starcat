# Starcat Project Structure

Starcat is a Godot 4.6.2 strategy prototype with repository-level design docs and Python structural tests.

## Root

- `README.md` - project entry point and setup notes.
- `SPEC.md` - high-level product/specification source.
- `.gitignore` - repository-wide local and generated file rules.
- `tests/` - Python regression tests that inspect Godot scripts, scenes, assets, and docs.

## Godot Project

- `starcat/project.godot` - Godot project file.
- `starcat/scenes/` - top-level scenes:
  - `Main.tscn` launches the game.
  - `StarMap.tscn` renders the 3D star map.
  - `HudLayer.tscn` renders the main HUD.
- `starcat/scenes/ui/` - reusable Control scene components.
- `starcat/scripts/` - GDScript runtime code:
  - `autoload/` contains global game services.
  - `config/` loads local and project settings.
  - `data/` owns initial state and setup presets.
  - `llm/` contains optional model provider clients.
  - `services/` contains local analysis, AI, narrative, and iteration services.
- `starcat/assets/` - imported runtime assets for audio, UI, factions, fonts, and star map VFX.
- `starcat/tools/` - asset generation, smoke tests, and runtime audit scripts.

## Documentation

- `docs/design/` - canonical design documents split by topic.
- `docs/papers/` - academic paper drafts and publication-oriented research artifacts.
- `docs/research/` - external research summaries and technical recommendations.
- `docs/superpowers/specs/` - implementation specs used by agentic workflows.
- `docs/superpowers/plans/` - task-by-task implementation plans.

## Local-Only Outputs

The following paths are intentionally ignored:

- `.tmp/` - downloaded or extracted source assets and scratch files.
- `.superpowers/` - local brainstorming companion state.
- `runtime_captures/` - generated screenshots and runtime logs.
- `starcat/starcat.local.cfg` - local LLM keys and provider settings.

Keep durable assets under `starcat/assets/`, durable documentation under `docs/`, and reproducible checks under `tests/`.
