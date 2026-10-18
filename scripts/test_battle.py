# -*- coding: utf-8 -*-
"""战斗试错脚本：进战斗 -> 观察结算 -> 抓 .crash / retry。

用法:
    python scripts/test_battle.py             # 跑一场
    python scripts/test_battle.py --rounds 3  # 连跑 3 场

设计要点：
  * 战斗地图上用「前进」推进，遇到怪点才会真正 triggerBattleEvent；
  * 每步都截图到 work/battle_test/，出事时直接看图定位；
  * 每次点击后都检查 errorlogs 是否新增 .crash，抓到就 dump 前 900 字节。
"""
import os
import sys
import time
import glob
import argparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ui_test as U  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'work', 'battle_test')
ERRDIR = '/data/data/%s/errorlogs/' % U.PKG


def shot(tag):
    os.makedirs(OUT, exist_ok=True)
    return U.screenshot('bt_%s' % tag)


def err_files():
    rc, out = U.shell('ls -1 %s 2>/dev/null' % ERRDIR)
    return {n for n in out.split() if n.endswith('.log')}


def crash_text(name):
    rc, out = U.shell('head -c 900 %s%s' % (ERRDIR, name))
    return out


def goto_main(tries=6):
    """复用 ui_test 里带「结算面板确定」的版本（否则会被战败面板卡住）。"""
    return U.goto_main(tries)


def tap_ok():
    for name in ('battle_ok', 'dialog_ok'):
        U.tap(name)
        time.sleep(0.8)


def ensure_map():
    """从主界面走到战斗地图。"""
    if not U.is_main():
        goto_main()
    U.tap('nav_stage')
    time.sleep(2.2)
    U.tap('stage_challenge')
    time.sleep(2.0)
    # 点「挑战」后弹「挑战次数 x/99」选择框，必须再点右边「闯关」才进地图
    U.tap('stage_enter_map')
    time.sleep(4.5)


def watch(before, tag, seconds=12, step=2.0):
    """等 seconds 秒，期间循环截图 + 查崩溃。返回 (状态, 是否见到战斗)。"""
    for k in range(int(seconds / step)):
        time.sleep(step)
        p = shot('%s_%d' % (tag, k))
        born = err_files() - before
        if born:
            print('    !! 崩溃: %s' % sorted(born), flush=True)
            for n in sorted(born):
                print(crash_text(n)[:800], flush=True)
            return 'crash', p
        if not U.alive():
            print('    !! 进程消失', flush=True)
            return 'crash', p
    return 'ok', p


def run_one(idx, forward_clicks=14):
    print('--- 第 %d 场 ---' % (idx + 1), flush=True)
    before = err_files()
    ensure_map()
    shot('map%d' % idx)
    battle_seen = False
    for i in range(forward_clicks):
        if not U.alive():
            print('    !! 进程没了 pid=0', flush=True)
            return 'crash'
        U.tap('stage_forward')
        time.sleep(2.6)
        p = shot('fwd%d_%d' % (idx, i))
        born = err_files() - before
        if born:
            print('    !! 崩溃: %s' % sorted(born), flush=True)
            for n in sorted(born):
                print(crash_text(n)[:800], flush=True)
            return 'crash'
        try:
            sim = U.screen_sim(p, box=(0, 300, 720, 900))
        except Exception as e:
            sim = None
        print('      fwd %2d sim=%s' % (i, sim), flush=True)
        if sim is not None and sim < 0.55:
            battle_seen = True
            st, _ = watch(before, 'battle%d_%d' % (idx, i), seconds=14)
            if st == 'crash':
                return 'crash'
            break
    if not battle_seen:
        print('    ?? 没识别出战斗（可能只是走路/金币事件）', flush=True)
    tap_ok()
    time.sleep(2.0)
    tap_ok()
    time.sleep(1.5)
    shot('after%d' % idx)
    goto_main()
    return 'ok'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rounds', type=int, default=1)
    ap.add_argument('--wait', type=float, default=3.0)
    a = ap.parse_args()
    print('pid=%d' % U.pid(), flush=True)
    if not U.alive():
        print('游戏没在跑，先启动', flush=True)
        U.launch()
        U.Runner(a).auto_login()
    bad = 0
    for i in range(a.rounds):
        r = run_one(i)
        print('   => %s' % r, flush=True)
        if r == 'crash':
            bad += 1
            if not U.alive():
                U.launch()
                U.Runner(a).auto_login()
    print('崩溃场次: %d/%d' % (bad, a.rounds), flush=True)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
