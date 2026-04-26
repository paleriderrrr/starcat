# 喵星领主 (MeowStellar) - AI原生策略游戏开发规范

## 1. 项目概述

### 1.1 项目名称与定位

**项目名称**: 喵星领主 (MeowStellar)
**项目类型**: AI原生4X策略游戏 / 网页游戏 (WebGL)
**核心概念**: 玩家扮演喵星文明的"领航员"，与其他由LLM驱动的独立猫咪文明在程序生成的星系中竞争与合作。游戏强调"涌现式叙事"，每一次外交和战争都有独特的AI生成理由。

### 1.2 技术栈

| 层级 | 推荐技术 | 说明 |
|------|---------|------|
| 渲染引擎 | Godot 4.6 | 当前客户端与场景运行时 |
| 核心逻辑 | GDScript | 游戏规则、状态与服务层 |
| UI框架 | Godot Control | 客户端界面与交互 |
| AI集成 | 可选 LLM Provider | 本地规则优先，联网调用可选 |
| 服务形态 | Godot 内建服务 | 分析、决策、外交与叙事能力内嵌 |

### 1.3 核心设计理念

- **AI原生**: 每一个势力领袖均由大语言模型驱动，具备独立的思维推理能力、个性化的决策风格以及动态演化的外交人格
- **涌现叙事**: 游戏进程中产生的内容非预设剧情，而是AI基于游戏状态和人格特质自主生成的独特故事
- **真实政治模拟**: AI领袖之间能够进行私密通讯、组建同盟、进行战略协调与背叛，形成如同现实国际关系般的复杂博弈网络

---

## 2. 系统架构设计

### 2.1 双脑架构 (The Dual-Brain System)

#### 快思考层 (Rust/Wasm)
- 基于效用函数(Utility Functions)的决策树
- 处理移动、资源采集、战斗计算
- 速度快，确定性高
- 毫秒级响应

#### 慢思考层 (LLM/Python)
- 处理外交辞令、重大战略转型
- 宣战理由生成、性格演变
- 异步运行，不阻塞渲染帧

### 2.2 分层记忆系统 (Hierarchical Memory)

#### 短期记忆
- 当前回合的星系状态(JSON格式)
- 容量: 最近20个交互回合
- 压缩策略: 超出容量时压缩为摘要

#### 长期记忆 (向量数据库)
- 关键历史事件存储
- 语义检索相关性最高的上下文
- 记忆节点结构:
  - 记忆ID (全局唯一)
  - 时间戳 (回合数)
  - 关联势力
  - 事件类型
  - 事件内容
  - 情感冲击值 (-1.0 到 +1.0)
  - 衰减系数 (默认0.98)

### 2.3 共享协议层

使用强类型JSON Schema定义所有数据结构:
- Rust编译为Wasm时暴露内存指针给JS读取
- 减少序列化开销
- 三层数据同步: Rust(状态) ↔ React(渲染) ↔ Python(AI)

---

## 3. 视觉与UI设计规范

### 3.1 视觉风格定位

**主题**: 喵星科幻卡通风格 (Feline Sci-Fi Cartoon)
- 融合可爱猫咪形象与未来科幻元素
- 圆润的卡通造型
- 所有势力领袖以可爱的猫咪形象呈现

### 3.2 配色方案

| 用途 | 颜色代码 | 说明 |
|------|---------|------|
| 背景 | #0B0C15 | 深空黑 |
| 主色 | #7F5AF0 | 霓虹紫 - 科技感 |
| 强调 | #2CB67D | 全息绿 - 资源/友善 |
| 警示 | #EF4565 | 激光红 - 敌对 |
| 食物资源 | #FF6B6B | 珊瑚红 |
| 矿产资源 | #4ECDC4 | 青绿色 |
| 工业资源 | #FFE66D | 明黄色 |
| 能源资源 | #95E1D3 | 薄荷绿 |

### 3.3 界面布局

```
+------------------------------------------------------------------+
|  [全局信息栏] 时间/回合 | 食物/矿产/工业/能源 | 科研进度 | 舰队实力 |
+------------------------------------------------------------------+
|        |                                      |                  |
| 帝国    |         3D星际版图                   |  上下文行动面板   |
| 状态    |      (Three.js Canvas)              |  (选中对象详情)   |
| 面板    |                                      |                  |
|        |                                      |                  |
+--------+                                      +------------------+
|  [舰队指挥栏] 舰队列表 | 舰队状态 | 快速选择                          |
+------------------------------------------------------------------+
|  [通讯中心] AI发送的消息/外交信函                                  |
+------------------------------------------------------------------+
```

### 3.4 组件规范

#### 星系节点
- 圆形呈现，直径根据重要性动态调整
- 颜色: 势力主色调 (无归属为灰色)
- 边缘光晕: 战斗/建设活动指示
- 悬停: 弹出简要信息卡片

#### 航道连线
- 实线: 已探索永久航道
- 虚线: 推测航道
- 高亮实线: 舰队移动中

#### 资源面板
- 卡片形式并排显示
- 包含: 图标、名称、当前储备、净产出
- 颜色编码: 绿色(增长)/红色(减少)

---

## 4. AI智能体底层架构

### 4.1 感知输入系统

#### 游戏状态结构化模板

**全局态势层**
- 当前回合数 (Turn)
- 所属时代 (先驱/扩张/纷争/统一/飞升)
- 综合国力雷达图 (军事/经济/科技/外交 0-100)
- 当前战略重心
- 近期重大事件摘要 (不超过3件)

**资源状态层**
- 食物: 当前值 (净产出/周期)
- 矿产: 当前值 (净产出/周期)
- 工业: 当前值 (净产出/周期)
- 能源: 当前值 (净产出/周期)
- 研究进度百分比

**威胁感知层**
- 直接接壤的敌对势力及舰队实力
- 已知潜在威胁
- 情报来源不明的异常活动
- 近期遭受攻击记录

**外交情报层**
- 所有已知势力及关系等级 (九级)
- 近期外交动作记录
- 当前生效条约
- 正在洽谈中的合作项目

### 4.2 性格矩阵

#### 五维性格特质

| 维度 | 说明 | 范围 |
|------|------|------|
| 好战程度 (Aggression) | 偏好军事解决 | 0-10 |
| 多疑程度 (Paranoia) | 对他方意图的怀疑度 | 0-10 |
| 贪婪程度 (Greed) | 对领土/资源的渴望 | 0-10 |
| 忠诚程度 (Loyalty) | 遵守承诺的程度 | 0-10 |
| 理性程度 (Rationality) | 冲动vs理性的平衡 | 0-10 |

#### 文明类型与特质倾向

| 文明类型 | 好战 | 贪婪 | 忠诚 | 理性 | 特殊倾向 |
|---------|------|------|------|------|---------|
| 军事帝国 | 8 | 6 | 5 | 7 | 舰船产能+20% |
| 商业联邦 | 3 | 7 | 6 | 8 | 贸易收益+25% |
| 科技联盟 | 4 | 5 | 6 | 9 | 研究速度+20% |
| 和平主义 | 1 | 4 | 9 | 7 | 舒适度+15% |
| 游牧联盟 | 7 | 6 | 4 | 6 | 移动速度+20% |
| 封建王国 | 5 | 6 | 8 | 6 | 附庸忠诚+20% |
| 虚空观察者 | 2 | 3 | 5 | 10 | 视野+25% |

#### 特质数值计算公式
```
实际特质值 = 文明倾向值 + 随机扰动(-0.1到+0.1) + 个体差异修正
```

### 4.3 效用函数

#### 基础效用公式
```
U(行动) = 基础收益 × 贪婪系数 + 战略价值 × 理性系数 - 风险成本 × (1 + 多疑系数) + 性格倾向修正
```

#### 行动类型效用模板

**宣战行动**
```
U(宣战) = 预期收益 × 好战系数 - 战争成本 × 理性系数 - 敌方实力 × (1 + 多疑系数) + 领土欲望 × 贪婪系数
```

**结盟行动**
```
U(结盟) = 合作收益 × 贪婪系数 + 安全保障 × (1 - 多疑系数) - 背叛风险 × 多疑系数 + 忠诚系数
```

**贸易协议**
```
U(贸易) = 利润 × 贪婪系数 + 关系改善 × (1 - 多疑系数) + 稳定收益 × 忠诚系数
```

### 4.4 提示词模板

#### 基础系统提示词
```
你的身份
你是{领袖名称}，{文明名称}的最高执政官。你的文明位于{星系位置}，拥有{星系数量}个星系和{人口规模}人口。

你的性格特质：
- 好战程度：{aggression}/10
- 多疑程度：{paranoia}/10
- 贪婪程度：{greed}/10
- 忠诚程度：{loyalty}/10
- 理性程度：{rationality}/10
你当前的战略目标是：{grand_strategy}。

当前局势
回合：{turn_number}，{era_name}
资源状况
食物：{food_stock}（{food_net}/周期）
矿产：{mineral_stock}（{mineral_net}/周期）
工业：{industry_stock}（{industry_net}/周期）
能源：{energy_stock}（{energy_net}/周期）
研究进度：{research_progress}%

威胁评估
{static_threats}

外交关系
{diplomatic_summary}

内部状态
{internal_situation}

近期记忆
{memory_context}

决策要求
基于以上信息，你需要进行战略思考并做出决策。请遵循以下思维链条：
1. 形势分析：评估当前的优势、劣势、机遇与威胁
2. 目标审视：对照你的战略目标，判断是否需要调整优先级
3. 选项评估：考虑可行的行动方案，评估各方案的收益与风险
4. 利益计算：结合你的性格特质，计算各选项的效用值
5. 最终决策：选择效用最高的行动方案

输出格式
请以JSON格式输出你的决策...
```

---

## 5. 外交与多智能体系统

### 5.1 跨星系通讯协议

#### 消息结构参数

**target_type (目标类型)**
- SINGLE: 点对点通讯
- GROUP: 群组通讯
- BROADCAST: 广播通讯

**visibility_level (可见性等级)**
- PUBLIC: 公开可见
- SECRET: 高度保密
- ENCRYPTED: 加密通讯

### 5.2 动态信任机制

#### 五维认知矩阵

| 维度 | 范围 | 说明 |
|------|------|------|
| 信任 | -100 to +100 | 遵守承诺程度 |
| 利用价值 | -100 to +100 | 战略价值评估 |
| 忌惮 | -100 to +100 | 军事威胁评估 |
| 好感 | -100 to +100 | 情感倾向 |
| 记忆影响 | 动态 | 时间加成项 |

#### 关系等级划分

| 总评范围 | 等级 |
|---------|------|
| ≥80 | 至高同盟 |
| 60-79 | 亲密盟友 |
| 20-59 | 正常外交 |
| -19-19 | 冷峻中立 |
| -20-59 | 关系紧张 |
| -60-79 | 深仇大恨 |
| <-80 | 血仇不共戴天 |

### 5.3 外交操作接口

#### 基础外交动作
- 建交 (ESTABLISH_RELATIONS)
- 断交 (SEVER_RELATIONS)
- 宣战 (DECLARE_WAR)
- 缔结条约 (TREATY)
- 附庸 (VASSALAGE)
- 朝贡 (TRIBUTE)
- 和平条约 (PEACE_TREATY)
- 索赔 (DEMAND_REPARATIONS)

---

## 6. 4X游戏玩法系统

### 6.1 星系拓扑结构

#### 节点数据结构
```typescript
interface StarSystem {
  id: string;
  name: string;
  position: { x: number; y: number };
  type: StarSystemType; // 单星/双星/星云/电磁风暴
  resources: ResourceBundle;
  buildingSlots: number;
  ownerId: string | null;
  buildings: Building[];
  fleet: Fleet | null;
}
```

#### 航道数据结构
```typescript
interface Hyperlane {
  id: string;
  startSystemId: string;
  endSystemId: string;
  type: 'LANE' | 'WORMHOLE';
  traversalCost: number; // 回合数
  bandwidth: number;
}
```

### 6.2 建筑系统

#### 建筑分类

| 类别 | 建筑 | 效果 |
|------|------|------|
| 居住 | 居住站/都市/同步轨道城市 | 住房++/+++/++++ |
| 食物 | 水培农场/合成食物工厂/人造生物圈 | 食物+/+++/+++- |
| 能源 | 聚变反应堆/暗物质反应堆/零点反应堆 | 能量+/++/+++ |
| 矿产 | 自动采矿站/深层采矿站/轨道采掘站 | 矿产+/++/++++ |
| 工业 | 集成工厂/纳米工厂 | 工业+/++ |
| 船坞 | 太空船坞/太空港湾 | 舰船制造 |
| 研究 | 科研实验室/高级研究中心/量子计算中心 | 研究 5/12/20 |

### 6.3 经济系统

#### 资源循环

**食物循环**
- 人口消耗: 1单位/人口/回合
- 正产出: 人口增长
- 负产出: 叛乱风险

**矿产循环**
- 建设消耗
- 舰船制造消耗
- 需求随规模增长

**工业循环**
- 高级建筑/舰船制造
- 消耗矿产和能源

**能源循环**
- 建筑维护成本
- 舰队维护成本
- 负产出: 50%产能惩罚

### 6.4 舰船系统

#### 舰船类型

| 类型 | 特点 | 克制关系 |
|------|------|---------|
| 护卫舰 | 高闪避/低血量/造价低 | 闪避战列舰，被驱逐舰克制 |
| 驱逐舰 | 高追踪/反护卫 | 对护卫舰+50%伤害 |
| 巡洋舰 | 多功能/可搭载舰载机 | 对驱逐舰+50%伤害 |
| 战列舰 | 超远程/高装甲/低闪避 | 对巡洋舰+50%伤害 |

#### 克制机制
- 伤害乘数: 1.5倍
- 战列舰被护卫舰克制 (1.5倍)

### 6.5 战争系统

#### 宣战方式
1. 单方面宣战 (声誉损失)
2. 最后通牒 (被拒绝后自动战争)
3. 反侵略反击

#### 战术选择
- 焦土政策: +20%攻击，摧毁建筑
- 轨道轰炸: +50%对防御增伤
- 狼群突袭: 护卫舰+25%闪避
- 跃迁突击: 首轮+100%伤害
- 战列线: 巡洋舰/战列舰+15%伤害

---

## 7. API接口规范

### 7.1 外交系统API

#### execute_diplomatic_action
```typescript
interface DiplomaticActionRequest {
  source_faction_id: string;
  target_faction_id: string;
  action_type: 'DECLARE_WAR' | 'PROPOSE_ALLIANCE' | 'OFFER_VASSALAGE' | 
               'PROPOSE_TRADE' | 'DEMAND_TRIBUTE' | 'PROPOSE_NON_AGGRESSION';
  payload?: {
    offer: ResourceBundle | TerritoryBundle | TreatyBundle;
    request: ResourceBundle | TerritoryBundle | TreatyBundle;
  };
}
```

#### query_relationship_status
```typescript
interface RelationshipResponse {
  trust_score: number;      // -100 to +100
  utility_score: number;     // -100 to +100
  fear_score: number;       // -100 to +100
  affinity_score: number;    // -100 to +100
  memory_impact: number;    // 动态
  relationship_level: string; // HOSTILE/NEUTRAL/ALLIED etc.
  recent_events: EventSummary[];
}
```

### 7.2 战争系统API

#### fleet_strategic_move
```typescript
interface FleetMoveRequest {
  fleet_id: string;
  destination_system_id: string;
  movement_mode: 'NORMAL' | 'WARP' | 'STEALTH';
}

interface FleetMoveResponse {
  status: 'SUCCESS' | 'INSUFFICIENT_ENERGY' | 'BLOCKED';
  estimated_arrival_turns: number;
  path_segments: string[];
  warning_messages?: string[];
}
```

#### initiate_combat_protocol
```typescript
interface CombatRequest {
  fleet_id: string;
  target_type: 'FLEET' | 'PLANET' | 'STATION';
  target_id: string;
  engagement_rules: 'ALL_OUT' | 'HIT_AND_RUN' | 'DEFENSIVE';
  formation: 'WEDGE' | 'LINE' | 'SPHERE';
}

interface CombatReport {
  victory: boolean;
  casualties: UnitLosses;
  kills: UnitKills;
  remaining_power: number;
  tactical_notes: string[];
}
```

### 7.3 经济系统API

#### query_resource_status
```typescript
interface ResourceStatusResponse {
  food: { stock: number; net: number; };
  minerals: { stock: number; net: number; };
  industry: { stock: number; net: number; };
  energy: { stock: number; net: number; balance_warning: boolean; };
}
```

#### manage_construction_queue
```typescript
interface ConstructionRequest {
  system_id: string;
  action: 'ADD' | 'CANCEL' | 'BOOST';
  blueprint_id: string;
  priority: 'HIGH' | 'NORMAL' | 'LOW';
}

interface ConstructionResponse {
  status: 'SUCCESS' | 'INSUFFICIENT_RESOURCES' | 'NO_SLOTS';
  queue_updated: ConstructionItem[];
  estimated_completion_turn: number;
}
```

### 7.4 导演系统API

#### query_world_state
```typescript
interface WorldStateRequest {
  query_filter: string; // SQL-like filter
  metrics: string[];
}

interface WorldStateResponse {
  matching_entities: Entity[];
  statistics: WorldStatistics;
  balance_assessment: 'BALANCED' | 'SLIGHTLY_UNBALANCED' | 'CRITICAL';
}
```

#### trigger_narrative_event
```typescript
interface EventRequest {
  event_template_id: string;
  target_location: string;
  affected_factions: string[];
  narrative_override?: string;
  outcome_modifiers?: Record<string, number>;
}
```

---

## 8. 终局胜利系统

### 8.1 征服胜利 (霸权征服)

**条件**:
- 占领所有敌对势力首都星系
- 或控制全宇宙65%以上可居住星系

**效果**:
- 专属过场动画
- "至高领主"称号
- 剩余势力变为附庸

### 8.2 外交胜利 (和平宪章)

**条件**:
- 建立泛星际联合国并成为议长
- 推动和平统一宪章提案并获得2/3以上支持

**效果**:
- 战争迷雾解除
- 所有关系变为友好/同盟
- "和平缔造者"称号

### 8.3 科技胜利 (奇观飞升)

**条件**:
完成"文明飞升计划"三阶段:
1. 基座铺设 (30回合)
2. 核心充能
3. 最终启动 (15回合保护期)

**效果**:
- 文明升华消失于现世
- "超越者"称号

---

## 8.1 科技研究系统

### 8.1.1 科技分类

科技研究分为两类：

**解锁型科技 (UNLOCK)**
- 解锁高级建筑（太空船坞、贸易空间站、科研实验室等）
- 解锁高级舰船（驱逐舰、巡洋舰、战列舰）
- 解锁特殊能力

**加成型科技 (BOOSTER)**
- 资源生产加成（食物、矿产、工业、能源）
- 舰船战斗加成（伤害、防御、速度）
- 探索范围加成
- 贸易收益加成
- 研究速度加成

### 8.1.2 科技树结构

| 类别 | Tier 1 | Tier 2 | Tier 3 | Tier 4 | Tier 5 |
|------|--------|--------|--------|--------|--------|
| 军事 | 基础武器/船坞 | 进阶推进/驱逐舰 | 巡洋舰/军事学说 | 战列舰/高级装甲 | - |
| 经济 | 贸易网络/基础采矿 | 深层采矿/贸易协定 | 纳米工厂/经济繁荣 | - | - |
| 科技 | 科研实验室/研究加速 | 高级中心/量子计算 | 超级计算机 | - | - |
| 扩张 | 居住站/食物合成 | 轨道城市/生物圈 | 能源网格/探索学说 | 暗物质反应堆 | 零点能源 |

### 8.1.3 研究机制

- **研究消耗**: 工业点数
- **研究时间**: 根据科技等级 2-10 回合
- **研究队列**: 初始1个队列，可通过建筑扩展
- **取消机制**: 中途取消返还50%资源
- **前置依赖**: 高级科技需要前置科技解锁

### 8.1.4 科技状态

| 状态 | 说明 |
|------|------|
| LOCKED | 未解锁，需要前置科技 |
| AVAILABLE | 可研究，前置条件已满足 |
| RESEARCHING | 正在研究中 |
| RESEARCHED | 已完成研究 |

---

## 9. 开发里程碑

### 第一阶段: 创世引擎 (Engine & Environment)
- [ ] Rust ECS架构初始化
- [ ] 星系程序化生成
- [ ] React + Three.js框架
- [ ] Wasm桥接实现

### 第二阶段: 4X游戏循环 (Gameplay Loop)
- [ ] 经济系统 (Rust)
- [ ] 移动与战斗逻辑
- [ ] 回合状态机

### 第三阶段: 植入灵魂 (AI Integration)
- [ ] Prompt Engineering
- [ ] Godot 内建服务与可选 LLM Provider 完善
- [ ] 向量数据库集成
- [ ] 接口对接

### 第四阶段: 社会与战争 (Diplomacy & Conflict)
- [ ] AI互信机制
- [ ] 导演系统
- [ ] 胜利条件判定

### 第五阶段: UI交互与打磨 (Polish & UX)
- [ ] 组件美化
- [ ] 粒子特效
- [ ] 性能优化

---

## 10. 验收标准

### 性能测试
- [ ] WebAssembly 3秒内加载
- [ ] 500星系时FPS≥60
- [ ] 回合处理<100ms

### AI测试
- [ ] 情感一致性 (负面交互→愤怒值上升)
- [ ] JSON错误率<1%
- [ ] 记忆检索准确性

### 游戏性测试
- [ ] 完整开局→胜利流程
- [ ] 数值变化UI反馈
- [ ] 无致命崩溃

---

*文档版本: 1.0*
*最后更新: 2026-03-11*
*作者: Matrix Agent*
