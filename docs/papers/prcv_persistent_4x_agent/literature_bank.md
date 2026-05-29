# Literature Bank: Persistent Persona Agents for 4X Games

This survey was prepared with the local Research Harness MCP domain `starcat_persistent_4x_agents`, the downloaded Oh My Paper research harness, and web searches over agent and 4X strategy literature.

## Agent Architecture Papers

### Generative Agents

- Source: https://arxiv.org/abs/2304.03442
- Claim: believable agents require observation, memory retrieval, reflection, and planning over accumulated experiences.
- Use in paper: motivates persistent persona memory and reflection records.

### ReAct

- Source: https://arxiv.org/abs/2210.03629
- Claim: reasoning traces and environment actions are more useful when interleaved.
- Use in paper: motivates LLM-authored rationales paired with typed decision primitives.

### Reflexion

- Source: https://arxiv.org/abs/2303.11366
- Claim: language agents can improve by storing verbal reflections derived from feedback rather than updating model weights.
- Use in paper: motivates offline reflection and playbook revision.

### Voyager

- Source: https://arxiv.org/abs/2305.16291
- Claim: lifelong embodied agents can accumulate reusable skills and improve through iterative feedback.
- Use in paper: motivates a playbook library, but PPA keeps playbooks declarative and rule-validated rather than arbitrary runtime code.

## 4X / Strategy Game AI Papers

### CivRealm

- Source: https://arxiv.org/abs/2401.10568
- Claim: Civilization-like environments support both tensor-based RL agents and language-based reasoning agents.
- Use in paper: establishes 4X-like games as serious decision-making benchmarks.

### Vox Deorum

- Source: https://arxiv.org/abs/2512.18564
- Claim: in 4X games, LLMs are promising for macro strategy while tactical execution should be delegated to specialized subsystems.
- Use in paper: supports the high-level strategist plus deterministic rule executor split.

### CivBench

- Source: https://arxiv.org/abs/2604.07733
- Claim: terminal win/loss is too sparse for long Civilization games; turn-level victory progress is needed.
- Use in paper: supports VP-AUC and dense progress evaluation for offline improvement.

### CivAgent

- Source: https://github.com/fuxiAIlab/CivAgent
- Claim: human players outperform traditional AI partly through rational strategic decisions, flexible diplomacy, negotiation, and deception.
- Use in paper: supports persistent diplomatic persona and memory.

## Research Gap

Existing work shows memory, reflection, macro-strategy LLMs, and long-horizon strategic benchmarks. The gap is a deployable 4X game architecture where each AI faction has a persistent persona that affects every decision, emits rule-checkable primitives, and improves through offline trajectory analysis without unsafe runtime self-modification.
