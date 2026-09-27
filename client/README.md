# 客户端（Client）

推荐安装包：

| 文件 | 说明 |
|------|------|
| `zjt_pack_enablefix_signed.apk` | 已打补丁并签名的可玩包（约 193 MB） |

## 获取 APK

GitHub / 仓库本身**不包含** APK（单文件超过 100 MB 限制）。任选其一：

1. **Release 附件**：打开仓库的 [Releases](../../releases)，下载 `v1.0.0`（或最新 tag）里的  
   `zjt_pack_enablefix_signed.apk`，放到本目录。
2. **本机已有构建产物**：从仓库旁的 `work/` 复制：

```bat
copy ..\work\zjt_pack_enablefix_signed.apk .\zjt_pack_enablefix_signed.apk
```

## 安装到模拟器

见根目录 [README.md](../README.md)「三、安装客户端」一节。

包名：`com.happyelements.canon.baiduDK`  
签名 keystore（仅本地调试）：`../work/canon.keystore`（密码 `123456`，alias `canon`）。
