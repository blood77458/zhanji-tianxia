# 第 5 轮记录：登录链路整条打通，RPC 拦截生效

## 大突破：完整登录链在**离线**状态跑通

客户端日志（`adb logcat` 过滤 `SINGLE`）：

```
GET  /staticVersion                        -> 本地应答（ASCII，PrintStream）
[SINGLE] single-player server ready, handlers=4
POST /loginAccount/hasVisitorAccount       -> replay (67 字节)
POST /check/android                        -> replay (90 字节)
POST /mappingAccount                       -> replay (51 字节)
[SINGLE-DBG] init / initSession
POST /sessionKey/init  body=1125           -> replay (46 字节)
[SINGLE-DBG] communicationInitSessionCallback / initTransponder / login
[SINGLE] rpc divert active                 <- Communication 拦截生效
[SINGLE] unhandled login                   <- 下一批要实现的
[SINGLE-DBG] communicationLoginCallback
[SINGLE] unhandled loginServer
```

并且登录页已经渲染出 **「1区 本地测试服 推荐」**（来自本地合成的 systemInfo）。

## 本轮改动

1. **修 `replay_body` 的 hex/字节 bug**：之前把十六进制字符串当字节回，
   日志里 `replay /systemInfo (718 bytes)`（718 = 359×2）。现在返回真字节。
2. **`/systemInfo` 改为本地合成**（不再打 HTTP）：
   在 `LoginScene` 里给 `onSystemInfoCall` 加了一个 `response.__prebuilt` 入口，
   并在原 `SystemInfoCall.getData(onSystemInfoCall)` 之前插入：
   ```lua
   local ok2, single = pcall(require, 'canon.single.main')
   if ok2 and single and single.enabled and single.system_info then
       onSystemInfoCall({errorCode = 0, httpCode = 200,
                         __prebuilt = single.system_info()})
       return
   end
   ```
   结构在 `canon/single/main.lua` 的 `Single.system_info()` 里（ts=os.time()、
   一个「本地测试服」、serverStatuses）。

   > 坑：最初写的是读 `package.loaded['canon.single.main']`，但登录发生在**第一次业务请求之前**，
   > 那时模块还没被 require 过 → 拿到 nil → 悄悄回退到 HTTP。必须**主动 require**。

3. `deploy_single.py` 新增 `--login`（打 LoginScene 补丁），现在 `--all` 会依次做：
   rpc / Communication / launcher / LoginScene / single/*.lua 五件事。

## 目录/工具现状

| 覆盖文件（Caches/src） | 作用 |
|---|---|
| `launcher.<md5>.lua` | 最前面启动本地 HTTP |
| `canon/single/httpserver.lua` | 本地 HTTP（只支持 ASCII body） |
| `canon/single/http_replay.lua` | 5 个登录端点的响应字节（hex） |
| `canon/single/main.lua` | 服务端骨架 + `system_info()` 合成 |
| `canon/single/handlers_core.lua` | handler 占位（目前 4 个） |
| `canon/request/Communication.<md5>.lua` | 业务请求拦截（已生效） |
| `canon/scene/LoginScene.<md5>.lua` | 跳过 /systemInfo 的 HTTP |

## 下一轮：实现 `login` / `loginServer`

这两个是 S1 的核心 —— 返回玩家完整存档（sharkUser / sharkCards / 队伍 / 关卡进度…）。

**推荐做法：冻结快照**。单机版不需要多账号，直接把当前服务端（`canon.db`）里
这个角色的登录响应**导出一份**，作为初始存档嵌进 APK：

1. 用在线模式（hosts 指向宿主机服务端）跑一次登录；
2. 在 `gameserver.py` 的 `_send` 白名单里加上 `/protocol`，按 method 名落盘
   `login`、`loginServer` 两个响应字节；
3. 生成 hex 表（复用 `gen_http_replay.py` 的思路），在 `handlers_core.lua` 里注册：
   ```lua
   Single.register('login', function() return Single.replay_proto('login') end)
   ```
   —— 但注意 `/protocol` 的响应是 **AMF3 信封**，我们的 Lua 派发层拿到的是
   **A 代码层面的数据表**，不是字节。所以这里要走另一条：把导出的响应**先解码成 Lua 表**，
   再以 Lua 字面量形式嵌进来（`python` 侧解码 + 生成 `.lua` 数据文件）。

   这条路能立刻跑起来；等跑通后再逐步把「静态快照」换成「按操作变更」的实现（S2）。

## 已知限制（写在前面，避免下一轮踩）

- 本地 HTTP 只能发 ASCII：`/staticVersion` 和 5 个 JSON 端点没问题，
  真二进制端点（如 `/systemInfo`）一律走「客户端 Lua 合成」。
- 目前存档是「只读快照」，玩家在游戏里做的操作不会持久化 —— S2 再处理。
