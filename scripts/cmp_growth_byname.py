# -*- coding: utf-8 -*-
"""《五星武将成长表》× 客户端 card_meta 精确比对（按 readName 匹配）。

表的列：花色 | 国 | 武将 | 连协1 连协2 连协3 | 成长值(攻/防/血) | 成长合计
我方：card_meta.readName = "白·孙尚香_1"（系列·名字_进化级），去掉尾部 _N 就能对上。

输出：
  1. 精确命中多少条、成长值是否一致、差异多大；
  2. 表里有、我们配置里没有的武将；
  3. 「连协」这三列在我们的 card_meta 里是否对应某个字段。
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
DUMP = os.path.join(ROOT, 'work', 'growth', 'dump.txt')

import luaconf  # noqa: E402


def fnum(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def parse():
    text = open(DUMP, encoding='utf-8').read().split('=== sheet: ')
    growth = []
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
            name = cells[2]
            name = re.sub(r'[ ]*[0-9]+[☆★]$', '', name).strip()   # 「孙权 6☆」-> 「孙权」
            growth.append({'suit': cells[0], 'country': cells[1], 'name': name,
                           'link': tuple(nums[0:3]), 'g': tuple(nums[3:6]),
                           'total': nums[6]})
    return growth


def main():
    table = parse()
    metas = [r for r in luaconf.as_list(luaconf.load('card_meta')) if isinstance(r, dict)]
    by_name = {}
    for m in metas:
        rn = str(m.get('readName') or '')
        if not rn:
            continue
        base = rn.rsplit('_', 1)[0] if rn.rsplit('_', 1)[-1].isdigit() else rn
        by_name.setdefault(base, []).append(m)

    rare = {int(r.get('rare') or 0): r
            for r in luaconf.as_list(luaconf.load('card_rare')) if isinstance(r, dict)}
    evolve = {int(r.get('evolutionLevel') or 0): r
              for r in luaconf.as_list(luaconf.load('card_evolve')) if isinstance(r, dict)}

    exact = mism = missing = 0
    diffs = []
    no_cfg = []
    for row in table:
        cands = by_name.get(row['name'])
        if not cands:
            missing += 1
            no_cfg.append(row['name'])
            continue
        # 取基础形态（_1）/五星那张
        cands.sort(key=lambda m: (int(m.get('evolutionLevel') or 0),
                                  int(m.get('rare') or 0)))
        m = cands[0]
        got = (float(m.get('reviseATT') or 0), float(m.get('reviseDEF') or 0),
               float(m.get('reviseHP') or 0))
        want = row['g']
        d = tuple(round(got[i] - want[i], 4) for i in range(3))
        if all(abs(x) < 1e-6 for x in d):
            exact += 1
        else:
            mism += 1
            diffs.append((row['name'], want, got, d,
                          int(m.get('id') or 0), int(m.get('rare') or 0),
                          int(m.get('evolutionLevel') or 0)))

    print('表里 %d 条；我方 card_meta %d 张' % (len(table), len(metas)))
    print('按名字匹配：成长值完全一致 %d，不一致 %d，配置里没有 %d'
          % (exact, mism, missing))
    if diffs:
        print('\n=== 成长值不一致（表 vs 我们）===')
        for name, want, got, d, mid, ra, evo in diffs:
            print('  %-12s 表=%s 我们=%s 差=%s  meta=%s rare=%s evo=%s'
                  % (name, want, got, d, mid, ra, evo))
    if no_cfg:
        print('\n=== 表里有、我们配置里没有 ===')
        print('  ' + '，'.join(no_cfg))
    # 「连协」是不是某个字段？拿两条去看它
    print('\n=== 「连协」列抽样对照（看是否对应 card_meta 某个数值字段）===')
    for row in table[:3]:
        cands = by_name.get(row['name'])
        if not cands:
            continue
        m = sorted(cands, key=lambda x: int(x.get('evolutionLevel') or 0))[0]
        nums = {k: v for k, v in m.items()
                if isinstance(v, (int, float)) and not isinstance(v, bool)}
        hits = [k for k, v in nums.items()
                if any(abs(float(v) - x) < 1e-6 for x in row['link'])]
        print('  %-10s 连协=%s  → 数值相同的字段: %s' % (row['name'], row['link'],
                                                   hits or '无'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
