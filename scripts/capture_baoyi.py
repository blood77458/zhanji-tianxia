# -*- coding: utf-8 -*-
"""一键复现「爆衣」并留证据。

做法：
  1. 临时把 work/battle_debug_x.txt 设成 0.02、battle_debug_enemy.txt 设成 104071（貂蝉），
     让这场必赢、且敌方是**有破碎立绘的卡牌**（card/crush/diaochan_0.png）；
  2. 清战斗事件缓存后跑 rec_battle.py 录像 + 抽帧；
  3. 把「CRUSH!!!」到结算之间的关键帧复制到 work/proof/baoyi/；
  4. **删掉**两个调试开关，恢复原生数值。

前提：客户端已打 patch_battle_guard.py 的补丁（否则队列空掉会崩）。
"""
import os
import shutil
import subprocess
import sys
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(ROOT, 'work')
PROOF = os.path.join(WORK, 'proof', 'baoyi')
FPS = 10

DBG_X = os.path.join(WORK, 'battle_debug_x.txt')
DBG_ENEMY = os.path.join(WORK, 'battle_debug_enemy.txt')


def run(args):
    print('>', ' '.join(args), flush=True)
    return subprocess.run([sys.executable] + args, cwd=ROOT).returncode


def main():
    for f in (DBG_X, DBG_ENEMY):
        os.makedirs(os.path.dirname(f), exist_ok=True)
    open(DBG_X, 'w').write('0.02')
    open(DBG_ENEMY, 'w').write('104071')
    print('调试开关: x=0.02 enemy=104071(貂蝉)')
    try:
        run(['scripts/clear_battle_cache.py'])
        rc = run(['scripts/rec_battle.py', '--fps', str(FPS)])
        print('录像返回码', rc)
    finally:
        for f in (DBG_X, DBG_ENEMY):
            if os.path.exists(f):
                os.remove(f)
        print('调试开关已删除，恢复原生数值')
        run(['scripts/clear_battle_cache.py'])
    frames = sorted(glob.glob(os.path.join(WORK, 'battle_video', 'f', 'f*.png')))
    if not frames:
        print('!! 没抽到帧')
        return 1
    if os.path.isdir(PROOF):
        shutil.rmtree(PROOF, ignore_errors=True)
    os.makedirs(PROOF, exist_ok=True)
    # 只留前 60 帧（战斗结束得很快，CRUSH 镜头都在前面）
    keep = frames[:60]
    for i, f in enumerate(keep):
        shutil.copy2(f, os.path.join(PROOF, 'f%03d.png' % (i + 1)))
    print('留下 %d 帧 -> %s' % (len(keep), PROOF))
    return 0


if __name__ == '__main__':
    sys.exit(main())
