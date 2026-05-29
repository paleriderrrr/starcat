# Research Harness Log

## Branch

- Branch: `codex/prcv-persistent-agent-research`
- Goal: prepare a PRCV-style research manuscript on persistent persona agents for 4X strategy games.

## Harness Setup

The external research harness was downloaded to an ignored local directory:

```text
.tmp/research_harness/Oh-my--paper
```

The downloaded harness identifies itself as "Oh My Paper", a research harness for agentic literature survey, ideation, experiment planning, paper writing, and review workflows. It provides the staged pipeline:

```text
Survey -> Ideation -> Experiment -> Publication -> Review
```

It also provides reusable paper section templates, research memory templates, and specialized research-agent role descriptions.

## MCP Research Harness Usage

The in-session Research Harness MCP was used to create a local research domain:

```text
domain: starcat_persistent_4x_agents
description: Persistent personality-driven LLM agents for long-horizon 4X strategy games, with primitive action validation and offline iteration.
```

The domain currently records the research direction and can be extended with topics, claims, and gap detection in later sessions.

## Survey Sources

The literature survey used web search over primary arXiv/OpenReview/GitHub sources for:

- Generative Agents
- ReAct
- Reflexion
- Voyager
- CivRealm
- Vox Deorum
- CivBench
- CivAgent

The working paper in this directory cites these sources in `references.bib`.

## Paper-Writing Adaptation

The downloaded harness section templates were used as structural scaffolding only. The generated manuscript was adapted to a PRCV-style system paper with:

- abstract
- introduction
- problem analysis
- related work
- method
- offline improvement layer
- evaluation protocol
- discussion
- conclusion

## Current Output

- `main.tex` - PRCV-style manuscript draft.
- `references.bib` - BibTeX references.
- `literature_bank.md` - source map and claims.
- `research_harness_log.md` - reproducibility record.
