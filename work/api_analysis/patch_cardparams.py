#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""修正卡牌操作接口的契约：
  1) 参数名是 masterId（不是 cardId）
  2) 响应要包成 {'sharkCard': ...}
"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server'))

# ---- handlers.py: cardId -> masterId 兜底 ----
H = os.path.join(ROOT, 'api', 'handlers.py')
t = open(H, encoding='utf-8').read()
subs = [
    ("api.param(params, 'cardId')", "api.param(params, 'masterId', api.param(params, 'cardId'))"),
    ("api.param(params, 'cardId'), api.param(params, 'slaveIds')",
     "api.param(params, 'masterId', api.param(params, 'cardId')), api.param(params, 'slaveIds')"),
    ("api.param(params, 'cardId'), bool(api.param(params, 'useGold', True))",
     "api.param(params, 'masterId', api.param(params, 'cardId')),"
     " bool(api.param(params, 'useGold', True))"),
    ("api.param(params, 'cardId'), api.param(params, 'targetLevel', 1)",
     "api.param(params, 'masterId', api.param(params, 'cardId')),"
     " api.param(params, 'targetLevel', 1)"),
    ("api.param(params, 'cardId'), api.param(params, 'metaId', 0)",
     "api.param(params, 'masterId', api.param(params, 'cardId')),"
     " api.param(params, 'metaId', 0)"),
]
n = 0
for a, b in subs:
    if a in t:
        t = t.replace(a, b)
        n += 1
open(H, 'w', encoding='utf-8').write(t)
print('handlers.py 替换 %d 处' % n)
left = re.findall(r"api\.param\(params, 'cardId'\)", t)
print('剩余裸 cardId:', len(left))
