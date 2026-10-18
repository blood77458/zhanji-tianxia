# -*- coding: utf-8 -*-
"""对比「敌方怪物数值」的两种算法，判断哪个量级才对。

背景：
  battle_monster 里的 reviseHP / reviseATT / reviseDEF 取值 60~360 这种量级，
  明显是**百分比系数**，不是绝对血量。我们服务端之前直接
      hp = reviseHP * monsterRevise
  当绝对血量用，于是第一章小怪就有 122183 血（满级五星卡才 5k 出头）。

两种算法对照：
  旧: hp = mon.reviseHP * monsterRevise
  新: hp = (card_meta[mon.cardId].initHp + L * reviseHP_meta) * mon.reviseHP / 100
      （monsterRevise 再当难度百分比乘一次）

跑法：python scripts/cmp_monster_stats.py
"""
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
os.chdir(os.path.join(ROOT, 'server'))

import gamedata as G                       # noqa: E402
from services import cardstats as CS       # noqa: E402
from db import Database                    # noqa: E402


def main():
    G.init_battle_meta()
    src = G._cs
    ks = list(src._BATTLE_EVENT.keys())
    print('battle_event 条数: %d；key 样例: %s' % (len(ks), ks[:3]))

    for mission in (100102, 100109):
        ev = None
        for k in ks:
            if isinstance(k, tuple):
                if k and int(k[0]) == mission:
                    ev = src._BATTLE_EVENT[k]
                    break
            elif int(k) == mission:
                ev = src._BATTLE_EVENT[k]
                break
        if not ev:
            print('!! 找不到 mission', mission)
            continue
        L = int(ev.get('monsterLevel') or 1)
        rev = float(ev.get('monsterRevise') or 1)
        print('\n=== mission %s  monsterLevel=%s monsterRevise=%s group=%s'
              % (mission, L, rev, ev.get('monsterGroupId')))
        grp = src._BATTLE_MONSTER_GROUP.get(ev['monsterGroupId']) or []
        for mid in grp[:4]:
            m = src._BATTLE_MONSTER.get(mid) or {}
            card = int(m.get('cardId') or 0)
            meta = CS.card_meta(card) or {}
            base_hp = float(meta.get('initHp') or 0) + L * float(meta.get('reviseHP') or 0)
            base_att = float(meta.get('initAtt') or 0) + L * float(meta.get('reviseATT') or 0)
            base_def = float(meta.get('initDef') or 0) + L * float(meta.get('reviseDEF') or 0)
            old_hp = float(m.get('reviseHP') or 0) * rev
            old_att = float(m.get('reviseATT') or 0) * rev
            new_hp = base_hp * float(m.get('reviseHP') or 0) / 100.0 * rev / 100.0
            new_att = base_att * float(m.get('reviseATT') or 0) / 100.0 * rev / 100.0
            new_def = base_def * float(m.get('reviseDEF') or 0) / 100.0 * rev / 100.0
            print('  mon=%-5s card=%-6s %-22s 旧 hp=%-8.0f att=%-6.0f | 新 hp=%-7.0f att=%-6.0f def=%.0f'
                  % (mid, card, str(meta.get('readName'))[:20], old_hp, old_att,
                     new_hp, new_att, new_def))

    db = Database('canon.db')
    db.connect()
    slots = db.all("SELECT s.card_id FROM player_battle_slot s JOIN player_battle_array a "
                   "ON a.player_id=s.player_id AND a.array_id=s.array_id "
                   "WHERE s.player_id=100000 AND a.is_active=1 ORDER BY s.slot")
    print('\n我方出战队伍（用于比较量级）:')
    for s in slots:
        c = db.one('SELECT * FROM player_card WHERE player_id=100000 AND card_id=?',
                   (s['card_id'],))
        if not c:
            continue
        st = CS.card_attributes(c)
        meta = CS.card_meta(c['meta_id']) or {}
        print('  card=%-5s %-14s lv=%-3s att=%-5s def=%-5s hp=%-6s'
              % (c['card_id'], str(meta.get('readName'))[:14], c['level'],
                 st['att'], st['def'], st['hp']))
    db.close()
    return 0


if __name__ == '__main__':
    sys.exit(main())
