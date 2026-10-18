# 《战姬天下》(canon) 客户端 · 服务端接口文档

> **逆向对象**：`zjt_pack_enablefix_signed.apk`（包名 `com.happyelements.canon.baiduDK`，版本 11.0.61，渠道 oem_5500058，193 MB）
> **分析目标**：APK 内 `assets/src/**.lua`（1088 个 Lua 源文件，AES-128-CBC + zlib 加密，已解密）
> **生成方式**：对解密后的 Lua 源码做静态分析 —— 请求参数取自实际调用点，响应字段由 `event.data.X` 引用点反推
> **用途**：自建私服时对齐客户端期望，避免「字段缺失 / 类型不对 → 客户端 SIGKILL」

---

## 0. 先读这一节：本文档怎么用

| 你想要 | 看哪一节 |
|---|---|
| 搞清楚客户端怎么发包 | §1 通信架构 |
| 补 `/protocol` 里某个 method | §4 总表定位 → §5 详情 |
| 找登录/账号链路 | §2 REST 接口 |
| 找实时推送 | §3 TCP 通道 |
| 排查客户端崩溃 | §1.6 类型与空值陷阱 + §8 踩坑清单 |

**可信度分级**（每个接口的字段都有来源，不要混用）：

| 标记 | 含义 | 可信度 |
|---|---|---|
| 🟢 `<protocol>` | 客户端源码注释里**官方内嵌的协议定义**，含字段类型与中文描述 | 最高（原厂自述）|
| 🔵 调用点 | 从 Lua 调用点静态解析出的参数名与取值表达式 | 高 |
| 🟡 响应字段 | 从 `event.data.X` 引用点反推客户端**读取**的字段 | 中（是「客户端会读」，不是「完整响应结构」）|
| ⚪ 推断 | 由文件名 / 注释得到的接口用途 | 参考 |

**目录**

| 章节 | 内容 |
|---|---|
| §1 | 通信架构、请求/响应信封、全局参数、类型陷阱 |
| §2 | REST 接口（`/sessionKey/init`、`/systemInfo`、`/check/*`、`/mappingAccount`、`/loginAccount/*` …）|
| §3 | TCP 实时通道帧格式与消息 |
| §4 | 363 个 RPC method 总表（按功能域）|
| §5 | 363 个 RPC 接口逐个详情 |
| §6 | 客户端内嵌的精确 `<protocol>` / `<bean>` 定义 |
| §7 | 137 条业务错误码 |
| §8 | 踩坑清单 |
| §9 | 附录：死代码与统计口径 |

### 0.1 30 秒速览：一次完整登录会打哪些接口

```
①  GET  /staticVersion?clientVersion=11.0.61&releaseVersion=11.0&platform=baiduDK&debugVersion=false
         └ 原生层发起；config_md5 必须匹配 APK 内 assets/static_config.<md5>.xml 文件名
②  POST /systemInfo                      → 裸 AMF3，读 ts（校时）/ 选服表
③  POST /loginAccount/hasVisitorAccount  → JSON {code, hasVisitorAccount, deviceId}
④  POST /check/android?  (或 /check/duoku?)  → JSON {code:1, loginAccountId}
⑤  POST /mappingAccount                  → JSON {code:1, accountId, token}
⑥  POST /sessionKey/init                 → 纯文本 "uid,uuid,sessionKey"
⑦  POST /protocol   [login]              → subHeader.errCode 必须 ≤ 0
⑧  POST /protocol   [loginServer]        → {uid:"1"}（"1" = 新玩家）
⑨  POST /protocol   [getMeta]            → 45 个 config 表
⑩  POST /protocol   [geneNickname]       → {nickname}
⑪  POST /protocol   [createUser]         → {sharkUser}
⑫  POST /protocol   [gameInit]           → 完整角色数据（字段最全，最容易崩）
⑬  POST /protocol   [getMaintenanceMeta] / [getAchievements] / [getUserBanInfo]
⑭  TCP  {serverAddress}:{serverPort}  →  {method="login"}  →  必须回 retCode=0
```

> ⑦ 之后的 `pf` 字段来自平台判定。本包是 `baiduDK` 渠道包，默认强制走百度 SDK 登录（服务器已停运）；
> 打补丁把 `canon/data/ThirdPlatformLogin.lua` 的 `isDKAndroid()` 改 false / `isPlatformAndroid()` 改 true，
> 即可切到官方账号通道 —— 本包默认那条百度 SDK 通道已经连不上了，不改的话客户端走不到自己的服务端。

---

## 1. 通信架构与通用约定

### 1.1 三条通道

```
客户端 ──HTTP POST── {domain}/protocol?uid=<uid>    主 RPC（业务 99% 走这里）
       ──HTTP POST── {domain}/sessionKey/init       会话密钥
       ──HTTP POST── {domain}/systemInfo            系统配置（响应是裸 AMF3）
       ──HTTP POST── {domain}/check/<platform>?     第三方平台账号校验（JSON）
       ──HTTP POST── {domain}/mappingAccount        账号绑定映射（JSON）
       ──HTTP POST── {domain}/loginAccount/*        账号登录/注册（JSON）
       ──HTTP GET ── {domain}/staticVersion         资源清单版本（原生层发起）
       ──HTTP GET ── {domain}/getLoginServer?accountId=  已登录服务器列表（纯文本）
       ──TCP─────── {serverAddress}:{serverPort}    实时通道（地址由 RPC getSocketServer 下发）
```

`{domain}` 取自 APK 内 `assets/StartupConfig.plist` 的 `gameDomain`，本包为 `http://android1.canon.happyelements.cn`（域名已注销，需 hosts 劫持）。

### 1.2 `/protocol` 编码管线

来自 `hecore/rpc.lua` + `canon/request/Communication.lua`：

```lua
transponder:registryConvertor(
    rpc.AssembleConvertor.new(true, "0.3.0", "12306", "canon", "zh_CN", platformFinder, 0),
    { rpc.CompressConvertor.new(), rpc.HeaderConvertor.new() },   -- 二进制转换链
    { rpc.PackageConvertor.new() }                                 -- 包转换链
)
```

**发送**（`convertD`，按注册顺序）：

```
业务表 {header, [ {...}, ... ]}  --AMF3编码-->  bytes  --zlib压缩-->  bytes  --headercvt封装-->  HTTP body
```

**headercvt 外层**（`libhegame.so` 的 `headercvt` 模块）：

```
客户端 → 服务端 :  00 64 ‖ MD5(C16 ‖ X) ‖ X     其中 X = payload 逐字节 XOR 0xC3
服务端 → 客户端 :  00 64 ‖ MD5(C16 ‖ X) ‖ X     其中 X = payload 逐字节 XOR 0x71

C16 = 25 5e 26 2a 40 51 30 6a 65 33 35 69 37 71 70 39
```

> ⚠️ **两个方向异或密钥不同**，写反了客户端会报 `zlib checksum failed`。
> 客户端解码时**不校验** MD5，但服务端仍应按规范填。

请求 HTTP 头：`Content-Type: application/octet-stream`，URL 带 `?uid=<uid>`。

### 1.3 请求信封（AMF3 第一元素 = header）

`AssembleConvertor:convertD()`（`hecore/rpc.lua:851`）逐字构造：

| 键 | 值（本包实测）| 说明 |
|---|---|---|
| `v` | `"0.3.0"` | 协议版本 |
| `mv` | `"12306"` | meta 版本 |
| `ct` | `0` | clientType |
| `aid` | `"canon"` | appID |
| `lang` | `"zh_CN"` | 语言 |
| `pf` | `getPlatFormIgnoreDevice()` | 平台串。本包为 `baiduDK` 渠道；打过补丁后可走官方通道 |
| `notify` | `true` | 恒定 |
| `sk` | sessionKey | 来自 `/sessionKey/init` 第 3 段 |
| `uk` | userKey | 登录后由服务端下发，随响应 `subHeader.uk` 回传 |
| `others` | `{}` | 可由 `Communication:putOthers(k,v)` 塞入 |
| `st` | 递增序号 | 从 0 开始；带外消息（`callOutOfBand`）固定 `-999` |

第二元素是请求数组，每项形如 `{ method = "<endpoint>", ...业务参数 }`（`method` 由框架写入）。

### 1.4 响应信封

```lua
responseData = amf3.decode(bytes)
subHeader  = responseData[1]   -- { errCode, ts, uk, st, others }
responses  = responseData[2]   -- [ { method=<endpoint>, retCode=200, ...业务数据 }, ... ]
events     = responseData[3]   -- 服务端主动推送（本服务端恒为空数组）
```

| 字段 | 约束 | 客户端行为 |
|---|---|---|
| `subHeader.errCode` | **必须 ≤ 0**（成功用 `0`）| `code = code and code > 0 and code or nil`，`>0` 一律当全局错误弹「主公，网络不好啊！」并重登 |
| `subHeader.ts` | 服务器时间戳（秒）| 用于校正本地时差 `__g_utcDiffSeconds` |
| `subHeader.uk` | 可选 | 有则保存并用于后续请求 |
| `subHeader.st` | 可选 | `counter = max(counter, st)` |
| `response.retCode` | **必须 = 200** 才算成功 | `pickResponseMeta`：`code ~= 200` → 走 `onError`，`retCode` 即业务错误码 |
| `response.extraMsg` | 可选 | 错误提示文案 |

### 1.5 框架自动附加的参数

`canon/request/BaseRequest.lua:842`：

```lua
self.params["serverId"] = DataManager.getServerid()
```

> **所有**走 `XxxRequest` 的 RPC 请求都会带 `serverId`，即使某些接口的业务代码没写。
> 例外：`Communication:login()` 直接 `transponder:call("login", nil, ...)`，**不带** `serverId`。

### 1.6 类型与空值陷阱（「错一个参数就崩」的真正原因）

客户端引擎对**未捕获的 Lua 错误直接 `SIGKILL` 自己**，所以下面每一条都等于一次闪退：

| # | 陷阱 | 说明 |
|---|---|---|
| 1 | **Lua 空表为真** | 客户端写法是 `x = data.f; if not x then <自建默认值> end`。下发 `{}` 会**顶掉**客户端默认值，随后在其上做 `nil` 运算崩溃。**要么给全字段，要么整个 key 不下发**。典型：`sharkMissionContext`、`accountReturnRewards` |
| 2 | **AMF3 整数是 29 位有符号** | 超过 ±2^28-1 的值（如毫秒时间戳）必须编码成 double，否则客户端解码溢出 |
| 3 | **数组 vs 关联数组** | 客户端 `ipairs` 遍历的字段必须编成 AMF3 密集数组；服务端响应里统一用关联数组（`0x09 0x01` + 字符串键 + `0x01` 结束） |
| 4 | **字符串 / 数字不能混** | `uid` 必须是字符串（`CanonEnvInjector:setGspGameUserId(java.lang.String)V`，luajava 不转换 Lua number → `Invalid method call` → SIGKILL）|
| 5 | **该给数字的不能是 nil** | 例如 `getHomeInfo.unionMonsterEscapeSeconds`，nil 会让 `UnionManager.setColosseumMonsterRunTime` 直接崩 |
| 6 | **只来自服务端的配置表没有本地兜底** | `gameSettingConfig` / `battleSettingConfig` / `spiritSettingConfig` 等，缺字段 = `setString(nil)` |
| 7 | **协程内错误被静默吞掉** | 新手引导协程（`NewUserGuideCoroutine`）里的 Lua 错误不打印、不崩溃，只表现为**黑屏 + 进程存活**。主界面 `MainMenuScene:onInit` 就是从这个协程进的 |

---

## 2. REST 接口（非 RPC 通道）

这些请求不走 `/protocol`，各自独立编码。**响应格式分三类**，容易踩坑：

| 接口 | 方法 | 请求编码 | 响应编码 | 客户端解析代码 |
|---|---|---|---|---|
| `/staticVersion` | GET | query | JSON | 原生层 `libhegame.so` |
| `/systemInfo` | POST | 空 body | **裸 AMF3**（不 zlib、不 headercvt）| `canon/utils/SystemInfoCall.lua:14` `amf3.decode(response.body)` |
| `/sessionKey/init` | POST | `x-www-form-urlencoded` | **纯文本** `uid,uuid,sessionKey` | `canon/request/Communication.lua:140` `response.body:split(",")` |
| `/check/<platform>?` | POST | `x-www-form-urlencoded` | JSON | `table.deserialize`（cjson） |
| `/mappingAccount` | POST | `x-www-form-urlencoded` | JSON | 同上 |
| `/loginAccount/*` | POST | `x-www-form-urlencoded` | JSON | 同上 |
| `/getLoginServer?accountId=` | GET | query | **纯文本**，逗号分隔的 serverId 列表 | `canon/panel/ServerSelectPanel.lua:200` `response.body:split(",")` |
| `/account?accountId=` | POST | query | **纯文本** `uid,uuid,sessionKey` | `canon/scene/LoginScene.lua:1071` |

### 2.1 `POST /sessionKey/init`

定义：`canon/request/Communication.lua:116-237`（`Communication:initSession`）

请求体是**超长表单**（`Content-Type: application/x-www-form-urlencoded`），字段全部由 `MetaInfo` 设备信息拼成：

| 参数 | 客户端取值 | 备注 |
|---|---|---|
| `uid` | `tonumber(self.uid)`，无则 `-1` | 已有账号时非负 |
| `uuid` | `self.uuid` | |
| `udid` | `MetaInfo:getUdid()` | Android ID |
| `sdCardRoot` | `MetaInfo:getSdCardRoot()` | |
| `ip` / `localIpAddress` | `MetaInfo:getIpAddress()` / `getLocalIpAddress()` | |
| `phoneNumber` | `MetaInfo:getPhoneNum()` | |
| `imei` / `imsi` / `iccid` | `MetaInfo` 对应方法 | |
| `simCountry` | `MetaInfo:getSimCountry()` | |
| `netOperatorName` / `netOperatorNum` | `MetaInfo` | 运营商 |
| `filesDir` / `crashLogDir` | `MetaInfo` | 沙盒路径 |
| `packageName` | 包名 | |
| `language` / `location` / `timeZone` | `MetaInfo` | |
| `mac` | `MetaInfo:getMacAddress()` | |
| `apkVersionCode` / `gameVersion` | `MetaInfo` | |
| `clientVersion` / `clientType` | 系统版本 / 机型 | ⚠️ 与 RPC header 里的 `v`/`ct` **语义不同** |
| `machineType` / `deviceModel` | `MetaInfo` | |
| `equipment` | `crack` / `nocrack` | 越狱检测 |
| `networkInfo` / `networkType` / `carrier` | `MetaInfo` | |
| `densityIndependentPixel` / `dotsPerInch` / `resolution` / `resolutionWidth` / `resolutionHeight` | `MetaInfo` | `resolution` 形如 `1280*720` |
| `deviceSerialNumber` / `serial_number` | `MetaInfo` | |
| `sdk` | `MetaInfo:getSdk()` | |
| `cpuAbi` / `isCpuArmv7a` | `MetaInfo` | |
| `sessionUuid` / `installKey` / `install_key` | `MetaInfo` | |
| `isRoot` | `true` / `false` | |
| `releaseVersion` | `StartupConfig:getReleaseVersion()` | 本包 `11.0` |
| `store` / `src` / `platform` | `getPlatFormIgnoreDevice()` | 三个同值 |
| `uniqid` | = `udid` | 重复字段 |
| `isLongyuan` | 恒 `true` | |
| `simulator` | `CanonEnvInjector:isAndroidEmulator()` | 仅 Android |
| `timezoneDiff` | `TimeUtil.getTimeZoneTotalDiffSecWithServer()/3600 + 8` | 与 GMT 差的小时数，可为负 |
| `channelName` | `getPlatFormChannelName()` | 存在才带 |
| `android_id` | `MetaInfo:getUdid()` | 非 iOS 分支 |

**响应**（纯文本，必须 200 + 非空）：`<uid>,<uuid>,<sessionKey>`

- `uid` 必须能 `tonumber` 且 `> 0`，否则视为失败；`-1` 表示新用户。
- `uuid` 会作为 `uuid` 参数在下次 initSession 回传。
- `sessionKey` 即 RPC header 的 `sk`。

### 2.2 `POST /systemInfo`

定义：`canon/utils/SystemInfoCall.lua`。**无请求参数**，响应是**裸 AMF3 二进制**（`application/octet-stream`，不 zlib、不 headercvt）。

| 响应字段 | 类型 | 客户端用途 |
|---|---|---|
| `ts` | int | `_G.__g_utcDiffSeconds = os.difftime(ts, os.time())`，用于换算服务器时间。缺失则用本地时间 |
| （其余字段）| — | 服务端可下发 `serverPartitionConfig` 等，客户端登录页会用于渲染选服列表 |

### 2.3 `POST /check/<platform>?` —— 平台账号校验

URL 由 `DataManager.SystemConfig.Check<Platform>IdUrl` 决定，本包（`baiduDK` 渠道）走 `CheckDKIdUrl = {domain}/check/duoku?`；打过补丁切官方通道后走 `CheckAndroidIdUrl = {domain}/check/android?`。

定义：`canon/data/AndroidPlatformLogin.lua`、`canon/data/AccountPlatformLogin.lua:112-185`

| 参数 | 说明 |
|---|---|
| `udid` | URL-encoded 设备 ID |
| `seconds` | `TimeUtil.getServerTimeSeconds()` |
| `sk` | `md5(udid .. seconds .. "123456")`（Android/官方通道）；iOS 走 `PlatformMgr:encodeData(udid..seconds)` |
| `loginType` | `1` = 游客登录，`2` = 账号登录 |

**响应**（JSON）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | int | **必须 = 1**，否则弹网络错误 |
| `loginAccountId` | string/int | 登录账号 ID；客户端 `tonumber()` 后 `<=0` 或缺失视作新用户（`_uid = -1`）|

### 2.4 `POST /mappingAccount` —— 账号绑定映射

定义：`canon/data/AccountPlatformLogin.lua:62-109`、`canon/data/ThirdPlatformLogin.lua:644`

| 参数 | 说明 |
|---|---|
| `platformId` | `getPlatFormId()` |
| `platformUid` | 游客登录时 = 设备 ID；账号登录时 = `_uid`（URL-encoded）|
| `sid` | `/check/*` 返回并保存的 `sk`（URL-encoded）|

**响应**（JSON）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | int | 必须 = 1 |
| `accountId` | 正整数 | `tonumber(accountId) == -1` → 新用户；否则老用户。**必须是正整数** |
| `token` | string | 作为 `initSession` 的第二个参数回传 |

### 2.5 `POST /loginAccount/*` —— 账号登录 / 注册 / 改密 / 找回

所有接口共用 `doHttpRequest(url, params, cb, needEncode, needShowLoading)`（`canon/canonUtils.lua:734`），把 params 拼成 `k=v&k=v` 后 POST。

| 路径 | 参数 | 定义位置 |
|---|---|---|
| `/loginAccount/login` | `account`, `password`, `deviceId`, `seconds`, `sk=md5(account..password..seconds)` | `AccountPlatformLogin.lua:187-200` |
| `/loginAccount/register` | `account`, `password`（已 md5）, `email`（可选） | `GuestBindAccountPanel.lua:126`、`RegisterNewAccountPanel.lua:126` |
| `/loginAccount/rebind` | `account`, `deviceId`, `seconds`, `platformId`, `sk=md5(account..deviceId..seconds)` | `AccountPlatformLogin.lua:27-60` |
| `/loginAccount/modifyPassword` | `account`, `oldPassword`(md5), `newPassword`(md5), `seconds`, `sk=md5(account..old..new..seconds)` | `ModifyPasswordPanel.lua:119-126` |
| `/loginAccount/resetPassword` | `account`, `email`, `deviceId`, `seconds`, `sk=md5(account..email..seconds)` | `AccountPlatformLogin.lua:294-307` |
| `/loginAccount/hasVisitorAccount` | `platformId`, `deviceId` | `AccountPlatformLogin.lua:202-219` |

响应统一为 JSON，用 `rTable.code` 判成功（`1`），错误码 `-3` 注册重名、`-4` 不存在、`-5` 密码错/已注册、`-6` 未注册等。

### 2.6 `GET /getLoginServer?accountId=<id>`

定义：`canon/panel/ServerSelectPanel.lua:196-215`。

**响应是纯文本**，逗号分隔该账号已创建角色的 serverId 列表，如 `1,3`；`0` 或空表示无。客户端 `body:split(",")` 后 `tonumber` 逐个标灰已选服务器。

### 2.7 `POST /account?accountId=<id>` （ChangeAccountUrl）

定义：`canon/scene/LoginScene.lua:1067-1080`。**无 body**，账号 ID 在 query。

**响应是纯文本** `uid,uuid,sessionKey`，客户端直接 `localStorage.setCurrentUser(response.body)` 然后重连。

### 2.8 `GET /staticVersion`

由原生层发起，query 为 `clientVersion=11.0.61&releaseVersion=11.0&platform=baiduDK&debugVersion=false`，`User-Agent: HeMobileGame`。

| 响应字段 | 说明 |
|---|---|
| `static_url_root` | 静态资源根 |
| `config_md5` | **必须等于 APK 内 `assets/static_config.<md5>.xml` 文件名里的 md5**，否则客户端走 dynamicUpdate 并报 `dynamicUpdateNetError` |
| `need_download` | `false` 时直接用包内资源 |
| `can_download` | |
| `download_url` | |
| `langs` / `resolutions` / `ref` | |

### 2.9 打点域名（可全部忽略）

| 域名 | 用途 |
|---|---|
| `http://log.dc.cn.happyelements.com/restapi.php` | 乐元素 DC 打点（`DcUrl`），响应 `{}` 即可 |
| `http://etlog.happyelements.cn/logservice.php` | 日志上报（`LogUploadUrl`）|

---

## 3. TCP 实时通道（默认 9700）

### 3.1 建连流程

`canon/manager/TCPManager.lua`：

1. RPC 调 `/protocol` 的 `getSocketServer`，拿到 `{ serverAddress, serverPort, token }`。
2. 连 `serverAddress:serverPort`。
3. `EVENT_CONNECTED` 时发送：

```lua
{ serverAddress=..., serverPort=..., token=..., uid=tonumber(uid), method="login" }
```

4. 收到 `method == "login"` 且 **`retCode ~= 0`** → 判定失败，**每 11 秒重连**，主界面永远渲染不出来。

> ✅ 服务端 `login` ack 必须 `retCode = 0`。

### 3.2 帧格式（逐字节实测）

```
uint32 BE  长度 = (剩余头 10 字节 + AMF3 载荷长度)
10 字节    0x00
N 字节     AMF3 载荷
```

AMF3 用 **object 标记（0x0A）+ dynamic traits** 编码（不是关联数组）：

```
0a            object marker
0b            u29 traits: inline | new-class | dynamic, 0 sealed members
01            class name ""  (u29 (0<<1)|1)
<key><value>  dynamic members
01            空 key 结束
```

### 3.3 消息类型

| 方向 | method | 载荷 |
|---|---|---|
| C→S | `login` | `serverAddress, serverPort, token, uid, method` |
| S→C | `login` | `{ method="login", retCode=0 }` |

> 本包客户端**只有 `login` 一个具名 TCP 消息**；其余实时性内容靠 RPC 轮询或本地演出。

---

## 4. RPC 接口总表（共 363 个 method）

> 全部经 `POST {domain}/protocol?uid=<uid>`，AMF3 数组元素形如 `{method="<下表 method>", ...参数}`。
> 「参数」列为静态解析出的请求键（**不含框架自动附加的 `serverId`**）。

| 功能域 | 接口数 |
|---|---|
| Boss / 通缉 | 15 |
| 任务 / 成就 / 奖励 | 40 |
| 元数据 / 初始化 | 3 |
| 元神 | 7 |
| 关卡 / 战斗 | 8 |
| 其他 | 20 |
| 军团 | 60 |
| 卡牌养成 | 25 |
| 夺宝 / 神兽 | 3 |
| 好友社交 | 22 |
| 宝物 | 13 |
| 抽卡 / 合成 | 12 |
| 活动 | 27 |
| 登录 / 账号 / 连接 | 8 |
| 矩阵 | 2 |
| 竞技场 / PK | 14 |
| 装备 | 5 |
| 装备附灵 | 2 |
| 跨服 | 30 |
| 通天塔 | 10 |
| 道具 / 商店 | 21 |
| 邮件 | 16 |
| **合计** | **363** |

### 4.1 按功能域总表

#### Boss / 通缉（15）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`challengeMultiplayerBoss`](#ep-challengeMultiplayerBoss) | ChallengeMultiplayerBossRequest | `battleType`, `bossId`, `triggerUid` | `bossHpMax`, `bossInfo`, `globalReturnScene`, `win` |
| [`challengeWanted`](#ep-challengeWanted) |  | — | `wantedId`, `win` |
| [`challengeWorldBoss`](#ep-challengeWorldBoss) | ActivityCowStageRequest.lua - 世界Bo | `battleType` | `bossHp`, `bossHpMax` |
| [`exchangeItem`](#ep-exchangeItem) |  | `itemId` | `rewards` |
| [`gainMultiplayerBossParticipationReward`](#ep-gainMultiplayerBossParticipationReward) | GainMultiplayerBossParticipationRe | `bossKey` | `rewards` |
| [`gainMultiplayerBossRankReward`](#ep-gainMultiplayerBossRankReward) | GainMultiplayerBossRankRewardReque | — | `rewards` |
| [`gainWorldBossRewards`](#ep-gainWorldBossRewards) | ActivityCowStageRequest.lua - 世界Bo | — | — |
| [`getMultiplayerBossDamage`](#ep-getMultiplayerBossDamage) | GetMultiplayerBossDamageRequest | `bossId`, `triggerUid` | `damages` |
| [`getMultiplayerBossLeftHp`](#ep-getMultiplayerBossLeftHp) | GetMultiplayerBossLeftHpRequest | `bossId`, `triggerUid` | `leftHp` |
| [`getMultiplayerBossRank`](#ep-getMultiplayerBossRank) | GetMultiplayerBossRankRequest | `beginPos`, `endPos` | `currRankMax`, `multiPlayerBossRanks` |
| [`getWantedInfo`](#ep-getWantedInfo) |  | — | `wantedInfo` |
| [`getWorldBossInfo`](#ep-getWorldBossInfo) | ActivityCowStageRequest.lua - 世界Bo | — | — |
| [`inspireInWorldBoss`](#ep-inspireInWorldBoss) | ActivityCowStageRequest.lua - 世界Bo | `worldBossInspireInfos` | — |
| [`refreshWanted`](#ep-refreshWanted) |  | `minimum` | `wantedId` |
| [`setAutoWorldBoss`](#ep-setAutoWorldBoss) | ActivityCowStageRequest.lua - 世界Bo | `autoChallenge` | — |
#### 任务 / 成就 / 奖励（40）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`gainAchievementReward`](#ep-gainAchievementReward) | GainAchievementRewardRequest | `achievementId`, `achievementType` | `reward` |
| [`gainActiveReward`](#ep-gainActiveReward) | ActiveRewardRequest | `activeRewardId` | `rewards` |
| [`gainBalloonPointReward`](#ep-gainBalloonPointReward) |  | `id` | `balloonRanks` |
| [`gainBalloonRankReward`](#ep-gainBalloonRankReward) |  | — | `balloonRanks` |
| [`gainChapterFinishReward`](#ep-gainChapterFinishReward) | GainChapterFinishRewardRequest | `chapterId` | `amount`, `itemType`, `metaId`, `reward` |
| [`gainChargeMoneyReward`](#ep-gainChargeMoneyReward) |  | `id` | `rewards` |
| [`gainConsumeReward`](#ep-gainConsumeReward) | 多重好礼获取面板信息接口 / 接口定义 后端提供 | `id` | `rewards` |
| [`gainDailyAchieveReward`](#ep-gainDailyAchieveReward) | 获取每日成就信息 | `achieveId` | `rewards` |
| [`gainDailyTaskReward`](#ep-gainDailyTaskReward) |  | `taskId` | `rewards` |
| [`gainDayReward`](#ep-gainDayReward) |  | `dayRewardId` | — |
| [`gainDiceReward`](#ep-gainDiceReward) | DiceGainRewardRequest | — | `changeDiceLuckCount`, `changeLuckCountPerThrow`, `diceNewRewards`, `gainedCoin`, `throwDiceCount` |
| [`gainFbActivityReward`](#ep-gainFbActivityReward) | Facebook相关 | — | `rewards` |
| [`gainFortuneRewards`](#ep-gainFortuneRewards) | GainFortuneRewardsRequest | — | `id`, `rewards` |
| [`gainGemConsumeRewards`](#ep-gainGemConsumeRewards) |  | `rewardId` | `rewards` |
| [`gainGoldGodRewards`](#ep-gainGoldGodRewards) | GainGoldGodRewardsRequest | — | `rewards` |
| [`gainInviteReward`](#ep-gainInviteReward) | 领取邀请好友奖励 | — | `rewards` |
| [`gainInvitedReward`](#ep-gainInvitedReward) | 领取邀请好友奖励 | `deviceId`, `invitationCode` | `rewards` |
| [`gainLevelRaceRewards`](#ep-gainLevelRaceRewards) | GainLevelRaceRewardsRequest | `level` | `rewards` |
| [`gainMondayReward`](#ep-gainMondayReward) |  | — | `rewards` |
| [`gainNewYearRewards`](#ep-gainNewYearRewards) | GainNewYearRewardsRequest | `id` | `rewards` |
| [`gainRankFirstReward`](#ep-gainRankFirstReward) | GainRankFirstRewardRequest | `rank` | `amount`, `itemType`, `metaId`, `rewards` |
| [`gainRankRewards`](#ep-gainRankRewards) |  | — | `rewards` |
| [`gainSwornReward`](#ep-gainSwornReward) |  | `swornRewardId` | `rewards` |
| [`gainTutorialFinishReward`](#ep-gainTutorialFinishReward) |  | — | `rewards` |
| [`getAchievements`](#ep-getAchievements) | GetAchievementsRequest | — | `cardBookAchievement`, `sharkAchievement` |
| [`getChargeFeedbackReward`](#ep-getChargeFeedbackReward) |  | `rewardId` | `rewards` |
| [`getConsumeRewardInfo`](#ep-getConsumeRewardInfo) | 多重好礼获取面板信息接口 / 接口定义 后端提供 | — | `recharges`, `rewards` |
| [`getContinuousLoginReward`](#ep-getContinuousLoginReward) | RewardRequest.lua - all request re | `getBigReward` | `bigReward`, `reward`, `rewardId` |
| [`getCountdownReward`](#ep-getCountdownReward) | 获取新手礼包请求 | — | `finished`, `inProcessRewardId`, `latestRewardTimestamp`, `rewards` |
| [`getDailyAchieveInfo`](#ep-getDailyAchieveInfo) | 获取每日成就信息 | — | — |
| [`getDailyActiveInfo`](#ep-getDailyActiveInfo) | GetDailyActiveInfoRequest | — | `dailyActiveInfo`, `dailyActiveInfo.activeValue`, `dailyActiveInfo.gainedRewards`, `dailyActiveInfo.taskCounters` |
| [`getLoginReward`](#ep-getLoginReward) | RewardRequest.lua - all request re | `*(动态)*` | — |
| [`getMonthlyLoginRewardMeta`](#ep-getMonthlyLoginRewardMeta) | RewardRequest.lua - all request re | `*(动态)*` | `adNum`, `monthlyLoginRewardItems` |
| [`getQuestionDailyReward`](#ep-getQuestionDailyReward) |  | — | `dailyNum`, `questionId`, `questionNum`, `wrongAnswer1Key`, `wrongAnswer2Key`, `wrongAnswer3Key` |
| [`getRewardList`](#ep-getRewardList) | RewardRequest.lua - all request re | — | `sharkRewardList` |
| [`getSignInReward`](#ep-getSignInReward) | RewardRequest.lua - all request re | `*(动态)*` | — |
| [`getTaskInfo`](#ep-getTaskInfo) |  | — | `dailyTaskInfos` |
| [`getWeekReward`](#ep-getWeekReward) |  | — | — |
| [`pickUpAllReward`](#ep-pickUpAllReward) | RewardRequest.lua - all request re | `pickUpCard`, `pickUpEquip` | `rewards` |
| [`pickUpReward`](#ep-pickUpReward) | RewardRequest.lua - all request re | `rewardId` | `reward` |
#### 元数据 / 初始化（3）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`gameInit`](#ep-gameInit) |  | — | `maintenanceItem`, `noChatEndSeconds`, `sharkAchievement` |
| [`getAnnouncementInfo`](#ep-getAnnouncementInfo) | 获取公告信息请求 | — | `announcementItemMetas` |
| [`getMeta`](#ep-getMeta) | GetGameMetaRequest.lua - 获取游戏元配置的请 | — | — |
#### 元神（7）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`buySpiritPool`](#ep-buySpiritPool) | 购买元神格子 | — | `requisite`, `requisite.amount` |
| [`equipSpirit`](#ep-equipSpirit) | 装备元神 | `cardId`, `index`, `spiritId` | — |
| [`sellSpirit`](#ep-sellSpirit) | 卖出元神 | `spiritIds` | `rewards` |
| [`setAutoSave`](#ep-setAutoSave) | 元神刷新复选框 | `autoSave` | — |
| [`spiritConcentrate`](#ep-spiritConcentrate) |  | `type` | `sharkSpirits` |
| [`unequipSpirit`](#ep-unequipSpirit) | 卸下元神 | `cardId`, `index` | — |
| [`upgradeSpirit`](#ep-upgradeSpirit) | 强化元神 | `masterSpiritId`, `slaveSpiritIds` | `sharkSpirit`, `sharkSpirit.spiritId` |
#### 关卡 / 战斗（8）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`challengeElite`](#ep-challengeElite) | ChallengeEliteRequest.lua - 挑战精英关卡 | `eliteId` | `selectId`, `win` |
| [`changeBattleArray`](#ep-changeBattleArray) |  | `battleArrayId` | — |
| [`clearElite`](#ep-clearElite) | 精英关卡扫荡 | `eliteId` | `challengeNum`, `lastEnergy`, `mergeRewards`, `rewards` |
| [`clearMission`](#ep-clearMission) | ClearMissionRequest | `clearRounds`, `missionId`, `routeId` | `clearMissionRewards` |
| [`getEliteInfo`](#ep-getEliteInfo) | GetEliteInfoRequest.lua - 获取精英关卡信息 | — | — |
| [`resetClearTime`](#ep-resetClearTime) | ResetClearTimeRequest | — | `gemRequisite`, `gemRequisite.amount` |
| [`resetElite`](#ep-resetElite) | ResetEliteRequest.lua - 重置精英关卡信息 | `eliteId` | — |
| [`triggerBattleEvent`](#ep-triggerBattleEvent) |  | `DoNotCaptureFailueMessage`, `battleType`, `missionId`, `routeId`, `step` | — |
#### 其他（20）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`adjustTeam`](#ep-adjustTeam) | 调整队列请求 | `additionalCardIds`, `mainCardId` | — |
| [`gainFloorAddition`](#ep-gainFloorAddition) |  | `type` | — |
| [`gainYesterdayAddition`](#ep-gainYesterdayAddition) |  | `type` | — |
| [`getHomeInfo`](#ep-getHomeInfo) | 获取主页信息请求 | — | `consumeRewardRecharges`, `consumeRewards`, `freeSpiritRefreshNum`, `unionMonsterEscapeSeconds`, `unionMonsterHp` |
| [`getMultiplayserBossInfo`](#ep-getMultiplayserBossInfo) | GetMultiplayserBossInfoRequest | — | — |
| [`getPlayerTeamInfo`](#ep-getPlayerTeamInfo) | GetPlayerTeamInfoRequest.lua - 培养卡 | `playerTeamData`, `playerUid` | — |
| [`getUserBanInfo`](#ep-getUserBanInfo) | 刷新元神副属性 | — | `noChatEndSeconds` |
| [`login`](#ep-login) |  | — | — |
| [`rebirthItem`](#ep-rebirthItem) | 武将重生 | `resourceId`, `resourceType` | `rewards` |
| [`recordAddictedTime`](#ep-recordAddictedTime) |  | `minutes` | — |
| [`recordTutorialStep`](#ep-recordTutorialStep) |  | `funcName`, `step` | — |
| [`refreshSubAttribute`](#ep-refreshSubAttribute) | 刷新元神副属性 | `lockIndex`, `refreshType`, `spiritId` | `refreshSharkSpiritAttribute` |
| [`rename`](#ep-rename) | 卖出元神 | `nickName` | — |
| [`sacrificeItem`](#ep-sacrificeItem) | 武将祭炼 | `resourceIds`, `resourceType` | `rewards` |
| [`selectSubAttribute`](#ep-selectSubAttribute) | 卖出元神 | `refreshIndex`, `spiritId` | — |
| [`triggerCoinEvent`](#ep-triggerCoinEvent) | TriggerCoinEventRequest | `DoNotCaptureFailueMessage`, `missionId`, `routeId`, `step` | — |
| [`triggerEmptyEvent`](#ep-triggerEmptyEvent) | TriggerEmptyEventRequest | `DoNotCaptureFailueMessage`, `missionId`, `routeId`, `step` | — |
| [`triggerExpEvent`](#ep-triggerExpEvent) | TriggerExpEventRequest | `DoNotCaptureFailueMessage`, `missionId`, `routeId`, `step` | — |
| [`triggerRandomEvent`](#ep-triggerRandomEvent) | TriggerRandomEventRequest | `DoNotCaptureFailueMessage`, `missionId`, `routeId`, `step` | `eventType` |
| [`validatePaymentOrder`](#ep-validatePaymentOrder) |  | `goldNum`, `orderId`, `productId` | `succ` |
#### 军团（60）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`acceptUnionApply`](#ep-acceptUnionApply) | 军团同意申请 | `applierUid` | — |
| [`applyCrossGvg`](#ep-applyCrossGvg) | 跨服GvG  报名请求 | `type` | — |
| [`applyUnion`](#ep-applyUnion) | 请求加入某军团 | `unionId` | — |
| [`applyUnionCity`](#ep-applyUnionCity) | 军团战 报名攻打城池 | `unionCityId` | — |
| [`appointUnion`](#ep-appointUnion) | 任命职务请求 | `appointUid`, `title` | — |
| [`blessForCrossGVG`](#ep-blessForCrossGVG) | 跨服GvG  祝福请求 | — | `rank`, `rewards` |
| [`buyUnionProp`](#ep-buyUnionProp) | BuyUnionPropRequest | `unionPropId`, `unionPropType` | `retCode`, `rewards` |
| [`cancelDissolveUnion`](#ep-cancelDissolveUnion) | 取消解散军团 | — | — |
| [`cancelTransferUnion`](#ep-cancelTransferUnion) | 撤销转让军团长 | — | — |
| [`cancelUnionApply`](#ep-cancelUnionApply) | 取消申请 | `unionId` | — |
| [`challengeUnionMonster`](#ep-challengeUnionMonster) | 军团挑战怪物 | — | `bossHpMax`, `generalExp` |
| [`constructUnion`](#ep-constructUnion) | 建设 | `constructType` | — |
| [`createUnion`](#ep-createUnion) | 创建军团请求 | `coinType`, `declaration`, `notice`, `unionName` | `sharkUnion`, `sharkUnion.unionId` |
| [`crossGVGGroupBattle`](#ep-crossGVGGroupBattle) | 获得跨服军团战小组赛战斗信息 | — | — |
| [`dissolveUnion`](#ep-dissolveUnion) | 解散军团请求 | — | `sharkUnion`, `sharkUserUnion` |
| [`exchangeUnionFormation`](#ep-exchangeUnionFormation) | 军团战更换阵型请求 | `forwardUid`, `headUids`, `middleUids`, `tailUids`, `unionCityId` | — |
| [`forceQuitUnion`](#ep-forceQuitUnion) | 军团踢人请求 | `quitUid` | — |
| [`gainUnionBattleReward`](#ep-gainUnionBattleReward) | 军团战 请求获得 我的奖励 | `rewardId` | `rewards` |
| [`getAppliedUnions`](#ep-getAppliedUnions) | 请求获取当前玩家的已申请军团列表 | — | `sharkUnionWrappers` |
| [`getApplyUnions`](#ep-getApplyUnions) | 军团战 获得指定城池具体信息 | `unionCityId` | — |
| [`getCrossGVGBlessInfo`](#ep-getCrossGVGBlessInfo) | 跨服GvG  祝福请求 | — | `crossGvgVersion`, `rank`, `rewards`, `selfApplyCrossGvg`, `selfQuitCrossGvg`, `unionApplyCrossGvg` |
| [`getCrossGvgGroupReports`](#ep-getCrossGvgGroupReports) | 获得跨服军团战小组赛战报 | — | — |
| [`getCrossGvgGroupTop10Score`](#ep-getCrossGvgGroupTop10Score) | 取得跨服gvg 排位赛数据 | — | — |
| [`getFiredUnionMemberStatus`](#ep-getFiredUnionMemberStatus) | 获得踢人之前获得被踢玩家当前状态 | `firedUid` | — |
| [`getGvgBattleResultDetail`](#ep-getGvgBattleResultDetail) | 获取gvg战斗信息 | `knockout`, `reportId` | — |
| [`getGvgKnockoutInfo`](#ep-getGvgKnockoutInfo) | 取得跨服gvg 排位赛数据 | — | `championBattle` |
| [`getOwnUnionInfo`](#ep-getOwnUnionInfo) | 军团战 获得 我的军团 列表信息 | — | — |
| [`getUnionAppliers`](#ep-getUnionAppliers) | 请求获得申请者列表 | — | `sharkUnionAppliers` |
| [`getUnionBattlefieldReport`](#ep-getUnionBattlefieldReport) | 战报接口 | `reportId`, `unionCityId` | — |
| [`getUnionBattlefieldReportList`](#ep-getUnionBattlefieldReportList) | 军团战 获得指定城池具体信息 | `unionCityId` | — |
| [`getUnionBuildingBankInfo`](#ep-getUnionBuildingBankInfo) | GetUnionBuildingBankInfoRequest | — | `level` |
| [`getUnionBuildingColosseumInfo`](#ep-getUnionBuildingColosseumInfo) | 军团斗兽场建筑信息 | — | `level`, `rankList`, `sharkUnionMonster`, `sharkUnionMonster.distributingUid`, `sharkUnionMonster.escapeSeconds`, `sharkUnionMonster.monsterId` |
| [`getUnionBuildingHallInfo`](#ep-getUnionBuildingHallInfo) | GetUnionBuildingHallInfoRequest | — | `constructTimesToday`, `lastestConstructSeconds` |
| [`getUnionBuildingShopInfo`](#ep-getUnionBuildingShopInfo) | GetUnionBuildingShopInfoRequest | — | `level`, `specialProps`, `specialShopRecord` |
| [`getUnionCityInfo`](#ep-getUnionCityInfo) | 军团战 获得指定城池具体信息 | `unionCityId` | `sharkUnionCity`, `sharkUnionCity.report`, `sharkUnionCity.successfulBid`, `unionFormation` |
| [`getUnionCityList`](#ep-getUnionCityList) | 军团战 获得城池列表 | — | `attendBattleNum`, `challengeCityIds`, `fightingCityIds`, `ownCityIds`, `roundWealth`, `smallCityNum` |
| [`getUnionFormation`](#ep-getUnionFormation) | 获取军团战阵型信息 | `unionCityId` | `sharkUnionCityApply`, `unionFormation` |
| [`getUnionInfo`](#ep-getUnionInfo) | 请求获得军团信息 | — | `canDistributeMonsterReward`, `sharkUnion`, `sharkUnionBuildingWrapper`, `unionMonsterEscapeSeconds`, `unionMonsterHp`, `unionTotalFightCapacity` |
| [`getUnionList`](#ep-getUnionList) | 查询军团列表请求 | `amount`, `startNum` | `sharkUnionWrappers` |
| [`getUnionMembersList`](#ep-getUnionMembersList) | 获得军团成员列表 | — | `sharkUnionMemberWrappers` |
| [`getUnionMonsterRank`](#ep-getUnionMonsterRank) | 获得斗兽场排行榜 | — | `rankList` |
| [`getUnionNewsList`](#ep-getUnionNewsList) | 获得军团动态请求 | — | `sharkUnionNewsWrappers`, `unionWarNewsWrappers` |
| [`getUnionWarCityMembersList`](#ep-getUnionWarCityMembersList) | 获得军团战城池报名成员列表 | `cityId` | `unionFormation` |
| [`getUserUnionInfo`](#ep-getUserUnionInfo) | 获得当前玩家的军团信息 | — | `crossGvgVersion`, `out`, `promotion`, `selfApplyCrossGvg`, `selfQuitCrossGvg`, `sharkUserUnion` |
| [`impeachUnionManager`](#ep-impeachUnionManager) | 弹劾军团长 | — | `currManagerNickName` |
| [`inspireUnionBattle`](#ep-inspireUnionBattle) | 鼓舞接口中BuffId / 1：金币鼓舞 / 2：银币鼓舞 / 3： | `buffId`, `unionCityId` | — |
| [`modifyUnionDeclaration`](#ep-modifyUnionDeclaration) | 换宣言请求 | `declaration` | — |
| [`modifyUnionNotice`](#ep-modifyUnionNotice) | 换公告请求 | `notice` | — |
| [`quitUnion`](#ep-quitUnion) | 退出军团请求 | — | `sharkUserUnion` |
| [`receiveUnionWage`](#ep-receiveUnionWage) | ReceiveUnionWageRequest | `unionWageId` | `rewards` |
| [`rejectUnionAllApplies`](#ep-rejectUnionAllApplies) | 请求全部拒绝 | — | — |
| [`rejectUnionApply`](#ep-rejectUnionApply) | 军团拒绝申请 | `applierUid` | — |
| [`searchUnion`](#ep-searchUnion) | 查找军团请求 | `unionName` | `sharkUnionWrappers` |
| [`summonUnionMonster`](#ep-summonUnionMonster) | 召唤军团boss | `monsterMetaId`, `summonType` | `sharkUnionMonster`, `sharkUnionMonster.distributingUid`, `sharkUnionMonster.escapeSeconds`, `sharkUnionMonster.monsterId`, `sharkUnionMonster.monsterLeftHp`, `sharkUnionMonster.reward.amount` |
| [`transferUnion`](#ep-transferUnion) | 移交军团长请求 | `transferedUid` | `transferTime` |
| [`unionMonsterRewardDistributeBegin`](#ep-unionMonsterRewardDistributeBegin) | 军团斗兽场开始分配 | — | `currMonsterRewards` |
| [`unionMonsterRewardDistributeGiveUp`](#ep-unionMonsterRewardDistributeGiveUp) | 军团斗兽场放弃分配 | — | — |
| [`unionMonsterRewardDistributeSave`](#ep-unionMonsterRewardDistributeSave) | 军团斗兽场分配奖励 | `unionMonsterRewards` | — |
| [`upgradeUnionBuilding`](#ep-upgradeUnionBuilding) | 升级建筑请求 | `unionBuildingId` | `currLevel` |
| [`userApplyUnionCity`](#ep-userApplyUnionCity) | 团员报名指定城池 | `unionCityId` | — |
#### 卡牌养成（25）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`adjustCardAvatar`](#ep-adjustCardAvatar) | 卖出元神 | `avatarMetaId`, `cardId` | — |
| [`buyMonthGemCard`](#ep-buyMonthGemCard) | BuyMonthGemCardRequest | — | `monthGemCardDeadline` |
| [`evolveCard`](#ep-evolveCard) | 卡牌进化Request / 参数1：masterId / 参数2：s | `masterId`, `slaveId` | `sharkCard`, `sharkCard.metaId` |
| [`evolveEquip`](#ep-evolveEquip) | EvolveEquipRequest | `equipId`, `userGems` | `equipId`, `sharkEquip` |
| [`exchangeCard`](#ep-exchangeCard) | 卡牌以旧换新兑换请求 | `cardId`, `shopId` | `reward` |
| [`exchangeCardDaily`](#ep-exchangeCardDaily) | 易帅换将 | `cardId`, `metaId` | `reward` |
| [`exchangeTrainDanByArenaScore`](#ep-exchangeTrainDanByArenaScore) | ExchangeTrainDanRequest | `exchangeType` | `amount`, `itemType`, `metaId`, `requisite`, `rewards` |
| [`gainedMonthGemCardReward`](#ep-gainedMonthGemCardReward) | GainMonthCardRequest | — | `rewards` |
| [`getCardBook`](#ep-getCardBook) | GetCardBookRequest.lua - get cards | — | `sharkCardBook`, `sharkCardBook.cardMetaIds`, `sharkCardBook.equipMetaIds` |
| [`giveUpCardTrain`](#ep-giveUpCardTrain) | GiveUpCardTrainRequest.lua - 放弃卡片培 | `cardId`, `masterId`, `slaveIds`, `*(动态)*` | `sharkCard`, `sharkCard.usedPotential` |
| [`lockCard`](#ep-lockCard) | LockCardRequest | `cardId`, `methodType` | — |
| [`prayCardFragment`](#ep-prayCardFragment) | PrayCardFragmentRequest | `cardId` | `prayNum`, `rewards` |
| [`refreshCardExchangeDaillyCard`](#ep-refreshCardExchangeDaillyCard) |  | `useGold` | `cardExchangeDailyInfo`, `cardExchangeDailyInfo.cardMetaIds`, `cardExchangeDailyInfo.exchangeTimes` |
| [`replaceCard`](#ep-replaceCard) | ReplaceCardRequest.lua - 重整队列的请求 | `insertCardId` | `type` |
| [`saveCardTrain`](#ep-saveCardTrain) | SaveCardTrainRequest.lua - 保存卡片培养结 | `masterId`, `slaveIds`, `*(动态)*` | `sharkCard`, `sharkCard.cardId`, `sharkCard.usedPotential` |
| [`sellCards`](#ep-sellCards) | SellCardsRequest.lua - 出售装备的请求 | `cardIds` | `rewards` |
| [`setCardGroupInterworking`](#ep-setCardGroupInterworking) | 领取邀请好友奖励 | `cardGroupInterworking` | — |
| [`splitCard`](#ep-splitCard) | SplitCardRequest | `cardId` | `rewards` |
| [`trainCard`](#ep-trainCard) | CardTrainingRequest.lua - 培养卡片的请求 | `*(动态)*` | `attTrainValue`, `defTrainValue`, `hpTrainValue` |
| [`triggerCardEvent`](#ep-triggerCardEvent) | TriggerCardEventRequest | `DoNotCaptureFailueMessage`, `missionId`, `routeId`, `step` | — |
| [`unlockSubAttribute`](#ep-unlockSubAttribute) | 解锁元神副属性 | `spiritId` | `sharkSpiritAttribute` |
| [`upgradeCardByGeneralExp`](#ep-upgradeCardByGeneralExp) | 卡牌经验强化接口 | `masterId`, `targetLevel` | `sharkCard` |
| [`upgradeEquipForOneCard`](#ep-upgradeEquipForOneCard) | 卡牌装备全部强化 | `equipIds` | `sharkEquips` |
| [`upgradeSkill`](#ep-upgradeSkill) | UpgradeSkillRequest.lua - 技能升级的请求 | `cardId`, `skillBooks`, `skillId` | `cardSkill`, `cardSkill.skillId` |
| [`upgradeUser`](#ep-upgradeUser) | UpgradeUserRequest.lua - 用户升级的请求 | — | `sharkUser` |
#### 夺宝 / 神兽（3）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`getRobUserList`](#ep-getRobUserList) | GetRobUserListRequest | `beastFragmentId` | — |
| [`getSharkBeasts`](#ep-getSharkBeasts) |  | — | `sharkBeasts` |
| [`robBeastFragment`](#ep-robBeastFragment) | RobBeastFragmentRequest | `beastFragmentId`, `enemyUid`, `robType`, `robotId` | — |
#### 好友社交（22）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`acceptAllFreeGift`](#ep-acceptAllFreeGift) | SendAllFreeGiftRequest.lua - 向玩家发送 | — | `gainedEnergy` |
| [`acceptAllInvitations`](#ep-acceptAllInvitations) | AcceptAllInvitationsRequest.lua -  | — | `acceptedFriends`, `reviewingFriends` |
| [`acceptInvitation`](#ep-acceptInvitation) | AcceptInvitationRequest.lua - 接受玩家 | `friendUid` | `acceptedFriend` |
| [`cancelInvitation`](#ep-cancelInvitation) | CancelInvitationRequest.lua - 接受玩家 | `friendUid` | — |
| [`challengeFriend`](#ep-challengeFriend) | ChallengeFriendRequest.lua - 与好友切磋 | `friendUid` | `tableContentHeight` |
| [`challengeFriendList`](#ep-challengeFriendList) | 一键切磋 | `friendUids` | `rewards` |
| [`deleteFriend`](#ep-deleteFriend) | DeleteFriendRequest.lua - 接受玩家的添加好 | `friendUid` | — |
| [`gainPraiseReward`](#ep-gainPraiseReward) | 领取点赞礼包奖励 | `praiseId` | `rewards` |
| [`getFriendDetail`](#ep-getFriendDetail) | GetFriendDetailRequest.lua - 获取好友的 | `friendUid` | `sharkFriendDetail`, `sharkFriendDetail.fightCapacity`, `sharkFriendDetail.friendUid`, `sharkFriendDetail.level`, `sharkFriendDetail.mainCardMetaId`, `sharkFriendDetail.nickName` |
| [`getFriends`](#ep-getFriends) | GetFriendsRequest.lua - 获取当前玩家的好友信 | — | `receivedEnergy`, `sharkFriends` |
| [`getInvitationFriends`](#ep-getInvitationFriends) | GetFriends.lua - 获取当前玩家的好友信息 | — | `sharkFriends` |
| [`getInvitationInfo`](#ep-getInvitationInfo) | 领取邀请好友奖励 | `deviceId` | `deviceHasInvited`, `sharkAccountInvitation` |
| [`getRecommendedFriends`](#ep-getRecommendedFriends) | GetRecommendedFriendsRequest.lua - | — | `sharkFriends` |
| [`getReviewFriends`](#ep-getReviewFriends) | GetReviewFriendsRequest.lua - 获取等待 | — | `sharkFriends` |
| [`inviteFbFriends`](#ep-inviteFbFriends) | Facebook相关 | `fbFriendIds` | — |
| [`recordPraiseId`](#ep-recordPraiseId) | 获取记录点赞id | `praiseId` | — |
| [`refuseAllInvitations`](#ep-refuseAllInvitations) | RefuseAllInvitationsRequest.lua -  | — | — |
| [`refuseInvitation`](#ep-refuseInvitation) | RefuseInvitationRequest.lua - 拒绝玩家 | `friendUid` | — |
| [`sendAllFreeGift`](#ep-sendAllFreeGift) | SendAllFreeGiftRequest.lua - 向玩家发送 | `friendUids` | `friendUids`, `gainedEnergy` |
| [`sendAllInvitations`](#ep-sendAllInvitations) | SendAllInvitationsRequest.lua - 发送 | `friendUids` | `friendUids` |
| [`sendFreeGift`](#ep-sendFreeGift) | SendFreeGiftRequest.lua - 向玩家发送免费礼 | `friendUid` | `gainedEnergy` |
| [`sendInvitation`](#ep-sendInvitation) | SendInvitationRequest.lua - 发送邀请 | `friendUid` | — |
#### 宝物（13）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`buyTreasureGrid`](#ep-buyTreasureGrid) | 宝物格子 | `*(动态)*` | — |
| [`evolveTreasure`](#ep-evolveTreasure) | 宝物升星 | `treasureId` | `sharkTreasure` |
| [`gachaTreasure`](#ep-gachaTreasure) | 宝物扭蛋 | `free`, `time` | `rewards` |
| [`gainTreasureboxPointsRankReward`](#ep-gainTreasureboxPointsRankReward) | TreasureboxRankRewardRequest.lua | — | `rewards` |
| [`gainTreasureboxPointsReward`](#ep-gainTreasureboxPointsReward) | TreasureboxPointRewardRequest.lua | `id` | `rewards` |
| [`getTreasureboxPointsInfo`](#ep-getTreasureboxPointsInfo) | TreasureboxPointsInfoGetRequest.lu | — | `treasureboxPointsRanks` |
| [`lockTreasure`](#ep-lockTreasure) | 宝物锁定 | `treasureId`, `type` | — |
| [`potentialTreasure`](#ep-potentialTreasure) | 宝物激发 | `treasureId`, `type` | `sharkTreasure` |
| [`resetTreasurePotential`](#ep-resetTreasurePotential) | 宝物重置潜力 | `treasureId` | — |
| [`sellTreasures`](#ep-sellTreasures) | 卖出宝物 | `treasureIds` | `rewards` |
| [`setupTreasure`](#ep-setupTreasure) | 装备宝物 / 装备元神 | `cardId`, `treasureId` | — |
| [`splitTreasure`](#ep-splitTreasure) | request / /request / response / /r | `treasureId` | `rewards` |
| [`upgradeTreasure`](#ep-upgradeTreasure) | 宝物强化 | `oneClick`, `treasureId` | `sharkTreasure` |
#### 抽卡 / 合成（12）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`gachaCard`](#ep-gachaCard) |  | `gachaId`, `time` | `countdownFreeGachaInfos`, `free`, `rewards` |
| [`gachaCardByBox`](#ep-gachaCardByBox) | 领取邀请好友奖励 | — | `rewards` |
| [`gachaCardFree`](#ep-gachaCardFree) |  | `gachaId` | `countdownFreeGachaInfos`, `free`, `rewards` |
| [`gainGachaPointsRewards`](#ep-gainGachaPointsRewards) | GainGachaPointsRewardsRequest | — | `rewards` |
| [`getGachaBroadcast`](#ep-getGachaBroadcast) |  | — | — |
| [`getGachaPointsInfo`](#ep-getGachaPointsInfo) | GetGachaPointsInfoRequest | — | — |
| [`getSharkGachaBoxInfo`](#ep-getSharkGachaBoxInfo) | 领取邀请好友奖励 | — | `gachaBoxCard` |
| [`refreshGachaBox`](#ep-refreshGachaBox) | 领取邀请好友奖励 | `refreshType` | `gachaBoxCard` |
| [`synthetizeCard`](#ep-synthetizeCard) | FragmentSynthetizeCardRequest 卡牌碎片 | `metaId` | `rewards` |
| [`synthetizeEquip`](#ep-synthetizeEquip) | FragmentSynthetizeEquipRequest 武器碎 | `metaId` | `rewards` |
| [`synthetizeItem`](#ep-synthetizeItem) |  | `formulaId` | — |
| [`upgradeCard`](#ep-upgradeCard) | 卡牌合成Request / 参数1：masterId / 参数2：s | `masterId`, `slaveIds` | `sharkCard`, `sharkCard.metaId` |
#### 活动（27）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`answerQuestion`](#ep-answerQuestion) |  | `answer`, `questionMetaId` | `nextQuestionMetaId`, `over`, `result`, `wrongAnswer1Key`, `wrongAnswer2Key`, `wrongAnswer3Key` |
| [`challengeChrist`](#ep-challengeChrist) | MerryChristmasChallengeRequest.lua | `christId` | `bigReward`, `chapterFinishReward`, `dialogId`, `retCode`, `win` |
| [`challengeCowStage`](#ep-challengeCowStage) | ActivityCowStageRequest.lua - 牧场大战 | `cowStageId` | `selectId`, `win` |
| [`challengeMysterious`](#ep-challengeMysterious) | request / /request / response | `difficultyDegree`, `id` | — |
| [`changeDiceLuck`](#ep-changeDiceLuck) | DiceChangeLuckRequest | — | `changeDiceLuckCount`, `changeLuckCountPerThrow`, `diceNewRewards`, `gainedCoin`, `throwDiceCount` |
| [`chargeBalloon`](#ep-chargeBalloon) |  | `ensureSuccess` | `currPoint` |
| [`defaultPhoneNum`](#ep-defaultPhoneNum) | 修改/设定玩家手机号码 | `phoneNum` | — |
| [`distributeBonus`](#ep-distributeBonus) | 分配红包，区分好友和军团 | `accepterList`, `accepterType`, `bonusId` | — |
| [`eatPeach`](#ep-eatPeach) | ActivityEatPeachRequest.lua - 吃桃补充 | `featureName` | `gainedEnergy` |
| [`gainBalloonPoint`](#ep-gainBalloonPoint) |  | — | `currPoint` |
| [`gainLimitReward`](#ep-gainLimitReward) | ActiveRechangeRequest.lua / 2014-1 | `stepId` | — |
| [`getAccumulateGems`](#ep-getAccumulateGems) | GetAccumulateGemsRequest | — | `accumulateGems` |
| [`getAccumulateRechargeInfo`](#ep-getAccumulateRechargeInfo) |  | — | `remainingDays`, `rewards` |
| [`getActivityBalloonInfo`](#ep-getActivityBalloonInfo) |  | — | `balloonRanks`, `currPoint` |
| [`getBonusAccepterList`](#ep-getBonusAccepterList) | 分配红包，区分好友和军团 | `bonusId` | `friendList`, `unionList` |
| [`getDailyRecharge`](#ep-getDailyRecharge) | 获得充值活动最新状态接口 | — | `dailyRecharge` |
| [`getGemConsumeInfo`](#ep-getGemConsumeInfo) |  | `rewardId` | `consumeGems`, `gainedRewards` |
| [`getLevelRaceInfo`](#ep-getLevelRaceInfo) | GetLevelRaceInfoRequest | — | `levelRaceRanks` |
| [`getMaintenanceMeta`](#ep-getMaintenanceMeta) | GetActivityOnOffConfigRequest.lua  | — | `maintenanceItem` |
| [`getQuestionInfo`](#ep-getQuestionInfo) |  | — | `dailyNum`, `questionId`, `questionNum`, `wrongAnswer1Key`, `wrongAnswer2Key`, `wrongAnswer3Key` |
| [`rechargeCalls`](#ep-rechargeCalls) | 送话费活动 获取话费 | `callsType`, `phoneNum` | — |
| [`recordActivityFbShare`](#ep-recordActivityFbShare) | Facebook相关 | — | — |
| [`recordGameFbShare`](#ep-recordGameFbShare) | Facebook相关 | `shareId`, `shareSuccess` | — |
| [`resetChrist`](#ep-resetChrist) | MerryChristmasResetRequest.lua / z | `christId` | `retCode` |
| [`setoffFireworks`](#ep-setoffFireworks) | FireworksFireRequest.lua - 向玩家发送免费 | — | `rewards` |
| [`throwDice`](#ep-throwDice) | DiceRollRequest | — | `changeDiceLuckCount`, `changeLuckCountPerThrow`, `coins`, `diceStates`, `throwDiceCount` |
| [`wishing`](#ep-wishing) | 许愿池许愿接口 / 接口定义 后端提供 | — | `coins`, `multiple` |
#### 登录 / 账号 / 连接（8）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`bindAccount`](#ep-bindAccount) |  | `platformId`, `platformUid`, `sid` | — |
| [`createUser`](#ep-createUser) |  | `avatarId`, `inviteCode`, `nickName` | `sharkUser`, `sharkUser.serverId`, `sharkUser.uid` |
| [`geneNickname`](#ep-geneNickname) | GeneNicknameRequest.lua - 获取好友的详情 | — | `nickname` |
| [`getServerStatus`](#ep-getServerStatus) |  | — | — |
| [`getServerTimeStamp`](#ep-getServerTimeStamp) |  | — | — |
| [`getSocketServer`](#ep-getSocketServer) | GetSocketServerRequest | — | `serverAddress`, `serverPort`, `token` |
| [`loginServer`](#ep-loginServer) |  | `accountId`, `serverId` | `accountReturnRewards`, `uid` |
| [`searchUserByNickname`](#ep-searchUserByNickname) | SearchUserByNicknameRequest.lua -  | `nickName` | `friendUid`, `sharkFriendDetail`, `sharkFriendDetail.friend`, `sharkFriendDetail.invitationSent` |
#### 矩阵（2）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`replaceMatrixGrid`](#ep-replaceMatrixGrid) |  | `cardId`, `matrixId`, `posId` | `type` |
| [`upgradeMatrix`](#ep-upgradeMatrix) |  | `matrixId` | — |
#### 竞技场 / PK（14）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`challengeArena`](#ep-challengeArena) | ChallengeArenaRequest | `matchedUid`, `revenge` | — |
| [`challengeContend`](#ep-challengeContend) | ChallengeContendRequest | `contendId` | — |
| [`challengeCrossUser`](#ep-challengeCrossUser) | 挑战 | `index` | `matchList` |
| [`challengePkUser`](#ep-challengePkUser) | PKChallengePkUserRequest.lua - 比武请 | `opponentUid`, `type` | — |
| [`destinyBattle`](#ep-destinyBattle) |  | `cardId`, `destinyBattleId` | `isBossBattle`, `monsterGroupId` |
| [`gainArenaScoreByRank`](#ep-gainArenaScoreByRank) | GainArenaScoreByRankRequest | — | `reward`, `reward.amount` |
| [`gainPkBuff`](#ep-gainPkBuff) | PKGainPkBuffRequest.lua - 比武请求武神祝福 | — | — |
| [`gainPkRewards`](#ep-gainPkRewards) | PKGainPkRewardsRequest.lua - 比武请求领 | — | `rewards` |
| [`getArenaMatchedPlayers`](#ep-getArenaMatchedPlayers) | GetArenaMatchedPlayersRequest | — | `retCode`, `reward`, `reward.amount` |
| [`getDestinyInfo`](#ep-getDestinyInfo) |  | `ignoreAction` | — |
| [`getPkFoes`](#ep-getPkFoes) | PKGetPkFoesRequest.lua - 比武请求仇人列表 | — | `pkUserInfos` |
| [`getPkInfo`](#ep-getPkInfo) | PKGetPKInfoRequest.lua - 比武请求基础信息 | — | — |
| [`getPkTopRankUsers`](#ep-getPkTopRankUsers) | PKGetPkTopRankUsersRequest.lua - 比 | — | `pkUserInfos` |
| [`refreshMatch`](#ep-refreshMatch) | 刷新对手 | `type` | `matchList` |
#### 装备（5）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`getEquips`](#ep-getEquips) | 获取装备 | `*(动态)*` | — |
| [`quickUpgradeEquip`](#ep-quickUpgradeEquip) | QuickUpgradeEquipRequest | `equipId` | `equipId`, `sharkEquip` |
| [`sellEquips`](#ep-sellEquips) | SellEquipsRequest.lua - 出售装备的请求 | `equipIds` | `rewards` |
| [`setupEquip`](#ep-setupEquip) | SetupEquipRequest.lua - 更换装备的请求 | `cardId`, `equipId` | — |
| [`upgradeEquip`](#ep-upgradeEquip) | UpgradeEquipRequest | `equipId` | `equipId`, `sharkEquip` |
#### 装备附灵（2）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`equipEnchant`](#ep-equipEnchant) | 附灵接口 | `equipId` | `sharkEquip`, `sharkEquip.cardId`, `sharkEquip.enchantLevel`, `sharkEquip.enchantNum` |
| [`getEnchantStepReward`](#ep-getEnchantStepReward) | 附灵引导奖励接口 | — | `rewards` |
#### 跨服（30）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`buyCrossPvpChallengeTime`](#ep-buyCrossPvpChallengeTime) | request / /request / response / /r | — | `matchList` |
| [`challengeCrossBoss`](#ep-challengeCrossBoss) | 获取世界boss信息 | `bossType`, `type` | — |
| [`crossGvgCanMindApply`](#ep-crossGvgCanMindApply) | 跨服GvG  军团界面弹框请求 | — | `applyCrossGvgRemind` |
| [`exchangeGvgFormation`](#ep-exchangeGvgFormation) | request / /request / response / /r | `*(动态)*` | — |
| [`gainCrossBossReward`](#ep-gainCrossBossReward) | 领取奖励 | — | — |
| [`gainCrossGachaPointReward`](#ep-gainCrossGachaPointReward) | 跨服Gacha 小玉嫁到 相关 / 获取活动信息 | `id` | `rewards` |
| [`gainCrossGachaRankAndMysteriousReward`](#ep-gainCrossGachaRankAndMysteriousReward) | 跨服Gacha 小玉嫁到 相关 / 获取活动信息 | — | `mysteriousRewards`, `rankRewards` |
| [`gainCrossPkGuessReward`](#ep-gainCrossPkGuessReward) | GainCrossPkGuessRewardRequest | — | `rewards` |
| [`gainCrossPkRankReward`](#ep-gainCrossPkRankReward) | GainCrossPkRankRewardRequest | — | `rewards` |
| [`gainCrossPkServerReward`](#ep-gainCrossPkServerReward) | GainCrossPkServerRewardRequest | — | `rewards` |
| [`gainCrossPvpActiveReward`](#ep-gainCrossPvpActiveReward) |  | `activeId` | `rewards` |
| [`gainCrossPvpBattleReward`](#ep-gainCrossPvpBattleReward) | 领取跨服pvp奖励 | `type` | `rewards` |
| [`getCrossBossInfo`](#ep-getCrossBossInfo) | 获取世界boss信息 | — | — |
| [`getCrossBossRankInfo`](#ep-getCrossBossRankInfo) | 领取奖励 | — | — |
| [`getCrossGachaInfo`](#ep-getCrossGachaInfo) | 跨服Gacha 小玉嫁到 相关 / 获取活动信息 | — | — |
| [`getCrossGvgGroupInfo`](#ep-getCrossGvgGroupInfo) | request / /request / response / /r | — | — |
| [`getCrossGvgInfo`](#ep-getCrossGvgInfo) | request / /request / response / /r | — | `coinInspireNum`, `signs`, `striveInspireNum` |
| [`getCrossGvgInfoBase`](#ep-getCrossGvgInfoBase) | 跨服GvG  获取淘汰信息 | — | `crossGvgVersion`, `groupId`, `out`, `selfApplyCrossGvg`, `selfQuitCrossGvg`, `unionApplyCrossGvg` |
| [`getCrossPkCapacity`](#ep-getCrossPkCapacity) | GetCrossPkCapacityRequest | — | `crossPkUserCapacities` |
| [`getCrossPkInfo`](#ep-getCrossPkInfo) | GetCrossPkInfoRequest | — | `crossPkGroupInfo` |
| [`getCrossPkReport`](#ep-getCrossPkReport) | GetCrossPkReportRequest | `reportId` | `userinfo1`, `userinfo2`, `whetherWin` |
| [`getCrossPvpInfo`](#ep-getCrossPvpInfo) | request / /request / response / /r | — | `battleInfo`, `battleInfo.activeScore`, `battleInfo.battleScore`, `battleInfo.freeRefreshTimestamp`, `battleInfo.matchList`, `battleInfo.rank` |
| [`getCrossPvpRankInfo`](#ep-getCrossPvpRankInfo) | 获得跨服PVP排行榜信息 | — | `rank`, `rankInfos`, `score` |
| [`getCrossPvpReport`](#ep-getCrossPvpReport) | request / /request / response / /r | — | `rank`, `score` |
| [`getCrossPvpVideo`](#ep-getCrossPvpVideo) | request / /request / response / /r | `reportId` | `retCode` |
| [`guessCrossPkRank`](#ep-guessCrossPkRank) | GuessCrossPkRankRequest | `guessUid` | — |
| [`inspireCrossBossTeam`](#ep-inspireCrossBossTeam) | 获取世界boss信息 | `gems`, `props` | — |
| [`inspireCrossGvg`](#ep-inspireCrossGvg) | request / /request / response / /r | `type` | — |
| [`refreshCrossBossBattlePhase`](#ep-refreshCrossBossBattlePhase) | 获取世界boss信息 | — | — |
| [`uploadCrossGvgTeamMirror`](#ep-uploadCrossGvgTeamMirror) |  | — | — |
#### 通天塔（10）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`challengeBabel`](#ep-challengeBabel) |  | `*(动态)*` | `selectId` |
| [`challengeSkyTower`](#ep-challengeSkyTower) |  | `floor`, `type`, `version` | `clearNewBabel`, `currFloor`, `currTotalStars`, `firstTimeBigWin`, `forbidSkip`, `haveReward` |
| [`gainAutoClimbReward`](#ep-gainAutoClimbReward) |  | `speedUp` | — |
| [`gainSkipBattleAddition`](#ep-gainSkipBattleAddition) |  | `floorId`, `type` | — |
| [`gainSkipBattleRewards`](#ep-gainSkipBattleRewards) |  | — | `rewards` |
| [`getBabelInfo`](#ep-getBabelInfo) |  | `*(动态)*` | — |
| [`resetBabel`](#ep-resetBabel) |  | `*(动态)*` | — |
| [`resetClimbData`](#ep-resetClimbData) |  | `type` | — |
| [`skipSkyTowerBattle`](#ep-skipSkyTowerBattle) |  | — | — |
| [`startAutoClimbBabel`](#ep-startAutoClimbBabel) |  | `*(动态)*` | — |
#### 道具 / 商店（21）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`buyActionPower`](#ep-buyActionPower) | BuyActionPowerRequest | — | `requisites` |
| [`buyChallengeNum`](#ep-buyChallengeNum) | BuyChallengeNumRequest | — | `amount`, `requisite` |
| [`buyEnergy`](#ep-buyEnergy) | BuyEnergyRequest | `*(动态)*` | — |
| [`buyEnergyStone`](#ep-buyEnergyStone) |  | `num` | `rewards` |
| [`buyEventPoint`](#ep-buyEventPoint) | BuyEventPointRequest | `*(动态)*` | — |
| [`buyGoods`](#ep-buyGoods) |  | `goodsId` | `reward` |
| [`buyGrid`](#ep-buyGrid) |  | — | `requisite`, `requisite.amount`, `rewards` |
| [`buyMissionCompleteCount`](#ep-buyMissionCompleteCount) | BuyMissionCompleteCountRequest | `missionId` | `gems` |
| [`buySeckillItem`](#ep-buySeckillItem) | 购买限时秒杀物品接口 | `id` | `rewards` |
| [`exchangeGiftBag`](#ep-exchangeGiftBag) | 兑换礼包请求 | `activationCode` | `exchangeGiftBagInfo`, `rewards` |
| [`exchangeMedalShop`](#ep-exchangeMedalShop) | 获得商品 | `exchangeId`, `exchangeListId` | `rewards` |
| [`exchangeMysteriousItem`](#ep-exchangeMysteriousItem) | 宝物锁定 | `id` | — |
| [`exchangeSecretShop`](#ep-exchangeSecretShop) | 神秘商店兑换 | `exchangeId`, `exchangeListId` | `rewards` |
| [`getMedalShopList`](#ep-getMedalShopList) | 获得商品 | `*(动态)*` | `itemIdList` |
| [`getProps`](#ep-getProps) | GetPropsRequest.lua - 培养卡片的请求 | `*(动态)*` | — |
| [`getSeckillInfo`](#ep-getSeckillInfo) | 获得秒杀活动当前状态 | — | `seckillItems` |
| [`getSecretShopList`](#ep-getSecretShopList) | 获得神秘商店列表 | — | `itemIdList` |
| [`refreshMedalShop`](#ep-refreshMedalShop) | 刷新勋章商城 | `*(动态)*` | `itemIdList` |
| [`refreshSecretShop`](#ep-refreshSecretShop) | 刷新神秘商店 | — | `itemIdList` |
| [`sellProps`](#ep-sellProps) | SellPropsRequest.lua - 出售道具的请求 | `requisite` | `rewards` |
| [`useProp`](#ep-useProp) |  | `amount`, `propId` | `rewards` |
#### 邮件（16）

| method | 说明 | 请求参数 | 响应字段（客户端读取）|
|---|---|---|---|
| [`batchDeleteRewardEmail`](#ep-batchDeleteRewardEmail) | 批量删除奖励邮件 | `rewardEmailIds` | — |
| [`batchDeleteSysEmail`](#ep-batchDeleteSysEmail) | 批量删除系统邮件 | `sysEmailIds` | — |
| [`batchDeleteSysNotice`](#ep-batchDeleteSysNotice) | 批量删除系统通知 | `sysNoticeIds` | — |
| [`batchDeleteUserEmail`](#ep-batchDeleteUserEmail) | 批量删除用户邮件 | `userEmailIds` | — |
| [`deleteSysEmail`](#ep-deleteSysEmail) | DeleteSysEmailRequest | `sysEmailMetaId` | — |
| [`deleteSysNotice`](#ep-deleteSysNotice) | DeleteSysNoticeRequest | `sysNoticeId` | — |
| [`deleteUserEmail`](#ep-deleteUserEmail) | DeleteUserEmailRequest | `userEmailId` | — |
| [`gainRewardEmailReward`](#ep-gainRewardEmailReward) | 领取邮件奖励 | `rewardEmailId` | `rewards` |
| [`gainSysEmailReward`](#ep-gainSysEmailReward) | GainSysEmailRewardRequest | `sysEmailId` | `rewards` |
| [`getUserEmails`](#ep-getUserEmails) | GetUserEmailsRequest | — | — |
| [`modifyEmail`](#ep-modifyEmail) | EmailChangeRequest | `newEmail` | — |
| [`readRewardEmail`](#ep-readRewardEmail) | 标记奖励邮件为已读 | `rewardEmailId` | — |
| [`readSysEmail`](#ep-readSysEmail) | ReadSysEmailRequest | `sysEmailMetaId` | — |
| [`readSysNotice`](#ep-readSysNotice) | ReadSysNoticeRequest | `sysNoticeId` | — |
| [`readUserEmail`](#ep-readUserEmail) | ReadUserEmailRequest | `userEmailId` | — |
| [`sendUserEmail`](#ep-sendUserEmail) | SendUserEmailRequest | `content`, `receiveUid` | `rewards` |
---

## 5. RPC 接口详情

每个接口给出：请求类 / 定义文件 / 调用点 / 请求参数 / 客户端读取的响应字段。

> 说明：**请求参数**来自 Lua 调用点的静态解析，标 `*(动态)*` 表示参数表由上层函数传入、静态无法完全还原，
> 此时请以「调用点」列出的源码位置为准人肉确认。**响应字段**是「客户端会读的字段」，不是完整响应结构；
> 结构化定义见 §6。

### 5.1 Boss / 通缉

<a id="ep-challengeMultiplayerBoss"></a>
#### `challengeMultiplayerBoss` — ChallengeMultiplayerBossRequest

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeMultiplayerBossRequest` |
| 定义文件 | `ChallengeMultiplayerBossRequest.93261557.lua` |
| 调用点数 | 1 |
调用点：`MultiplayerBossChallengeScene.2c2bff50.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `battleType` | `battleType` | MultiplayerBossChallengeScene.2c2bff50.lua:563 |
| `bossId` | `self.bossInfo.id` | MultiplayerBossChallengeScene.2c2bff50.lua:563 |
| `triggerUid` | `self.bossInfo.triggerUid` | MultiplayerBossChallengeScene.2c2bff50.lua:563 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `win` | 1 |
| `bossInfo` | 1 |
| `globalReturnScene` | 1 |
| `bossHpMax` | 1 |


<a id="ep-challengeWanted"></a>
#### `challengeWanted`

| 项 | 值 |
|---|---|
| 请求类 | `WantedActivityChallengeRequest` |
| 定义文件 | `WantedActivityChallengeRequest.fb63f159.lua` |
| 调用点数 | 1 |
调用点：`Activity_WantedLayer.93f6a96d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `win` | 1 |
| `wantedId` | 1 |


<a id="ep-challengeWorldBoss"></a>
#### `challengeWorldBoss` — ActivityCowStageRequest.lua - 世界Boss请求

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeWorldBossRequest` |
| 定义文件 | `ActivityWorldBossRequest.79730ed8.lua` |
| 调用点数 | 1 |
调用点：`WorldBossScene.245210ce.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `battleType` | `fightType` | WorldBossScene.245210ce.lua:195 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `bossHpMax` | 1 |
| `bossHp` | 1 |


<a id="ep-exchangeItem"></a>
#### `exchangeItem`

| 项 | 值 |
|---|---|
| 请求类 | `WantedActivityExchangeRequest` |
| 定义文件 | `WantedActivityExchangeRequest.6b61cc12.lua` |
| 调用点数 | 1 |
调用点：`WantedActivityShopPanel.620cab54.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `itemId` | `data.id` | WantedActivityShopPanel.620cab54.lua:260 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainMultiplayerBossParticipationReward"></a>
#### `gainMultiplayerBossParticipationReward` — GainMultiplayerBossParticipationRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainMultiplayerBossParticipationRewardRequest` |
| 定义文件 | `GainMultiplayerBossParticipationRewardRequest.3f189c19.lua` |
| 调用点数 | 1 |
调用点：`MultiplayerBossScene.96f80f3f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `bossKey` | `aScene.rewardBossIdList` | MultiplayerBossScene.96f80f3f.lua:90 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainMultiplayerBossRankReward"></a>
#### `gainMultiplayerBossRankReward` — GainMultiplayerBossRankRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainMultiplayerBossRankRewardRequest` |
| 定义文件 | `GainMultiplayerBossRankRewardRequest.41892267.lua` |
| 调用点数 | 1 |
调用点：`Activity_MultiplayerBossLayer.89f9d55c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainWorldBossRewards"></a>
#### `gainWorldBossRewards` — ActivityCowStageRequest.lua - 世界Boss请求

| 项 | 值 |
|---|---|
| 请求类 | `GainWorldBossRewardsRequest` |
| 定义文件 | `ActivityWorldBossRequest.79730ed8.lua` |
| 调用点数 | 1 |
调用点：`WorldBossScene.245210ce.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getMultiplayerBossDamage"></a>
#### `getMultiplayerBossDamage` — GetMultiplayerBossDamageRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetMultiplayerBossDamageRequest` |
| 定义文件 | `GetMultiplayerBossDamageRequest.18c57b79.lua` |
| 调用点数 | 2 |
调用点：`MBRecordListPanel.c0718da0.lua`, `MultiplayerBossChallengeScene.2c2bff50.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `bossId` | `self.recordList[aIndex].id` ・ `self.bossInfo.id` | MBRecordListPanel.c0718da0.lua:213 |
| `triggerUid` | `tonumber(self.recordList[aIndex].triggerUid)` ・ `self.bossInfo.triggerUid` | MBRecordListPanel.c0718da0.lua:213 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `damages` | 2 |


<a id="ep-getMultiplayerBossLeftHp"></a>
#### `getMultiplayerBossLeftHp` — GetMultiplayerBossLeftHpRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetMultiplayerBossLeftHpRequest` |
| 定义文件 | `GetMultiplayerBossLeftHpRequest.ee4af100.lua` |
| 调用点数 | 2 |
调用点：`MBBossListPanel.ab19c100.lua`, `BattleScene.07008061.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `bossId` | `self.bossList[aIndex].id` ・ `SELF.data.bossInfo.id` | MBBossListPanel.ab19c100.lua:187 |
| `triggerUid` | `self.bossList[aIndex].triggerUid` ・ `SELF.data.bossInfo.triggerUid` | MBBossListPanel.ab19c100.lua:187 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `leftHp` | 2 |


<a id="ep-getMultiplayerBossRank"></a>
#### `getMultiplayerBossRank` — GetMultiplayerBossRankRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetMultiplayerBossRankRequest` |
| 定义文件 | `GetMultiplayerBossRankRequest.beadaad5.lua` |
| 调用点数 | 1 |
调用点：`MBRankListPanel.46619b2f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `beginPos` | `beginIndex` | MBRankListPanel.46619b2f.lua:338 |
| `endPos` | `endIndex` | MBRankListPanel.46619b2f.lua:338 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `multiPlayerBossRanks` | 4 |
| `currRankMax` | 2 |


<a id="ep-getWantedInfo"></a>
#### `getWantedInfo`

| 项 | 值 |
|---|---|
| 请求类 | `WantedActivityGetWantedInfoRequest` |
| 定义文件 | `WantedActivityGetWantedInfoRequest.7cbf0a6d.lua` |
| 调用点数 | 1 |
调用点：`Activity_WantedLayer.93f6a96d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `wantedInfo` | 1 |


<a id="ep-getWorldBossInfo"></a>
#### `getWorldBossInfo` — ActivityCowStageRequest.lua - 世界Boss请求

| 项 | 值 |
|---|---|
| 请求类 | `GetWorldBossInfoRequest` |
| 定义文件 | `ActivityWorldBossRequest.79730ed8.lua` |
| 调用点数 | 7 |
调用点：`Activity_WorldBossLayer.365dd021.lua`, `ActivityPanelScene.71655c90.lua`, `BattleScene.07008061.lua`, `TestBattleScene.f10b8190.lua`, `WorldBossScene.245210ce.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-inspireInWorldBoss"></a>
#### `inspireInWorldBoss` — ActivityCowStageRequest.lua - 世界Boss请求

| 项 | 值 |
|---|---|
| 请求类 | `InspireInWorldBossRequest` |
| 定义文件 | `ActivityWorldBossRequest.79730ed8.lua` |
| 调用点数 | 1 |
调用点：`InspirePanel.621ef2b0.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `worldBossInspireInfos` | `worldBossInspireList` | InspirePanel.621ef2b0.lua:189 |


<a id="ep-refreshWanted"></a>
#### `refreshWanted`

| 项 | 值 |
|---|---|
| 请求类 | `WantedActivityRefreshTaskRequest` |
| 定义文件 | `WantedActivityRefreshTaskRequest.0ee51728.lua` |
| 调用点数 | 1 |
调用点：`Activity_WantedLayer.93f6a96d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `minimum` | `self.CheckBoxSelected` | Activity_WantedLayer.93f6a96d.lua:133 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `wantedId` | 2 |


<a id="ep-setAutoWorldBoss"></a>
#### `setAutoWorldBoss` — ActivityCowStageRequest.lua - 世界Boss请求

| 项 | 值 |
|---|---|
| 请求类 | `SetAutoWorldBossRequest` |
| 定义文件 | `ActivityWorldBossRequest.79730ed8.lua` |
| 调用点数 | 2 |
调用点：`Activity_WorldBossLayer.365dd021.lua`, `WorldBossAutoFightPanel.aeee3929.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `autoChallenge` | `false` ・ `true` | Activity_WorldBossLayer.365dd021.lua:372 |


### 5.2 任务 / 成就 / 奖励

<a id="ep-gainAchievementReward"></a>
#### `gainAchievementReward` — GainAchievementRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainAchievementRewardRequest` |
| 定义文件 | `GainAchievementRewardRequest.f6e1a58d.lua` |
| 调用点数 | 1 |
调用点：`AchievementScene.c76e2465.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `achievementId` | `aData.achieveId` | AchievementScene.c76e2465.lua:1320 |
| `achievementType` | `aData.achieveType` | AchievementScene.c76e2465.lua:1320 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 2 |


<a id="ep-gainActiveReward"></a>
#### `gainActiveReward` — ActiveRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `ActiveRewardRequest` |
| 定义文件 | `ActiveRewardRequest.c8dd0487.lua` |
| 调用点数 | 2 |
调用点：`DailyActivityRewardPanel.ea572cb3.lua`, `SecretaryScene.dcffcc9c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `activeRewardId` | `evt.data + 1` | DailyActivityRewardPanel.ea572cb3.lua:325 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainBalloonPointReward"></a>
#### `gainBalloonPointReward`

| 项 | 值 |
|---|---|
| 请求类 | `BlowBalloonActGetMagicRewardRequest` |
| 定义文件 | `BlowBalloonActGetMagicRewardRequest.7909eb28.lua` |
| 调用点数 | 2 |
调用点：`BlowBalloonMagicRewardPanel.b48bb4a7.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `0` ・ `data.id` | BlowBalloonMagicRewardPanel.b48bb4a7.lua:139 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `balloonRanks` | 2 |


<a id="ep-gainBalloonRankReward"></a>
#### `gainBalloonRankReward`

| 项 | 值 |
|---|---|
| 请求类 | `BlowBalloonActGetRankRewardRequest` |
| 定义文件 | `BlowBalloonActGetRankRewardRequest.22c456aa.lua` |
| 调用点数 | 1 |
调用点：`BlowBalloonRankPanel.93d441a2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `balloonRanks` | 2 |


<a id="ep-gainChapterFinishReward"></a>
#### `gainChapterFinishReward` — GainChapterFinishRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainChapterFinishRewardRequest` |
| 定义文件 | `GainChapterFinishRewardRequest.9a01fc1f.lua` |
| 调用点数 | 2 |
调用点：`ChapterFinishRewardPanel.4bb93a14.lua`, `CityMainScene.6c78a367.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `chapterId` | `CountryManager:sharedManager().selectedChapterID` ・ `self.currentChapterID` | ChapterFinishRewardPanel.4bb93a14.lua:128 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemType` | 6 |
| `metaId` | 4 |
| `reward` | 3 |
| `amount` | 2 |


<a id="ep-gainChargeMoneyReward"></a>
#### `gainChargeMoneyReward`

| 项 | 值 |
|---|---|
| 请求类 | `GainChargeMoneyRewardRequest` |
| 定义文件 | `GainChargeMoneyRewardRequest.4393dd96.lua` |
| 调用点数 | 1 |
调用点：`Activity_ChargeRewardLayer.0f693d93.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `self.chargeLevel + 1` | Activity_ChargeRewardLayer.0f693d93.lua:191 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainConsumeReward"></a>
#### `gainConsumeReward` — 多重好礼获取面板信息接口 / 接口定义 后端提供

| 项 | 值 |
|---|---|
| 请求类 | `ConsumeRewardGainRequest` |
| 定义文件 | `ConsumeRewardGainRequest.dfd6be07.lua` |
| 调用点数 | 1 |
调用点：`Activity_ConsumeRewardsLayer.56e66370.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `cell.data.id` | ConsumeRewardGainRequest.dfd6be07.lua:canon\request\ConsumeRewardGainRequest.dfd6be07409096baa8dc881be56521b8.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-gainDailyAchieveReward"></a>
#### `gainDailyAchieveReward` — 获取每日成就信息

| 项 | 值 |
|---|---|
| 请求类 | `GainDailyAchieveRequest` |
| 定义文件 | `GainDailyAchieveRequest.2d650a07.lua` |
| 调用点数 | 1 |
调用点：`DailyTargetScene.51fbbf86.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `achieveId` | `aData.taskId` | GainDailyAchieveRequest.2d650a07.lua:canon\request\GainDailyAchieveRequest.2d650a0714cef570dbdd5367805aea11.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainDailyTaskReward"></a>
#### `gainDailyTaskReward`

| 项 | 值 |
|---|---|
| 请求类 | `GainDailyTaskRewardRequest` |
| 定义文件 | `GainDailyTaskRewardRequest.dcaec627.lua` |
| 调用点数 | 1 |
调用点：`Activity_FestivalLayer.3c0ab853.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `taskId` | `lstTask[evt.data + 1].taskId` | Activity_FestivalLayer.3c0ab853.lua:477 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-gainDayReward"></a>
#### `gainDayReward`

| 项 | 值 |
|---|---|
| 请求类 | `GainDayRewardRequest` |
| 定义文件 | `ActivityNewYear8DaysRequest.4e455b81.lua` |
| 调用点数 | 1 |
调用点：`Activity_NewYear8DaysLayer.ace412dd.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `dayRewardId` | `dayRewardId` | Activity_NewYear8DaysLayer.ace412dd.lua:152 |


<a id="ep-gainDiceReward"></a>
#### `gainDiceReward` — DiceGainRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `DiceGainRewardRequest` |
| 定义文件 | `DiceGainRewardRequest.4d79c892.lua` |
| 调用点数 | 1 |
调用点：`ActivitySilverDiceLayer_POP.613ecc7a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gainedCoin` | 1 |
| `diceNewRewards` | 1 |
| `throwDiceCount` | 1 |
| `changeDiceLuckCount` | 1 |
| `changeLuckCountPerThrow` | 1 |


<a id="ep-gainFbActivityReward"></a>
#### `gainFbActivityReward` — Facebook相关

| 项 | 值 |
|---|---|
| 请求类 | `FacebookGainActivityRewardRequest` |
| 定义文件 | `FacebookActivityRequest.fe356c3f.lua` |
| 调用点数 | 1 |
调用点：`Activity_FacebookShareLayer.0f401528.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainFortuneRewards"></a>
#### `gainFortuneRewards` — GainFortuneRewardsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainFortuneRewardsRequest` |
| 定义文件 | `GainFortuneRewardsRequest.1b669ce1.lua` |
| 调用点数 | 1 |
调用点：`Activity_LotteryFortuneLayer.95e3f0e7.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `id` | 1 |
| `rewards` | 1 |


<a id="ep-gainGemConsumeRewards"></a>
#### `gainGemConsumeRewards`

| 项 | 值 |
|---|---|
| 请求类 | `GainGemConsumeRewardsRequest` |
| 定义文件 | `ActivityGemConsumeRequest.b73f4b38.lua` |
| 调用点数 | 1 |
调用点：`Activity_GemConsumeRewardsLayer.6c13c7f4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardId` | `gemConsumeMeta[evt.context].id` | Activity_GemConsumeRewardsLayer.6c13c7f4.lua:77 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-gainGoldGodRewards"></a>
#### `gainGoldGodRewards` — GainGoldGodRewardsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainGoldGodRewardsRequest` |
| 定义文件 | `GainGoldGodRewardsRequest.92674d75.lua` |
| 调用点数 | 1 |
调用点：`Activity_WealthGodLayer.b07c36e0.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


<a id="ep-gainInviteReward"></a>
#### `gainInviteReward` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `GainInviteRewardRequest` |
| 定义文件 | `GainInviteRewardRequest.d4c6a1f0.lua` |
| 调用点数 | 1 |
调用点：`Activity_InvitationCodeLayer.3a5f0e8f.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainInvitedReward"></a>
#### `gainInvitedReward` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `GainInvitedRewardRequest` |
| 定义文件 | `GainInvitedRewardRequest.1d234014.lua` |
| 调用点数 | 1 |
调用点：`Activity_InvitationCodeLayer.3a5f0e8f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `deviceId` | `getDeviceId()` | Activity_InvitationCodeLayer.3a5f0e8f.lua:259 |
| `invitationCode` | `selectedText` | Activity_InvitationCodeLayer.3a5f0e8f.lua:259 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainLevelRaceRewards"></a>
#### `gainLevelRaceRewards` — GainLevelRaceRewardsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainLevelRaceRewardsRequest` |
| 定义文件 | `GainLevelRaceRewardsRequest.e709f453.lua` |
| 调用点数 | 1 |
调用点：`Activity_LevelRaceLayer.2d661a03.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `level` | `aLevel` | Activity_LevelRaceLayer.2d661a03.lua:276 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainMondayReward"></a>
#### `gainMondayReward`

| 项 | 值 |
|---|---|
| 请求类 | `GainMondayRewardRequest` |
| 定义文件 | `GainMondayRewardRequest.9d1325dc.lua` |
| 调用点数 | 1 |
调用点：`BaseUIScene.0cb7c1e5.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainNewYearRewards"></a>
#### `gainNewYearRewards` — GainNewYearRewardsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainNewYearRewardsRequest` |
| 定义文件 | `GainNewYearRewardsRequest.8ee3b34e.lua` |
| 调用点数 | 2 |
调用点：`Activity_NewChargeRewardLayer.00334c8b.lua`, `Activity_NewYearLayer.44de7958.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `aRewardId` | Activity_NewChargeRewardLayer.00334c8b.lua:150 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 4 |


<a id="ep-gainRankFirstReward"></a>
#### `gainRankFirstReward` — GainRankFirstRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainRankFirstRewardRequest` |
| 定义文件 | `GainRankFirstRewardRequest.a7089d92.lua` |
| 调用点数 | 1 |
调用点：`ArenaExchangeScene.b7cb89da.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rank` | `aRank` | ArenaExchangeScene.b7cb89da.lua:571 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemType` | 3 |
| `metaId` | 3 |
| `rewards` | 2 |
| `amount` | 1 |


<a id="ep-gainRankRewards"></a>
#### `gainRankRewards`

| 项 | 值 |
|---|---|
| 请求类 | `GainRankRewardsRequest` |
| 定义文件 | `GainRankRewardsRequest.436d2cd2.lua` |
| 调用点数 | 1 |
调用点：`NewBabelRankScene.d514276e.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainSwornReward"></a>
#### `gainSwornReward`

| 项 | 值 |
|---|---|
| 请求类 | `SwornRewardGainRequest` |
| 定义文件 | `SwornRewardGainRequest.de4713d1.lua` |
| 调用点数 | 1 |
调用点：`Activity_SwornLayer.5628e30f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `swornRewardId` | `configItem.id` | Activity_SwornLayer.5628e30f.lua:292 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainTutorialFinishReward"></a>
#### `gainTutorialFinishReward`

| 项 | 值 |
|---|---|
| 请求类 | `GainTutorialFinishRewardRequest` |
| 定义文件 | `GainTutorialFinishRewardRequest.552891a2.lua` |
| 调用点数 | 1 |
调用点：`MainMenuScene.2bc9508c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-getAchievements"></a>
#### `getAchievements` — GetAchievementsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetAchievementsRequest` |
| 定义文件 | `GetAchievementsRequest.ea160313.lua` |
| 调用点数 | 3 |
调用点：`CreateCharacterScene.728208fe.lua`, `LoginScene.9fbb94e7.lua`, `MainMenuScene.2bc9508c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkAchievement` | 3 |
| `cardBookAchievement` | 1 |


<a id="ep-getChargeFeedbackReward"></a>
#### `getChargeFeedbackReward`

| 项 | 值 |
|---|---|
| 请求类 | `GetChargeFeedbackRewardRequest` |
| 定义文件 | `GetChargeFeedbackRewardRequest.47d95489.lua` |
| 调用点数 | 1 |
调用点：`Activity_ChargeFeedbackLayer.2b80db7e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardId` | `selectId` | Activity_ChargeFeedbackLayer.2b80db7e.lua:166 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-getConsumeRewardInfo"></a>
#### `getConsumeRewardInfo` — 多重好礼获取面板信息接口 / 接口定义 后端提供

| 项 | 值 |
|---|---|
| 请求类 | `ConsumeRewardGetInfoRequest` |
| 定义文件 | `ConsumeRewardGetInfoRequest.c27c4978.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `recharges` | 1 |
| `rewards` | 1 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getContinuousLoginReward"></a>
#### `getContinuousLoginReward` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetContinueLoginRewardRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 2 |
调用点：`UserContinueLoginShowPanel.ade2205f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `getBigReward` | `false` ・ `true` | UserContinueLoginShowPanel.ade2205f.lua:546 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewardId` | 4 |
| `reward` | 2 |
| `bigReward` | 2 |


<a id="ep-getCountdownReward"></a>
#### `getCountdownReward` — 获取新手礼包请求

| 项 | 值 |
|---|---|
| 请求类 | `GetCountdownRewardRequest` |
| 定义文件 | `GetCountdownRewardRequest.d2bf05fe.lua` |
| 调用点数 | 2 |
调用点：`CountDownRewardNewPanel.4f382db0.lua`, `CountDownRewardNewPanel.97597a37.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 4 |
| `latestRewardTimestamp` | 2 |
| `inProcessRewardId` | 2 |
| `finished` | 2 |


<a id="ep-getDailyAchieveInfo"></a>
#### `getDailyAchieveInfo` — 获取每日成就信息

| 项 | 值 |
|---|---|
| 请求类 | `GetDailyAchieveInfoRequest` |
| 定义文件 | `GetDailyAchieveInfoRequest.cc55ffc0.lua` |
| 调用点数 | 3 |
调用点：`AchievementScene.c76e2465.lua`, `DailyTargetScene.51fbbf86.lua`, `SecretaryScene.dcffcc9c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getDailyActiveInfo"></a>
#### `getDailyActiveInfo` — GetDailyActiveInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetDailyActiveInfoRequest` |
| 定义文件 | `GetDailyActiveInfoRequest.828061c1.lua` |
| 调用点数 | 5 |
调用点：`AchievementScene.c76e2465.lua`, `DailyTargetScene.51fbbf86.lua`, `MainMenuScene.2bc9508c.lua`, `MedalShopScene.1b93eac7.lua`, `SecretaryScene.dcffcc9c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `dailyActiveInfo` | 3 |
| `dailyActiveInfo.taskCounters` | 1 |
| `dailyActiveInfo.gainedRewards` | 1 |
| `dailyActiveInfo.activeValue` | 1 |


<a id="ep-getLoginReward"></a>
#### `getLoginReward` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetLoginRewardRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 1 |
调用点：`CalendarSignInPanel.d5ccd8fa.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-getMonthlyLoginRewardMeta"></a>
#### `getMonthlyLoginRewardMeta` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetCurMonthRewardListRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 1 |
调用点：`CalendarSignInPanel.d5ccd8fa.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `monthlyLoginRewardItems` | 3 |
| `adNum` | 1 |


<a id="ep-getQuestionDailyReward"></a>
#### `getQuestionDailyReward`

| 项 | 值 |
|---|---|
| 请求类 | `QuestionActDailyRewardRequest` |
| 定义文件 | `QuestionActDailyRewardRequest.c4de211b.lua` |
| 调用点数 | 1 |
调用点：`Activity_QuestionLayer.160a5d4c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `questionNum` | 1 |
| `dailyNum` | 1 |
| `questionId` | 1 |
| `wrongAnswer1Key` | 1 |
| `wrongAnswer2Key` | 1 |
| `wrongAnswer3Key` | 1 |


<a id="ep-getRewardList"></a>
#### `getRewardList` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetRewardListRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 1 |
调用点：`RewardScene.991f3c30.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkRewardList` | 2 |


<a id="ep-getSignInReward"></a>
#### `getSignInReward` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetSigninRewardRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 1 |
调用点：`CalendarSignInPanel.d5ccd8fa.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-getTaskInfo"></a>
#### `getTaskInfo`

| 项 | 值 |
|---|---|
| 请求类 | `GetTaskInfoRequest` |
| 定义文件 | `GetTaskInfoRequest.6d128e4c.lua` |
| 调用点数 | 2 |
调用点：`Activity_FestivalLayer.3c0ab853.lua`, `ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `dailyTaskInfos` | 1 |


<a id="ep-getWeekReward"></a>
#### `getWeekReward`

| 项 | 值 |
|---|---|
| 请求类 | `QuestionActWeekRewardRequest` |
| 定义文件 | `QuestionActWeekRewardRequest.c962d72d.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-pickUpAllReward"></a>
#### `pickUpAllReward` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetAllRewardRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 1 |
调用点：`RewardScene.991f3c30.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `pickUpCard` | `not(self.getNoCardReward)` | RewardScene.991f3c30.lua:724 |
| `pickUpEquip` | `not(self.getNoEquipReward)` | RewardScene.991f3c30.lua:724 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-pickUpReward"></a>
#### `pickUpReward` — RewardRequest.lua - all request related requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetSingleRewardRequest` |
| 定义文件 | `RewardRequest.216776d3.lua` |
| 调用点数 | 1 |
调用点：`RewardScene.991f3c30.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardId` | `data[selectedIndex].rewardId` | RewardScene.991f3c30.lua:457 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 1 |


### 5.3 元数据 / 初始化

<a id="ep-gameInit"></a>
#### `gameInit`

| 项 | 值 |
|---|---|
| 请求类 | `GameInitRequest` |
| 定义文件 | `GameInitRequest.b9918425.lua` |
| 调用点数 | 4 |
调用点：`ConfigScene.a838f4ae.lua`, `CreateCharacterScene.728208fe.lua`, `LoginScene.9fbb94e7.lua`, `MainMenuScene.2bc9508c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `maintenanceItem` | 2 |
| `sharkAchievement` | 2 |
| `noChatEndSeconds` | 2 |


<a id="ep-getAnnouncementInfo"></a>
#### `getAnnouncementInfo` — 获取公告信息请求

| 项 | 值 |
|---|---|
| 请求类 | `GetAnnouncementInfoRequest` |
| 定义文件 | `GetAnnouncementInfoRequest.4dbf9c1c.lua` |
| 调用点数 | 2 |
调用点：`ConfigScene.a838f4ae.lua`, `MainMenuScene.2bc9508c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `announcementItemMetas` | 2 |


<a id="ep-getMeta"></a>
#### `getMeta` — GetGameMetaRequest.lua - 获取游戏元配置的请求

| 项 | 值 |
|---|---|
| 请求类 | `GetGameMetaRequest` |
| 定义文件 | `GetGameMetaRequest.ec6b494e.lua` |
| 调用点数 | 3 |
调用点：`MetaManager.a149e152.lua`, `LoginScene.9fbb94e7.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


### 5.4 元神

<a id="ep-buySpiritPool"></a>
#### `buySpiritPool` — 购买元神格子

| 项 | 值 |
|---|---|
| 请求类 | `BuySpiritPoolRequest` |
| 定义文件 | `BuySpiritPoolRequest.5a113a85.lua` |
| 调用点数 | 2 |
调用点：`SpiritPackageFullPanel.c73b3939.lua`, `SpiritBackPackScene.edebcdb4.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `requisite` | 6 |
| `requisite.amount` | 4 |


<a id="ep-equipSpirit"></a>
#### `equipSpirit` — 装备元神

| 项 | 值 |
|---|---|
| 请求类 | `EquipSpiritRequest` |
| 定义文件 | `EquipSpiritRequest.c4199534.lua` |
| 调用点数 | 1 |
调用点：`SpiritBackPackScene.edebcdb4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `SELF.argv.params.cardId` | SpiritBackPackScene.edebcdb4.lua:1142 |
| `index` | `HeMemDataHolder:getInteger("SpiritChange_Position")` | SpiritBackPackScene.edebcdb4.lua:1142 |
| `spiritId` | `SELF._data.spiritId` | SpiritBackPackScene.edebcdb4.lua:1142 |


<a id="ep-sellSpirit"></a>
#### `sellSpirit` — 卖出元神

| 项 | 值 |
|---|---|
| 请求类 | `SellSpiritRequest` |
| 定义文件 | `SellSpiritRequest.614d89ca.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `spiritIds` | `items` | ItemSellMessageBoxPanel.7afb89c9.lua:323 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-setAutoSave"></a>
#### `setAutoSave` — 元神刷新复选框

| 项 | 值 |
|---|---|
| 请求类 | `SetSpiritRefreshAutoSaveRequest` |
| 定义文件 | `SetSpiritRefreshAutoSaveRequest.ddd4b75c.lua` |
| 调用点数 | 1 |
调用点：`SpiritComposePanel.83663dd4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `autoSave` | `not sendValue` | SpiritComposePanel.83663dd4.lua:915 |


<a id="ep-spiritConcentrate"></a>
#### `spiritConcentrate`

| 项 | 值 |
|---|---|
| 请求类 | `SpiritConcentrateRequest` |
| 定义文件 | `SpiritConcentrateRequest.5a874303.lua` |
| 调用点数 | 2 |
调用点：`KingTempleScene.f2b46794.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `1` ・ `2` | KingTempleScene.f2b46794.lua:216 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkSpirits` | 4 |


<a id="ep-unequipSpirit"></a>
#### `unequipSpirit` — 卸下元神

| 项 | 值 |
|---|---|
| 请求类 | `UnequipSpiritRequest` |
| 定义文件 | `UnequipSpiritRequest.550c7bcb.lua` |
| 调用点数 | 1 |
调用点：`SpiritInfoPanel.12341460.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `self.spirit.cardId` | SpiritInfoPanel.12341460.lua:234 |
| `index` | `SpiritManager.getSpiritEquipPos( self.spirit )` | SpiritInfoPanel.12341460.lua:234 |


<a id="ep-upgradeSpirit"></a>
#### `upgradeSpirit` — 强化元神

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeSpiritRequest` |
| 定义文件 | `UpgradeSpiritRequest.43bb2ba7.lua` |
| 调用点数 | 1 |
调用点：`SpiritComposePanel.83663dd4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `masterSpiritId` | `self.spirit.spiritId` | SpiritComposePanel.83663dd4.lua:244 |
| `slaveSpiritIds` | `slaveIds` | SpiritComposePanel.83663dd4.lua:244 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkSpirit` | 3 |
| `sharkSpirit.spiritId` | 1 |


### 5.5 关卡 / 战斗

<a id="ep-challengeElite"></a>
#### `challengeElite` — ChallengeEliteRequest.lua - 挑战精英关卡

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeEliteRequest` |
| 定义文件 | `ChallengeEliteRequest.ed86442a.lua` |
| 调用点数 | 1 |
调用点：`EliteMissionScene.6d30c853.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `eliteId` | `eliteMissionInfo.id` | EliteMissionScene.6d30c853.lua:625 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `win` | 1 |
| `selectId` | 1 |


<a id="ep-changeBattleArray"></a>
#### `changeBattleArray`

| 项 | 值 |
|---|---|
| 请求类 | `ChangeBattleArrayRequest` |
| 定义文件 | `ChangeBattleArrayRequest.f6740d20.lua` |
| 调用点数 | 1 |
调用点：`CardQueueScene.ec2c79d1.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `battleArrayId` | `nowId` | ChangeBattleArrayRequest.f6740d20.lua:canon\features\multilineup\request\ChangeBattleArrayRequest.f6740d2001095337e0a1190f383d3864.lua |


<a id="ep-clearElite"></a>
#### `clearElite` — 精英关卡扫荡

| 项 | 值 |
|---|---|
| 请求类 | `EliteSweepRequest` |
| 定义文件 | `EliteSweepRequest.9c91b00c.lua` |
| 调用点数 | 1 |
调用点：`EliteSweepConfirmPopmPanel.390894c5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `eliteId` | `self.missionConfig.id` | EliteSweepRequest.9c91b00c.lua:canon\request\EliteSweepRequest.9c91b00c947545cd7e3f1efcf33cb555.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `lastEnergy` | 1 |
| `mergeRewards` | 1 |
| `rewards` | 1 |
| `challengeNum` | 1 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-clearMission"></a>
#### `clearMission` — ClearMissionRequest

| 项 | 值 |
|---|---|
| 请求类 | `ClearMissionRequest` |
| 定义文件 | `ClearMissionRequest.f568d8f1.lua` |
| 调用点数 | 1 |
调用点：`CityMainScene.6c78a367.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `clearRounds` | `extraArgs.clearRounds` | CityMainScene.6c78a367.lua:1290 |
| `missionId` | `extraArgs.missionId` | CityMainScene.6c78a367.lua:1290 |
| `routeId` | `extraArgs.routeId` | CityMainScene.6c78a367.lua:1290 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `clearMissionRewards` | 2 |


<a id="ep-getEliteInfo"></a>
#### `getEliteInfo` — GetEliteInfoRequest.lua - 获取精英关卡信息

| 项 | 值 |
|---|---|
| 请求类 | `GetEliteInfoRequest` |
| 定义文件 | `GetEliteInfoRequest.47083066.lua` |
| 调用点数 | 1 |
调用点：`EliteMissionScene.6d30c853.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-resetClearTime"></a>
#### `resetClearTime` — ResetClearTimeRequest

| 项 | 值 |
|---|---|
| 请求类 | `ResetClearTimeRequest` |
| 定义文件 | `ResetClearTimeRequest.ea2c9959.lua` |
| 调用点数 | 1 |
调用点：`CityMainScene.6c78a367.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gemRequisite` | 3 |
| `gemRequisite.amount` | 2 |


<a id="ep-resetElite"></a>
#### `resetElite` — ResetEliteRequest.lua - 重置精英关卡信息

| 项 | 值 |
|---|---|
| 请求类 | `ResetEliteRequest` |
| 定义文件 | `ResetEliteRequest.768ea391.lua` |
| 调用点数 | 1 |
调用点：`EliteMissionScene.6d30c853.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `eliteId` | `eliteMissionInfo.id` | EliteMissionScene.6d30c853.lua:690 |


<a id="ep-triggerBattleEvent"></a>
#### `triggerBattleEvent`

| 项 | 值 |
|---|---|
| 请求类 | `TriggerBattleRequest` |
| 定义文件 | `TriggerBattleRequest.c6641c5d.lua` |
| 调用点数 | 2 |
调用点：`ChapterMapScene.56ea0d90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `DoNotCaptureFailueMessage` | `true` | ChapterMapScene.56ea0d90.lua:1334 |
| `battleType` | `1` ・ `2` | ChapterMapScene.56ea0d90.lua:1334 |
| `missionId` | `self.currentMissionId` | ChapterMapScene.56ea0d90.lua:1334 |
| `routeId` | `self.currentRouteId` | ChapterMapScene.56ea0d90.lua:1334 |
| `step` | `self.currentFinishedStep + 1` | ChapterMapScene.56ea0d90.lua:1334 |


### 5.6 其他

<a id="ep-adjustTeam"></a>
#### `adjustTeam` — 调整队列请求

| 项 | 值 |
|---|---|
| 请求类 | `AdjustTeamRequest` |
| 定义文件 | `AdjustTeamRequest.16692cfa.lua` |
| 调用点数 | 1 |
调用点：`AdjustTeamScene.44c0233c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `additionalCardIds` | `additionalCardIds` | AdjustTeamScene.44c0233c.lua:350 |
| `mainCardId` | `mainCardId` | AdjustTeamScene.44c0233c.lua:350 |


<a id="ep-gainFloorAddition"></a>
#### `gainFloorAddition`

| 项 | 值 |
|---|---|
| 请求类 | `GainFloorAdditionRequest` |
| 定义文件 | `GainFloorAdditionRequest.9e2f3d3a.lua` |
| 调用点数 | 1 |
调用点：`NewBabelFloorBuffPanel.78ad1ec2.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `evt.context` | NewBabelFloorBuffPanel.78ad1ec2.lua:108 |


<a id="ep-gainYesterdayAddition"></a>
#### `gainYesterdayAddition`

| 项 | 值 |
|---|---|
| 请求类 | `GainYesterdayAdditionRequest` |
| 定义文件 | `GainYesterdayAdditionRequest.b3f1d138.lua` |
| 调用点数 | 1 |
调用点：`NewBabelEnterBuffPanel.45fe7596.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `evt.context` | NewBabelEnterBuffPanel.45fe7596.lua:125 |


<a id="ep-getHomeInfo"></a>
#### `getHomeInfo` — 获取主页信息请求

| 项 | 值 |
|---|---|
| 请求类 | `GetHomeInfoRequest` |
| 定义文件 | `GetHomeInfoRequest.db95c015.lua` |
| 调用点数 | 2 |
调用点：`SpiritComposePanel.83663dd4.lua`, `MainMenuScene.2bc9508c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `freeSpiritRefreshNum` | 1 |
| `unionMonsterHp` | 1 |
| `unionMonsterEscapeSeconds` | 1 |
| `consumeRewardRecharges` | 1 |
| `consumeRewards` | 1 |


<a id="ep-getMultiplayserBossInfo"></a>
#### `getMultiplayserBossInfo` — GetMultiplayserBossInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetMultiplayserBossInfoRequest` |
| 定义文件 | `GetMultiplayserBossInfoRequest.53de7fa9.lua` |
| 调用点数 | 2 |
调用点：`MultiplayerBossScene.96f80f3f.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getPlayerTeamInfo"></a>
#### `getPlayerTeamInfo` — GetPlayerTeamInfoRequest.lua - 培养卡片的请求

| 项 | 值 |
|---|---|
| 请求类 | `GetPlayerTeamInfoRequest` |
| 定义文件 | `GetPlayerTeamInfoRequest.ed2f803a.lua` |
| 调用点数 | 8 |
调用点：`CrossArena.e1b6cb0b.lua`, `AcrossUserDetailPanel.62232f9a.lua`, `CrossBossRankInfoPanel.66b7fc14.lua`, `UnionMemberListPanel.10242232.lua`, `UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `playerTeamData` | `evt.data` ・ `e.data` | CrossArena.e1b6cb0b.lua:141 |
| `playerUid` | `uid` ・ `self.params.uid` ・ `ranks[evt.data + 1].uid` | CrossArena.e1b6cb0b.lua:141 |


<a id="ep-getUserBanInfo"></a>
#### `getUserBanInfo` — 刷新元神副属性

| 项 | 值 |
|---|---|
| 请求类 | `SpeakLimitStutasRequest` |
| 定义文件 | `SpeakLimitStutasRequest.f6e4423c.lua` |
| 调用点数 | 2 |
调用点：`CreateCharacterScene.728208fe.lua`, `LoginScene.9fbb94e7.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `noChatEndSeconds` | 2 |


<a id="ep-login"></a>
#### `login`

| 项 | 值 |
|---|---|
| 请求类 | `(direct)` |
| 定义文件 |  |
| 调用点数 | 1 |
调用点：`Communication.6d25bf31.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-rebirthItem"></a>
#### `rebirthItem` — 武将重生

| 项 | 值 |
|---|---|
| 请求类 | `ItemRebirthRequest` |
| 定义文件 | `ItemRebirthRequest.cf449df5.lua` |
| 调用点数 | 1 |
调用点：`CardRebirthScene.f580de62.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `resourceId` | `cardData.cardId` | CardRebirthScene.f580de62.lua:1176 |
| `resourceType` | `ResourceEnum.CARD` | CardRebirthScene.f580de62.lua:1176 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


<a id="ep-recordAddictedTime"></a>
#### `recordAddictedTime`

| 项 | 值 |
|---|---|
| 请求类 | `RecordAddictedTimeRequest` |
| 定义文件 | `RecordAddictedTimeRequest.70286d02.lua` |
| 调用点数 | 2 |
调用点：`AntiAddictionManager.a8003a32.lua`, `AntiAddictionReminderPanel.e83bec0a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `minutes` | `math.modf(curUserPlayInfo.during / 60)` ・ `0` | AntiAddictionManager.a8003a32.lua:55 |


<a id="ep-recordTutorialStep"></a>
#### `recordTutorialStep`

| 项 | 值 |
|---|---|
| 请求类 | `RecordTutorialStepRequest` |
| 定义文件 | `RecordTutorialStepRequest.2822ad80.lua` |
| 调用点数 | 10 |
调用点：`GlobalScene.3dc0f426.lua`, `canonUtils.f9d1d84b.lua`, `UserLevelupBox.3ae9c559.lua`, `CardQueueScene.ec2c79d1.lua`, `MainMenuScene.2bc9508c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `funcName` | `guide` ・ `g_curGuide` ・ `"Guide_MultiLineupBox"` | canonUtils.f9d1d84b.lua:569 |
| `step` | `1` | canonUtils.f9d1d84b.lua:569 |


<a id="ep-refreshSubAttribute"></a>
#### `refreshSubAttribute` — 刷新元神副属性

| 项 | 值 |
|---|---|
| 请求类 | `RefreshSubAttributeRequest` |
| 定义文件 | `RefreshSubAttributeRequest.3fcca836.lua` |
| 调用点数 | 1 |
调用点：`SpiritComposePanel.83663dd4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `lockIndex` | `self.lockId` | SpiritComposePanel.83663dd4.lua:155 |
| `refreshType` | `btnType` | SpiritComposePanel.83663dd4.lua:155 |
| `spiritId` | `self.spirit.spiritId` | SpiritComposePanel.83663dd4.lua:155 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `refreshSharkSpiritAttribute` | 9 |


<a id="ep-rename"></a>
#### `rename` — 卖出元神

| 项 | 值 |
|---|---|
| 请求类 | `ChangeNameRequest` |
| 定义文件 | `ChangeNameRequest.291bf8d0.lua` |
| 调用点数 | 1 |
调用点：`ReNameInputPanel.e3b5f50c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `nickName` | `strNickName` | ReNameInputPanel.e3b5f50c.lua:146 |


<a id="ep-sacrificeItem"></a>
#### `sacrificeItem` — 武将祭炼

| 项 | 值 |
|---|---|
| 请求类 | `ItemSacrificeRequest` |
| 定义文件 | `ItemSacrificeRequest.9185bdc3.lua` |
| 调用点数 | 1 |
调用点：`CardRebirthScene.f580de62.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `resourceIds` | `idList` | CardRebirthScene.f580de62.lua:1336 |
| `resourceType` | `resourceType` | CardRebirthScene.f580de62.lua:1336 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 4 |


<a id="ep-selectSubAttribute"></a>
#### `selectSubAttribute` — 卖出元神

| 项 | 值 |
|---|---|
| 请求类 | `SelectSubAttributeRequest` |
| 定义文件 | `SelectSubAttributeRequest.8ff79658.lua` |
| 调用点数 | 2 |
调用点：`SpiritBatchRefreshResultPanel.c74b6e98.lua`, `SpiritBatchRefreshSingleResultPanel.af6cb0e3.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `refreshIndex` | `self.selectId - 1` | SpiritBatchRefreshResultPanel.c74b6e98.lua:138 |
| `spiritId` | `self.container.spirit.spiritId` | SpiritBatchRefreshResultPanel.c74b6e98.lua:138 |


<a id="ep-triggerCoinEvent"></a>
#### `triggerCoinEvent` — TriggerCoinEventRequest

| 项 | 值 |
|---|---|
| 请求类 | `TriggerCoinEventRequest` |
| 定义文件 | `TriggerCoinEventRequest.7b3b3a68.lua` |
| 调用点数 | 1 |
调用点：`ChapterMapScene.56ea0d90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `DoNotCaptureFailueMessage` | `true` | ChapterMapScene.56ea0d90.lua:1516 |
| `missionId` | `self.currentMissionId` | ChapterMapScene.56ea0d90.lua:1516 |
| `routeId` | `self.currentRouteId` | ChapterMapScene.56ea0d90.lua:1516 |
| `step` | `self.currentFinishedStep + 1` | ChapterMapScene.56ea0d90.lua:1516 |


<a id="ep-triggerEmptyEvent"></a>
#### `triggerEmptyEvent` — TriggerEmptyEventRequest

| 项 | 值 |
|---|---|
| 请求类 | `TriggerEmptyEventRequest` |
| 定义文件 | `TriggerEmptyEventRequest.fd6dc6e2.lua` |
| 调用点数 | 1 |
调用点：`ChapterMapScene.56ea0d90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `DoNotCaptureFailueMessage` | `true` | ChapterMapScene.56ea0d90.lua:2010 |
| `missionId` | `self.currentMissionId` | ChapterMapScene.56ea0d90.lua:2010 |
| `routeId` | `self.currentRouteId` | ChapterMapScene.56ea0d90.lua:2010 |
| `step` | `self.currentFinishedStep + 1` | ChapterMapScene.56ea0d90.lua:2010 |


<a id="ep-triggerExpEvent"></a>
#### `triggerExpEvent` — TriggerExpEventRequest

| 项 | 值 |
|---|---|
| 请求类 | `TriggerExpEventRequest` |
| 定义文件 | `TriggerExpEventRequest.4e69904f.lua` |
| 调用点数 | 1 |
调用点：`ChapterMapScene.56ea0d90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `DoNotCaptureFailueMessage` | `true` | ChapterMapScene.56ea0d90.lua:1660 |
| `missionId` | `self.currentMissionId` | ChapterMapScene.56ea0d90.lua:1660 |
| `routeId` | `self.currentRouteId` | ChapterMapScene.56ea0d90.lua:1660 |
| `step` | `self.currentFinishedStep + 1` | ChapterMapScene.56ea0d90.lua:1660 |


<a id="ep-triggerRandomEvent"></a>
#### `triggerRandomEvent` — TriggerRandomEventRequest

| 项 | 值 |
|---|---|
| 请求类 | `TriggerRandomEventRequest` |
| 定义文件 | `TriggerRandomEventRequest.6eff6ff2.lua` |
| 调用点数 | 1 |
调用点：`ChapterMapScene.56ea0d90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `DoNotCaptureFailueMessage` | `true` | ChapterMapScene.56ea0d90.lua:2052 |
| `missionId` | `self.currentMissionId` | ChapterMapScene.56ea0d90.lua:2052 |
| `routeId` | `self.currentRouteId` | ChapterMapScene.56ea0d90.lua:2052 |
| `step` | `self.currentFinishedStep + 1` | ChapterMapScene.56ea0d90.lua:2052 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `eventType` | 4 |


<a id="ep-validatePaymentOrder"></a>
#### `validatePaymentOrder`

| 项 | 值 |
|---|---|
| 请求类 | `ValidatePaymentOrderRequest` |
| 定义文件 | `ValidatePaymentOrderRequest.6fe4b9a2.lua` |
| 调用点数 | 3 |
调用点：`IosPlatformLogin.9d58c348.lua`, `GspBridge.0c348fb9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `goldNum` | `gold` | GspBridge.0c348fb9.lua:88 |
| `orderId` | `info` ・ `"local-" .. tostring(os.time()) .. "-" .. tostring(productId)` ・ `recieveOrderId` | IosPlatformLogin.9d58c348.lua:137 |
| `productId` | `productId` | GspBridge.0c348fb9.lua:88 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `succ` | 4 |


### 5.7 军团

<a id="ep-acceptUnionApply"></a>
#### `acceptUnionApply` — 军团同意申请

| 项 | 值 |
|---|---|
| 请求类 | `UnionAcceptRequest` |
| 定义文件 | `UnionAcceptRequest.db4fa7a7.lua` |
| 调用点数 | 1 |
调用点：`UnionApplierListPanel.ca9ac36c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `applierUid` | `aData.uid` | UnionAcceptRequest.db4fa7a7.lua:canon\request\UnionAcceptRequest.db4fa7a7e9221d21bfb7631dd22b440c.lua |


<a id="ep-applyCrossGvg"></a>
#### `applyCrossGvg` — 跨服GvG  报名请求

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetApplyRequest` |
| 定义文件 | `CrossUnionPkGetApplyRequest.d1b58d57.lua` |
| 调用点数 | 2 |
调用点：`CrossUnionPKLoginScene.912ba2bf.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `1` ・ `0` | CrossUnionPkGetApplyRequest.d1b58d57.lua:canon\features\crossUnionPk\request\CrossUnionPkGetApplyRequest.d1b58d5759a10a98b22e16aed96f8620.lua |


<a id="ep-applyUnion"></a>
#### `applyUnion` — 请求加入某军团

| 项 | 值 |
|---|---|
| 请求类 | `UnionApplyRequest` |
| 定义文件 | `UnionApplyRequest.b0e9f34c.lua` |
| 调用点数 | 1 |
调用点：`UnionListPanel.fe41ccb0.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionId` | `aData.unionId` | UnionApplyRequest.b0e9f34c.lua:canon\request\UnionApplyRequest.b0e9f34c3e09a808587369a498024995.lua |


<a id="ep-applyUnionCity"></a>
#### `applyUnionCity` — 军团战 报名攻打城池

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkSignAttackRequest` |
| 定义文件 | `UnionPkSignAttackRequest.3150114c.lua` |
| 调用点数 | 1 |
调用点：`UnionPkCityInfoPopPanel.53c4cba5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionCityId` | `self.cityData.cityId` | UnionPkSignAttackRequest.3150114c.lua:canon\features\unionPk\request\UnionPkSignAttackRequest.3150114c0ab044a627fdde9bc2428fa4.lua |


<a id="ep-appointUnion"></a>
#### `appointUnion` — 任命职务请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionAppointRequest` |
| 定义文件 | `UnionAppointRequest.32443dde.lua` |
| 调用点数 | 3 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `appointUid` | `targetMemberData.uid` | UnionAppointRequest.32443dde.lua:canon\request\UnionAppointRequest.32443dde97fe00fd436132fca8bcbfdb.lua |
| `title` | `UnionManager.TITLE_VICE_MANAGER` ・ `UnionManager.TITLE_ELITE_MEMBER` ・ `UnionManager.TITLE_MEMBER` | UnionAppointRequest.32443dde.lua:canon\request\UnionAppointRequest.32443dde97fe00fd436132fca8bcbfdb.lua |


<a id="ep-blessForCrossGVG"></a>
#### `blessForCrossGVG` — 跨服GvG  祝福请求

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetBlessRequest` |
| 定义文件 | `CrossUnionPkGetBlessRequest.ba5c92b1.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPKBlessingScene.215c36cd.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rank` | 6 |
| `rewards` | 2 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`rewards`


<a id="ep-buyUnionProp"></a>
#### `buyUnionProp` — BuyUnionPropRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyUnionPropRequest` |
| 定义文件 | `BuyUnionPropRequest.3e44cf8e.lua` |
| 调用点数 | 2 |
调用点：`UnionShopNormalPanel.6a73d00e.lua`, `UnionShopSpecialPanel.403eb39a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionPropId` | `aData.id` | UnionShopNormalPanel.6a73d00e.lua:259 |
| `unionPropType` | `1` ・ `2` | UnionShopNormalPanel.6a73d00e.lua:259 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |
| `retCode` | 2 |


<a id="ep-cancelDissolveUnion"></a>
#### `cancelDissolveUnion` — 取消解散军团

| 项 | 值 |
|---|---|
| 请求类 | `UnionCancelDissolveRequest` |
| 定义文件 | `UnionCancelDissolveRequest.fd3279fb.lua` |
| 调用点数 | 1 |
调用点：`UnionManageMenuPanel.a4a49e0b.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-cancelTransferUnion"></a>
#### `cancelTransferUnion` — 撤销转让军团长

| 项 | 值 |
|---|---|
| 请求类 | `UnionCancelTransferRequest` |
| 定义文件 | `UnionCancelTransferRequest.4dec28b6.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-cancelUnionApply"></a>
#### `cancelUnionApply` — 取消申请

| 项 | 值 |
|---|---|
| 请求类 | `UnionCancelApplyRequest` |
| 定义文件 | `UnionCancelApplyRequest.efe9ea22.lua` |
| 调用点数 | 1 |
调用点：`UnionListPanel.fe41ccb0.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionId` | `aData.unionId` | UnionCancelApplyRequest.efe9ea22.lua:canon\request\UnionCancelApplyRequest.efe9ea22cf3757ce53b2c00651b61361.lua |


<a id="ep-challengeUnionMonster"></a>
#### `challengeUnionMonster` — 军团挑战怪物

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumChallengeRequest` |
| 定义文件 | `UnionColosseumChallengeRequest.ce9e0acf.lua` |
| 调用点数 | 1 |
调用点：`UnionColosseumBossInfoPanel.48f6fc1b.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `generalExp` | 1 |
| `bossHpMax` | 1 |


<a id="ep-constructUnion"></a>
#### `constructUnion` — 建设

| 项 | 值 |
|---|---|
| 请求类 | `UnionConstructUnionRequest` |
| 定义文件 | `UnionConstructUnionRequest.693fa24c.lua` |
| 调用点数 | 1 |
调用点：`UnionHallScene.7f35b07d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `constructType` | `buildLevel` | UnionConstructUnionRequest.693fa24c.lua:canon\request\UnionConstructUnionRequest.693fa24cbd08e8e0d64b0fd03af8de99.lua |


<a id="ep-createUnion"></a>
#### `createUnion` — 创建军团请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionCreateRequest` |
| 定义文件 | `UnionCreateRequest.02b0159b.lua` |
| 调用点数 | 2 |
调用点：`UnionCreatePopPanel.077b5ebd.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `coinType` | `ResourceEnum.GEMS` ・ `ResourceEnum.COIN` | UnionCreateRequest.02b0159b.lua:canon\request\UnionCreateRequest.02b0159b3338bfcb18d64029d6b2f011.lua |
| `declaration` | `defaultDeclaration` | UnionCreateRequest.02b0159b.lua:canon\request\UnionCreateRequest.02b0159b3338bfcb18d64029d6b2f011.lua |
| `notice` | `defaultNotice` | UnionCreateRequest.02b0159b.lua:canon\request\UnionCreateRequest.02b0159b3338bfcb18d64029d6b2f011.lua |
| `unionName` | `selectedText` | UnionCreateRequest.02b0159b.lua:canon\request\UnionCreateRequest.02b0159b3338bfcb18d64029d6b2f011.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnion` | 2 |
| `sharkUnion.unionId` | 1 |


<a id="ep-crossGVGGroupBattle"></a>
#### `crossGVGGroupBattle` — 获得跨服军团战小组赛战斗信息

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGroupBattleRequest` |
| 定义文件 | `CrossUnionPkGroupBattleRequest.5b745209.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPKTeamAdjustScene.a1da1acc.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-dissolveUnion"></a>
#### `dissolveUnion` — 解散军团请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionDissolveRequest` |
| 定义文件 | `UnionDissolveRequest.c562fbce.lua` |
| 调用点数 | 1 |
调用点：`UnionManageMenuPanel.a4a49e0b.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnion` | 1 |
| `sharkUserUnion` | 1 |


<a id="ep-exchangeUnionFormation"></a>
#### `exchangeUnionFormation` — 军团战更换阵型请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkExchangeUnionFormationRequest` |
| 定义文件 | `UnionPkExchangeUnionFormationRequest.8ad2f97e.lua` |
| 调用点数 | 1 |
调用点：`UnionPkChangeFormationPopPanel.adcb7c7c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `forwardUid` | `self.forwardMemberData.uid` | UnionPkExchangeUnionFormationRequest.8ad2f97e.lua:canon\features\unionPk\request\UnionPkExchangeUnionFormationRequest.8ad2f97ee9ec6c8d1f553569eda38085.lua |
| `headUids` | `headUids` | UnionPkExchangeUnionFormationRequest.8ad2f97e.lua:canon\features\unionPk\request\UnionPkExchangeUnionFormationRequest.8ad2f97ee9ec6c8d1f553569eda38085.lua |
| `middleUids` | `middleUids` | UnionPkExchangeUnionFormationRequest.8ad2f97e.lua:canon\features\unionPk\request\UnionPkExchangeUnionFormationRequest.8ad2f97ee9ec6c8d1f553569eda38085.lua |
| `tailUids` | `tailUids` | UnionPkExchangeUnionFormationRequest.8ad2f97e.lua:canon\features\unionPk\request\UnionPkExchangeUnionFormationRequest.8ad2f97ee9ec6c8d1f553569eda38085.lua |
| `unionCityId` | `self.cityData.cityId` | UnionPkExchangeUnionFormationRequest.8ad2f97e.lua:canon\features\unionPk\request\UnionPkExchangeUnionFormationRequest.8ad2f97ee9ec6c8d1f553569eda38085.lua |


<a id="ep-forceQuitUnion"></a>
#### `forceQuitUnion` — 军团踢人请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionKickRequest` |
| 定义文件 | `UnionKickRequest.6d9f0a22.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `quitUid` | `targetMemberData.uid` | UnionKickRequest.6d9f0a22.lua:canon\request\UnionKickRequest.6d9f0a2286958dcefd9099c51865a1b7.lua |


<a id="ep-gainUnionBattleReward"></a>
#### `gainUnionBattleReward` — 军团战 请求获得 我的奖励

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGainUnionBattleRewardRequest` |
| 定义文件 | `UnionPkGainUnionBattleRewardRequest.57a7df32.lua` |
| 调用点数 | 1 |
调用点：`UnionPKMyRewardPopPanel.d95ebdb0.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardId` | `index` | UnionPkGainUnionBattleRewardRequest.57a7df32.lua:canon\features\unionPk\request\UnionPkGainUnionBattleRewardRequest.57a7df324f26362e208bb9ae9780eb96.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-getAppliedUnions"></a>
#### `getAppliedUnions` — 请求获取当前玩家的已申请军团列表

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetMyApplyListRequest` |
| 定义文件 | `UnionGetMyApplyListRequest.db7cf5b8.lua` |
| 调用点数 | 2 |
调用点：`UnionManager.00af801a.lua`, `UnionListScene.00865c6e.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionWrappers` | 3 |


<a id="ep-getApplyUnions"></a>
#### `getApplyUnions` — 军团战 获得指定城池具体信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetApplyUnionsRequest` |
| 定义文件 | `UnionPkGetApplyUnionsRequest.54f333ac.lua` |
| 调用点数 | 1 |
调用点：`UnionPkCityInfoPopPanel.53c4cba5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionCityId` | `self.cityData.cityId` | UnionPkGetApplyUnionsRequest.54f333ac.lua:canon\features\unionPk\request\UnionPkGetApplyUnionsRequest.54f333acd58333f52b5e4682746f2db2.lua |


<a id="ep-getCrossGVGBlessInfo"></a>
#### `getCrossGVGBlessInfo` — 跨服GvG  祝福请求

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetBlessInFoRequest` |
| 定义文件 | `CrossUnionPkGetBlessInFoRequest.01739184.lua` |
| 调用点数 | 2 |
调用点：`CrossUnionPk.ba058536.lua`, `CrossUnionPKBlessingScene.215c36cd.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rank` | 6 |
| `rewards` | 2 |
| `unionApplyCrossGvg` | 1 |
| `selfApplyCrossGvg` | 1 |
| `crossGvgVersion` | 1 |
| `selfQuitCrossGvg` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`blessNum`, `canBlessTimes`, `gainGvgKnockoutReward`, `king`, `kingUid`, `mainCardMetaId`, `nickname`, `serverId`, `unionName`


<a id="ep-getCrossGvgGroupReports"></a>
#### `getCrossGvgGroupReports` — 获得跨服军团战小组赛战报

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetGroupReportsRequest` |
| 定义文件 | `CrossUnionPkGetGroupReportsRequest.1a9e91f3.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPk.ba058536.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`reports`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossGvgGroupTop10Score"></a>
#### `getCrossGvgGroupTop10Score` — 取得跨服gvg 排位赛数据

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetGroupRankScoreRequest` |
| 定义文件 | `CrossUnionPkGetGroupRankScoreRequest.c20fba73.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPk.ba058536.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`selfScore`, `top10ScoreList`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getFiredUnionMemberStatus"></a>
#### `getFiredUnionMemberStatus` — 获得踢人之前获得被踢玩家当前状态

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkCheckFiredStatueRequest` |
| 定义文件 | `CrossUnionPkCheckFiredStatueRequest.c8d68b6b.lua` |
| 调用点数 | 2 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `firedUid` | `targetMemberData.uid` | CrossUnionPkCheckFiredStatueRequest.c8d68b6b.lua:canon\features\crossUnionPk\request\CrossUnionPkCheckFiredStatueRequest.c8d68b6b0120b127f800415e0b2d6e84.lua |


<a id="ep-getGvgBattleResultDetail"></a>
#### `getGvgBattleResultDetail` — 获取gvg战斗信息

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetBattleReportRequest` |
| 定义文件 | `CrossUnionPkGetBattleReportRequest.1b502719.lua` |
| 调用点数 | 2 |
调用点：`CrossUnionPkGroupReportsPanel.0279387b.lua`, `CrossUnionPkKnockoutScene.2570206b.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `knockout` | `false` ・ `true` | CrossUnionPkGetBattleReportRequest.1b502719.lua:canon\features\crossUnionPk\request\CrossUnionPkGetBattleReportRequest.1b502719c35e0ebf9428d4e07f3c565f.lua |
| `reportId` | `aData.uuid` ・ `reportId` | CrossUnionPkGetBattleReportRequest.1b502719.lua:canon\features\crossUnionPk\request\CrossUnionPkGetBattleReportRequest.1b502719c35e0ebf9428d4e07f3c565f.lua |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getGvgKnockoutInfo"></a>
#### `getGvgKnockoutInfo` — 取得跨服gvg 排位赛数据

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetKnockoutInfoRequest` |
| 定义文件 | `CrossUnionPkGetKnockoutInfoRequest.9688e362.lua` |
| 调用点数 | 2 |
调用点：`CrossUnionPk.ba058536.lua`, `CrossUnionPkKnockoutScene.2570206b.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `championBattle` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`championBattle`, `eight`, `four`, `sixteen`, `thirdPlaceBattle`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getOwnUnionInfo"></a>
#### `getOwnUnionInfo` — 军团战 获得 我的军团 列表信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionPKGetMyGuildInfoRequest` |
| 定义文件 | `UnionPKGetMyGuildInfoRequest.3ded5a0f.lua` |
| 调用点数 | 1 |
调用点：`UnionPkScene.e5ae4099.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getUnionAppliers"></a>
#### `getUnionAppliers` — 请求获得申请者列表

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetApplierListRequest` |
| 定义文件 | `UnionGetApplierListRequest.ff8256be.lua` |
| 调用点数 | 6 |
调用点：`UnionManager.00af801a.lua`, `UnionBottomMenuPanel.4327be48.lua`, `UnionManageMenuPanel.a4a49e0b.lua`, `UnionMemberListScene.5baa803f.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionAppliers` | 1 |


<a id="ep-getUnionBattlefieldReport"></a>
#### `getUnionBattlefieldReport` — 战报接口

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetBattleReportRequest` |
| 定义文件 | `UnionPkGetBattleReportRequest.2a2e040d.lua` |
| 调用点数 | 2 |
调用点：`UnionBattleReportPopPanel.add33c57.lua`, `UnionPkCityPowerupPopPanel.43d23ba6.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `reportId` | `evt.target.tableViewRenderer.list[aIndex].reportId` ・ `1` | UnionPkGetBattleReportRequest.2a2e040d.lua:canon\features\unionPk\request\UnionPkGetBattleReportRequest.2a2e040d7cdc0b177fab28d734b0f9c7.lua |
| `unionCityId` | `self.cityId` ・ `self.cityData.cityId` | UnionPkGetBattleReportRequest.2a2e040d.lua:canon\features\unionPk\request\UnionPkGetBattleReportRequest.2a2e040d7cdc0b177fab28d734b0f9c7.lua |


<a id="ep-getUnionBattlefieldReportList"></a>
#### `getUnionBattlefieldReportList` — 军团战 获得指定城池具体信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetBattleReportListRequest` |
| 定义文件 | `UnionPkGetBattleReportListRequest.3f45f406.lua` |
| 调用点数 | 1 |
调用点：`UnionPkCityInfoPopPanel.53c4cba5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionCityId` | `self.cityData.cityId` | UnionPkGetBattleReportListRequest.3f45f406.lua:canon\features\unionPk\request\UnionPkGetBattleReportListRequest.3f45f406343ad979f96e7a2100988198.lua |


<a id="ep-getUnionBuildingBankInfo"></a>
#### `getUnionBuildingBankInfo` — GetUnionBuildingBankInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetUnionBuildingBankInfoRequest` |
| 定义文件 | `GetUnionBuildingBankInfoRequest.92fda6ad.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `level` | 1 |


<a id="ep-getUnionBuildingColosseumInfo"></a>
#### `getUnionBuildingColosseumInfo` — 军团斗兽场建筑信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumBuildingInfoRequest` |
| 定义文件 | `UnionColosseumBuildingInfoRequest.e00552b1.lua` |
| 调用点数 | 4 |
调用点：`UnionManager.00af801a.lua`, `UnionColosseumBossInfoPanel.48f6fc1b.lua`, `UnionColosseumGetRankRequest.a7691f70.lua`, `UnionColosseumStartAllocationRequest.f9c320a6.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionMonster` | 9 |
| `level` | 1 |
| `summonTimes` | 1 |
| `rankList` | 1 |
| `unionWealth` | 1 |
| `sharkUnionMonster.summonUserNickname` | 1 |
| `sharkUnionMonster.monsterLeftHp` | 1 |
| `sharkUnionMonster.escapeSeconds` | 1 |
| `sharkUnionMonster.rewardDouble` | 1 |
| `sharkUnionMonster.monsterId` | 1 |
| `sharkUnionMonster.reward.amount` | 1 |
| `sharkUnionMonster.distributingUid` | 1 |
| `sharkUnionMonster.rewardDistributed` | 1 |


<a id="ep-getUnionBuildingHallInfo"></a>
#### `getUnionBuildingHallInfo` — GetUnionBuildingHallInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetUnionBuildingHallInfoRequest` |
| 定义文件 | `GetUnionBuildingHallInfoRequest.e65813af.lua` |
| 调用点数 | 2 |
调用点：`UnionManager.00af801a.lua`, `UnionHallScene.7f35b07d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `lastestConstructSeconds` | 1 |
| `constructTimesToday` | 1 |


<a id="ep-getUnionBuildingShopInfo"></a>
#### `getUnionBuildingShopInfo` — GetUnionBuildingShopInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetUnionBuildingShopInfoRequest` |
| 定义文件 | `GetUnionBuildingShopInfoRequest.9ec07c7f.lua` |
| 调用点数 | 5 |
调用点：`UnionManager.00af801a.lua`, `UnionShopSpecialPanel.403eb39a.lua`, `UnionShopScene.0dc9931e.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `level` | 1 |
| `specialProps` | 1 |
| `specialShopRecord` | 1 |


<a id="ep-getUnionCityInfo"></a>
#### `getUnionCityInfo` — 军团战 获得指定城池具体信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetCityInfoRequest` |
| 定义文件 | `UnionPkGetCityInfoRequest.9b9516df.lua` |
| 调用点数 | 4 |
调用点：`UnionPK.ad496a08.lua`, `UnionPkTest.96485232.lua`, `UnionPKMyGuildPopPanel.1da001b0.lua`, `UnionPkCityInfoPopPanel.53c4cba5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionCityId` | `cityId` ・ `self.cityData.cityId` ・ `data[index]` | UnionPkGetCityInfoRequest.9b9516df.lua:canon\features\unionPk\request\UnionPkGetCityInfoRequest.9b9516df3bcfb33ea95973e4a6e71982.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionCity` | 2 |
| `unionFormation` | 1 |
| `sharkUnionCity.report` | 1 |
| `sharkUnionCity.successfulBid` | 1 |


<a id="ep-getUnionCityList"></a>
#### `getUnionCityList` — 军团战 获得城池列表

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetCityListRequest` |
| 定义文件 | `UnionPkGetCityListRequest.604c0bf8.lua` |
| 调用点数 | 2 |
调用点：`UnionPK.ad496a08.lua`, `UnionPkScene.e5ae4099.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `ownCityIds` | 1 |
| `smallCityNum` | 1 |
| `roundWealth` | 1 |
| `userTitle` | 1 |
| `challengeCityIds` | 1 |
| `fightingCityIds` | 1 |
| `unionWinNum` | 1 |
| `attendBattleNum` | 1 |
| `unionFormation` | 1 |


<a id="ep-getUnionFormation"></a>
#### `getUnionFormation` — 获取军团战阵型信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetCityFormationRequest` |
| 定义文件 | `UnionPkGetCityFormationRequest.9ad34405.lua` |
| 调用点数 | 3 |
调用点：`UnionPK.ad496a08.lua`, `UnionPkCityPowerupPopPanel.43d23ba6.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionCityId` | `cityData.cityId` ・ `self.cityData.cityId` | UnionPkGetCityFormationRequest.9ad34405.lua:canon\features\unionPk\request\UnionPkGetCityFormationRequest.9ad34405703576576dd25023a9a38f14.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `unionFormation` | 2 |
| `sharkUnionCityApply` | 1 |


<a id="ep-getUnionInfo"></a>
#### `getUnionInfo` — 请求获得军团信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetUnionInfoRequest` |
| 定义文件 | `UnionGetUnionInfoRequest.d2018b79.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnion` | 1 |
| `sharkUnionBuildingWrapper` | 1 |
| `unionMonsterHp` | 1 |
| `unionMonsterEscapeSeconds` | 1 |
| `canDistributeMonsterReward` | 1 |
| `unionWarLightOn` | 1 |
| `unionTotalFightCapacity` | 1 |


<a id="ep-getUnionList"></a>
#### `getUnionList` — 查询军团列表请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetUnionListRequest` |
| 定义文件 | `UnionGetUnionListRequest.a2c0c616.lua` |
| 调用点数 | 4 |
调用点：`UnionManager.00af801a.lua`, `UnionListPanel.fe41ccb0.lua`, `UnionListScene.00865c6e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `amount` | `20` | UnionGetUnionListRequest.a2c0c616.lua:canon\request\UnionGetUnionListRequest.a2c0c61648162e5ad7bf8c1f6de67b1e.lua |
| `startNum` | `1` ・ `topRank` | UnionGetUnionListRequest.a2c0c616.lua:canon\request\UnionGetUnionListRequest.a2c0c61648162e5ad7bf8c1f6de67b1e.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionWrappers` | 2 |


<a id="ep-getUnionMembersList"></a>
#### `getUnionMembersList` — 获得军团成员列表

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetMemberListRequest` |
| 定义文件 | `UnionGetMemberListRequest.603f4d16.lua` |
| 调用点数 | 5 |
调用点：`UnionManager.00af801a.lua`, `UnionColosseumBossListPanel.5342babf.lua`, `UnionMemberListPanel.10242232.lua`, `UnionMemberListScene.5baa803f.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionMemberWrappers` | 2 |


<a id="ep-getUnionMonsterRank"></a>
#### `getUnionMonsterRank` — 获得斗兽场排行榜

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumGetRankRequest` |
| 定义文件 | `UnionColosseumGetRankRequest.a7691f70.lua` |
| 调用点数 | 2 |
调用点：`UnionColosseumBossInfoPanel.48f6fc1b.lua`, `UnionColosseumBossListPanel.5342babf.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rankList` | 1 |


<a id="ep-getUnionNewsList"></a>
#### `getUnionNewsList` — 获得军团动态请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetNewsRequest` |
| 定义文件 | `UnionGetNewsRequest.0e2518a0.lua` |
| 调用点数 | 2 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionNewsWrappers` | 10 |
| `unionWarNewsWrappers` | 2 |


<a id="ep-getUnionWarCityMembersList"></a>
#### `getUnionWarCityMembersList` — 获得军团战城池报名成员列表

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkGetCityMemberListRequest` |
| 定义文件 | `UnionPkGetCityMemberListRequest.771a7187.lua` |
| 调用点数 | 1 |
调用点：`UnionPK.ad496a08.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cityId` | `cityId` | UnionPkGetCityMemberListRequest.771a7187.lua:canon\features\unionPk\request\UnionPkGetCityMemberListRequest.771a71876d04701f51e64562be1abf1d.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `unionFormation` | 1 |


<a id="ep-getUserUnionInfo"></a>
#### `getUserUnionInfo` — 获得当前玩家的军团信息

| 项 | 值 |
|---|---|
| 请求类 | `UnionGetMyDataRequest` |
| 定义文件 | `UnionGetMyDataRequest.db580889.lua` |
| 调用点数 | 8 |
调用点：`UnionPkExchangeUnionFormationRequest.8ad2f97e.lua`, `UnionPkSignAttackRequest.3150114c.lua`, `UnionManager.00af801a.lua`, `UnionMemberListPanel.10242232.lua`, `UnionGetMemberListRequest.603f4d16.lua`, `MainMenuScene.2bc9508c.lua` 等 7 个文件

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUserUnion` | 2 |
| `out` | 1 |
| `unionApplyCrossGvg` | 1 |
| `selfApplyCrossGvg` | 1 |
| `crossGvgVersion` | 1 |
| `promotion` | 1 |
| `selfQuitCrossGvg` | 1 |
| `unionWarHintNum` | 1 |


<a id="ep-impeachUnionManager"></a>
#### `impeachUnionManager` — 弹劾军团长

| 项 | 值 |
|---|---|
| 请求类 | `UnionImpeachRequest` |
| 定义文件 | `UnionImpeachRequest.3a916429.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `currManagerNickName` | 1 |


<a id="ep-inspireUnionBattle"></a>
#### `inspireUnionBattle` — 鼓舞接口中BuffId / 1：金币鼓舞 / 2：银币鼓舞 / 3：奋力一击

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkPowerupRequest` |
| 定义文件 | `UnionPkPowerupRequest.ab378109.lua` |
| 调用点数 | 5 |
调用点：`UnionPkCityPowerupPopPanel.43d23ba6.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `buffId` | `UnionPkConsts.POWERUP_SILVER` ・ `UnionPkConsts.POWERUP_GOLD` ・ `UnionPkConsts.POWERUP_STRIKE` | UnionPkPowerupRequest.ab378109.lua:canon\features\unionPk\request\UnionPkPowerupRequest.ab378109d751fea5754c231b46e53940.lua |
| `unionCityId` | `self.cityData.cityId` | UnionPkPowerupRequest.ab378109.lua:canon\features\unionPk\request\UnionPkPowerupRequest.ab378109d751fea5754c231b46e53940.lua |


<a id="ep-modifyUnionDeclaration"></a>
#### `modifyUnionDeclaration` — 换宣言请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionChangeDeclarationRequest` |
| 定义文件 | `UnionChangeDeclarationRequest.08ea3c14.lua` |
| 调用点数 | 1 |
调用点：`UnionChangeDeclarationPopPanel.f3d23f80.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `declaration` | `selectedText` | UnionChangeDeclarationRequest.08ea3c14.lua:canon\request\UnionChangeDeclarationRequest.08ea3c1462463d9f954d866a2928159e.lua |


<a id="ep-modifyUnionNotice"></a>
#### `modifyUnionNotice` — 换公告请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionChangeNoticeRequest` |
| 定义文件 | `UnionChangeNoticeRequest.e7d8e136.lua` |
| 调用点数 | 1 |
调用点：`UnionChangeNoticePopPanel.1b5338c4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `notice` | `selectedText` | UnionChangeNoticeRequest.e7d8e136.lua:canon\request\UnionChangeNoticeRequest.e7d8e136e7e1518badd7f0a4fa099323.lua |


<a id="ep-quitUnion"></a>
#### `quitUnion` — 退出军团请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionQuitRequest` |
| 定义文件 | `UnionQuitRequest.20ca3224.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUserUnion` | 1 |


<a id="ep-receiveUnionWage"></a>
#### `receiveUnionWage` — ReceiveUnionWageRequest

| 项 | 值 |
|---|---|
| 请求类 | `ReceiveUnionWageRequest` |
| 定义文件 | `ReceiveUnionWageRequest.123a0b04.lua` |
| 调用点数 | 1 |
调用点：`UnionBankScene.726a9bf4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionWageId` | `UnionManager.getBankLevel()` | UnionBankScene.726a9bf4.lua:159 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-rejectUnionAllApplies"></a>
#### `rejectUnionAllApplies` — 请求全部拒绝

| 项 | 值 |
|---|---|
| 请求类 | `UnionRejectAllRequest` |
| 定义文件 | `UnionRejectAllRequest.e5c30dcc.lua` |
| 调用点数 | 1 |
调用点：`UnionMemberListScene.5baa803f.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-rejectUnionApply"></a>
#### `rejectUnionApply` — 军团拒绝申请

| 项 | 值 |
|---|---|
| 请求类 | `UnionRejectRequest` |
| 定义文件 | `UnionRejectRequest.d62ab6f2.lua` |
| 调用点数 | 1 |
调用点：`UnionApplierListPanel.ca9ac36c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `applierUid` | `aData.uid` | UnionRejectRequest.d62ab6f2.lua:canon\request\UnionRejectRequest.d62ab6f22096f2d9fa1705226c958fd9.lua |


<a id="ep-searchUnion"></a>
#### `searchUnion` — 查找军团请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionSearchRequest` |
| 定义文件 | `UnionSearchRequest.da396d66.lua` |
| 调用点数 | 1 |
调用点：`UnionListScene.00865c6e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionName` | `selectedText` | UnionSearchRequest.da396d66.lua:canon\request\UnionSearchRequest.da396d66a2fea71a33fb9bb947cd35d2.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionWrappers` | 2 |


<a id="ep-summonUnionMonster"></a>
#### `summonUnionMonster` — 召唤军团boss

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumSummonRequest` |
| 定义文件 | `UnionColosseumSummonRequest.376bde68.lua` |
| 调用点数 | 2 |
调用点：`UnionColosseumSummonSelectPopPanel.ee1d6d61.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `monsterMetaId` | `self.monsterData.id` | UnionColosseumSummonRequest.376bde68.lua:canon\request\UnionColosseumSummonRequest.376bde68a58eae45a13573b9878bfb5c.lua |
| `summonType` | `UnionManager.SUMMON_DOUBLE` ・ `UnionManager.SUMMON_NORMAL` | UnionColosseumSummonRequest.376bde68.lua:canon\request\UnionColosseumSummonRequest.376bde68a58eae45a13573b9878bfb5c.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUnionMonster` | 8 |
| `sharkUnionMonster.summonUserNickname` | 1 |
| `sharkUnionMonster.monsterLeftHp` | 1 |
| `sharkUnionMonster.escapeSeconds` | 1 |
| `sharkUnionMonster.rewardDouble` | 1 |
| `sharkUnionMonster.monsterId` | 1 |
| `sharkUnionMonster.reward.amount` | 1 |
| `sharkUnionMonster.distributingUid` | 1 |
| `sharkUnionMonster.rewardDistributed` | 1 |


<a id="ep-transferUnion"></a>
#### `transferUnion` — 移交军团长请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionTransferRequest` |
| 定义文件 | `UnionTransferRequest.f48328f8.lua` |
| 调用点数 | 1 |
调用点：`UnionManager.00af801a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `transferedUid` | `targetMemberData.uid` | UnionTransferRequest.f48328f8.lua:canon\request\UnionTransferRequest.f48328f84a891c6ea8480c2ea11bdd09.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `transferTime` | 2 |


<a id="ep-unionMonsterRewardDistributeBegin"></a>
#### `unionMonsterRewardDistributeBegin` — 军团斗兽场开始分配

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumStartAllocationRequest` |
| 定义文件 | `UnionColosseumStartAllocationRequest.f9c320a6.lua` |
| 调用点数 | 2 |
调用点：`UnionColosseumBossListPanel.5342babf.lua`, `UnionColosseumDistributionPopPanel.b6ac3944.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `currMonsterRewards` | 1 |


<a id="ep-unionMonsterRewardDistributeGiveUp"></a>
#### `unionMonsterRewardDistributeGiveUp` — 军团斗兽场放弃分配

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumGiveUpAllocationRequest` |
| 定义文件 | `UnionColosseumGiveUpAllocationRequest.7f10d5fa.lua` |
| 调用点数 | 1 |
调用点：`UnionColosseumDistributionPopPanel.b6ac3944.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-unionMonsterRewardDistributeSave"></a>
#### `unionMonsterRewardDistributeSave` — 军团斗兽场分配奖励

| 项 | 值 |
|---|---|
| 请求类 | `UnionColosseumAllocateRequest` |
| 定义文件 | `UnionColosseumAllocateRequest.6f4c3160.lua` |
| 调用点数 | 1 |
调用点：`UnionColosseumDistributionPopPanel.b6ac3944.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionMonsterRewards` | `requestList` | UnionColosseumAllocateRequest.6f4c3160.lua:canon\request\UnionColosseumAllocateRequest.6f4c3160a325464e671d1422c8d9f796.lua |


<a id="ep-upgradeUnionBuilding"></a>
#### `upgradeUnionBuilding` — 升级建筑请求

| 项 | 值 |
|---|---|
| 请求类 | `UnionBuildingUpgradeRequest` |
| 定义文件 | `UnionBuildingUpgradeRequest.2acf797b.lua` |
| 调用点数 | 1 |
调用点：`UnionBuildingUpgradePopPanel.8ccaeafb.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionBuildingId` | `self.buildingId` | UnionBuildingUpgradeRequest.2acf797b.lua:canon\request\UnionBuildingUpgradeRequest.2acf797b0c2276fa80c038acbb11b343.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `currLevel` | 1 |


<a id="ep-userApplyUnionCity"></a>
#### `userApplyUnionCity` — 团员报名指定城池

| 项 | 值 |
|---|---|
| 请求类 | `UnionPkMemberApplyRequest` |
| 定义文件 | `UnionPkMemberApplyRequest.f4d2f7da.lua` |
| 调用点数 | 1 |
调用点：`UnionPkCityInfoPopPanel.53c4cba5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `unionCityId` | `self.cityData.cityId` | UnionPkMemberApplyRequest.f4d2f7da.lua:canon\features\unionPk\request\UnionPkMemberApplyRequest.f4d2f7da603a30c179ad8f4123c04449.lua |


### 5.8 卡牌养成

<a id="ep-adjustCardAvatar"></a>
#### `adjustCardAvatar` — 卖出元神

| 项 | 值 |
|---|---|
| 请求类 | `AdjustCardAvatarRequest` |
| 定义文件 | `AdjustCardAvatarRequest.c6f318ec.lua` |
| 调用点数 | 1 |
调用点：`CardSelectPanel.9ed0badb.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `avatarMetaId` | `metaId` | CardSelectPanel.9ed0badb.lua:279 |
| `cardId` | `self.cardNewPanel.cardId` | CardSelectPanel.9ed0badb.lua:279 |


<a id="ep-buyMonthGemCard"></a>
#### `buyMonthGemCard` — BuyMonthGemCardRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyMonthGemCardRequest` |
| 定义文件 | `BuyMonthGemCardRequest.7c7c42f6.lua` |
| 调用点数 | 1 |
调用点：`Activity_MonthCardLayer.26bc91b6.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `monthGemCardDeadline` | 3 |


<a id="ep-evolveCard"></a>
#### `evolveCard` — 卡牌进化Request / 参数1：masterId / 参数2：slaveId

| 项 | 值 |
|---|---|
| 请求类 | `CardEvolutionRequest` |
| 定义文件 | `CardEvolutionRequest.c2f65907.lua` |
| 调用点数 | 2 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CardEvolutionScene.cc52d9fb.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `masterId` | `masterId` | CardInfoNewPanel.6ac529d8.lua:1811 |
| `slaveId` | `slaveId` | CardInfoNewPanel.6ac529d8.lua:1811 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkCard` | 6 |
| `sharkCard.metaId` | 2 |


<a id="ep-evolveEquip"></a>
#### `evolveEquip` — EvolveEquipRequest

| 项 | 值 |
|---|---|
| 请求类 | `EvolveEquipRequest` |
| 定义文件 | `EvolveEquipRequest.d277d9ea.lua` |
| 调用点数 | 1 |
调用点：`EquipEvolveScene.0294c0e8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `equipId` | `arg.equipId` | EquipEvolveScene.0294c0e8.lua:850 |
| `userGems` | `arg.useGems` | EquipEvolveScene.0294c0e8.lua:850 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkEquip` | 1 |
| `equipId` | 1 |


<a id="ep-exchangeCard"></a>
#### `exchangeCard` — 卡牌以旧换新兑换请求

| 项 | 值 |
|---|---|
| 请求类 | `CardOldToNewExchangeRequest` |
| 定义文件 | `CardOldToNewExchangeRequest.a4f3b533.lua` |
| 调用点数 | 1 |
调用点：`CardOldToNewExchangeScene.c669adc9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `exchangeCardIds` | CardOldToNewExchangeRequest.a4f3b533.lua:canon\request\CardOldToNewExchangeRequest.a4f3b533c9f8bd3b76b597d2c07996be.lua |
| `shopId` | `self.argv.params.exchangeId` | CardOldToNewExchangeRequest.a4f3b533.lua:canon\request\CardOldToNewExchangeRequest.a4f3b533c9f8bd3b76b597d2c07996be.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 2 |


<a id="ep-exchangeCardDaily"></a>
#### `exchangeCardDaily` — 易帅换将

| 项 | 值 |
|---|---|
| 请求类 | `ActivityexchangeCardDailyRequest` |
| 定义文件 | `ActivityexchangeCardDailyRequest.4cee3bb5.lua` |
| 调用点数 | 1 |
调用点：`CardOldToNewExchangeScene.c669adc9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `exchangeCardIds` | ActivityexchangeCardDailyRequest.4cee3bb5.lua:canon\request\ActivityexchangeCardDailyRequest.4cee3bb5afb9d065e1227ed2810b3283.lua |
| `metaId` | `exchangeMeta.cardId` | ActivityexchangeCardDailyRequest.4cee3bb5.lua:canon\request\ActivityexchangeCardDailyRequest.4cee3bb5afb9d065e1227ed2810b3283.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 2 |


<a id="ep-exchangeTrainDanByArenaScore"></a>
#### `exchangeTrainDanByArenaScore` — ExchangeTrainDanRequest

| 项 | 值 |
|---|---|
| 请求类 | `ExchangeTrainDanRequest` |
| 定义文件 | `ExchangeTrainDanRequest.36398ace.lua` |
| 调用点数 | 1 |
调用点：`ArenaExchangeScene.b7cb89da.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `exchangeType` | `aEId` | ArenaExchangeScene.b7cb89da.lua:615 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemType` | 3 |
| `metaId` | 3 |
| `rewards` | 2 |
| `requisite` | 1 |
| `amount` | 1 |


<a id="ep-gainedMonthGemCardReward"></a>
#### `gainedMonthGemCardReward` — GainMonthCardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainMonthCardRequest` |
| 定义文件 | `GainMonthCardRequest.19dc6d07.lua` |
| 调用点数 | 1 |
调用点：`Activity_MonthCardLayer.26bc91b6.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-getCardBook"></a>
#### `getCardBook` — GetCardBookRequest.lua - get cards illustrated info requeset

| 项 | 值 |
|---|---|
| 请求类 | `GetCardBookRequest` |
| 定义文件 | `GetCardBookRequest.47d2abe9.lua` |
| 调用点数 | 2 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CanonCardScene.cdd1b27c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkCardBook` | 9 |
| `sharkCardBook.cardMetaIds` | 4 |
| `sharkCardBook.equipMetaIds` | 2 |


<a id="ep-giveUpCardTrain"></a>
#### `giveUpCardTrain` — GiveUpCardTrainRequest.lua - 放弃卡片培养的请求

| 项 | 值 |
|---|---|
| 请求类 | `GiveUpCardTrainRequest` |
| 定义文件 | `GiveUpCardTrainRequest.02ebbc04.lua` |
| 调用点数 | 3 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CardTrainingScene.38592680.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `self.cardId` | CardInfoNewPanel.6ac529d8.lua:2496 |
| `masterId` | `self.parentView.cardId` | CardInfoNewPanel.6ac529d8.lua:1543 |
| `slaveIds` | `slaveIds` | CardInfoNewPanel.6ac529d8.lua:1543 |
| *(动态)* | params | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkCard` | 2 |
| `sharkCard.usedPotential` | 1 |


<a id="ep-lockCard"></a>
#### `lockCard` — LockCardRequest

| 项 | 值 |
|---|---|
| 请求类 | `LockCardRequest` |
| 定义文件 | `LockCardRequest.2c9fce5e.lua` |
| 调用点数 | 1 |
调用点：`CardInfoNewPanel.6ac529d8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `self.parentView.cardId` | CardInfoNewPanel.6ac529d8.lua:103 |
| `methodType` | `aCardData.lock and 2 or 1` | CardInfoNewPanel.6ac529d8.lua:103 |


<a id="ep-prayCardFragment"></a>
#### `prayCardFragment` — PrayCardFragmentRequest

| 项 | 值 |
|---|---|
| 请求类 | `PrayCardFragmentRequest` |
| 定义文件 | `PrayCardFragmentRequest.90170adf.lua` |
| 调用点数 | 1 |
调用点：`Activity_SoulPrayerLayer.99cbe025.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `self.sharkCard.cardId` | Activity_SoulPrayerLayer.99cbe025.lua:144 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `prayNum` | 2 |
| `rewards` | 2 |


<a id="ep-refreshCardExchangeDaillyCard"></a>
#### `refreshCardExchangeDaillyCard`

| 项 | 值 |
|---|---|
| 请求类 | `ActivereFreshCardExchangeDaillyCardRequest` |
| 定义文件 | `ActivereFreshCardExchangeDaillyCardRequest.eda7ab7c.lua` |
| 调用点数 | 2 |
调用点：`Activity_ExchangeDailyLayer.8ca95379.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `useGold` | `false` ・ `true` | ActivereFreshCardExchangeDaillyCardRequest.eda7ab7c.lua:canon\request\ActivereFreshCardExchangeDaillyCardRequest.eda7ab7c0f5684018a3a1ba20a71f41c.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `cardExchangeDailyInfo` | 4 |
| `cardExchangeDailyInfo.exchangeTimes` | 2 |
| `cardExchangeDailyInfo.cardMetaIds` | 2 |


<a id="ep-replaceCard"></a>
#### `replaceCard` — ReplaceCardRequest.lua - 重整队列的请求

| 项 | 值 |
|---|---|
| 请求类 | `ReplaceCardRequest` |
| 定义文件 | `ReplaceCardRequest.5cd6ba0d.lua` |
| 调用点数 | 1 |
调用点：`BackpackScene.9b0694aa.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `insertCardId` | `SELF._data.cardId` | BackpackScene.9b0694aa.lua:3633 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `type` | 1 |


<a id="ep-saveCardTrain"></a>
#### `saveCardTrain` — SaveCardTrainRequest.lua - 保存卡片培养结果的请求

| 项 | 值 |
|---|---|
| 请求类 | `SaveCardTrainRequest` |
| 定义文件 | `SaveCardTrainRequest.a6e89cc0.lua` |
| 调用点数 | 2 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CardTrainingScene.38592680.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `masterId` | `self.parentView.cardId` | CardInfoNewPanel.6ac529d8.lua:1588 |
| `slaveIds` | `slaveIds` | CardInfoNewPanel.6ac529d8.lua:1588 |
| *(动态)* | params | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkCard` | 7 |
| `sharkCard.usedPotential` | 2 |
| `sharkCard.cardId` | 2 |


<a id="ep-sellCards"></a>
#### `sellCards` — SellCardsRequest.lua - 出售装备的请求

| 项 | 值 |
|---|---|
| 请求类 | `SellCardsRequest` |
| 定义文件 | `SellCardsRequest.330c4808.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardIds` | `items` | ItemSellMessageBoxPanel.7afb89c9.lua:196 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-setCardGroupInterworking"></a>
#### `setCardGroupInterworking` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `SetCardGroupInterworkingRequest` |
| 定义文件 | `SetCardGroupInterworkingRequest.fa8c66fa.lua` |
| 调用点数 | 1 |
调用点：`FateScene.fe53bad0.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardGroupInterworking` | `not gameInitData.sharkUserExtend.cardGroupInterworking` | FateScene.fe53bad0.lua:103 |


<a id="ep-splitCard"></a>
#### `splitCard` — SplitCardRequest

| 项 | 值 |
|---|---|
| 请求类 | `SplitCardRequest` |
| 定义文件 | `SplitCardRequest.3dac85e6.lua` |
| 调用点数 | 1 |
调用点：`CardRebirthScene.f580de62.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `self.cardData.cardId` | CardRebirthScene.f580de62.lua:1060 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


<a id="ep-trainCard"></a>
#### `trainCard` — CardTrainingRequest.lua - 培养卡片的请求

| 项 | 值 |
|---|---|
| 请求类 | `CardTrainingRequest` |
| 定义文件 | `CardTrainingRequest.769fa42b.lua` |
| 调用点数 | 2 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CardTrainingScene.38592680.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | trainOpts | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `attTrainValue` | 1 |
| `defTrainValue` | 1 |
| `hpTrainValue` | 1 |


<a id="ep-triggerCardEvent"></a>
#### `triggerCardEvent` — TriggerCardEventRequest

| 项 | 值 |
|---|---|
| 请求类 | `TriggerCardEventRequest` |
| 定义文件 | `TriggerCardEventRequest.b630e8ba.lua` |
| 调用点数 | 1 |
调用点：`ChapterMapScene.56ea0d90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `DoNotCaptureFailueMessage` | `true` | ChapterMapScene.56ea0d90.lua:1807 |
| `missionId` | `self.currentMissionId` | ChapterMapScene.56ea0d90.lua:1807 |
| `routeId` | `self.currentRouteId` | ChapterMapScene.56ea0d90.lua:1807 |
| `step` | `self.currentFinishedStep + 1` | ChapterMapScene.56ea0d90.lua:1807 |


<a id="ep-unlockSubAttribute"></a>
#### `unlockSubAttribute` — 解锁元神副属性

| 项 | 值 |
|---|---|
| 请求类 | `UnlockSubAttributeRequest` |
| 定义文件 | `UnlockSubAttributeRequest.bf93701f.lua` |
| 调用点数 | 1 |
调用点：`SpiritComposePanel.83663dd4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `spiritId` | `self.spirit.spiritId` | SpiritComposePanel.83663dd4.lua:692 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkSpiritAttribute` | 1 |


<a id="ep-upgradeCardByGeneralExp"></a>
#### `upgradeCardByGeneralExp` — 卡牌经验强化接口

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeCardByGeneralExpRequest` |
| 定义文件 | `UpgradeCardByGeneralExpRequest.f78549cc.lua` |
| 调用点数 | 2 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CardComposeScene.8612aa78.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `masterId` | `getCardInfoFromInitData(self.parentView.cardId).cardId` ・ `self.currentCardData.cardId` | UpgradeCardByGeneralExpRequest.f78549cc.lua:canon\request\UpgradeCardByGeneralExpRequest.f78549cc0784e269335a0b514370d142.lua |
| `targetLevel` | `self.currentTargetLevel` | UpgradeCardByGeneralExpRequest.f78549cc.lua:canon\request\UpgradeCardByGeneralExpRequest.f78549cc0784e269335a0b514370d142.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkCard` | 1 |


<a id="ep-upgradeEquipForOneCard"></a>
#### `upgradeEquipForOneCard` — 卡牌装备全部强化

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeEquipForOneCardRequest` |
| 定义文件 | `UpgradeEquipForOneCardRequest.0b3f42c4.lua` |
| 调用点数 | 1 |
调用点：`EquipQuickUpgradeScene.ace72441.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `equipIds` | `self.upgardeEquipId` | UpgradeEquipForOneCardRequest.0b3f42c4.lua:canon\request\UpgradeEquipForOneCardRequest.0b3f42c4553bec771f17043ec316f838.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkEquips` | 1 |


<a id="ep-upgradeSkill"></a>
#### `upgradeSkill` — UpgradeSkillRequest.lua - 技能升级的请求

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeSkillRequest` |
| 定义文件 | `UpgradeSkillRequest.232e286d.lua` |
| 调用点数 | 2 |
调用点：`SkillEvolveScene.247c6c83.lua`, `SkillUpgradeScene.0d6f6ea2.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `self.cardId` | SkillEvolveScene.247c6c83.lua:369 |
| `skillBooks` | `skillBooks1` | SkillUpgradeScene.0d6f6ea2.lua:860 |
| `skillId` | `self.skillId` | SkillEvolveScene.247c6c83.lua:369 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `cardSkill.skillId` | 4 |
| `cardSkill` | 4 |


<a id="ep-upgradeUser"></a>
#### `upgradeUser` — UpgradeUserRequest.lua - 用户升级的请求

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeUserRequest` |
| 定义文件 | `UpgradeUserRequest.fa91b55e.lua` |
| 调用点数 | 1 |
调用点：`UserLevelManager.436a6b7f.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUser` | 1 |


### 5.9 夺宝 / 神兽

<a id="ep-getRobUserList"></a>
#### `getRobUserList` — GetRobUserListRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetRobUserListRequest` |
| 定义文件 | `GetRobUserListRequest.f5d4e67c.lua` |
| 调用点数 | 1 |
调用点：`RobFragmentScene.81537fa5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `beastFragmentId` | `beastFragmentId` | RobFragmentScene.81537fa5.lua:554 |


<a id="ep-getSharkBeasts"></a>
#### `getSharkBeasts`

| 项 | 值 |
|---|---|
| 请求类 | `GetSharkBeastsRequest` |
| 定义文件 | `GetSharkBeastsRequest.b66f15fb.lua` |
| 调用点数 | 2 |
调用点：`BeastScene.c3e11a4d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkBeasts` | 2 |


<a id="ep-robBeastFragment"></a>
#### `robBeastFragment` — RobBeastFragmentRequest

| 项 | 值 |
|---|---|
| 请求类 | `RobBeastFragmentRequest` |
| 定义文件 | `RobBeastFragmentRequest.aefe107b.lua` |
| 调用点数 | 1 |
调用点：`RobFragmentScene.81537fa5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `beastFragmentId` | `extraArgs.beastFragmentId` | RobFragmentScene.81537fa5.lua:575 |
| `enemyUid` | `extraArgs.enemyUid` | RobFragmentScene.81537fa5.lua:575 |
| `robType` | `extraArgs.robType` | RobFragmentScene.81537fa5.lua:575 |
| `robotId` | `extraArgs.robotId` | RobFragmentScene.81537fa5.lua:575 |


### 5.10 好友社交

<a id="ep-acceptAllFreeGift"></a>
#### `acceptAllFreeGift` — SendAllFreeGiftRequest.lua - 向玩家发送免费礼物

| 项 | 值 |
|---|---|
| 请求类 | `AcceptAllFreeGiftRequest` |
| 定义文件 | `AcceptAllFreeGiftRequest.24f53f71.lua` |
| 调用点数 | 1 |
调用点：`MyFriendsPanel.da9e823d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gainedEnergy` | 1 |


<a id="ep-acceptAllInvitations"></a>
#### `acceptAllInvitations` — AcceptAllInvitationsRequest.lua - 接受所有玩家的好友邀请

| 项 | 值 |
|---|---|
| 请求类 | `AcceptAllInvitationsRequest` |
| 定义文件 | `AcceptAllInvitationsRequest.721b5137.lua` |
| 调用点数 | 1 |
调用点：`InviteReceivedPanel.8578b0c1.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `acceptedFriends` | 1 |
| `reviewingFriends` | 1 |


<a id="ep-acceptInvitation"></a>
#### `acceptInvitation` — AcceptInvitationRequest.lua - 接受玩家的添加好友邀请

| 项 | 值 |
|---|---|
| 请求类 | `AcceptInvitationRequest` |
| 定义文件 | `AcceptInvitationRequest.3b450586.lua` |
| 调用点数 | 2 |
调用点：`InviteReceivedPanel.8578b0c1.lua`, `UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `friendUid` ・ `self.friendUid` | InviteReceivedPanel.8578b0c1.lua:243 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `acceptedFriend` | 1 |


<a id="ep-cancelInvitation"></a>
#### `cancelInvitation` — CancelInvitationRequest.lua - 接受玩家的添加好友邀请

| 项 | 值 |
|---|---|
| 请求类 | `CancelInvitationRequest` |
| 定义文件 | `CancelInvitationRequest.db3c2412.lua` |
| 调用点数 | 2 |
调用点：`InviteSentPanel.66a3b721.lua`, `UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `friendUid` ・ `self.friendUid` | InviteSentPanel.66a3b721.lua:153 |


<a id="ep-challengeFriend"></a>
#### `challengeFriend` — ChallengeFriendRequest.lua - 与好友切磋请求

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeFriendRequest` |
| 定义文件 | `ChallengeFriendRequest.559d4d27.lua` |
| 调用点数 | 1 |
调用点：`UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `self.friendUid` | UserDetailPanel.7356d71e.lua:334 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `tableContentHeight` | 1 |


<a id="ep-challengeFriendList"></a>
#### `challengeFriendList` — 一键切磋

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeFriendListRequest` |
| 定义文件 | `ChallengeFriendListRequest.19d3b17f.lua` |
| 调用点数 | 1 |
调用点：`UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUids` | `friendUids` | ChallengeFriendListRequest.19d3b17f.lua:canon\request\ChallengeFriendListRequest.19d3b17f8a9747d208da25639bbe9a4b.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`rewards`


<a id="ep-deleteFriend"></a>
#### `deleteFriend` — DeleteFriendRequest.lua - 接受玩家的添加好友邀请

| 项 | 值 |
|---|---|
| 请求类 | `DeleteFriendRequest` |
| 定义文件 | `DeleteFriendRequest.cc4809bf.lua` |
| 调用点数 | 1 |
调用点：`UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `self.friendUid` | UserDetailPanel.7356d71e.lua:404 |


<a id="ep-gainPraiseReward"></a>
#### `gainPraiseReward` — 领取点赞礼包奖励

| 项 | 值 |
|---|---|
| 请求类 | `GainPraiseRewardRequest` |
| 定义文件 | `GainPraiseRewardRequest.513f4bc5.lua` |
| 调用点数 | 1 |
调用点：`Activity_PraiseLayer.ec347692.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `praiseId` | `clickContext` | GainPraiseRewardRequest.513f4bc5.lua:canon\request\GainPraiseRewardRequest.513f4bc57f4c453fc2076b1180ad138f.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-getFriendDetail"></a>
#### `getFriendDetail` — GetFriendDetailRequest.lua - 获取好友的详情

| 项 | 值 |
|---|---|
| 请求类 | `GetFriendDetailRequest` |
| 定义文件 | `GetFriendDetailRequest.cac2036a.lua` |
| 调用点数 | 2 |
调用点：`AcrossUserDetailPanel.62232f9a.lua`, `UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `self.params.uid` ・ `self.friendUid` | AcrossUserDetailPanel.62232f9a.lua:120 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkFriendDetail` | 6 |
| `sharkFriendDetail.nickName` | 1 |
| `sharkFriendDetail.level` | 1 |
| `sharkFriendDetail.fightCapacity` | 1 |
| `sharkFriendDetail.friendUid` | 1 |
| `sharkFriendDetail.mainCardMetaId` | 1 |


<a id="ep-getFriends"></a>
#### `getFriends` — GetFriendsRequest.lua - 获取当前玩家的好友信息

| 项 | 值 |
|---|---|
| 请求类 | `GetFriendsRequest` |
| 定义文件 | `GetFriendsRequest.af3a0480.lua` |
| 调用点数 | 2 |
调用点：`UserDetailPanel.7356d71e.lua`, `FriendScene.d9382f2c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkFriends` | 2 |
| `receivedEnergy` | 1 |


<a id="ep-getInvitationFriends"></a>
#### `getInvitationFriends` — GetFriends.lua - 获取当前玩家的好友信息

| 项 | 值 |
|---|---|
| 请求类 | `GetInvitationFriendsRequest` |
| 定义文件 | `GetInvitationFriendsRequest.c1a5dbe3.lua` |
| 调用点数 | 1 |
调用点：`FriendScene.d9382f2c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkFriends` | 1 |


<a id="ep-getInvitationInfo"></a>
#### `getInvitationInfo` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `GetInvitationInfoRequest` |
| 定义文件 | `GetInvitationInfoRequest.739aa21c.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `deviceId` | `getDeviceId()` | ActivityPanelScene.71655c90.lua:602 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkAccountInvitation` | 2 |
| `deviceHasInvited` | 1 |


<a id="ep-getRecommendedFriends"></a>
#### `getRecommendedFriends` — GetRecommendedFriendsRequest.lua - 获取推荐好友信息

| 项 | 值 |
|---|---|
| 请求类 | `GetRecommendedFriendsRequest` |
| 定义文件 | `GetRecommendedFriendsRequest.de0d51fc.lua` |
| 调用点数 | 2 |
调用点：`FindFriendsPanel.4fa3f8f2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkFriends` | 2 |


<a id="ep-getReviewFriends"></a>
#### `getReviewFriends` — GetReviewFriendsRequest.lua - 获取等待玩家审核的用户请求列表

| 项 | 值 |
|---|---|
| 请求类 | `GetReviewFriendsRequest` |
| 定义文件 | `GetReviewFriendsRequest.90a99f7e.lua` |
| 调用点数 | 1 |
调用点：`FriendScene.d9382f2c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkFriends` | 1 |


<a id="ep-inviteFbFriends"></a>
#### `inviteFbFriends` — Facebook相关

| 项 | 值 |
|---|---|
| 请求类 | `FacebookInviteFriendRequest` |
| 定义文件 | `FacebookActivityRequest.fe356c3f.lua` |
| 调用点数 | 1 |
调用点：`Activity_FacebookShareLayer.0f401528.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `fbFriendIds` | `friendList` | Activity_FacebookShareLayer.0f401528.lua:246 |


<a id="ep-recordPraiseId"></a>
#### `recordPraiseId` — 获取记录点赞id

| 项 | 值 |
|---|---|
| 请求类 | `GetRecordPraiseIdRequest` |
| 定义文件 | `GetRecordPraiseIdRequest.2f91ff83.lua` |
| 调用点数 | 1 |
调用点：`Activity_PraiseLayer.ec347692.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `praiseId` | `clickContext` | GetRecordPraiseIdRequest.2f91ff83.lua:canon\request\GetRecordPraiseIdRequest.2f91ff8302ed1838ed3234c39ad43360.lua |


<a id="ep-refuseAllInvitations"></a>
#### `refuseAllInvitations` — RefuseAllInvitationsRequest.lua - 拒绝所有玩家的好友邀请

| 项 | 值 |
|---|---|
| 请求类 | `RefuseAllInvitationsRequest` |
| 定义文件 | `RefuseAllInvitationsRequest.598c64ef.lua` |
| 调用点数 | 1 |
调用点：`InviteReceivedPanel.8578b0c1.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-refuseInvitation"></a>
#### `refuseInvitation` — RefuseInvitationRequest.lua - 拒绝玩家的添加好友邀请

| 项 | 值 |
|---|---|
| 请求类 | `RefuseInvitationRequest` |
| 定义文件 | `RefuseInvitationRequest.390248d4.lua` |
| 调用点数 | 2 |
调用点：`InviteReceivedPanel.8578b0c1.lua`, `UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `friendUid` ・ `self.friendUid` | InviteReceivedPanel.8578b0c1.lua:260 |


<a id="ep-sendAllFreeGift"></a>
#### `sendAllFreeGift` — SendAllFreeGiftRequest.lua - 向玩家发送免费礼物

| 项 | 值 |
|---|---|
| 请求类 | `SendAllFreeGiftRequest` |
| 定义文件 | `SendAllFreeGiftRequest.2e59fd25.lua` |
| 调用点数 | 1 |
调用点：`MyFriendsPanel.da9e823d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUids` | `notSentUids` | MyFriendsPanel.da9e823d.lua:544 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `friendUids` | 1 |
| `gainedEnergy` | 1 |


<a id="ep-sendAllInvitations"></a>
#### `sendAllInvitations` — SendAllInvitationsRequest.lua - 发送全部邀请

| 项 | 值 |
|---|---|
| 请求类 | `SendAllInvitationsRequest` |
| 定义文件 | `SendAllInvitationsRequest.05aa871b.lua` |
| 调用点数 | 1 |
调用点：`FindFriendsPanel.4fa3f8f2.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUids` | `sendingUids` | FindFriendsPanel.4fa3f8f2.lua:515 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `friendUids` | 1 |


<a id="ep-sendFreeGift"></a>
#### `sendFreeGift` — SendFreeGiftRequest.lua - 向玩家发送免费礼物

| 项 | 值 |
|---|---|
| 请求类 | `SendFreeGiftRequest` |
| 定义文件 | `SendFreeGiftRequest.98ee6609.lua` |
| 调用点数 | 1 |
调用点：`MyFriendsPanel.da9e823d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `aData.friendUid` | MyFriendsPanel.da9e823d.lua:335 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gainedEnergy` | 1 |


<a id="ep-sendInvitation"></a>
#### `sendInvitation` — SendInvitationRequest.lua - 发送邀请

| 项 | 值 |
|---|---|
| 请求类 | `SendInvitationRequest` |
| 定义文件 | `SendInvitationRequest.a16137b1.lua` |
| 调用点数 | 3 |
调用点：`UnionManager.00af801a.lua`, `FindFriendsPanel.4fa3f8f2.lua`, `UserDetailPanel.7356d71e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `friendUid` | `targetMemberData.uid` ・ `aData.friendUid` ・ `self.friendUid` | UnionManager.00af801a.lua:1156 |


### 5.11 宝物

<a id="ep-buyTreasureGrid"></a>
#### `buyTreasureGrid` — 宝物格子

| 项 | 值 |
|---|---|
| 请求类 | `BuyTreasureGridRequest` |
| 定义文件 | `BuyTreasureGridRequest.a343619a.lua` |
| 调用点数 | 2 |
调用点：`TreasurePackageFullPanel.7fb358e8.lua`, `TreasureBackpackScene.cd3f6cb8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | onSucceed | 参数表由上层构造，见调用点 |


<a id="ep-evolveTreasure"></a>
#### `evolveTreasure` — 宝物升星

| 项 | 值 |
|---|---|
| 请求类 | `EvolveTreasureRequest` |
| 定义文件 | `EvolveTreasureRequest.32d9ef65.lua` |
| 调用点数 | 1 |
调用点：`TreasureNewInfoPanel.b22b6a6a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `treasureId` | `self.parentView.Treasure.treasureId` | EvolveTreasureRequest.32d9ef65.lua:canon\features\treasureSystem\request\EvolveTreasureRequest.32d9ef65ee8531a36f358f189539b707.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkTreasure` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`sharkTreasure`, `sharkTreasure.addGemPotential`, `sharkTreasure.addPotential`, `sharkTreasure.cardId`, `sharkTreasure.level`, `sharkTreasure.lock`, `sharkTreasure.metaId`, `sharkTreasure.treasureId`, `sharkTreasure.usedPotential`


<a id="ep-gachaTreasure"></a>
#### `gachaTreasure` — 宝物扭蛋

| 项 | 值 |
|---|---|
| 请求类 | `GachaTreasureRequest` |
| 定义文件 | `GachaTreasureRequest.48f3d140.lua` |
| 调用点数 | 1 |
调用点：`TreasureGachaScene.432faf6f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `free` | `freeGacha` | GachaTreasureRequest.48f3d140.lua:canon\features\treasureSystem\request\GachaTreasureRequest.48f3d140cf71bb8f8d4af017a1f1fd80.lua |
| `time` | `time` | GachaTreasureRequest.48f3d140.lua:canon\features\treasureSystem\request\GachaTreasureRequest.48f3d140cf71bb8f8d4af017a1f1fd80.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


<a id="ep-gainTreasureboxPointsRankReward"></a>
#### `gainTreasureboxPointsRankReward` — TreasureboxRankRewardRequest.lua

| 项 | 值 |
|---|---|
| 请求类 | `TreasureboxRankRewardRequest` |
| 定义文件 | `TreasureboxRankRewardRequest.611d25c3.lua` |
| 调用点数 | 1 |
调用点：`Activity_TreasureboxRankLayer.46ddc1f5.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainTreasureboxPointsReward"></a>
#### `gainTreasureboxPointsReward` — TreasureboxPointRewardRequest.lua

| 项 | 值 |
|---|---|
| 请求类 | `TreasureboxPointRewardRequest` |
| 定义文件 | `TreasureboxPointRewardRequest.aa84867e.lua` |
| 调用点数 | 1 |
调用点：`TreasureboxRankRewardPanel.1c97d0db.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `aData.id` | TreasureboxPointRewardRequest.aa84867e.lua:canon\request\TreasureboxPointRewardRequest.aa84867e6bd17b1483aaf413c7cf1451.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-getTreasureboxPointsInfo"></a>
#### `getTreasureboxPointsInfo` — TreasureboxPointsInfoGetRequest.lua

| 项 | 值 |
|---|---|
| 请求类 | `TreasureboxPointsInfoGetRequest` |
| 定义文件 | `TreasureboxPointsInfoGetRequest.8f973aa6.lua` |
| 调用点数 | 2 |
调用点：`Activity_TreasureboxRankLayer.46ddc1f5.lua`, `ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `treasureboxPointsRanks` | 1 |


<a id="ep-lockTreasure"></a>
#### `lockTreasure` — 宝物锁定

| 项 | 值 |
|---|---|
| 请求类 | `LockTreasuresRequest` |
| 定义文件 | `LockTreasuresRequest.95681669.lua` |
| 调用点数 | 1 |
调用点：`TreasureNewInfoPanel.b22b6a6a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `treasureId` | `self.parentView.Treasure.treasureId` | LockTreasuresRequest.95681669.lua:canon\features\treasureSystem\request\LockTreasuresRequest.956816692716831fbfd3882e1058941f.lua |
| `type` | `aTreasureData.lock and 2 or 1` | LockTreasuresRequest.95681669.lua:canon\features\treasureSystem\request\LockTreasuresRequest.956816692716831fbfd3882e1058941f.lua |


<a id="ep-potentialTreasure"></a>
#### `potentialTreasure` — 宝物激发

| 项 | 值 |
|---|---|
| 请求类 | `PotentialTreasureRequest` |
| 定义文件 | `PotentialTreasureRequest.c75bf378.lua` |
| 调用点数 | 1 |
调用点：`TreasureNewInfoPanel.b22b6a6a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `treasureId` | `self.parentView.Treasure.treasureId` | PotentialTreasureRequest.c75bf378.lua:canon\features\treasureSystem\request\PotentialTreasureRequest.c75bf378082134882e754f34e172ed0c.lua |
| `type` | `self.selectPotentialType` | PotentialTreasureRequest.c75bf378.lua:canon\features\treasureSystem\request\PotentialTreasureRequest.c75bf378082134882e754f34e172ed0c.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkTreasure` | 1 |


<a id="ep-resetTreasurePotential"></a>
#### `resetTreasurePotential` — 宝物重置潜力

| 项 | 值 |
|---|---|
| 请求类 | `ResetTreasurePotentialRequest` |
| 定义文件 | `ResetTreasurePotentialRequest.9625c198.lua` |
| 调用点数 | 1 |
调用点：`TreasureNewInfoPanel.b22b6a6a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `treasureId` | `self.parentView.Treasure.treasureId` | ResetTreasurePotentialRequest.9625c198.lua:canon\features\treasureSystem\request\ResetTreasurePotentialRequest.9625c1982396e89fc63d3bfebdb8533c.lua |


<a id="ep-sellTreasures"></a>
#### `sellTreasures` — 卖出宝物

| 项 | 值 |
|---|---|
| 请求类 | `SellTreasureRequest` |
| 定义文件 | `SellTreasureRequest.45a2c2b5.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `treasureIds` | `self.items.treasureData` | SellTreasureRequest.45a2c2b5.lua:canon\features\treasureSystem\request\SellTreasureRequest.45a2c2b536b06d9e6d9106f89b4be32a.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-setupTreasure"></a>
#### `setupTreasure` — 装备宝物 / 装备元神

| 项 | 值 |
|---|---|
| 请求类 | `SetupTreasureRequest` |
| 定义文件 | `SetupTreasureRequest.17a0fa3f.lua` |
| 调用点数 | 1 |
调用点：`TreasureBackpackScene.cd3f6cb8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `SELF.argv.params.cardId` | TreasureBackpackScene.cd3f6cb8.lua:1009 |
| `treasureId` | `SELF._data.treasureId` | TreasureBackpackScene.cd3f6cb8.lua:1009 |


<a id="ep-splitTreasure"></a>
#### `splitTreasure` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `SplitTreasureRequest` |
| 定义文件 | `SplitTreasureRequest.210e2c80.lua` |
| 调用点数 | 1 |
调用点：`CardRebirthScene.f580de62.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `treasureId` | `self.cardData.treasureId` | SplitTreasureRequest.210e2c80.lua:canon\features\treasureSystem\request\SplitTreasureRequest.210e2c80839cfca30684d9e788a535fd.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`reports`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-upgradeTreasure"></a>
#### `upgradeTreasure` — 宝物强化

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeTreasureRequest` |
| 定义文件 | `UpgradeTreasureRequest.cbdfea91.lua` |
| 调用点数 | 2 |
调用点：`TreasureNewInfoPanel.b22b6a6a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `oneClick` | `true` ・ `false` | UpgradeTreasureRequest.cbdfea91.lua:canon\features\treasureSystem\request\UpgradeTreasureRequest.cbdfea915195774e1e5400a0679075ee.lua |
| `treasureId` | `aScene.parentView.Treasure.treasureId` | UpgradeTreasureRequest.cbdfea91.lua:canon\features\treasureSystem\request\UpgradeTreasureRequest.cbdfea915195774e1e5400a0679075ee.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkTreasure` | 2 |


### 5.12 抽卡 / 合成

<a id="ep-gachaCard"></a>
#### `gachaCard`

| 项 | 值 |
|---|---|
| 请求类 | `GachaCardRequest` |
| 定义文件 | `GachaCardRequest.43682873.lua` |
| 调用点数 | 2 |
调用点：`GachaScene.fb4d302a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `gachaId` | `gachaType` | GachaScene.fb4d302a.lua:866 |
| `time` | `gachaTimes` | GachaScene.fb4d302a.lua:1446 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 16 |
| `free` | 4 |
| `countdownFreeGachaInfos` | 2 |


<a id="ep-gachaCardByBox"></a>
#### `gachaCardByBox` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `GachaCardByBoxRequest` |
| 定义文件 | `GachaCardByBoxRequest.a23aa1ad.lua` |
| 调用点数 | 1 |
调用点：`GachaScene.fb4d302a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gachaCardFree"></a>
#### `gachaCardFree`

| 项 | 值 |
|---|---|
| 请求类 | `GachaCardFreeRequest` |
| 定义文件 | `GachaCardFreeRequest.8e92bf3b.lua` |
| 调用点数 | 2 |
调用点：`GachaScene.fb4d302a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `gachaId` | `gachaType` | GachaScene.fb4d302a.lua:861 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 16 |
| `free` | 4 |
| `countdownFreeGachaInfos` | 2 |


<a id="ep-gainGachaPointsRewards"></a>
#### `gainGachaPointsRewards` — GainGachaPointsRewardsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainGachaPointsRewardsRequest` |
| 定义文件 | `GainGachaPointsRewardsRequest.7eae1e08.lua` |
| 调用点数 | 1 |
调用点：`Activity_GachaPointsLayer.51ddefb5.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-getGachaBroadcast"></a>
#### `getGachaBroadcast`

| 项 | 值 |
|---|---|
| 请求类 | `GetGachaBroadcastRequest` |
| 定义文件 | `GetGachaBroadcastRequest.8fe3cf56.lua` |
| 调用点数 | 3 |
调用点：`TreasureGachaScene.432faf6f.lua`, `DialogOnceScene.06d3213a.lua`, `GachaScene.fb4d302a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getGachaPointsInfo"></a>
#### `getGachaPointsInfo` — GetGachaPointsInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetGachaPointsInfoRequest` |
| 定义文件 | `GetGachaPointsInfoRequest.12547f11.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getSharkGachaBoxInfo"></a>
#### `getSharkGachaBoxInfo` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `GetSharkGachaBoxInfoRequest` |
| 定义文件 | `GetSharkGachaBoxInfoRequest.796c376c.lua` |
| 调用点数 | 1 |
调用点：`GachaScene.fb4d302a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gachaBoxCard` | 1 |


<a id="ep-refreshGachaBox"></a>
#### `refreshGachaBox` — 领取邀请好友奖励

| 项 | 值 |
|---|---|
| 请求类 | `RefreshGachaBoxRequest` |
| 定义文件 | `RefreshGachaBoxRequest.b5feccec.lua` |
| 调用点数 | 2 |
调用点：`GachaScene.fb4d302a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `refreshType` | `1` | GachaScene.fb4d302a.lua:602 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gachaBoxCard` | 2 |


<a id="ep-synthetizeCard"></a>
#### `synthetizeCard` — FragmentSynthetizeCardRequest 卡牌碎片合成

| 项 | 值 |
|---|---|
| 请求类 | `FragmentSynthetizeCardRequest` |
| 定义文件 | `FragmentSynthetizeCardRequest.bdc38382.lua` |
| 调用点数 | 1 |
调用点：`FragmentCardListPanel.260e81b0.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `metaId` | `aData.metaId` | FragmentCardListPanel.260e81b0.lua:460 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-synthetizeEquip"></a>
#### `synthetizeEquip` — FragmentSynthetizeEquipRequest 武器碎片合成

| 项 | 值 |
|---|---|
| 请求类 | `FragmentSynthetizeEquipRequest` |
| 定义文件 | `FragmentSynthetizeEquipRequest.b41c7e7b.lua` |
| 调用点数 | 1 |
调用点：`FragmentEquipListPanel.215b6645.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `metaId` | `aData.metaId` | FragmentEquipListPanel.215b6645.lua:408 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-synthetizeItem"></a>
#### `synthetizeItem`

| 项 | 值 |
|---|---|
| 请求类 | `SynthetizeItemRequest` |
| 定义文件 | `SynthetizeItemRequest.54040167.lua` |
| 调用点数 | 1 |
调用点：`CombineScene.2d6b77d5.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `formulaId` | `combineData.id` | CombineScene.2d6b77d5.lua:211 |


<a id="ep-upgradeCard"></a>
#### `upgradeCard` — 卡牌合成Request / 参数1：masterId / 参数2：slaveIds

| 项 | 值 |
|---|---|
| 请求类 | `CardComposeRequest` |
| 定义文件 | `CardComposeRequest.0044b922.lua` |
| 调用点数 | 2 |
调用点：`CardInfoNewPanel.6ac529d8.lua`, `CardComposeScene.8612aa78.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `masterId` | `self.parentView.cardId` ・ `masterId` | CardInfoNewPanel.6ac529d8.lua:424 |
| `slaveIds` | `slaveIds` | CardInfoNewPanel.6ac529d8.lua:424 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkCard` | 5 |
| `sharkCard.metaId` | 1 |


### 5.13 活动

<a id="ep-answerQuestion"></a>
#### `answerQuestion`

| 项 | 值 |
|---|---|
| 请求类 | `QuestionActAnswerRequest` |
| 定义文件 | `QuestionActAnswerRequest.308a5e12.lua` |
| 调用点数 | 1 |
调用点：`Activity_QuestionLayer.160a5d4c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `answer` | `self.answerKeyArr[evt.target.index]` | Activity_QuestionLayer.160a5d4c.lua:478 |
| `questionMetaId` | `self.currentQuestionId` | Activity_QuestionLayer.160a5d4c.lua:478 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `result` | 1 |
| `over` | 1 |
| `nextQuestionMetaId` | 1 |
| `wrongAnswer1Key` | 1 |
| `wrongAnswer2Key` | 1 |
| `wrongAnswer3Key` | 1 |


<a id="ep-challengeChrist"></a>
#### `challengeChrist` — MerryChristmasChallengeRequest.lua / luoyang.yi

| 项 | 值 |
|---|---|
| 请求类 | `MerryChristmasChallengeRequest` |
| 定义文件 | `MerryChristmasChallengeRequest.40ad6667.lua` |
| 调用点数 | 1 |
调用点：`MerryChristmasChallengePanel.075f3aa8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `christId` | `data.id` | MerryChristmasChallengePanel.075f3aa8.lua:410 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `bigReward` | 5 |
| `win` | 3 |
| `chapterFinishReward` | 1 |
| `dialogId` | 1 |
| `retCode` | 1 |


<a id="ep-challengeCowStage"></a>
#### `challengeCowStage` — ActivityCowStageRequest.lua - 牧场大战活动相关请求 / 挑战牧场

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeCowStageRequest` |
| 定义文件 | `ActivityCowStageRequest.1d62e730.lua` |
| 调用点数 | 1 |
调用点：`Activity_CowstageLayer.a78d739e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cowStageId` | `MetaManager.cow_stage[evt.context].id` | Activity_CowstageLayer.a78d739e.lua:198 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `win` | 1 |
| `selectId` | 1 |


<a id="ep-challengeMysterious"></a>
#### `challengeMysterious` — request / /request / response

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeMysteriousRequest` |
| 定义文件 | `challengeMysteriousRequest.d3e3c682.lua` |
| 调用点数 | 1 |
调用点：`MesteriousChanllengePanel.08653aaf.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `difficultyDegree` | `MesteriousManager.getDefaultDiffculty()` | challengeMysteriousRequest.d3e3c682.lua:canon\features\mesterious\request\challengeMysteriousRequest.d3e3c682c8ade7bfaaed91ff1bd72d99.lua |
| `id` | `chooseCountry` | challengeMysteriousRequest.d3e3c682.lua:canon\features\mesterious\request\challengeMysteriousRequest.d3e3c682c8ade7bfaaed91ff1bd72d99.lua |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-changeDiceLuck"></a>
#### `changeDiceLuck` — DiceChangeLuckRequest

| 项 | 值 |
|---|---|
| 请求类 | `DiceChangeLuckRequest` |
| 定义文件 | `DiceChangeLuckRequest.8cc0e71a.lua` |
| 调用点数 | 1 |
调用点：`ActivitySilverDiceLayer_POP.613ecc7a.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gainedCoin` | 1 |
| `diceNewRewards` | 1 |
| `throwDiceCount` | 1 |
| `changeDiceLuckCount` | 1 |
| `changeLuckCountPerThrow` | 1 |


<a id="ep-chargeBalloon"></a>
#### `chargeBalloon`

| 项 | 值 |
|---|---|
| 请求类 | `BlowBalloonActGetEnegyRequest` |
| 定义文件 | `BlowBalloonActGetEnegyRequest.7542b7d1.lua` |
| 调用点数 | 1 |
调用点：`Activity_BlowBalloonLayer.011188e8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `ensureSuccess` | `self.CheckBoxSelected` | Activity_BlowBalloonLayer.011188e8.lua:254 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `currPoint` | 2 |


<a id="ep-defaultPhoneNum"></a>
#### `defaultPhoneNum` — 修改/设定玩家手机号码

| 项 | 值 |
|---|---|
| 请求类 | `PhoneChargeSetNumRequest` |
| 定义文件 | `PhoneChargeSetNumRequest.9c3408a6.lua` |
| 调用点数 | 2 |
调用点：`PhoneChargeBindPopPanel.902307b4.lua`, `PhoneChargeChangePhoneNumberPopPanel.69d6be0e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `phoneNum` | `selectedText` | PhoneChargeSetNumRequest.9c3408a6.lua:canon\request\PhoneChargeSetNumRequest.9c3408a6d12eebf770b9bf087fb6e073.lua |


<a id="ep-distributeBonus"></a>
#### `distributeBonus` — 分配红包，区分好友和军团

| 项 | 值 |
|---|---|
| 请求类 | `DistributeBonusRequest` |
| 定义文件 | `DistributeBonusRequest.6fe52257.lua` |
| 调用点数 | 1 |
调用点：`RedPacketDispatchScene.f1724041.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `accepterList` | `{}` ・ `= 0 then` | RedPacketDispatchScene.f1724041.lua:360 |
| `accepterType` | `self.selectID - 1` | RedPacketDispatchScene.f1724041.lua:360 |
| `bonusId` | `self.bonusId` | RedPacketDispatchScene.f1724041.lua:360 |


<a id="ep-eatPeach"></a>
#### `eatPeach` — ActivityEatPeachRequest.lua - 吃桃补充体力活动相关请求

| 项 | 值 |
|---|---|
| 请求类 | `EatPeachRequest` |
| 定义文件 | `ActivityEatPeachRequest.2b404187.lua` |
| 调用点数 | 1 |
调用点：`Activity_EatPeachLayer.2be8c9eb.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `featureName` | `self.eatWhichPeach` | Activity_EatPeachLayer.2be8c9eb.lua:168 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gainedEnergy` | 2 |


<a id="ep-gainBalloonPoint"></a>
#### `gainBalloonPoint`

| 项 | 值 |
|---|---|
| 请求类 | `BlowBalloonActGainMagicValueRequest` |
| 定义文件 | `BlowBalloonActGainMagicValueRequest.83e7674f.lua` |
| 调用点数 | 1 |
调用点：`Activity_BlowBalloonLayer.011188e8.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `currPoint` | 2 |


<a id="ep-gainLimitReward"></a>
#### `gainLimitReward` — ActiveRechangeRequest.lua / 2014-1-19 / meilan.xie / request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `ActiveRechangeRequest` |
| 定义文件 | `ActiveRechangeRequest.271668d3.lua` |
| 调用点数 | 1 |
调用点：`Activity_rechargeLayer.9cd8a922.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `stepId` | `Id` | ActiveRechangeRequest.271668d3.lua:canon\request\ActiveRechangeRequest.271668d3b873d2e20803cb4cf0792686.lua |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getAccumulateGems"></a>
#### `getAccumulateGems` — GetAccumulateGemsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetAccumulateGemsRequest` |
| 定义文件 | `GetAccumulateGemsRequest.a1c81f1e.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `accumulateGems` | 1 |


<a id="ep-getAccumulateRechargeInfo"></a>
#### `getAccumulateRechargeInfo`

| 项 | 值 |
|---|---|
| 请求类 | `GetRechargeInfoRequest` |
| 定义文件 | `GetRechargeInfoRequest.6e337b24.lua` |
| 调用点数 | 2 |
调用点：`Activity_DailyFirstChargeLayer.ec9feca4.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `remainingDays` | 2 |
| `rewards` | 2 |


<a id="ep-getActivityBalloonInfo"></a>
#### `getActivityBalloonInfo`

| 项 | 值 |
|---|---|
| 请求类 | `BlowBalloonActInfoRequest` |
| 定义文件 | `BlowBalloonActInfoRequest.06e8dd36.lua` |
| 调用点数 | 5 |
调用点：`Activity_BlowBalloonLayer.011188e8.lua`, `BlowBalloonMagicRewardPanel.b48bb4a7.lua`, `BlowBalloonRankInfoPanel.9239d3d9.lua`, `BlowBalloonRankPanel.93d441a2.lua`, `ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `balloonRanks` | 4 |
| `currPoint` | 2 |


<a id="ep-getBonusAccepterList"></a>
#### `getBonusAccepterList` — 分配红包，区分好友和军团

| 项 | 值 |
|---|---|
| 请求类 | `GetBonusAccepterListRequest` |
| 定义文件 | `GetBonusAccepterListRequest.dd0d6395.lua` |
| 调用点数 | 2 |
调用点：`UsePropRequest.46c7f25f.lua`, `RedPacketDispatchScene.f1724041.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `bonusId` | `MetaManager.prop_meta[selectData.metaId].id` ・ `self.bonusId` | UsePropRequest.46c7f25f.lua:150 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `friendList` | 1 |
| `unionList` | 1 |


<a id="ep-getDailyRecharge"></a>
#### `getDailyRecharge` — 获得充值活动最新状态接口

| 项 | 值 |
|---|---|
| 请求类 | `PhoneChargeGetInfoRequest` |
| 定义文件 | `PhoneChargeGetInfoRequest.77bd3dc8.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `dailyRecharge` | 1 |


<a id="ep-getGemConsumeInfo"></a>
#### `getGemConsumeInfo`

| 项 | 值 |
|---|---|
| 请求类 | `GetGemConsumeInfoRequest` |
| 定义文件 | `ActivityGemConsumeRequest.b73f4b38.lua` |
| 调用点数 | 1 |
调用点：`Activity_GemConsumeRewardsLayer.6c13c7f4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardId` | `gemConsumeMeta[evt.context].id` | Activity_GemConsumeRewardsLayer.6c13c7f4.lua:178 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gainedRewards` | 2 |
| `consumeGems` | 1 |


<a id="ep-getLevelRaceInfo"></a>
#### `getLevelRaceInfo` — GetLevelRaceInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetLevelRaceInfoRequest` |
| 定义文件 | `GetLevelRaceInfoRequest.a9fc2705.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `levelRaceRanks` | 1 |


<a id="ep-getMaintenanceMeta"></a>
#### `getMaintenanceMeta` — GetActivityOnOffConfigRequest.lua - 得到活动配置请求

| 项 | 值 |
|---|---|
| 请求类 | `GetActivityOnOffConfigRequest` |
| 定义文件 | `GetActivityOnOffConfigRequest.831dd4c7.lua` |
| 调用点数 | 2 |
调用点：`CreateCharacterScene.728208fe.lua`, `LoginScene.9fbb94e7.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `maintenanceItem` | 2 |


<a id="ep-getQuestionInfo"></a>
#### `getQuestionInfo`

| 项 | 值 |
|---|---|
| 请求类 | `QuestionActGetStateRequest` |
| 定义文件 | `QuestionActGetStateRequest.26bec18f.lua` |
| 调用点数 | 1 |
调用点：`Activity_QuestionLayer.160a5d4c.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `questionNum` | 1 |
| `dailyNum` | 1 |
| `questionId` | 1 |
| `wrongAnswer1Key` | 1 |
| `wrongAnswer2Key` | 1 |
| `wrongAnswer3Key` | 1 |


<a id="ep-rechargeCalls"></a>
#### `rechargeCalls` — 送话费活动 获取话费

| 项 | 值 |
|---|---|
| 请求类 | `PhoneChargeGainRequest` |
| 定义文件 | `PhoneChargeGainRequest.bada54a7.lua` |
| 调用点数 | 2 |
调用点：`PhoneChargeGainByNumPopPanel.b19d6ace.lua`, `PhoneChargeGainPopPanel.e87cd229.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `callsType` | `1` | PhoneChargeGainRequest.bada54a7.lua:canon\request\PhoneChargeGainRequest.bada54a7bbeb1ce1a2ec315c171e0d00.lua |
| `phoneNum` | `selectedText` ・ `Activity_PhoneChargeLayer.getBindPhoneNumber()` | PhoneChargeGainRequest.bada54a7.lua:canon\request\PhoneChargeGainRequest.bada54a7bbeb1ce1a2ec315c171e0d00.lua |


<a id="ep-recordActivityFbShare"></a>
#### `recordActivityFbShare` — Facebook相关

| 项 | 值 |
|---|---|
| 请求类 | `ShareFacebookActivityeRequest` |
| 定义文件 | `FacebookActivityRequest.fe356c3f.lua` |
| 调用点数 | 1 |
调用点：`Activity_FacebookShareLayer.0f401528.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-recordGameFbShare"></a>
#### `recordGameFbShare` — Facebook相关

| 项 | 值 |
|---|---|
| 请求类 | `FacebookRecordTriggerShareRequest` |
| 定义文件 | `FacebookActivityRequest.fe356c3f.lua` |
| 调用点数 | 1 |
调用点：`FacebookShareTriggerPanel.1b7de140.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `shareId` | `self.shareId` | FacebookShareTriggerPanel.1b7de140.lua:89 |
| `shareSuccess` | `shareSuccess` | FacebookShareTriggerPanel.1b7de140.lua:89 |


<a id="ep-resetChrist"></a>
#### `resetChrist` — MerryChristmasResetRequest.lua / zhehua.ou

| 项 | 值 |
|---|---|
| 请求类 | `MerryChristmasResetRequest` |
| 定义文件 | `MerryChristmasResetRequest.79b6f963.lua` |
| 调用点数 | 1 |
调用点：`MerryChristmasChallengePanel.075f3aa8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `christId` | `data.id` | MerryChristmasChallengePanel.075f3aa8.lua:450 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `retCode` | 1 |


<a id="ep-setoffFireworks"></a>
#### `setoffFireworks` — FireworksFireRequest.lua - 向玩家发送免费礼物

| 项 | 值 |
|---|---|
| 请求类 | `FireworksFireRequest` |
| 定义文件 | `FireworksFireRequest.c62a1676.lua` |
| 调用点数 | 1 |
调用点：`Activity_FireworksLayer.92af8fa4.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-throwDice"></a>
#### `throwDice` — DiceRollRequest

| 项 | 值 |
|---|---|
| 请求类 | `DiceRollRequest` |
| 定义文件 | `DiceRollRequest.f2fd37c8.lua` |
| 调用点数 | 1 |
调用点：`Activity_SilverDiceLayer.61f8a2c2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `diceStates` | 1 |
| `coins` | 1 |
| `throwDiceCount` | 1 |
| `changeDiceLuckCount` | 1 |
| `changeLuckCountPerThrow` | 1 |


<a id="ep-wishing"></a>
#### `wishing` — 许愿池许愿接口 / 接口定义 后端提供

| 项 | 值 |
|---|---|
| 请求类 | `FountainWishRequest` |
| 定义文件 | `FountainWishRequest.53e99de3.lua` |
| 调用点数 | 1 |
调用点：`Activity_FountainLayer.612ffc4d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `multiple` | 3 |
| `coins` | 2 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


### 5.14 登录 / 账号 / 连接

<a id="ep-bindAccount"></a>
#### `bindAccount`

| 项 | 值 |
|---|---|
| 请求类 | `BindAccountRequest` |
| 定义文件 | `LoginServerRequest.3825a728.lua` |
| 调用点数 | 1 |
调用点：`ThirdPlatformLogin.c4321326.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `platformId` | `getPlatFormId()` | ThirdPlatformLogin.c4321326.lua:516 |
| `platformUid` | `getPlatformUid()` | ThirdPlatformLogin.c4321326.lua:516 |
| `sid` | `getPlatformSid()` | ThirdPlatformLogin.c4321326.lua:516 |


<a id="ep-createUser"></a>
#### `createUser`

| 项 | 值 |
|---|---|
| 请求类 | `CreateUserRequest` |
| 定义文件 | `CreateUserRequest.2df91423.lua` |
| 调用点数 | 1 |
调用点：`CreateCharacterScene.728208fe.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `avatarId` | `1` | CreateCharacterScene.728208fe.lua:309 |
| `inviteCode` | `""` | CreateCharacterScene.728208fe.lua:309 |
| `nickName` | `strNickName` | CreateCharacterScene.728208fe.lua:309 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkUser` | 2 |
| `sharkUser.uid` | 1 |
| `sharkUser.serverId` | 1 |


<a id="ep-geneNickname"></a>
#### `geneNickname` — GeneNicknameRequest.lua - 获取好友的详情

| 项 | 值 |
|---|---|
| 请求类 | `GeneNicknameRequest` |
| 定义文件 | `GeneNicknameRequest.23dd5c01.lua` |
| 调用点数 | 1 |
调用点：`CreateCharacterScene.728208fe.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `nickname` | 1 |


<a id="ep-getServerStatus"></a>
#### `getServerStatus`

| 项 | 值 |
|---|---|
| 请求类 | `GetServerStatusRequest` |
| 定义文件 | `GetServerStatusRequest.82e51a66.lua` |
| 调用点数 | 1 |
调用点：`MainApplication.e63b9818.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getServerTimeStamp"></a>
#### `getServerTimeStamp`

| 项 | 值 |
|---|---|
| 请求类 | `GetServerTimeStampRequest` |
| 定义文件 | `LoginServerRequest.3825a728.lua` |
| 调用点数 | 1 |
调用点：`LoginScene.9fbb94e7.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getSocketServer"></a>
#### `getSocketServer` — GetSocketServerRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetSocketServerRequest` |
| 定义文件 | `GetSocketServerRequest.5b24d380.lua` |
| 调用点数 | 1 |
调用点：`TCPManager.8977dcac.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `serverAddress` | 1 |
| `serverPort` | 1 |
| `token` | 1 |


<a id="ep-loginServer"></a>
#### `loginServer`

| 项 | 值 |
|---|---|
| 请求类 | `LoginServerRequest` |
| 定义文件 | `LoginServerRequest.3825a728.lua` |
| 调用点数 | 2 |
调用点：`MainApplication.e63b9818.lua`, `LoginScene.9fbb94e7.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `accountId` | `getAccountId()` | LoginScene.9fbb94e7.lua:400 |
| `serverId` | `serverId` | LoginScene.9fbb94e7.lua:400 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `uid` | 2 |
| `accountReturnRewards` | 1 |


<a id="ep-searchUserByNickname"></a>
#### `searchUserByNickname` — SearchUserByNicknameRequest.lua - 据昵称查找用户

| 项 | 值 |
|---|---|
| 请求类 | `SearchUserByNicknameRequest` |
| 定义文件 | `SearchUserByNicknameRequest.d058bd26.lua` |
| 调用点数 | 2 |
调用点：`FindFriendsPanel.4fa3f8f2.lua`, `UnionMemberListPanel.10242232.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `nickName` | `nickName` ・ `aData.nickName` | FindFriendsPanel.4fa3f8f2.lua:554 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkFriendDetail` | 4 |
| `friendUid` | 1 |
| `sharkFriendDetail.friend` | 1 |
| `sharkFriendDetail.invitationSent` | 1 |


### 5.15 矩阵

<a id="ep-replaceMatrixGrid"></a>
#### `replaceMatrixGrid`

| 项 | 值 |
|---|---|
| 请求类 | `ReplaceMatrixGridRequest` |
| 定义文件 | `ReplaceMatrixGridRequest.004fcb77.lua` |
| 调用点数 | 1 |
调用点：`BackpackScene.9b0694aa.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `cardData.cardId` | BackpackScene.9b0694aa.lua:2237 |
| `matrixId` | `SELF.argv.params.matrixId` | BackpackScene.9b0694aa.lua:2237 |
| `posId` | `SELF.argv.params.posId` | BackpackScene.9b0694aa.lua:2237 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `type` | 1 |


<a id="ep-upgradeMatrix"></a>
#### `upgradeMatrix`

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeMatrixRequest` |
| 定义文件 | `UpgradeMatrixRequest.5af8e9af.lua` |
| 调用点数 | 1 |
调用点：`MatrixUpgradePanel.475f1ab4.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `matrixId` | `self.matrixInfo.matrixId` | MatrixUpgradePanel.475f1ab4.lua:152 |


### 5.16 竞技场 / PK

<a id="ep-challengeArena"></a>
#### `challengeArena` — ChallengeArenaRequest

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeArenaRequest` |
| 定义文件 | `ChallengeArenaRequest.b2a0bb87.lua` |
| 调用点数 | 3 |
调用点：`ArenaFoePanel.362a1614.lua`, `ArenaRankScene.22570f79.lua`, `ArenaReportScene.e61bb6a9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `matchedUid` | `ArenaManager:sharedManager().arenaPersonalFoes.foes[aIndex].uid` ・ `args.matchedUid` ・ `aUid` | ArenaFoePanel.362a1614.lua:175 |
| `revenge` | `true` ・ `args.revenge` | ArenaFoePanel.362a1614.lua:175 |


<a id="ep-challengeContend"></a>
#### `challengeContend` — ChallengeContendRequest

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeContendRequest` |
| 定义文件 | `ChallengeContendRequest.96a04851.lua` |
| 调用点数 | 1 |
调用点：`Activity_ContendLayer.1aaebd85.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `contendId` | `aContendId` | Activity_ContendLayer.1aaebd85.lua:243 |


<a id="ep-challengeCrossUser"></a>
#### `challengeCrossUser` — 挑战

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeCrossUserRequest` |
| 定义文件 | `ChallengeCrossUserRequest.91796ba9.lua` |
| 调用点数 | 1 |
调用点：`CrossArenaChanllengeLayer.c7c48abc.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `index` | `evt.context-1` | CrossArenaChanllengeLayer.c7c48abc.lua:156 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `matchList` | 1 |


<a id="ep-challengePkUser"></a>
#### `challengePkUser` — PKChallengePkUserRequest.lua - 比武请求挑战

| 项 | 值 |
|---|---|
| 请求类 | `PKChallengePkUserRequest` |
| 定义文件 | `PKChallengePkUserRequest.ae2eef79.lua` |
| 调用点数 | 1 |
调用点：`PKScene.1ca50cd2.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `opponentUid` | `uid` | PKScene.1ca50cd2.lua:1157 |
| `type` | `revenge and 1 or 0` | PKScene.1ca50cd2.lua:1157 |


<a id="ep-destinyBattle"></a>
#### `destinyBattle`

| 项 | 值 |
|---|---|
| 请求类 | `DestinyBattleRequest` |
| 定义文件 | `DestinyBattleRequest.b5aedea7.lua` |
| 调用点数 | 1 |
调用点：`DestinyFightChallengeScene.d711a49a.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `getDestinyFightCardId()` | DestinyFightChallengeScene.d711a49a.lua:223 |
| `destinyBattleId` | `destinyData.destinyBattle` | DestinyFightChallengeScene.d711a49a.lua:223 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `monsterGroupId` | 1 |
| `isBossBattle` | 1 |


<a id="ep-gainArenaScoreByRank"></a>
#### `gainArenaScoreByRank` — GainArenaScoreByRankRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainArenaScoreByRankRequest` |
| 定义文件 | `GainArenaScoreByRankRequest.ea9f0cb0.lua` |
| 调用点数 | 4 |
调用点：`BattleResultPanel.5b63b566.lua`, `UserLevelupBox.3ae9c559.lua`, `BaseUIScene.0cb7c1e5.lua`, `BattleScene.07008061.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 8 |
| `reward.amount` | 4 |


<a id="ep-gainPkBuff"></a>
#### `gainPkBuff` — PKGainPkBuffRequest.lua - 比武请求武神祝福

| 项 | 值 |
|---|---|
| 请求类 | `PKGainPkBuffRequest` |
| 定义文件 | `PKGainPkBuffRequest.a7f1d92a.lua` |
| 调用点数 | 1 |
调用点：`PKScene.1ca50cd2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-gainPkRewards"></a>
#### `gainPkRewards` — PKGainPkRewardsRequest.lua - 比武请求领奖

| 项 | 值 |
|---|---|
| 请求类 | `PKGainPkRewardsRequest` |
| 定义文件 | `PKGainPkRewardsRequest.ca90e5ff.lua` |
| 调用点数 | 1 |
调用点：`PKScene.1ca50cd2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


<a id="ep-getArenaMatchedPlayers"></a>
#### `getArenaMatchedPlayers` — GetArenaMatchedPlayersRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetArenaMatchedPlayersRequest` |
| 定义文件 | `GetArenaMatchedPlayersRequest.c4f729e1.lua` |
| 调用点数 | 4 |
调用点：`BattleResultPanel.5b63b566.lua`, `UserLevelupBox.3ae9c559.lua`, `BaseUIScene.0cb7c1e5.lua`, `BattleScene.07008061.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 8 |
| `reward.amount` | 4 |
| `retCode` | 4 |


<a id="ep-getDestinyInfo"></a>
#### `getDestinyInfo`

| 项 | 值 |
|---|---|
| 请求类 | `GetDestinyInfoRequest` |
| 定义文件 | `GetDestinyInfoRequest.ebb7819f.lua` |
| 调用点数 | 2 |
调用点：`DestinyFightChallengeScene.d711a49a.lua`, `KingTempleScene.f2b46794.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `ignoreAction` | `false` | DestinyFightChallengeScene.d711a49a.lua:138 |


<a id="ep-getPkFoes"></a>
#### `getPkFoes` — PKGetPkFoesRequest.lua - 比武请求仇人列表

| 项 | 值 |
|---|---|
| 请求类 | `PKGetPkFoesRequest` |
| 定义文件 | `PKGetPkFoesRequest.1c0bdda4.lua` |
| 调用点数 | 2 |
调用点：`PKScene.1ca50cd2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `pkUserInfos` | 2 |


<a id="ep-getPkInfo"></a>
#### `getPkInfo` — PKGetPKInfoRequest.lua - 比武请求基础信息

| 项 | 值 |
|---|---|
| 请求类 | `PKGetPKInfoRequest` |
| 定义文件 | `PKGetPKInfoRequest.a37195cf.lua` |
| 调用点数 | 1 |
调用点：`PKScene.1ca50cd2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getPkTopRankUsers"></a>
#### `getPkTopRankUsers` — PKGetPkTopRankUsersRequest.lua - 比武请求排名信息

| 项 | 值 |
|---|---|
| 请求类 | `PKGetPkTopRankUsersRequest` |
| 定义文件 | `PKGetPkTopRankUsersRequest.e5760720.lua` |
| 调用点数 | 1 |
调用点：`PKScene.1ca50cd2.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `pkUserInfos` | 1 |


<a id="ep-refreshMatch"></a>
#### `refreshMatch` — 刷新对手

| 项 | 值 |
|---|---|
| 请求类 | `RefreshMatchRequest` |
| 定义文件 | `RefreshMatchRequest.e1381115.lua` |
| 调用点数 | 1 |
调用点：`CrossArenaChanllengeLayer.c7c48abc.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `self.refreshType` | CrossArenaChanllengeLayer.c7c48abc.lua:222 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `matchList` | 1 |


### 5.17 装备

<a id="ep-getEquips"></a>
#### `getEquips` — 获取装备

| 项 | 值 |
|---|---|
| 请求类 | `GetEquipsRequest` |
| 定义文件 | `GetEquipsRequest.2935cfff.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-quickUpgradeEquip"></a>
#### `quickUpgradeEquip` — QuickUpgradeEquipRequest

| 项 | 值 |
|---|---|
| 请求类 | `QuickUpgradeEquipRequest` |
| 定义文件 | `QuickUpgradeEquipRequest.3a39a8d9.lua` |
| 调用点数 | 1 |
调用点：`EquipUpgradeScene.531bdf0b.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `equipId` | `aScene.equip.equipId` | EquipUpgradeScene.531bdf0b.lua:170 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkEquip` | 1 |
| `equipId` | 1 |


<a id="ep-sellEquips"></a>
#### `sellEquips` — SellEquipsRequest.lua - 出售装备的请求

| 项 | 值 |
|---|---|
| 请求类 | `SellEquipsRequest` |
| 定义文件 | `SellEquipsRequest.80af692d.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `equipIds` | `items` | ItemSellMessageBoxPanel.7afb89c9.lua:268 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-setupEquip"></a>
#### `setupEquip` — SetupEquipRequest.lua - 更换装备的请求

| 项 | 值 |
|---|---|
| 请求类 | `SetupEquipRequest` |
| 定义文件 | `SetupEquipRequest.9e10b307.lua` |
| 调用点数 | 1 |
调用点：`BackpackScene.9b0694aa.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `cardId` | `SELF.argv.params.cardId` | BackpackScene.9b0694aa.lua:3386 |
| `equipId` | `SELF._data.equipId` | BackpackScene.9b0694aa.lua:3386 |


<a id="ep-upgradeEquip"></a>
#### `upgradeEquip` — UpgradeEquipRequest

| 项 | 值 |
|---|---|
| 请求类 | `UpgradeEquipRequest` |
| 定义文件 | `UpgradeEquipRequest.79639e22.lua` |
| 调用点数 | 1 |
调用点：`EquipUpgradeScene.531bdf0b.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `equipId` | `aScene.equip.equipId` | EquipUpgradeScene.531bdf0b.lua:93 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkEquip` | 1 |
| `equipId` | 1 |


### 5.18 装备附灵

<a id="ep-equipEnchant"></a>
#### `equipEnchant` — 附灵接口

| 项 | 值 |
|---|---|
| 请求类 | `EnchantUpgradeRequest` |
| 定义文件 | `EnchantUpgradeRequest.2f528881.lua` |
| 调用点数 | 1 |
调用点：`EnchantScene.49885a7f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `equipId` | `self.equipData.equipId` | EnchantUpgradeRequest.2f528881.lua:canon\features\enchant\request\EnchantUpgradeRequest.2f52888139568fcf4a54851d72ba1dbc.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `sharkEquip` | 4 |
| `sharkEquip.enchantLevel` | 1 |
| `sharkEquip.enchantNum` | 1 |
| `sharkEquip.cardId` | 1 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getEnchantStepReward"></a>
#### `getEnchantStepReward` — 附灵引导奖励接口

| 项 | 值 |
|---|---|
| 请求类 | `GetEnchantStepRewardRequest` |
| 定义文件 | `GetEnchantStepRewardRequest.7ec01e80.lua` |
| 调用点数 | 1 |
调用点：`EnchantGuideRewardPanel.c08da954.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


### 5.19 跨服

<a id="ep-buyCrossPvpChallengeTime"></a>
#### `buyCrossPvpChallengeTime` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `BuyCrossPvpChallengeTimeRequest` |
| 定义文件 | `BuyCrossPvpChallengeTimeRequest.3bc93bf2.lua` |
| 调用点数 | 1 |
调用点：`CrossArenaChanllengeLayer.c7c48abc.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `matchList` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`reports`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-challengeCrossBoss"></a>
#### `challengeCrossBoss` — 获取世界boss信息

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeCrossBossRequest` |
| 定义文件 | `ChallengeCrossBossRequest.06a920e2.lua` |
| 调用点数 | 1 |
调用点：`Activity_CrossMultiplayerBossLayer.b09bc644.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `bossType` | `self.bossType` | Activity_CrossMultiplayerBossLayer.b09bc644.lua:821 |
| `type` | `self.challengeType` | Activity_CrossMultiplayerBossLayer.b09bc644.lua:821 |


<a id="ep-crossGvgCanMindApply"></a>
#### `crossGvgCanMindApply` — 跨服GvG  军团界面弹框请求

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkcrossGvgCanMindApplyRequest` |
| 定义文件 | `CrossUnionPkcrossGvgCanMindApplyRequest.16183b33.lua` |
| 调用点数 | 1 |
调用点：`UnionScene.f27a33ee.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `applyCrossGvgRemind` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`applyCrossGvgRemind`


<a id="ep-exchangeGvgFormation"></a>
#### `exchangeGvgFormation` — request / /request / response / /response

| 项 | 值 |
|---|---|
| 请求类 | `ExchangeGvgFormationRequest` |
| 定义文件 | `ExchangeGvgFormationRequest.e50e16c2.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPkUpdatePanel.126d28bd.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-gainCrossBossReward"></a>
#### `gainCrossBossReward` — 领取奖励

| 项 | 值 |
|---|---|
| 请求类 | `GainCrossBossRewardRequest` |
| 定义文件 | `GainCrossBossRewardRequest.e119823f.lua` |
| 调用点数 | 1 |
调用点：`Activity_CrossMultiplayerBossLayer.b09bc644.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-gainCrossGachaPointReward"></a>
#### `gainCrossGachaPointReward` — 跨服Gacha 小玉嫁到 相关 / 获取活动信息

| 项 | 值 |
|---|---|
| 请求类 | `CrossGachaGainPointRewardRequest` |
| 定义文件 | `CrossGachaXiaoyuRequest.bd08f56e.lua` |
| 调用点数 | 1 |
调用点：`GachaXiaoyuPointsRankRewardPanel.8dfb7f55.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `aData.id` | CrossGachaXiaoyuRequest.bd08f56e.lua:canon\request\CrossGachaXiaoyuRequest.bd08f56ef4808714d8ba5891f4ef3644.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainCrossGachaRankAndMysteriousReward"></a>
#### `gainCrossGachaRankAndMysteriousReward` — 跨服Gacha 小玉嫁到 相关 / 获取活动信息

| 项 | 值 |
|---|---|
| 请求类 | `CrossGachaGainRankRewardRequest` |
| 定义文件 | `CrossGachaXiaoyuRequest.bd08f56e.lua` |
| 调用点数 | 1 |
调用点：`Activity_GachaXiaoyuLayer.da946792.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `mysteriousRewards` | 3 |
| `rankRewards` | 2 |


<a id="ep-gainCrossPkGuessReward"></a>
#### `gainCrossPkGuessReward` — GainCrossPkGuessRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainCrossPkGuessRewardRequest` |
| 定义文件 | `GainCrossPkGuessRewardRequest.2d6a1e74.lua` |
| 调用点数 | 1 |
调用点：`AcrossRewardPanel.83b5d31d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainCrossPkRankReward"></a>
#### `gainCrossPkRankReward` — GainCrossPkRankRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainCrossPkRankRewardRequest` |
| 定义文件 | `GainCrossPkRankRewardRequest.d519946a.lua` |
| 调用点数 | 1 |
调用点：`AcrossRewardPanel.83b5d31d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainCrossPkServerReward"></a>
#### `gainCrossPkServerReward` — GainCrossPkServerRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainCrossPkServerRewardRequest` |
| 定义文件 | `GainCrossPkServerRewardRequest.1ab4f3ae.lua` |
| 调用点数 | 1 |
调用点：`AcrossRewardPanel.83b5d31d.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainCrossPvpActiveReward"></a>
#### `gainCrossPvpActiveReward`

| 项 | 值 |
|---|---|
| 请求类 | `CrossPvpActiveRewardRequest` |
| 定义文件 | `CrossPvpActiveRewardRequest.ac0245bc.lua` |
| 调用点数 | 1 |
调用点：`CrossArenaScoreLayer.8330d291.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `activeId` | `activeId` | CrossPvpActiveRewardRequest.ac0245bc.lua:canon\features\crossArena\request\CrossPvpActiveRewardRequest.ac0245bcb5df218b4c1fea6c6a557e8b.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`rewards`


<a id="ep-gainCrossPvpBattleReward"></a>
#### `gainCrossPvpBattleReward` — 领取跨服pvp奖励

| 项 | 值 |
|---|---|
| 请求类 | `CrossPvpGainBattleRewardRequest` |
| 定义文件 | `CrossPvpGainBattleRewardRequest.12e5c325.lua` |
| 调用点数 | 2 |
调用点：`CrossArenaRewardLayer.05d304bc.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `CrossArenaConsts.REWARD_TYPE_RANK` ・ `CrossArenaConsts.REWARD_TYPE_SERVER` | CrossPvpGainBattleRewardRequest.12e5c325.lua:canon\features\crossArena\request\CrossPvpGainBattleRewardRequest.12e5c3251b4dfdd80ac70a4be3510f47.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`rewards`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossBossInfo"></a>
#### `getCrossBossInfo` — 获取世界boss信息

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossBossInfoRequest` |
| 定义文件 | `GetCrossBossInfoRequest.0a6d2771.lua` |
| 调用点数 | 3 |
调用点：`Activity_CrossMultiplayerBossLayer.b09bc644.lua`, `ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getCrossBossRankInfo"></a>
#### `getCrossBossRankInfo` — 领取奖励

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossBossRankInfoRequest` |
| 定义文件 | `GetCrossBossRankInfoRequest.1b57cf9b.lua` |
| 调用点数 | 1 |
调用点：`Activity_CrossMultiplayerBossLayer.b09bc644.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getCrossGachaInfo"></a>
#### `getCrossGachaInfo` — 跨服Gacha 小玉嫁到 相关 / 获取活动信息

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossGachaInfoRequest` |
| 定义文件 | `CrossGachaXiaoyuRequest.bd08f56e.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-getCrossGvgGroupInfo"></a>
#### `getCrossGvgGroupInfo` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossGvgGroupInfoRequest` |
| 定义文件 | `GetCrossGvgGroupInfoRequest.6b3a365e.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPk.ba058536.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossGvgInfo"></a>
#### `getCrossGvgInfo` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossGvgInfoRequest` |
| 定义文件 | `GetCrossGvgInfoRequest.d980ae99.lua` |
| 调用点数 | 3 |
调用点：`CrossUnionPk.ba058536.lua`, `CrossUnionPKTeamAdjustScene.a1da1acc.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `coinInspireNum` | 2 |
| `striveInspireNum` | 2 |
| `signs` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`coinInspireNum`, `gemInspireNum`, `signs`, `striveInspireNum`, `version`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossGvgInfoBase"></a>
#### `getCrossGvgInfoBase` — 跨服GvG  获取淘汰信息

| 项 | 值 |
|---|---|
| 请求类 | `CrossUnionPkGetCrossGvgInfoBaseRequest` |
| 定义文件 | `CrossUnionPkGetCrossGvgInfoBaseRequest.c3585bab.lua` |
| 调用点数 | 2 |
调用点：`CrossUnionPk.ba058536.lua`, `CrossUnionPKLoginScene.912ba2bf.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `unionApplyCrossGvg` | 2 |
| `selfApplyCrossGvg` | 2 |
| `crossGvgVersion` | 2 |
| `selfQuitCrossGvg` | 1 |
| `groupId` | 1 |
| `out` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`groupId`, `out`


<a id="ep-getCrossPkCapacity"></a>
#### `getCrossPkCapacity` — GetCrossPkCapacityRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossPkCapacityRequest` |
| 定义文件 | `GetCrossPkCapacityRequest.5318f25a.lua` |
| 调用点数 | 1 |
调用点：`AcrossGuessPanel.a59493bb.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `crossPkUserCapacities` | 1 |


<a id="ep-getCrossPkInfo"></a>
#### `getCrossPkInfo` — GetCrossPkInfoRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossPkInfoRequest` |
| 定义文件 | `GetCrossPkInfoRequest.87291a5c.lua` |
| 调用点数 | 2 |
调用点：`AcrossFightScene.b6e63d13.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `crossPkGroupInfo` | 1 |


<a id="ep-getCrossPkReport"></a>
#### `getCrossPkReport` — GetCrossPkReportRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossPkReportRequest` |
| 定义文件 | `GetCrossPkReportRequest.21d6d432.lua` |
| 调用点数 | 2 |
调用点：`AcrossFixturesPanel.2103ed1e.lua`, `AcrossTop4Panel.aab09f76.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `reportId` | `aUid` | AcrossFixturesPanel.2103ed1e.lua:404 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `userinfo1` | 2 |
| `userinfo2` | 2 |
| `whetherWin` | 2 |


<a id="ep-getCrossPvpInfo"></a>
#### `getCrossPvpInfo` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossPvpInfoRequest` |
| 定义文件 | `GetCrossPvpInfoRequest.8e25ad6f.lua` |
| 调用点数 | 3 |
调用点：`CrossArena.e1b6cb0b.lua`, `CrossArenaChanllengeScene.e849d68e.lua`, `CrossArenaRewardScene.9140abb4.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `battleInfo` | 5 |
| `phaseIndex` | 3 |
| `rewardInfo` | 3 |
| `battleInfo.battleScore` | 1 |
| `battleInfo.rank` | 1 |
| `battleInfo.activeScore` | 1 |
| `battleInfo.matchList` | 1 |
| `battleInfo.freeRefreshTimestamp` | 1 |
| `rewardInfo.ranks` | 1 |
| `rewardInfo.rankRewardStatus` | 1 |
| `rewardInfo.serverRewardStatus` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`battleInfo`, `crossVersion`, `phaseIndex`, `rewardInfo`, `rewardInfo.ranks`, `rewardInfo.rewardStatus`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossPvpRankInfo"></a>
#### `getCrossPvpRankInfo` — 获得跨服PVP排行榜信息

| 项 | 值 |
|---|---|
| 请求类 | `CrossPvpGetRankInfoRequest` |
| 定义文件 | `CrossPvpGetRankInfoRequest.2b178242.lua` |
| 调用点数 | 4 |
调用点：`CrossArena.e1b6cb0b.lua`, `CrossArenaChanllengeScene.e849d68e.lua`, `CrossArenaRewardScene.9140abb4.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rankInfos` | 1 |
| `rank` | 1 |
| `score` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`rankInfos`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossPvpReport"></a>
#### `getCrossPvpReport` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossPvpReportRequest` |
| 定义文件 | `GetCrossPvpReportRequest.44236f03.lua` |
| 调用点数 | 3 |
调用点：`CrossArena.e1b6cb0b.lua`, `CrossArenaReviewLayer.34588065.lua`, `CrossArenaChanllengeScene.e849d68e.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rank` | 1 |
| `score` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`reports`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-getCrossPvpVideo"></a>
#### `getCrossPvpVideo` — request / /request / response / /response / /protocol

| 项 | 值 |
|---|---|
| 请求类 | `GetCrossPvpVideoRequest` |
| 定义文件 | `GetCrossPvpVideoRequest.cd099cfe.lua` |
| 调用点数 | 1 |
调用点：`CrossArenaReviewLayer.34588065.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `reportId` | `dataList[aIndex].uuid` | CrossArenaReviewLayer.34588065.lua:183 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `retCode` | 1 |

客户端自带的假数据构造器（`getDebugDatas`）里出现的字段，可当响应结构参考：`reports`

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-guessCrossPkRank"></a>
#### `guessCrossPkRank` — GuessCrossPkRankRequest

| 项 | 值 |
|---|---|
| 请求类 | `GuessCrossPkRankRequest` |
| 定义文件 | `GuessCrossPkRankRequest.29b5f5f7.lua` |
| 调用点数 | 1 |
调用点：`AcrossGuessPanel.a59493bb.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `guessUid` | `tonumber(self.selectedUid)` | AcrossGuessPanel.a59493bb.lua:128 |


<a id="ep-inspireCrossBossTeam"></a>
#### `inspireCrossBossTeam` — 获取世界boss信息

| 项 | 值 |
|---|---|
| 请求类 | `InspireCrossBossTeamRequest` |
| 定义文件 | `InspireCrossBossTeamRequest.44d764de.lua` |
| 调用点数 | 1 |
调用点：`CrossBossInspirePanel.f9f3f814.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `gems` | `self.goldInspireCount` | CrossBossInspirePanel.f9f3f814.lua:191 |
| `props` | `self.propInspireCount` | CrossBossInspirePanel.f9f3f814.lua:191 |


<a id="ep-inspireCrossGvg"></a>
#### `inspireCrossGvg` — request / /request / response / /response

| 项 | 值 |
|---|---|
| 请求类 | `InspireCrossGvgRequest` |
| 定义文件 | `InspireCrossGvgRequest.3e517cf1.lua` |
| 调用点数 | 1 |
调用点：`CrossUnionPKTeamAdjustScene.a1da1acc.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `id` | CrossUnionPKTeamAdjustScene.a1da1acc.lua:190 |

> 🟢 该接口在客户端源码里有**官方内嵌协议定义**，精确 schema 见 §6。


<a id="ep-refreshCrossBossBattlePhase"></a>
#### `refreshCrossBossBattlePhase` — 获取世界boss信息

| 项 | 值 |
|---|---|
| 请求类 | `RefreshCrossBossBattlePhaseRequest` |
| 定义文件 | `RefreshCrossBossBattlePhaseRequest.b26fd4ec.lua` |
| 调用点数 | 1 |
调用点：`Activity_CrossMultiplayerBossLayer.b09bc644.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-uploadCrossGvgTeamMirror"></a>
#### `uploadCrossGvgTeamMirror`

| 项 | 值 |
|---|---|
| 请求类 | `UploadCrossGvgTeamMirrorRequest` |
| 定义文件 | `UploadCrossGvgTeamMirrorRequest.2aa39c20.lua` |
| 调用点数 | 2 |
调用点：`CrossUnionPkUpdatePanel.126d28bd.lua`, `CrossUnionPKTeamAdjustScene.a1da1acc.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


### 5.20 通天塔

<a id="ep-challengeBabel"></a>
#### `challengeBabel`

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeBabelRequest` |
| 定义文件 | `ChallengeBabelRequest.5643264f.lua` |
| 调用点数 | 1 |
调用点：`SkyTowerMainScene.4cbbd4a6.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `selectId` | 1 |


<a id="ep-challengeSkyTower"></a>
#### `challengeSkyTower`

| 项 | 值 |
|---|---|
| 请求类 | `ChallengeSkyTowerRequest` |
| 定义文件 | `ChallengeSkyTowerRequest.cb67b5af.lua` |
| 调用点数 | 1 |
调用点：`NewBabelScene.e3c184cb.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `floor` | `(self.sharkSkyTowerData.currStatus.currFloor + 1)` | NewBabelScene.e3c184cb.lua:182 |
| `type` | `evt.context` | NewBabelScene.e3c184cb.lua:182 |
| `version` | `1` | NewBabelScene.e3c184cb.lua:182 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `leftHpRate` | 2 |
| `win` | 1 |
| `forbidSkip` | 1 |
| `monsterGroupId` | 1 |
| `haveTimesLeft` | 1 |
| `selectDifficult` | 1 |
| `haveReward` | 1 |
| `currTotalStars` | 1 |
| `currFloor` | 1 |
| `firstTimeBigWin` | 1 |
| `clearNewBabel` | 1 |


<a id="ep-gainAutoClimbReward"></a>
#### `gainAutoClimbReward`

| 项 | 值 |
|---|---|
| 请求类 | `GainAutoClimbRewardRequest` |
| 定义文件 | `GainAutoClimbRewardRequest.7cac1c99.lua` |
| 调用点数 | 6 |
调用点：`SkyRunAutoPanel.6cc1fa93.lua`, `SkyRunAutoScene.489e905d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `speedUp` | `false` ・ `true` | SkyRunAutoPanel.6cc1fa93.lua:138 |


<a id="ep-gainSkipBattleAddition"></a>
#### `gainSkipBattleAddition`

| 项 | 值 |
|---|---|
| 请求类 | `SkyTowerSkipGainAddRequest` |
| 定义文件 | `SkyTowerSkipGainAddRequest.59f1cb67.lua` |
| 调用点数 | 1 |
调用点：`NewBabelSkipFloorBuffPanel.059fe0b8.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `floorId` | `self.currentAdditionFloor + 1` | NewBabelSkipFloorBuffPanel.059fe0b8.lua:113 |
| `type` | `evt.target.index` | NewBabelSkipFloorBuffPanel.059fe0b8.lua:113 |


<a id="ep-gainSkipBattleRewards"></a>
#### `gainSkipBattleRewards`

| 项 | 值 |
|---|---|
| 请求类 | `SkyTowerSkipGainRewardsRequest` |
| 定义文件 | `SkyTowerSkipGainRewardsRequest.f00455e2.lua` |
| 调用点数 | 1 |
调用点：`NewBabelSkipPanel.10ed3cd8.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


<a id="ep-getBabelInfo"></a>
#### `getBabelInfo`

| 项 | 值 |
|---|---|
| 请求类 | `GetBabelInfoRequest` |
| 定义文件 | `GetBabelInfoRequest.d70322ad.lua` |
| 调用点数 | 6 |
调用点：`SkyEnterPanel.7a7c4204.lua`, `SkyRunAutoPanel.6cc1fa93.lua`, `SkyRunAutoScene.489e905d.lua`, `SkyTowerMainScene.4cbbd4a6.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-resetBabel"></a>
#### `resetBabel`

| 项 | 值 |
|---|---|
| 请求类 | `ResetBabelRequest` |
| 定义文件 | `ResetBabelRequest.9486a787.lua` |
| 调用点数 | 1 |
调用点：`SkyTowerMainScene.4cbbd4a6.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-resetClimbData"></a>
#### `resetClimbData`

| 项 | 值 |
|---|---|
| 请求类 | `ResetClimbTowerRequest` |
| 定义文件 | `ResetClimbTowerRequest.26f2060b.lua` |
| 调用点数 | 4 |
调用点：`BattleResultPanel.5b63b566.lua`, `NewBabelRestartAfterDiePanel.a48a90ec.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `type` | `0` ・ `1` | BattleResultPanel.5b63b566.lua:1685 |


<a id="ep-skipSkyTowerBattle"></a>
#### `skipSkyTowerBattle`

| 项 | 值 |
|---|---|
| 请求类 | `SkyTowerSkipBattleRequest` |
| 定义文件 | `SkyTowerSkipBattleRequest.69987798.lua` |
| 调用点数 | 1 |
调用点：`NewBabelSkipPanel.10ed3cd8.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-startAutoClimbBabel"></a>
#### `startAutoClimbBabel`

| 项 | 值 |
|---|---|
| 请求类 | `StartAutoClimbBabelRequest` |
| 定义文件 | `StartAutoClimbBabelRequest.36b78357.lua` |
| 调用点数 | 2 |
调用点：`SkyRunAutoPanel.6cc1fa93.lua`, `SkyRunAutoScene.489e905d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


### 5.21 道具 / 商店

<a id="ep-buyActionPower"></a>
#### `buyActionPower` — BuyActionPowerRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyActionPowerRequest` |
| 定义文件 | `BuyActionPowerRequest.1c50b194.lua` |
| 调用点数 | 1 |
调用点：`MultiplayerBossChallengeScene.2c2bff50.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `requisites` | 1 |


<a id="ep-buyChallengeNum"></a>
#### `buyChallengeNum` — BuyChallengeNumRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyChallengeNumRequest` |
| 定义文件 | `BuyChallengeNumRequest.bca8c9ee.lua` |
| 调用点数 | 1 |
调用点：`ArenaRankScene.22570f79.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `amount` | 2 |
| `requisite` | 1 |


<a id="ep-buyEnergy"></a>
#### `buyEnergy` — BuyEnergyRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyEnergyRequest` |
| 定义文件 | `BuyEnergyRequest.f643505d.lua` |
| 调用点数 | 1 |
调用点：`EENPSupplyPanel.687ca331.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-buyEnergyStone"></a>
#### `buyEnergyStone`

| 项 | 值 |
|---|---|
| 请求类 | `BlowBalloonActBuyEnegyRequest` |
| 定义文件 | `BlowBalloonActBuyEnegyRequest.7ea97172.lua` |
| 调用点数 | 1 |
调用点：`BlowBalloonBuyStonePanel.be3b553f.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `num` | `evt.target.count` | BlowBalloonBuyStonePanel.be3b553f.lua:105 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-buyEventPoint"></a>
#### `buyEventPoint` — BuyEventPointRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyEventPointRequest` |
| 定义文件 | `BuyEventPointRequest.e51238ae.lua` |
| 调用点数 | 1 |
调用点：`EENPSupplyPanel.687ca331.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-buyGoods"></a>
#### `buyGoods`

| 项 | 值 |
|---|---|
| 请求类 | `BuyGoodsRequest` |
| 定义文件 | `BuyGoodsRequest.bbee259e.lua` |
| 调用点数 | 2 |
调用点：`ReNamePropBuyPanel.3ebfd6d4.lua`, `ShopScene.8c29c890.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `goodsId` | `shopReNameProp.id` ・ `self._data.id` | ReNamePropBuyPanel.3ebfd6d4.lua:101 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `reward` | 2 |


<a id="ep-buyGrid"></a>
#### `buyGrid`

| 项 | 值 |
|---|---|
| 请求类 | `BuyGridRequest` |
| 定义文件 | `BuyGridRequest.862462d3.lua` |
| 调用点数 | 2 |
调用点：`NewPackageFullPanel.ae448d89.lua`, `BackpackScene.9b0694aa.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `requisite` | 6 |
| `requisite.amount` | 4 |
| `rewards` | 3 |


<a id="ep-buyMissionCompleteCount"></a>
#### `buyMissionCompleteCount` — BuyMissionCompleteCountRequest

| 项 | 值 |
|---|---|
| 请求类 | `BuyMissionCompleteCountRequest` |
| 定义文件 | `BuyMissionCompleteCountRequest.7a825c09.lua` |
| 调用点数 | 2 |
调用点：`ChapterMapScene.56ea0d90.lua`, `CityMainScene.6c78a367.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `missionId` | `aMissionId` | ChapterMapScene.56ea0d90.lua:2507 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `gems` | 2 |


<a id="ep-buySeckillItem"></a>
#### `buySeckillItem` — 购买限时秒杀物品接口

| 项 | 值 |
|---|---|
| 请求类 | `SeckillBuyRequest` |
| 定义文件 | `SeckillBuyRequest.2050642e.lua` |
| 调用点数 | 1 |
调用点：`Activity_SeckillLayer.75fdb5be.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `aData.id` | SeckillBuyRequest.2050642e.lua:canon\request\SeckillBuyRequest.2050642ede29292abe1da24788a3eb75.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-exchangeGiftBag"></a>
#### `exchangeGiftBag` — 兑换礼包请求

| 项 | 值 |
|---|---|
| 请求类 | `ExchangeGiftBagRequest` |
| 定义文件 | `ExchangeGiftBagRequest.b70954ca.lua` |
| 调用点数 | 1 |
调用点：`ConfigScene.a838f4ae.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `activationCode` | `self.txtCodeInput:getText()` | ConfigScene.a838f4ae.lua:449 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |
| `exchangeGiftBagInfo` | 1 |


<a id="ep-exchangeMedalShop"></a>
#### `exchangeMedalShop` — 获得商品

| 项 | 值 |
|---|---|
| 请求类 | `ExchangeMedalShopRequest` |
| 定义文件 | `ExchangeMedalShopRequest.b18e718a.lua` |
| 调用点数 | 1 |
调用点：`MedalShopScene.1b93eac7.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `exchangeId` | `self._data.id` | ExchangeMedalShopRequest.b18e718a.lua:canon\request\ExchangeMedalShopRequest.b18e718a7b23d331d96e33b0a802cc39.lua |
| `exchangeListId` | `self._data.listId` | ExchangeMedalShopRequest.b18e718a.lua:canon\request\ExchangeMedalShopRequest.b18e718a7b23d331d96e33b0a802cc39.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-exchangeMysteriousItem"></a>
#### `exchangeMysteriousItem` — 宝物锁定

| 项 | 值 |
|---|---|
| 请求类 | `ExchangeMysteriousItemRequest` |
| 定义文件 | `ExchangeMysteriousItemRequest.d5be1c48.lua` |
| 调用点数 | 1 |
调用点：`Activity_MySteriousShopLayer.060e867d.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `id` | `Config.id` | ExchangeMysteriousItemRequest.d5be1c48.lua:canon\request\ExchangeMysteriousItemRequest.d5be1c484e43cb627aaf525b56e46a54.lua |


<a id="ep-exchangeSecretShop"></a>
#### `exchangeSecretShop` — 神秘商店兑换

| 项 | 值 |
|---|---|
| 请求类 | `ExchangeSecretShopRequest` |
| 定义文件 | `ExchangeSecretShopRequest.38676edc.lua` |
| 调用点数 | 1 |
调用点：`Activity_MysteryShopLayer.c9857fcd.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `exchangeId` | `itemList[evt.data + 1].id` | Activity_MysteryShopLayer.c9857fcd.lua:476 |
| `exchangeListId` | `itemList[evt.data + 1].listId` | Activity_MysteryShopLayer.c9857fcd.lua:476 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-getMedalShopList"></a>
#### `getMedalShopList` — 获得商品

| 项 | 值 |
|---|---|
| 请求类 | `GetMedalShopListRequest` |
| 定义文件 | `GetMedalShopListRequest.b88ec024.lua` |
| 调用点数 | 2 |
调用点：`MedalShopScene.1b93eac7.lua`, `SecretaryScene.dcffcc9c.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | onSucceed | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemIdList` | 5 |


<a id="ep-getProps"></a>
#### `getProps` — GetPropsRequest.lua - 培养卡片的请求

| 项 | 值 |
|---|---|
| 请求类 | `GetPropsRequest` |
| 定义文件 | `GetPropsRequest.213a08ab.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | params | 参数表由上层构造，见调用点 |


<a id="ep-getSeckillInfo"></a>
#### `getSeckillInfo` — 获得秒杀活动当前状态

| 项 | 值 |
|---|---|
| 请求类 | `SeckillGetInfoRequest` |
| 定义文件 | `SeckillGetInfoRequest.118853ca.lua` |
| 调用点数 | 1 |
调用点：`ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `seckillItems` | 1 |


<a id="ep-getSecretShopList"></a>
#### `getSecretShopList` — 获得神秘商店列表

| 项 | 值 |
|---|---|
| 请求类 | `GetSecretShopListRequest` |
| 定义文件 | `GetSecretShopListRequest.26031608.lua` |
| 调用点数 | 3 |
调用点：`Activity_MysteryShopLayer.c9857fcd.lua`, `ActivityPanelScene.71655c90.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemIdList` | 2 |


<a id="ep-refreshMedalShop"></a>
#### `refreshMedalShop` — 刷新勋章商城

| 项 | 值 |
|---|---|
| 请求类 | `RefreshMedalShopRequest` |
| 定义文件 | `RefreshMedalShopRequest.546aee30.lua` |
| 调用点数 | 1 |
调用点：`MedalShopScene.1b93eac7.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| *(动态)* | onSucceed | 参数表由上层构造，见调用点 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemIdList` | 3 |


<a id="ep-refreshSecretShop"></a>
#### `refreshSecretShop` — 刷新神秘商店

| 项 | 值 |
|---|---|
| 请求类 | `RefreshSecretShopRequest` |
| 定义文件 | `RefreshSecretShopRequest.dbf115f9.lua` |
| 调用点数 | 1 |
调用点：`Activity_MysteryShopLayer.c9857fcd.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `itemIdList` | 1 |


<a id="ep-sellProps"></a>
#### `sellProps` — SellPropsRequest.lua - 出售道具的请求

| 项 | 值 |
|---|---|
| 请求类 | `SellPropsRequest` |
| 定义文件 | `SellPropsRequest.ee3d7d51.lua` |
| 调用点数 | 1 |
调用点：`ItemSellMessageBoxPanel.7afb89c9.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `requisite` | `items` | ItemSellMessageBoxPanel.7afb89c9.lua:230 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 1 |


<a id="ep-useProp"></a>
#### `useProp`

| 项 | 值 |
|---|---|
| 请求类 | `UsePropRequest` |
| 定义文件 | `UsePropRequest.46c7f25f.lua` |
| 调用点数 | 11 |
调用点：`Activity_ChallengeMysteriousLayer.72ee98dc.lua`, `Activity_CowstageLayer.a78d739e.lua`, `MerryChristmasChallengePanel.075f3aa8.lua`, `ArenaRankScene.22570f79.lua`, `ArenaReportScene.e61bb6a9.lua`, `BattleScene.07008061.lua` 等 11 个文件

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `amount` | `1` | Activity_ChallengeMysteriousLayer.72ee98dc.lua:288 |
| `propId` | `aEventPointPropId` ・ `aEnergyPropId` | Activity_ChallengeMysteriousLayer.72ee98dc.lua:288 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 11 |


### 5.22 邮件

<a id="ep-batchDeleteRewardEmail"></a>
#### `batchDeleteRewardEmail` — 批量删除奖励邮件

| 项 | 值 |
|---|---|
| 请求类 | `EmailBatchDeleteRewardEmailRequest` |
| 定义文件 | `EmailBatchDeleteRewardEmailRequest.229b21af.lua` |
| 调用点数 | 3 |
调用点：`EmailViewPanel.f64f248e.lua`, `EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardEmailIds` | `{targetEmailId}` ・ `rewardList` | EmailBatchDeleteRewardEmailRequest.229b21af.lua:canon\request\EmailBatchDeleteRewardEmailRequest.229b21af2621c5c6b8209fc52127ba77.lua |


<a id="ep-batchDeleteSysEmail"></a>
#### `batchDeleteSysEmail` — 批量删除系统邮件

| 项 | 值 |
|---|---|
| 请求类 | `EmailBatchDeleteSysEmailRequest` |
| 定义文件 | `EmailBatchDeleteSysEmailRequest.6b71d5f5.lua` |
| 调用点数 | 2 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysEmailIds` | `sysList` | EmailBatchDeleteSysEmailRequest.6b71d5f5.lua:canon\request\EmailBatchDeleteSysEmailRequest.6b71d5f5d890abf40c4003981cc25caf.lua |


<a id="ep-batchDeleteSysNotice"></a>
#### `batchDeleteSysNotice` — 批量删除系统通知

| 项 | 值 |
|---|---|
| 请求类 | `EmailBatchDeleteSysNoticeRequest` |
| 定义文件 | `EmailBatchDeleteSysNoticeRequest.c682843e.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysNoticeIds` | `mailList` | EmailBatchDeleteSysNoticeRequest.c682843e.lua:canon\request\EmailBatchDeleteSysNoticeRequest.c682843eacde88db7d78d1a1c01b8c69.lua |


<a id="ep-batchDeleteUserEmail"></a>
#### `batchDeleteUserEmail` — 批量删除用户邮件

| 项 | 值 |
|---|---|
| 请求类 | `EmailBatchDeleteUserEmailRequest` |
| 定义文件 | `EmailBatchDeleteUserEmailRequest.b6821f4d.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `userEmailIds` | `mailList` | EmailBatchDeleteUserEmailRequest.b6821f4d.lua:canon\request\EmailBatchDeleteUserEmailRequest.b6821f4d16813ea12e5525965d051deb.lua |


<a id="ep-deleteSysEmail"></a>
#### `deleteSysEmail` — DeleteSysEmailRequest

| 项 | 值 |
|---|---|
| 请求类 | `DeleteSysEmailRequest` |
| 定义文件 | `DeleteSysEmailRequest.cfefd2e1.lua` |
| 调用点数 | 1 |
调用点：`EmailViewPanel.f64f248e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysEmailMetaId` | `targetEmailId` | EmailViewPanel.f64f248e.lua:91 |


<a id="ep-deleteSysNotice"></a>
#### `deleteSysNotice` — DeleteSysNoticeRequest

| 项 | 值 |
|---|---|
| 请求类 | `DeleteSysNoticeRequest` |
| 定义文件 | `DeleteSysNoticeRequest.c72e5440.lua` |
| 调用点数 | 1 |
调用点：`EmailViewPanel.f64f248e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysNoticeId` | `mailData.sysNoticeId` | EmailViewPanel.f64f248e.lua:112 |


<a id="ep-deleteUserEmail"></a>
#### `deleteUserEmail` — DeleteUserEmailRequest

| 项 | 值 |
|---|---|
| 请求类 | `DeleteUserEmailRequest` |
| 定义文件 | `DeleteUserEmailRequest.d7d3343e.lua` |
| 调用点数 | 1 |
调用点：`EmailViewPanel.f64f248e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `userEmailId` | `mailData.userEmailId` | EmailViewPanel.f64f248e.lua:124 |


<a id="ep-gainRewardEmailReward"></a>
#### `gainRewardEmailReward` — 领取邮件奖励

| 项 | 值 |
|---|---|
| 请求类 | `EmailGainRewardEmailRewardRequest` |
| 定义文件 | `EmailGainRewardEmailRewardRequest.8932a63d.lua` |
| 调用点数 | 1 |
调用点：`EmailViewPanel.f64f248e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardEmailId` | `mailData.rewardEmailId` | EmailGainRewardEmailRewardRequest.8932a63d.lua:canon\request\EmailGainRewardEmailRewardRequest.8932a63d616d1bbaf20b989115c51b66.lua |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-gainSysEmailReward"></a>
#### `gainSysEmailReward` — GainSysEmailRewardRequest

| 项 | 值 |
|---|---|
| 请求类 | `GainSysEmailRewardRequest` |
| 定义文件 | `GainSysEmailRewardRequest.fa76c2d1.lua` |
| 调用点数 | 1 |
调用点：`EmailViewPanel.f64f248e.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysEmailId` | `mailData.sysEmailMetaId` | EmailViewPanel.f64f248e.lua:168 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 2 |


<a id="ep-getUserEmails"></a>
#### `getUserEmails` — GetUserEmailsRequest

| 项 | 值 |
|---|---|
| 请求类 | `GetUserEmailsRequest` |
| 定义文件 | `GetUserEmailsRequest.64a20b0b.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

无业务参数（仅框架附加的 `serverId`）。


<a id="ep-modifyEmail"></a>
#### `modifyEmail` — EmailChangeRequest

| 项 | 值 |
|---|---|
| 请求类 | `EmailChangeRequest` |
| 定义文件 | `EmailChangeRequest.cd5e5bcb.lua` |
| 调用点数 | 1 |
调用点：`ConfigScene.a838f4ae.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `newEmail` | `newEmail` | ConfigScene.a838f4ae.lua:308 |


<a id="ep-readRewardEmail"></a>
#### `readRewardEmail` — 标记奖励邮件为已读

| 项 | 值 |
|---|---|
| 请求类 | `EmailReadRewardEmailRequest` |
| 定义文件 | `EmailReadRewardEmailRequest.3e8751ec.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `rewardEmailId` | `mailData.rewardEmailId` | EmailReadRewardEmailRequest.3e8751ec.lua:canon\request\EmailReadRewardEmailRequest.3e8751ec864433b3c82e55737bf2edb1.lua |


<a id="ep-readSysEmail"></a>
#### `readSysEmail` — ReadSysEmailRequest

| 项 | 值 |
|---|---|
| 请求类 | `ReadSysEmailRequest` |
| 定义文件 | `ReadSysEmailRequest.1813d037.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysEmailMetaId` | `mailData.sysEmailMetaId` | EmailScene.58cd4eda.lua:776 |


<a id="ep-readSysNotice"></a>
#### `readSysNotice` — ReadSysNoticeRequest

| 项 | 值 |
|---|---|
| 请求类 | `ReadSysNoticeRequest` |
| 定义文件 | `ReadSysNoticeRequest.bb40eff7.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `sysNoticeId` | `mailData.sysNoticeId` | EmailScene.58cd4eda.lua:788 |


<a id="ep-readUserEmail"></a>
#### `readUserEmail` — ReadUserEmailRequest

| 项 | 值 |
|---|---|
| 请求类 | `ReadUserEmailRequest` |
| 定义文件 | `ReadUserEmailRequest.c29f595f.lua` |
| 调用点数 | 1 |
调用点：`EmailScene.58cd4eda.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `userEmailId` | `mailData.userEmailId` | EmailScene.58cd4eda.lua:796 |


<a id="ep-sendUserEmail"></a>
#### `sendUserEmail` — SendUserEmailRequest

| 项 | 值 |
|---|---|
| 请求类 | `SendUserEmailRequest` |
| 定义文件 | `SendUserEmailRequest.ca142726.lua` |
| 调用点数 | 1 |
调用点：`EmailWritePanel.76d107e2.lua`

**请求参数**

| 参数 | 取值 / 表达式示例 | 证据 |
|---|---|---|
| `serverId` | `DataManager.getServerid()` | 框架 `BaseRequest:start` 自动附加 |
| `content` | `self.mailContent` | EmailWritePanel.76d107e2.lua:70 |
| `receiveUid` | `self.targetUid` | EmailWritePanel.76d107e2.lua:70 |

**客户端读取的响应字段**（括号内为引用次数）

| 字段 | 次数 |
|---|---|
| `rewards` | 3 |


---

## 6. 客户端内嵌的精确协议定义（`<protocol>` DSL）

这 24 个接口的 Lua 文件顶部带有原厂协议注释，字段名、类型、中文说明俱全——**这是最高可信度的 schema**。

### 获取跨服pvp录像信息

- 文件：`BuyCrossPvpChallengeTimeRequest.3bc93bf2.lua`  行 2
- 关联请求类：`BuyCrossPvpChallengeTimeRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `reportId` | int |  | 录像id |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cardInitDatas` | list | BattleCardInitData | 怪物/卡牌/墙的初始值 |
| `eventFlow` | list | BattleEvent | 战斗事件流 |
| `win` | boolean |  | 本波怪是否胜利 |
| `leftHpRate` | float |  | 胜利方剩余血量比例 |

### 领取跨服pvp奖励

- 文件：`CrossPvpGainBattleRewardRequest.12e5c325.lua`  行 6
- 关联请求类：`CrossPvpGainBattleRewardRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `type` | int |  | 领取类型(0-全区礼包;1-排名礼包) |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rewards` | list | Reward | 奖励详情 |

### 获得跨服PVP排行榜信息

- 文件：`CrossPvpGetRankInfoRequest.2b178242.lua`  行 6
- 关联请求类：`CrossPvpGetRankInfoRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rankInfos` | list | RankInfo | 排名列表 |

### 获得跨服PVP信息

- 文件：`GetCrossPvpInfoRequest.8e25ad6f.lua`  行 1
- 关联请求类：`GetCrossPvpInfoRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `crossVersion` | int |  | 届数 |
| `phaseIndex` | int |  | 阶段指针(0-战斗;1-领奖) |
| `battleInfo` | property | BattlePhase | 战斗阶段信息 |
| `rewardInfo` | property | RewawrdPhase | 领奖阶段信息 |

### 获得跨服PVP战报信息

- 文件：`GetCrossPvpReportRequest.44236f03.lua`  行 1
- 关联请求类：`GetCrossPvpReportRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `reports` | list | ReportInfo | 战报列表 |

### 获取跨服pvp录像信息

- 文件：`GetCrossPvpVideoRequest.cd099cfe.lua`  行 2
- 关联请求类：`GetCrossPvpVideoRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `reportId` | int |  | 录像id |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cardInitDatas` | list | BattleCardInitData | 怪物/卡牌/墙的初始值 |
| `eventFlow` | list | BattleEvent | 战斗事件流 |
| `win` | boolean |  | 本波怪是否胜利 |
| `leftHpRate` | float |  | 胜利方剩余血量比例 |

### 获取gvg战斗信息

- 文件：`CrossUnionPkGetBattleReportRequest.1b502719.lua`  行 6
- 关联请求类：`CrossUnionPkGetBattleReportRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `reportId` | int |  | 战报id |
| `knockout` | boolean |  | 是否是淘汰赛 |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `battleReport` | property | SharkUnionBattlefieldReport | 战报 |

### 获得军团积分前十名及自己

- 文件：`CrossUnionPkGetGroupRankScoreRequest.c20fba73.lua`  行 6
- 关联请求类：`CrossUnionPkGetGroupRankScoreRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `selfScore` | property | CrossGVGScoreInfo | 自己军团的积分信息 |
| `top10ScoreList` | list | CrossGVGScoreInfo | 积分前十名军团信息 |

### 获得跨服军团战小组赛战报

- 文件：`CrossUnionPkGetGroupReportsRequest.1a9e91f3.lua`  行 6
- 关联请求类：`CrossUnionPkGetGroupReportsRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `reports` | list | GVGReport | 战报信息列表 |

### 获取淘汰赛信息

- 文件：`CrossUnionPkGetKnockoutInfoRequest.9688e362.lua`  行 6
- 关联请求类：`CrossUnionPkGetKnockoutInfoRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `sixteen` | list | CrossGvgResultOutline | 16强 |
| `eight` | list | CrossGvgResultOutline | 8强 |
| `four` | list | CrossGvgResultOutline | 4强 |
| `championBattle` | property | CrossGvgResultOutline | 冠军赛 |
| `thirdPlaceBattle` | property | CrossGvgResultOutline | 季军赛 |

### 获得跨服军团战小组赛战斗信息

- 文件：`CrossUnionPkGroupBattleRequest.5b745209.lua`  行 6
- 关联请求类：`CrossUnionPkGroupBattleRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `battleReport` | property | SharkUnionBattlefieldReport | 城池的战报 |
| `changePoints` | int |  | 变化的积分数 |
| `currPoints` | int |  | 当前积分 |

### 调整阵型

- 文件：`ExchangeGvgFormationRequest.e50e16c2.lua`  行 2
- 关联请求类：`ExchangeGvgFormationRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `override` | boolean |  | 是否强制覆盖 |
| `unionId` | int |  | 军团id |
| `serverId` | int |  | 服务器 |
| `version` | int |  | 阵型版本号 |
| `forwardUid` | long |  | 单挑战玩家id |
| `headUids` | long |  | 阵首玩家id |
| `middleUids` | long |  | 阵中玩家id |
| `tailUids` | long |  | 阵尾玩家id |

**response**：无

### 获得跨服军团战分在同一个组的服务器id

- 文件：`GetCrossGvgGroupInfoRequest.6b3a365e.lua`  行 2
- 关联请求类：`GetCrossGvgGroupInfoRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `serverIds` | int |  | 分在同一个组的服务器id |

### 获得跨服军团战主界面

- 文件：`GetCrossGvgInfoRequest.d980ae99.lua`  行 2
- 关联请求类：`GetCrossGvgInfoRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `version` | int |  | 阵型版本号 |
| `striveInspireNum` | int |  | 奋力一击 |
| `coinInspireNum` | int |  | 金币鼓舞次数 |
| `gemInspireNum` | int |  | 金币鼓舞次数 |
| `signs` | list | ApplicantGvgUserInfo | 报名玩家信息 |

### 调整阵型

- 文件：`InspireCrossGvgRequest.3e517cf1.lua`  行 2
- 关联请求类：`InspireCrossGvgRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `override` | boolean |  | 是否强制覆盖 |
| `unionId` | int |  | 军团id |
| `serverId` | int |  | 服务器 |
| `version` | int |  | 阵型版本号 |
| `forwardUid` | long |  | 单挑战玩家id |
| `headUids` | long |  | 阵首玩家id |
| `middleUids` | long |  | 阵中玩家id |
| `tailUids` | long |  | 阵尾玩家id |

**response**：无

### 装备附灵

- 文件：`EnchantUpgradeRequest.2f528881.lua`  行 6
- 关联请求类：`EnchantUpgradeRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `equipId` | int |  | 被附灵装备ID |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `sharkEquip` | property | SharkEquip | 装备信息 |

### 完成装备附灵新手引导

- 文件：`GetEnchantStepRewardRequest.7ec01e80.lua`  行 6
- 关联请求类：`GetEnchantStepRewardRequest`

**request**：无参数

**response**：无

### 挑战六星武将副本

- 文件：`challengeMysteriousRequest.d3e3c682.lua`  行 2
- 关联请求类：`ChallengeMysteriousRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 要挑战的副本id |
| `difficultyDegree` | int |  | 难度 |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cardInitDatas` | list | BattleCardInitData | 敌我卡牌初始数据 |
| `eventFlow` | list | BattleEvent | 战斗事件流 |
| `rewards` | list | Reward | 挑战成功奖励 |
| `qteRewards` | list | Reward | qte奖励 |
| `vipRewards` | list | Reward | vip加成奖励 |
| `qte` | boolean |  | 是否触发qte |
| `win` | boolean |  | 挑战是否成功 |
| `leftHpRate` | float |  | 胜利方剩余血量比例 |

### 拆分宝物

- 文件：`SplitTreasureRequest.210e2c80.lua`  行 2
- 关联请求类：`SplitTreasureRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `treasureId` | int |  | 宝物Id |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rewards` | list | Reward | 拆分获取物品列表 |

### 领取世界Boss奖励

- 文件：`ActiveRechangeRequest.271668d3.lua`  行 5
- 关联请求类：`ActiveRechangeRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `level` | int |  | 奖励等级 |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rewards` | list | Reward | 等级奖励 |

### 领取多重好礼活动奖励

- 文件：`ConsumeRewardGainRequest.dfd6be07.lua`  行 7
- 关联请求类：`ConsumeRewardGainRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 奖励id |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rewards` | list | Reward | 奖励 |

### 获得多重好礼信息

- 文件：`ConsumeRewardGetInfoRequest.c27c4978.lua`  行 7
- 关联请求类：`ConsumeRewardGetInfoRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `recharges` | int |  | 活动期间充值金币 |
| `rewards` | int |  | 已领取礼品id |

### 扫荡精英关卡

- 文件：`EliteSweepRequest.9c91b00c.lua`  行 6
- 关联请求类：`EliteSweepRequest`

**request**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `eliteId` | int |  | 精英关卡id |

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rewards` | list | ClearMissionReward | 扫荡结果 |

### 许愿池许愿

- 文件：`FountainWishRequest.53e99de3.lua`  行 7
- 关联请求类：`FountainWishRequest`

**request**：无参数

**response**

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `coins` | int |  | 基础银币获得 |
| `multiple` | int |  | 暴击倍数 |

### 6.1 结构体定义（`<bean>`，共 40 个）

这些是**服务端下发给客户端的配置/数据结构**（多见于 `getMeta`、`getCrossGvgInfo` 等），字段名必须一致。

<details><summary><code>CrossArenaRankLayer.75b7763f.lua</code> — local aCell = self:getChildByTag(rawCocosObj, cellTag) local aData = self.list[i</summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `uid` | long |  | uid |
| `rank` | int |  | 排名 |
| `battleScore` | int |  | 天梯积分 |
| `metaId` | int |  | 主卡牌ID |
| `nickName` | string |  | 昵称 |
| `level` | int |  | 等级 |
| `server` | int |  | 服务器 |
| `unionName` | string |  | 军团名称 |
| `combat` | int |  | 战斗力 |

</details>

<details><summary><code>CrossArenaRewardLayer.05d304bc.lua</code> — cell.displayInited 表示显示组件已初始化 function onCellDataSet(cell) </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rank` | int |  | 排名 |
| `battleScore` | int |  | 天梯积分 |
| `metaId` | int |  | 主卡牌ID |
| `nickName` | string |  | 昵称 |
| `level` | int |  | 等级 |
| `server` | int |  | 服务器 |
| `unionName` | string |  | 军团名称 |
| `combat` | int |  | 战斗力 |

</details>

<details><summary><code>CrossArenaTest.b6014742.lua</code> — 生成排名表 function CrossArenaTest.createRanks() </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rank` | int |  | 排名 |
| `battleScore` | int |  | 天梯积分 |
| `metaId` | int |  | 主卡牌ID |
| `nickName` | string |  | 昵称 |
| `level` | int |  | 等级 |
| `server` | int |  | 服务器 |
| `unionName` | string |  | 军团名称 |
| `combat` | int |  | 战斗力 |

</details>

<details><summary><code>CrossPvpGetRankInfoRequest.2b178242.lua</code> — </protocol> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `rank` | int |  | 排名 |
| `battleScore` | int |  | 天梯积分 |
| `metaId` | int |  | 主卡牌ID |
| `nickName` | string |  | 昵称 |
| `level` | int |  | 等级 |
| `server` | int |  | 服务器 |
| `unionName` | string |  | 军团名称 |
| `combat` | int |  | 战斗力 |

</details>

<details><summary><code>CrossUnionPkConfig.11f122c7.lua</code> — 军团战时间配置<interUnionWarTimeMeta> list </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 事件id |
| `warBeginTime` | int |  | 事件开始时间 |
| `warContinueTime` | int |  | 事件持续时间 |

</details>

<details><summary><code>CrossUnionPkGroupRankPanel.1be75f8b.lua</code> — local aData = self.list[index + 1] </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `unionId` | int |  | 军团id |
| `unionName` | String |  | 军团名 |
| `score` | int |  | 军团当前积分 |
| `rank` | int |  | 当前积分排名 |

</details>

<details><summary><code>CrossUnionPkGroupReportsPanel.0279387b.lua</code> — local aData = self.list[index + 1] </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `uuid` | int |  | 战报id |
| `attUnionName` | string |  | 进攻方公会名称 |
| `defUnionName` | string |  | 防守方公会名称 |
| `win` | boolean |  | 进攻方是否胜利 |

</details>

<details><summary><code>CrossUnionPkGetGroupRankScoreRequest.c20fba73.lua</code> — CrossGVGScoreInfo </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `unionId` | int |  | 军团id |
| `unionName` | String |  | 军团名 |
| `score` | int |  | 军团当前积分 |
| `rank` | int |  | 当前积分排名 |

</details>

<details><summary><code>CrossUnionPkGetGroupReportsRequest.1a9e91f3.lua</code> — </protocol> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `uuid` | int |  | 战报id |
| `attUnionName` | string |  | 进攻方公会名称 |
| `defUnionName` | string |  | 防守方公会名称 |
| `win` | boolean |  | 进攻方是否胜利 |

</details>

<details><summary><code>CrossUnionPkGetGroupReportsRequest.1a9e91f3.lua</code> — 获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除 function CrossUnionPkGetGroupReportsRequest.</summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 用于获取战报的id |
| `attUnion` | property | UnionIdentification | 进攻军团 |
| `defUnion` | property | UnionIdentification | 防守军团 |
| `win` | boolean |  | 是否取胜 |

</details>

<details><summary><code>CrossUnionPkGetGroupReportsRequest.1a9e91f3.lua</code> — </bean> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `serverId` | int |  | 服务器id |
| `unionId` | int |  | 军团id |
| `unionName` | string |  | 军团名称 |

</details>

<details><summary><code>CrossUnionPkGetKnockoutInfoRequest.9688e362.lua</code> — </protocol> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 用于获取战报的id |
| `attUnion` | property | UnionIdentification | 进攻军团 |
| `defUnion` | property | UnionIdentification | 防守军团 |
| `win` | boolean |  | 是否取胜 |

</details>

<details><summary><code>CrossUnionPkGetKnockoutInfoRequest.9688e362.lua</code> — 获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除 function CrossUnionPkGetKnockoutInfoRequest.</summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 用于获取战报的id |
| `attUnion` | property | UnionIdentification | 进攻军团 |
| `defUnion` | property | UnionIdentification | 防守军团 |
| `win` | boolean |  | 是否取胜 |

</details>

<details><summary><code>CrossUnionPkGetKnockoutInfoRequest.9688e362.lua</code> — </bean> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `serverId` | int |  | 服务器id |
| `unionId` | int |  | 军团id |
| `unionName` | string |  | 军团名称 |

</details>

<details><summary><code>CrossUnionPkKnockoutScene.2570206b.lua</code> — 显示军团信息 data =</summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `serverId` | int |  | 服务器id |
| `unionId` | int |  | 军团id |
| `unionName` | string |  | 军团名称 |

</details>

<details><summary><code>CrossUnionPkKnockoutScene.2570206b.lua</code> — 添加对抗内容 local againstSize = {height = 200}--给个默认值 防止信息错误情况崩溃 v =</summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 用于获取战报的id |
| `attUnion` | property | UnionIdentification | 进攻军团 |
| `defUnion` | property | UnionIdentification | 防守军团 |
| `win` | boolean |  | 是否取胜 |

</details>

<details><summary><code>UnionPkCityData.419f9161.lua</code> — UnionPkCityData = {} </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cityId` | int |  | 城池id |
| `unionId` | int |  | 占领的军团id，没有时为0 |
| `unionName` | String |  | 军团名称 |
| `occupyNum` | int |  | 当前占领的军团连续占领次数 |
| `userPosition` | int |  | 当前uid的军团职位 |
| `report` | boolean |  | 当前uid的军团是否报名该城池 |
| `successfulBid` | boolean |  | 当前uid的军团是否竞标成功该城池 |
| `challengeCityNum` | int |  | 玩家所在军团的挑战城池数 |
| `ownCityNum` | int |  | 玩家所在军团的占领军团数 |
| `applyNum` | int |  | 报名该城池的军团数量 |

</details>

<details><summary><code>UnionPkConfig.b11216f2.lua</code> — 城池npc防守怪物组<CityNpcGroup> list </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 城池类型 |
| `monsterGroupId` | int |  | 怪物组id |

</details>

<details><summary><code>UnionPkConfig.b11216f2.lua</code> — 团战buff;1单挑普通胜利2单挑大胜3阵首4阵中5阵尾<UnionWarBuff> list </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 团战buff;1单挑普通胜利2单挑大胜3阵首4阵中5阵尾 |
| `attBuff` | int |  | 攻击BUFF |
| `defBuff` | int |  | 防御BUFF |
| `hpBuff` | int |  | 血量BUFF |

</details>

<details><summary><code>UnionPkConfig.b11216f2.lua</code> — 获得不同种类城池报名限制的配置表 list类型 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cityId` | int |  | 城池类型id |
| `signUpLevel` | int |  | 军团等级限制 |
| `signUpStrength` | int |  | 军团战斗力限制 |

</details>

<details><summary><code>UnionPkConfig.b11216f2.lua</code> — 生效服务器 list类型 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `serverMin` | int |  | 生效服务器min（闭集） |
| `serverMax` | int |  | 生效服务器max（闭集） |

</details>

<details><summary><code>UnionPkConfig.b11216f2.lua</code> — 军团战奖励Config<UnionWarRewardMeta> dic </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cityId` | int |  | 城市类型id |
| `dailyProfit1` | int |  | 奖励1 |
| `dailyProfit2` | int |  | 奖励2 |
| `dailyProfit3` | int |  | 奖励3 |
| `cityOccupyReward` | int |  | 城市占领奖励 |

</details>

<details><summary><code>UnionPkConfig.b11216f2.lua</code> — 军团战时间配置<UnionWarTimeMeta> list </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 事件id |
| `warBeginTime` | int |  | 事件开始时间 |
| `warContinueTime` | int |  | 事件持续时间 |

</details>

<details><summary><code>UnionPkData.d028b07d.lua</code> — 军团战军团胜利次数列表 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cityId` | int |  | 城池id |
| `winNum` | int |  | 胜利次数 |

</details>

<details><summary><code>Activity_CardOldToNewLayer.364882df.lua</code> — 查找获得卡牌具体配置 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 配置序列 |
| `cardId` | int |  | 兑换卡牌metaId |
| `secretNum` | int |  | 需要星灵数量 |
| `exchangeNum` | int |  | 卡牌兑换上限 |

</details>

<details><summary><code>Activity_CardOldToNewLayer.364882df.lua</code> — 获得当前的兑换信息 hash </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `shopId` | int |  | 卡牌兑换标示 |
| `exchangeNum` | int |  | 已兑换次数 |

</details>

<details><summary><code>Activity_CardOldToNewLayer.364882df.lua</code> — </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cardId` | int |  | 卡牌id |
| `metaId` | int |  | 卡牌配置id |
| `level` | int |  | 卡牌等级 |
| `exp` | int |  | 卡牌经验 |
| `usedPotential` | int |  | 用掉的潜力值 |
| `attTrainValue` | int |  | 培养得来的攻击属性增量 |
| `defTrainValue` | int |  | 培养得来的防御属性增量 |
| `hpTrainValue` | int |  | 培养得来的血量属性增量 |
| `attEvolveValue` | int |  | 进阶获得的血量属性增量 |
| `defEvolveValue` | int |  | 进阶获得的血量属性增量 |
| `hpEvolveValue` | int |  | 进阶获得的血量属性增量 |
| `equipIds` | int |  | 已安装的装备列表 |
| `cardSkills` | list | CardSkill | 卡牌拥有的技能 |
| `cardSpirits` | list | CardSpirits | 已装备的元神列表 |
| `lock` | boolean |  | 是否锁定 |
| `avatarMetaId` | int |  | 武将头像metaId |

</details>

<details><summary><code>Activity_ChallengeMysteriousLayer.72ee98dc.lua</code> — local aData = self.list[index + 1] </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `unionId` | int |  | 军团id |
| `unionName` | String |  | 军团名 |
| `score` | int |  | 军团当前积分 |
| `rank` | int |  | 当前积分排名 |

</details>

<details><summary><code>Activity_ConsumeRewardsLayer.56e66370.lua</code> — 获得奖励预览内容 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 奖励Id |
| `requiredGold` | int |  | 领取条件 |
| `rewards` | list | Reward | 奖励内容 |

</details>

<details><summary><code>Activity_DoubleRewardLayer.068b1062.lua</code> — 获得多倍奖励配置 list </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `silverType` | int |  | 模块类型 |
| `silverMultiple` | float |  | 倍数 |
| `resourceType` | int |  | 影响属性 |
| `open` | int |  | 是否开启 |

</details>

<details><summary><code>Activity_ExchangeDailyLayer.8ca95379.lua</code> — 查找获得卡牌具体配置 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 配置序列 |
| `cardId` | int |  | 兑换卡牌metaId |
| `secretNum` | int |  | 需要星灵数量 |
| `exchangeNum` | int |  | 卡牌兑换上限 |

</details>

<details><summary><code>Activity_ExchangeDailyLayer.8ca95379.lua</code> — 获得当前的兑换信息 hash </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `cardMetaIds` | int |  | 当前可兑换的卡牌metaId |
| `exchangeTimes` | int |  | 当前兑换次数 |

</details>

<details><summary><code>Activity_FountainLayer.612ffc4d.lua</code> — 获得每次奖励银币数量列表 list </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `fountainNum` | int |  | 许愿次数 |
| `silverCoins` | int |  | 银币基数 |

</details>

<details><summary><code>Activity_rechargeLayer.9cd8a922.lua</code> — 获得多倍奖励配置 list <?xml version="1.0" encoding="UTF-8"?> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `stepId` | int |  | 奖励Id |
| `reward` | property | Reward | 奖励内容 |
| `rewardDetail` | string |  | 奖励条件 |

</details>

<details><summary><code>Activity_SeckillLayer.75fdb5be.lua</code> — print("self.list[" .. (index+1) .. "] : " .. table.tostring(self.list[index+1]))</summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `id` | int |  | 活动配置id |
| `itemType` | int |  | 物品类型 |
| `itemNum` | int |  | 物品数量 |
| `itemId` | int |  | 物品配置id |
| `limitNum` | int |  | 单人限购数量 |
| `activeTime` | int |  | 物品开放时间（单位天） |
| `timeBegin` | int |  | 秒杀起始时间（单位分钟） |
| `timeContinue` | int |  | 秒杀持续时间（单位分钟） |
| `coinType` | int |  | 货币类型（1：银币，2：金币） |
| `realNum` | int |  | 真实库存 |
| `showNum` | int |  | 显示库存 |
| `costPrice` | int |  | 原始价格 |
| `presentPrice` | int |  | 折后价格 |

</details>

<details><summary><code>UnionColosseumAllocateRequest.6f4c3160.lua</code> — UnionMonsterReward </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `uid` | long |  | 用户id |
| `amount` | int |  | 用户分得的奖励数量 |

</details>

<details><summary><code>UnionColosseumGetRankRequest.a7691f70.lua</code> — </response> </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `uid` | long |  | 用户id |
| `nickName` | string |  | 用户昵称 |
| `totalDamage` | int |  | 用户对怪兽的累积伤害 |

</details>

<details><summary><code>UnionColosseumStartAllocationRequest.f9c320a6.lua</code> — 重置成员本周领取数量 local tempHash = {} </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `uid` | long |  | 用户id |
| `amount` | int |  | 用户分得的奖励数量 |

</details>

<details><summary><code>DailyTargetScene.51fbbf86.lua</code> — DailyAchieve.xml </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `taskId` | int |  | 任务ID |
| `num` | int |  | 任务完成次数 |
| `complete` | boolean |  | 任务是否完成 |
| `gain` | boolean |  | 是否已领取 |

</details>

<details><summary><code>DailyTargetScene.51fbbf86.lua</code> — 获取目标列表 </summary>

| code | 类型 | ref | 说明 |
|---|---|---|---|
| `achieveId` | int |  | 每日成就唯一id |
| `achieveType` | int |  | 每日成就奖励类型，用于区分成就种类 |
| `achieveNum` | int |  | 成就计数 |
| `achieveReward` | int |  | 成就奖励包id |

</details>

---

## 7. 业务错误码表（来自客户端 `canon/request/CommErrorCodes.lua`）

错误码基址 `SHARK_ERROCODE_ORIGH = 710000`。服务端在响应项里回 `retCode = <码>`（≠200 即触发 `onError`），
或作为全局错误放在 `subHeader.errCode`（`>0` 时客户端弹全局网络错误并重登）。

| 常量 | 码 | 客户端文案 key | 备注 |
|---|---|---|---|
| `USER_NOT_EXIST` | 710070 | `EC_USER_NOT_EXIST_TXT` |  |
| `CREATE_USER_ERROR` | 710071 | `EC_CREATE_USER` |  |
| `NICKNAME_IS_NULL` | 710073 | `login_popup_nicknameIsNull` |  |
| `NICKNAME_IS_INVALID` | 710074 | `login_popup_nicknameIsIllegal` |  |
| `NICKNAME_IS_TOOSHORT` | 710075 | `login_popup_nicknameIsTooShort` |  |
| `NICKNAME_IS_TOOLONG` | 710076 | `login_popup_nicknameIsTooLong` |  |
| `NICKNAME_IS_EXIST` | 710077 | `login_popup_nicknameExist` |  |
| `INVITECODE_NOT_EXIST` | 710078 | `login_popup_InvitationCodeDoesNotExist` |  |
| `NICKNAME_CONTAIN_SENSTIVEWORD` | 710079 | `login_popup_nicknameExist` |  |
| `USER_ENERGY_FULL` | 710090 | `playerInfo_energyFull` |  |
| `USER_ENERGY_BOUGHT_NUM_FULL` | 710091 | `playerInfo_cannotRecoverStamina` |  |
| `USER_EVENT_POINT_FULL` | 710092 | `playerInfo_eventPointFull` |  |
| `USER_EVENT_POINT_BOUGHT_NUM_FULL` | 710093 | `playerInfo_cannotRecoverVigour` |  |
| `CHALLENAGE_PK_ERROR` | 710103 | `EC_CHALLENGE_PK_USER` |  |
| `USER_LEVELUP_EVENT_NOT_EXIST` | 710530 | `popup_normalError` | 依赖的普通关卡未解锁 |
| `GAIN_PK_REWARD_ERROR` | 710544 | `EC_GAIN_PK_REWARDS` |  |
| `FRIEND_NOT_EXIST` | 710601 | `EC_FRIEND_RELATIONSHIP_NOT_EXIST_TXT` | 玩家已不是好友 |
| `FRIEND_LIST_FULL` | 710604 | `EC_FRIEND_LIST_FULL_TXT` | 好友数达到上限 |
| `FRIEND_RELATIONSHIP_EXIST` | 710605 | `EC_FRIEND_RELATIONSHIP_EXIST_TXT` | 好友关系已经建立 |
| `FRIEND_INVITATION_EXIST` | 710606 | `EC_FRIEND_INVITATION_EXIST_TXT` | 已被好友邀请 |
| `FRIEND_INVITATION_NOT_EXIST` | 710607 | `EC_FRIEND_INVITATION_NOT_EXIST_TXT` | 不被好友邀请 |
| `FRIEND_SENDER_INVITATION_LIST_FULL` | 710608 | `EC_FRIEND_SENDER_INVITATION_LIST_FULL_TXT` | 玩家发送邀请数达到上限 |
| `FRIEND_RECEIVER_INVITATION_LIST_FULL` | 710609 | `EC_FRIEND_RECEIVER_INVITATION_LIST_FULL_TXT` | 玩家接收邀请数达到上限 |
| `FRIEND_RELATIONSHIP_NOT_EXIST` | 710610 | `EC_FRIEND_RELATIONSHIP_NOT_EXIST_TXT` | 玩家已不是好友 |
| `FRIEND_FREEGIFT_SEND` | 710611 | `EC_FRIEND_FREEGIFT_SEND_TXT` | 当日已向玩家发送过礼物 |
| `FRIEND_FREEGIFT_SENDNUM_FULL` | 710612 | `EC_FRIEND_FREEGIFT_SENDNUM_FULL_TXT` | 可发送礼物达到上限 |
| `FRIEND_FREEGIFT_ENERGY_POOL_EMPTY` | 710614 | `EC_FRIEND_FREEGIFT_ENERGY_POOL_EMPTY_TXT` | 没有体力可接收 |
| `FRIEND_FREEGIFT_ENERGY_FULL` | 710615 | `EC_FRIEND_FREEGIFT_ENERGY_FULL_TXT` | 玩家体力满 |
| `FRIEND_SELF_LIST_FULL` | 710616 | `friend_acceptRequestFailed_friendFull` | 自己好友数达上限 |
| `FRIEND_ENEMY_LIST_FULL` | 710617 | `friend_acceptRequestFailed_opponentFriendFull` | 对方好友数达上限 |
| `CARD_TARGET_LEVEL_IS_INVALID` | 711063 | `cardEnhance_levelInvalid` | 您选择的等级不正确 |
| `OPEN_VIPBOX` | 712908 | `EC_USE_PROP` |  |
| `ELITE_SETTING_NOTCONFIG` | 713201 | `—` | 关卡配置不存在 |
| `ELITE_CHALLENGETIMES_REACH` | 713202 | `EC_ELITE_CHALLENGETIMES_REACH_TXT` | 挑战次数达到上限 |
| `ELITE_GRID_FULL` | 713203 | `EC_ELITE_GRID_FULL_TXT` | 背包已满 |
| `ELITE_PREMISSION_UNLOCK` | 713204 | `EC_ELITE_PREMISSION_UNLOCK_TXT` | 上一精英关卡未解锁 |
| `ELITE_REQUIREMISSION_UNLOCK` | 713205 | `EC_ELITE_REQUIREMISSION_UNLOCK_TXT` | 依赖的普通关卡未解锁 |
| `COUNTDOWN_REWARD_META_NOT_CONFIGED` | 714180 | `countdownReward_cannotOpen` |  |
| `COUNTDOWN_REWARD_NOT_REACH_TIME` | 714181 | `countdownReward_cannotOpen` |  |
| `EXCHANGE_GIFT_BAG_INVALID_ACTIVATION_CODE` | 714200 | `—` |  |
| `EXCHANGE_GIFT_BAG_HAS_GET_REWARD` | 714201 | `—` |  |
| `ACTIVATION_CODE_META_NOT_CONFIGED` | 714202 | `—` |  |
| `EXCHANGE_GIFT_BAG_NOT_IN_ACTIVITY_TIME` | 714203 | `—` |  |
| `EXCHANGE_GIFT_BAG_ACTIVATION_CODE_NOT_EXIST` | 714204 | `—` |  |
| `EXCHANGE_GIFT_BAG_ACTIVATION_HAS_USED` | 714205 | `—` |  |
| `ACTIVATION_CODE_ITEM_NOT_CONFIGED` | 714207 | `—` |  |
| `ACTIVITY_SECKILL_CLOSE` | 714600 | `activity_goldGod_end_remind` | 活动已结束 |
| `ACTIVITY_SECKILL_ITEM_NOT_CONFIG` | 714601 | `xxx` | 没有配置 |
| `ACTIVITY_SECKILL_CURRENCY_TYPE_NOT_SUPPORT` | 714602 | `xxx` | 无效类型 |
| `ACTIVITY_SECKILL_USER_PURCHASE_LIMIT` | 714603 | `activity_seckill_limit` | 购买次数到达上限 |
| `ACTIVITY_SECKILL_ITEM_SOLD_OUT` | 714604 | `activity_seckill_exhausted` | 库存告罄，下次请早 |
| `ACTIVITY_SECKILL_ITEM_NOT_IN_TIME` | 714605 | `activity_seckill_close` | 不在购买时限内 |
| `USER_JOINED_UNION` | 716300 | `union_creat_not_satisfied5` | 已经加入军团 |
| `USER_IN_UNION_COLD` | 716301 | `union_apply_not_satisfied3` | 加入军团冷却时间 |
| `USER_LEVEL_NOT_FIT_UNION` | 716302 | `union_apply_not_satisfied1` | 需要达到{num}级才能申请加入军团 |
| `UNION_NAME_IS_NULL` | 716304 | `union_creat_not_satisfied6` | 军团名称不能为空 |
| `UNION_NAME_IS_INVALID` | 716305 | `union_creat_not_satisfied8` | 军团名称包含非法字符(只能是中文 数字 字母) |
| `UNION_NAME_IS_TOOSHORT` | 716306 | `union_creat_not_satisfied7` | 军团名称过短 |
| `UNION_NAME_IS_TOOLONG` | 716307 | `union_creat_not_satisfied2` | 军团名不能超过6个汉字或12位英文数字 |
| `UNION_NAME_IS_EXIST` | 716308 | `union_creat_not_satisfied3` | 该军团名已存在 |
| `UNION_NAME_CONTIAN_SENSITIVE_WORD` | 716309 | `union_creat_not_satisfied8` | 军团名称包含非法字符 |
| `USER_APPLY_UNION_REACH_UPPER` | 716311 | `union_apply_not_satisfied4` | 您提交的申请已经达到上限 |
| `UNION_APPLIERS_REACH_UPPER` | 716312 | `union_apply_not_satisfied5` | 该军团不能接受更多的申请了 |
| `USER_NOT_JOIN_ANY_UNION` | 716313 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_APPLY_NOT_EXIST` | 716314 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_CANONT_DISSOLVE_FOR_LEVEL` | 716316 | `union_dissolve_not_satisfied2` | 军团等级达到{num}级后不能解散 |
| `USER_NOT_UNION_MANAGER` | 716317 | `union_dissolve_not_satisfied1` | 只有军团长才能解散军团 |
| `USER_IS_UNION_MANAGER` | 716318 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `USERS_NOT_IN_SAME_UNION` | 716319 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_MEMBERS_REACH_UPPER` | 716320 | `union_examine_accept_remind1` | 军团人数已满 |
| `UNION_CANNOT_DISSOLVE_FOR_MULTIPLE_MEMBERS` | 716322 | `union_dissolve_not_satisfied3` | 军团人数为1时才能解散军团 |
| `UNSUPPORT_UNION_APPOINT_TYPE` | 716323 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_MEMBERS_SUBTYPE_REACH_UPPER` | 716324 | `union_player_button_appointment_remind` | 该职位人数已满 |
| `UNION_MANAGER_LEAVE_TIME_NOT_ENOUGH` | 716325 | `union_player_button_impeach_remind` | 军团长离开超过7天后才能弹劾 |
| `NO_MEMBERS_IN_UNION` | 716326 | `union_data_refresh_remind` | 除了军团长没有其他成员 |
| `USER_IS_NOT_UNION_MANAGER` | 716327 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_NOT_IN_TRANSFER_STATUS` | 716328 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_NOT_IN_DISSOLVE_STATUS` | 716329 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_ALREADY_DISSOLVED` | 716330 | `union_data_refresh_remind` | 数据已过期，请重新进入界面 |
| `UNION_IN_DISSOLVE_STATUS` | 716331 | `union_building_upgrade_not_satisfied3` | 解散中不能执行该操作 |
| `UNION_DECLARATION_TOO_LONG` | 716332 | `union_announcement_not_satisfied1` | 文本过长 |
| `UNION_DECLARATION_CONTAINS_SENSITIVE_WROD` | 716333 | `union_announcement_not_satisfied3` | 您的公告中包含非法字符 |
| `UNION_DECLARATION_IS_EMPTY` | 716334 | `union_announcement_not_satisfied4` | 文本不能为空 |
| `UNION_NOTICE_TOO_LONG` | 716335 | `union_announcement_not_satisfied1` | 文本过长 |
| `UNION_NOTICE_CONTAINS_SENSITIVE_WORD` | 716336 | `union_announcement_not_satisfied3` | 您的公告中包含非法字符 |
| `UNION_NOTICE_IS_EMPTY` | 716337 | `union_announcement_not_satisfied4` | 文本不能为空 |
| `UNION_WEALTH_NOT_ENOUGH` | 716338 | `union_building_upgrade__not_satisfied3` | 财富不够，不能进行升级 |
| `USER_IS_NOT_IN_UNION` | 716339 | `union_monster_errorNum1` | 此人不在军团里，请重新分配 |
| `STR_HAS_WROWN_WORD` | 716340 | `union_text_explain` | 不支持特殊符号的显示，请重新输入 |
| `UNION_BUILDING_REACH_MAX_LEVEL` | 716353 | `union_building_upgrade__not_satisfied1` | 建筑已经达到满级 |
| `UNION_BUILDING_LEVEL_BIGGER_THAN_UNION_LEVEL` | 716357 | `union_building_upgrade__not_satisfied2` | 建筑等级不能超过军团大厅的等级 |
| `UNION_BUILDING_TYPE_UNSUPPORT` | 716358 | `111` | 不存在的建筑类型 |
| `ALREADY_CONSTRUCT_TODAY` | 716359 | `union_build_today_complete_remind` | 今日已建设 |
| `SHARK_USER_UNION_IS_NULL` | 716360 | `111` |  |
| `USER_NOT_IN_UNION` | 716361 | `111` | 用户不在这个军团中 |
| `UNION_CONSTRUCT_TYPE_UNSUPPORT` | 716362 | `111` | 捐献类型不存在 |
| `UNION_SHOP_NORMAL_META_NOT_CONFIGED` | 716363 | `111` |  |
| `UNION_SHOP_SPECIAL_META_NOT_CONFIGED` | 716364 | `111` |  |
| `UNION_NORMAL_PROP_DAILY_PURCHASE_TIMES_LIMIT` | 716365 | `111` | 道具到达上限 |
| `UNION_SPECIAL_PROP_DAILY_PURCHASE_TIMES_LIMIT` | 716366 | `111` | 特殊道具达到上限 |
| `SPECIAL_PROP_IS_NOT_ON_SALE` | 716367 | `111` | 现在不出售 |
| `UNION_SHOP_PROP_TYPE_UNSUPPORT` | 716368 | `111` | 不支持的商城道具类型 |
| `UNION_SHOP_LEVEL_NOT_ENOUGH` | 716369 | `111` | 商城等级不足 |
| `USER_UNION_CONTRIBUTE_NOT_ENOUGH` | 716370 | `111` | 贡献值不足 |
| `RECEIVE_WAGE_AT_WRONG_TIME` | 716371 | `111` | 领工资时间不对 |
| `ALREADY_RECEIVED_WAGE_TODAY` | 716372 | `111` | 今日已领过工资 |
| `UNION_MONSTER_IS_ALIVE` | 716377 | `union_monster_errorNum2` | 怪物尚未死亡，不能进行分配 |
| `UNOIN_MONSTER_CANNOT_SUMMON_MONSTER_THIS_TIME` | 716378 | `union_monster_errorNum3` | 主公，现在不在召唤时间哦 |
| `UNION_MONSTER_HAS_REWARD_NOT_DISTRIBUTE` | 716379 | `union_monster_errorNum4` | 奖励尚未分配 |
| `UNION_MONSTER_ESCAPE` | 716382 | `union_monster_errorNum5` | 怪物已逃跑 |
| `UNION_MONSTER_IS_DEAD` | 716383 | `union_monster_errorNum6` | 怪物已被击杀 |
| `UNION_MONSTER_COLOSSEUM_LEVEL_LIMIT` | 716384 | `union_monster_errorNum7` | 怪物未解锁，请升级斗兽场 |
| `UNION_MONSTER_DAILY_ATT_TIMES_LIMIT` | 716385 | `union_monster_errorNum8` | 攻击次数不足 |
| `UNION_MONSTER_REWARD_ALREADY_DISTRIBUTED` | 716386 | `union_monster_errorNum9` | 奖励已分配 |
| `UNION_MONSTER_REWARD_DISTRIBUTE_NUM_NOT_MATCH` | 716387 | `union_data_refresh_remind` | 分配总数不符--数据已过期，请重新进入界面 |
| `UNION_MONSTER_SUMMON_TIMES_LIMIT` | 716388 | `union_monster_errorNum10` | 召唤次数到达上限 |
| `UNION_MONSTER_SOMEONE_DISTRIBUTING_REWARD` | 716389 | `union_monster_reward_distribution_not_satisfied1` | 有其他玩家正在分配战利品 |
| `UNION_MONSTER_SOMEONE_SUMMONING_MONSTER` | 716390 | `union_monster_summon_not_satisfied1` | 同一时间只能召唤一只怪兽 |
| `UNION_CAREER_META_NOT_CONFIGED` | 716410 | `111` |  |
| `HAS_NO_UNION_PRIVILIGE_DISSOLVE_UNION` | 716411 | `union_announcement_not_satisfied2` | 没有权限解散 |
| `HAS_NO_UNION_PRIVILIGE_APPOINT_VICE_MANAGER` | 716412 | `union_announcement_not_satisfied2` | 没有权限任命副团长 |
| `HAS_NO_UNION_PRIVILIGE_TRANSFER_UNION` | 716413 | `union_announcement_not_satisfied2` | 没有权限移交 |
| `HAS_NO_UNION_PRIVILIGE_KICK_OUT_VICE_MANAGER` | 716414 | `union_announcement_not_satisfied2` | 没有权限踢副团长 |
| `HAS_NO_UNION_PRIVILIGE_RECALL_VICE_MANAGER` | 716415 | `union_announcement_not_satisfied2` | 没有权限罢免副团长 |
| `HAS_NO_UNION_PRIVILIGE_MODIFY_DECLARATION` | 716416 | `union_announcement_not_satisfied2` | 没有权限修改宣言 |
| `HAS_NO_UNION_PRIVILIGE_MODIFY_ANNOUNCEMENT` | 716417 | `union_announcement_not_satisfied2` | 没有权限修改公告 |
| `HAS_NO_UNION_PRIVILIGE_APPOINT_ELITE_MEMBER` | 716418 | `union_announcement_not_satisfied2` | 没有权限任命精英成员 |
| `HAS_NO_UNION_PRIVILIGE_RECALL_ELITE_MEMBER` | 716419 | `union_announcement_not_satisfied2` | 没有权限罢免精英成员 |
| `HAS_NO_UNION_PRIVILIGE_UPGRAGE_UNION_BUILDING` | 716420 | `union_announcement_not_satisfied2` | 没有权限升级建筑 |
| `HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE` | 716421 | `union_announcement_not_satisfied2` | 您的职务不能执行此操作 |
| `HAS_NO_UNION_PRIVILIGE_KICK_OUT_MEMBER` | 716422 | `union_announcement_not_satisfied2` | 没有权限踢人 |
| `HAS_NO_UNION_PRIVILIGE_DONATE` | 716423 | `111` | 没有权限捐献 |
| `HAS_NO_UNION_PRIVILIGE_UNION_SHOP_BUY` | 716424 | `111` | 没有权限购买 |
| `HAS_NO_UNION_PRIVILIGE_RECEIVE_WAGE` | 716425 | `111` | 没有权限领工资 |
| `HAS_NO_UNION_PRIVILIGE_SUMMON_MONSTER` | 716426 | `union_monster_errorNum11` | 主公，您没有召唤权限哦 |
| `HAS_NO_UNION_PRIVILIGE_DISTRIBUTE_MONSTER_REWARD` | 716427 | `union_monster_errorNum12` | 主公，您没有分配权限哦 |
| `GENERAL_EXP_NOT_ENOUGH` | 716471 | `cardEnhance_expInsufficient` | 当前拥有的武将经验不足 |

另有一套内联在代码里的错误码（`canon/request/BaseRequest.lua:796` `errorCodeSet`）：

```
710203 710204 710404 710403 710513 710549 710515 710071 710544 710548 711051
711059 713608 714000 714103 714105 716373 710503 710206
```

---

## 8. 踩坑清单（按「客户端会怎么死」组织）

### 8.1 协议层

| # | 坑 | 现象 | 对策 |
|---|---|---|---|
| 1 | headercvt 双向异或不同（请求 `0xC3` / 响应 `0x71`）| 客户端报 `zlib checksum failed` | 响应方向必须用 `0x71` |
| 2 | `subHeader.errCode > 0` | 弹「主公，网络不好啊！」→ 回登录页 | 成功必须填 `0` |
| 3 | `retCode != 200` | 走 `onError`，业务失败 | 成功必须 `200` |
| 4 | AMF3 整数超 29 位 | 时间戳解码错乱 | 大数编成 double |
| 5 | 响应用密集数组 vs 关联数组 | `pairs` 能读、`ipairs` 读不到 | 统一关联数组；列表字段才用密集数组 |
| 6 | `/systemInfo` 响应被 zlib/headercvt 包了 | 客户端解不出、选服列表空白 | 该接口响应必须是**裸 AMF3** |
| 7 | `/sessionKey/init` 返回 JSON | `split(",")` 拿到垃圾 → 会话失败 | 必须返回纯文本 `uid,uuid,sk` |
| 8 | `config_md5` 与 APK 内 manifest 名不符 | `dynamicUpdateNetError` | 与 `assets/static_config.<md5>.xml` 对齐 |
| 9 | TCP `login` 的 `retCode != 0` | 每 11 秒重连，主界面黑屏 | 必须 `0` |

### 8.2 响应数据层（最容易造成 SIGKILL）

| # | 坑 | 说明 |
|---|---|---|
| 10 | **下发空表 `{}` 反而有害** | Lua 空表为真，会顶掉客户端本地默认值，下一行 nil 运算崩。**宁可省略整个 key** |
| 11 | `uid` / 数字型 ID 必须是字符串 | luajava 签名 `setGspGameUserId(String)`，传 number → `Invalid method call` → SIGKILL |
| 12 | `gameSettingConfig` / `battleSettingConfig` | 只来自服务端 `getMeta`，无本地兜底；缺字段 = `setString(nil)` |
| 13 | `spiritSettingConfig` 等配置表 | 下发 `{}` 会让 `SpiritManager.isUserLevelEnough` 无守卫崩 |
| 14 | `adPictureConfig.adPictures` | 列出的每个 id 都会被 `GachaScene.preloadAd` 无守卫解引用，必须都存在 |
| 15 | `sharkUserExtend` | 被 `canonUtils.lua:603` 的 `pairs(data.sharkUserExtend.tutorialSteps)` 无守卫解引用 |
| 16 | `getHomeInfo.unionMonsterEscapeSeconds` | 必须是数字，nil → `UnionManager.setColosseumMonsterRunTime` 崩 |
| 17 | `accountReturnRewards` | 空 `{}` 为真 → 弹空「主公归来」面板挡住闯关；**故意不下发** |
| 18 | `monthlyLoginRewardItems` | 省略它可让客户端跳过签到网格动画（缺图会崩）|

### 8.3 排查手段

- 引擎对**未捕获** Lua 错误直接 `SIGKILL`，所以「游戏闪退」≈「某处 Lua 报错」。抓 logcat 里的 `[LUA-print]` / `LUA ERROR`。
- **协程里的错误不会打印**（`NewUserGuideCoroutine` 自述）→ 表现是「黑屏 + 进程存活 + 0% CPU」。主界面 `MainMenuScene:onInit` 就在该协程内。
- 开启 `StartupConfig.plist` 的 `LuaDebugEnable` 可接 Lua 远程调试（`hecore.lua_debugger`，外连 8172）。

---

## 9. 附录

### 9.1 被引用但未定义为请求类的名字（1 个）

| 名字 | 引用次数 | 说明 |
|---|---|---|
| `RpcRequest` | 2 | `hecore/rpc.lua` 内部框架类，非业务请求类，可忽略 |

> 全部 372 个业务请求类都能在包内找到定义，没有缺失。

### 9.2 客户端定义了但从未被调用的 endpoint

共 9 个：`getBuyMonthGemCardResult`, `getCowStageInfo`, `getCrossGVGKnockoutStauts`, `getDiceInfo`, `getEatPeachInfo`, `getLimitReward`, `getMissionCompleteInfo`, `getSkyTowerInfo`, `getSysEmailMeta`

### 9.3 统计口径

| 口径 | 数量 | 说明 |
|---|---|---|
| APK 内 Lua 文件 | 1088 | `assets/src/**` |
| `Xxx = class(BaseRequest)` 请求类 | 372 | 由 `^\s*(\w+Request)\s*=\s*class\s*\(` 全文扫描 |
| 声明了 `self.endpoint` 的类 | 371 | |
| **客户端实际发送的 distinct method** | **363** | 本文档第 4/5 节的对象 |
| 有 endpoint 但无任何调用点 | 9 | 见 §9.2 |
| 被引用但未随包发布的请求类 | 1 | 见 §9.1，死代码 |

> 统计口径取「**实际会发出的 method**」：只算有调用点的，不算只定义未使用的 endpoint（见 §9.2）。

### 9.4 免责

《战姬天下》著作权属乐元素（Happy Elements）。本文档仅为个人学习与软件保存目的所做的协议分析，
不含任何原厂代码或资源，不得用于公开运营或盈利。
