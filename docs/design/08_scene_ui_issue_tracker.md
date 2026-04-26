# HUD 场景化修复 Issue 列表

范围：
- 仅覆盖当前 `Godot HUD / 场景可视化维护` 任务
- 目标是把常驻 HUD 与基础视觉组件从“脚本硬编码生成”为主，收束成“场景 / 预制可视化维护”为主

状态定义：
- `OPEN`：已确认但未修复
- `IN_PROGRESS`：正在修复
- `RESOLVED`：已修复并完成启动验证

## Issues

| ID | 标题 | 状态 | 说明 |
|---|---|---|---|
| HUD-001 | 顶部栏仍由脚本重建 | RESOLVED | 顶部栏改成场景内固定节点，脚本只更新值 |
| HUD-002 | 底部固定导航由脚本重建 | RESOLVED | 固定导航改成场景节点，脚本只更新激活态 |
| HUD-003 | 底部导航固定宽度不利于场景调整 | RESOLVED | 改为锚点驱动的自适应布局 |
| HUD-004 | 基础按钮/卡片/芯片为脚本硬生成 | RESOLVED | 已拆成 `ActionButton` / `InfoCard` / `Chip` 预制 |
| HUD-005 | 分段标题仍由脚本直接创建 | RESOLVED | 已拆成 `SectionTitle` 预制 |
| HUD-006 | 信息卡内部文本行仍由脚本直接创建 | RESOLVED | 已拆成 `InfoLine` 预制 |
| HUD-007 | 基础组件默认样式仍主要在脚本中定义 | RESOLVED | 默认样式迁移到预制场景 |
| HUD-008 | 右侧抽屉主面板样式仍由脚本施加 | RESOLVED | 主抽屉基础样式已迁移到 `.tscn` |
| HUD-009 | `NextTurnButton` 仍是普通场景按钮而非复用预制 | RESOLVED | 已改为 `ActionButton` 预制实例 |
| HUD-010 | 右侧抽屉重复操作行仍由脚本直接创建 | RESOLVED | 已拆成 `ActionRow` 预制，减少脚本内布局硬编码 |
| HUD-011 | 场景默认中文文本存在乱码占位 | RESOLVED | 已修复 `HudLayer.tscn` 与基础 UI 预制的默认中文文本 |
| HUD-012 | 外交自由交流输入区仍由脚本直接创建基础控件 | RESOLVED | 已拆成 `DiplomacyComposer` 预制，脚本只绑定数据与信号 |
| HUD-013 | 科技卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `TechCard` 预制，研究信息与详情区由脚本填充 |
| HUD-014 | 建筑卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `BuildingCard` 预制，字段布局可直接在场景中调整 |
| HUD-015 | 舰队路线卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `RouteCard` 预制，路线信息与状态区可视化维护 |
| HUD-016 | 帝国/星系摘要块仍由脚本拼装文本块 | RESOLVED | 已拆成 `SummaryCard` 预制，用于帝国总览、星系概览和队列摘要 |
| HUD-017 | 舰队成员列表仍由脚本拼装文本块 | RESOLVED | 已拆成 `FleetShipCard` 预制，舰船条目可直接在场景里调整样式 |
| HUD-018 | 在建项目卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `QueueItemCard` 预制，用于生产/建造队列条目 |
| HUD-019 | 事件/消息/战斗报告卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `FeedCard` 预制，用于时间线类信息展示 |
| HUD-020 | 外交关系卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `DiplomacyFactionCard` 预制，用于势力关系展示 |
| HUD-021 | 殖民方案卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `ColonizationOptionCard` 预制，用于殖民模式展示 |
| HUD-022 | 外交提案卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `ProposalCard` 预制，用于待处理提案展示 |
| HUD-023 | 可见通信/外交记忆/最新回应仍由脚本拼装文本块 | RESOLVED | 已统一切到 `FeedCard` 预制，脚本只填标题、摘要、正文与附注 |
| HUD-024 | 关系趋势卡仍由脚本拼装文本块 | RESOLVED | 已拆成 `TrendCard` 预制，用于外交关系趋势展示 |
| HUD-025 | 关系查询 API / 提案评估 API 结果仍由脚本拼装文本块 | RESOLVED | 已拆成 `ApiReportCard` 预制，摘要与明细分离展示 |
| HUD-026 | 顾问战略态势摘要仍由脚本拼装文本块 | RESOLVED | 已拆成 `PostureCard` 预制，用于顾问态势展示 |
| HUD-027 | 目标/胜利/顾问/殖民/舰队等状态摘要仍由脚本拼装文本块 | RESOLVED | 已拆成 `StatusCard` 预制，用于统一状态类摘要展示 |
| HUD-028 | HUD 剩余空状态与外交意图提示仍由通用文本卡直接拼装 | RESOLVED | 已统一切到 `StatusCard`，保留 `_make_info_card` 仅作通用兜底工具 |
| HUD-029 | HUD 在不同桌面宽度下仍依赖固定尺寸，存在挤压风险 | RESOLVED | 已增加响应式布局更新，动态调整右侧抽屉宽度、顶部间距与底部导航按钮宽度 |

## 验证要求

- 每完成一项修复后，用 Godot CLI 运行：

```powershell
& "E:\applications\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe" --headless --path "d:\2Projects\26.03.11 starcat\starcat" --quit
```

- 结果必须无脚本解析错误、无场景实例化错误
