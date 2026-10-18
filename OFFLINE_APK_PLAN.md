# 单机版 APK 方案（服务端内置）

> 目标：一个**断网可玩**的 APK —— 不连电脑、不连模拟器宿主、不需要 Python 进程，服务端逻辑跑在 APK 内。

---

## 一、可行性：已把关键点全部探明

### 1.1 唯一网络出口 `HTTPChannel:send()` —— 可替换【已确认】

`hecore/rpc.lua`：

```lua
HTTPChannel = class(EventDispatcher)
function HTTPChannel:send(url, bytes, timeout, retryTimes, aMethod)
    local request = HttpRequest:createPost(url)      -- 唯一的真实网络动作
    ...
    channel:dispatchEvent(Event.new(ChannelEvent.kComplete, response, channel))
end
```

- 上层只认 `ChannelEvent.kComplete` + `response.body`（`rpc.lua:374 local bytes = http_response.body`）；
- `ChannelRegistry` 存在，说明 channel 本来就是可插拔的；
- **所以只要实现一个 `LocalChannel:send()`：不建 HttpRequest，直接把响应塞回 `{httpCode=200, body=bytes}` + dispatch kComplete**，全客户端就会以为服务端回话了。

### 1.2 编解码在 Lua 侧全都有【已确认】

| 需要的能力 | 客户端是否已具备 |
|---|---|
| AMF3 编码/解码 | ✅ 引擎 C 模块 `amf3.encode` / `amf3.decode`（`rpc.lua:885/889` 就是这么用的） |
| zlib 压缩/解压 | ✅ `require "hecore.zlib"`（`rpc.lua:6`），纯 Lua 实现，同样用于收发 |
| XOR 混淆 | ✅ 只是逐字节异或（0xC3 / 0x71），Lua 里几行 |
| 信封 | ✅ `body = headercvt(zlib(amf3(payload)))` |

**结论：不需要在 APK 里塞 Python、不需要 native server，纯 Lua 就能顶替服务端。**

### 1.3 打包工具链【已确认存在】

| 工具 | 位置 |
|---|---|
| `apktool.jar` | `tools/apktool.jar` |
| `apksigner` / `zipalign` | `%LOCALAPPDATA%\Android\Sdk\build-tools\36.0.0\` |
| keystore | 工作区里的 `canon.keystore` |
| Java | `C:\ProgramData\Oracle\Java\javapath\java.exe` |

---

## 二、架构

```
APK
├── assets/src/…                 原客户端 Lua（不动）
├── assets/src/hecore/rpc.lua    ★ 打补丁：HTTPChannel → LocalChannel
├── assets/src/canon/single/     ★ 新增：单机服务端（纯 Lua）
│   ├── dispatcher.lua             方法名 → handler 路由
│   ├── state.lua                  玩家存档（读写 cc.UserDefault / 本地文件）
│   ├── codec.lua                  XOR + zlib + amf3 + 信封
│   └── handlers/*.lua             各业务端点
└── assets/resource/…            原资源（本来就在包里）
```

一次请求的流转（全部在 Lua 里同步完成）：

```
BaseRequest → RpcTransponder → ChannelRegistry → LocalChannel:send(url, bytes)
  → codec.unpack(bytes)                 -- XOR 0xC3 → inflate → amf3.decode
  → dispatcher.dispatch(method, params) -- 等价于我们 Python 服务端的 endpoint
  → codec.pack(resp)                    -- amf3.encode → deflate → XOR 0x71
  → dispatchEvent(ChannelEvent.kComplete, {httpCode=200, body=…})
```

### 资源/版本校验也要本地化

客户端启动会走「正在检查资源更新」。单机版把它接管成固定应答（无更新、manifest md5 用包内值），
否则会卡在网络错误弹窗。

---

## 三、分阶段实施（每阶段都可独立验证、可交付）

| 阶段 | 内容 | 验收标准 | 规模 |
|---|---|---|---|
| **S0** | `LocalChannel` + `codec` + `dispatcher` 骨架；接管「检查资源更新」 | 断网启动不再弹「网络不好」 | 3 个文件 |
| **S1** | 登录 / 创角 / 新手引导 / 主界面所需端点 + `state.lua` 存档 | **断网能进主界面，角色可创建、可保存** | 约 25~30 个端点 |
| **S2** | 背包 / 武将 / 队伍 / 装备 / 强化 / 升级 / 关卡 / 战斗 / 结算 | 断网能推图打完一场战斗 | 约 60 个端点 |
| **S3** | 活动 / 商城 / 抽卡 / 邮件 / 竞技场 / 军团 … 其余 | 主要入口点开不崩、不闪退 | 剩余 ~250 个 |
| **S4** | 打包：apktool 回编译 + zipalign + apksigner 签名 | 独立安装、断网可玩 | — |

### 为什么不能一次做完

Python 服务端有 **397 个 endpoint**，其中相当一部分依赖「服务端才有的状态」
（跨服、排行、军团成员、活动进度）。单机版要么用本地假数据替代，要么关掉入口。
这是逐项移植的工作量，不是几小时能收尾的；但**每一阶段都能独立跑起来**，
而且 S0/S1 做完就已经是「能进游戏的单机 APK」，后面的阶段只是把可玩面做大。

---

## 四、打包细节（S4 预研）

1. **改哪些文件**：`assets/src/` 下新增 `canon/single/*.lua`；`hecore/rpc.*.lua` 打补丁。
2. **文件名规则**：引擎按 `<逻辑名>.<md5(密文)>.lua` 找文件。两种落法：
   - 保守：沿用原文件名覆盖 + 新增文件按「明文 md5」命名（引擎对此并不校验内容 md5，实测 `Caches/src` 里名字随意也能加载）；
   - 稳妥：改 `assets/static_config.<md5>.xml` 里的清单 —— **注意文件名里的 md5 是清单内容算的**，改了必须同步改名。
3. **加密**：新增 Lua 必须用同一套 `IV ‖ AES-128-CBC(PKCS#7(zlib))` 加密（key 已知）。
4. **签名**：`zipalign -p 4 in.apk out.apk` → `apksigner sign --ks canon.keystore`（v1+v2 都签，MuMu/Android 12 才认）。
5. **不复用旧 APK 的签名**：签名不同装不上，需要先卸载原包（存档在 `/data/data/<pkg>`，卸载会清档）。

---

## 五、风险与取舍

| 风险 | 说明 | 应对 |
|---|---|---|
| 存档落在 `cc.UserDefault` | 卸载/清数据即丢档 | 加「导出存档」入口（写 SD 卡） |
| 部分玩法天生需要多端 | 军团、竞技场、跨服、排行 | 单机版用本地假数据或直接关入口（维护项里关掉） |
| 客户端偶发依赖服务端节流 | 请求并发/重试 | `LocalChannel` 可以同步返回，反而更稳 |
| 397 个端点覆盖面 | 见 §3 | 分阶段，先保证主干可玩 |
| 版本升级 | 包一旦改动，后续官方数据无从对照 | 保留 `client/` 原始 APK 只读副本 |

---

## 六、下一步（按顺序）

1. S0：写 `canon/single/codec.lua` + `localchannel.lua` + `dispatcher.lua`，先用 `Caches/src` 热补丁在模拟器上验证「不连服务端也能启动到登录页」。
2. S1：把 `server/api/handlers.py` 里主界面链路对应的端点逐个翻成 Lua，存档落本地。
3. 之后按 S2/S3 推进，最后 S4 打包。
