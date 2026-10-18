-- 单机版：核心端点（登录 / 主界面 / 地图事件 / 战斗）
--
-- S1 的做法是「静态快照」：`scripts/gen_proto_snapshot.py` 在服务端按方法名
-- dispatch 出响应（`work/proto_capture/*.json`），`scripts/gen_proto_lua.py`
-- 再把它们转成 `canon/single/proto_data.lua`。这里把这些方法逐个注册成 handler。
--
-- ⚠️ 本文件只能有一个 `return M`，且必须是最后一条语句。
--    （曾经因为插入代码多出一个 return，导致整个模块语法错误、静默加载失败，
--     表现为 login/loginServer 全变成 unhandled。）

local Single = require('canon.single.main')

local M = {}

-- ---------------------------------------------------------------- 静态快照
local ok, data = pcall(require, 'canon.single.proto_data')
if not ok or type(data) ~= 'table' then
    Single.log('proto_data load failed: ' .. tostring(data))
    data = {}
end

-- 深拷贝：客户端会就地改这些表（比如往列表里插东西），模板不能被动过
local function copy(v)
    if type(v) ~= 'table' then
        return v
    end
    local out = {}
    for k, vv in pairs(v) do
        out[k] = copy(vv)
    end
    return out
end

local snapshot_count = 0
for method, payload in pairs(data) do
    Single.register(method, function()
        return copy(payload)
    end)
    snapshot_count = snapshot_count + 1
end
Single.log('snapshot handlers registered: ' .. tostring(snapshot_count))

-- ---------------------------------------------------------------- 动态方法
-- 时间戳必须每次给当前时间，否则客户端的体力/冷却判断会错乱
Single.register('getServerTimeStamp', function()
    return {retCode = 200, ts = os.time()}
end)

-- 地图事件族：客户端会**直接索引** `rewards`（ChapterMapScene:2064），
-- 只回 retCode=200 会崩在 `attempt to index field 'rewards' (a nil value)`。
for _, name in ipairs({'triggerCoinEvent', 'triggerExpEvent', 'triggerRandomEvent',
                       'triggerCardEvent', 'triggerPropEvent'}) do
    Single.register(name, function(params)
        -- ⚠️ rewards **不能为空**：ChapterMapScene:2064 直接取 rewards[1].amount
        --    （空表 -> attempt to index a nil value -> 闪退）
        return {retCode = 200,
                rewards = {{metaId = 400001, amount = 100}},
                coins = 0, exp = 0, eventType = 0, eventId = 0,
                encounterMultiPlayerBoss = false,
                missionId = (params and params.missionId) or 0}
    end)
end
Single.log('map event handlers registered')

-- 战斗：真实生成事件流（快照只能重复同一场）
local ok_battle, Battle = pcall(require, 'canon.single.battle')
if ok_battle and type(Battle) == 'table' then
    Single.register('triggerBattleEvent', function(params)
        return Battle.run(params)
    end)
    Single.log('battle handlers registered')
else
    Single.log('battle.lua load failed: ' .. tostring(Battle))
end

return M
