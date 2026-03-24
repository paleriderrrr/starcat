# MeowStellar

按 `SPEC.md` 从零重建的三层项目骨架：

- `frontend`: React + TypeScript + Three.js 的 4X 原型界面
- `backend`: FastAPI 的 AI 与外交接口骨架
- `core`: Rust/Wasm 的状态核心与效用函数骨架

## 启动方式

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Backend

后端已支持阿里云百炼兼容接口。默认读取 `backend/.env` 或系统环境变量中的：

- `BAILIAN_API_KEY`
- `BAILIAN_MODEL`，默认 `qwen3.5-flash`
- `BAILIAN_BASE_URL`，默认 `https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1`

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

如果需要新建本地配置，可参考 `backend/.env.example`。

### Core

```bash
cd core
cargo build
```

## 当前范围

这版已恢复并联通：基础星图、资源展示、回合推进、研究推进、后端 AI 决策、外交文案生成，以及 Rust 核心构建。
