# -*- coding: utf-8 -*-
"""生成 Release 的 PATCH 负载（JSON，UTF-8 无 BOM）。

之所以用脚本生成而不是在 PowerShell 里拼字符串：Invoke-RestMethod 传字符串 body
时会按 Latin-1 编码发出，中文全变 `?`。这里直接写字节，再用 curl --data-binary 发。
"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

NAME = 'canon_net.apk 模拟器直连版'

BODY = """## canon_net.apk — 模拟器直连版客户端

《战姬天下》(canon) 11.0.61 客户端，仅修改了 `assets/StartupConfig.plist` 中的
`gameDomain` 与 `StaticSettingsUrl`，指向 `http://10.0.2.2`
（MuMu / AVD 中代表宿主机的固定地址）。

**用途**：配合本仓库的自建服务端，在模拟器里直接进游戏，无需修改 hosts、无需端口转发。

### 使用前提

1. 宿主机已启动本仓库服务端：`cd server && python -u gameserver.py`
2. 首次使用先执行 `python scripts/bootstrap.py` 准备配置与数据库

### 说明

- 仅改动一个配置文件，游戏资源未做任何修改
- 单机版（服务端内置、纯离线）仍在开发中，暂不发布
- 版权属乐元素，仅供个人学习与软件保存使用，请勿传播或商用
"""


def main():
    out = os.path.join(ROOT, 'work', 'release_patch.json')
    payload = {'name': NAME, 'body': BODY}
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(payload, f, ensure_ascii=False)
    size = os.path.getsize(out)
    print('已生成 %s (%d 字节, UTF-8)' % (out, size))
    # 自检：确认文件里是中文而不是问号
    text = open(out, encoding='utf-8').read()
    print('含中文:', any('\u4e00' <= c <= '\u9fff' for c in text),
          '| 含问号:', '?' in text.replace('UTF', ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
