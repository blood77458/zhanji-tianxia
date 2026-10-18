# -*- coding: utf-8 -*-
"""录一场战斗，抽帧找「爆衣/破衣」立绘。

流程：主界面 -> 闯关 -> 挑战 -> 闯关(进地图) -> 前进(直到进战斗) -> 录像 -> 结算
录像用设备端 screenrecord，抽帧用 ffmpeg，帧率 8fps，短动画不会漏。

用法:
    python scripts/rec_battle.py            # 录一场
    python scripts/rec_battle.py --fps 12
"""
import os
import re
import sys
import time
import shutil
import glob
import argparse
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_test as U  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FFMPEG = r'I:\ffmpeg\bin\ffmpeg.exe'
OUT = os.path.join(ROOT, 'work', 'battle_video')
REMOTE = '/sdcard/_btl.mp4'


def sh(*a, timeout=180):
    return U.sh(*a, timeout=timeout)


def goto_main(tries=6):
    """复用 ui_test 里带「结算面板确定」的版本（否则会被战败面板卡住）。"""
    return U.goto_main(tries)


def enter_map():
    if not U.is_main():
        goto_main()
    U.tap('nav_stage'); time.sleep(2.2)
    U.tap('stage_challenge'); time.sleep(2.0)
    U.tap('stage_enter_map'); time.sleep(4.5)


REC = None


def start_rec(seconds):
    """后台起 screenrecord（Popen 不等待），录完由 time-limit 自行结束。"""
    global REC
    sh('shell', 'rm -f %s' % REMOTE)
    adb = U.ADB
    REC = subprocess.Popen(
        [adb, '-s', U.DEV, 'shell',
         'screenrecord --bit-rate 8000000 --time-limit %d %s' % (seconds, REMOTE)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def stop_rec():
    sh('shell', 'pkill -INT screenrecord 2>/dev/null; true')
    if REC is not None:
        try:
            REC.wait(timeout=12)
        except Exception:
            REC.kill()
    time.sleep(2.0)


def pull_and_extract(fps):
    sh('pull', REMOTE, os.path.join(OUT, 'battle.mp4'))
    mp4 = os.path.join(OUT, 'battle.mp4')
    if not os.path.exists(mp4) or os.path.getsize(mp4) < 10000:
        print('!! 录像没拿到', flush=True)
        return []
    fdir = os.path.join(OUT, 'f')
    if os.path.isdir(fdir):
        shutil.rmtree(fdir, ignore_errors=True)
    os.makedirs(fdir, exist_ok=True)
    subprocess.run([FFMPEG, '-y', '-loglevel', 'error', '-i', mp4,
                    '-vf', 'fps=%d' % fps, os.path.join(fdir, 'f%03d.png')],
                   capture_output=True)
    return sorted(glob.glob(os.path.join(fdir, 'f*.png')))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--fps', type=int, default=8)
    ap.add_argument('--clicks', type=int, default=10)
    ap.add_argument('--in-map', action='store_true',
                    help='已经手动站在战斗地图上时跳过导航（主界面参照图对不上就用它）')
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    print('pid=%d' % U.pid(), flush=True)
    if not U.alive():
        print('启动游戏', flush=True)
        U.launch()
        U.Runner(a).auto_login()
        goto_main()
    if a.in_map:
        print('跳过导航，直接在当前地图上点「前进」', flush=True)
    else:
        enter_map()
    U.screenshot('rec_map')
    # 先探一下哪个「前进」能进战斗：点一次，比较与主界面的差异
    for i in range(a.clicks):
        U.tap('stage_forward'); time.sleep(2.6)
        p = U.screenshot('rec_probe%d' % i)
        try:
            sim = U.screen_sim(p, box=(0, 300, 720, 900))
        except Exception:
            sim = 1.0
        print('  probe %d sim=%s' % (i, sim), flush=True)
        if sim < 0.55:
            print('  进战斗了，开始录像', flush=True)
            start_rec(75)
            # 战斗演出 + 结算，多留点时间
            for k in range(30):
                time.sleep(2.0)
                if not U.alive():
                    print('  !! 进程消失', flush=True)
                    break
            stop_rec()
            frames = pull_and_extract(a.fps)
            print('抽帧 %d 张 -> %s' % (len(frames), os.path.join(OUT, 'f')),
                  flush=True)
            U.screenshot('rec_result')
            return 0
    print('?? 没进战斗', flush=True)
    U.screenshot('rec_nobattle')
    return 1


if __name__ == '__main__':
    sys.exit(main())
