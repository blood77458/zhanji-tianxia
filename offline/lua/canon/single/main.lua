-- 单机版服务端入口（纯 Lua）
--
-- 思路：拦截 `RpcTransponder:call(endpoint, data, handler)`。
-- 这一层收到的 `data` 已经是**明文 Lua 表**（AMF3/zlib/XOR 是更下面才做的），
-- 所以整个编解码层都不用实现，直接把服务端的应答表交给 handler 即可。
--
-- 应答表形状与真实服务端一致：{ retCode = 200, <业务字段...> }
-- 派发规则逐字对齐 hecore/rpc.lua 第 442-503 行（请求自带 handler → 全局 handlerRegistry）。

local Single = {}

print('[SINGLE] main.lua loaded')

Single.enabled = true
Single.verbose = true
Single.handlers = {}

-- 用 print 而不是 he_log_info：实测 he_log_info 不进 logcat，print 会带 [LUA-print] 出来
local function log(msg)
    print('[SINGLE] ' .. tostring(msg))
end

Single.log = log

-- ---------------------------------------------------------------- 注册/派发
function Single.register(name, fn)
    Single.handlers[name] = fn
end

function Single.dispatch(endpoint, params)
    local fn = Single.handlers[endpoint]
    if fn then
        local ok, resp = pcall(fn, params or {})
        if ok and type(resp) == 'table' then
            return resp
        end
        log('handler failed ' .. tostring(endpoint) .. ': ' .. tostring(resp))
        return {retCode = 200}
    end
    if Single.verbose then
        log('unhandled ' .. tostring(endpoint))
    end
    return {retCode = 200}
end

-- 下一帧再回调：调用方通常刚发出请求就继续往下走，
-- 同步回调会在它返回前重入，容易踩到半初始化状态。
local function defer(fn)
    local ok = pcall(function()
        local scene = CCDirector:sharedDirector():getRunningScene()
        if not scene then
            return false
        end
        local acts = CCArray:create()
        acts:addObject(CCDelayTime:create(0))
        acts:addObject(CCCallFuncN:create(function() fn() end))
        scene:runAction(CCSequence:create(acts))
        return true
    end)
    if not ok then
        fn()
    end
end

-- ---------------------------------------------------------------- 结果投递
function Single.deliver(transponder, endpoint, resp, handler)
    local payload = resp or {}
    local code = tonumber(payload.retCode) or 200
    payload.method = nil
    payload.retCode = nil
    payload.extraMsg = nil

    local stop = false
    if handler then
        local t = type(handler)
        if t == 'function' then
            stop = handler(endpoint, payload, code ~= 200 and code or nil)
        elseif t == 'table' then
            if code ~= 200 then
                local eh = handler['error'] or handler[code]
                if eh then
                    stop = eh(endpoint, code)
                end
            else
                local ch = handler['complete']
                if ch then
                    stop = ch(endpoint, payload)
                end
            end
        end
    end
    if stop then
        return
    end

    local registry = transponder and transponder.processor
                     and transponder.processor.handlerRegistry
    if not registry then
        return
    end
    if code ~= 200 then
        local hs = registry[tostring(code)]
                or registry[tostring(InternalError and InternalError.kDefaultError or 0)]
        if hs then
            for _, h in ipairs(hs) do
                h:handleError({endpoint}, code)
            end
        end
    else
        local hs = registry[endpoint]
        if hs then
            for _, h in ipairs(hs) do
                h:handleResponse(endpoint, payload)
            end
        end
    end
end

-- ---------------------------------------------------------------- 入口
function Single.call(owner, endpoint, data, handler, priority, retry)
    local tp = owner
    if type(owner) == 'table' and owner.transponder then
        tp = owner.transponder          -- Communication 实例
    end
    local resp = Single.dispatch(endpoint, data)
    defer(function()
        Single.deliver(tp, endpoint, resp, handler)
    end)
end

-- 本地合成的 /systemInfo 结构（对应真实服务端那个二进制响应）。
-- 客户端 LoginScene 只在拿到表之后取 .ts / .systemConf / .serverPartitionConfig，
-- 所以直接给表就能跳过那次 HTTP 请求。
function Single.system_info()
    return {
        ts = os.time(),
        cleanVersion = false,
        systemConf = {
            serverMergeConfig = {enable = false, gameDomain = '', serverOffset = 0},
            maintenanceFeatures = {},
        },
        serverPartitionConfig = {
            runningServers = {{
                serverId = 1, serverName = '本地测试服', enable = true,
                beginTime = '0', serverBusy = 100000, serverNormal = 50000,
                newServer = true, whiteAccountIds = '',
            }},
            preparedServers = {},
        },
        serverStatuses = {{serverId = 1, amount = 1}},
    }
end

-- 供 handler 脚本自己用：深拷贝、安全取数
function Single.copy(t)
    if type(t) ~= 'table' then
        return t
    end
    local out = {}
    for k, v in pairs(t) do
        out[k] = Single.copy(v)
    end
    return out
end

function Single.num(v, default)
    v = tonumber(v)
    if v == nil then
        return default or 0
    end
    return v
end

-- 先把模块登记进 package.loaded，否则 handler 文件里 require 本模块会死循环
package.loaded['canon.single.main'] = Single

-- 载入各业务 handler（一个文件一类，按需加）
local modules = {
    'canon.single.handlers_core',
}
for _, name in ipairs(modules) do
    local ok, err = pcall(require, name)
    if not ok then
        log('load ' .. name .. ' failed: ' .. tostring(err))
    end
end

local count = 0
for _ in pairs(Single.handlers) do
    count = count + 1
end
log('single-player server ready, handlers=' .. tostring(count))

return Single
