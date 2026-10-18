# -*- coding: utf-8 -*-
"""② 连协 / 套装 的自测：人造满足条件，确认确实算出了非 0 加成。

只验证「管道通不通 + 口径对不对」，不依赖当前角色的实际阵容。
"""
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))

import luaconf                          # noqa: E402
from services import cardstats as CS    # noqa: E402


def test_group_skill():
    groups = luaconf.load('special_group_skill') or {}
    metas = luaconf.load('card_meta') or {}
    # 找一张 cardGroupId 命中连协表的卡
    for gid, gs in groups.items():
        target = None
        for m in metas.values():
            if int(m.get('cardGroupId') or 0) == int(gid):
                target = m
                break
        if not target:
            continue
        # 人造国家队：让 4 条都满足（本国 +1 的规则由 country 决定）
        nums = {}
        for i in (1, 2, 3, 4):
            grp = int(gs.get('group%d' % i) or 0)
            need = int(gs.get('groupNum%d' % i) or 0)
            if not grp:
                continue
            nums[grp] = need + 1
        nums[int(target.get('country'))] = nums.get(int(target.get('country')), 0) + 1
        pct, flat = CS.group_skill_bonus(target, nums)
        total = sum(pct.values()) + sum(flat.values())
        print('连协 cardGroupId=%-5s 卡=%-14s -> pct=%s flat=%s'
              % (gid, target.get('readName'),
                 {k: round(v, 3) for k, v in pct.items()},
                 {k: v for k, v in flat.items()}))
        assert total > 0, '连协算出来是 0，管道有问题'
        print('  OK  总加成=%s' % round(total, 4))
        return True
    print('!! 没有任何卡能命中连协表')
    return False


def test_equip_suit():
    suits = luaconf.load('equip_suit') or {}
    metas = luaconf.load('card_meta') or {}
    equips = luaconf.load('equip_meta') or {}
    rows = list(suits.values()) if isinstance(suits, dict) else suits
    by_prefix = {}
    for mid, em in (equips.items() if isinstance(equips, dict) else enumerate(equips)):
        if isinstance(em, dict):
            by_prefix.setdefault(int(em.get('prefixId') or 0), int(em.get('id') or mid))
    for row in rows:
        gid = int(row.get('cardGroupId') or 0)
        equip_id = int(row.get('equipId') or 0)
        meta_id = by_prefix.get(equip_id)
        if not meta_id:
            continue
        target = None
        for m in metas.values():
            if int(m.get('cardGroupId') or 0) == gid:
                target = m
                break
        if not target:
            continue
        fake = [{'meta_id': meta_id, 'level': 1}]
        pct, flat = CS.equip_suit_bonus(target, fake)
        total = sum(pct.values()) + sum(flat.values())
        print('套装 cardGroupId=%-5s equipId=%-6s 卡=%-14s effectValue=%s -> pct=%s flat=%s'
              % (gid, equip_id, target.get('readName'), row.get('effectValue'),
                 {k: round(v, 4) for k, v in pct.items()},
                 {k: v for k, v in flat.items()}))
        assert total > 0, '套装算出来是 0，管道有问题'
        print('  OK  总加成=%s' % round(total, 4))
        return True
    print('!! 没有任何套装能被命中')
    return False


if __name__ == '__main__':
    a = test_group_skill()
    b = test_equip_suit()
    print('\n连协=%s 套装=%s' % ('PASS' if a else 'FAIL', 'PASS' if b else 'FAIL'))
    sys.exit(0 if (a and b) else 1)
