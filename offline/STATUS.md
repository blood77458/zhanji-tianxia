# 单机 APK 进度（S0 基本完成）

> 目标见 `OFFLINE_APK_PLAN.md`。这里是实际推进记录，接手先读它。

## 结论速览

| 环节 | 状态 |
|---|---|
| 重打包 + zipalign + apksigner（v1/v2/v3） | 可用，产物能装能跑 |
| 域名重定向到 `127.0.0.1` | **已验证生效** |
| APK 内本地 HTTP 服务（luajava） | 可用，已应答资源检查 |
| 资源检查（native）离线通过 | 无端口转发也通过 |
| 登录页 | 能到 |
| 游客登录链路 | 卡在 `/systemInfo` 等直连 HTTP 端点 |

## 1. 域名重定向（关键解锁）

`assets/StartupConfig.plist` 里两行改成 `http://127.0.0.1:18080`：
`gameDomain`、`StaticSettingsUrl`。引擎首次运行会把它复制到
`/data/data/<pkg>/files/StartupConfig.plist`，之后读副本（**两处都要对**）。

**验证方法**（不要再用「改完还能进登录页」当证据，那可能是走 hosts）：
撤掉 `adb reverse tcp:18080`、保留 hosts，启动后服务端**收不到** `/staticVersion`
→ 说明客户端确实在连 `127.0.0.1:18080`，plist 生效。已实测。

## 2. APK 内本地 HTTP（`offline/lua/canon/single/httpserver.lua`）

- `luajava.newInstance('java.net.ServerSocket', 18080)`；
- **不建 Java 线程**：`setSoTimeout(2)`，每帧在主线程 `accept()`，超时异常用 pcall 吃，
  Lua 状态只在主线程碰，安全；
- 启动点挂在**最早的 Lua 入口** `launcher.lua` 最前面（必须在 `ResourceLoader.init()` 之前，
  `deploy_single.py --launcher` 会自动插）；
- `/staticVersion` 回：
  ```json
  {"static_url_root":"http://<host>/static/","config_md5":"81c8ede8d76998cd852173d537c04aac",
   "need_download":false,"can_download":false,"download_url":"",
   "langs":["zh_CN"],"resolutions":["1280x720"],"ref":0}
  ```
  `config_md5` 必须等于 APK 内 `static_config.<md5>.xml` 的 md5。

实测日志（**此时 adb reverse 已撤掉**）：
```
[SINGLE-HTTP] listening on 127.0.0.1:18080
[SINGLE-HTTP] GET /staticVersion      <- 资源检查被本地应答
[SINGLE] Communication loaded from overlay
[SINGLE-HTTP] GET /systemInfo
```
→ 客户端顺利到了登录页。

> 补充：整包只有 `/staticVersion` 这一个资源相关请求，**没有任何 `/static/*` 下载**。
> 所以资源更新这块只需一个 20 行的 HTTP 应答，不需要实现文件服务。

## 3. 现在的卡点：登录直连 HTTP 端点

点「游客登录」后弹「网络不好」。原因是登录链路走
`canonUtils.doHttpRequest` / `AndroidPlatformLogin` 的**直连 HTTP**（不经过 `Communication`），
对应我们 Python 服务端这些路由（`server/gameserver.py`）：

```
GET  /systemInfo
POST /sessionKey/init
POST /check/*              （平台校验）
POST /mappingAccount
POST /loginAccount/hasVisitorAccount
POST /loginAccount/*
```

它们返回 **AMF3 + zlib + XOR(0x71)** 的二进制信封，Lua 里要现编现解。

### 下一轮方案（推荐：抓包回放）

这些端点的应答**与请求基本无关、是常量**（不像 /protocol 会随玩家状态变），所以：

1. 用在线模式（hosts 指向宿主机服务端）跑一遍游客登录；
2. 在 Python 服务端把这些 URL 的**响应字节原样落盘**到 `work/http_capture/`；
3. 打进 APK `assets/single/http/<key>.bin`；
4. 本地 HTTP 服务按路径回放对应字节，找不到就 404 并打日志。

这样登录链路零编解码成本。唯一需要动态的是 `/protocol` —— 它已经在
`Communication:request` 层被拦下，走 Lua 表直接派发（`canon/single/main.lua`），不需要信封。

### 备选：Lua 里实现完整信封

`amf3.encode`（引擎自带）+ `hecore.zlib` compress + headercvt
（`00 64 ‖ md5(C16‖X) ‖ X`，`X = data ^ 0x71`，C16 = `255e262a4051306a6533356937717039`），
需要 Lua 侧能算 md5。工作量比回放大得多。

## 4. 下一轮 TODO

1. 恢复 hosts 在线模式，抓这 6 个登录端点的响应字节；
2. 扩展 `httpserver.lua`：按路径回放字节（含 `/protocol` 之外的兜底日志）；
3. 登录通过后 `[SINGLE] unhandled <method>` 会开始刷屏 —— 那就是 S1 的 handler 清单，
   照 `server/api/handlers.py` 逐个翻成 Lua（存档先放 `CCUserDefault`）；
4. 能进主界面后，把 `offline/` 的 Lua 和 plist 一起打进 APK（扩展 `repack_apk.py`），
   出 S1 的可交付包。

## 5. 设备当前状态

- 装的是自己签的 `work/out/canon_single.apk`（apksigner verify: v1/v2/v3 通过）；
- `files/StartupConfig.plist` 已指向 `127.0.0.1:18080`；
- `adb reverse` 已撤（18099 探针还在跑，可随时清理）；
- hosts 仍在（含 `android1.canon` 等 5 条）—— 下一轮抓包需要它；
- 客户端当前停在登录页背后的「网络不好」弹窗，进程存活（无崩溃）。

## 6. 已部署到设备上的单机层文件（Caches/src 覆盖）

| 路径 | 作用 |
|---|---|
| `canon/single/main.lua` | 服务端骨架：注册/派发/结果投递 |
| `canon/single/handlers_core.lua` | 核心 handler 占位 |
| `canon/single/httpserver.lua` | 本地 HTTP（资源检查） |
| `canon/request/Communication.<md5>.lua` | 请求拦截（业务请求走 Lua 派发） |
| `launcher.<md5>.lua` | 启动本地 HTTP |
| `hecore/rpc.<md5>.lua` | 备用拦截（当前未生效，hecore 加载太早） |
