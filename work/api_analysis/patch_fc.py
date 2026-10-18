#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 assembler.py 里两处 sharkUser/sharkUserExtend 的 fightCapacity 换成真实总战力。"""
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
P = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server', 'assembler.py'))
t = open(P, encoding='utf-8').read()
old = "'fightCapacity': int(p['fight_capacity']),"
new = ("'fightCapacity': int(fight_capacity if fight_capacity is not None"
       " else (p['fight_capacity'] or 0)),")
n = t.count(old)
t = t.replace(old, new)
open(P, 'w', encoding='utf-8').write(t)
print('替换 %d 处' % n)
