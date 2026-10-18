#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按关键字列出一组接口的契约（请求参数 + 客户端读取的响应字段 + 调用点）。

用法: python contract.py <关键字正则> [关键字正则...]
"""
import io
import json
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
REC = json.load(open(os.path.join(HERE, 'records.json'), encoding='utf-8'))

for pat in (sys.argv[1:] or ['.']):
    rx = re.compile(pat, re.I)
    rows = [r for r in REC if rx.search(r['method'])]
    print('=' * 100)
    print('## /%s/  命中 %d 个接口' % (pat, len(rows)))
    for r in sorted(rows, key=lambda x: x['method']):
        ps = sorted(k for k in r['params'] if k not in ('*dynamic*', 'serverId'))
        rf = sorted(r['response_fields'].items(), key=lambda x: -x[1])
        print()
        print('  %s   %s' % (r['method'], r['desc'][:40]))
        print('     请求参数: %s' % (', '.join(ps) or '—'))
        print('     响应字段: %s' % (', '.join(k for k, _ in rf[:14]) or '—'))
        files = sorted(set(c['file'].split('\\')[-1].split('.')[0] for c in r['callsites']))
        print('     调用点  : %s' % ', '.join(files[:4]))
