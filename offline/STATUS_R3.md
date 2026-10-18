# 第 3 轮记录：抓包回放上线，登录卡在 /systemInfo 之后

（主进度见 `STATUS.md`，这里是本轮增量）

## 已完成

1. **服务端加了抓包钩子**：`server/gameserver.py` 的 `_send` 把白名单端点的响应字节落盘到
   `work/http_capture/*.bin`（每个路径只存第一次）。
2. 在线跑一遍游客登录，抓到 5 个直连 HTTP 端点（合计 613 字节）：

   | 路径 | 字节 | 格式 |
   |---|---|---|
   | `/systemInfo` | 359 | **裸 AMF3**（`09 01 05 74…`，无 headercvt 信封） |
   | `/check/android` | 90 | JSON |
   | `/loginAccount/hasVisitorAccount` | 67 | JSON |
   | `/mappingAccount` | 51 | JSON |
   | `/sessionKey/init` | 46 | 半结构化文本（`32 2c 6c 6f…`） |

3. `scripts/gen_http_replay.py` 把 `.bin` 生成十六进制 Lua 表
   `canon/single/http_replay.lua`，`httpserver.lua` 按路径回放
   → 日志确认 `replay /systemInfo (359 bytes)`。
4. 修了本地 HTTP 一个真 bug：**之前没读 POST 请求体**就回包，HTTP/1.1 下客户端判失败；
   现在读 Content-Length 并读空 body，日志也能区分 GET/POST。
5. 未知路径从 404 改成 `200 + {}`（SDK 桥接普遍 `httpCode ~= 200` 就弹网络错误）。

## 卡点

`POST /systemInfo` 已经本地回放成功（200 + 原始字节），但客户端**在它之后就停住**：
不发起 `/check/android`、也不进 `Communication:initSession`（打点没触发），直接弹「网络不好」。

解码出的 systemInfo：

```json
{"ts": 1792290708, "cleanVersion": false, "systemConf": {...},
 "serverPartitionConfig": {"runningServers": {"1": {"serverId": 1, "serverName": "本地测试服",
   "enable": true, "beginTime": "1790697655", ...}}},
 "serverStatuses": {"1": {"serverId": 1, "amount": 1}}}
```

最可能原因：**`ts` 是抓包那一刻的时间戳**，客户端可能校验新鲜度或用它算时差，
回放一份几分钟前的 ts 就被判失效。

## 下一轮首选做法

不要回放死的 systemInfo —— **在 Lua 里动态生成**（客户端自带 `amf3.encode`）：

```lua
local obj = {ts = os.time(), cleanVersion = false,
  systemConf = {serverMergeConfig = {enable=false, gameDomain="", serverOffset=0},
                maintenanceFeatures = {}},
  serverPartitionConfig = {runningServers = {["1"] = {...}}, preparedServers = {}},
  serverStatuses = {["1"] = {serverId=1, amount=1}}}
-- 用 amf3.encode(obj) 出字节
```

退路：保留原始字节，只把里面 8 字节的 `ts` 双精度就地改成当前时间
（luajava 的 `Double.doubleToLongBits`）。

## 其他结论

- 登录链路所有 URL 都由 `DataManager.SystemConfig.*Url` 从 `domainUrl` 拼出来
  （`DKSdkToCanon` 用的 `CheckDKIdUrl` 也是），所以**全部受 plist 重定向控制**，离线可控。
- 设备上 plist 指向 `127.0.0.1:18080`，本地服务在跑，客户端停在登录页，无崩溃。
- 打点工具：`deploy_single.py --comm` 会给 `Communication` 的 initSession/initTransponder/
  login/init 等关键步骤插 `[SINGLE-DBG]` 日志；`--launcher` 会插本地 HTTP 启动；
  `--lua` 部署 `offline/lua/canon/single/*.lua`。
