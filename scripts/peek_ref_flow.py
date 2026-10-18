# -*- coding: utf-8 -*-
"""检查真实抓包里 eventFlow 的结尾形态（用来对齐服务端发包）。"""
import json
import sys
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(ROOT, 'work', 'reference_capture', 'reference_decoded_2.json')


def walk(o, path=''):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == 'eventFlow' and isinstance(v, list) and v:
                print('FOUND %s/%s len=%d' % (path, k, len(v)))
                show(o, path)
            walk(v, path + '/' + str(k))
    elif isinstance(o, list):
        for i, v in enumerate(o):
            walk(v, path + '[%d]' % i)

def show(node, path):
    fl = node['eventFlow']
    init = node.get('cardInitDatas') or []
    hp = {}
    for u in init:
        if isinstance(u, dict):
            hp[u.get('posId')] = u.get('hp') or u.get('maxHp') or 0
    print('cardInitDatas=%d win=%r' % (len(init), node.get('win')))
    print('init hp:', {k: v for k, v in list(hp.items())[:8]})
    inc = {}
    for i, e in enumerate(fl):
        acts = e.get('battleCardActs') or []
        for a in acts:
            inc[a.get('posId')] = inc.get(a.get('posId'), 0) + (a.get('changedValue') or 0)
    print('total events=%d' % len(fl))
    print('--- last 6 ---')
    for e in fl[-6:]:
        print('  type=%s round=%s act=%s acts=%s' % (
            e.get('eventType'), e.get('round'), e.get('actionType'),
            [(a.get('posId'), a.get('skillId'), a.get('effectId'),
              a.get('changedValue')) for a in (e.get('battleCardActs') or [])]))
    print('--- first 3 ---')
    for e in fl[:3]:
        print('  type=%s round=%s act=%s acts=%s' % (
            e.get('eventType'), e.get('round'), e.get('actionType'),
            [(a.get('posId'), a.get('skillId'), a.get('effectId'),
              a.get('changedValue')) for a in (e.get('battleCardActs') or [])]))
    # eventType 分布
    from collections import Counter
    print('eventType 分布:', Counter(str(e.get('eventType')) for e in fl))
    print('actionType 分布:', Counter(str(e.get('actionType')) for e in fl))
    ets = Counter()
    for e in fl:
        for a in (e.get('battleCardActs') or []):
            ets[(a.get('effectId'), a.get('skillId'))] += 1
    print('(effectId,skillId) 分布:', ets.most_common(8))


if __name__ == '__main__':
    d = json.load(open(P, encoding='utf-8'))
    walk(d)
