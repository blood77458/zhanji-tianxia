# -*- coding: utf-8 -*-
"""把《五星武将成长表》和客户端 card_meta / card_rare / card_evolve 对一遍。

表里的列（第一张 sheet「武将成长表」）：
    花色 | 国 | 武将 | 连协1 连协2 连协3 | 成长值(攻) 成长值(防) 成长值(血) | 成长合计
    「武将各项排名」sheet 里还有一列「攻击成长」，例如 学·诸葛亮 = 294.3

我们这边的来源（全部来自客户端配置，服务端只是照抄公式）：
    card_meta[meta].reviseATT / reviseDEF / reviseHP    ← 就是表里的「成长值」
    实际每级成长 = reviseATT * card_rare[rare].basicAttack
                              * card_evolve[evolutionLevel].reviseAttack

所以本脚本做两件事：
  1. 用「成长值三元组」把表里的武将匹配到 card_meta（按数值匹配，绕开中文名）；
  2. 用 matched 的 card 算「每级攻击成长」，和表里的「攻击成长」列比对。
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
DUMP = os.path.join(ROOT, 'work', 'growth', 'dump.txt')

import luaconf  # noqa: E402


def parse_dump():
    """从 dump.txt 里抠出两张表。"""
    text = open(DUMP, encoding='utf-8').read().split('=== sheet: ')
    growth, rank = [], []
    for block in text[1:]:
        name = block.split(' ')[0]
        rows = []
        for line in block.split('\n')[1:]:
            if ' | ' not in line:
                continue
            cells = [c.strip() for c in line.split(' | ')]
            while cells and cells[0] == '':      # xlsx 前面有一列空
                cells.pop(0)
            if cells:
                rows.append(cells)
        if '成长表' in name:
            growth = rows
        elif '排名' in name:
            rank = rows
    return growth, rank


def fnum(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def rows_to_cards(rows):
    """成长表 -> [(花色, 国, 名字, (连1,连2,连3), (g1,g2,g3), 合计)]"""
    out = []
    for cells in rows:
        if len(cells) < 10:
            continue
        suit, country, name = cells[0], cells[1], cells[2]
        nums = [fnum(c) for c in cells[3:10]]
        if not name or any(n is None for n in nums):
            continue
        out.append((suit, country, name, tuple(nums[0:3]), tuple(nums[3:6]), nums[6]))
    return out


def rank_attack(rows):
    """排名表 -> {名字: 攻击成长}"""
    out = {}
    for cells in rows:
        if len(cells) < 6:
            continue
        name = cells[2]
        if not name or cells[3] == '':
            continue
        att = fnum(cells[5])
        if att is None:
            continue
        out[name] = att
    return out


def meta_index():
    """{(revATT, revDEF, revHP): [(metaId, rare, evo), ...]}"""
    idx = {}
    metas = luaconf.as_list(luaconf.load('card_meta'))
    for row in metas:
        if not isinstance(row, dict):
            continue
        key = (round(float(row.get('reviseATT') or 0), 4),
               round(float(row.get('reviseDEF') or 0), 4),
               round(float(row.get('reviseHP') or 0), 4))
        idx.setdefault(key, []).append((int(row.get('id') or 0),
                                        int(row.get('rare') or 0),
                                        int(row.get('evolutionLevel') or 0)))
    return idx


def main():
    growth_rows, rank_rows = parse_dump()
    cards = rows_to_cards(growth_rows)
    attack_of = rank_attack(rank_rows)
    print('表里武将: %d 条；排名表攻击成长: %d 条' % (len(cards), len(attack_of)))

    idx = meta_index()
    rare = {int(r.get('rare') or 0): r
            for r in luaconf.as_list(luaconf.load('card_rare')) if isinstance(r, dict)}
    evolve = {int(r.get('evolutionLevel') or 0): r
              for r in luaconf.as_list(luaconf.load('card_evolve')) if isinstance(r, dict)}
    print('card_meta 不同成长值三元组: %d；card_rare: %d；card_evolve: %d'
          % (len(idx), len(rare), len(evolve)))

    hit = miss = 0
    mismatched = []
    for suit, country, name, link, g, total in cards:
        key = (round(g[0], 4), round(g[1], 4), round(g[2], 4))
        cands = idx.get(key)
        if not cands:
            miss += 1
            continue
        hit += 1
        meta_id, ra, evo = cands[0]
        ra_row = rare.get(ra) or {}
        ev_row = evolve.get(evo) or {}
        per_lv_att = (g[0] * float(ra_row.get('basicAttack') or 0)
                      * float(ev_row.get('reviseAttack') or 0))
        want = attack_of.get(name)
        if want is None:
            continue
        if abs(per_lv_att - want) > 0.5:
            mismatched.append((name, g, ra, evo, per_lv_att, want, meta_id))

    print('\n按成长值三元组匹配: 命中 %d / 未命中 %d' % (hit, miss))
    print('「攻击成长」列对不上: %d 条' % len(mismatched))
    for name, g, ra, evo, got, want, mid in mismatched[:15]:
        print('  %-12s rare=%s evo=%s  我们算=%.3f  表里=%.3f  (meta=%s)'
              % (name, ra, evo, got, want, mid))
    if hit:
        print('\n抽样（前 5 条命中的）:')
        shown = 0
        for suit, country, name, link, g, total in cards:
            key = (round(g[0], 4), round(g[1], 4), round(g[2], 4))
            cands = idx.get(key)
            if not cands:
                continue
            meta_id, ra, evo = cands[0]
            ra_row = rare.get(ra) or {}
            ev_row = evolve.get(evo) or {}
            per_lv_att = (g[0] * float(ra_row.get('basicAttack') or 0)
                          * float(ev_row.get('reviseAttack') or 0))
            print('  %-12s 成长值=%s rare=%s evo=%s 每级攻=%.3f 表攻成长=%s meta=%s'
                  % (name, g, ra, evo, per_lv_att, attack_of.get(name), meta_id))
            shown += 1
            if shown >= 5:
                break
    return 0


if __name__ == '__main__':
    sys.exit(main())
