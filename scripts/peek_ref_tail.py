# -*- coding: utf-8 -*-
"""从真实抓包里把 eventFlow 抠出来看结尾，服务端对齐用。"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(open(os.path.join(ROOT, 'work', 'reference_capture',
                                'reference_decoded_2.json'), encoding='utf-8'))


def find_flow(o, out):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == 'eventFlow' and isinstance(v, list):
                out.append(v)
            find_flow(v, out)
    elif isinstance(o, list):
        for v in o:
            find_flow(v, out)


flows = []
find_flow(D, flows)
print('eventFlow 数量:', len(flows), [len(f) for f in flows])
for fi, FL in enumerate(flows):
    print('\n===== flow %d  events=%d =====' % (fi, len(FL)))
    from collections import Counter
    print('eventType:', Counter(str(e.get('eventType')) for e in FL))
    print('actionType:', Counter(str(e.get('actionType')) for e in FL))

    def acts(e):
        b = e.get('battleCardActs') or {}
        return list(b.values()) if isinstance(b, dict) else b

    for i, e in enumerate(FL[-8:], start=max(0, len(FL) - 8)):
        print(i, 'type=%s round=%s act=%s' % (e.get('eventType'), e.get('round'),
                                              e.get('actionType')),
              [(a.get('posId'), a.get('skillId'), a.get('effectId'),
                a.get('changedValue')) for a in acts(e)])
