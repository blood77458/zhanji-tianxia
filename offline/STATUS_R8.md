# 第 8 轮记录：**S1 可交付 APK 达成（真断网验证通过）**

## 成果

work/out/战姬天下_单机版_S1.apk（184 MB，v1/v2/v3 签名通过）

**验证条件（最严格）**：
- 卸载后全新安装（/data/data 全清，Caches/src 覆盖层不存在）
- 设备 hosts 只留 localhost（所有 canon/happyelements 域名不可解析）
- 宿主机 Python 服务端**已停**
- 启动 → 点过兼容提示 → 游客登录 → **完整主界面**

截图：work/uitest/offline_final1.png
- 进程存活，unhandled = 0，errorlogs 为空

## 打包内容（scripts/pack_single_apk.py）

| 动作 | 内容 |
|---|---|
| 新增 | ssets/src/canon/single/{main,handlers_core,httpserver,http_replay,proto_data}.lua（按 APK 同款 AES+zlib 加密） |
| 替换 | ssets/src/launcher.* / canon/request/Communication.* / canon/scene/LoginScene.* / hecore/rpc.* |
| 修改 | ssets/StartupConfig.plist：gameDomain 与 StaticSettingsUrl → http://127.0.0.1:18080 |
| 打包 | zip 重写 → zipalign -p 4 → pksigner（keystore work/canon.keystore / 123456 / canon） |

> 关键结论：**引擎能直接加载新增的 ssets/src/canon/single/*.lua，不需要登记进
> static_config.xml**（之前担心的清单问题不存在）。

## 当前能力边界（重要，别高估）

现在能离线跑通的只有「启动链路」：
- 资源检查（/staticVersion）、5 个登录直连端点（回放）、systemInfo（本地合成）
- 14 个 /protocol 方法（静态快照）：login / loginServer / gameInit / getMeta /
  getMaintenanceMeta / getHomeInfo / getAchievements / getUserBanInfo / getSocketServer /
  getAnnouncementInfo / getMultiplayserBossInfo / getUserUnionInfo /
  getServerTimeStamp / recordTutorialStep + getSharkBeasts / getSharkBeastFragments

**未覆盖**：背包、武将、队伍、关卡、战斗、活动、商城、军团、竞技……点进去会走
unhandled → 回 {retCode:200} 空壳，界面多半空白或报错。存档也是只读快照，
游戏内的操作不会持久化。

## 下一轮（S2）

1. 用 scripts/single_iter.py 反复迭代，把「背包 / 武将 / 队伍 / 关卡 / 战斗结算」
   这些入口会请求的方法补进快照；
2. 每补一批就 pack_single_apk.py --install 打一次包验证（现在打包很便宜，
   一次 ~1 分钟）；
3. 战斗这块要注意：	riggerBattleEvent 返回的是事件流，静态快照只能重复同一场战斗，
   要真正「能打」必须把战斗逻辑移植到 Lua（把 server/services/battle.py 的算法
   翻成 Lua）。这一步工作量最大，放在 S2 后期。
