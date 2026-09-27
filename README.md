# 战姬天下 · 本地复现包（服务端 + 客户端）

乐元素《战姬天下》（内部代号 **canon**）停服后的**个人学习 / 软件保存**项目：自研兼容服务端 + 已打补丁的客户端 APK，可在本机 MuMu 模拟器上完整登录、养成、活动、转生等。

> **合规**：版权属乐元素。仅限个人私有使用，禁止公开运营、盈利或传播 APK / 解包资源。请将本仓库保持为 **Private**。

---

## 目录结构

```
app_server/
├── README.md                 ← 你正在读的使用说明
├── NOTICE.md                 ← 版权与免责声明
├── requirements.txt          ← Python 依赖（可选 Pillow）
├── ARCHITECTURE.md           ← 协议 / 架构逆向报告（进阶）
├── HANDOFF.md                ← 开发交接笔记（进阶）
├── server/                   ← 兼容服务端（开箱即用）
│   ├── canon_server.py       ← HTTP :80 + TCP :9700
│   ├── features.py           ← 养成 / 转生 / 活动等业务
│   ├── admin_api.py + admin.html + card_dict.json
│   └── start_server.bat      ← 一键启动
├── client/                   ← 客户端说明（APK 见 Release）
│   └── README.md
└── work/
    ├── luasrc/canon/configs/ ← 服务端读的卡牌/关卡等配置（必需）
    ├── patch_lua.py          ← 重新打补丁用（可选）
    ├── canon.keystore        ← APK 签名（本地调试）
    └── hosts_*.txt           ← 模拟器 hosts 示例
```

**账号是否共享？**  
服务端用本地文件 `server/user_state.json` 存档（**不是 SQL 数据库**）。每人各自跑服务端 = 各自独立账号；多人连同一台服务端 = 共享同一份存档。

---

## 一、环境要求

| 项 | 建议 |
|----|------|
| 系统 | Windows 10/11（本仓库按此验证） |
| Python | 3.10+（标准库即可跑服；管理页头像建议装 Pillow） |
| 模拟器 | **MuMu 模拟器 12**（Android 12 + x86_64 + **Houdini ARM 翻译**） |
| 为什么必须 MuMu | 游戏原生库 `libhegame.so` **只有 armeabi-v7a**；官方 Google 模拟器新版本已去掉 ARM guest |
| adb | Android SDK platform-tools，或 MuMu 自带 adb |
| 权限 | 服务端需监听 **80** 端口（可能需管理员权限） |

可选依赖：

```bat
pip install -r requirements.txt
```

---

## 二、启动服务端

1. 打开终端，进入 `server` 目录：

```bat
cd /d <本仓库>\server
start_server.bat
```

或：

```bat
set CANON_MANIFEST_MD5=81c8ede8d76998cd852173d537c04aac
python -u canon_server.py
```

2. 看到类似日志即成功：

- HTTP 监听 `0.0.0.0:80`
- TCP 监听 `0.0.0.0:9700`

3. 本机浏览器打开管理页：

- [http://127.0.0.1/admin](http://127.0.0.1/admin)  
  可改金币/元宝/VIP、加删武将、调等级等。

**重要**：`CANON_MANIFEST_MD5` 必须与客户端 APK 内 `assets/static_config.<md5>.xml` 一致。  
当前推荐客户端对应：`81c8ede8d76998cd852173d537c04aac`。若你重新打了补丁，请用新 MD5 覆盖该环境变量。

### 防火墙

若模拟器在另一台机器，需放行宿主 **80** 与 **9700**，并把下方 hosts 里的 IP 改成宿主机局域网 IP。

---

## 三、准备客户端 APK

仓库**不包含** 193MB 的 APK（超过 Git 单文件限制）。请：

1. 打开本仓库 **Releases**，下载 tag（如 `v1.0.0`）附件  
   `zjt_pack_enablefix_signed.apk`，放到 `client\` 目录；或  
2. 若你从完整开发目录拷贝，本地已有：

```bat
copy work\zjt_pack_enablefix_signed.apk client\zjt_pack_enablefix_signed.apk
```

包名：`com.happyelements.canon.baiduDK`  
版本：11.0.61（渠道 oem_5500058，已打本地支付 / 活动 / 崩溃修复等补丁）

---

## 四、配置模拟器 hosts（流量指到本机）

游戏会请求：

- `android1.canon.happyelements.cn`
- `android1.canon.happyelements.com`
- 以及若干日志域名

在 **已 root** 的 MuMu 里改 `/system/etc/hosts`，把它们指到宿主：

| 场景 | hosts 里写的 IP |
|------|-----------------|
| MuMu（常见） | 宿主在模拟器里的地址，多为 `10.0.2.2`；部分 MuMu 版本用 `172.x`（见 `work/hosts_mumu.txt`） |
| 官方 emulator | `10.0.2.2` |

示例（MuMu 指向宿主回环映射）：

```
10.0.2.2  android1.canon.happyelements.cn
10.0.2.2  android1.canon.happyelements.com
10.0.2.2  log.dc.cn.happyelements.com
10.0.2.2  etlog.happyelements.cn
```

可用 adb（按你的 MuMu adb 端口改串号，常见 `127.0.0.1:16384`）：

```bat
adb -s 127.0.0.1:16384 root
adb -s 127.0.0.1:16384 remount
adb -s 127.0.0.1:16384 push work\hosts_emu.txt /system/etc/hosts
```

改完 hosts 后如仍连不上，在模拟器里 `ping` 上述域名，确认解析到宿主。

---

## 五、安装并启动游戏

```bat
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set DEV=127.0.0.1:16384
set APK=client\zjt_pack_enablefix_signed.apk
set PKG=com.happyelements.canon.baiduDK

"%ADB%" -s %DEV% install -r "%APK%"
"%ADB%" -s %DEV% shell am start -n %PKG%/com.happyelements.arda.MainActivity
```

首次安装会弹出权限确认，需点「继续」，或：

```bat
"%ADB%" -s %DEV% shell pm grant %PKG% android.permission.READ_EXTERNAL_STORAGE
"%ADB%" -s %DEV% shell pm grant %PKG% android.permission.WRITE_EXTERNAL_STORAGE
```

（具体权限以系统弹窗为准。）

---

## 六、游玩流程（预期行为）

1. 启动后走登录 / 创角 / 新手引导 → 进入主界面。  
2. **充值**：客户端已 patch 为本地校验，点充值会走服务端发元宝，无需真实支付。  
3. **活动 / 签到 / 领将**：服务端已对接；部分未实装活动在客户端侧做了保护，避免闪退。  
4. **武将养成 / 升级 / 转生**：转生按配置 `evolutionCardId` 升阶（不再卡在 +4）。  
5. **管理页**：浏览器打开 `/admin` 可直接改号、发将。

存档文件：`server/user_state.json`（备份/换号/多人分档都复制此文件即可）。

---

## 七、常见问题

| 现象 | 处理 |
|------|------|
| 动态更新 / `dynamicUpdateNetError` | `CANON_MANIFEST_MD5` 与 APK 内 manifest 不一致；对齐 MD5 或重打补丁 |
| 一直转圈 / 连不上服 | 检查服务端是否在跑；hosts 是否指向正确 IP；80 端口是否被占用 |
| 安装后闪退 | 确认用的是 `zjt_pack_enablefix_signed.apk`，不要用未签名或旧的 broken 包 |
| 冒充「缺图」崩溃 | 本包美术完整；若仍崩，抓 logcat 查 Lua error |
| 管理页武将图是色块字 | 正常：原 head 为 HQCE 加密，服务端用 Pillow 生成占位头像 |
| 换电脑后号没了 | 拷贝 `server/user_state.json` |

端口占用（PowerShell）：

```powershell
netstat -ano | findstr ":80 "
netstat -ano | findstr ":9700 "
```

---

## 八、（可选）自己重新打客户端补丁

需要：`pycryptodome`、JDK、Android build-tools（zipalign / apksigner）、底包 APK。

```bat
pip install pycryptodome
python work\patch_lua.py
rem 再 zipalign + apksigner（keystore: work\canon.keystore，密码 123456，alias canon）
```

打完后读出新的 `static_config.<md5>.xml` 文件名中的 md5，启动服务端时设置：

```bat
set CANON_MANIFEST_MD5=<新md5>
```

---

## 九、给协作者的最短路径

```bat
git clone <本仓库 URL>
cd app_server
pip install -r requirements.txt
rem 从 Release 下载 APK 到 client\
cd server
start_server.bat
rem 另开终端：配置 hosts → adb install client\*.apk → 启动游戏
```

进阶协议细节见 `ARCHITECTURE.md`；开发踩坑见 `HANDOFF.md`。

---

## Tag / 版本

| Tag | 说明 |
|-----|------|
| `v1.0.0` | 首个可玩打包：服务端 + 配置 + 说明；APK 在 Release 附件 |

祝本地重温愉快。
