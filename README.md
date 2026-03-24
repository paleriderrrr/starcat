# starcat

MeowStellar / starcat project workspace.

Current structure:

- `frontend`: React + TypeScript + Three.js prototype client
- `backend`: FastAPI backend for AI and game services
- `core`: Rust core prototype
- `starcat`: Godot client migration and gameplay prototype
- `docs/design`: converted and split design documents

## Run

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Backend

The backend supports Bailian-compatible model access via environment variables:

- `BAILIAN_API_KEY`
- `BAILIAN_MODEL` default: `qwen3.5-flash`
- `BAILIAN_BASE_URL` default: `https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1`

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

See `backend/.env.example` for local configuration.

### Core

```bash
cd core
cargo build
```

### Godot Client

Open `starcat/project.godot` with Godot 4.5.

## Status

The repository contains the current playable prototype, Godot migration work, backend AI integration, and the synced design documentation.
