"""用 screenrecord 录像 + ffmpeg 抽帧，抓「我方全员阵亡 -> 战败面板」之间的演出。

比逐张 screencap 可靠得多：录像 30fps，抽帧 10fps，短动画也不会漏。
"""
import os
import glob
import shutil
import subprocess
import sys
import time

ROOT = r'E:\deepseek_projects\app_server'
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
FFMPEG = r'I:\ffmpeg\bin\ffmpeg.exe'
DEV = '127.0.0.1:16384'
OUT = os.path.join(ROOT, 'work', 'baoyi_video')

NAV_HOME = (60, 1218)
NAV_STAGE = (300, 1218)
CHALLENGE = (574, 948)
FORWARD = (360, 1066)
CONFIRM = (360, 1154)


def sh(*a, timeout=120):
    try:
        return subprocess.run([ADB, '-s', DEV] + list(a), capture_output=True,
                              timeout=timeout).stdout.decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        return ''


def tap(pt, wait=1.2):
    sh('shell', 'input tap %d %d' % pt)
    time.sleep(wait)


def grab(path):
    sh('shell', 'screencap -p /sdcard/_v.png')
    sh('pull', '/sdcard/_v.png', path)
    return path


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
    if not os.path.exists(FFMPEG):
        print('!! 没有 ffmpeg'); return 1
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT, exist_ok=True)

    # 清掉可能残留的弹窗，回到闯关地图
    tap(CONFIRM, 1.0)
    tap(NAV_HOME, 1.5)
    tap(NAV_STAGE, 2.0)
    tap(CHALLENGE, 2.5)

    # 先走到踩到怪物格（不录），进了战斗才开始录 —— 否则前 20 秒全是走路
    for attempt in range(25):
        tap(FORWARD, 1.0)
        p = grab(os.path.join(OUT, '_probe.png'))
        top, bot = bars(p)
        if top > 200 and bot > 200:
            print('进战斗 (#%d)，开始录像' % attempt)
            break
    else:
        print('!! 没进战斗')

    sh('shell', 'rm -f /sdcard/battle.mp4')
    subprocess.Popen([ADB, '-s', DEV, 'shell',
                      'screenrecord --time-limit 20 --bit-rate 8000000 /sdcard/battle.mp4'])
    time.sleep(19)

    # 等录像自然结束（time-limit 22s）
    time.sleep(21)
    sh('pull', '/sdcard/battle.mp4', os.path.join(OUT, 'battle.mp4'), timeout=180)

    mp4 = os.path.join(OUT, 'battle.mp4')
    if not os.path.exists(mp4):
        print('!! 没拿到录像'); return 1
    print('录像大小 %d' % os.path.getsize(mp4))

    # 抽帧 10fps
    frames = os.path.join(OUT, 'f')
    os.makedirs(frames, exist_ok=True)
    subprocess.run([FFMPEG, '-y', '-loglevel', 'error', '-i', mp4,
                    '-vf', 'fps=10', os.path.join(frames, 'f%03d.png')],
                   capture_output=True)
    fs = sorted(glob.glob(os.path.join(frames, 'f*.png')))
    print('抽到 %d 帧' % len(fs))

    # 标注每帧的我方血条像素数，找出「归零后不再回升」的起点
    seq = []
    for f in fs:
        top, bot = bars(f)
        seq.append((os.path.basename(f), top, bot))
    zero_run = 0
    for i, (n, top, bot) in enumerate(seq):
        if top > 100 and bot == 0:
            zero_run += 1
        else:
            zero_run = 0
        if zero_run == 3:
            start = max(0, i - 6)
            print('\n我方血条稳定归零起始帧: %s (第 %d 帧)' % (n, i))
            print('关键帧区间: %s .. %s' % (seq[start][0], seq[min(len(seq)-1, i+12)][0]))
            break
    print('\n血条序列（后 40 帧）:')
    for n, top, bot in seq[-40:]:
        print('  %-9s top=%-4d bot=%d' % (n, top, bot))
    print('\n目录:', OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
