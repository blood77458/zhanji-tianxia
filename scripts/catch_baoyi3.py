"""极速连拍：进战斗后尽可能快地抓帧，专门抓「我方血量归零 -> 战败面板」之间那一两秒。

不 sleep，能多快抓多快（screencap 大约 0.25~0.35s 一帧）。
"""
import os
import subprocess
import sys
import time

ROOT = r'E:\deepseek_projects\app_server'
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
OUT = os.path.join(ROOT, 'work', 'baoyi_fast')

NAV_HOME = (60, 1218)
NAV_STAGE = (300, 1218)
CHALLENGE = (574, 948)
FORWARD = (360, 1066)


def sh(*a):
    return subprocess.run([ADB, '-s', DEV] + list(a),
                          capture_output=True).stdout.decode('utf-8', 'replace')


def tap(pt, wait=1.2):
    sh('shell', 'input tap %d %d' % pt)
    time.sleep(wait)


def grab(tag):
    os.makedirs(OUT, exist_ok=True)
    local = os.path.join(OUT, '%s.png' % tag)
    sh('shell', 'screencap -p /sdcard/_ff.png')
    sh('pull', '/sdcard/_ff.png', local)
    return local


def bars(path):
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
    except Exception:
        return 0, 0


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))
    tap((360, 1154), 1.2)
    tap((360, 1102), 1.0)
    tap(NAV_HOME, 1.5)
    tap(NAV_STAGE, 2.0)
    tap(CHALLENGE, 2.5)

    for attempt in range(20):
        tap(FORWARD, 1.0)
        p = grab('probe')
        top, bot = bars(p)
        if top > 200 and bot > 200:
            print('进战斗 (#%d)' % attempt)
            break
    else:
        print('!! 没进战斗'); return 1

    print('极速连拍中...')
    frames = []
    t0 = time.time()
    while time.time() - t0 < 26:
        tag = 'f%03d' % len(frames)
        p = grab(tag)
        top, bot = bars(p)
        frames.append((tag, top, bot))
        if bot == 0 and top > 200:
            print('  我方血条归零 @ %s (%.1fs)' % (tag, time.time() - t0))
            # 再多抓 8 帧把演出抓全
            for _ in range(8):
                q = grab('f%03d' % len(frames))
                tt, bb = bars(q)
                frames.append(('f%03d' % (len(frames)), tt, bb))
            break

    print('\n共 %d 帧:' % len(frames))
    for tag, top, bot in frames:
        print('  %-6s top=%-4d bot=%d' % (tag, top, bot))
    print('目录:', OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
