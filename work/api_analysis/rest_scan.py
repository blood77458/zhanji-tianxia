#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""列出客户端里所有非 RPC 的 HTTP 调用点（REST），含 URL 来源与参数构造。"""
import os, re, io, sys, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))

KEYS = ['CheckAndroidIdUrl', 'CheckDKIdUrl', 'CheckPlatformIdUrl', 'SessionKeyUrl',
        'ProtocolUrl', 'LoginAccountUrl', 'RegisterAccountUrl', 'GetLoginedServer',
        'ChangeAccountUrl', 'GetBoundMappingUrl', 'CheckDeviceAccountUrl',
        'ModifyPasswordUrl', 'ResetPasswordUrl', 'RebindAccountUrl',
        'BindFacebookAccountUrl', 'StaticSettingsUrl', 'DcUrl', 'LogUploadUrl']

hits = collections.defaultdict(list)
lit = collections.defaultdict(list)
for r, _, fs in os.walk(D):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(r, f)
        t = open(p, encoding='utf-8', errors='replace').read()
        rel = os.path.relpath(p, D)
        lines = t.split('\n')
        for i, ln in enumerate(lines):
            for k in KEYS:
                if 'SystemConfig.' + k in ln or ('StartupConfig' in ln and k in ln):
                    hits[k].append('%s:%d  %s' % (rel, i + 1, ln.strip()[:150]))
            for m in re.finditer(r'createPost\s*\(\s*([^)]+)\)', ln):
                lit['createPost'].append('%s:%d  %s' % (rel, i + 1, ln.strip()[:150]))
            for m in re.finditer(r'createGet\s*\(\s*([^)]+)\)', ln):
                lit['createGet'].append('%s:%d  %s' % (rel, i + 1, ln.strip()[:150]))

for k in KEYS:
    if hits[k]:
        print('### %s  (%d 处)' % (k, len(hits[k])))
        for h in hits[k][:8]:
            print('    ' + h)
        print()

for k, v in lit.items():
    print('### %s  (%d 处)' % (k, len(v)))
    for h in v[:60]:
        print('    ' + h)
