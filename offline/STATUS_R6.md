# 第 6 轮记录：S1 快照机制成型（13 个方法已冻结）

## 做了什么

### 1. 不再依赖模拟器 UI 抓包 —— 改成服务端直接合成

新脚本 `scripts/gen_proto_snapshot.py`：直接调 `api.dispatch(...)`
（跟 `gameserver.rpc()` 里完全相同的入口），把一批方法的响应写成
`work/proto_capture/<method>.json`。不用开客户端、不用点界面。

踩到两个坑（都修了）：

| 坑 | 现象 | 修法 |
|---|---|---|
| 会话表名猜错 | 查 `player_session` / `account_session` 都返回 None → `session_key=None` | 实际表是 **`auth_session`**：`SELECT * FROM auth_session WHERE player_id=? AND revoked=0` |
| 没载入 handler | 14 个方法全返回 `{retCode:200}`（16 字节空壳） | 不跑 `main()` 时 `REGISTRY` 是空的，脚本里必须 `api.load_handlers()` |

### 2. JSON → Lua 数据（`scripts/gen_proto_lua.py`）

输出 `offline/lua/canon/single/proto_data.lua`，转换规则：

- JSON array → Lua **序列表** `{a, b, c}`（客户端用 `ipairs` 遍历，必须是序列）
- JSON object → 键表 `{['k'] = v}`
- JSON null → 直接丢掉（Lua 里写 nil 没意义）
- 空对象/空数组 → `{}`

本轮生成 13 个方法 / 142,056 字符：

```
getMeta 119366 | getMaintenanceMeta 19952 | getHomeInfo 852
getAchievements 674 | getMultiplayserBossInfo 486 | getAnnouncementInfo 265
getSocketServer 132 | loginServer 82 | getUserBanInfo 64
getUserUnionInfo 60 | getServerTimeStamp 59 | login 32 | recordTutorialStep 32
```

> `login` 只有 32 字符是**正常的**：`h_login` 本来就返回 `{}`，
> 客户端只要求 `retCode=200`（见 handlers.py 的注释）。

### 3. 注册成 handler（`handlers_core.lua`）

- 遍历 `proto_data` 逐个 `Single.register(method, ...)`；
- 每次调用返回**深拷贝**（客户端会就地改这些表，模板不能被动过）；
- `getServerTimeStamp` 例外，动态返回 `os.time()`（否则体力/冷却判断会错乱）。

实测日志：

```
[SINGLE] main.lua loaded
[SINGLE] snapshot handlers registered: 13
[SINGLE] single-player server ready, handlers=13
[SINGLE-HTTP] POST /loginAccount/hasVisitorAccount -> replay (67 bytes)
```

## 下一轮

1. 点游客登录，看 `login` / `loginServer` 之后还会撞哪些方法
   （日志里的 `[SINGLE] unhandled <method>` 就是清单）；
2. 把缺的方法加进 `gen_proto_snapshot.py` 的清单，重跑两个脚本 + `deploy_single.py --lua`
   （**不用重新打包 APK**，走的还是 Caches/src 覆盖）；
3. 直到能进主界面为止，然后把 `offline/lua/**` + 改过的 plist 一起打进 APK 出 S1 包。

## 重要提醒

`getMeta`（62KB JSON / 119K 字符 Lua）是客户端启动的关键大包。
它现在是从服务端 `canon.db` 冻结的 —— 如果之后改了服务端 meta，记得重跑两个生成脚本。
