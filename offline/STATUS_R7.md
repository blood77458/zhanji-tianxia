# 第 7 轮记录：**S1 达成 —— 离线进主界面**

## 结果

客户端在**只依赖 APK 内 Lua 单机层**的情况下，完整走到主界面：
主界面所有元素正常渲染（任务/活动/奖励/求将/求宝/商城、竞技/演武、角色卡、
底部导航、战斗力 2809、吃桃横幅）。

截图证据：`work/uitest/boot_1792292467.png`

### 配套证据

| 项 | 值 |
|---|---|
| 进程 | 存活（pid 20701） |
| 未实现方法（`unhandled`） | **0 个** |
| 崩溃/错误日志 | **无** |
| 全部请求走本地 | `[SINGLE-HTTP] replay /loginAccount/hasVisitorAccount`、`/check/android`、`/mappingAccount`、`/sessionKey/init` |
| 快照 handler | `snapshot handlers registered: 14` |

## 本轮改动

1. **新增 `scripts/single_boot.py`**：一键「重启客户端 → 点掉兼容提示 → 游客登录 →
   收集 `unhandled` 清单 → 截图/日志」。这是迭代的主工具。
2. **新增 `scripts/single_iter.py`**：自动循环「boot → 收集 unhandled → 补快照 →
   重新生成 → 重部署」，收敛即停。新方法记录在 `work/proto_methods.txt`。
3. `gen_proto_snapshot.py` 支持从 `work/proto_methods.txt` 读取附加方法。
4. **踩坑修复：点一次「游客登录」不生效** —— 兼容提示关掉后的第一次点击会被吞掉，
   必须连点两次（间隔 2s）。这一条已写进 `single_boot.py`。

## 快照清单（14 个方法，197,964 字符）

```
login / loginServer / gameInit / getMeta / getMaintenanceMeta / getHomeInfo
getAchievements / getUserBanInfo / getSocketServer / getAnnouncementInfo
getMultiplayserBossInfo / getUserUnionInfo / getServerTimeStamp / recordTutorialStep
+ getSharkBeasts / getSharkBeastFragments（work/proto_methods.txt）
```

## 距离「可交付 APK」还差什么

**当前单机层只存在于设备的 `Caches/src` 覆盖目录里**，全新安装的 APK 里没有。
所以下一步必须把下面这些打进 APK：

| 要打进 APK 的东西 | 目标位置 |
|---|---|
| `offline/lua/canon/single/{main,handlers_core,httpserver,http_replay,proto_data}.lua` | `assets/src/canon/single/`（需加密，与 APK 内其它 Lua 同格式） |
| 打过补丁的 `launcher` / `Communication` / `LoginScene` | 覆盖 `assets/src/...` 同名文件 |
| 修改过的 `StartupConfig.plist` | `assets/StartupConfig.plist`（已实现于 `repack_apk.py`） |

`repack_apk.py` 目前只改 plist，需要扩展成「替换/新增若干 assets 条目」。

### 打包前要验证的一件事

引擎解析 **新增** 的 Lua（`canon/single/*.lua`）时，是否也走
`assets/static_config.<md5>.xml` 清单？如果走，新增文件必须同时登记进清单
（且文件名里的 md5 是清单内容算的，改完要同步改名）。验证方式：
先在模拟器上**卸载重装**打包好的 APK（Caches 会被清空），看能否进主界面。

### 另一个待确认项（真断网）

日志显示客户端仍会访问 `rest_v3/...`、`restapi.php`（百度 SDK / 日志上报），
这些走 hosts 到宿主机。真断网时它们会失败 —— 从目前表现看是**非阻塞**的
（游客登录和进主界面都成功了），但要在完全无网的环境下再跑一遍确认。

## 下一轮计划

1. 扩展 `repack_apk.py`：把单机层 Lua + 三个补丁文件 + plist 一起写进 APK；
2. 卸载重装验证（Caches 清空 → 只剩 APK 内资源）；
3. 若新增 Lua 加载失败 → 把 `canon/single/*` 登记进 `static_config.xml` 并同步改名；
4. 通过后即为 **S1 可交付 APK**，再继续 S2（背包/战斗）。
