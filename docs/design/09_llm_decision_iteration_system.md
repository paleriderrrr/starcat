# LLM Decision Iteration System

This design adapts the latest deep research report into Starcat's current Godot architecture. The key idea is to treat model improvement as a closed-loop artifact protocol, not as direct in-game self-modification.

## Research Mapping

The report's recommended loop is:

`Game Adapter -> State Briefer -> Router -> Playbook Library/Strategist -> Action/Patch -> Evaluator VP(t)/Risk -> Regression Harness -> Coding-Agent Updater -> Compression/Refactor -> loop`

Starcat maps that loop as follows:

- Game Adapter: `GameState.gd`, `GameLogic.gd`, and `GameAnalysisService.gd`.
- State Briefer: `DecisionIterationService.gd` builds compact turn artifacts from the current game state.
- Router: `ApiClient.gd` exposes provider-free snapshot collection first; later it can choose local heuristics, LLM strategy, or replay mode.
- Playbook Library/Strategist: current `LocalAIService.gd` decisions become the baseline playbook.
- Action/Patch: game actions remain explicit `GameLogic.gd` transitions; code patches stay outside runtime play.
- Evaluator VP(t)/Risk: transition records compare victory progress, resources, fleet power, status, and risk flags.
- Regression Harness: Python/Godot tests and saved JSONL trial records gate accepted changes.
- Coding-Agent Updater: future patches are produced from failure clusters, then tested before adoption.
- Compression/Refactor: winning records and playbooks are periodically summarized into smaller strategy artifacts.

## Minimum Artifacts

`TurnSnapshot` captures `game_id`, `turn`, `civ`, `visible_state`, `features23`, and `vp_t`. The `features23` block is deliberately fixed-width so trials can be compared in CSV/JSONL without parsing arbitrary prompt text.

`DecisionRecord` captures the chosen action, target, rationale, `playbook_id`, called tools, token metadata, fallback status, and a digest of the snapshot it came from.

`PatchRecord` is not executed inside the game runtime. It should be produced by external coding-agent runs with `parent_sha`, `diff`, `root_cause`, and `tests_added`.

`TrialRecord` summarizes a replay or simulation run with seed, map, civilizations, turn count, VP_AUC, cost, wall time, and code SHA.

`TestCase` points to a savegame plus assertions. It is the bridge between a discovered failure and a regression test.

## First Implementation

`DecisionIterationService.gd` is the first internal closed loop component. It can:

- build a `TurnSnapshot` from the current dictionary game state;
- build a `DecisionRecord` around existing AI or heuristic decisions;
- evaluate before/after snapshots with VP and risk deltas;
- build `PatchRecord` and `TestCase` artifacts for external coding-agent loops;
- build a `TrialRecord` for replay comparison;
- validate required artifact fields before accepting records;
- serialize records as JSONL lines;
- append valid artifacts to `user://decision_iterations/records.jsonl`.

`ApiClient.gd` exposes snapshot, decision, transition evaluation, trial, and JSONL write routes without requiring Bailian or any other model provider. `GameState.gd` still exposes a snapshot request wrapper for UI/debug tooling, and now also records the merchant AI turn automatically: it captures the pre-turn state, the selected decision, the post-turn state, and the evaluation as one JSONL artifact group. This keeps instrumentation available in CI and during offline play without granting the model authority to mutate game state directly.

## Iteration Policy

The game should not let a model patch code during a live run. A safe iteration cycle is:

1. Record snapshots and decisions during deterministic local trials.
2. Evaluate runs with VP_AUC, loss flags, and cost.
3. Cluster repeated failures into candidate root causes.
4. Generate minimal patches outside runtime.
5. Add regression tests for each accepted failure case.
6. Accept a patch only when replay and regression checks pass.
7. Compress successful playbooks into smaller strategy records.

This keeps Starcat's model loop inspectable, reproducible, and rollback-friendly.

## Completion Boundary

This module is complete for local instrumentation and offline iteration data collection when:

- all five minimum artifacts can be constructed;
- artifact records can be validated before persistence;
- records can be emitted as JSONL for replay/regression tooling;
- `ApiClient.gd` can route snapshot, record, evaluation, trial, and write requests;
- no runtime path allows a model to directly mutate source code or apply patches during active play.

The next module should be a deterministic replay harness that consumes JSONL and savegame fixtures, then reports VP_AUC and regression failures.
