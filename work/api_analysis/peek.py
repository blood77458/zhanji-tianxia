#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""人工抽查 endpoints.raw.json。"""
import json, os, sys, collections

here = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(here, 'endpoints.raw.json'), encoding='utf-8'))
EPS = d['endpoints']
CLS = d['classes']

arg = sys.argv[1] if len(sys.argv) > 1 else '--stats'

if arg == '--stats':
    print('endpoints: %d   classes: %d' % (len(EPS), len(CLS)))
    c = collections.Counter(len(v['params']) for v in EPS.values())
    print('\n== 参数个数分布 ==')
    for k in sorted(c):
        print('  %3d : %d' % (k, c[k]))
    print('\n== 无 endpoint 的类 ==')
    for k, v in CLS.items():
        if not v['endpoint']:
            print('  %-45s %s  expr=%s' % (k, v['file'], v['endpoint_expr']))
    print('\n== 未被调用点覆盖的类 ==')
    used = set()
    for v in EPS.values():
        used.update(v['classes'])
    miss = [k for k in CLS if k not in used and CLS[k]['endpoint']]
    print('  %d: %s' % (len(miss), ', '.join(miss)))
    print('\n== 未知类 ==')
    for k, v in d['unknown_classes'].items():
        print('  %-50s %d' % (k, v))
    print('\n== *dynamic* 参数较多的接口 ==')
    n = 0
    for k, v in EPS.items():
        if '*dynamic*' in v['params']:
            n += 1
    print('  %d 个接口含动态参数' % n)
    print('\n== 含响应字段推断的类数 ==')
    print('  %d' % sum(1 for v in CLS.values() if v.get('response_fields')))
    sys.exit()

if arg == '--unknown':
    for k, v in d['unknown_classes'].items():
        print('%-50s %d' % (k, v))
    sys.exit()

if arg == '--response':
    for ep in sys.argv[2:]:
        v = EPS.get(ep)
        if not v:
            print('!! no endpoint %s' % ep)
            continue
        print('=== %s  classes=%s' % (ep, ','.join(v['classes'])))
        for c in v['classes']:
            ci = CLS.get(c, {})
            print('   %s -> events=%s' % (c, ci.get('success_events')))
            rf = ci.get('response_fields') or {}
            if rf:
                print('      response fields: %s' % ', '.join('%s(%d)' % (k, n) for k, n in
                                                              sorted(rf.items(), key=lambda x: -x[1])))
    sys.exit()

for ep in sys.argv[1:]:
    v = EPS.get(ep)
    if not v:
        print('!! no such endpoint: %s' % ep)
        continue
    print('=== %s' % ep)
    print('  classes: %s' % ', '.join(v['classes']))
    print('  call sites: %d' % len(v['callsites']))
    for f in sorted(set(c['file'] for c in v['callsites'])):
        print('     - %s' % f)
    print('  params:')
    for k, pv in v['params'].items():
        print('     %-26s values=%s' % (k, ' | '.join(pv['values'][:3])))
    for c in v['classes']:
        ci = CLS.get(c)
        if ci:
            print('  [%s] events=%s files=%s' % (c, ci['success_events'], ci['files']))
            rf = ci.get('response_fields') or {}
            if rf:
                print('      resp: %s' % ', '.join(sorted(rf)))
