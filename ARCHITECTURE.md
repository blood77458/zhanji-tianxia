# 《战姬天下》客户端架构与 S 端接口逆向分析报告

> 目标 APK：`zjtianxia_11.0.61_oem5500058.apk`（193,327,619 字节）
> MD5 `00CC40EC4D833A46930E04DC68CFD914` / SHA256 `32AF9EE5…4B6C7733`
> 包名 `com.happyelements.canon.baiduDK`｜版本 11.0.61｜渠道 龙渊/百度多酷（oem_5500058）
> 开发/发行：**乐元素 Happy Elements**（内部项目代号 **canon**）

---

## 1. 结论速览

| 项目 | 结论 |
|---|---|
| 客户端引擎 | **Cocos2d-x + Lua（tolua++ 绑定）+ 乐元素自研 HeCore 层** |
| 核心原生库 | `lib/hegame.so`（`libhegame.so`，7.06 MB，**仅 armeabi-v7a**） |
| 业务脚本 | `assets/src/**` 共 **1088 个 .lua**，**AES-128-CBC + zlib 加密** |
| 加固 | **无**（无 360/乐固/梆梆等壳），可完整静态分析 |
| 资源命名 | 内容寻址：`<name>.<md5>.lua`，文件名中的 md5 == 文件内容 md5 |
| HTTP 通道 | `POST {domain}/protocol?uid=<uid>`，**AMF3 序列化 + zlib 压缩** |
| 实时通道 | 自研 TCP 长连接（`SocketTCP`），同样 AMF3 编码 |
| 服务端域名 | `http://android1.canon.happyelements.cn` |
| 接口总数 | **386** 个具名 RPC 端点 |
| 登录第三方 | 百度多酷 SDK、支付宝、腾讯、Atlassian JConnect 客服 |
| **复现进度** | 客户端已跑到 **`MainMenuScene:onInit`（主界面构造函数）**；协议全部打通 |
| **当前阻塞** | 本包**美术资源不完整**（主界面 85 张图缺 42 张，manifest 里就没有），原版靠 CDN 动态下载补齐，CDN 已下线 —— 详见 §9.6 |

---

## 2. 客户端总体架构

```
┌──────────────────────────────────────────────────────────┐
│ com.happyelements.arda.MainActivity                      │
│   └─ Application: com.happyelements.canon.nd91.ND91MainApplication │
│        └─ com.happyelements.gsp.*  (Game Service Platform)│
│             DC / PAYMENT / NOTIFICATION / CUSTOMERSUPPORT │
├──────────────────────────────────────────────────────────┤
│ libhegame.so  (armeabi-v7a, 7060420 B, 19926 dynsyms)     │
│   Cocos2d-x (CCApplication/CCLuaEngine/tolua)             │
│   HeCore 自研层：                                          │
│     HeLuaLoader     ── 自定义 Lua 加载器（解密入口）        │
│     HeResFileLocator── 资源定位                            │
│     HeMathUtils     ── aesEncrypt/aesDecrypt               │
│     DataEncrypt     ── DES-CBC / base64                    │
│     GameSocketData  ── 暴露给 Lua 的 socket 封装           │
│     bp_wapper       ── 断点包装                            │
│     hedebug/snapshot── Lua 远程调试器（LuaSocket 2.0.2）   │
│   内置: protobuf / libcurl / libxml2 / OpenSSL / LuaSocket │
├──────────────────────────────────────────────────────────┤
│ assets/src/**  (1088 Lua, 解密后 16.05 MB)                 │
│   canon/request/*   ── 386 个 RPC 定义                     │
│   hecore/rpc.lua    ── RPC 栈与编解码核心                   │
│   canon/manager/TCPManager.lua ── 实时通道                  │
│   canon/data/DataManager.lua   ── 服务端下发的 URL 配置      │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Lua 资源加密方案（已完全破解）

### 3.1 文件格式

```
file = IV(16 字节随机) || AES-128-CBC( zlib( lua_source ) )   [PKCS#7 填充]
```

### 3.2 密钥来源（运行时）

引擎在 `load_lua` 中从 `.bss` 的静态对象读取密钥与开关：

```asm
0x2ef1e8  ldr.w  sb, [pc,#0x3d8]   ; 字面量 0x003cbe14
0x2ef1ec  add    sb, pc            ; sb = 0x6BB004  ← HeLuaLoader 静态对象
0x2ef1ee  ldr.w  r3, [sb, #0x24]   ; 读开关 (+0x24→+0x28，见下)
0x2ef1f2  lsls   r3, r3, #0x1f
0x2ef1f4  bpl.w  0x2ef35a          ; bit0=0 → 跳过解密
0x2ef200  add    r0, pc            ; r0 = 0x6BB004
0x2ef20a  adds   r0, #0x28         ; r0 = 0x6BB02C  ← 密钥指针
0x2ef20c  add.w  r2, r6, #0x10     ; r2 = 文件+16  ← 密文
0x2ef210  mov    r1, r6            ; r1 = 文件头     ← IV
0x2ef212  bl     HeMathUtils::aesDecrypt(key, iv, ct, len-16, &out)
```

运行时实测（MuMu 12 / Android 12 / ARM 翻译层）：

```
ELF vaddr 0x6BB028 = 01 00 00 00   → 开关 = 1（启用解密）
ELF vaddr 0x6BB02C = e9 74 7d 92 cc 32 2e 7d 11 2e 7c 34 51 d7 b3 6a
                     ↑ AES-128 密钥
```

**密钥：`e9747d92cc322e7d112e7c3451d7b36a`**

> 该密钥不是二进制中的静态常量（对 `libhegame.so` 与 `classes.dex` 做了
> 全部偏移的 16/24/32 字节滑窗暴力验证，共 4200 万次尝试，0 命中），
> 而是运行时填入 `.bss` 的，因此**只能**从活动进程内存中取得。

### 3.3 验证

`canon/models/LocalUserDataModel.*.lua` 明文为空。32 字节密文 =
`IV(16)` + 空明文经 zlib 后为 8 字节 `78 9c 03 00 00 00 00 01`，
再经 AES-CBC+PKCS#7 → 16 字节 → 合计 32 字节，**与实测完全一致**。

---

## 4. S 端通信协议

### 4.1 通道拓扑

```
客户端 ──HTTP── POST {domain}/protocol?uid=<uid>     （主 RPC，请求/响应）
       ──HTTP── POST {domain}/sessionKey/init        （会话密钥）
       ──HTTP── GET  {domain}/staticVersion          （资源版本检查）
       ──HTTP── POST {domain}/getLoginServer?        （选服）
       ──TCP─── {serverAddress}:{serverPort}         （实时推送/战斗）
                         ↑ 地址与 token 由 RPC `getSocketServer` 下发
```

### 4.2 编码管线（`hecore/rpc.lua`）

注册于 `canon/request/Communication.lua`：

```lua
transponder:registryConvertor(
    rpc.AssembleConvertor.new(true, "0.3.0", "12306", "canon", "zh_CN", platformFinder, 0),
    { rpc.CompressConvertor.new(), rpc.HeaderConvertor.new() }
)
-- 参数依次: amf3Enabled=true, version="0.3.0", metaVersion="12306",
--           appID="canon", language="zh_CN", platformFinder, clientType=0
```

**发送方向**：`AssembleConvertor` (AMF3) → `CompressConvertor` (zlib) → `HeaderConvertor` (`headercvt`)

### 4.3 请求结构

```lua
header = {
    v = "0.3.0",        -- 客户端版本
    mv = "12306",       -- 元数据版本
    ct = 0,             -- clientType
    aid = "canon",      -- appID
    lang = "zh_CN",
    pf = <platform>,    -- 平台，如 "duoku"
    notify = true,
    sk = <sessionKey>,  -- /sessionKey/init 获得
    uk = <userKey>,     -- 登录后由服务端下发
    others = {...},
    st = <counter>      -- 递增序号；带外消息为 -999
}
data = { header, { { method="<endpoint>", ...业务参数 }, ... } }
body = amf3.encode(data)    -- 随后 zlib 压缩
```

HTTP 头：`Content-Type: application/octet-stream`

### 4.4 响应结构

```lua
responseData = amf3.decode(bytes)
subHeader = responseData[1]   -- { errCode, ts, uk, st, others }
responses = responseData[2]   -- [ { method=<endpoint>, retCode=200, ...业务数据 } ]
events    = responseData[3]   -- 服务端主动推送事件（可选）
```

- `retCode == 200` 表示成功；`errCode > 0` 视为业务错误
- 响应中的 `uk` 会被客户端保存并用于后续请求
- 响应中的 `st` 用于同步序号
- 客户端会反向执行 `headercvt.convertU` → `zlib.uncompress` → AMF3 解码

### 4.5 服务端下发的 URL 配置（`DataManager.SystemConfig`）

`domainUrl` 来自 `StartupConfig.plist` 的 `gameDomain`。**关键端点**：

| 配置键 | URL |
|---|---|
| `ProtocolUrl` | `{domain}/protocol` ← **主 RPC 入口** |
| `SessionKeyUrl` | `{domain}/sessionKey/init` |
| `CheckAndroidIdUrl` | `{domain}/check/android?` |
| `CheckDKIdUrl` | `{domain}/check/duoku?` |
| `LoginAccountUrl` | `{domain}/loginAccount/login` |
| `RegisterAccountUrl` | `{domain}/loginAccount/register` |
| `GetLoginedServer` | `{domain}/getLoginServer?` |
| `ChangeAccountUrl` | `{domain}/account?accountId=` |
| `GetBoundMappingUrl` | `{domain}/mappingAccount` |

资源检查：`StartupConfig.StaticSettingsUrl = {domain}/staticVersion`

### 4.6 客户端启动配置（`assets/StartupConfig.plist`，明文）

```xml
<key>gameDomain</key>        <string>http://android1.canon.happyelements.cn</string>
<key>StaticSettingsUrl</key> <string>http://android1.canon.happyelements.cn/staticVersion</string>
<key>DcUrl</key>             <string>http://log.dc.cn.happyelements.com/restapi.php</string>
<key>DcUniqueKey</key>       <string>canon_androidlongyuan_prod</string>
<key>LogUploadUrl</key>      <string>http://etlog.happyelements.cn/logservice.php</string>
<key>LuaDebugEnable</key>    <false/>   <!-- 置 true 可开启 Lua 远程调试 -->
<key>LuaDebugIdeIp</key>     <string>10.130.144.253</string>
<key>LocalDevelopMode</key>  <false/>
<key>ExternalLibLoaderEnabled</key> <true/>
<key>releaseVersion</key>    <string>11.0</string>
```

> 运行时该文件会被复制到 `/data/data/<pkg>/files/StartupConfig.plist`，
> 可直接修改而不必重打包 APK。

---

## 5. 接口清单（386 个 RPC 端点，节选）

完整列表见 `work/endpoints.txt`。

**账号/会话**
`login` `loginServer` `createUser` `bindAccount` `geneNickname` `rename`
`getServerStatus` `getServerTimeStamp` `getSocketServer` `online` `offline`

**核心玩法**
`gameInit` `getMeta` `getHomeInfo` `getPlayerTeamInfo` `getProps` `getEquips`
`clearMission` `challengeElite` `challengeBabel` `challengeArena` `challengeSkyTower`
`gachaCard` `gachaCardFree` `evolveCard` `synthetizeCard` `trainCard` `splitCard`
`upgradeSkill`（含于请求集）`buyEnergy` `buyGoods` `sellCards`

**社交**
`getFriends` `sendInvitation` `acceptInvitation` `deleteFriend` `sendFreeGift`
`searchUserByNickname` `privateChat` `challengeFriend`

**公会（Union）**
`createUnion` `getUnionInfo` `getUnionList` `applyUnion` `appointUnion`
`dissolveUnion` `getUnionMembersList` `challengeUnionMonster` `getUnionCityList`

**跨服 / 活动**
`getCrossPvpInfo` `getCrossGvgInfo` `getCrossBossInfo` `getWorldBossInfo`
`getActivityBalloonInfo` `eatPeach` `gainContinuousLoginRewardV2` `getSignInReward`

**付费**
`rechargeCalls` `getDailyRecharge` `gainChargeMoneyReward` `buyMonthGemCard`

---

## 6. 现行故障点（停服后的表现）

客户端运行到资源更新检查时：

```
GET /staticVersion?clientVersion=11.0.61&releaseVersion=11.0&platform=baiduDK&debugVersion=false
User-Agent: HeMobileGame
Accept-Encoding: gzip
```

因原服务端已下线，客户端弹出「主公，网络不好啊！」并停在标题页。
**该请求本身即证明了客户端网络层完好，只缺服务端应答。**

---

## 7. 复现实验环境（本项目实测可行）

| 组件 | 说明 |
|---|---|
| 模拟器 | **MuMu Player 12**（Android 12 / SDK 32 / `x86_64,arm64-v8a,x86,armeabi-v7a,armeabi`，`native.bridge=libnb.so`，含 `libhoudini.so`） |
| 为什么必须用它 | `libhegame.so` **仅 armeabi-v7a**。Google 官方 emulator 35.x 已移除 ARM 客户机支持（`PANIC: CPU Architecture 'arm' is not supported`），x86 镜像的 `libndk_translation` 也未接线 |
| APK 改造 | 删除 `lib/x86`、`lib/mips`（各 4 个文件），强制走 ARM 路径；zipalign + `apksigner`（**JKS** 密钥库，PKCS12 会导致 apktool 报 `Invalid keystore format`）重新签名 |
| 流量劫持 | 以 root 将定制 hosts **bind-mount** 到 `/system/etc/hosts`，把游戏域名指向宿主 `10.0.2.2` |
| 取密钥 | root 读 `/proc/<pid>/mem`：基址 `0x0c830000`（映射段）＋ `.bss` 匿名段 `0x0cee7000-0cf11000`，密钥位于 `0x6ceeb02c` |

> 注：`.bss` 是**匿名映射**，`grep libhegame /proc/pid/maps` 看不到它，
> 需另找 `rw-p 00000000 00:00 0` 的相邻段。

---

## 8. 可复用的调试后门

`LuaDebugEnable = true` 后，引擎加载 `hecore.lua_debugger`，
通过 **LuaSocket 主动外连 `LuaDebugIdeIp:8172`**：

```
[LUA-print] Could not connect to 10.0.2.2:8172
```

该连接上客户端表现为 **HTTP 风格的服务端**（对无法解析的输入回 `400 Bad Request`）。
在宿主监听 8172 即可接入，用于读取运行态脚本与执行 Lua —— 这是
不依赖内存取证即可获取明文的第二条路径。

---

## 8.1 阶段一实测：客户端首次与自建服务端联通（早期结果）

> 本节是推进过程中的阶段性记录；完整成果见第 9 节。


### 9.0 阶段一：客户端首次与自建服务端联通（早期结果）

在 MuMu Player 12（Android 12 + Houdini ARM 翻译）中运行改造后的 APK，
客户端完整走通以下流程：

```
启动 → 资源版本检查 GET /staticVersion      ✅ 通过（need_download=false 直接使用内置资源）
     → 系统配置     POST /systemInfo        ✅ 通过（AMF3 响应被正确解析）
     → 服务器列表   ← 由我们下发的 serverPartitionConfig 渲染
     → 标题/选服界面「1区  本地测试服  正常  点击选区」+「登录」按钮
```

截图证据：`work/shot2.png`（选服界面，服务器名 **本地测试服** 来自自建服务端）。

**这证明了三件事**：网络层完好、我们实现的 AMF3 编解码与服务端接口正确、
以及客户端确实读到了自建服务端下发的数据。

当时点击「登录」后进入 **百度/多酷渠道 SDK**（`com.baidu.platformsdk.LoginActivity`），
因百度游戏平台已关停而失败：

```
ACT:1,resultCode:-1,resultDesc:网络连接异常，请重试
```

**这是第三方渠道 SDK 的服务器停运，与游戏服务端无关。**
本 APK 是 `baiduDK` 渠道包，包名后缀决定 `platFormId = duoku`，
因此强制走百度 SDK 登录。收尾方法见 9.3（改平台判定，切官方账号通道）。

---

## 9. 最终成果（端到端跑通）

### 9.1 客户端推进到什么程度

实测已通过的完整链路（`work/shot_run2/3/5/6` 为截图证据）：

```
启动 → 登录页（服务端 serverPartitionConfig 正确渲染：「1区 本地测试服 正常」）
     → 游客登录 → 角色创建页（输入名字「Hero」）
     → 创建角色 → createUser / gameInit 成功
     → 新手引导对话（DialogOnceScene_Script_1）
     → 假战斗（BattleScene kFakeBattle）→ On_Battle_Ok
     → DialogOnceScene_Script_2
     → MainMenuScene:create → MainMenuScene:onInit 开始执行
```

日志实证 `MainMenuScene:onInit` 已经跑起来（这是主界面的构造函数）：

```
[LUA-print] DialogOnceScene_Script all finished
[LUA-print] TEST HOMEINFOMANAGER        <- MainMenuScene.lua:313
[LUA-print] 2                            <- HomeInfoManager.getFreeGachaStatus()
[LUA-print] false                        <- HomeInfoManager.getChargeRewardStatus()
```

服务端侧的完整调用序列（登录 + 创角 + 主界面）：

```
GET  /staticVersion?clientVersion=11.0.61&releaseVersion=11.0&platform=baiduDK&debugVersion=false
POST /systemInfo
POST /loginAccount/hasVisitorAccount
POST /check/android?                 -> {"code":1,"loginAccountId":"100001"}
POST /mappingAccount                 -> {"code":1,"accountId":"100001","token":"..."}
POST /sessionKey/init                -> "100001,<uuid>,<sesskey>"
POST /protocol  [login]              -> retCode 0
POST /protocol  [loginServer]        -> {"uid":"1"}          (字符串 "1" == 新玩家)
POST /protocol  [getMeta]            -> 游戏元数据
POST /protocol  [geneNickname]       -> {"nickname":"..."}
POST /protocol  [createUser]         -> {"sharkUser":{...}}
POST /protocol  [gameInit]           -> 完整角色数据
POST /protocol  [getMaintenanceMeta] -> {"maintenanceItem":[]}
POST /protocol  [getAchievements]    -> {"sharkAchievement":[]}
POST /protocol  [getUserBanInfo]     -> {"noChatEndSeconds":0}
TCP  <addr>:9700  login              -> {"method":"login","retCode":0}
```

### 9.2 完整通信协议（全部实证）

#### 9.2.1 HTTP RPC 通道

```
HTTP body = headercvt( zlib( amf3( payload ) ) )
```

**headercvt 外层封装**（源自 `libhegame.so` 模块 `headercvt`，
`convertD@0x30edf8` / `convertU@0x30ed8c`，注册表位于 `0x682a80`）：

```
客户端 -> 服务端 : 00 64 || MD5(C16 || X) || X      X = payload ^ 0xC3
服务端 -> 客户端 : 00 64 || MD5(C16 || X) || X      X = payload ^ 0x71

C16 = 25 5e 26 2a 40 51 30 6a 65 33 35 69 37 71 70 39
```

> **两个方向异或密钥不同**（0xC3 / 0x71）—— 这是实测确认的：
> 用 0xC3 编码响应时客户端报 `zlib checksum failed`，换 0x71 后立即通过。
> 客户端解码时**不校验** MD5，但仍按规范填好。

**RPC 载荷（AMF3）**

```
请求 = [ header, [ {method=<endpoint>, ...params}, ... ] ]
响应 = [ subHeader, [ {method=<endpoint>, retCode=200, ...data} ], [events] ]

subHeader.errCode 必须 <= 0（成功用 0）：
    local code = tonumber(subHeader.errCode)
    code = code and code > 0 and code or nil     -- >0 被当作错误
```

**AMF3 实现要点**（客户端内置 `lua-amf3 1.0.2`）

- 服务端响应统一用**关联数组**（`0x09 0x01` + 字符串键值对 + `0x01` 结束）
- 客户端请求里会出现**对象**（`0x0A`），位布局：
  `bit0=内联, bit1=新类定义, bit2=externalizable, bit3=dynamic, bit4+=成员数`；
  引用既有类时 `traits 索引 = u29 >> 2`
- AMF3 整数是 29 位有符号，超出必须编码为 double（如服务器时间戳）

#### 9.2.2 实时 TCP 通道（帧格式已逐字节验证）

`TCPManager.lua`：`/protocol getSocketServer` 拿到 `{serverAddress, serverPort, token}` 后
建立 TCP 连接，并在 `EVENT_CONNECTED` 时发送

```lua
{serverAddress=..., serverPort=..., token=..., uid=tonumber(uid), method="login"}
```

`TCPManager:dataReceived` 判定
`bodyData.method == "login" and bodyData.retCode ~= 0` 即为失败并**立刻重连** ——
这正是导致主界面永远渲染不出来的 `SOCKET_TCP_CONNECT_FAILURE` 11 秒重连循环。
因此必须回 `retCode = 0`。

**帧格式**（抓包得到，104 字节 = 14 字节头 + 90 字节 AMF3）：

```
uint32 BE 长度 (= 剩余头 10 字节 + AMF3 长度)
10 字节 0x00
AMF3 载荷
```

AMF3 对象（`0x0A`）编码，已用捕获帧**逐字节回归验证**：

```
0a            object marker
0b            u29 traits: inline | new-class | dynamic, 0 sealed members
01            class name "" (u29 (0<<1)|1)
<key><value>  dynamic members
01            空 key 结束
```

### 9.3 官方账号登录协议（绕过已停运的百度 SDK）

APK 是 `baiduDK` 渠道包，登录默认走百度 SDK（服务器已停运）。
通过修改 `canon/data/ThirdPlatformLogin.lua` 让
`isDKAndroid()` 返回 false、`isPlatformAndroid()` 返回 true，
即可切换到官方账号通道（全部对接自建服务端）：

| 步骤 | 端点 | 请求 | 响应 |
|---|---|---|---|
| 1 | `/loginAccount/hasVisitorAccount` | `platformId,deviceId` | JSON |
| 2 | `/check/android?` | `udid,seconds,sk=md5(udid..seconds.."123456"),loginType` | `{code:1, loginAccountId}` |
| 3 | `/mappingAccount` | `platformId,platformUid,sid` | `{code:1, accountId, token}` |
| 4 | `/sessionKey/init` | 大量设备参数 | 纯文本 `uid,uuid,sessionKey` |
| 5 | `/protocol` | AMF3 RPC | 见上 |

> `accountId` / `uid` 必须是**正整数**：客户端执行
> `tonumber(fields[1])` 并判断 `<= 0`（`-1` 表示新用户）。

### 9.4 崩溃链与根因（引擎的失败模型）

**关键前提：引擎对任何未捕获的 Lua 错误直接 `SIGKILL` 自己。**
所以「游戏直接弹出」在本文档里等价于「有一处未捕获的 Lua 错误」。
排查过程按发生顺序记录如下 —— 这些坑具有普遍参考价值。

| # | 现象 | 根因 | 处理 |
|---|---|---|---|
| 1 | `CreateCharacterScene.lua:152 attempt to call field 'getSixPointIsExist' (a nil value)` | 该函数在**本包中根本不存在**。「打6号点」是乐元素广告投放统计，在渠道包里是死代码；我们把 `isPlatformAndroid()` 改成 true 后这条分支才被执行 | 客户端补丁：整块删除（同时避免向第三方推广服务器发请求） |
| 2 | `Invalid method call. No such method.` @ `CanonEnvInjector.lua:20 setGspGameUserId` | **luajava 类型不匹配**：dex 中签名为 `setGspGameUserId(java.lang.String)V`，而服务端把 `sharkUser.uid` 下发成了 JSON **数字** 100001。luajava 不会把 Lua number 转成 `java.lang.String` | 服务端修复：`uid` 下发为**字符串** |
| 3 | `canonUtils.lua:603 bad argument #1 to 'pairs' (table expected, got nil)` | `IsGuideExecuted` 直接 `pairs(data.sharkUserExtend.tutorialSteps)`；`gameInit` 缺少 `sharkUserExtend` | 服务端补全 `sharkUserExtend`（28 个字段，类型按客户端用法推断） |
| 4 | `GachaScene.lua:1167 attempt to index a nil value` | `MetaManager.getAdPictureById(id).url`；`getMeta` 未下发 `adPictureConfig` | 服务端下发 `adPictureConfig.adPictures`（7 个 id）+ 新增 `/static/ad/*.png` 占位图 |
| 5 | `DataManager.lua:280 attempt to index field 'sharkCards'` | `getCardsData()` 无保护地取 `sharkCards.sharkCards` | 服务端下发初始卡牌 |
| 6 | `CountryManager.lua:113 arithmetic on field 'missionId'` | **空表陷阱**：客户端写的是 `self.missionContext = GameInitData.sharkMissionContext` 然后 `if not self.missionContext then <用本地 battle_chapter 构造默认值> end`。Lua 里**空表为真**，下发 `{}` 会顶掉客户端自己的默认值 | 服务端改为**不下发**该字段，让客户端自建默认值 |
| 7 | `MainMenuScene:735 setString(nil)` 类错误（`gameSettingConfig.arenaUnlockLevel` 等） | `gameSettingConfig` / `battleSettingConfig` **只来自服务端**，客户端无本地兜底；缺字段即 `setString(nil)` | 服务端补全 38 + 14 个字段（按 Lua 扫描结果） |
| 8 | 主界面**纯黑但进程存活、0% CPU、仍在 30fps 渲染** | `DialogOnceScene:60` 在**新手引导协程**里调用 `MainMenuScene:create()`。`NewUserGuideCoroutine.lua` 开头明确写着：<br>「cocoutine中发生错误会直接终止coroutine, **不会输出到控制台**」<br>→ 协程内抛错会被静默吞掉：没有 logcat、没有 crash 文件、没有 SIGKILL，只剩黑屏 | 用诊断补丁把错误逼出来（见 9.5） |
| 9 | `SOCKET_TCP_CONNECT_FAILURE` 每 11 秒循环，主界面永不渲染 | 实时 TCP 通道（9700）未实现 | 服务端实现 TCP 通道（帧格式见 9.2.2） |
| 10 | `Fatal signal 11 (SIGSEGV) fault addr 0x0 in GLThread` | **空纹理绘制**：`CCSprite:create()` 无贴图时 `CCSprite::draw()` 解引用空纹理。`LayoutBuilder.lua:221` 在 `width==0 or height==0` 时就调用 `Sprite:create()` | 客户端补丁：给无参 `Sprite:create()` 与缺失的 `Scale9Sprite` 兜底到真实存在的贴图 |
| 11 | 同上（卡牌头像） | `getCardSpriteFrame()` 取 `sdandard.png`，但本包 879 个卡面目录里**只有 1 个**带标准尺寸帧（其余 `full.png` 是 CDN 下载的） | 客户端补丁：取不到就回退到 `full.png` |

**排查手法（可复用）**：`hecore/display/CocosObject.lua` 是所有显示对象的基类，
在 `ctor` 里检测 `refCocosObj == nil` 并打印 `debug.traceback()`，
即可把「GLThread 空指针」直接定位到 Lua 调用点。
（注意 `Layer`/`MultiTouchLayer` 是**两段式构造** —— `new()` 时本就为空，
随后 `initLayer()` 才挂原生对象，所以这类日志需人工排除。）

### 9.5 APK 改造流水线（可复现）

`work/patch_lua.py` 把单文件替换升级为**多文件补丁框架**：

1. 解出目标 Lua（`IV(16) || AES-128-CBC(zlib(src))`，密钥 `e9747d92...`）
2. 对每个补丁做**块配平校验**（比较补丁前后的 `opens - ends` 差值），配平破坏即拒绝出包
3. 重新加密 → 得到新的内容 md5，资源改名 `<name>.<newmd5>.lua`
4. 同步更新清单条目 `md5`/`size`，并**重命名清单** `static_config.<newmd5>.xml`
   （引擎会拿文件名里的 md5 校验文件内容）
5. zipalign + apksigner（JKS）

已注册补丁（`PATCHES` 列表）：`CreateCharacterScene.lua`（删广告打点）、
`Sprite.lua`（空/无贴图精灵兜底）、`CocosObject.lua`（诊断 traceback）、
`canonUtils.lua`（卡面帧回退）。

> 一个文件只能有一个补丁入口 —— `main()` 每个补丁都从**原始资源**重新解密，
> 因此同一文件的多个补丁必须链式合成一个 builder。

### 9.6 当前阻塞点：本包的美术资源不完整（已证实，非代码问题）

主界面 `mainmenu_scene_new.json` 引用 85 张图，其中 **42 张在本 APK 中不存在**，
包括 `mainmenu_scene_home_main`、`txt_heroword`、`mainmenu_scene_home_icons`、
`btn/mainmenu_scene_btn_1` 等 —— 这些名字**连 manifest 里都没有**
（`assets/static_config.*.xml` 是引擎的资源总表），也没有对应的 `.fpk` / `.plist` 合集。

这与协议里 `staticVersion` 的字段相吻合：

```json
{"need_download": false, "can_download": false, "download_url": "", "ref": 0}
```

原版客户端是靠 **CDN 动态下载资源包**补齐这部分美术的，而 CDN 早已下线。
因此本包**仅凭自身资源无法完整渲染主界面**，引擎会在绘制空纹理时崩溃。

**结论**：这一层不是协议问题、也不是服务端能补的（服务端只能下发数据，不能下发美术）。

#### 9.6.1 资源包搜寻结果（已排查，公开渠道基本无望）

| 目标 | 结果 |
|---|---|
| **官方 CDN** `android1.canon.happyelements.cn`<br>`canon.happyelements.cn` | **NXDOMAIN（域名已注销）**。乐元素其他域名仍在解析<br>（`www.happyelements.cn`、`etlog.happyelements.cn`、<br>`log.dc.cn.happyelements.com`），说明公司还在运营，<br>但该游戏的 CDN 子域已被删除 → **原始资源包无法再从源头获取** |
| 七匣子 | v11.0.46 / 181.5 MB；另有 v10.0.43、v3.0.10、v3.0.1 |
| 单机100 | v11.0.61 百度版 / 184.40 MB，MD5 `5E476144…`<br>（第三方重打包，厂商写着「甘肃想好再分手网络科技有限公司」） |
| 刷机之家 | 标称 11.0.65 / 183.02 MB，**同一个 MD5 `5E476144…`**，内置菜单破解版 |
| ARP联盟「战姬天下单机」 | 181.5 MB，下载按钮是 `javascript:;`，纯 SEO 填充页 |
| 换名版本 | **《一姬当千：万人斩》v8.0.38**（同一游戏的马甲包） |
| **iOS 版（最有希望）** | 战姬天下ios版 **413.95 MB**（远大于安卓 184 MB，符合<br>App Store 要求自带全部资源）。下载链接经简单混淆<br>（`n` 分隔 hex）解出为 `https://t.appxiazia2021.cn/ios/157922_4`，<br>但该主机**同样已失效（NXDOMAIN）**，镜像页也已 404 |
| Wayback / archive.org | 本机环境**无法访问** web.archive.org 与 archive.org<br>（连接层面失败），故未能查证 CDN 快照 |

**结论**：所有能拿到的安卓包都是**同一套资源管线的部分包**（资源跨渠道共用），
没有任何一个补上缺失的美术；唯一可能自带全量资源的 iOS IPA 所在主机已死。

> ⚠️ **一个尚未证实的疑点**：如果客户端真的在请求这 42 个不存在的文件，
> 我们在 `Sprite:create` 里加的 `!!!NULL_SPRITE` 守卫**应当会打印**，但实测为 0 次。
> 这有两种解释：
> 1. tolua 对「文件缺失」返回的是**非 nil 的 userdata（内部指针为 NULL）**，
>    因此 `if not sprite` 这类 Lua 守卫看不见它 —— 若是这样，崩溃确实源于缺图；
> 2. 客户端根本没走这条路径，缺失的是别的东西。
>
> 下一步应当先**证伪/证实这一点**（例如在 Lua 侧检测贴图是否有效、
> 或对 `LayoutBuilder` 请求的每个路径做存在性探测并打日志），
> 再决定是「继续找包」还是「给缺失图生成占位图注入 APK」。

---

## 10. 合规提示

《战姬天下》著作权属**乐元素（Happy Elements）**，该公司仍在正常运营。
本项目所做的一切均为**个人学习与软件保存（preservation）**目的：

- 未破解付费内容，未修改游戏逻辑，未分发游戏资源
- 服务端为独立编写的兼容实现，不含任何原厂代码或资源
- **不得公开运营、不得用于盈利、不得传播 APK 与解出的资源**

若要长期研究，建议仅保留自行编写的协议实现与分析文档。
