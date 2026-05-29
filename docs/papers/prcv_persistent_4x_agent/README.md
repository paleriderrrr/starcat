# PRCV Persistent 4X Agent Paper

This folder contains a research-oriented paper draft for Starcat's persistent AI agent architecture.

## Files

- `main.tex` - PRCV-style manuscript draft.
- `references.bib` - bibliography.
- `literature_bank.md` - research survey notes and claim mapping.
- `model_construction.md` - detailed persistent persona agent state, storage, primitive, validation, and update design.
- `experiment_plan.md` - research questions, baselines, ablations, scenario suite, metrics, and execution milestones.
- `experiments/` - deterministic Stage 1 proxy experiment used to exercise the proposed metrics before live game integration.
- `results/` - generated Stage 1 CSV, manifest, and summary artifacts.
- `research_harness_log.md` - record of Research Harness and Oh My Paper usage.

## Core Thesis

4X game AI often has local tactical competence but weak global strategic continuity. A persistent persona agent can improve long-horizon believability and strategic coherence by making every decision depend on:

- durable personality traits;
- mutable strategic commitments;
- memories and reflections;
- current game state;
- global strategic summary;
- rule-validated decision primitives.

The LLM proposes primitives. The game engine validates and executes. Offline analysis updates persona playbooks and regression tests.
