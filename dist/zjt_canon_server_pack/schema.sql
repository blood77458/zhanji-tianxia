-- ============================================================================
--  《战姬天下》(canon) 私服数据库结构  v1
-- ============================================================================
--  引擎：SQLite 3（建议开启 WAL）
--  依据：API.md（从 zjt_pack_enablefix_signed.apk 逆向出的 363 个接口）
--        + work/api_analysis/struct_*.md（客户端实际读取的字段路径）
--
--  设计约定
--  --------
--  1. 时间统一 INTEGER = Unix 秒。对应客户端 TimeUtil.getServerTimeSeconds()
--     与 subHeader.ts。**不要**用毫秒，客户端多处直接当秒做减法。
--  2. 布尔用 INTEGER 0/1（SQLite 无 BOOLEAN）。
--  3. 金额/数量一律 INTEGER。客户端的 gem/gold/exp 都是整数运算。
--  4. `*_json` 列 = 「客户端契约字段」的整块载体：服务端只存不解析，
--     组装响应时原样取出。命名用 json 后缀明确标注。
--  5. 列名 snake_case；组装层（assembler）负责映射回客户端要的 camelCase。
--     **不要**为了省事把客户端字段名直接当列名，否则改名/camelCase
--     拼写（nickName vs nickname）会污染数据层。
--  6. 一个角色的所有资产表都带 player_id + 外键级联删除。
--
--  为什么是「混合模型」而不是全关系化
--  ----------------------------------
--  这个客户端把近百个字段打包在 gameInit 里一次性下发，其中大量字段
--  （活动状态、每日计数、配置镜像）服务端从不需要按字段查询。把它们
--  拆成列只会得到几百个只会被整体读写的字段。所以：
--    * 需要索引 / 跨玩家查询 / 原子自增 / 有独立接口的  -> 关系表或列
--    * 只整块下发的                                    -> JSON 列
--  每个 JSON 列在下方都有注释说明它承载哪个客户端 key。
-- ============================================================================

PRAGMA foreign_keys = ON;


-- ============================================================================
--  一、账号与会话
-- ============================================================================

-- 账号。一个账号可以在多个 serverId 上各有一个角色（getLoginServer 返回列表）
CREATE TABLE account (
    account_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    account_name    TEXT    UNIQUE,              -- 注册账号名；游客账号为 NULL
    password_hash   TEXT,                        -- 客户端注册时已做 md5，服务端再盐化一道
    password_salt   TEXT,
    email           TEXT,                        -- 绑定邮箱（resetPassword / 找回）
    device_id       TEXT,                        -- 游客账号的设备标识
    status          INTEGER NOT NULL DEFAULT 1,  -- 1 正常 / 0 封停
    create_time     INTEGER NOT NULL,
    last_login_time INTEGER,
    last_login_ip   TEXT
);
CREATE INDEX idx_account_device ON account(device_id);

-- 第三方平台 / 设备绑定。rebindAccount、mappingAccount 写这里
CREATE TABLE account_binding (
    binding_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id   INTEGER NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
    platform_id  TEXT    NOT NULL,               -- duoku / android / ios / guest ...
    platform_uid TEXT    NOT NULL,               -- 平台 uid，游客登录时=设备 ID
    device_id    TEXT,                           -- 原始设备号（游客账号用）
    sid          TEXT,                           -- /check/* 返回并回传的 sk
    bind_time    INTEGER NOT NULL,
    UNIQUE (platform_id, platform_uid)           -- mappingAccount 靠这个反查账号
);

-- 会话。对应 /sessionKey/init 返回的 "uid,uuid,sessionKey"
CREATE TABLE auth_session (
    session_key TEXT    PRIMARY KEY,             -- = RPC header 的 sk
    account_id  INTEGER NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
    player_id   INTEGER,                         -- 选定角色后回填
    uuid        TEXT,
    uk          TEXT,                            -- 下发客户端的 userKey（header.uk）
    udid        TEXT,
    client_ip   TEXT,
    create_time INTEGER NOT NULL,
    expire_time INTEGER NOT NULL,
    revoked     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_session_account ON auth_session(account_id);


-- ============================================================================
--  二、角色（sharkUser）
-- ============================================================================

CREATE TABLE player (
    player_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id      INTEGER NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
    server_id       INTEGER NOT NULL DEFAULT 1,

    -- --- 身份 ---
    nickname        TEXT    NOT NULL,
    create_time     INTEGER NOT NULL,
    last_login_time INTEGER,
    last_logout_time INTEGER,

    -- --- 等级与经验 ---
    level           INTEGER NOT NULL DEFAULT 1,   -- 客户端最多算到 99
    exp             INTEGER NOT NULL DEFAULT 0,   -- 当前等级内的经验

    -- --- 货币 ---
    -- 注意：客户端同时读 gold 和 coins 两个字段，语义相同（都是金币），
    -- BaseUIScene 用 coins，CanonGoodIcon 用 gold。这里只存一份，组装时都下发。
    gold            INTEGER NOT NULL DEFAULT 0,
    gem             INTEGER NOT NULL DEFAULT 0,   -- 总钻石
    free_gems       INTEGER NOT NULL DEFAULT 0,   -- 免费钻石
    used_free_gems  INTEGER NOT NULL DEFAULT 0,
    recharge_gems   INTEGER NOT NULL DEFAULT 0,   -- 充值获得钻石（累充活动按它算）
    used_recharge_gems INTEGER NOT NULL DEFAULT 0,
    -- CalculationManager.calcComplex_getGemsNow =
    --   recharge_gems + free_gems - used_free_gems - used_recharge_gems
    -- 四个字段缺一个就是 nil 算术 -> 黑屏。
    silver          INTEGER NOT NULL DEFAULT 0,
    medal_num       INTEGER NOT NULL DEFAULT 0,   -- 勋章（sharkUserExtendMore.medalNum）
    astral_essence  INTEGER NOT NULL DEFAULT 0,   -- 星灵（sharkUserExtend.astralEssence）
    friend_point    INTEGER NOT NULL DEFAULT 0,   -- 友情点
    general_exp     INTEGER NOT NULL DEFAULT 0,   -- 通用经验（卡牌经验强化）

    -- --- VIP ---
    vip_level       INTEGER NOT NULL DEFAULT 0,
    vip_exp         INTEGER NOT NULL DEFAULT 0,

    -- --- 体力 / 精力（带时间戳，客户端自己按秒恢复）---
    energy          INTEGER NOT NULL DEFAULT 0,
    energy_last_update_time     INTEGER NOT NULL DEFAULT 0,
    event_point     INTEGER NOT NULL DEFAULT 0,
    event_point_last_update_time INTEGER NOT NULL DEFAULT 0,
    action_power    INTEGER NOT NULL DEFAULT 0,   -- 活动行动力
    action_power_last_update_time INTEGER NOT NULL DEFAULT 0,

    -- --- 阵容（当前生效的那一套；多套阵容在 player_battle_array）---
    -- 客户端 CommonManager.getQueueData() 读的就是这两个字段：
    --   mainCardId           = 1 号位
    --   additionalCardIds    = 逗号分隔字符串（**必须是 string**，客户端 :split(",")）
    main_card_id        INTEGER NOT NULL DEFAULT 0,
    additional_card_ids TEXT    NOT NULL DEFAULT '',

    -- --- 引导 / 改名 ---
    guide_step      INTEGER NOT NULL DEFAULT 0,
    new_guide_step  INTEGER NOT NULL DEFAULT 0,
    last_rename_times INTEGER NOT NULL DEFAULT 0,
    rename_cd       INTEGER NOT NULL DEFAULT 0,

    -- --- 展示 / 运营 ---
    fight_capacity  INTEGER NOT NULL DEFAULT 0,
    leadership      INTEGER NOT NULL DEFAULT 0,
    no_chat_end_seconds INTEGER NOT NULL DEFAULT 0,  -- getUserBanInfo：禁言截止
    last_free_gacha_seconds INTEGER NOT NULL DEFAULT 0,

    UNIQUE (account_id, server_id)
);
CREATE INDEX idx_player_nickname ON player(nickname);


-- 玩家扩展（sharkUserExtend + sharkUserExtendMore）。
-- 1:1 于 player，但字段生命周期短、变动频繁，单独一张表避免热表变宽。
CREATE TABLE player_extend (
    player_id       INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,

    -- --- 标量计数器：这些会被自己的接口改动，做列 ---
    battle_array_id          INTEGER NOT NULL DEFAULT 0,  -- 当前使用的阵容 id（sharkUserExtendMore）
    bought_grid_num          INTEGER NOT NULL DEFAULT 0,  -- 已买背包格
    bought_grid_times        INTEGER NOT NULL DEFAULT 0,  -- 已买次数（每日重置）
    bought_spirit_pool_num   INTEGER NOT NULL DEFAULT 0,  -- 已买元神池格
    senior_gacha_ten_times   INTEGER NOT NULL DEFAULT 0,  -- 高级十连计数（保底）
    treasure_fragment_num    INTEGER NOT NULL DEFAULT 0,  -- sharkUserExtendMore.treasureInfo
    treasure_buy_grid_times  INTEGER NOT NULL DEFAULT 0,
    enchant_step_reward      INTEGER NOT NULL DEFAULT 0,  -- 附灵引导奖励是否已领

    -- --- 活动系数（新号/回归号判定用）---
    ny_charged_gems          INTEGER NOT NULL DEFAULT 0,  -- 新年活动累计充值钻石
    gold_god_num             INTEGER NOT NULL DEFAULT 0,  -- 财神活动次数
    gg_version               INTEGER NOT NULL DEFAULT 0,  -- 财神活动版本

    -- --- 整块下发的客户端契约字段（服务端不解析）---
    -- sharkUserExtend.cardGroupInterworking      : list
    -- sharkUserExtend.countdownFreeGachaInfos    : list
    -- sharkUserExtend.lifeLimitGoods             : list
    -- sharkUserExtend.lstEatPeachInfo            : list
    -- sharkUserExtend.paidChannelNames           : list
    -- sharkUserExtend.vipPackages                : list
    -- sharkUserExtend.doubleChargeInfo           : dict
    -- sharkUserExtend.exchangeGiftBagInfo        : dict
    -- sharkUserExtendMore.continuousLoginRewardInfoV2 : dict（另有 player_continuous_login）
    extend_json     TEXT NOT NULL DEFAULT '{}',

    -- sharkUserExtendMore 里其余新字段（跨服类）
    extend_more_json TEXT NOT NULL DEFAULT '{}',

    updated_at      INTEGER NOT NULL DEFAULT 0
);

-- 新手引导已完成步骤。单独成表：canonUtils.IsGuideExecuted 会 pairs() 它，
-- 且服务端也可能要按步骤做运营查询。
CREATE TABLE player_tutorial_step (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    step       INTEGER NOT NULL,
    done_time  INTEGER NOT NULL,
    PRIMARY KEY (player_id, step)
);


-- ============================================================================
--  三、ID 分配器
-- ============================================================================
-- 卡牌/装备/元神/宝物/邮件的实例 id 都由服务端生成。用一张表集中分配，
-- 避免在每张资产表上各搞一套计数器，也方便一次性调大起点（旧存档从 1000 起）。
CREATE TABLE id_alloc (
    name      TEXT    PRIMARY KEY,      -- card / equip / spirit / treasure / mail / union ...
    next_val  INTEGER NOT NULL DEFAULT 1
);
INSERT INTO id_alloc (name, next_val) VALUES
    ('card', 1000), ('equip', 100), ('spirit', 1), ('treasure', 1),
    ('mail', 1), ('union', 1), ('order', 1);


-- ============================================================================
--  四、资产：卡牌 / 装备 / 道具 / 元神 / 宝物 / 碎片
-- ============================================================================

-- 卡牌实例（sharkCards.sharkCards[]）
CREATE TABLE player_card (
    card_id         INTEGER PRIMARY KEY,          -- 游戏内 cardId（= id_alloc 'card'）
    player_id       INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    meta_id         INTEGER NOT NULL,             -- 卡牌配置 id
    avatar_meta_id  INTEGER NOT NULL DEFAULT 0,   -- 自定义头像（adjustCardAvatar）
    level           INTEGER NOT NULL DEFAULT 1,
    exp             INTEGER NOT NULL DEFAULT 0,
    card_group_id   INTEGER NOT NULL DEFAULT 0,   -- 必须等于 card_meta[metaId].cardGroupId，否则编队界面崩
    fight_capacity  INTEGER NOT NULL DEFAULT 0,
    -- 培养值（trainCard / saveCardTrain）
    att_train_value INTEGER NOT NULL DEFAULT 0,
    def_train_value INTEGER NOT NULL DEFAULT 0,
    hp_train_value  INTEGER NOT NULL DEFAULT 0,
    -- 进化加成值（evolveCard）
    att_evolve_value INTEGER NOT NULL DEFAULT 0,
    def_evolve_value INTEGER NOT NULL DEFAULT 0,
    hp_evolve_value  INTEGER NOT NULL DEFAULT 0,
    -- 潜能
    used_potential  INTEGER NOT NULL DEFAULT 0,
    -- 这里**没有** treasure_id 列：客户端的 sharkCard.treasureId 与
    -- sharkUserQueue[].treasureId 是同一份数据的两个视图，唯一权威来源是
    -- player_treasure.card_id，组装时反查（同 equipIds / cardSpirits）。
    -- 组装时必须输出 0 而不是 null —— CommonManager 判的是 `~= 0`。
    is_locked       INTEGER NOT NULL DEFAULT 0,   -- lockCard
    create_time     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_card_player ON player_card(player_id);
CREATE INDEX idx_card_meta   ON player_card(meta_id);

-- 卡牌技能（sharkCard.cardSkills[]）。
-- 客户端 QueueCardPanel 会 cardSkills[i].skillId 索引 skill_meta，
-- 空列表 + card_meta.skill ~= 0 就是 SIGKILL，所以实例化时必须按配置预生成。
CREATE TABLE player_card_skill (
    card_id          INTEGER NOT NULL REFERENCES player_card(card_id) ON DELETE CASCADE,
    slot             INTEGER NOT NULL,            -- 顺序，组装时按它排序
    skill_id         INTEGER NOT NULL,
    skill_type       INTEGER NOT NULL DEFAULT 0,
    curr_quality     INTEGER NOT NULL DEFAULT 0,
    country_group_id INTEGER NOT NULL DEFAULT 0,  -- skillType==4 才有效
    country_group_num INTEGER NOT NULL DEFAULT 0,
    card_group_ids   TEXT    NOT NULL DEFAULT '', -- 逗号分隔
    PRIMARY KEY (card_id, slot)
);

-- 装备实例（sharkEquips.sharkEquips[]）
CREATE TABLE player_equip (
    equip_id      INTEGER PRIMARY KEY,            -- = id_alloc 'equip'
    player_id     INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    meta_id       INTEGER NOT NULL,
    level         INTEGER NOT NULL DEFAULT 1,
    exp           INTEGER NOT NULL DEFAULT 0,
    -- 穿戴者。**这是唯一权威来源**：组装时同时派生
    --   sharkCard.equipIds[] 和 sharkEquip.cardId
    -- 两个客户端字段都从这一列算出来，绝不能各存一份（changeBattleArray
    -- 会按两个方向互相覆盖，不一致就会丢装备）。
    card_id       INTEGER NOT NULL DEFAULT 0,
    enchant_level INTEGER NOT NULL DEFAULT 0,     -- 附灵
    enchant_num   INTEGER NOT NULL DEFAULT 0,
    create_time   INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_equip_player ON player_equip(player_id);
CREATE INDEX idx_equip_card   ON player_equip(card_id);

-- 道具/材料（sharkProps.sharkProps[]，只有 metaId + amount，没有实例 id）
CREATE TABLE player_prop (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    meta_id    INTEGER NOT NULL,
    amount     INTEGER NOT NULL DEFAULT 0,
    update_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, meta_id)
);
-- 神圣币（sharkMysteriousCoins.sharkMysteriousCoins）：本质也是 metaId->amount
CREATE TABLE player_mysterious_coin (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    meta_id    INTEGER NOT NULL,
    amount     INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, meta_id)
);

-- 元神实例（sharkSpirits.sharkSpirits[]）
CREATE TABLE player_spirit (
    spirit_id           INTEGER PRIMARY KEY,      -- = id_alloc 'spirit'
    player_id           INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    meta_id             INTEGER NOT NULL,
    level               INTEGER NOT NULL DEFAULT 1,
    exp                 INTEGER NOT NULL DEFAULT 0,
    card_id             INTEGER NOT NULL DEFAULT 0,  -- 装备在哪个武将上（0=在池里）
    lock_attribute_index INTEGER NOT NULL DEFAULT 0, -- 洗炼锁定的属性位
    create_time         INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_spirit_player ON player_spirit(player_id);

-- 元神副属性（spirit.sharkSpiritAttributes[]）。
-- SpiritManager 会 attr.attributeType / attr.attributeGrowing 逐条累加，
-- 空列表不会崩，但属性数值会全错。
CREATE TABLE player_spirit_attr (
    spirit_id        INTEGER NOT NULL REFERENCES player_spirit(spirit_id) ON DELETE CASCADE,
    slot             INTEGER NOT NULL,
    attribute_type   INTEGER NOT NULL,            -- 1攻 2防 3血 6/7/8... 见 SpiritManager.getTextBySpiritAttrType
    attribute_growing REAL   NOT NULL DEFAULT 0,  -- 浮点：客户端 getFloatNumber(v*growth*level)
    PRIMARY KEY (spirit_id, slot)
);

-- 元神洗炼的暂存结果（sharkUserExtendMore.unsaveSpiritId / unsaveSpiritAttributes）
CREATE TABLE player_spirit_unsaved (
    player_id   INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    spirit_id   INTEGER NOT NULL DEFAULT 0,
    attributes_json TEXT NOT NULL DEFAULT '[]',
    updated_at  INTEGER NOT NULL DEFAULT 0
);

-- 宝物实例（sharkTreasures.sharkTreasures[]）
CREATE TABLE player_treasure (
    treasure_id     INTEGER PRIMARY KEY,          -- = id_alloc 'treasure'
    player_id       INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    meta_id         INTEGER NOT NULL,
    level           INTEGER NOT NULL DEFAULT 1,
    add_potential   INTEGER NOT NULL DEFAULT 0,   -- 已加潜能
    add_gem_potential INTEGER NOT NULL DEFAULT 0, -- 钻石加潜能
    used_potential  INTEGER NOT NULL DEFAULT 0,
    card_id         INTEGER NOT NULL DEFAULT 0,   -- 装备者（同装备，单点存储）
    is_locked       INTEGER NOT NULL DEFAULT 0,
    create_time     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_treasure_player ON player_treasure(player_id);

-- 碎片（sharkCardFragments.sharkCardFragments / sharkEquipFragments）
CREATE TABLE player_fragment (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    kind       INTEGER NOT NULL,                  -- 1=卡牌碎片 2=装备碎片
    meta_id    INTEGER NOT NULL,
    amount     INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, kind, meta_id)
);


-- ============================================================================
--  五、阵容（多套）
-- ============================================================================
--  客户端结构（见 ChangeBattleArrayRequest.onSucceedDefault）：
--    sharkUserBattleArray[battleArrayId] = {
--        sharkUserQueue   = [ {cardId, equips[], spirits[], treasureId}, ... ],  -- 1 号位 = 主将
--        sharkMatrices    = { sharkMatrices = [ {matrixId, sharkMatrixGrids=[{matrixGridId,cardId}]} ] }
--    }
--  当前生效的是 player_extend.battle_array_id 指向的那一套，
--  同时冗余写入 player.main_card_id / additional_card_ids 供 getQueueData 使用。

CREATE TABLE player_battle_array (
    array_id   INTEGER NOT NULL,                  -- 1..N 的阵容槽位
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    is_active  INTEGER NOT NULL DEFAULT 0,
    name       TEXT    NOT NULL DEFAULT '',
    unlock_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, array_id)
);

-- 阵容槽位。**只存"哪张卡站在哪个位置"**，不存装备/元神/宝物 id。
--
-- 为什么：客户端的 sharkUserQueue[j] 里确实有 equips[] / spirits[] /
-- treasureId 三个列表，但它们和 sharkCards[].equipIds / cardSpirits /
-- treasureId 是**同一份数据的两个视图**。客户端自己就是靠
-- player_equip.card_id / player_spirit.card_id / player_treasure.card_id
-- 反查出来的（原服务端 _game_init_extra 也是这么做的：
--   worn = [e for e in equips if e.cardId == slot.cardId]）。
-- 如果这里也存一份，切阵容时两处不同步就会**静默丢装备**。
CREATE TABLE player_battle_slot (
    player_id  INTEGER NOT NULL,
    array_id   INTEGER NOT NULL,
    slot       INTEGER NOT NULL,                  -- 1 = 主将位，2..6 = 副将位
    card_id    INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, array_id, slot),
    FOREIGN KEY (player_id, array_id)
        REFERENCES player_battle_array(player_id, array_id) ON DELETE CASCADE
);

-- 阵法（sharkMatrices.sharkMatrices[]）
CREATE TABLE player_matrix (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    matrix_id  INTEGER NOT NULL,
    level      INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, matrix_id)
);

-- 阵法格子（sharkMatrixGrids[] = {matrixGridId, cardId}）
CREATE TABLE player_matrix_grid (
    player_id      INTEGER NOT NULL,
    matrix_id      INTEGER NOT NULL,
    matrix_grid_id INTEGER NOT NULL,
    card_id        INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, matrix_id, matrix_grid_id),
    FOREIGN KEY (player_id, matrix_id)
        REFERENCES player_matrix(player_id, matrix_id) ON DELETE CASCADE
);


-- ============================================================================
--  六、闯关进度
-- ============================================================================

-- sharkMissionContext。**整体必须是完整对象，绝不能下发 {}**
-- （空表在 Lua 为真，会顶掉客户端的自建默认值，下一行 missionId/100 崩）
CREATE TABLE player_mission_context (
    player_id      INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    mission_id     INTEGER NOT NULL DEFAULT 100101,
    finished_step  INTEGER NOT NULL DEFAULT 0,
    fight_lose     INTEGER NOT NULL DEFAULT 0,
    route_id       INTEGER NOT NULL DEFAULT 1,
    updated_at     INTEGER NOT NULL DEFAULT 0
);

-- sharkSceneProcess
CREATE TABLE player_scene_process (
    player_id              INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    max_finished_mission_id INTEGER NOT NULL DEFAULT 0,
    last_clear_time        INTEGER NOT NULL DEFAULT 0,
    -- 其余整块字段：
    --   finishedCountryIds[] / sceneCountries[] / activitySceneChapterList
    data_json              TEXT NOT NULL DEFAULT '{}'
);
CREATE TABLE player_scene_country (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    country_id INTEGER NOT NULL,
    kind       INTEGER NOT NULL DEFAULT 1,        -- 1=finishedCountryIds 2=sceneCountries
    PRIMARY KEY (player_id, country_id, kind)
);

-- missionCompletes[]（章节通关记录，gainChapterFinishReward 用）
CREATE TABLE player_mission_complete (
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    mission_id  INTEGER NOT NULL,
    star        INTEGER NOT NULL DEFAULT 0,
    finish_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, mission_id)
);

-- sharkElite / sharkSkyTower / sharkChristInfo：三套独立的爬塔进度
CREATE TABLE player_elite (
    player_id            INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    max_finished_elite_id INTEGER NOT NULL DEFAULT 0,
    data_json            TEXT NOT NULL DEFAULT '{}'
);
CREATE TABLE player_sky_tower (
    player_id          INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    max_big_win_floor  INTEGER NOT NULL DEFAULT 0,
    max_floor          INTEGER NOT NULL DEFAULT 0,
    reset_time         INTEGER NOT NULL DEFAULT 0,
    data_json          TEXT NOT NULL DEFAULT '{}'
);
CREATE TABLE player_christ (
    player_id              INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    max_finished_christ_id INTEGER NOT NULL DEFAULT 0,
    data_json              TEXT NOT NULL DEFAULT '{}'   -- listSharkChristInfo
);


-- ============================================================================
--  七、每日 / 周期数据
-- ============================================================================
--  设计取舍：客户端把「今天的数据」当成一整块 sharkDailyData 下发。
--  这里拆成三层：
--    * player_daily          —— 当天整块 JSON（承载 sharkDailyData / sharkDailyDataExtend）
--    * player_daily_counter  —— 需要原子自增或跨天比对的计数（购买次数、活动次数…）
--    * 有独立接口的         —— 各自的专表（下面第八节）
--  `stat_date` 用本地日期的 unix 零点秒，便于跨天清理。

CREATE TABLE player_daily (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    stat_date  INTEGER NOT NULL,
    -- sharkDailyData（_date / lstCowStageInfo / lstEatPeachInfo / crossPvpDailyData …）
    data_json  TEXT NOT NULL DEFAULT '{}',
    -- sharkDailyDataExtend（mysteriousChallengeTimes / mysteriousExchangeTimes /
    --   treasureSacrificeTimes / cardExchangeDailyInfo）
    extend_json TEXT NOT NULL DEFAULT '{}',
    PRIMARY KEY (player_id, stat_date)
);

-- 每日计数器的键由服务端统一定义（建议放一个 daily_keys.py 常量表）。
-- 例：buy_energy_num / buy_ep_num / elite_reset_num / gacha_free_used ...
CREATE TABLE player_daily_counter (
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    stat_date  INTEGER NOT NULL,
    counter_key TEXT   NOT NULL,
    value      INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, stat_date, counter_key)
);

-- 长期计数器（不随天重置）：gacha 保底、累计次数等
CREATE TABLE player_counter (
    player_id    INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    counter_key  TEXT    NOT NULL,
    value        INTEGER NOT NULL DEFAULT 0,
    update_time  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, counter_key)
);


-- ============================================================================
--  八、签到 / 连续登录 / 充值相关
-- ============================================================================

-- sharkUserExtend.signInInfo（月签到）
CREATE TABLE player_sign_in (
    player_id            INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    login_days_month     INTEGER NOT NULL DEFAULT 0,   -- 本月已签天数
    last_reward_time     INTEGER NOT NULL DEFAULT 0,
    month_key            TEXT    NOT NULL DEFAULT '',  -- 'YYYY-MM'，跨月清零
    gained_day_ids_json  TEXT    NOT NULL DEFAULT '[]'
);

-- sharkUserExtend.continuousLoginInfo（累计登录）
CREATE TABLE player_continuous_login (
    player_id              INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    first_get_reward_time  INTEGER NOT NULL DEFAULT 0,
    latest_get_reward_time INTEGER NOT NULL DEFAULT 0,
    gain_rewards_json      TEXT    NOT NULL DEFAULT '[]',
    gain_reward_in_order   INTEGER NOT NULL DEFAULT 0,
    get_big_reward         INTEGER NOT NULL DEFAULT 0
);

-- sharkUserExtendMore.continuousLoginRewardInfoV2（7 天连登 V2）
CREATE TABLE player_continuous_login_v2 (
    player_id            INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    gain_reward_days     INTEGER NOT NULL DEFAULT 0,
    gained_rewards_json  TEXT    NOT NULL DEFAULT '[]',
    version              INTEGER NOT NULL DEFAULT 0
);

-- 充值累计档位领取记录：
--   sharkUserExtend.gainedChargeMoneyRewardList      （gainChargeMoneyReward）
--   sharkActivity.chargeInfo.gainedRewardIds         （新年累充）
--   sharkActivity.gainedSwornRewardList / gainedPraiseRewardIds / nyGainedRewardIds
-- 统一成一张「活动档位领取流水」，用 scope 区分。
CREATE TABLE player_activity_reward_claim (
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    scope       TEXT    NOT NULL,          -- charge_money / newyear_charge / sworn / praise / gold_god ...
    reward_id   INTEGER NOT NULL,
    claim_time  INTEGER NOT NULL,
    PRIMARY KEY (player_id, scope, reward_id)
);

-- 兑换码 / 礼包码（exchangeGiftBag）
CREATE TABLE player_gift_code (
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    code        TEXT    NOT NULL,
    exchange_time INTEGER NOT NULL,
    PRIMARY KEY (player_id, code)
);

-- 月卡（sharkGemCards.sharkGemCards[]，buyMonthGemCard / getBuyMonthGemCardResult）
CREATE TABLE player_gem_card (
    gem_card_id   INTEGER PRIMARY KEY,     -- = id_alloc 里另开一个 'gem_card'
    player_id     INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    product_id    TEXT    NOT NULL,        -- he_gold_xxx
    meta_id       INTEGER NOT NULL DEFAULT 0,
    start_time    INTEGER NOT NULL DEFAULT 0,
    end_time      INTEGER NOT NULL DEFAULT 0,
    last_gain_day TEXT    NOT NULL DEFAULT '',  -- 'YYYY-MM-DD'，防重复领取
    status        INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_gem_card_player ON player_gem_card(player_id);

-- 银币骰子活动（sharkDice）
CREATE TABLE player_dice (
    player_id               INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    throw_dice_count        INTEGER NOT NULL DEFAULT 0,
    change_dice_luck_count  INTEGER NOT NULL DEFAULT 0,
    change_luck_count_per_throw INTEGER NOT NULL DEFAULT 0,
    coin_value              INTEGER NOT NULL DEFAULT 0,
    gained_reward           INTEGER NOT NULL DEFAULT 0,
    dice_states_json        TEXT    NOT NULL DEFAULT '[]'
);

-- 商店循环购买（sharkShop.loopPurchaseInfos，VipManager 读）
CREATE TABLE player_shop_loop (
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    shop_id     INTEGER NOT NULL,
    goods_id    INTEGER NOT NULL,
    buy_count   INTEGER NOT NULL DEFAULT 0,
    last_buy_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, shop_id, goods_id)
);

-- 神秘商店（sharkUserSecretShop）
CREATE TABLE player_secret_shop (
    player_id          INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    free_times         INTEGER NOT NULL DEFAULT 0,
    last_refresh_second INTEGER NOT NULL DEFAULT 0,
    if_list_fresh      INTEGER NOT NULL DEFAULT 0,
    version            INTEGER NOT NULL DEFAULT 0,
    items_json         TEXT    NOT NULL DEFAULT '[]'
);

-- 通用活动状态表：所有「活动名 + 一坨状态」的玩法都塞这里。
-- 为什么不给每个活动建表：客户端侧有 27+ 个活动，每个活动的状态字段
-- 形态都不一样，且服务端从不按字段查询。用 (player_id, activity_key)
-- 做键 + JSON 值，配合 player_activity_reward_claim 处理「已领奖」。
CREATE TABLE player_activity (
    player_id     INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    activity_key  TEXT    NOT NULL,     -- newyear_8days / level_race / treasurebox / dice / question ...
    version       INTEGER NOT NULL DEFAULT 0,
    start_time    INTEGER NOT NULL DEFAULT 0,
    end_time      INTEGER NOT NULL DEFAULT 0,
    data_json     TEXT    NOT NULL DEFAULT '{}',
    update_time   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, activity_key)
);

-- 跨服 PVP 个人状态（sharkCrossPkUser）
CREATE TABLE player_cross_pk (
    player_id         INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    cross_version     INTEGER NOT NULL DEFAULT 0,
    guess_uid         INTEGER NOT NULL DEFAULT 0,
    gain_guess_reward INTEGER NOT NULL DEFAULT 0,
    gain_rank_reward  INTEGER NOT NULL DEFAULT 0,
    gain_server_reward INTEGER NOT NULL DEFAULT 0,
    data_json         TEXT    NOT NULL DEFAULT '{}'
);

-- 邀请码活动（fishInviteCode / invitationCode / sharkAccountInvitation）。
-- 客户端字段 invitePlayerNum / gainedInviteRewardNum **缺失会崩**，所以建列。
CREATE TABLE player_invite_code (
    player_id     INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    invite_code   TEXT    NOT NULL UNIQUE,
    invited_count INTEGER NOT NULL DEFAULT 0,   -- invitePlayerNum 被邀请人数
    gained_invite_reward_num INTEGER NOT NULL DEFAULT 0,
    has_invited   INTEGER NOT NULL DEFAULT 0,
    invited_by    INTEGER NOT NULL DEFAULT 0,
    create_time   INTEGER NOT NULL DEFAULT 0
);


-- ============================================================================
--  九、社交：好友 / 邀请 / 礼物 / 邮件
-- ============================================================================

-- 好友关系。**单向存两行**（A->B 和 B->A 各一行），
-- 因为客户端的 getFriends 只返回「我关注的人」，而删除是单向的。
--
-- ⚠️ 客户端要的好友条目是**组装出来的视图**，不是这张表的行，字段：
--   friendUid, nickName, level, mainCardMetaId, unionName, online,
--   lastestOfflineSeconds, giftSent, invitationSent, friend
-- 组装来源：
--   nickName/level        <- player
--   mainCardMetaId        <- player_card(player.main_card_id).meta_id
--   unionName             <- guild_member JOIN guild
--   online                <- auth_session 是否存在于最近 N 分钟
--   lastestOfflineSeconds <- player.last_logout_time 与 now 的差
--   giftSent/invitationSent <- friend.gift_sent_date / friend_invitation 状态
-- **online 为假时 lastestOfflineSeconds 必须存在**（MyFriendsPanel:239-241
-- 会对它做时间减法），缺失直接崩。
-- `acceptInvitation.acceptedFriend` / `acceptAllInvitations.acceptedFriends[]`
-- 也会走同一套渲染器，所以它们也必须带 online + lastestOfflineSeconds。
CREATE TABLE friend (
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    friend_uid  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    create_time INTEGER NOT NULL,
    -- 免费礼物当天的发放/领取状态（sendFreeGift / acceptAllFreeGift，按天重置）
    gift_sent_date   TEXT NOT NULL DEFAULT '',
    gift_taken_date  TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (player_id, friend_uid)
);
CREATE INDEX idx_friend_uid ON friend(friend_uid);

-- 好友邀请（sendInvitation / getReviewFriends / acceptInvitation …）
CREATE TABLE friend_invitation (
    invitation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_uid      INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    to_uid        INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    status        INTEGER NOT NULL DEFAULT 0,   -- 0待审核 1已接受 2已拒绝 3已取消
    create_time   INTEGER NOT NULL,
    handle_time   INTEGER
);
CREATE INDEX idx_invitation_to   ON friend_invitation(to_uid, status);
CREATE INDEX idx_invitation_from ON friend_invitation(from_uid, status);

-- 红包（distributeBonus / getBonusAccepterList）
CREATE TABLE red_packet (
    packet_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_uid    INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    bonus_id      INTEGER NOT NULL,
    total_amount  INTEGER NOT NULL DEFAULT 0,
    left_amount   INTEGER NOT NULL DEFAULT 0,
    total_count   INTEGER NOT NULL DEFAULT 0,
    left_count    INTEGER NOT NULL DEFAULT 0,
    scope         INTEGER NOT NULL DEFAULT 0,   -- 0好友 1军团
    create_time   INTEGER NOT NULL,
    expire_time   INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE red_packet_claim (
    packet_id  INTEGER NOT NULL REFERENCES red_packet(packet_id) ON DELETE CASCADE,
    player_id  INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    amount     INTEGER NOT NULL DEFAULT 0,
    claim_time INTEGER NOT NULL,
    PRIMARY KEY (packet_id, player_id)
);
-- 客户端红包候选列表要的 acceptNum = 该玩家在这个 bonusId 上已领的次数，
-- 用 COUNT(red_packet_claim) 现算；dispatchedNum / itemDescKey 是**纯客户端
-- 字段**，服务端不用下发。好友候选来自 friend+player，军团候选来自
-- guild_member（hisContribute / lastestConstructDays 也在那里）。
CREATE INDEX idx_claim_player ON red_packet_claim(player_id, packet_id);

-- 点赞（recordPraiseId / gainPraiseReward）
CREATE TABLE player_praise (
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    target_uid  INTEGER NOT NULL,
    praise_date TEXT    NOT NULL DEFAULT '',
    create_time INTEGER NOT NULL,
    PRIMARY KEY (player_id, target_uid)
);

-- 邮件总表。四类邮件共用一张表，用 mail_type 区分。
-- 客户端是 4 个独立数组：sysEmails / rewardEmails / sysNotices / userEmails，
-- **必须分别下发**——客户端会自己 table.union(sysEmails, rewardEmails) 后回写，
-- 服务端不要预先合并（EmailScene:495-510）。
--
-- 客户端字段映射（assembler 负责）：
--   mail_type=1 sysEmails[]   : sysEmailId, sysEmailMetaId, receiveSeconds, read, gainedReward
--   mail_type=2 rewardEmails[]: rewardEmailId, rewardEmailMetaId, content, receiveSeconds,
--                               gainedReward, reward(json 数组)
--   mail_type=3 sysNotices[]  : sysNoticeId, detail(**必须是合法 JSON 字符串**，
--                               客户端 cjson.decode), receiveTime
--   mail_type=4 userEmails[]  : userEmailId, receiveUid, sendUid, sendName, content,
--                               sendTime, read
--   ⚠️ 客户端同时读 mailType 作为本地时间标记，但那是它自己写进去的，服务端不要下发。
CREATE TABLE mail (
    mail_id      INTEGER PRIMARY KEY,        -- = id_alloc 'mail'
    player_id    INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    mail_type    INTEGER NOT NULL,           -- 1系统邮件 2奖励邮件 3系统公告 4玩家邮件
    meta_id      INTEGER NOT NULL DEFAULT 0, -- sysEmailMetaId / rewardEmailMetaId
    sender_uid   INTEGER NOT NULL DEFAULT 0, -- 玩家邮件才有（sendUid）
    sender_name  TEXT    NOT NULL DEFAULT '',
    title        TEXT    NOT NULL DEFAULT '',
    content      TEXT    NOT NULL DEFAULT '',
    -- sysNotices 专用：客户端会 cjson.decode(detail)，必须是合法 JSON 文本
    detail       TEXT    NOT NULL DEFAULT '{}',
    is_read      INTEGER NOT NULL DEFAULT 0,
    is_deleted   INTEGER NOT NULL DEFAULT 0,
    is_gained    INTEGER NOT NULL DEFAULT 0, -- gainedReward：附件是否已领
    -- create_time 同时映射成 sysEmails.receiveSeconds / userEmails.sendTime /
    -- sysNotices.receiveTime。**receiveSeconds 缺失会让客户端排序比较直接崩**
    -- （EmailScene:504 与 :645 的时间算术），绝不能为空。
    create_time  INTEGER NOT NULL,
    expire_time  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_mail_player ON mail(player_id, mail_type, is_deleted);

CREATE TABLE mail_attachment (
    mail_id   INTEGER NOT NULL REFERENCES mail(mail_id) ON DELETE CASCADE,
    slot      INTEGER NOT NULL,              -- 保持客户端看到的顺序
    item_type INTEGER NOT NULL,              -- ResourceEnum：1金币 4经验 6装备 ...
    meta_id   INTEGER NOT NULL DEFAULT 0,
    amount    INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (mail_id, slot)
);

-- 玩家间邮件（sendUserEmail）—— 收件人是离线玩家时落到 mail 表，
-- 这张表只用于审计/查重
CREATE TABLE user_mail_log (
    log_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    from_uid   INTEGER NOT NULL,
    to_uid     INTEGER NOT NULL,
    title      TEXT    NOT NULL DEFAULT '',
    content    TEXT    NOT NULL DEFAULT '',
    create_time INTEGER NOT NULL
);


-- 说明：军团是「跨玩家」数据，必须真关系化——成员、申请、建筑、城池
-- 都要能被别的玩家查询和更新。军团本身按 server_id 分域。
-- 客户端契约的字段级结构见 work/api_analysis/struct_union.md（69 个接口）。
--
-- ⚠️ 字段名拼写陷阱（组装层务必逐字照抄，本模块有 4 组）：
--     mainCardMeataId (阵型成员, 原厂拼写) ≠ mainCardMetaId (跨服 signs/申请者) ≠ mainCardId (成员/动态)
--     userName (阵型/signs) ≠ nickName (成员/申请者, 大写 N) ≠ nickname (帝王/新闻 detail)
--     arenaRank（不是 areanaRank）
--     阵型成员的 gemInspireNum 是"军团级总数"，与成员级同名不同义

CREATE TABLE guild (
    guild_id      INTEGER PRIMARY KEY,       -- 客户端字段名是 unionId
    server_id     INTEGER NOT NULL DEFAULT 1,
    name          TEXT    NOT NULL,          -- 列表项用 name；sharkUnion 里没有 unionName
    declaration   TEXT    NOT NULL DEFAULT '',   -- 宣言
    notice        TEXT    NOT NULL DEFAULT '',   -- 公告
    level         INTEGER NOT NULL DEFAULT 1,    -- 建议与 guild_building 的 hall 行同源
    exp           INTEGER NOT NULL DEFAULT 0,
    wealth        INTEGER NOT NULL DEFAULT 0,    -- unionWealth
    member_num    INTEGER NOT NULL DEFAULT 0,    -- 客户端每帧读
    rank          INTEGER NOT NULL DEFAULT -1,   -- sharkUnionWrappers[].rank，-1 = 未上榜
    leader_uid    INTEGER NOT NULL,              -- managerId
    transfer_uid  INTEGER NOT NULL DEFAULT 0,    -- nextManagerId
    transfer_time INTEGER NOT NULL DEFAULT 0,
    create_time   INTEGER NOT NULL,
    dissolve_time INTEGER NOT NULL DEFAULT 0,    -- unbandTime
    status        INTEGER NOT NULL DEFAULT 0,    -- 0正常 1已解散 2转让中
    union_war_version   INTEGER NOT NULL DEFAULT 0,
    union_war_round     INTEGER NOT NULL DEFAULT 0,
    union_war_light_on  INTEGER NOT NULL DEFAULT 0,   -- 军团战呼吸灯
    total_fight_capacity INTEGER NOT NULL DEFAULT 0,  -- 报名城池的战力门槛判定
    cross_gvg_applied   INTEGER NOT NULL DEFAULT 0,
    cross_gvg_version   INTEGER NOT NULL DEFAULT 0,
    data_json     TEXT    NOT NULL DEFAULT '{}',      -- 只放真正的杂项
    UNIQUE (server_id, name)
);
CREATE INDEX idx_guild_wealth ON guild(server_id, wealth);

CREATE TABLE guild_member (
    guild_id       INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    player_id      INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    title          INTEGER NOT NULL DEFAULT 0,   -- userTitle：军团长/副军团长/精英/成员
    -- 0成员 1主动退 2被踢 3解散。**退团后不要立即删行**：
    -- 客户端靠 status + dissolvedSeconds 判断"还在退出流程中"
    status         INTEGER NOT NULL DEFAULT 0,
    join_time      INTEGER NOT NULL,             -- joinSeconds
    reactive_time  INTEGER NOT NULL DEFAULT 0,   -- reactiveSeconds，入团冷却结束时刻
    dissolved_time INTEGER NOT NULL DEFAULT 0,   -- dissolvedSeconds
    contrib_total  INTEGER NOT NULL DEFAULT 0,   -- hisContribute
    contrib_week   INTEGER NOT NULL DEFAULT 0,   -- contribute
    contrib_day    INTEGER NOT NULL DEFAULT 0,
    last_construct_time INTEGER NOT NULL DEFAULT 0,  -- lastestConstructSeconds
    last_construct_type INTEGER NOT NULL DEFAULT 0,  -- 0无 1银币 2金币1 3金币3
    last_active_time    INTEGER NOT NULL DEFAULT 0,  -- lastestActiveSeconds（离线显示/弹劾）
    online              INTEGER NOT NULL DEFAULT 0,
    challenge_city_id   INTEGER NOT NULL DEFAULT 0,  -- challengeCityId，0=未报名
    coin_inspire_num    INTEGER NOT NULL DEFAULT 0,
    strive_inspire_num  INTEGER NOT NULL DEFAULT 0,
    gem_inspire_num     INTEGER NOT NULL DEFAULT 0,
    gain_war_play       INTEGER NOT NULL DEFAULT 0,  -- gainUnionWarPlayReward
    gain_war_occupy     INTEGER NOT NULL DEFAULT 0,  -- gainUnionWarOccupyReward
    gain_war_in_battle  INTEGER NOT NULL DEFAULT 0,  -- gainUnionWarInBattleReward
    cross_gvg_applied   INTEGER NOT NULL DEFAULT 0,  -- selfApplyCrossGvg
    cross_gvg_quit      INTEGER NOT NULL DEFAULT 0,  -- selfQuitCrossGvg
    gvg_position        INTEGER NOT NULL DEFAULT 0,  -- 1先锋 / 10-19阵首 / 20-29阵中 / 30-39阵尾
    gvg_team_mirror_version INTEGER NOT NULL DEFAULT 0,
    last_wage_time INTEGER NOT NULL DEFAULT 0,   -- receiveUnionWage
    quit_cd_time   INTEGER NOT NULL DEFAULT 0,   -- 退团冷却
    PRIMARY KEY (guild_id, player_id)
);
CREATE INDEX idx_guild_member_player ON guild_member(player_id);

CREATE TABLE guild_apply (
    apply_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    guild_id    INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    status      INTEGER NOT NULL DEFAULT 0,      -- 0待审 1已接受 2已拒绝 3已取消
    apply_time  INTEGER NOT NULL,
    handle_time INTEGER,
    UNIQUE (guild_id, player_id)
);
-- sharkUnionAppliers[] 需要 uid/nickName/level/mainCardMetaId/arenaRank/
-- fightCapacity —— 全部 join player 表得到。
-- ⚠️ 申请者用 mainCardMetaId，成员用 mainCardId，**不要复用同一个 mapper**。

CREATE TABLE guild_building (
    guild_id    INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    building_id INTEGER NOT NULL,                -- 1大厅 2商城 3钱庄 4斗兽场
    level       INTEGER NOT NULL DEFAULT 1,
    construct_times_today INTEGER NOT NULL DEFAULT 0,
    last_construct_seconds INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (guild_id, building_id)
);

-- 建筑捐献公告（donateAnnouncement[] = {nickname, donateNum}，最多取 10 条）
CREATE TABLE guild_donate_log (
    log_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    guild_id    INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    building_id INTEGER NOT NULL DEFAULT 0,
    player_id   INTEGER NOT NULL DEFAULT 0,
    nickname    TEXT    NOT NULL DEFAULT '',
    donate_num  INTEGER NOT NULL DEFAULT 0,
    create_time INTEGER NOT NULL
);
CREATE INDEX idx_donate ON guild_donate_log(guild_id, create_time);

-- 军团商城购买记录（specialShopRecord[]）。
-- leftNum 是算出来的（dailyPurchaseLimit - bought_num），**不要落库**。
CREATE TABLE guild_shop_record (
    guild_id   INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    shop_type  INTEGER NOT NULL,                 -- 1普通 2特殊
    prop_id    INTEGER NOT NULL,
    bought_num INTEGER NOT NULL DEFAULT 0,
    reset_time INTEGER NOT NULL DEFAULT 0,       -- 日/周重置时刻
    PRIMARY KEY (guild_id, shop_type, prop_id)
);

-- 军团动态（getUnionNews / sharkUnionNewsWrappers / unionWarNewsWrappers）
CREATE TABLE guild_news (
    news_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    guild_id    INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    news_type   INTEGER NOT NULL DEFAULT 0,      -- 1普通动态 2军团战动态（决定进哪个 wrapper 数组）
    event_type  INTEGER NOT NULL DEFAULT 0,      -- 客户端字段 `type`：1..12 / WAR_NEWS_TYPE_*
    actor_uid   INTEGER NOT NULL DEFAULT 0,      -- senderUid
    actor_name  TEXT    NOT NULL DEFAULT '',     -- senderNickname
    actor_level INTEGER NOT NULL DEFAULT 0,
    actor_main_card_id INTEGER NOT NULL DEFAULT 0,
    -- 客户端字段 `detail`：JSON 文本。普通动态里昵称用 nickname（小写 n）；
    -- 军团战动态里的城池 id 列表客户端按 :split(",") 读 → 存逗号分隔字符串
    content     TEXT    NOT NULL DEFAULT '{}',
    create_time INTEGER NOT NULL
);
CREATE INDEX idx_guild_news ON guild_news(guild_id, news_type, create_time);

-- 军团斗兽场 BOSS（challengeUnionMonster / unionMonsterRewardDistribute*）
CREATE TABLE guild_monster (
    guild_id             INTEGER PRIMARY KEY REFERENCES guild(guild_id) ON DELETE CASCADE,
    monster_id           INTEGER NOT NULL DEFAULT 0,   -- monsterMetaId
    monster_left_hp      INTEGER NOT NULL DEFAULT 0,
    -- escapeSeconds 是**时间戳**，客户端 +3 秒后与 now 比较；nil 必崩
    escape_seconds       INTEGER NOT NULL DEFAULT 0,
    summon_times         INTEGER NOT NULL DEFAULT 0,
    summon_user_uid      INTEGER NOT NULL DEFAULT 0,
    summon_user_nickname TEXT    NOT NULL DEFAULT '',
    reward_double        INTEGER NOT NULL DEFAULT 0,
    distributing_uid     INTEGER NOT NULL DEFAULT 0,
    reward_distributed   INTEGER NOT NULL DEFAULT 0,
    -- 客户端只读 sharkUnionMonster.reward.amount 一个数，且 reward 必须是
    -- **对象不是数组**；它会进 `totalNum - X` 算术，nil 必崩。
    reward_amount        INTEGER NOT NULL DEFAULT 0,
    refresh_time         INTEGER NOT NULL DEFAULT 0
);

-- 斗兽伤害榜（getUnionMonsterRank 的 rankList）
CREATE TABLE guild_monster_damage (
    guild_id     INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    monster_id   INTEGER NOT NULL DEFAULT 0,   -- 同一军团多次召唤要做轮次隔离
    player_id    INTEGER NOT NULL,
    nick_name    TEXT    NOT NULL DEFAULT '',  -- 快照，避免 join（注意大写 N）
    total_damage INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (guild_id, monster_id, player_id)
);
CREATE INDEX idx_monster_damage ON guild_monster_damage(guild_id, monster_id, total_damage);

-- 斗兽奖励分配（unionMonsterRewardDistribute* 的 currMonsterRewards[]）
CREATE TABLE guild_monster_allocate (
    guild_id      INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    monster_id    INTEGER NOT NULL DEFAULT 0,
    player_id     INTEGER NOT NULL,
    amount        INTEGER NOT NULL DEFAULT 0,
    week_get_num  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (guild_id, monster_id, player_id)
);

-- 军团战城池
CREATE TABLE guild_city (
    city_id        INTEGER PRIMARY KEY,          -- 配置里的城池 id
    server_id      INTEGER NOT NULL DEFAULT 1,
    owner_guild_id INTEGER NOT NULL DEFAULT 0,   -- 0 = NPC 守军
    owner_union_name TEXT  NOT NULL DEFAULT '',
    owner_guild_level INTEGER NOT NULL DEFAULT 0, -- unionLevel，客户端确实读
    defense_value  INTEGER NOT NULL DEFAULT 0,
    capture_times  INTEGER NOT NULL DEFAULT 0,   -- occupyNum，**连续**占领数，被攻下清零
    last_capture_time INTEGER NOT NULL DEFAULT 0,
    round          INTEGER NOT NULL DEFAULT 0,
    data_json      TEXT    NOT NULL DEFAULT '{}'
);
CREATE INDEX idx_city_owner ON guild_city(server_id, owner_guild_id);

-- 城池报名 / 竞标（applyUnionCity / userApplyUnionCity）
CREATE TABLE guild_city_apply (
    apply_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    city_id     INTEGER NOT NULL REFERENCES guild_city(city_id) ON DELETE CASCADE,
    guild_id    INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    apply_type  INTEGER NOT NULL DEFAULT 0,      -- 军团竞标 / 团员报名
    bid_wealth  INTEGER NOT NULL DEFAULT 0,      -- 客户端字段 wealth：竞标排序依据
    bid_rank    INTEGER NOT NULL DEFAULT 0,      -- 1守方 2攻1 3攻2
    is_winner   INTEGER NOT NULL DEFAULT 0,      -- winner/loserUnionCityApply 依据
    apply_time  INTEGER NOT NULL,
    UNIQUE (city_id, guild_id)
);
-- ⚠️ sharkUnionCityApply 至少要有 1 个元素（[1] 必须是防守方，NPC 也占位）；
--    winnerUnionCityApply / loserUnionCityApply 要发**空数组**而不是 nil。

-- 军团战战斗记录 / 战报（getUnionBattlefieldReport / getGvgBattleResultDetail）
CREATE TABLE guild_battle_report (
    report_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id      INTEGER NOT NULL DEFAULT 1,
    round          INTEGER NOT NULL DEFAULT 0,
    city_id        INTEGER NOT NULL DEFAULT 0,
    attack_guild_id INTEGER NOT NULL DEFAULT 0,
    attack_union_name TEXT NOT NULL DEFAULT '',
    defense_guild_id INTEGER NOT NULL DEFAULT 0,
    defense_union_name TEXT NOT NULL DEFAULT '',
    win            INTEGER NOT NULL DEFAULT 0,
    -- 客户端硬读 data.sharkUnionBattlefieldReport（BattleScene.lua:128-133），
    -- 而原厂 DSL 注释写的是 battleReport —— 组装时**两个 key 都发**。
    report_json    TEXT    NOT NULL DEFAULT '{}',
    create_time    INTEGER NOT NULL
);
CREATE INDEX idx_guild_report ON guild_battle_report(server_id, round, city_id);

-- 军团战阵型：按「城池 × 阵位」存（getUnionFormation 的入参是 unionCityId）
CREATE TABLE guild_formation_slot (
    city_id            INTEGER NOT NULL,
    guild_id           INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    slot               TEXT    NOT NULL,          -- forward / head / middle / tail
    slot_index         INTEGER NOT NULL,
    player_id          INTEGER NOT NULL,
    user_name          TEXT    NOT NULL DEFAULT '',   -- userName（注意不是 nickName）
    main_card_meata_id INTEGER NOT NULL DEFAULT 0,    -- mainCardMeataId（照抄原厂拼写）
    gem_inspire_num    INTEGER NOT NULL DEFAULT 0,    -- 该成员在这座城池的金币鼓舞次数
    PRIMARY KEY (city_id, guild_id, slot, slot_index)
);

-- 阵型军团级数据（gem_inspire_num 在这里是军团总数，与成员级同名不同义）
CREATE TABLE guild_formation_team (
    city_id         INTEGER NOT NULL,
    guild_id        INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    gem_inspire_num INTEGER NOT NULL DEFAULT 0,
    version         INTEGER NOT NULL DEFAULT 0,
    update_time     INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (city_id, guild_id)
);

-- 军团积分（getCrossGvgGroupTop10Score / getUnionMonsterRank / 建设积分）
CREATE TABLE guild_score (
    guild_id   INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    score_type TEXT    NOT NULL,                 -- gvg_group / monster_rank / construct ...
    round      INTEGER NOT NULL DEFAULT 0,
    score      INTEGER NOT NULL DEFAULT 0,
    update_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (guild_id, score_type, round)
);


-- ---------------------------------------------------------------- 跨服军团战
-- 现有服务端完全没有这一块，但客户端有 20+ 个接口在读
-- （struct_union.md §20-§25）。

-- 服务器分组（getCrossGvgGroupInfo.serverIds[]）
CREATE TABLE cross_gvg_group (
    group_id   INTEGER NOT NULL,
    server_id  INTEGER NOT NULL,
    version    INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (group_id, server_id)
);

-- 军团 / 个人报名（getCrossGvgInfoBase）
CREATE TABLE cross_gvg_apply (
    guild_id      INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    version       INTEGER NOT NULL DEFAULT 0,
    union_applied INTEGER NOT NULL DEFAULT 0,
    applied_num   INTEGER NOT NULL DEFAULT 0,
    quit_num      INTEGER NOT NULL DEFAULT 0,
    out_status    INTEGER NOT NULL DEFAULT 0,    -- 客户端 `out` 枚举
    promotion     INTEGER NOT NULL DEFAULT 0,
    update_time   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (guild_id, version)
);

-- 小组赛积分（CrossGVGScoreInfo）
CREATE TABLE cross_gvg_score (
    guild_id   INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    version    INTEGER NOT NULL DEFAULT 0,
    score      INTEGER NOT NULL DEFAULT 0,
    rank       INTEGER NOT NULL DEFAULT 0,
    union_name TEXT    NOT NULL DEFAULT '',      -- 快照
    update_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (guild_id, version)
);
CREATE INDEX idx_cross_score ON cross_gvg_score(version, score);

-- 跨服阵型镜像（signs[].position / exchangeGvgFormation）
CREATE TABLE cross_gvg_formation (
    guild_id          INTEGER NOT NULL REFERENCES guild(guild_id) ON DELETE CASCADE,
    version           INTEGER NOT NULL DEFAULT 0,
    player_id         INTEGER NOT NULL,
    position          INTEGER NOT NULL DEFAULT 0,  -- 1 / 10-19 / 20-29 / 30-39
    main_card_meta_id INTEGER NOT NULL DEFAULT 0,  -- 这里是 mainCardMetaId（与阵型成员不同）
    user_name         TEXT    NOT NULL DEFAULT '',
    PRIMARY KEY (guild_id, version, player_id)
);

-- 小组赛 / 淘汰赛战报（GVGReport / CrossGvgResultOutline）
CREATE TABLE cross_gvg_report (
    report_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    version         INTEGER NOT NULL DEFAULT 0,
    round_type      INTEGER NOT NULL DEFAULT 0,   -- 16/8/4/third/champion/group
    att_guild_id    INTEGER NOT NULL DEFAULT 0,
    att_server_id   INTEGER NOT NULL DEFAULT 0,
    att_union_name  TEXT    NOT NULL DEFAULT '',
    def_guild_id    INTEGER NOT NULL DEFAULT 0,
    def_server_id   INTEGER NOT NULL DEFAULT 0,
    def_union_name  TEXT    NOT NULL DEFAULT '',
    win             INTEGER NOT NULL DEFAULT 0,
    report_json     TEXT    NOT NULL DEFAULT '{}',
    create_time     INTEGER NOT NULL
);
CREATE INDEX idx_cross_report ON cross_gvg_report(version, round_type);

-- 祝福 / 至尊帝王（getCrossGVGBlessInfo）
CREATE TABLE cross_gvg_bless (
    version         INTEGER PRIMARY KEY,
    king_uid        INTEGER NOT NULL DEFAULT 0,
    king_player_id  INTEGER NOT NULL DEFAULT 0,
    king_union_name TEXT    NOT NULL DEFAULT '',
    king_server_id  INTEGER NOT NULL DEFAULT 0,
    king_nickname   TEXT    NOT NULL DEFAULT '',
    king_main_card_meta_id INTEGER NOT NULL DEFAULT 0,
    bless_num       INTEGER NOT NULL DEFAULT 0,
    can_bless_times INTEGER NOT NULL DEFAULT 0,
    update_time     INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE cross_gvg_bless_log (
    log_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    version     INTEGER NOT NULL DEFAULT 0,
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    reward_json TEXT    NOT NULL DEFAULT '[]',
    create_time INTEGER NOT NULL
);

-- ============================================================================
--  十一、竞技 / PK / 排行榜
-- ============================================================================

CREATE TABLE arena_rank (
    player_id     INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    server_id     INTEGER NOT NULL DEFAULT 1,
    score         INTEGER NOT NULL DEFAULT 0,
    rank          INTEGER NOT NULL DEFAULT 0,
    win_count     INTEGER NOT NULL DEFAULT 0,
    lose_count    INTEGER NOT NULL DEFAULT 0,
    last_match_time INTEGER NOT NULL DEFAULT 0,
    data_json     TEXT    NOT NULL DEFAULT '{}'
);
CREATE INDEX idx_arena_rank ON arena_rank(server_id, score DESC);

-- PK 记录（challengePkUser / getPkFoes）
CREATE TABLE pk_record (
    record_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id    INTEGER NOT NULL DEFAULT 1,
    attacker_uid INTEGER NOT NULL,
    defender_uid INTEGER NOT NULL,
    win          INTEGER NOT NULL DEFAULT 0,
    record_json  TEXT    NOT NULL DEFAULT '{}',
    create_time  INTEGER NOT NULL
);
CREATE INDEX idx_pk_attacker ON pk_record(attacker_uid, create_time);

-- 通用排行榜。排行榜条目全部是「一次算好、整块下发」的展示数据，
-- 所以整块 JSON 存储 + 数值列用于排序。
CREATE TABLE rank_board (
    board_key   TEXT    NOT NULL,        -- arena / cross_pvp / balloon / level_race / treasurebox ...
    server_id   INTEGER NOT NULL DEFAULT 1,
    round       INTEGER NOT NULL DEFAULT 0,
    rank        INTEGER NOT NULL,
    player_id   INTEGER NOT NULL DEFAULT 0,
    score       INTEGER NOT NULL DEFAULT 0,
    entry_json  TEXT    NOT NULL DEFAULT '{}',
    update_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (board_key, server_id, round, rank)
);
CREATE INDEX idx_rank_player ON rank_board(board_key, server_id, round, player_id);


-- ============================================================================
--  十二、支付 / 订单
-- ============================================================================

-- 充值订单（validatePaymentOrder）
CREATE TABLE payment_order (
    order_id     TEXT    PRIMARY KEY,        -- 客户端传上来的 orderId
    player_id    INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    product_id   TEXT    NOT NULL,           -- he_gold_60 / he_gold_300 ...
    gold_num     INTEGER NOT NULL DEFAULT 0,
    recharge_gems INTEGER NOT NULL DEFAULT 0,
    free_gems    INTEGER NOT NULL DEFAULT 0,
    amount_fen   INTEGER NOT NULL DEFAULT 0, -- 金额（分），仅记录
    status       INTEGER NOT NULL DEFAULT 0, -- 0待校验 1成功 2失败 3已发货
    channel      TEXT    NOT NULL DEFAULT '',
    create_time  INTEGER NOT NULL,
    finish_time  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_order_player ON payment_order(player_id, create_time);

-- 充值流水（发货审计，防重复发钻石）
CREATE TABLE charge_log (
    log_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id    INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    order_id     TEXT    NOT NULL DEFAULT '',
    product_id   TEXT    NOT NULL DEFAULT '',
    recharge_gems INTEGER NOT NULL DEFAULT 0,
    free_gems    INTEGER NOT NULL DEFAULT 0,
    source       TEXT    NOT NULL DEFAULT '',  -- iap / phone / gm
    create_time  INTEGER NOT NULL
);
CREATE INDEX idx_charge_player ON charge_log(player_id, create_time);

-- 话费充值（phoneChargeSetNum / phoneChargeGetInfo / phoneChargeGain）
CREATE TABLE phone_charge (
    player_id    INTEGER PRIMARY KEY REFERENCES player(player_id) ON DELETE CASCADE,
    phone_num    TEXT    NOT NULL DEFAULT '',
    set_num_time INTEGER NOT NULL DEFAULT 0,
    total_amount INTEGER NOT NULL DEFAULT 0,
    last_gain_time INTEGER NOT NULL DEFAULT 0
);


-- ============================================================================
--  十三、全局 / 运营
-- ============================================================================

-- 选服表（serverPartitionConfig，登录页「1区 本地测试服 正常」）
CREATE TABLE server_partition (
    server_id    INTEGER PRIMARY KEY,
    server_name  TEXT    NOT NULL,
    status       INTEGER NOT NULL DEFAULT 0,   -- 0正常 1维护 2爆满
    recommend    INTEGER NOT NULL DEFAULT 0,
    open_time    INTEGER NOT NULL DEFAULT 0,
    sort_order   INTEGER NOT NULL DEFAULT 0
);

-- 抽卡记录（保底计算、客服查询、概率审计）
CREATE TABLE gacha_log (
    log_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    gacha_id    INTEGER NOT NULL,
    gacha_type  TEXT    NOT NULL DEFAULT '',   -- normal / free / box / treasure
    times       INTEGER NOT NULL DEFAULT 1,
    results_json TEXT   NOT NULL DEFAULT '[]',
    create_time INTEGER NOT NULL
);
CREATE INDEX idx_gacha_player ON gacha_log(player_id, gacha_id);

-- 奖励发放流水。出问题时这是唯一能证明「我确实发过」的东西。
CREATE TABLE reward_log (
    log_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    reason      TEXT    NOT NULL DEFAULT '',   -- 哪个接口/哪次活动
    item_type   INTEGER NOT NULL,
    meta_id     INTEGER NOT NULL DEFAULT 0,
    amount      INTEGER NOT NULL DEFAULT 0,
    create_time INTEGER NOT NULL
);
CREATE INDEX idx_reward_player ON reward_log(player_id, create_time);

-- 公告（getAnnouncementInfo）
CREATE TABLE announcement (
    announce_id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id   INTEGER NOT NULL DEFAULT 0,   -- 0 = 全服
    title       TEXT    NOT NULL DEFAULT '',
    content     TEXT    NOT NULL DEFAULT '',
    start_time  INTEGER NOT NULL DEFAULT 0,
    end_time    INTEGER NOT NULL DEFAULT 0,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    enabled     INTEGER NOT NULL DEFAULT 1
);

-- 系统邮件模板。**注意：这不是服务端自用的配置表，而是随 `getUserEmails`
-- 一起下发的模板数组**（客户端字段 `sysEmailMeta[]`）。mail.meta_id ↔ 这里的
-- meta_id（客户端字段名是 `id`）。一旦开始下发 sysEmails 就必须同步下发它，
-- 否则邮件列表全是空白行；且 `contentText` 缺失会让客户端 gsub(nil) 直接崩。
-- （独立接口 `getSysEmailMeta` 在本包里零调用点，是死代码。）
CREATE TABLE sys_email_meta (
    meta_id        INTEGER PRIMARY KEY,        -- 客户端字段 `id`
    title_text     TEXT    NOT NULL DEFAULT '',-- titleText（本地化 key 或文案）
    content_text   TEXT    NOT NULL DEFAULT '',-- contentText（**必填**）
    contain_reward INTEGER NOT NULL DEFAULT 0, -- containReward
    reward_json    TEXT    NOT NULL DEFAULT '[]',
    expire_days    INTEGER NOT NULL DEFAULT 30,
    enabled        INTEGER NOT NULL DEFAULT 1
);

-- 维护项（getMaintenanceMeta.maintenanceItem）
CREATE TABLE maintenance_item (
    item_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    item_type   INTEGER NOT NULL DEFAULT 0,
    title       TEXT    NOT NULL DEFAULT '',
    content     TEXT    NOT NULL DEFAULT '',
    start_time  INTEGER NOT NULL DEFAULT 0,
    end_time    INTEGER NOT NULL DEFAULT 0,
    enabled     INTEGER NOT NULL DEFAULT 1
);

-- 封禁 / 禁言（getUserBanInfo.noChatEndSeconds 走 player 列，这里存历史）
CREATE TABLE ban_record (
    ban_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id   INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE,
    ban_type    INTEGER NOT NULL DEFAULT 0,   -- 0禁言 1封号
    reason      TEXT    NOT NULL DEFAULT '',
    start_time  INTEGER NOT NULL,
    end_time    INTEGER NOT NULL DEFAULT 0,   -- 0 = 永久
    operator    TEXT    NOT NULL DEFAULT ''
);

-- 未识别请求落盘（替代现在的 rpc_payloads.jsonl，方便继续补端点）
CREATE TABLE unknown_rpc (
    log_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id   INTEGER NOT NULL DEFAULT 0,
    method      TEXT    NOT NULL,
    params_json TEXT    NOT NULL DEFAULT '{}',
    create_time INTEGER NOT NULL
);
CREATE INDEX idx_unknown_method ON unknown_rpc(method, create_time);


-- ============================================================================
--  十四、常用视图：把「当前生效阵容」摊平成客户端要的形状
-- ============================================================================

-- 当前阵容成员（供 getPlayerTeamInfo / gameInit 组装用）
-- 注意宝物 id 是 LEFT JOIN 出来的（player_card 上没有 treasure_id 列）
CREATE VIEW v_active_battle_queue AS
SELECT s.player_id,
       s.array_id,
       s.slot,
       s.card_id,
       COALESCE(t.treasure_id, 0) AS treasure_id,
       c.meta_id,
       c.level,
       c.exp,
       c.card_group_id
FROM player_battle_slot s
JOIN player_battle_array a
  ON a.player_id = s.player_id AND a.array_id = s.array_id AND a.is_active = 1
LEFT JOIN player_card c ON c.card_id = s.card_id
LEFT JOIN player_treasure t ON t.player_id = s.player_id AND t.card_id = s.card_id;

-- 卡牌 → 已穿戴装备（组装 sharkCard.equipIds 用）
CREATE VIEW v_card_equips AS
SELECT player_id, card_id, equip_id
FROM player_equip
WHERE card_id > 0;

-- 卡牌 → 已装备元神（组装 sharkCard.cardSpirits 用）
CREATE VIEW v_card_spirits AS
SELECT player_id, card_id, spirit_id
FROM player_spirit
WHERE card_id > 0;

-- ============================================================================
--  END
-- ============================================================================
