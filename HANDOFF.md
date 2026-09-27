# 《战姬天下》(canon) 复现项目 —— 交接文档

> 目标读者：接手继续调试的 AI/工程师
> 工作目录：`E:\deepseek_projects\app_server`
> 配套详细报告：`ARCHITECTURE.md`（协议/架构/加密 全部实证，请先读它）

---

## 0. 一句话现状

**客户端已经能跑完登录 → 创角 → 新手引导 → 进入主界面 UI 构建（129 张图 / 83 个 group
全部构建成功）；服务端协议全部打通；资源完整性也已确认无缺。**

唯一剩下的阻塞是主界面绘制时的原生崩溃，**已经把范围锁定在「美术字体 `ArtTextField`
渲染路径」**：把 `BaseUIScene.lua:258` 的 `useArtLabelTTF` 改成 `false` 后
**原生 SIGSEGV 完全消失**，只剩一个 Lua `require` 失败需要修（见 §12 P0）。

> 重要修正：早期认为「缺失美术资源导致崩溃」是**错的**。本包美术**没有缺失**——
> manifest 用 `ref` 做了跨目录去重，详见 §9.0。


---

## 1. 项目目标

《战姬天下》是乐元素（Happy Elements）2014 年的三国娘化卡牌手游，已停服。
目标是：拿到 APK → 逆向出服务端接口 → 自写兼容服务端 → 让客户端重新跑起来进主界面。

**合规约束（必须遵守）**：版权属乐元素且公司仍在运营。本项目仅用于个人学习与软件保存，
不得公开运营、不得盈利、不得传播 APK 与解出的资源。

---

## 2. 环境（必须一致，否则结论不成立）

| 项 | 值 |
|---|---|
| APK | `work/zjtianxia_11.0.61_oem5500058.apk`（193,327,619 B，MD5 `00CC40EC4D833A46930E04DC68CFD914`） |
| 包名 | `com.happyelements.canon.baiduDK`（渠道：龙渊/百度多酷，oem_5500058） |
| 版本 | 11.0.61 |
| 模拟器 | **MuMu Player 12**（Android 12 + x86_64 + **Houdini ARM 翻译**）<br>adb serial `127.0.0.1:16384` |
| 为什么必须用 MuMu | 引擎 `libhegame.so` **只有 armeabi-v7a**；Google 官方模拟器 35.x 已移除 ARM guest |
| 另一个设备 | `emulator-5554`（旧的 Google x86 模拟器，**没装本游戏，忽略它**） |
| 构建工具 | `%LOCALAPPDATA%\Android\Sdk\build-tools\36.0.0`（zipalign / apksigner） |
| JDK | `C:\Program Files\Java\jdk-18.0.2.1` |
| 签名 | `work/canon.keystore`（JKS，storepass/keypass `123456`，alias `canon`） |
| 流量劫持 | 模拟器已 root，`/system/etc/hosts` 把游戏域名指向 `10.0.2.2`（宿主） |

`/system/etc/hosts` 当前内容（**若模拟器重启过需要重新确认**）：

```
10.0.2.2  android1.canon.happyelements.cn
10.0.2.2  log.dc.cn.happyelements.com
10.0.2.2  etlog.happyelements.cn
10.0.2.2  android1.canon.happyelements.com
```

⚠️ **每次 `uninstall` + `install` 后，Android 会重新弹「权限确认」对话框**，
必须先点掉（或 `pm grant`）否则游戏根本不会启动，会浪费一整轮测试时间。
对话框「继续」按钮坐标：`input tap 1864 1039`（1920×1080）。

---

## 3. 启动方式

```powershell
# 1) 起服务端（前台会一直输出日志；建议后台跑）
cd E:\deepseek_projects\app_server\server
python canon_server.py
```

服务端监听 **两个端口**：

- `:80` —— HTTP RPC（`/protocol`、`/staticVersion`、`/sessionKey/init` …）
- `:9700` —— **实时 TCP 通道**（帧格式见 §5.2，已逐字节验证）

```powershell
# 2) 装包
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$d = "127.0.0.1:16384"; $pkg = "com.happyelements.canon.baiduDK"
& $adb -s $d install -r E:\deepseek_projects\app_server\work\zjt_pack_signed.apk

# 3) 授权 + 启动
foreach ($p in @("READ_EXTERNAL_STORAGE","WRITE_EXTERNAL_STORAGE","READ_PHONE_STATE",
                 "READ_CONTACTS","RECEIVE_SMS","ACCESS_FINE_LOCATION","CAMERA","GET_ACCOUNTS")) {
  & $adb -s $d shell "pm grant $pkg android.permission.$p"
}
& $adb -s $d shell "monkey -p $pkg -c android.intent.category.LAUNCHER 1"
```

**UI 自动化坐标**（1920×1080，实测可用）：

| 步骤 | 命令 | 说明 |
|---|---|---|
| 游客登录 | `input tap 864 1692` | 登录页右下角 |
| 点名字输入框 | `input tap 576 1152` | |
| 输入名字 | `input text Hero` | 只能 ASCII |
| **提交名字** | `input keyevent 66` | **必须按回车**，否则 IME 挡住「创建角色」按钮 |
| 创建角色 | `input tap 540 1440` | |

---

## 4. 已经跑通的链路（有截图/日志证据）

```
启动 → 资源版本检查 GET /staticVersion
     → 登录页（服务端下发的 serverPartitionConfig 正确渲染：「1区 本地测试服 正常」）
     → 游客登录 → 创角页 → 输入名字 → 创建角色
     → createUser / gameInit 成功
     → 新手引导对话 DialogOnceScene_Script_1
     → 假战斗 BattleScene(kFakeBattle) → On_Battle_Ok
     → DialogOnceScene_Script_2
     → MainMenuScene:create → BaseUIScene:onInit 构建主界面 UI（129 张图 / 83 个 group 全部构建完成）
     → 【卡在这里】绘制阶段原生崩溃
```

服务端侧完整调用序列：

```
GET  /staticVersion
POST /systemInfo
POST /loginAccount/hasVisitorAccount
POST /check/android?
POST /mappingAccount
POST /sessionKey/init
POST /protocol  [login] / [loginServer] / [getMeta] / [geneNickname]
                / [createUser] / [gameInit] / [getMaintenanceMeta]
                / [getAchievements] / [getUserBanInfo]
TCP  :9700      login  -> {"method":"login","retCode":0}
```

---

## 5. 两个必须知道的底层结论（已实证，别再推翻重做）

### 5.0 ⚠️ manifest 文件名每次打包都会变（随机 IV），别被 md5 变化搞混

`patch_lua.py` 重新加密 Lua 时用的是 `os.urandom(16)` 作 AES IV，
所以**即使补丁完全一样，每次运行产出的密文也不同 → 新 md5 → 新的 manifest 文件名**。

`canon_server.py` 启动时会扫描 `work/*.apk`，取 **mtime 最新**的那个 APK 的 manifest，
并通过 `/staticVersion` 下发。因此：

- **每次 `patch_lua.py` 之后必须重启服务端**，否则下发的 md5 与已安装 APK 不一致，
  客户端会走 `dynamicUpdate` 报错。
- 看到 manifest md5 变了**不代表**内容变了，别当成 bug。

### 5.0.1 服务端 `/static/<manifest>` 已修复（原先是 404）

客户端在 `/staticVersion` 之后会立刻来取真实清单文件：

```
GET /static/static_config.<md5>.xml
```

原实现拿请求名去和 **APK 的文件名**（`zjt_pack_signed.apk`）比较，永远不匹配 → 一直 404。
现已改为：从最新 APK 内**读出** `assets/static_config.<md5>.xml` 的真实字节返回，
并已验证 `HTTP 200 / 1,364,460 bytes / 返回内容的 md5 == 文件名里的 md5`。

### 5.1 引擎的失败模型：**未捕获的 Lua 错误 = `SIGKILL` 自己**

引擎任何未捕获 Lua 错误都会写 crash 文件然后 `Process.sendSignal(pid, 9)`。
所以「游戏直接弹出」≈「有一处未捕获的 Lua 错误」。
**唯一例外**：错误发生在**新手引导协程**里时会被**完全静默吞掉**
（`canon/script_and_guide/NewUserGuideCoroutine.lua` 开头自己写了：
「cocoutine中发生错误会直接终止coroutine，不会输出到控制台」）
—— 表现为「纯黑屏、进程存活、0% CPU、仍在 30fps 渲染」，极难查。

### 5.2 实时 TCP 帧格式（抓包 + 逐字节回归验证）

```
帧 = uint32BE 长度 (= 剩余头10字节 + AMF3长度) | 10 字节 0x00 | AMF3 载荷

AMF3 对象编码（客户端自己的编码器行为）：
  0a            object marker
  0b            u29 traits: inline | new-class | dynamic, 0 sealed members
  01            class name "" (u29 (0<<1)|1)
  <key><value>  dynamic members
  01            空 key 结束
```

`TCPManager` 判定 `method=="login" and retCode~=0` 即失败并**立刻重连**（11 秒循环，
导致主界面永不渲染）。所以必须回 `retCode=0`。

---

## 6. 构建流水线

```
zjt_bypass.apk  (SDK 绕过，已存在)
      │  work/patch_lua.py     ← 多文件 Lua 补丁框架（唯一的打包入口）
      ▼
   zjt_run.apk  ==  zjt_pack.apk        (两者内容相同；不再需要资源注入)
      │  zipalign + apksigner
      ▼
   zjt_pack_signed.apk      ← 当前可安装产物
```

```powershell
cd E:\deepseek_projects\app_server\work
python patch_lua.py          # 输出 zjt_run.apk + 打印新 manifest 名
$bt = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0"
& "$bt\zipalign.exe" -p -f 4 zjt_run.apk zjt_pack_signed.apk
& "$bt\apksigner.bat" sign --ks canon.keystore --ks-pass pass:123456 `
    --ks-key-alias canon --ks-type JKS --out zjt_pack_signed.apk zjt_pack_signed.apk
```

> `work/inject_assets.py` **已废弃**（§9.0），流水线只剩这一段。

**⚠️ 每次重打包后必须重启服务端**：`canon_server.py` 启动时自动从**最新的 APK**
里发现 manifest md5 并通过 `/staticVersion` 下发。md5 不匹配客户端会走
`dynamicUpdate` 报错。服务端已改成「取 work 目录下 mtime 最新的 apk」，所以重打包即生效。

### 资源命名规则（两条，都已验证）

| 类型 | 物理名 | manifest 条目 |
|---|---|---|
| Lua | `assets/src/<dir>/<name>.<md5(加密后内容)>.lua` | 只有 `value/md5/size`，**没有 ref** |
| 美术 | `assets/resource/<ref 指向的路径>` | `value/md5/size/required` + **`ref="resource/..."`（关键！）** |

**美术资源必须按 `ref` 解析，不能只看逻辑名去拼路径**——打包器做过去重，
一份物理文件被多个逻辑名复用（§9.0）。这是本项目踩过最大的一个坑。

manifest 自身文件名 = `assets/static_config.<md5(manifest内容)>.xml`，引擎会校验。


### Lua 资源加密（已完全破解）

```
文件 = IV(16) || AES-128-CBC( zlib(lua_source) )      PKCS#7
密钥 = e9747d92cc322e7d112e7c3451d7b36a（运行时从 .bss 读，vaddr 0x6BB02C）
```

`patch_lua.py` 每次补丁都会做 **Lua 块配平校验**（比较补丁前后 `opens-ends` 差值），
配平变化即拒绝出包，避免打坏语法。

---

## 7. 已解决的问题（按发生顺序，含根因）

| # | 现象 | 根因 | 处理 |
|---|---|---|---|
| 1 | 登录走百度 SDK 失败 | 渠道包默认走已停运的百度 SDK | 改 `ThirdPlatformLogin.lua`：`isDKAndroid()→false`、`isPlatformAndroid()→true`，切官方账号通道 |
| 2 | `CreateCharacterScene.lua:152 attempt to call field 'getSixPointIsExist'` | 该函数**本包中不存在**（广告打点死代码，被我们开启官方分支后才执行） | 客户端补丁整块删除 |
| 3 | `Invalid method call. No such method.` @ `CanonEnvInjector:setGspGameUserId` | **luajava 类型不匹配**：dex 签名是 `(java.lang.String)V`，服务端把 `uid` 下发成了 **number** | 服务端 `uid` 改字符串 |
| 4 | `canonUtils.lua:603 pairs(...tutorialSteps)` nil | `gameInit` 缺 `sharkUserExtend` | 服务端补全 28 字段 |
| 5 | `GachaScene.lua:1167` index nil | `getMeta` 缺 `adPictureConfig` | 服务端补全 + 新增 `/static/ad/*.png` |
| 6 | `DataManager.lua:280 sharkCards` nil | `getMeta`/`gameInit` 缺卡牌 | 服务端下发初始卡牌 |
| 7 | `CountryManager.lua:113 missionId` 算术错误 | **空表陷阱**：客户端 `x = 数据; if not x then 自建默认值`，Lua **空表为真**，下发 `{}` 顶掉了客户端默认值 | 服务端改为**不下发**该字段 |
| 8 | `setString(nil)` 类 | `gameSettingConfig`/`battleSettingConfig` **只来自服务端**，无本地兜底 | 服务端补全 38+14 字段 |
| 9 | 主界面纯黑但进程存活、仍在 30fps 渲染 | 错误发生在新手引导**协程**里被静默吞掉 | 用诊断补丁逼出来 |
| 10 | `SOCKET_TCP_CONNECT_FAILURE` 每 11 秒循环 | 实时 TCP 通道未实现 | 服务端实现 TCP 通道 |
| 11 | `LayoutBuilder:221 Sprite:create()` 无贴图精灵 | `CCSprite:create()` 无贴图时 `draw()` 解引用空纹理 | 兜底到真实存在的贴图 |

**通用排查手法（强烈推荐继续用）**：
`hecore/display/CocosObject.lua:74` 的 `ctor` 里检测 `refCocosObj == nil` 并打印
`debug.traceback()`，能把「GLThread 空指针」直接钉到 Lua 调用行。
（注意 `Layer`/`MultiTouchLayer` 是**两段式构造**，`new()` 时本就为空，
随后 `initLayer()` 才挂原生对象 —— 这类日志要人工排除。）

---

## 8. 当前唯一阻塞点（**请从这里接手**）

### 8.1 现象

`BaseUIScene:onInit`（由 `MainMenuScene:onInit:873` 调用）**完整构建完主界面 UI**
（探针实测：129 张图全部创建、83 个 group 全部 build 成功、无任何 Lua 报错），
随后 **GLThread 段错误**：

```
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
  in tid ...: GLThread 63
Cause: null pointer dereference
backtrace: #00 pc 004ae17a  [anon:Mem_0x20000000]   ← Houdini ARM 翻译区，符号不可读
```

崩溃点紧跟在最后一批 `txt/*` group 之后：

```
!!!BUILD_GROUP cast_broadcast folder=shouye_new
!!!BUILD_GROUP txt/shouye_txt_home_broadcast folder=shouye_new
→ SIGSEGV
```

### 8.2 **最新重大突破：关掉美术字体，SIGSEGV 完全消失，而且客户端走得更远了**

`canon/scene/BaseUIScene.lua:257-258`：

```lua
self.builder = LayoutBuilder:createWithContentsOfFile("scene/shouye_new.json")
self.builder.useArtLabelTTF = true          -- ← 就是这一行
self.BaseUi = self.builder:build("shouye_home_menu")
```

把它改成 `false` 后（补丁 `P_disable_artfont`，已在 `patch_lua.py` 的 `PATCHES` 里）：

- ✅ **`Fatal signal` 计数 = 0 —— 原生崩溃彻底消失**
- ✅ **客户端越过了原来的崩溃点**，服务端日志可见它继续往下走：

```
[23:44:05]  POST /protocol  [getGachaBroadcast]      ← DialogOnceScene:onInit:73
[23:44:09]  GET  /static/ad/banner.png  -> 200 (136B image/png)
                                              ↑ GachaScene.preloadAd()，
                                                由 MainMenuScene:326 调用，
                                                即原来崩溃点之后的位置
```

  并且客户端之后持续存活了约 3 分钟（23:43 → 23:46 一直在打 `/restapi.php` 心跳）。

- ❌ 但仍有一个 Lua 报错把进程 SIGKILL 掉：

```
canon/panel/CanonMessageBox.lua:12: module 'hecore.display.CocosObject' not found:
    no field package.preload['hecore.display.CocosObject']
    no file './hecore/display/CocosObject.lua'
    ...
→ Process: Sending signal. PID: ... SIG: 9
```

**结论：原生 SIGSEGV 定位在 `ArtTextField`（美术字体/位图字体渲染器）这条路径上。**
`useArtLabelTTF=true` 时 `LayoutBuilder.buildText`（第 121-122 行）会把所有
**白色静态文本**走：

```lua
text = ArtTextField:create("", builder:getFontFace(symbol.face), symbol.size,
                           CCSizeMake(symbol.width, symbol.height),
                           hAlignment, kCCVerticalTextAlignmentTop)
```

`ArtTextField` 是**原生类**（不在 Lua 里），所以我在 `Sprite`/`CocosObject` 里加的
守卫**完全覆盖不到它**。


### 8.3 关于新出现的 `CocosObject not found`

这不是 manifest/打包 bug —— 已核对：`CocosObject.lua` 的 manifest 条目
md5/size 正确、物理文件 `assets/src/hecore/display/CocosObject.f8b89999....lua` 存在、
且 Lua 条目本来就没有 `ref` 字段。

**最可能的解释**：`MainMenuScene:onInit` 运行在**新手引导协程**里，
而 `CanonMessageBox` 是在那里**首次被惰性 require** 的。
`NewUserGuideCoroutine.lua` 自己注释过：「coroutine 只能保存 lua 状态，不能保存 c 堆栈，
**跨越 c 部分的切换会报错**」—— 在协程里跨 C 边界做 require 会失败。

**建议的第一步修复**：在**协程运行之前**就把这些惰性模块预加载好
（例如在 `launcher.lua` 或 `LoadingScene` 里加一句
`require "canon.panel.CanonMessageBox"`），让 `package.loaded` 里已经有它。

---

## 9. 已经**排除**的假设（别再重复试，会浪费大量时间）

### 9.0 ⭐ 最重要的结论：**这个 APK 的美术资源是完整的，根本不需要找资源包**

manifest 的 `<file>` 条目可以带 **`ref`** 属性，指向**另一个目录下真实存在的物理文件**，
实现「一份图被多个逻辑名复用」。例如：

```xml
<category value="resource/ui_res/shouye_new">
  <file value="shouye_bg_home_common_sb.png" md5="6ada63..." size="2159" required="1"
        ref="resource/ui_res/battleResult_new/battleResult_bg_home_common.6ada63....png" />
</category>
```

`ui_res/shouye_new/` 目录下**确实没有** `shouye_bg_home_common_sb.<md5>.png` 这个文件，
但引擎按 `ref` 去 `battleResult_new/` 取，**文件是存在的**。

我用探针抓到的客户端实际请求的 **20 个「缺失」路径，逐个查 `ref`，结果是 20/20 全部存在**：

| 逻辑名（客户端请求） | ref 实际指向 |
|---|---|
| `shouye_new/shouye_bg_home_common_sb.png` | `battleResult_new/battleResult_bg_home_common.<md5>.png` ✅ |
| `mainmenu_scene_new/dialogue_halfBlack9_pic.png` | `launch_activity/dialogue_halfBlack9_pic.<md5>.png` ✅ |
| `login_new/btn_gold_yellow.png` | `Gvg/btn_gold_yellow.<md5>.png` ✅ |
| `shouye_new/space.png` | `elesoul/space.<md5>.png` ✅ |
| `shouye_btn_home_back_sb.png` | `guild_pk/space.<md5>.png` ✅ |
| …其余 15 个同样全部存在 | 20/20 ✅ |

**所以：没有缺图。** 之前那份「42 张缺失」清单是**因为脚本没有解析 `ref` 属性**造成的假象。

> ⚠️ **两个必须记住的推论**
> 1. **不要再去找资源包**（§10 已彻底排查，且根本不需要）
> 2. `work/inject_assets.py` 不但白做，而且**有害**：它往同一 category 里又插了一条同名
>    `<file>`，造成 manifest 重复声明。客户端日志明确报了：
>    `[parseResourceItemXml|ERROR]:static config error, file resource/ui_res/login_new/btn_gold_yellow.png repeat`
>    —— 所以**那次「注入资源后仍然崩溃」的实验是无效的**，不能作为证据。
>    **该脚本已废弃，不要再运行。**

### 9.1 其余已排除项

| 假设 | 如何排除的 | 结论 |
|---|---|---|
| 缺美术资源导致崩溃 | 见 §9.0：`ref` 解析后 20/20 都存在；且探针实测 129 次取图**全部返回非 NULL 指针** | ❌ **彻底排除** |
| 缺美术是 CDN 下载的、找资源包就能修 | 见 §10 | ❌ 前提不成立（本来就不缺） |
| `Sprite:create` 返回 nil 造成空指针 | `!!!NULL_SPRITE` 守卫计数 = 0 | ❌ |
| 卡面帧 `sdandard.png` 缺失 | 已加 `full.png` 回退补丁，`NO_CARD_FRAME` = 0 | ❌ 不是主因 |
| 主线程死循环 | CPU 0.0%，主线程 sleeping；SurfaceFlinger 显示仍在 30fps 出帧 | ❌ 是「空纹理绘制」不是卡死 |
| 那 42 张「缺失图」都是图片 | 探针显示其中很多其实是**子 group 名**（`kGroup` 类型会递归 `build`） | 认知修正 |


---

## 10. 资源包搜寻结论（**结论：不需要，且已无必要继续**）

因为 §9.0 已证明**本包美术是完整的**（`ref` 去重机制），所以「找资源包」这件事**根本不需要做**。
下面记录已做过的排查，仅供存档：

| 目标 | 结果 |
|---|---|
| **官方 CDN** `android1.canon.happyelements.cn` / `canon.happyelements.cn` | **NXDOMAIN（域名已注销）**。乐元素其他域名仍解析，但该游戏 CDN 子域被删 |
| 七匣子 / 单机100 / 刷机之家 / ARP联盟 | 全是同一套 ~183-184MB 的包；「11.0.65」实为第三方重打包（同一 MD5 `5E476144...`，内置菜单破解版） |
| 换名马甲包 | 《一姬当千：万人斩》v8.0.38（同一游戏） |
| **iOS IPA** | 「战姬天下ios版」**413.95MB**，下载链接经 `n` 分隔 hex 混淆解出 `https://t.appxiazia2021.cn/ios/157922_4`，但**主机已失效**，镜像页 404 |
| Wayback / archive.org | 本机网络**无法访问** archive.org |

**⛔ 不要在这条路上继续投入。**


---

## 11. 文件清单

| 文件 | 作用 |
|---|---|
| `ARCHITECTURE.md` | **详细逆向报告**（协议、加密、386 端点、崩溃链根因、合规声明） |
| `server/canon_server.py` | 兼容服务端：HTTP RPC（headercvt + AMF3 + zlib）+ 实时 TCP 通道。约 1300 行 |
| `work/patch_lua.py` | **多文件 Lua 补丁框架**（解密→正则补丁→块配平校验→重加密→改物理名→改 manifest→重打包） |
| ~~`work/inject_assets.py`~~ | ⛔ **已废弃，不要运行**。它往 manifest 里重复插入同名条目导致客户端解析报错（§9.0） |
| `work/patch_sdk.py` | 最早的 SDK 绕过脚本（已是历史，被 `patch_lua.py` 取代） |
| `work/luasrc/` | **1088 个已解密 Lua**（16.05 MB），逆向主要依据 |
| `work/endpoints.txt` | 386 个 RPC 端点名 |
| `work/zjt_pack_signed.apk` | **当前可安装的产物** |
| `work/logcat_probe.txt` / `logcat_probe2.txt` | 带探针的完整 logcat（含 `!!!IMG_REQ` / `!!!IMG_OBJ`） |
| `work/shot_*.png` | 各阶段截图证据 |

### `patch_lua.py` 里已注册的补丁（`PATCHES` 列表）

| 目标文件 | 作用 |
|---|---|
| `canon/scene/CreateCharacterScene.lua` | 删除广告打点块（nil 调用） |
| `hecore/display/Sprite.lua` | NULL / 无贴图精灵兜底 + 缺失九宫格兜底 |
| `hecore/display/CocosObject.lua` | 诊断：NULL 原生对象打印 traceback |
| `canon/canonUtils.lua` | 卡面帧取不到时回退 `full.png` |
| `hecore/ui/LayoutBuilder.lua` | **探针**：打印每次取图路径 + 检测 NULL 指针 |
| `canon/scene/BaseUIScene.lua` | **关闭 `useArtLabelTTF`**（当前的关键实验开关） |

> 注意：一个文件只能有一个补丁入口 —— `main()` 每个补丁都从**原始资源**重新解密，
> 所以同一文件的多个补丁必须**链式合成一个 builder**（`Sprite.lua` 就是
> `lambda s: P_textureless_sprites(P_null_sprites(s))`）。

---

## 12. 建议的下一步（按优先级）

> 当前产物 `work/zjt_pack_signed.apk`（manifest `0974e263fa5f6d0f9003adc31916756d`）
> 已经包含 `useArtLabelTTF = false` 和全部探针，可直接用来验证 P0。
> **注意**：重打包后必须重启 `canon_server.py`（它启动时从最新 APK 发现 manifest md5）。

### P0 —— 修掉 `CanonMessageBox` 的 require 失败（让 `useArtLabelTTF=false` 这条线跑通）
关掉美术字体后原生 SIGSEGV 已经消失，只剩这个 Lua 报错把进程 SIGKILL 掉：

```
canon/panel/CanonMessageBox.lua:12: module 'hecore.display.CocosObject' not found
```

已核对**不是打包 bug**（manifest 条目 md5/size 正确、物理文件存在、Lua 条目本来就没有 `ref`）。

**最可能的解释**：`CanonMessageBox` 是在**新手引导协程内部**首次被惰性 `require`，
而 `NewUserGuideCoroutine.lua` 自己注释过「coroutine 跨越 C 边界会报错」。

**建议改法**：在协程运行**之前**预加载这些惰性模块。最省事是在
`work/luasrc/launcher.lua`（或 `canon/scene/LoadingScene.lua`）顶部加：

```lua
require "canon.panel.CanonMessageBox"
```

加个补丁即可。**如果这条线跑通，主界面就能显示出来**
（字体从美术字体退化为 TTF，视觉略变但功能正常）。

### P1 —— 或者正面修 `ArtTextField` 路径（希望保留美术字体时走这条）
需要查清 `ArtTextField` 为什么拿不到有效字体图集。线索：

- `LayoutBuilder.buildText:121-122` → `ArtTextField:create("", builder:getFontFace(symbol.face), ...)`
- `LayoutBuilder:getFontFace(designedFont)`（第 298-302 行）查 `self.fontMapping` 和
  `globalFontMapping`
- ⚠️ **疑似上游 bug**：`addFontFace` / `addGlobalFontFace`（第 291-296 行）实现是
  `map[designedFont] = designedFont`，**把 `mappingTo` 参数丢掉了**

建议加探针：打印 `symbol.face`、`getFontFace` 的返回值、以及 `ArtTextField:create` 之后
对象的指针（`tostring(refCocosObj)`），确认是不是拿到了空字体图集。

> 备选思路：`ArtTextField` 是原生类。若确认它拿到空图集，可以考虑给
> `useArtLabelTTF` 做**按 face 白名单**（只对确实可用的 face 开启），而不是全局关掉。

### P2 —— 若主界面能显示，继续往下推
主界面之后的战斗 / 背包 / 公会等仍需要服务端补数据
（386 个端点目前只实现了一小部分）。


---

## 13. 常见坑速查

1. **`amd uninstall/install` 后权限对话框** → 不点掉游戏不启动，白等一轮。
2. **重打包后没重启服务端** → `/staticVersion` 下发旧 md5 → 客户端走 `dynamicUpdate` 报错。
3. **`mainmenu_scene_new` vs `shouye_new`** → 主界面真正用的是 **`shouye_new`**
   （`BaseUIScene:257`），不是 `mainmenu_scene_new`。先看探针日志确认 folder 再判断。
4. **待机/锁屏** → 截图会全黑（12504 字节），别误判成「渲染黑屏」。先 `input keyevent 224` 唤醒。
5. **`screencap` 用 `exec-out > file` 会被 PowerShell 破坏** → 用
   `screencap -p /sdcard/x.png` + `adb pull`。
6. **ADB 有两个设备** → 所有命令必须 `-s 127.0.0.1:16384`。
7. **`adb shell "pidof $pkg"` 在嵌套引号里变量不展开** → 先 `$p = (& $adb ... ).Trim()`。
8. **本机无法访问 archive.org / web.archive.org**（连接层失败），别在这上面耗时间。
9. **manifest 文件名每次打包都变**（随机 IV）→ 重打包后**必须重启服务端**（见 §5.0）。
10. **可能有人在并发操作这个工作区**：曾观察到 `from_device.apk` 以及非本会话发起的
    重新打包 / python 进程被杀。若发现服务端无故退出、APK 被重建，先确认是否有别的
    会话（例如 Cursor）在同时跑，别盲目归因。

