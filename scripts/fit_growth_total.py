# -*- coding: utf-8 -*-
"""反推《五星武将成长表》里「成长合计」到底是什么公式。

已知（全部实证）：
    card_level[L].levelCoefficient == L          （1,2,10,20,40,60,70…）
    card_rare[*].basicX == 1，card_evolve[*].reviseX == 1
所以客户端公式退化成：
    att(L) = initAtt + L * reviseATT         （def / hp 同理）

本脚本尝试用最小二乘把「成长合计」拟合成 成长值三元组 的线性组合，
看能不能得到干净的系数（比如 13.92 / 6.4 这种），从而反推出隐藏倍率。
"""
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
DUMP = os.path.join(ROOT, 'work', 'growth', 'dump.txt')

import numpy as np            # noqa: E402
import luaconf               # noqa: E402


def fnum(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def parse():
    text = open(DUMP, encoding='utf-8').read().split('=== sheet: ')
    out = []
    for block in text[1:]:
        if '成长表' not in block.split(' ')[0]:
            continue
        for line in block.split('\n')[1:]:
            if ' | ' not in line:
                continue
            cells = [c.strip() for c in line.split(' | ')]
            while cells and cells[0] == '':
                cells.pop(0)
            if len(cells) < 10:
                continue
            nums = [fnum(c) for c in cells[3:10]]
            if any(n is None for n in nums):
                continue
            out.append((cells[2], tuple(nums[3:6]), nums[6]))
    return out


def main():
    rows = parse()
    metas = [r for r in luaconf.as_list(luaconf.load('card_meta')) if isinstance(r, dict)]
    by_name = {}
    for m in metas:
        rn = str(m.get('readName') or '')
        if not rn:
            continue
        base = rn.rsplit('_', 1)[0] if rn.rsplit('_', 1)[-1].isdigit() else rn
        by_name.setdefault(base, []).append(m)

    X, y, names = [], [], []
    for name, g, total in rows:
        if name not in by_name:
            continue
        m = sorted(by_name[name], key=lambda x: int(x.get('evolutionLevel') or 0))[0]
        got = (float(m.get('reviseATT') or 0), float(m.get('reviseDEF') or 0),
               float(m.get('reviseHP') or 0))
        if tuple(round(g[i], 4) for i in range(3)) != tuple(round(got[i], 4) for i in range(3)):
            continue
        X.append(list(g) + [1.0])
        y.append(total)
        names.append(name)

    X = np.array(X, dtype=float)
    y = np.array(y, dtype=float)
    print('参与拟合 %d 条' % len(y))

    # 无截距
    coef, *_ = np.linalg.lstsq(X[:, :3], y, rcond=None)
    pred = X[:, :3] @ coef
    err = np.abs(pred - y)
    print('无截距 系数 att=%.4f def=%.4f hp=%.4f  最大误差=%.3f 平均=%.3f'
          % (coef[0], coef[1], coef[2], err.max(), err.mean()))

    # 带截距
    coef2, *_ = np.linalg.lstsq(X, y, rcond=None)
    pred2 = X @ coef2
    err2 = np.abs(pred2 - y)
    print('带截距 系数 att=%.4f def=%.4f hp=%.4f 截距=%.3f  最大误差=%.3f 平均=%.3f'
          % (coef2[0], coef2[1], coef2[2], coef2[3], err2.max(), err2.mean()))

    # 试几个「好看」的假设
    print('\n单卡观察（按名字）:')
    shown = 0
    for i, name in enumerate(names):
        if shown >= 6:
            break
        g = X[i][:3]
        got = (g[0] + g[1] + g[2])
        print('  %-12s 成长值=%-22s 合计=%-10.3f 合计/单级和=%.4f'
              % (name, tuple(g), y[i], y[i] / got if got else 0))
        shown += 1

    # 已知的「攻击成长」列数据点，反推 att 倍率
    print('\n已知攻击成长倍率样本:')
    for name, att_growth in (('白·孙尚香', 232.464), ('学·孙策', 116.412),
                             ('恋·周瑜', 218.04), ('魔·陆逊', 171.312)):
        if name in by_name:
            m = sorted(by_name[name], key=lambda x: int(x.get('evolutionLevel') or 0))[0]
            g_att = float(m.get('reviseATT') or 0)
            print('  %-10s 攻击成长=%.3f / reviseATT=%.2f = %.4f'
                  % (name, att_growth, g_att, att_growth / g_att if g_att else 0))
    return 0


if __name__ == '__main__':
    sys.exit(main())
