#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""打印本地配置表的结构与样例。

用法: python confshow.py <表名> [条数]
"""
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server')))
import luaconf                                       # noqa: E402

for name in sys.argv[1:]:
    n = 3
    if ':' in name:
        name, ns = name.split(':')
        n = int(ns)
    v = luaconf.load(name)
    print('=' * 100)
    print('## %s   type=%s' % (name, type(v).__name__))
    lst = luaconf.as_list(v)
    if lst and isinstance(lst[0], dict):
        print('   共 %d 条，字段: %s' % (len(lst), ', '.join(sorted(lst[0].keys()))))
        for i, row in enumerate(lst[:n]):
            print('   [%d] %s' % (i, row))
    elif lst:
        print('   共 %d 项: %s' % (len(lst), lst[:20]))
    elif isinstance(v, dict):
        print('   字典 %d 键: %s' % (len(v), sorted(v.keys())[:30]))
        for k in sorted(v.keys())[:n]:
            print('   [%s] %s' % (k, v[k]))
    else:
        print('   ', v)
