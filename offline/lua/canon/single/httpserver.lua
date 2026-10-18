-- 单机版：APK 内的极小 HTTP 服务
--
-- 只干一件事：应答 native 层的资源检查
--     GET /staticVersion?clientVersion=..&releaseVersion=..&platform=..&debugVersion=..
-- 回包必须满足：
--     config_md5 == APK 里 static_config.<md5>.xml 的 md5
--     need_download = false
-- 这样客户端就不会去下载任何资源（实测下载请求为 0 次）。
--
-- 实现要点：
--   * 用 luajava 起 java.net.ServerSocket（客户端自己也在用 luajava，可用）；
--   * **不创建 Java 线程**：ServerSocket 设 setSoTimeout(2)，
--     每帧在主线程里试一次 accept，超时抛异常被 pcall 吃掉。
--     Lua 状态只在主线程碰，安全。
--   * 业务请求（/protocol）不走这里 —— 已经被 canon/single/main.lua 在
--     Communication:request 层拦截了。

local Http = {}

Http.files = {}

local write_file, writable_dir, hex2bytes

Http.port = 18080
Http.enabled = false
Http.manifestMd5 = '81c8ede8d76998cd852173d537c04aac'   -- APK 内 static_config 的 md5

local function log(msg)
    print('[SINGLE-HTTP] ' .. tostring(msg))
end

Http.log = log

local function body_for_static_version(host)
    if not host or host == '' then
        host = '127.0.0.1:' .. tostring(Http.port)
    end
    return string.format(
        '{"static_url_root":"http://%s/static/","config_md5":"%s",' ..
        '"need_download":false,"can_download":false,"download_url":"",' ..
        '"langs":["zh_CN"],"resolutions":["1280x720"],"ref":0}',
        host, Http.manifestMd5)
end

-- ---------------------------------------------------------------- 回放表
-- 登录链路上的「直连 HTTP」端点（/systemInfo、/sessionKey/init、/check/*、
-- /loginAccount/*、/mappingAccount）返回的是 AMF3+zlib+XOR 信封。
-- 这些应答与请求无关、是常量，所以用抓包回放，不在 Lua 里重写编码器。
local replay_hex = nil

local function replay_table()
    if replay_hex == nil then
        local ok, tbl = pcall(require, 'canon.single.http_replay')
        replay_hex = (ok and type(tbl) == 'table') and tbl or {}
        if not ok then
            log('http_replay load failed: ' .. tostring(tbl))
        end
    end
    return replay_hex
end

hex2bytes = function(hex)
    local out = {}
    for i = 1, #hex, 2 do
        out[#out + 1] = string.char(tonumber(string.sub(hex, i, i + 1), 16))
    end
    return table.concat(out)
end

local function replay_body(path)
    local tbl = replay_table()
    local hex = tbl[path]
    if hex then
        -- 落盘一次，之后热路径只做 Files.copy，不碰字节数组
        if not Http.files[path] then
            local ok, hex2 = pcall(hex2bytes, hex)
            if ok and hex2 then
                local name = string.gsub(path, '[^%w]', '_') .. '.bin'
                Http.files[path] = write_file(name, hex2)
            end
        end
        local bok, bytes = pcall(hex2bytes, hex)
        if bok and bytes then
            return bytes, true
        end
        return nil, false
    end
    return nil, false
end

-- 写响应：头用 PrintStream（纯 ASCII），**body 必须写原始字节**。
-- 踩过的坑：body 也走 PrintStream:print(string) 时，AMF3 里的 0x00 / >0x7F 字节
-- 会被字符集转换搞坏，客户端报
--     errorCode=18 "Transferred a partial file", bodyLength=0, httpCode=0
-- （头收到了、Content-Length 对，但 body 一个字节都没到）。
local function send(sock, text)
    local ok, err = pcall(function()
        local out = sock:getOutputStream()
        local ps = luajava.newInstance('java.io.PrintStream', out)
        ps:print(text)
        ps:flush()
        out:flush()
        ps:close()
    end)
    if not ok then
        log('send failed: ' .. tostring(err))
    end
end

-- 写响应：头用 PrintStream（纯 ASCII），body 用 **文件 + Files.copy** 流式写出。
--
-- 为什么这么绕：
--   1) body 走 PrintStream:print(string) 时，AMF3 里的 0x00 / >0x7F 字节会被字符集
--      转换搞坏，客户端报 errorCode=18 "Transferred a partial file", bodyLength=0
--      （头收到了、Content-Length 对，body 一个字节都没到）；
--   2) luajava.newArray 在本引擎的 LuaJ 里不存在；
--   3) ByteArrayOutputStream:write(int) / OutputStream:write(int) 都报
--      "Invalid method call. No such method." —— LuaJ 把 Lua number 当 double，匹配不上 int 重载。
-- 所以：先把字节落到可写目录的文件里，再用 java.nio.file.Files.copy(InputStream, OutputStream)
-- 整段拷到 socket。全程没有 int 参数。
writable_dir = function()
    if Http._dir then
        return Http._dir
    end
    local ok, p = pcall(function()
        return CCFileUtils:sharedFileUtils():getWritablePath()
    end)
    local dir = (ok and p or '/data/data/') .. 'single_http/'
    -- 目录必须先建出来，否则 io.open 会失败（Lua 不能建目录）
    pcall(function()
        local f = luajava.newInstance('java.io.File', dir)
        f:mkdirs()
    end)
    Http._dir = dir
    return dir
end

write_file = function(name, data)
    local path = writable_dir() .. name
    local f = io.open(path, 'wb')
    if not f then
        log('write_file FAILED: ' .. tostring(path))
        return nil
    end
    f:write(data)
    f:close()
    return path
end

local function is_ascii(s)
    for i = 1, #s do
        local b = string.byte(s, i)
        if b == 0 or b > 127 then
            return false
        end
    end
    return true
end

-- 写响应。ASCII（JSON/文本）走 PrintStream，已验证可靠；
-- 二进制 body 在这个 LuaJ 上发不出去：
--   luajava.newArray 不存在；ByteArrayOutputStream:write(int)/OutputStream:write(int)
--   报 Invalid method call；FileInputStream:readAllBytes 在 Android 12 没有（API 33 才有）；
--   Files.copy 静态调用报 Not a OO function call。
-- 所以二进制端点（/systemInfo 等）不走这条 HTTP，改成在客户端 Lua 里合成（见 STATUS_R4.md）。
local function send_parts(sock, head, body, filepath)
    local ok, err = pcall(function()
        local out = sock:getOutputStream()
        local ps = luajava.newInstance('java.io.PrintStream', out)
        ps:print(head)
        if body and #body > 0 then
            if is_ascii(body) then
                ps:print(body)
            else
                log('BINARY body not supported on this LuaJ, dropped ('
                    .. tostring(#body) .. ' bytes)')
            end
        end
        ps:flush()
        out:flush()
    end)
    if not ok then
        log('send_parts failed: ' .. tostring(err))
    end
end

local function handle(sock)
    -- 读请求行 + 头部（读到空行为止），并**把请求体读完**：
    -- HTTP/1.1 下不读 body 就回包并关连接，客户端会当成出错（实测会导致登录失败）。
    local reqLine = ''
    local host = ''
    local bodyLen = 0
    local ok = pcall(function()
        local ins = luajava.newInstance('java.io.BufferedReader',
            luajava.newInstance('java.io.InputStreamReader', sock:getInputStream()))
        reqLine = ins:readLine() or ''
        for _ = 1, 60 do
            local line = ins:readLine()
            if line == nil or line == '' then
                break
            end
            local h = string.lower(line)
            if string.sub(h, 1, 5) == 'host:' then
                host = string.gsub(string.sub(line, 6), '^%s+', '')
            elseif string.find(h, 'content-length:', 1, true) then
                bodyLen = tonumber(string.match(line, '(%d+)')) or 0
            end
        end
        if bodyLen > 0 then
            for _ = 1, bodyLen do
                if ins:read() == -1 then
                    break
                end
            end
        end
    end)
    if not ok then
        send(sock, 'HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\nConnection: close\r\n\r\n')
        pcall(function() sock:close() end)
        return
    end

    local path = string.match(reqLine or '', '^%a+%s+(%S+)') or '/'
    local method = string.match(reqLine or '', '^(%a+)') or '?'
    path = string.gsub(path, '%?.*$', '')
    log(method .. ' ' .. path .. (bodyLen > 0 and (' body=' .. bodyLen) or ''))

    local body, ctype, code
    local filepath = Http.files[path]
    if path == '/staticVersion' then
        body = body_for_static_version(host)
        ctype = 'application/json'
        code = '200 OK'
    elseif path == '/health' then
        body = '{"ok":true,"single":true}'
        ctype = 'application/json'
        code = '200 OK'
    else
        local rp
        rp, ok = replay_body(path)
        if rp then
            body = rp
            ctype = 'application/octet-stream'
            code = '200 OK'
            log('replay ' .. path .. ' (' .. tostring(#body) .. ' bytes)')
        else
            -- SDK 桥接代码普遍是 `if response.httpCode ~= 200 then 弹网络错误`，
            -- 回 404 会把整条链路判死。单机版对未知路径先回 200 + 空 JSON，
            -- 并把路径打到日志里，方便下一轮补回放。
            body = '{}'
            ctype = 'application/json'
            code = '200 OK'
            log('MISS ' .. path .. ' -> 200 {}')
        end
    end

    send_parts(sock, string.format(
        'HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n',
        code, ctype, #body), body, filepath)
    pcall(function() sock:close() end)
end

function Http.tick()
    if not Http.server then
        return
    end
    local ok, sock = pcall(function()
        return Http.server:accept()
    end)
    if ok and sock then
        local hok, err = pcall(handle, sock)
        if not hok then
            log('handle failed: ' .. tostring(err))
            pcall(function() sock:close() end)
        end
    end
end

function Http.start(port)
    if Http.enabled then
        return true
    end
    if port then
        Http.port = port
    end
    local ok, err = pcall(function()
        Http.server = luajava.newInstance('java.net.ServerSocket', Http.port)
        Http.server:setSoTimeout(2)          -- accept 最多阻塞 2ms，异常被 pcall 吃
        local scheduler = CCDirector:sharedDirector():getScheduler()
        scheduler:scheduleScriptFunc(function()
            Http.tick()
        end, 0, false)                        -- 每帧执行
        Http.enabled = true
    end)
    if ok and Http.enabled then
        log('listening on 127.0.0.1:' .. tostring(Http.port))
        return true
    end
    log('start failed: ' .. tostring(err))
    return false
end

return Http
