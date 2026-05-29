# PRCV Persistent 4X Agent Paper

This folder contains a research-oriented paper draft for Starcat's persistent AI agent architecture.

## Files

- `main.tex` - PRCV-style manuscript draft.
- `references.bib` - bibliography.
- `literature_bank.md` - research survey notes and claim mapping.
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
