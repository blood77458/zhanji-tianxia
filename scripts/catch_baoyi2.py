"""反复点「前进」，直到进入战斗场景，然后按固定间隔连拍，抓「我方血量被打空」那一刻。

判定「在战斗中」：战斗场景顶部(敌方)和底部(我方)各有一条满宽红色血条。
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
FORWARD = (360, 1066)
NAV_STAGE = (300, 1218)
NAV_HOME = (60, 1218)
CHALLENGE = (574, 946)


def sh(*a):
    return subprocess.run([ADB, '-s', DEV] + list(a),
                          capture_output=True).stdout.decode('utf-8', 'replace')


def tap(pt, wait=1.5):
    sh('shell', 'input tap %d %d' % pt)
    time.sleep(wait)


def grab(tag):
    os.makedirs(OUT, exist_ok=True)
    r = '/sdcard/_bb.png'
    local = os.path.join(OUT, '%s.png' % tag)
    sh('shell', 'screencap -p ' + r)
    sh('pull', r, local)
    return local


def red_bars(path):
    """返回 (顶部红条像素数, 底部红条像素数)。"""
    try:
        from PIL import Image
        im = Image.open(path).convert('RGB')
        px = im.load()
        W, H = im.size

        def count(y0, y1):
            n = 0
            for y in range(y0, y1, 2):
                for x in range(0, W, 3):
                    r, g, b = px[x, y]
                    if r > 150 and g < 90 and b < 90:
                        n += 1
            return n
        return count(10, 40), count(H - 40, H - 10)
    except Exception as e:
        print('   (读图失败 %s)' % e)
        return 0, 0


def in_battle(path):
    top, bot = red_bars(path)
    return top > 200 and bot > 200, top, bot


def main():
    if not os.path.exists(ADB):
        print('!! 找不到 adb'); return 1
    os.makedirs(OUT, exist_ok=True)

    # 先回到闯关地图
    tap(NAV_HOME, 1.5)
    tap(NAV_STAGE, 2.0)
    tap(CHALLENGE, 2.5)          # 章节列表 -> 挑战(进战斗地图)
    p = grab('r0')
    ok, t, b = in_battle(p)
    print('进入闯关: 战斗中=%s (top=%d bot=%d)' % (ok, t, b))

    for attempt in range(20):
        tap(FORWARD, 1.2)
        p = grab('probe')
        ok, t, b = in_battle(p)
        print('  前进#%02d -> 战斗中=%s (top=%d bot=%d)' % (attempt, ok, t, b))
        if ok:
            print('  >>> 进战斗了，开始连拍')
            for i in range(16):
                q = grab('btl%02d' % i)
                ot, tb = red_bars(q)
                print('     btl%02d size=%d top=%d bot=%d' % (
                    i, os.path.getsize(q), ot, tb))
                time.sleep(0.7)
            print('\npid =', sh('shell', 'pidof com.happyelements.canon.baiduDK').strip())
            print('帧目录:', OUT)
            return 0
        # 若弹了什么框，点一下中间偏下把它关掉
        if os.path.getsize(p) < 500000:
            tap((360, 950), 1.0)
    print('!! 20 次前进都没进战斗')
    return 1


if __name__ == '__main__':
    sys.exit(main())
