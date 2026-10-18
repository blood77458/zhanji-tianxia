#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把所有「列表型参数」的读取方式改成 api.list_param / int_list_param。

背景：AMF3 密集数组解码回来是 {1:a,2:b} 的 Lua 表，
     直接迭代拿到的是下标而不是元素。
"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server', 'api'))

# (文件名, 旧写法, 新写法)
SUBS = [
    ('handlers.py',
     "api.param(params, 'slaveIds') or []",
     "api.int_list_param(params, 'slaveIds')"),
    ('handlers.py',
     "api.param(params, 'slaveIds')",
     "api.int_list_param(params, 'slaveIds')"),
    ('handlers.py',
     "api.param(params, 'cardIds') or []",
     "api.int_list_param(params, 'cardIds')"),
    ('handlers.py',
     "api.param(params, 'equipIds') or []",
     "api.int_list_param(params, 'equipIds')"),
    ('handlers.py',
     "api.param(params, 'equipIds')",
     "api.int_list_param(params, 'equipIds')"),
    ('handlers.py',
     "api.param(params, 'cardGroupInterworking') or []",
     "api.list_param(params, 'cardGroupInterworking')"),
    ('handlers.py',
     "ids = v if isinstance(v, list) else [v]",
     "ids = to_list(v)"),
    ('handlers.py',
     "from . import endpoint, ApiError",
     "from . import endpoint, ApiError, to_list, to_int_list"),
    ('handlers_more.py',
     "api.param(params, 'friendUids') or ([api.param(params, 'friendUid')]",
     "api.int_list_param(params, 'friendUids') or ([api.param(params, 'friendUid')]"),
    ('handlers_more.py',
     "groups = params or []",
     "groups = to_list(params)"),
]

total = 0
for fn, old, new in SUBS:
    p = os.path.join(ROOT, fn)
    t = open(p, encoding='utf-8').read()
    if old in t:
        t = t.replace(old, new)
        open(p, 'w', encoding='utf-8').write(t)
        total += 1
        print('  %-20s %s' % (fn, old[:52]))
print('共替换 %d 处' % total)

# 复查还有没有裸迭代列表参数的地方
print()
print('复查（应只剩非列表参数）:')
for fn in ('handlers.py', 'handlers_more.py', 'handlers_activity.py', 'handlers_union.py'):
    p = os.path.join(ROOT, fn)
    t = open(p, encoding='utf-8').read()
    for m in re.finditer(r"api\.param\(params, '([A-Za-z]*[Ii]ds|[A-Za-z]*[Ll]ist)'[^)]*\)", t):
        print('  %-20s %s' % (fn, m.group(0)))
