# Starcat Godot Client Skeleton

这个目录下的 `starcat` 已经从空 Godot 工程推进到“可继续开发的完整迁移底座”，目标是把现有 `React + Three.js` 原型逐步迁入 Godot。

## 当前已落地

- `project.godot`
  - 设置了 `Main.tscn` 为入口场景
  - 注册了 `GameState` 和 `ApiClient` 两个 AutoLoad
- `scenes/Main.tscn`
  - 主场景，组合星图与 HUD
- `scenes/StarMap.tscn`
  - 3D 星图根场景
- `scenes/HudLayer.tscn`
  - 顶部资源栏、右侧抽屉、底部导航栏
- `scripts/autoload/GameState.gd`
  - 全局游戏状态、选中上下文、标签显隐、回合推进
- `scripts/autoload/ApiClient.gd`
  - 后端接口入口占位
- `scripts/StarMap.gd`
  - 用现代 Godot 模式动态生成星系、航道、舰队
- `scripts/HudLayer.gd`
  - HUD 与抽屉内容的动态构建
- `scripts/data/InitialData.gd`
  - 从 web 版迁入的全量初始配置、建筑、科技、舰船与星图数据
- `scripts/GameLogic.gd`
  - 从 web 版迁入的核心玩法规则：研究、建造、造舰、跃迁、探索、殖民、维修、条约、回合推进、飞升与胜负判定

## 迁移映射

网页原型到 Godot 的映射已经定下来了：

- `frontend/src/App.tsx` -> `scripts/Main.gd`
- `frontend/src/components/StarMap.tsx` -> `scripts/StarMap.gd`
- `frontend/src/components/UI.tsx` -> `scripts/HudLayer.gd`
- `frontend/src/game/data.ts` -> `scripts/autoload/GameState.gd`
- `backend/main.py` -> `scripts/autoload/ApiClient.gd` 的 HTTP 调用目标

## 下一步建议

1. 用 Godot 编辑器实际打开工程，修正仅在运行时才会暴露的 UI 或 GDScript 细节
2. 把后端 AI 决策正式接进 `advance_turn`，让商贾联盟回合也走结构化模型输出
3. 给星图补相机拖拽、缩放、Hover 提示和更清晰的舰队选中反馈
4. 给 HUD 增加消息中心与更精细的战斗/条约摘要
5. 再评估是否把 Rust 核心通过 GDExtension 接入 Godot

## 设计约束

- 场景切换优先用 `get_tree().change_scene_to_file()`
- 场景通信优先用 `signals`
- 全局状态放在 `AutoLoad`
- GDScript 统一写类型标注
- 涉及用户可见界面改动时，默认优先通过 `.tscn` 场景和 Godot 编辑器完成可视化修改；只有在需求明确说明，或 UI 结构本身由通用数据驱动且无法稳定用编辑器表达时，才允许在脚本中动态创建 UI 节点
- 暂时不把百炼 API Key 放进 Godot 客户端，AI 仍保留走 FastAPI
