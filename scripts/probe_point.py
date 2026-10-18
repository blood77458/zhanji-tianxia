"""在多个候选坐标上各点一次，看哪个「完全没反应」——用来给 ui_test 找
真正中性的空白点（点了不该弹任何面板的那一个）。

用法: python scripts/probe_point.py 5,500 712,650 360,1185 ...
"""
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))

from PIL import Image, ImageChops            # noqa: E402

ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = os.environ.get('CANON_DEV', '127.0.0.1:16384')
OUT = os.path.join(ROOT, 'work', 'uitest')
REF = os.path.join(OUT, '_ref_main.png')
BOX = (0, 120, 720, 1150)


def sh(*a):
    return subprocess.run([ADB, '-s', DEV] + list(a),
                          capture_output=True).stdout.decode('utf-8', 'replace')


def grab(path):
    sh('shell', 'screencap -p /sdcard/_pp.png')
    sh('pull', '/sdcard/_pp.png', path)
    return Image.open(path).convert('L')


def sim(im):
    a = Image.open(REF).convert('L').crop(BOX)
    b = im.crop(BOX)
    h = ImageChops.difference(a, b).histogram()
    t = sum(h) or 1
    return sum(h[:13]) / float(t)


def main():
    ref = Image.open(REF).convert('L')
    base = sim(ref)
    print('基准(自比) sim=%.4f' % base)
    for arg in sys.argv[1:]:
        x, y = [int(v) for v in arg.split(',')]
        sh('shell', 'input tap %d %d' % (x, y))
        time.sleep(2.5)
        s = sim(grab(os.path.join(OUT, '_probe.png')))
        print('  (%4d,%4d) sim=%.4f  %s' % (x, y, s,
              'OK 中性' if s >= 0.90 else '** 有反应 **'))
        if s < 0.90:
            sh('shell', 'input keyevent 4')
            time.sleep(1.5)
            sh('shell', 'input tap 233 858')     # 取消退出确认
            time.sleep(1.5)
            cur = sim(grab(os.path.join(OUT, '_probe.png')))
            if cur < 0.90:
                print('       !! 未恢复 (sim=%.4f)' % cur)
    return 0


if __name__ == '__main__':
    sys.exit(main())
