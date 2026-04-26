# starcat

MeowStellar / starcat project workspace.

Current structure:

- `starcat`: Godot client and gameplay prototype
- `docs/design`: converted and split design documents
- `tests`: repository-level migration regression checks

### Godot Client

Open `starcat/project.godot` with Godot 4.6.2.

The Godot client now includes local game-analysis, AI-decision, diplomacy, and narrative services. Normal development runs fully inside the Godot project.

### Optional LLM

Create `starcat/starcat.local.cfg` from `starcat/starcat.local.cfg.example` if you want direct Bailian access from Godot:

```ini
[llm]
remote_enabled=true
api_key=your-key
model=qwen3.5-flash
base_url=https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1
```

If `remote_enabled` is `false` or no key is provided, the client stays fully local and falls back to built-in rule/template generation.

## Status

The repository contains the Godot client with built-in local services, optional direct LLM integration, synced design documentation, and lightweight regression tests for the Godot-side service migration.
