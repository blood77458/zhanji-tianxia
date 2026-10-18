#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""解析客户端 Lua 注释里的 <protocol> / <bean> 协议 DSL，产出 dsl.json。

DSL 形如（全部在 Lua 行注释里）：

    -- <protocol desc="获得跨服PVP信息">
    --   <request>
    --     <property code="id" type="int" desc="编号" />
    --   </request>
    --   <response>
    --     <property code="crossVersion" type="int" desc="届数" />
    --     <list code="ranks" ref="RankInfo" desc="排行榜" />
    --   </response>
    -- </protocol>
"""
import os, re, io, sys, json, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.abspath(os.path.join(HERE, '..', 'apk_luasrc'))

RE_CLASS_DEF = re.compile(r'^[ \t]*([A-Za-z_][A-Za-z0-9_]*Request)\s*=\s*class\s*\(', re.M)
RE_PROTO_BLOCK = re.compile(r'<protocol\b([^>]*)>(.*?)</protocol>', re.S)
RE_BEAN_BLOCK = re.compile(r'<bean\b([^>]*)>(.*?)</bean>', re.S)
RE_REQUEST = re.compile(r'<request\b[^>]*>(.*?)</request>', re.S)
RE_RESPONSE = re.compile(r'<response\b[^>]*>(.*?)</response>', re.S)
RE_FIELD = re.compile(r'<(property|list)\b([^>]*?)/?>', re.S)
RE_ATTR = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"')


def decomment(lines):
    out = []
    for ln in lines:
        s = ln.strip()
        if s.startswith('--'):
            s = s[2:]
        out.append(s)
    return '\n'.join(out)


def parse_fields(text):
    fields = []
    for m in RE_FIELD.finditer(text):
        a = dict(RE_ATTR.findall(m.group(2)))
        fields.append({
            'kind': m.group(1),
            'code': a.get('code', ''),
            'type': a.get('type', ''),
            'ref': a.get('ref', ''),
            'desc': a.get('desc', ''),
        })
    return fields


protos, beans = [], []
for r, _, fs in os.walk(D):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(r, f)
        t = open(p, encoding='utf-8', errors='replace').read()
        if '<protocol' not in t and '<bean' not in t:
            continue
        rel = os.path.relpath(p, D)
        cls = [m.group(1) for m in RE_CLASS_DEF.finditer(t)]
        for m in RE_PROTO_BLOCK.finditer(t):
            body = decomment(m.group(2).split('\n'))
            attrs = dict(RE_ATTR.findall(m.group(1)))
            rm = RE_REQUEST.search(body)
            sm = RE_RESPONSE.search(body)
            protos.append({
                'file': rel,
                'line': t[:m.start()].count('\n') + 1,
                'desc': attrs.get('desc', ''),
                'classes': cls,
                'request': parse_fields(rm.group(1)) if rm else [],
                'response': parse_fields(sm.group(1)) if sm else [],
            })
        for m in RE_BEAN_BLOCK.finditer(t):
            body = decomment(m.group(2).split('\n'))
            attrs = dict(RE_ATTR.findall(m.group(1)))
            # 紧邻其上的注释行往往是 bean 名字
            head = t[:m.start()].split('\n')
            beans.append({
                'file': rel,
                'line': t[:m.start()].count('\n') + 1,
                'name': attrs.get('name', ''),
                'context': '\n'.join(x.strip().lstrip('-').strip() for x in head[-3:] if x.strip()),
                'fields': parse_fields(body),
            })

out = {'protocols': protos, 'beans': beans}
with open(os.path.join(HERE, 'dsl.json'), 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=1)

print('protocols: %d   beans: %d' % (len(protos), len(beans)))
for p in protos:
    print('  %-24s req=%d resp=%d  %s' % (p['desc'][:22], len(p['request']), len(p['response']),
                                          ','.join(p['classes'])[:40]))
