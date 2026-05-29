# starcat

MeowStellar / starcat project workspace.

Current structure:

- `starcat`: Godot client and gameplay prototype
- `docs/design`: converted and split design documents
- `docs/papers`: academic paper drafts and publication-oriented research artifacts
- `docs/research`: research notes that inform future AI and evaluation work
- `docs/superpowers`: implementation specs and plans
- `tests`: repository-level migration regression checks

### Godot Client

Open `starcat/project.godot` with Godot 4.6.2.

The Godot client now includes local game-analysis, AI-decision, diplomacy, and narrative services. Normal development runs fully inside the Godot project.

### Optional LLM

Create `starcat/starcat.local.cfg` from `starcat/starcat.local.cfg.example` if you want direct LLM access from Godot. If `remote_enabled` is `false` or no key is provided, the client stays fully local and falls back to built-in rule/template generation.

Bailian-compatible example:

```ini
[llm]
remote_enabled=true
provider=bailian
api_key=your-key
model=qwen3.5-flash
base_url=https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1
```

Mimo/OpenAI-compatible example:

```ini
[llm]
remote_enabled=true
provider=mimo
mimo_api_key=your-key
mimo_model=mimo-v2.5-pro
mimo_base_url=https://api.xiaomimimo.com/v1
```

Environment variables are also supported: `BAILIAN_API_KEY`, `DASHSCOPE_API_KEY`, `BAILIAN_MODEL`, `BAILIAN_BASE_URL`, `MIMO_API_KEY`, `MIMO_MODEL`, and `MIMO_BASE_URL`.

## Project Map

See `docs/PROJECT_STRUCTURE.md` for the current directory layout, ownership boundaries, and ignored local-only outputs.

## Status

The repository contains the Godot client with built-in local services, optional direct LLM integration, synced design documentation, and lightweight regression tests for the Godot-side service migration.
