# Persistent Persona Agent Model Construction

## Goal

Build a persistent AI civilization model for 4X strategy games. The model should make every strategic decision depend on:

- durable personality traits;
- mutable strategic commitments;
- long-term memories and reflections;
- current local game state;
- global strategic summary;
- typed decision primitives emitted by an LLM;
- deterministic rule validation and execution;
- offline improvement from decision trajectories.

The model is not a neural network trained inside the game. It is a deployable agent architecture that combines persistent storage, LLM reasoning, symbolic validation, and trajectory-level evaluation.

## Core State

At turn `t`, each civilization agent owns a persistent state:

```text
A_t = {
  persona: P_t,
  memory: M_t,
  commitments: C_t,
  playbook_weights: W_t,
  decision_ledger: L_t
}
```

The game engine owns the authoritative world state:

```text
S_t = {
  map,
  factions,
  fleets,
  resources,
  diplomacy,
  technology,
  events,
  victory_progress,
  visibility
}
```

The agent never mutates `S_t` directly. It proposes intent. The engine validates and executes.

## Persona State

`P_t` contains slow-moving identity variables:

| Field | Range | Meaning |
|---|---:|---|
| aggression | 0-100 | preference for military pressure |
| risk_tolerance | 0-100 | willingness to accept uncertain outcomes |
| honor | 0-100 | treaty-keeping and retaliation restraint |
| expansionism | 0-100 | preference for colonization and territorial growth |
| opportunism | 0-100 | willingness to exploit weakness |
| trade_affinity | 0-100 | preference for treaties and economic exchange |
| science_drive | 0-100 | preference for research and ascension goals |
| paranoia | 0-100 | sensitivity to nearby threats |

These traits define the agent's style. They should change slowly, if at all, during a single campaign.

## Strategic Commitments

`C_t` stores medium-rate strategic choices:

```text
C_t = {
  victory_path: MILITARY | DIPLOMATIC | SCIENCE | ECONOMIC | SURVIVAL,
  posture: PEACEFUL | GUARDED | EXPANSIONIST | MILITARIZED | DESPERATE,
  primary_rival,
  preferred_ally,
  expansion_frontier,
  defense_priority,
  treaty_policy,
  current_campaign_goal
}
```

Commitments can change, but only when evidence exceeds a threshold. This prevents strategic drift.

## Memory Store

`M_t` is split into three memory types.

### Episodic Memory

Raw events:

```text
{
  turn,
  actor,
  target,
  event_type,
  payload,
  salience,
  trust_delta,
  threat_delta
}
```

Examples: treaty signed, border violation, surprise attack, gift, colony race, fleet loss.

### Semantic Memory

Compressed facts:

```text
{
  subject,
  predicate,
  value,
  confidence,
  last_observed_turn
}
```

Example: "Orchid Pact tends to expand toward nebula systems."

### Reflective Memory

Natural-language strategic lessons:

```text
{
  reflection_id,
  trigger_cluster,
  lesson,
  affected_playbooks,
  expiry_condition
}
```

Example: "Do not open a second front unless fleet_power_ratio > 1.4 and minerals_net is positive."

## Global Summary

The system builds `G_t`, a compact global strategic summary:

```text
G_t = {
  leader_board,
  victory_race,
  threat_map,
  opportunity_map,
  diplomatic_blocs,
  contested_frontiers,
  economic_bottlenecks,
  upcoming_risks
}
```

The summary is separate from local observation. It gives the strategist a high-level view without exposing illegal hidden information. Fields must respect visibility rules.

## Decision Packet

Each LLM call receives a bounded packet:

```text
X_t = {
  persona_state: P_t,
  commitments: C_t,
  retrieved_memories: R(M_t, S_t, G_t),
  playbook_hints: top_k(W_t),
  local_state: O_t,
  global_summary: G_t,
  legal_primitive_schema,
  output_contract
}
```

The packet is intentionally redundant in strategic terms but narrow in action terms. The LLM can reason broadly but can only output typed primitives.

## LLM Policy

The LLM strategist is a black-box policy:

```text
Z_t = pi_llm(X_t)
```

The output `Z_t` is a list of primitives:

```json
{
  "turn": 42,
  "stance_update": {
    "primitive": "SHIFT_POSTURE",
    "value": "MILITARIZED",
    "reason": "Nearby rival fleet concentration threatens the expansion frontier."
  },
  "actions": [
    {
      "primitive": "MOBILIZE_FLEET",
      "target": "frontier_cluster_alpha",
      "priority": 0.82,
      "persona_alignment": ["paranoia", "aggression"]
    },
    {
      "primitive": "INVEST_ECONOMY",
      "target": "mineral_shortage",
      "priority": 0.61,
      "persona_alignment": ["risk_tolerance"]
    }
  ],
  "memory_write": [
    {
      "type": "reflection_candidate",
      "content": "Rival pressure is now high enough to justify fleet consolidation."
    }
  ]
}
```

## Decision Primitive Set

| Family | Primitive | Meaning |
|---|---|---|
| Identity | SHIFT_POSTURE | update strategic stance |
| Identity | UPDATE_RIVALRY | mark rival or ally |
| Victory | PURSUE_VICTORY | choose or reinforce victory route |
| Economy | INVEST_ECONOMY | improve resource base |
| Economy | BUILD_INFRASTRUCTURE | request legal building choice |
| Military | MOBILIZE_FLEET | prepare or move forces |
| Military | DECLARE_WAR_INTENT | request war validation |
| Expansion | EXPAND_FRONTIER | scout or colonize target region |
| Diplomacy | PROPOSE_TREATY | request treaty action |
| Diplomacy | ISSUE_WARNING | generate diplomatic pressure |
| Meta | WRITE_MEMORY | add candidate memory |
| Meta | REQUEST_ANALYSIS | ask local analyzer for a report |

The LLM never emits direct engine commands such as "subtract 50 minerals" or "move fleet object X to coordinate Y." It emits intent.

## Rule Validation

The validator maps primitives to executable game actions:

```text
Y_t = V(Z_t, S_t, P_t, C_t)
```

Validation checks:

- primitive name is known;
- target exists and is visible or legally inferable;
- action is affordable;
- action respects diplomacy rules;
- action is compatible with current treaties;
- action does not violate hard persona constraints unless a crisis override is justified;
- action can be resolved into one or more concrete game commands.

Invalid primitives are rejected or downgraded to safe alternatives.

## Execution

The executor applies validated actions:

```text
S_{t+1} = E(Y_t, S_t)
```

The executor is deterministic. Randomness, if used, is seeded and logged.

## Persona Update

After execution, the system computes feedback:

```text
F_t = Eval(S_t, Y_t, S_{t+1})
```

Then it updates medium and fast state:

```text
C_{t+1} = U_C(C_t, F_t, P_t)
M_{t+1} = U_M(M_t, events_t, F_t)
W_{t+1} = U_W(W_t, F_t)
```

Slow persona traits update only through bounded calibration:

```text
P_{t+1} = clamp(P_t + delta_p, max_step = epsilon)
```

In most shipped games, `epsilon` should be very small or zero during a single campaign. The point is to preserve recognizable civilization identity.

## Persistent Storage Schema

Recommended storage layout:

```text
persona_store/
  faction_id.persona.json
memory_store/
  faction_id.episodic.jsonl
  faction_id.semantic.jsonl
  faction_id.reflections.jsonl
playbook_store/
  playbooks.json
  faction_id.weights.json
decision_ledger/
  game_id.decisions.jsonl
evaluation_store/
  game_id.evaluations.jsonl
regression_store/
  scenarios/
  expected_metrics.json
```

All stores should be append-friendly. Compaction runs offline.

## Offline Improvement Loop

The offline layer processes ledgers:

1. Cluster failure cases.
2. Extract repeated strategic mistakes.
3. Generate reflection candidates.
4. Update playbook weights.
5. Add regression scenarios.
6. Re-run deterministic trials.
7. Accept changes only if metrics improve and persona coherence does not regress.

This is the safety boundary: the runtime agent learns through stored state and curated playbooks, not through live code mutation.

## Model Variants

| Variant | Description | Purpose |
|---|---|---|
| Heuristic | local rules only | baseline |
| LLM-NoPersona | current state + global summary only | tests value of LLM reasoning |
| LLM-Episodic | adds raw memory | tests memory without identity |
| PPA-NoOffline | persona + memory, no improvement loop | tests persistent identity |
| PPA-Full | persona + memory + primitives + offline updates | proposed model |

## Expected Behavior

A strong PPA agent should:

- keep a recognizable strategic identity across the campaign;
- change plans when evidence justifies it;
- remember treaties, betrayals, and border pressure;
- improve from repeated failure cases;
- emit only auditable intent primitives;
- avoid illegal or hallucinated game actions through validation.
