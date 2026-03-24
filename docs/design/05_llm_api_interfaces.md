第五篇：大模型行为调用接口（API）

## 5.1 外交系统封装

### 5.1.1 设计目标与架构

外交系统封装的目标是将AI的自然语言外交意图转化为游戏引擎可执行的精确指令。不同于玩家通过直观界面进行外交操作，AI需要通过结构化的API接口与游戏引擎交互。这种设计既保证了AI行为的规范性，又为AI提供了足够的灵活性来表达复杂的外交策略。

外交API的设计遵循以下原则：语义清晰性要求每个API的名称和参数都能被AI准确理解；结果反馈闭环要求每个API调用都返回执行结果，使AI能够根据反馈调整后续策略；错误可追溯性要求API返回具体的错误原因，便于AI进行错误恢复。

### 5.1.2 外交行动API

核心API：execute_diplomatic_action

该API是外交系统的核心入口，负责处理所有类型的外交行动。

输入参数包括：source_faction_id为发起方的势力标识符；target_faction_id为目标方的势力标识符；action_type为行动类型枚举，可选值包括DECLARE_WAR（宣战）、PROPOSE_ALLIANCE（结盟提议）、OFFER_VASSALAGE（提议附庸）、REQUEST_VASSALAGE（请求成为附庸）、PROPOSE_TRADE（贸易提议）、DEMAND_TRIBUTE（索要贡品）、PROPOSE_NON_AGGRESSION（互不侵犯条约）；payload为可选的行动载荷，包含具体的条款内容。

条款内容结构定义如下：offer字段定义发起方愿意提供的筹码，可包括resources资源列表（如minerals:1000、energy:500）、territory_ids割让的星系列表、treaties愿意缔结的条约类型列表；request字段定义发起方希望获得的回报，结构同offer。

执行逻辑流程

第一步进行合法性检查。系统验证以下前置条件：发起方与目标方是否已建交（部分行动需要）；当前是否处于停战期（宣战等行动受限）；目标方是否存在且可交互。

第二步进行AI意愿计算。如果目标是AI势力，系统调用该AI的接受度评估函数；如果目标是玩家，系统向玩家弹窗显示外交提议。

第三步进行状态变更。成功执行时，更新双方关系值、转移资源所有权、写入外交日志；失败时，返回具体错误原因。

返回结果定义如下：status字段表示执行状态，SUCCESS、REJECTED、INVALID_REQUEST或ERROR；new_relation_state表示执行后的新关系状态；reputation_change表示执行对发起方国际声誉的影响；rejection_reason如果被拒绝，显示拒绝原因。

### 5.1.3 关系查询API

API：query_relationship_status

该API用于查询两个势力之间的关系状态。

输入参数包括：faction_a_id和faction_b_id分别表示要查询的两个势力。

返回结果包括：trust_score表示信任维度得分（-100到+100）；utility_score表示利用价值维度得分；fear_score表示忌惮维度得分；好感维度得分；记忆影响总分；relationship_level表示关系等级标签（如HOSTILE、NEUTRAL、ALLIED等）；recent_events列表表示近期影响关系的事件摘要。

### 5.1.4 外交提案评估API

API：evaluate_diplomatic_proposal

该API用于评估收到的外交提案是否可接受，主要供AI评估玩家发来的提案时使用。

输入参数包括：proposal_id表示待评估的提案标识；evaluator_faction_id表示进行评估的势力。

返回结果包括：acceptance_score表示接受度评分（-100到+100）；key_concerns表示主要顾虑列表；counter_proposal如果不愿接受原提案，可选择的还价内容；recommended_action表示推荐的操作（ACCEPT、REJECT或COUNTER）。

## 5.2 战争系统封装

### 5.2.1 设计理念

战争系统封装的核心设计理念是分离战略决策与战术执行。AI负责决定“是否战争”“对谁作战”“投入多少兵力”等高层战略问题，而具体的战斗演算由游戏引擎内置的算法完成。这种设计避免了让AI处理过于细节化的战斗计算，同时保证了战斗结果的公平性和观赏性。

### 5.2.2 舰队调动API

API：fleet_strategic_move

该API用于指挥舰队在星系之间移动。

输入参数包括：fleet_id表示要调动的舰队标识；destination_system_id表示目标星系标识；movement_mode表示移动模式，可选值包括NORMAL（常规航行）、WARP（跃迁，需要跃迁科技）、STEALTH（隐蔽航行，降低被拦截概率）。

执行逻辑流程如下：首先计算移动所需的资源和时间，检查舰队是否有足够能源支持移动；然后锁定舰队状态为“移动中”，触发引擎寻路算法计算最优路径；如果路径上的航道被封锁或存在拦截风险，返回警告信息；最后舰队到达目标后触发回调，更新位置并通知相关AI。

返回结果包括：status表示执行状态；estimated_arrival_turns表示预计到达回合数；path_segments表示路径经停的星系列表；warning_messages如果有拦截风险，显示警告信息。

### 5.2.3 战斗发起API

API：initiate_combat_protocol

该API用于发起战斗或设置战斗规则。

输入参数包括：fleet_id表示发起进攻的舰队标识；target_type表示目标类型，可选值包括FLEET（敌方舰队）、PLANET（敌方星系）、STATION（敌方空间站）；target_id表示具体的目标标识；engagement_rules表示交战规则，可选值包括ALL_OUT（全力进攻，不死不休）、HIT_AND_RUN（打了就跑，利于消耗）、DEFENSIVE（仅自卫，不主动追击）；formation表示阵型，可选值包括WEDGE（楔形，突击用）、LINE（横列，远程对轰用）、SPHERE（球形，防御用）。

执行逻辑流程如下：首先验证双方是否处于战争状态，如果尚未宣战则返回错误或自动宣战（会有外交惩罚）；然后将控制权移交给战斗演算模块，该模块根据阵型和交战规则自动进行战斗；最后战斗结束后生成战斗报告。

战斗报告内容包括：victory表示是否获胜；casualties表示己方损失；kills表示敌方击杀数；remaining_power表示剩余战力百分比；tactical_notes表示战术备注，如克制效果触发情况。

### 5.2.4 战术选择算法

虽然战斗演算由引擎自动完成，但战术选择对战斗结果有重大影响。系统内置了一套战术选择算法，可以被AI调用以获得最优战术建议。

API：recommend_tactical_approach

该API根据当前态势推荐最优战术。

输入参数包括：attacker_fleet_id表示进攻方舰队；defender_fleet_id表示防御方舰队（如果有）；target_system_id表示目标星系；attack_objective表示攻击目标，可选值包括DESTROY_ENEMY（消灭敌方舰队）、OCCUPY（占领星系）、RAID（掠夺后撤退）。

返回结果包括：recommended_tactics表示推荐的战术卡；expected_outcomes表示各战术的预期结果评估；risk_assessments表示各战术的风险评估。

### 5.2.5 舰队状态查询API

API：query_fleet_status

该API用于查询舰队的当前状态。

输入参数包括：fleet_id表示要查询的舰队标识；include_units表示是否包含舰船详情（布尔值）。

返回结果包括：location表示当前所在星系；mission表示当前任务类型；strength表示当前战力评估；unit_composition表示舰船构成列表；readiness表示战备状态（FULL、DEGRADED、CRITICAL）。

## 5.3 经济与星系建设系统封装

### 5.3.1 经济API设计概述

经济系统封装的目标是让AI能够像人类玩家一样管理文明的资源流动。AI需要能够查询资源状况、调整资源配置、规划建设项目，并确保经济系统的健康运转。

### 5.3.2 资源查询API

API：query_resource_status

该API用于查询当前资源状况。

输入参数包括：faction_id表示要查询的势力；scope表示查询范围，可选值包括GLOBAL（全势力范围）、SYSTEM（特定星系）。

返回结果包括：food表示食物储备和净产出；minerals表示矿产储备和净产出；industry表示工业储备和净产出；energy表示能源储备和净产出（区分正负）；balance_warning表示是否存在负能源等需要警告的情况。

### 5.3.3 建设管理API

API：manage_construction_queue

该API用于管理建设队列。

输入参数包括：system_id表示目标星系；action表示操作类型，可选值包括ADD（添加项目）、CANCEL（取消项目）、BOOST（加速项目）；blueprint_id表示建筑蓝图标识，如mining_complex_lvl2（ lvl2采矿综合设施）；priority表示优先级，HIGH、NORMAL或LOW。

执行逻辑如下：检查资源是否足够支撑建设，检查星系是否有空余建设槽位，检查前置科技是否满足；如通过则扣除资源并启动建设倒计时；如失败则返回具体缺口信息。

返回结果包括：status表示执行状态；queue_updated表示更新后的建设队列；estimated_completion_turn表示预计完工回合；resource_shortage如果资源不足，显示具体缺口。

### 5.3.4 资源政策调整API

API：adjust_resource_policy

该API用于调整经济政策参数。

输入参数包括：scope表示调整范围，GLOBAL或指定星系ID；policy_name表示政策名称，可选值包括TAX_RATE（税率）、ENERGY_ALLOCATION（能源分配优先）、FOOD_DISTRIBUTION（食物配给）；value表示政策值，如0.15表示15%的税率；priority_focus表示自动分配时的优先领域。

执行逻辑如下：修改指定范围内的政策参数，引擎在下一个结算周期应用新参数，返回修改后的完整政策列表。

### 5.3.5 科技研发API

API：set_research_priority

该API用于设置科技研发优先级。

输入参数包括：faction_id表示进行研发的势力；tech_id表示目标科技ID；allocation表示投入的科研点数比例。

返回结果包括：current_research表示当前正在研发的科技；progress表示研发进度百分比；estimated_completion_turns表示预计完成回合；prerequisites_met表示前置科技是否满足。

### 5.3.6 舰船生产API

API：order_ship_production

该API用于下单生产舰船。

输入参数包括：system_id表示生产星系（需要有轨道船坞）；ship_type表示舰船类型，CORVETTE、DESTROYER、CRUISER或BATTLESHIP；quantity表示数量；priority表示优先级。

执行逻辑如下：检查星系是否有轨道船坞，检查资源是否足够，检查生产队列是否已满；通过则加入生产队列并开始制造。

返回结果包括：status表示执行状态；production_queue表示更新后的生产队列；estimated_completion表示预计完工时间；resource_cost表示实际消耗的资源。

## 5.4 导演系统封装

### 5.4.1 导演系统设计理念

导演系统封装服务于游戏世界的“幕后导演”——一个特殊的AI实体，负责监控游戏态势、触发事件和调整游戏节奏。不同于普通AI势力关注自身利益，导演系统关注的是整个游戏世界的动态平衡和玩家体验。

导演系统的核心功能包括：态势监控，持续跟踪各势力的实力对比和游戏进程；事件触发，在适当的时机触发随机事件或世界事件；节奏调整，当游戏过于和平或一边倒时，注入挑战以维持趣味性；叙事生成，为事件配上符合世界观的外交辞令。

### 5.4.2 全局态势查询API

API：query_world_state

该API用于查询游戏世界的整体态势。

输入参数包括：query_filter表示查询过滤条件，使用类SQL的过滤表达式；metrics表示要获取的指标列表。

查询过滤器示例：FACTIONS WHERE military_power > 10000表示所有军力超过10000的势力；SYSTEMS WHERE owner_id = NULL AND explored = true表示所有已发现但无主的星系。

返回结果包括：matching_entities表示符合条件的实体列表；statistics表示统计摘要，如平均军力、势力数量、战争频率等；balance_assessment表示实力对比评估，如UNBALANCED（BALANCED、SLIGHTLY_UNBALANCED、CRITICAL）。

### 5.4.3 事件触发API

API：trigger_narrative_event

该API用于触发特定的事件。

输入参数包括：event_template_id表示事件模板ID，如ANCIENT_RUINS_DISCOVERY（远古遗迹发现）、PIRATE_RAID（海盗袭击）、WARP_STORM（跃迁风暴）；target_location表示事件发生的星系位置；affected_factions表示受影响的势力列表；narrative_override表示可选的自定义叙事文本，替换默认的事件描述；outcome_modifiers表示结果修正系数，如science_bonus: 1.5表示科技奖励增加50%。

执行逻辑如下：在指定位置生成事件实体，向受影响势力发送事件通知，挂载相应的脚本钩子以处理后续效果。

返回结果包括：event_id表示新创建的事件ID；narrative_content表示实际使用的事件叙事文本；immediate_effects表示即时效果列表；follow_up_options表示后续选项列表（如有）。

### 5.4.4 动态难度调整API

API：inject_director_intervention

该API用于注入导演干预，改变游戏平衡或增加挑战。

输入参数包括：intervention_type表示干预类型，可选值包括SPAWN_PIRATES（生成海盗）、BOOST_AI（增强AI势力）、REDUCE_RESOURCES（减少资源产出）、TRIGGER_CRISIS（触发危机事件）；intensity表示干预强度，从0.0到1.0；target_scope表示目标范围，GLOBAL或指定势力；duration表示持续时间，以回合为单位。

返回结果包括：intervention_id表示创建的干预ID；effects_summary表示效果摘要；player_perception表示是否会被玩家察觉（如间谍网等级足够高）。

### 5.4.5 叙事生成API

API：generate_narrative_content

该API用于为特定情境生成叙事内容。

输入参数包括：context表示情境描述，如“玩家刚刚赢得了一场对外战争”；style表示风格偏好，如FORMAL（正式）、CASUAL（随意）、THREATENING（威胁性）；recipient表示接收方势力ID；content_type表示内容类型，可选值包括PROPAGANDA（宣传）、DECLARATION（公告）、INTELLIGENCE_BRIEFING（情报简报）。

返回结果包括：generated_content表示生成的具体文本内容；tone_analysis表示语气分析；key_themes表示包含的核心主题。

## 5.5 API调用流程与最佳实践

### 5.5.1 OODA决策循环

AI与游戏引擎的交互遵循Observe-Orient-Decide-Act（OODA）循环模式，确保决策的连贯性和有效性。

观察阶段（Observe）。AI首先调用相关查询API获取当前游戏状态。典型调用包括：query_resource_status获取资源状况；query_fleet_status获取舰队状态；query_relationship_status获取外交关系；query_world_state获取全局态势。

分析阶段（Orient）。AI分析获取的数据，结合自身的性格特质和战略目标，形成对当前局势的判断。这一阶段不涉及API调用，而是AI内部的推理过程。

决策阶段（Decide）。AI基于分析结果选择行动方案。决策可能涉及调用评估类API，如recommend_tactical_approach获取战术建议，或evaluate_diplomatic_proposal评估外交提案。

执行阶段（Act）。AI通过执行类API将决策转化为游戏内行动。执行后获取返回结果，更新AI的上下文信息，为下一轮OODA循环做准备。

### 5.5.2 错误处理与重试策略

AI在调用API时可能遇到各种错误情况，系统设计了相应的错误处理机制。

可重试错误。包括网络超时、服务端暂时不可用等临时性错误。AI应等待一段时间后重试，通常采用指数退避策略。

参数错误。AI传递了不存在的参数或参数格式错误。系统返回具体的错误描述，AI应根据错误信息修正参数后重试。

业务逻辑错误。如资源不足、前置条件不满足等。系统返回具体的失败原因，AI应调整策略，如等待资源积累或改变行动目标。

不可恢复错误。如目标不存在、权限不足等严重错误。AI应记录该错误并调整后续决策，避免重复尝试无效操作。
