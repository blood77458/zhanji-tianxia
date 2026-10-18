# -*- coding: utf-8 -*-
"""S2 探测：进主界面后逐个点开入口，收集 `unhandled <method>` 清单。

用法:
    python scripts/single_probe.py            # 探测并打印清单
    python scripts/single_probe.py --no-boot  # 已经停在主界面，只探测

坐标取自 scripts/ui_test.py 的 COORD（720x1280）。
"""
import os
import re
import subprocess
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
PKG = 'com.happyelements.canon.baiduDK'

# 底部导航 + 图标行 + 顶部菜单
ENTRIES = [
    ('背包', (420, 1218)),
    ('队伍', (180, 1218)),
    ('闯关', (300, 1218)),
    ('神兽', (540, 1218)),
    ('军团', (660, 1218)),
    ('任务', (60, 168)),
    ('活动', (180, 168)),
    ('奖励', (300, 168)),
    ('求将', (420, 168)),
    ('商城', (660, 168)),
    ('装备', (60, 1086)),
    ('好友', (180, 1086)),
    ('邮箱', (300, 1086)),
    ('元神', (420, 1086)),
    ('宝物', (540, 1086)),
    ('炼魂', (660, 1086)),
    ('竞技', (108, 314)),
    ('演武', (126, 732)),
]

BACK = [(400, 190), (676, 252), (60, 1218)]


def shell(cmd, timeout=90):
    try:
        r = subprocess.run([ADB, '-s', DEV, 'shell', cmd], capture_output=True,
                           timeout=timeout)
        return (r.stdout or b'').decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        return ''


def tap(pt, wait=1.2):
    shell('input tap %d %d' % pt)
    time.sleep(wait)


def back_home():
    for pt in BACK:
        tap(pt, 1.2)


def unhandled_now():
    out = shell('logcat -d | grep -oE "unhandled [A-Za-z_0-9]+"')
    return set(re.findall(r'unhandled ([A-Za-z_0-9]+)', out or ''))


def main():
    if '--no-boot' not in sys.argv:
        subprocess.run([sys.executable, os.path.join(ROOT, 'scripts', 'single_boot.py'),
                        '--wait', '26'], cwd=ROOT, capture_output=True)

    seen = unhandled_now()
    fresh = set()
    for name, pt in ENTRIES:
        shell('logcat -c')
        tap(pt, 1.0)
        time.sleep(2.6)
        got = unhandled_now()
        if got:
            print('%-6s -> %s' % (name, ' '.join(sorted(got))), flush=True)
            fresh |= got
        else:
            print('%-6s -> （无）' % name, flush=True)
        seen |= got
        back_home()

    print('\n=== 本轮新发现（写进 work/proto_methods.txt）===')
    print(' '.join(sorted(fresh)) if fresh else '（无）')
    print('\n=== 累计 ===')
    print(' '.join(sorted(seen)) if seen else '（无）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
