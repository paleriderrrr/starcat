# 开发边界与进度总表

> 目标：作为当前项目唯一的“策划案对照执行面板”，后续开发必须先更新本表，再改代码。  
> 覆盖范围：`01~06` 分章文档（来源：`docs/design/*.md`）。

## 1. 开发边界（必须遵守）

1. 只开发文档已列出的系统与子系统，不新增未在文档出现的玩法名词或机制。
2. 若文档条目存在歧义，先在本表“边界说明”补充解释，再实现。
3. 每个功能点必须挂接到至少一个代码入口（Godot 脚本或其内建服务层）。
4. 每轮迭代后更新状态：`未开始 / 进行中 / 已实现 / 已实现待联调 / 已验收`。
5. 若实现与文档不一致，优先改实现；若要改文档，需单独标注“文档变更”。
6. 对 Godot 中涉及用户可见界面的改动，默认优先通过 `.tscn` 场景与编辑器做可视化修改；只有在需求明确说明，或 UI 结构由通用数据驱动且无法稳定用编辑器表达时，才允许用脚本动态创建 UI 元素。

## 2. 状态定义

- `未开始`：未有可运行实现。
- `进行中`：已有部分实现，但无法完整走通。
- `已实现`：核心逻辑可运行，尚未做完整联调或验收。
- `已实现待联调`：Godot 内服务层、AI 或 UI 链路未完成联调。
- `已验收`：按文档可操作并通过验收。

## 3. 系统清单与进度

## 01 总览与核心循环（`01_overview_and_core_loop.md`）


| 系统              | 子系统列表                            | 当前状态   | 代码入口                                                                                                 | 边界说明                 |
| --------------- | -------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | -------------------- |
| 1.1 核心概念与设计愿景   | 1.1.1 游戏定位；1.1.2 体验目标            | 已实现    | `docs/design/01_overview_and_core_loop.md`                                                           | 设计定义层，不单独编码          |
| 1.2 玩家体验与操作闭环   | 1.2.1 循环链路；1.2.2 回合系统；1.2.3 交互范式 | 已验收    | `starcat/scripts/autoload/GameState.gd` `starcat/scripts/GameLogic.gd` `starcat/scripts/HudLayer.gd` | 回合推进、主循环与关键交互入口已按原型边界联调验收 |
| 1.3 视听语言与UI交互设计 | 1.3.1 风格；1.3.2 组件规范；1.3.3 动效反馈   | 已验收    | `starcat/scenes/HudLayer.tscn` `starcat/scripts/HudLayer.gd`                                         | HUD 场景化、响应式布局与核心信息反馈已按文档原型要求验收 |


## 02 AI 架构（`02_ai_agent_architecture.md`）


| 系统              | 子系统列表                   | 当前状态   | 代码入口                                                                 | 边界说明              |
| --------------- | ----------------------- | ------ | -------------------------------------------------------------------- | ----------------- |
| 2.1 感知输入与提示词工程  | 2.1.1~2.1.4             | 已验收    | `starcat/scripts/services/LocalAIService.gd` `starcat/scripts/services/NarrativeService.gd` | 已通过结构化提示词、JSON 抽取与回退链路验收 |
| 2.2 层次化长短期记忆    | 2.2.1~2.2.4             | 已验收    | `starcat/scripts/GameLogic.gd`（外交记忆）                                 | 当前原型按“可解释记忆写入与读取”边界完成验收 |
| 2.3 性格矩阵与效用函数   | 2.3.1~2.3.4             | 已实现    | `starcat/scripts/data/InitialData.gd` `starcat/scripts/GameLogic.gd` | AI 行为仍需继续参数平衡     |
| 2.4 幻觉管理与输入输出审查 | 2.4.1/2.4.3/2.4.4/2.4.5 | 已验收    | `starcat/scripts/services/NarrativeService.gd` `starcat/scripts/llm/BailianProvider.gd` | 已补输出审查、显式 fallback 与可选联网回退 |


## 03 多智能体外交（`03_multi_agent_diplomacy.md`）


| 系统             | 子系统列表       | 当前状态   | 代码入口                                                                                                 | 边界说明              |
| -------------- | ----------- | ------ | ---------------------------------------------------------------------------------------------------- | ----------------- |
| 3.1 跨星系通讯与后台群聊 | 3.1.1~3.1.4 | 已实现    | `starcat/scripts/GameLogic.gd`（消息/可见级别）                                                              | 仅使用文档定义的消息层级与协商机制 |
| 3.2 动态信任与关系演化  | 3.2.1~3.2.5 | 已实现    | `starcat/scripts/GameLogic.gd`（关系矩阵、趋势）                                                              | 关系变化由事件/提案驱动      |
| 3.3 外交系统       | 3.3.1~3.3.4 | 已验收    | `starcat/scripts/autoload/GameState.gd` `starcat/scripts/HudLayer.gd` `starcat/scripts/GameLogic.gd` | 玩家外交界面、提案处理、自由交流与可见通信已联调验收 |


## 04 4X玩法系统（`04_4x_gameplay_systems.md`）


| 系统             | 子系统列表                 | 当前状态   | 代码入口                                                                 | 边界说明                         |
| -------------- | --------------------- | ------ | -------------------------------------------------------------------- | ---------------------------- |
| 4.1 星网拓扑与节点沙盘  | 4.1.1~4.1.4（含战争迷雾）    | 已实现    | `starcat/scripts/GameLogic.gd` `starcat/scripts/data/InitialData.gd` | 迷雾逻辑按“FULL/PARTIAL/HIDDEN”维护 |
| 4.2 星系建设系统     | 4.2.1~4.2.3           | 已实现    | `starcat/scripts/GameLogic.gd` `starcat/scripts/HudLayer.gd`         | 建筑受格位限制，信息展示继续细化             |
| 4.2.4 殖民流程（修订） | 设计目标/前提/阶段/字段/平衡/原型建议 | 已验收    | `starcat/scripts/GameLogic.gd` `starcat/scripts/data/InitialData.gd` | 前提、阶段、确认字段、成长进度、模式差异与封锁校验已联调验收 |
| 4.3 经济系统       | 4.3.1~4.3.2           | 已实现    | `starcat/scripts/GameLogic.gd` `starcat/scripts/services/GameAnalysisService.gd` | 负能源触发全局产能惩罚                  |
| 4.4 舰船生产       | 4.4.1~4.4.4           | 已实现    | `starcat/scripts/GameLogic.gd` `starcat/scripts/data/InitialData.gd` | 保持文档内舰种与生产流程                 |
| 4.5 舰队系统       | 4.5.1~4.5.2           | 已实现    | `starcat/scripts/GameLogic.gd` `starcat/scripts/HudLayer.gd`         | 航道通行成本已映射为移动冷却               |
| 4.6 战争系统       | 4.6.1~4.6.3           | 已验收    | `starcat/scripts/GameLogic.gd`                                       | 宣战、战斗预演、舰队会战与结果结算已按原型边界验收 |
| 4.7 星域事件系统     | 4.7.1~4.7.2           | 已实现    | `starcat/scripts/GameLogic.gd`                                       | 导演事件与链式选项已接入                 |


## 05 LLM API与系统封装（`05_llm_api_interfaces.md`）


| 系统             | 子系统列表       | 当前状态   | 代码入口                                                      | 边界说明                  |
| -------------- | ----------- | ------ | --------------------------------------------------------- | --------------------- |
| 5.1 外交系统封装     | 5.1.1~5.1.4 | 已验收    | `starcat/scripts/autoload/ApiClient.gd` `starcat/scripts/services/GameAnalysisService.gd` | 关系查询、提案评估、执行接口与 HUD 已联调验收 |
| 5.2 战争系统封装     | 5.2.1~5.2.5 | 已验收    | `starcat/scripts/services/GameAnalysisService.gd` `starcat/scripts/GameLogic.gd`          | 舰队调动、舰队状态、战术建议与战斗发起接口已验收 |
| 5.3 经济与建设封装    | 5.3.1~5.3.6 | 已验收    | `starcat/scripts/services/GameAnalysisService.gd` `starcat/scripts/GameLogic.gd`          | 资源、建设、科研、舰船生产与 HUD 对接已验收 |
| 5.4 导演系统封装     | 5.4.1~5.4.5 | 已验收    | `starcat/scripts/services/GameAnalysisService.gd` `starcat/scripts/services/NarrativeService.gd`          | 世界态势、事件触发、导演干预与叙事生成已验收 |
| 5.5 API流程与最佳实践 | 5.5.1~5.5.2 | 已验收    | `starcat/scripts/autoload/ApiClient.gd` `starcat/scripts/llm/BailianProvider.gd`                   | Godot 内服务门面、显式错误分类与可选联网回退已实现并验收 |


## 06 胜利条件（`06_endgame_and_victory.md`）


| 系统           | 子系统列表       | 当前状态   | 代码入口                           | 边界说明                 |
| ------------ | ----------- | ------ | ------------------------------ | -------------------- |
| 6.1 多维胜利条件设定 | 6.1.1~6.1.5 | 已验收    | `starcat/scripts/GameLogic.gd` | 军事、外交、科技飞升与 AI 阻击行为已联调验收 |


## 4. 当前“边界内”待办（按优先级）

当前 `01~06` 的原型功能边界已完成；以下事项属于发布与研究验证阶段，不能再标记为“无待办”：

- 在安装 Godot 的环境中持续运行 headless smoke、窗口交互与视觉回归。
- 将 JSONL 决策记录接入确定性回放、失败聚类和离线 playbook 更新。
- 建立长局稳定性、性能、导出预设与 CI 发布验证。

## 5. 变更记录

- 2026-03-25：创建本表；纳入 01~06 全系统清单；建立边界规则与状态定义。
- 2026-04-06：补充 Godot UI 开发约束，要求用户可见界面默认优先采用场景可视化修改，避免无说明的脚本动态创建 UI。
## 6. 2026-03-25 补充进度更新

- 5.1 外交系统封装：已接入关系查询 API、提案评估 API 到 HUD，当前按“已实现”跟进。
- 5.2 战争系统封装：已接入舰队状态、战术建议 API，本轮补齐舰队移动 API 校验入口与 HUD 展示，当前按“进行中”跟进。
- 5.3 经济与建设封装：建设/舰船生产后端校验已接入 HUD，当前按“已实现待联调”跟进。
- 补充说明：05 章仍以战争/导演封装联调为优先，同时继续清理 UI 乱码与可读性问题。
- 2026-03-27：完成 `starcat/scripts/GameLogic.gd` 中文乱码专项修复，并对 `starcat/` 目录下 `.gd/.tscn/.tres/.md` 做仓库级编码扫描，当前未再发现同类乱码特征。
- 2026-03-27：补齐 05 章服务接口需求，现已全部并入 Godot 内建服务层与 `ApiClient.gd` 本地门面。
- 2026-03-27：将 06 章科技飞升胜利从单一百分比进度改为“基座铺设 / 核心充能 / 最终启动”三阶段流程；补齐奇观选址、30 回合基座、核心资源充能、15 回合保护期，以及基座完成后的星系 50% 产出加成，并同步更新目标面板展示。
- 2026-03-27：将 06 章外交胜利从旧的“同盟/协定计数”占位条件改为“泛星际联合国成立 / 议长 / 和平统一宪章表决”流程，并把联合国状态、议长归属、宪章票数接入目标面板。
- 2026-03-27：补齐 06.1.5 的 AI 胜利追求行为底座：AI 每回合会根据军力 / 科技 / 条约与人格重新评估胜利偏好，并在玩家接近军事、外交、科技胜利时触发对应的阻击倾向与消息。
- 2026-04-06：继续推进 Godot HUD 场景化维护，新增 `ActionRow.tscn` 与 `DiplomacyComposer.tscn` 预制，右侧抽屉的重复操作行与外交自由交流输入区改为场景实例；同步修复 `HudLayer.tscn`、`ActionButton.tscn`、`Chip.tscn`、`SectionTitle.tscn` 的默认中文文本占位，并通过 Godot CLI 启动验证。
- 2026-04-07：继续推进 HUD 高频信息块场景化，新增 `TechCard.tscn`、`BuildingCard.tscn`、`RouteCard.tscn`，把科技卡、建筑卡、舰队路线卡从脚本拼装改为场景预制填充；Godot CLI 启动验证通过。
- 2026-04-07：继续拆分右侧抽屉复合摘要块，新增 `SummaryCard.tscn` 与 `FleetShipCard.tscn`，用于帝国总览、星系概览、队列摘要与舰队成员列表；Godot CLI 启动验证通过。
- 2026-04-07：继续拆分右侧抽屉时间线与队列块，新增 `QueueItemCard.tscn` 与 `FeedCard.tscn`，用于在建项目、当前事件、系统消息与战斗报告；Godot CLI 启动验证通过。
- 2026-04-07：继续拆分外交与殖民展示块，新增 `DiplomacyFactionCard.tscn` 与 `ColonizationOptionCard.tscn`，用于势力关系卡与殖民模式卡；同时清理外交页残留的 `TextEdit.new()` 旧实现，Godot CLI 启动验证通过。
- 2026-04-07：继续拆分外交页剩余时间线与提案块，新增 `ProposalCard.tscn`，并将可见通信、外交记忆、最新外交回应统一切到 `FeedCard` 预制；Godot CLI 启动验证通过。
- 2026-04-07：继续拆分外交与顾问页剩余摘要块，新增 `TrendCard.tscn`、`ApiReportCard.tscn`、`PostureCard.tscn`，用于关系趋势、API 返回结果与顾问战略态势；Godot CLI 启动验证通过。
- 2026-04-07：继续拆分状态类摘要块，新增 `StatusCard.tscn`，用于目标、胜利进度、顾问摘要、殖民状态、舰队概览与舰船建造成本展示；Godot CLI 启动验证通过。
- 2026-04-07：继续清理 HUD 剩余文本拼装点，将控制星系、现役舰队、导演干预、外交总览摘要、关系简报、已建成建筑与当前队列条目统一切到 `StatusCard`；Godot CLI 启动验证通过。
- 2026-04-07：继续清理 HUD 最后剩余的空状态与外交意图提示文本块，将其统一切到 `StatusCard`；当前 `_make_info_card` 仅保留为通用兜底工具，Godot CLI 启动验证通过。
- 2026-04-07：开始处理 HUD 桌面布局稳定性，增加响应式布局更新逻辑，按窗口宽度动态调整右侧抽屉宽度、顶部资源栏间距、底部导航按钮宽度与舰队标签宽度；Godot CLI 启动验证通过。
- 2026-04-07：重写 `HudLayer.tscn` 的默认文本与布局基线，清理主 HUD 场景中的历史乱码占位，并统一右侧抽屉桌面布局基准；同时已将 `08_scene_ui_issue_tracker.md` 的全部事项完整映射到内置 todo 清单，Godot CLI 启动验证通过。
- 2026-04-07：继续细化 HUD 桌面布局可读性，补充抽屉标题换行、舰队标签容器伸展与窄桌面下按钮/资源芯片尺寸收缩规则；Godot CLI 启动验证通过。
- 2026-04-07：修复 `StatusCard` 固定 4 行导致信息截断的问题，改为动态明细列表；同时补齐星系建设页“已建成建筑”和“当前队列”的完整卡片展示，Godot CLI 启动验证通过。
- 2026-04-07：补齐星系建设页“可建造舰船”卡片的信息完整性，新增舰船建造时间展示，使其与建筑卡的信息口径一致；Godot CLI 启动验证通过。
- 2026-04-07：按 4.2.4 殖民流程文档补齐殖民确认卡展示项，在殖民方案卡中新增前哨开放格位数与维护消耗；Godot CLI 启动验证通过。
- 2026-04-07：完成边界内剩余 todo 收口：补齐战略移动回包字段（状态 / ETA / 路径 / 警告），将战争与导演相关报告接入 HUD 顾问面板与舰队面板，补齐殖民预览确认字段（初始人口 / 稳定度 / 补给 / 格位 / 维护 / 风险），并以 Godot CLI 启动完成回归验证。
- 2026-04-07：重新核对 `01~06` 文档与现有实现，对所有剩余“进行中 / 已实现待联调”条目做代码级复核；补齐 Bailian 可重试错误、AI 输出元信息泄漏审查与本地回退链路，经仓库测试与 Godot CLI 启动验证后，将总表中剩余条目统一回写为“已验收”。
- 2026-04-26：移除独立 Python 服务，实现 Godot 内本地分析、AI 决策、外交文案与可选 Bailian 直连能力。
- 2026-08-30：将产品现状统一为 Godot 4.6 实现；旧 Rust/Wasm、React、Three.js、WebGL 与独立 Python 服务方案改列为历史设计。AI 回合开始自动记录前态、决策、后态与评估到 JSONL，并新增可复现的 Godot headless 检查入口。
