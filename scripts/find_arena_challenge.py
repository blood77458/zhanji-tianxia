"""在竞技场里自动找到能把战斗真正打起来的「挑战」按钮位置。

做法：每次先关掉可能开着的「玩家信息」弹窗，再点一个候选点，然后看服务端日志里
有没有出现 challengeArena。找到就打印坐标并退出。
"""
import os
import subprocess
import sys
import time

ROOT = r'E:\deepseek_projects\app_server'
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
LOG = os.path.join(ROOT, 'work', 'srv_detached.log')
CLOSE = (676, 340)          # 「玩家信息」弹窗的 X

CANDIDATES = [(600, 936), (600, 1086), (600, 782), (600, 710), (600, 560),
              (620, 940), (560, 940), (640, 940)]


def sh(*a):
    return subprocess.run([ADB, '-s', DEV] + list(a),
                          capture_output=True).stdout.decode('utf-8', 'replace')


def tap(x, y):
    sh('shell', 'input tap %d %d' % (x, y))


def log_size():
    try:
        return os.path.getsize(LOG)
    except OSError:
        return 0


def new_battle(since):
    try:
        with open(LOG, 'rb') as f:
            f.seek(since)
            return b'challengeArena' in f.read()
    except OSError:
        return False


def main():
    if not os.path.exists(ADB):
        print('!! 找不到 adb'); return 1
    for (x, y) in CANDIDATES:
        tap(*CLOSE); time.sleep(1.0)          # 关弹窗（没弹窗时点这里也无害）
        pos = log_size()
        tap(x, y)
        time.sleep(4.0)
        if new_battle(pos):
            print('找到可用的挑战按钮: (%d, %d)' % (x, y))
            time.sleep(1)
            print('pid =', sh('shell', 'pidof com.happyelements.canon.baiduDK').strip())
            return 0
        print('  (%d,%d) 没触发战斗' % (x, y))
    print('!! 所有候选点都没触发，需要人工给坐标')
    return 1


if __name__ == '__main__':
    sys.exit(main())
