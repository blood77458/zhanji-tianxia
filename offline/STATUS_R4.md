# 第 4 轮记录：本地 HTTP 二进制响应的死路与绕法

（主进度见 `STATUS.md`，本轮增量如下）

## 结论：这个 LuaJ 发不出二进制 HTTP body

已把能想到的四条路全试过，全部失败，且错误各不相同：

| 尝试 | 报错 | 原因 |
|---|---|---|
| `luajava.newArray('byte', n)` | `attempt to call field 'newArray' (a nil value)` | 该 LuaJ 没导出 newArray |
| `ByteArrayOutputStream:write(int)` / `OutputStream:write(int)` | `Invalid method call. No such method.` | LuaJ 把 Lua number 当 double，匹配不上 int 重载 |
| `FileInputStream:readAllBytes()` | `Invalid method call. No such method.` | `InputStream.readAllBytes` 是 **API 33** 才有，模拟器是 Android 12 |
| `java.nio.file.Files:copy(fis, out)` | `Not a OO function call.` | 静态方法调用方式不被支持 |
| `PrintStream:print(string)`（原方案） | 客户端报 `errorCode=18 "Transferred a partial file", bodyLength=0` | 字符串走字符集转换，二进制被吃掉（头发出去了、Content-Length 对、body 0 字节） |

**ASCII 文本没问题**：`PrintStream:print(string)` 对纯 ASCII 完全可靠 ——
资源检查 `/staticVersion` 就是靠它通过的（日志稳定出现 `GET /staticVersion` → 进登录页）。

## 定位手段（很有用，留着）

客户端自己的错误日志在 `/data/data/<pkg>/errorlogs/<ts>.log`，
它会**把 HTTP 响应对象整个 dump 出来**：

```
errorCode = 18, errorMsg = "Transferred a partial file",
bodyLength = 0, httpCode = 0,
headers = {"HTTP/1.1 200 OK", "Content-Type: application/octet-stream",
           "Content-Length: 359", "Connection: close"}
```

一眼就能看出「头对了、body 没到」。

## 由此确定的新方案：绕开二进制，改在客户端 Lua 里合成

`/systemInfo` 是唯一挡在登录前的二进制端点。客户端在
`LoginScene.lua:623` 做：

```lua
self.systemInfo = amf3.decode(response.body)
local ts = self.systemInfo.ts or os.time()
local serverMergeConfig = self.systemInfo.systemConf.serverMergeConfig
```

也就是说**只要 `self.systemInfo` 是个表**，后面逻辑就能跑。所以：

- **不打 HTTP 了**，直接给 `LoginScene` 打补丁（`Caches/src` 覆盖）：
  跳过 `/systemInfo` 的发送，直接构造本地表：
  ```lua
  self.systemInfo = {
    ts = os.time(), cleanVersion = false,
    systemConf = {serverMergeConfig = {enable=false, gameDomain="", serverOffset=0},
                  maintenanceFeatures = {}},
    serverPartitionConfig = {runningServers = {
        {serverId=1, serverName="本地测试服", enable=true,
         beginTime="0", serverBusy=100000, serverNormal=50000, newServer=true}},
      preparedServers = {}},
    serverStatuses = {{serverId=1, amount=1}},
  }
  ```
  然后走原来的成功分支。

其余登录端点（`/check/android`、`/loginAccount/hasVisitorAccount`、`/mappingAccount`、
`/sessionKey/init`）抓到的都是 **JSON / 半结构化文本**（ASCII）→ 可以正常回放，
不需要合成。

## 顺手发现的 bug（下轮修）

`httpserver.lua` 的 `replay_body` 返回的是**十六进制字符串**而不是字节
（日志里 `replay /systemInfo (718 bytes)` —— 718 = 359×2）。
ASCII 端点（JSON）目前因此会回出一串 hex 文本，客户端解析会失败。
修法：`replay_body` 里 `return hex2bytes(hex), true`。

## 下一轮 TODO

1. 修 `replay_body` 返回真字节（JSON 端点要能正常回放）。
2. 给 `LoginScene` 打补丁，本地合成 `systemInfo`，跳过该 HTTP 请求。
3. 继续点游客登录，看下一个卡点（预计 `/check/android`、`/sessionKey/init`，都是 ASCII，可回放）。
4. 登录通了以后 `[SINGLE] unhandled <method>` 就会刷屏 → 那就是 S1 的 handler 清单。

## 设备状态

- plist 指向 `127.0.0.1:18080`；本地 HTTP 在跑；`/staticVersion` 稳定通过；
- 客户端停在登录页；`/systemInfo` 的二进制 body 被主动丢弃（日志有 `BINARY body not supported`）。
