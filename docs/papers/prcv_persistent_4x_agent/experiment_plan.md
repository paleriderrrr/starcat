# Experiment Plan for Persistent Persona Agents

## Goal

Evaluate whether persistent persona, global strategic summaries, primitive-constrained LLM decisions, and offline trajectory improvement produce better 4X game AI than local heuristics or stateless LLM strategists.

## Research Questions

**RQ1: Strategic Progress.** Does the full Persistent Persona Agent improve long-horizon progress toward victory compared with heuristic and stateless LLM baselines?

**RQ2: Persona Coherence.** Do persistent traits and commitments make AI behavior more consistent and interpretable across turns?

**RQ3: Adaptation.** Does offline reflection and playbook updating reduce repeated strategic failures across scenarios?

**RQ4: Safety and Legality.** Does primitive validation reduce illegal or hallucinated actions while preserving strategic expressiveness?

**RQ5: Global Strategy.** Does adding a global summary improve macro-strategic decisions beyond local observation alone?

## Hypotheses

| ID | Hypothesis |
|---|---|
| H1 | PPA-Full achieves higher VP-AUC than Heuristic and LLM-NoPersona. |
| H2 | PPA-Full has higher persona-action alignment than LLM-Episodic. |
| H3 | Removing GlobalSummary reduces response to distant victory threats and diplomatic blocs. |
| H4 | Removing primitive validation increases invalid or unrealizable actions. |
| H5 | Offline playbook updates reduce repeated failure clusters over evaluation rounds. |

## Environments

### Stage 1: Starcat Local Prototype

Use Starcat as the controlled implementation environment.

- Advantages: fully inspectable state, quick iteration, domain-specific personality fields.
- Role: architecture validation, schema testing, early ablation.
- Output: decision ledgers, persona coherence metrics, deterministic scenario tests.

### Stage 2: CivRealm / Freeciv

Use CivRealm as a broader 4X-like benchmark.

- Advantages: published environment, language-agent interface, existing baselines.
- Role: external validity beyond Starcat.
- Output: progress metrics, task completion, full-game survival and expansion results.

### Stage 3: Civilization-Style Progress Benchmark

Use CivBench-like progress evaluation when available.

- Advantages: turn-level victory probability and strategic profile analysis.
- Role: long-horizon macro-strategy validation.
- Output: VP-AUC, strategic profile, model-specific behavior comparison.

## Agent Variants

| Variant | Persona | Memory | Global Summary | Primitive Validation | Offline Update |
|---|---|---|---|---|---|
| Heuristic | no | no | limited | yes | no |
| LLM-NoPersona | no | no | yes | yes | no |
| LLM-Episodic | no | episodic | yes | yes | no |
| PPA-NoGlobal | yes | yes | no | yes | no |
| PPA-NoValidation | yes | yes | yes | no | no |
| PPA-NoOffline | yes | yes | yes | yes | no |
| PPA-Full | yes | yes | yes | yes | yes |

## Scenario Suite

Create deterministic scenarios that expose global strategy weaknesses.

### S1: Expansion Race

Two factions compete for high-value neutral systems.

- Measures: expansion efficiency, resource growth, frontier commitment.
- Failure pattern: wandering exploration without securing valuable systems.

### S2: Betrayal Memory

One faction breaks a treaty, then later requests cooperation.

- Measures: memory recall, trust adjustment, treaty response.
- Failure pattern: accepting repeated betrayal without persona-consistent consequence.

### S3: Distant Victory Threat

A rival approaches science or diplomacy victory outside the local frontier.

- Measures: global summary usage, response latency, coalition behavior.
- Failure pattern: ignoring non-local victory threats.

### S4: Two-Front War

The agent faces pressure from two rivals.

- Measures: defensive posture, fleet consolidation, peace-seeking.
- Failure pattern: overextension and incoherent target switching.

### S5: Resource Bottleneck

The agent has strong military intent but weak mineral or industry income.

- Measures: ability to delay aggression and invest economy.
- Failure pattern: declaring war without production support.

### S6: Personality Conflict

An honorable but aggressive faction faces a tempting betrayal opportunity.

- Measures: persona coherence, justified override, long-term diplomatic cost.
- Failure pattern: personality collapse into short-term utility maximization.

## Metrics

### Strategic Metrics

| Metric | Definition |
|---|---|
| VP-AUC | average turn-level victory progress over a run |
| Victory Delta | final best victory progress minus initial progress |
| Expansion Efficiency | acquired system value per turn |
| Military Readiness | fleet power relative to nearby rivals |
| Recovery Score | improvement after negative events |

### Persona Metrics

| Metric | Definition |
|---|---|
| Persona-Action Alignment | fraction of actions consistent with active traits and commitments |
| Commitment Stability | average duration of victory path and posture absent strong evidence |
| Justified Pivot Rate | fraction of strategy changes backed by explicit evidence |
| Diplomatic Memory Accuracy | correct recall of past treaties, betrayals, and favors |
| Identity Diversity | behavioral separation between different persona presets |

### Safety Metrics

| Metric | Definition |
|---|---|
| Invalid Primitive Rate | primitives rejected by validator |
| Illegal Action Rate | attempted actions impossible under game rules |
| Fallback Rate | decisions replaced by heuristic fallback |
| Hallucinated Target Rate | references to nonexistent or invisible targets |

### Improvement Metrics

| Metric | Definition |
|---|---|
| Failure Recurrence | repeated instances of the same failure cluster |
| Regression Pass Rate | scenario tests passed after offline update |
| Playbook Lift | metric improvement after playbook update |
| Reflection Utility | improvement when retrieved reflection is used |

## Persona Presets

Use six initial personas:

| Persona | Traits |
|---|---|
| Militarist Hegemon | high aggression, high expansionism, medium honor |
| Cautious Trader | low aggression, high trade, high honor |
| Scientific Isolationist | high science, low trade, low risk |
| Opportunistic Raider | high opportunism, high aggression, low honor |
| Defensive Federalist | high honor, high paranoia, high diplomacy |
| Expansionist Industrialist | high expansionism, high economy, medium risk |

Each scenario should run with at least three personas to test identity diversity.

## Prompt Packet Ablation

Test the effect of packet fields:

```text
Base packet: local_state + legal_primitive_schema
+ persona_state
+ retrieved_memories
+ global_summary
+ playbook_hints
+ previous_reflections
```

Measure both performance and prompt cost.

## Offline Update Protocol

One experimental round:

1. Run all scenarios for all variants.
2. Write decision ledgers and evaluation records.
3. Cluster failures by cause.
4. Generate reflection candidates.
5. Update playbook weights for PPA-Full only.
6. Re-run all scenarios.
7. Compare before/after metrics.

Acceptance rule:

```text
accept update if:
  VP-AUC improves or failure recurrence decreases
  and invalid primitive rate does not increase
  and persona-action alignment does not decrease by more than 3%
```

## Statistical Plan

For each environment and variant:

- run at least 20 seeds per scenario in Starcat;
- run at least 5 seeds per scenario in CivRealm if runtime cost is high;
- report mean, standard deviation, and bootstrap 95% confidence interval;
- use paired comparisons where variants share seeds;
- report per-persona breakdowns rather than only aggregate scores.

## Tables for the Paper

### Main Result Table

| Variant | VP-AUC | Persona Alignment | Invalid Primitive Rate | Failure Recurrence |
|---|---:|---:|---:|---:|
| Heuristic | | | | |
| LLM-NoPersona | | | | |
| LLM-Episodic | | | | |
| PPA-NoOffline | | | | |
| PPA-Full | | | | |

### Ablation Table

| Ablation | VP-AUC Change | Alignment Change | Invalid Rate Change |
|---|---:|---:|---:|
| remove persona | | | |
| remove memory | | | |
| remove global summary | | | |
| remove validation | | | |
| remove offline update | | | |

## Implementation Milestones

### Milestone 1: Schema and Logging

- Define persona, memory, primitive, validation, and ledger schemas.
- Create deterministic scenario runner.
- Verify JSONL logs are replayable.

### Milestone 2: Baselines

- Implement Heuristic, LLM-NoPersona, and LLM-Episodic.
- Record invalid action and fallback metrics.

### Milestone 3: PPA Core

- Implement persona store.
- Implement memory retrieval.
- Implement global summary.
- Implement primitive validator.

### Milestone 4: Offline Iteration

- Build failure clustering.
- Generate reflection candidates.
- Update playbook weights.
- Add regression scenario acceptance checks.

### Milestone 5: Paper Experiments

- Run seed grid.
- Export result tables.
- Produce trajectory examples.
- Write PRCV experiments section.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Persona becomes too rigid | allow evidence-gated strategic pivots |
| Memory becomes stale | add decay and retrieval recency weighting |
| LLM emits vague primitives | strict schema and validator feedback |
| Global summary leaks hidden info | construct summaries from legal visibility only |
| Offline updates overfit scenarios | hold out evaluation scenarios |
| Token cost grows too high | summarize memory and cap retrieved records |

## Minimum Publishable Experiment

If time is limited, run only Starcat Stage 1:

- six scenarios;
- four variants: Heuristic, LLM-NoPersona, PPA-NoOffline, PPA-Full;
- ten seeds per scenario;
- report VP-AUC, persona alignment, invalid primitive rate, and failure recurrence;
- include two qualitative trajectory case studies.

This is enough for a PRCV workshop-style system paper if positioned as an architecture and benchmark proposal.
