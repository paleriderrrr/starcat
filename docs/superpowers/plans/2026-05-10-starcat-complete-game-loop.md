# Starcat Complete Game Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete local game loop from main menu setup to multi-turn AI-driven 4X play.

**Architecture:** Extend existing data-driven GDScript instead of replacing the game. `InitialData.gd` owns setup presets and map construction, `GameState.gd` owns match reset from setup options, `Main.gd` owns the launch overlay, and `GameLogic.gd` owns richer AI action records.

**Tech Stack:** Godot 4.6.2, GDScript, Python unittest structural tests, Godot runtime smoke script.

---

### Task 1: Tests First

**Files:**
- Modify: `tests/test_godot_backend_migration.py`
- Modify: `starcat/tools/runtime_smoke_test.gd`

- [ ] Add structural tests for setup presets, configured initial state, expanded maps, main menu scene nodes, AI action records, and configured runtime smoke coverage.
- [ ] Run `python -m unittest tests.test_godot_backend_migration.GodotBackendMigrationTests.test_complete_game_loop_setup_and_ai_are_wired -v` and confirm it fails because the new setup APIs and menu nodes are missing.

### Task 2: Data Setup

**Files:**
- Modify: `starcat/scripts/data/InitialData.gd`
- Modify: `starcat/scripts/autoload/GameState.gd`

- [ ] Add `default_game_setup_options()`, `map_scale_presets()`, `difficulty_presets()`, and `normalize_game_setup_options(options)`.
- [ ] Change `create_initial_state()` to accept an optional options dictionary while preserving the no-argument default.
- [ ] Build extra systems, hyperlanes, AI factions, fleets, and relationships from normalized setup options.
- [ ] Add `GameState.start_new_game(options)` that resets selections and emits state.

### Task 3: Main Menu

**Files:**
- Modify: `starcat/scenes/Main.tscn`
- Modify: `starcat/scripts/Main.gd`

- [ ] Add `MainMenuLayer` overlay with title, civilization selector, map scale selector, difficulty selector, opponent count selector, and start button.
- [ ] Populate selectors from `InitialData` presets.
- [ ] Start a configured game through `GameState.start_new_game(options)` and hide the overlay.
- [ ] Add runtime capture of `runtime_main_menu.png` before starting the in-game capture path.

### Task 4: AI Actions

**Files:**
- Modify: `starcat/scripts/GameLogic.gd`

- [ ] Add lightweight AI action records with turn, faction, action type, target, and summary.
- [ ] During `merchant_ai_turn` and `orchid_ai_turn`, append records for construction, fleet movement, colony attempts, and diplomacy.
- [ ] Generalize helper behavior enough for additional configured AI factions.

### Task 5: Verification

**Files:**
- Existing test and smoke files.

- [ ] Run targeted tests until green.
- [ ] Run `python -m unittest discover -s tests -v`.
- [ ] Run Godot headless startup and runtime smoke.
- [ ] Run real render capture and verify all PNGs are nonblank.
- [ ] Run static `res://` reference scan and GDScript delimiter scan.
