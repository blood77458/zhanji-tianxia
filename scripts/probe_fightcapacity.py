# -*- coding: utf-8 -*-
"""从真实抓包里找「战斗力 ↔ 攻防血」的样本，用来拟合战斗力系数。

原版战斗力是**服务端**下发的（`sharkUserExtend.fightCapacity`），客户端那份公式
已经废弃（`getLocalPlayerStrength` 里整段被注释掉）。所以只能拿抓包里的
(战斗力, 攻, 防, 血) 样本反推系数。
"""
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAP = os.path.join(ROOT, 'work', 'reference_capture', 'reference_decoded_2.json')

D = json.load(open(CAP, encoding='utf-8'))
PAT = re.compile(r'fightCapacity\\?"\s*:\s*(-?\d+)')


def main():
    vals = []
    for i, e in enumerate(D):
        s = json.dumps(e, ensure_ascii=False)
        for m in PAT.finditer(s):
            vals.append((i, int(m.group(1))))
    vals = [v for v in vals if v[1] > 0]
    print('抓包里有 %d 个非零 fightCapacity 样本' % len(vals))
    for i, v in vals[:10]:
        print('  包#%d -> %d' % (i, v))

    # 找带攻击/防御/血量字段的包（玩家详情、竞技场对手、排行）
    keys = ('totalAttack', 'totalDefence', 'totalHP', 'fightCapacity',
            'att', 'defence', 'hp')
    hits = 0
    for i, e in enumerate(D):
        s = json.dumps(e, ensure_ascii=False)
        if 'fightCapacity' in s and ('totalAttack' in s or 'cardInitDatas' in s):
            hits += 1
            if hits <= 5:
                print('  含属性+战力的包 #%d (%s)' % (i, e.get('direction')))
    print('同时含属性与战力的包: %d' % hits)
    return 0


if __name__ == '__main__':
    sys.exit(main())
