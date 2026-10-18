-- 单机版战斗：把 server/services/battle.py 的模型翻成 Lua
--
-- 数据来源全部在客户端本地：
--   * 我方：`MetaManager.card_meta` + 玩家卡（从 gameInit 快照里取）
--   * 敌方：`MetaManager.battle_event_battle` → monsterGroupId → `battle_monster_group`
--           → `battle_monster`（reviseHP/reviseATT/reviseDEF 就是绝对值）
--   * 技能：`skill_meta[skillId].statusIdList` → `skill_status[id]`
--           （prob / impactAttr 1攻2防3血 / valueType 1百分比2绝对值 / effectValue）
--   * 伤害：抓包只给了两条样本 → 伤害 ≈ 有效攻击 × 0.9~1.1，防御用递减式减伤
--           （与 work/DAMAGE_MODEL.md 一致）
--
-- 输出与真实服务端同形状：
--   {retCode=200, win=bool, leftHpRate=int, qte=true, rewards={},
--    cardInitDatas={...}, eventFlow={...}, encounterMultiPlayerBoss=false}

local Single = require('canon.single.main')

local B = {}

local CURVE = {
    dmg_lo = 0.90, dmg_hi = 1.10,
    crit_base = 0.05, crit_mul = 1.60,
    block = 0.50, max_mit = 0.70,
}

local function cfg(name)
    local t = MetaManager and MetaManager[name]
    return t or {}
end

local function num(v, d)
    v = tonumber(v)
    if v == nil then
        return d or 0
    end
    return v
end

-- 配置行取值：兼容「按 id 索引的 dict」和「数组」
local function row(tab, key)
    if type(tab) ~= 'table' then
        return nil
    end
    local r = tab[key]
    if type(r) == 'table' then
        return r
    end
    for _, v in pairs(tab) do
        if type(v) == 'table' and num(v.id or v.monsterGroupId or v.eventId, -1) == num(key, -2) then
            return v
        end
    end
    return nil
end

-- ---------------------------------------------------------------- 我方
local function my_cards()
    local data = package.loaded['canon.single.proto_data'] or {}
    local init = data['gameInit'] or {}
    local cards = {}
    local sc = init['sharkCards'] or {}
    local list = sc['sharkCards'] or sc
    for _, c in pairs(list) do
        if type(c) == 'table' and num(c.cardId) > 0 then
            cards[#cards + 1] = c
        end
    end
    table.sort(cards, function(a, b) return num(a.cardId) < num(b.cardId) end)
    -- 出战队列
    local arr = init['sharkUserBattleArray'] or {}
    local queue = arr['sharkUserBattleArray'] or arr['parts'] or arr
    local out = {}
    local wanted = {}
    for _, p in pairs(queue) do
        if type(p) == 'table' then
            for _, cid in pairs(p.cardIds or p) do
                if tonumber(cid) then
                    wanted[tonumber(cid)] = true
                end
            end
        end
    end
    for _, c in ipairs(cards) do
        if next(wanted) == nil or wanted[num(c.cardId)] then
            out[#out + 1] = c
            if #out >= 5 then break end
        end
    end
    if #out == 0 then
        for i = 1, math.min(4, #cards) do
            out[i] = cards[i]
        end
    end
    return out
end

-- 卡 → 面板属性（客户端 MetaManager 里的卡没有算装备，这里只用基础值）
local function card_stats(c)
    local meta = cfg('card_meta')[num(c.metaId)] or {}
    local lv = num(c.level, 1)
    local rare = cfg('card_rare')[num(meta.rare, 1)] or {}
    local evo = cfg('card_evolve')[num(meta.evolutionLevel, 1)] or {}
    local lvc = cfg('card_level')[lv] or {}
    local coef = num(lvc.levelCoefficient, 0)
    local function stat(init, rev, rareKey, evoKey)
        return math.floor(num(meta[init]) + coef * num(meta[rev])
            * num(rare[rareKey], 1) * num(evo[evoKey], 1))
    end
    return {
        att = math.max(1, stat('initAtt', 'reviseATT', 'basicAttack', 'reviseAttack')),
        def = math.max(0, stat('initDef', 'reviseDEF', 'basicDefence', 'reviseDefence')),
        hp = math.max(1, stat('initHp', 'reviseHP', 'basicHP', 'reviseHp')),
    }
end

-- ---------------------------------------------------------------- 敌方
local function enemy_units(mission_id, battle_type)
    local ev = row(cfg('battle_event_battle'), mission_id)
    if not ev then
        return {}
    end
    local gid = num(ev.monsterGroupId)
    local group = row(cfg('battle_monster_group'), gid) or {}
    local ids = group.monsterIds or group.monsters or group
    local revise = num(ev.monsterRevise, 1)
    local lvl = num(ev.monsterLevel, 1)
    local out = {}
    local idx = 0
    for _, mid in pairs(ids) do
        if tonumber(mid) then
            local mon = row(cfg('battle_monster'), tonumber(mid))
            if mon then
                idx = idx + 1
                out[idx] = {
                    posId = 10000 + idx,
                    cardId = 90000 + idx - 1,
                    metaId = num(mon.cardId),
                    level = lvl, exp = 0,
                    hp = math.max(1, math.floor(num(mon.reviseHP) * revise)),
                    att = math.max(1, math.floor(num(mon.reviseATT) * revise)),
                    def = math.max(0, math.floor(num(mon.reviseDEF) * revise)),
                }
                if idx >= 5 then break end
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------- 技能
local function skill_effects(meta_id)
    local meta = cfg('card_meta')[num(meta_id)] or {}
    local out = {}
    local st = cfg('skill_status')
    for _, sk in pairs({meta.skill, meta.mainSkill,
                        meta.groupSkill1, meta.groupSkill2}) do
        local sid = num(sk)
        if sid > 0 then
            local sm = row(cfg('skill_meta'), sid)
            local list = sm and tostring(sm.statusIdList or '') or ''
            for part in string.gmatch(list, '[^|]+') do
                local id = tonumber(part)
                local s = id and st[id]
                if s and num(s.impactAttr) >= 1 and num(s.impactAttr) <= 3 then
                    out[#out + 1] = {
                        skillId = sid,
                        prob = num(s.prob, 0),
                        attr = num(s.impactAttr),
                        vtype = num(s.valueType, 2),
                        value = num(s.effectValue, 0),
                    }
                end
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------- 主流程
function B.run(params)
    Single.log('battle.run ' .. tostring(params and params.missionId))
    local mission_id = num(params and params.missionId, 100101)
    local battle_type = num(params and params.battleType, 1)

    local units = {}
    local allies = {}
    for i, c in ipairs(my_cards()) do
        local st = card_stats(c)
        local u = {posId = i, cardId = num(c.cardId), metaId = num(c.metaId),
                   level = num(c.level, 1), exp = num(c.exp),
                   hp = st.hp, att = st.att, def = st.def}
        allies[#allies + 1] = u
        units[#units + 1] = u
    end
    local enemies = enemy_units(mission_id, battle_type)
    for _, u in ipairs(enemies) do
        units[#units + 1] = u
    end
    if #allies == 0 or #enemies == 0 then
        Single.log('battle: no units (allies=' .. #allies .. ' enemies=' .. #enemies .. ')')
        return {retCode = 200, win = false, leftHpRate = 0, qte = true,
                rewards = {}, cardInitDatas = units, eventFlow = {},
                encounterMultiPlayerBoss = false}
    end

    local health = {}
    for _, u in ipairs(units) do
        health[u.posId] = u.hp
    end
    local events = {}

    local function living(team)
        local out = {}
        for _, u in ipairs(team) do
            if health[u.posId] > 0 then
                out[#out + 1] = u
            end
        end
        return out
    end

    local function mit(att, dfn)
        if dfn <= 0 then return 0 end
        local r = dfn / (dfn + att * 2 + 200)
        return math.min(CURVE.max_mit, r)
    end

    local skills = {}
    for _, u in ipairs(allies) do
        skills[u.posId] = skill_effects(u.metaId)
    end

    local ATTR = {[1] = 'att', [2] = 'def', [3] = 'hp'}
    local bonus = {}
    for _, u in ipairs(units) do
        bonus[u.posId] = {att = 0, def = 0, hp = 0}
    end

    local function fire_skills(rnd)
        for _, u in ipairs(living(allies)) do
            for _, sk in ipairs(skills[u.posId] or {}) do
                if sk.prob > 0 and math.random() < sk.prob then
                    local key = ATTR[sk.attr]
                    local base = u[key]
                    local d = sk.value
                    if sk.vtype ~= 2 then
                        d = math.floor(base * sk.value / 100)
                    end
                    d = math.floor(d)
                    if d ~= 0 then
                        bonus[u.posId][key] = bonus[u.posId][key] + d
                        events[#events + 1] = {
                            eventType = 102, round = rnd, actionType = 0,
                            battleCardActs = {{posId = u.posId, skillId = sk.skillId,
                                               effectId = sk.attr, changedValue = math.abs(d)}},
                        }
                    end
                end
            end
        end
    end

    local max_rounds = 20
    local rnd = 0
    while rnd < max_rounds do
        fire_skills(rnd)
        local acted = false
        local turns = math.max(#allies, #enemies)
        for t = 0, turns - 1 do
            for action = 0, 1 do
                local actors = living(action == 0 and allies or enemies)
                local targets = living(action == 1 and allies or enemies)
                if #actors > 0 and #targets > 0 then
                    local actor = actors[(t % #actors) + 1]
                    local target = targets[(t % #targets) + 1]
                    local aatt = actor.att + bonus[actor.posId].att
                    local ddef = target.def + bonus[target.posId].def
                    local etype, dmg = 0, 0
                    -- 未命中
                    if math.random() < 0.03 then
                        etype = 2
                    else
                        dmg = aatt * (CURVE.dmg_lo + math.random() * (CURVE.dmg_hi - CURVE.dmg_lo))
                        dmg = dmg * (1 - mit(aatt, ddef))
                        if math.random() < CURVE.crit_base then
                            dmg = dmg * CURVE.crit_mul
                            etype = 1
                        elseif math.random() < 0.10 then
                            dmg = dmg * CURVE.block
                            etype = 4
                        end
                        dmg = math.max(1, math.floor(dmg))
                        local tpos = target.posId
                        health[tpos] = health[tpos] - math.min(dmg, health[tpos])
                    end
                    events[#events + 1] = {
                        eventType = etype, round = rnd, actionType = action,
                        battleCardActs = {{posId = target.posId, skillId = 0,
                                           effectId = 6, changedValue = dmg}},
                    }
                    acted = true
                end
            end
        end
        if #living(allies) == 0 or #living(enemies) == 0 then
            break
        end
        if not acted then
            break
        end
        rnd = rnd + 1
    end

    local alive_allies = living(allies)
    local win = (#alive_allies > 0) and (#living(enemies) == 0)
    local sum, maxsum = 0, 0
    for _, u in ipairs(allies) do
        sum = sum + health[u.posId]
        maxsum = maxsum + u.hp
    end
    local left = maxsum > 0 and math.floor(100 * sum / maxsum) or 0

    Single.log(string.format('battle done win=%s left=%d events=%d',
                             tostring(win), left, #events))
    return {retCode = 200, win = win, leftHpRate = left, qte = true,
            rewards = {}, cardInitDatas = units, eventFlow = events,
            encounterMultiPlayerBoss = false}
end

return B
