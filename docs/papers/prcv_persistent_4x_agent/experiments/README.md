# Stage 1 Proxy Experiment

This folder contains a deterministic Starcat-like proxy experiment for the Persistent Persona Agent paper.

Run:

```bash
python docs/papers/prcv_persistent_4x_agent/experiments/ppa_stage1_experiment.py --seeds 20
```

Outputs are written to:

```text
docs/papers/prcv_persistent_4x_agent/results/
```

The experiment is intended to validate the research protocol before full Godot/CivRealm experiments. It does not call live LLM services.
