"""抓「我方血量被打空」那一刻的画面，用来验证爆衣演出。

前提：work/battle_debug_x.txt 里写了放大倍率（保证必败）。

流程（每步都校验，失败就打印出来而不是硬往下走）：
  主界面 -> 闯关 -> 挑战 -> 前进 -> 连拍 N 帧
"""
import os
import subprocess
import sys
import time

ROOT = r'E:\deepseek_projects\app_server'
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
OUT = os.path.join(ROOT, 'work', 'baoyi')

# 720x1280 实测坐标
NAV_HOME = (60, 1218)
NAV_STAGE = (300, 1218)
STAGE_CHALLENGE = (574, 946)
STAGE_FORWARD = (360, 1066)


def sh(*a):
    return subprocess.run([ADB, '-s', DEV] + list(a),
                          capture_output=True).stdout.decode('utf-8', 'replace')


def tap(pt, wait=2.0):
    sh('shell', 'input tap %d %d' % pt)
    time.sleep(wait)


def shot(tag):
    os.makedirs(OUT, exist_ok=True)
    remote = '/sdcard/_by_%s.png' % tag
    local = os.path.join(OUT, '%s.png' % tag)
    sh('shell', 'screencap -p ' + remote)
    sh('pull', remote, local)
    return local if os.path.exists(local) else ''


def sig(path):
    """用文件大小当粗指纹：界面变了大小几乎必变。"""
    try:
        return os.path.getsize(path)
    except OSError:
        return 0


def main():
    if not os.path.exists(ADB):
        print('!! 找不到 adb'); return 1
    dbg = os.path.join(ROOT, 'work', 'battle_debug_x.txt')
    print('调试倍率文件:', open(dbg).read().strip() if os.path.exists(dbg) else '(无，战斗不会必输)')

    taps = [('00-home', NAV_HOME), ('01-stage', NAV_STAGE),
            ('02-challenge', STAGE_CHALLENGE)]
    prev = None
    for tag, pt in taps:
        tap(pt, 2.0)
        p = shot(tag)
        cur = sig(p)
        print('  %-14s -> %s (size=%d%s)' % (
            tag, pt, cur, '' if prev is None else ', 变化' if cur != prev else ', 没变!'))
        prev = cur

    # 前进 = 开战；之后马上连拍
    tap(STAGE_FORWARD, 0.3)
    print('\n前进后连拍：')
    for i in range(14):
        p = shot('frame%02d' % i)
        print('  frame%02d %d bytes' % (i, sig(p)))
        time.sleep(0.9)

    print('\npid =', sh('shell', 'pidof com.happyelements.canon.baiduDK').strip())
    err = sh('shell', 'cat /data/data/com.happyelements.canon.baiduDK/errorlogs/*.crash 2>/dev/null')
    if err.strip():
        print('!! 有崩溃文件:\n' + err[:600])
    print('帧目录:', OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
