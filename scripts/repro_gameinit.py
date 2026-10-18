#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""直接调用 assembler 复现 gameInit 的 500，打印 traceback。"""
import os
import sys
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
SRV = os.path.join(os.path.dirname(HERE), 'server')
sys.path.insert(0, SRV)
os.chdir(SRV)

from db import Database           # noqa: E402
import assembler                  # noqa: E402

print('assembler functions:',
      [n for n in dir(assembler) if n.startswith('build_')])
print('DONE_TUTORIAL_STEPS =', len(getattr(assembler, 'DONE_TUTORIAL_STEPS', [])))

db = Database(os.path.join(SRV, 'canon.db'))

# 找一个 player_id
row = db.one("SELECT player_id FROM player ORDER BY player_id LIMIT 1")
pid = row['player_id'] if row else 100000
print('player_id =', pid)

fn = None
for cand in ('build_game_init', 'build_gameinit', 'game_init', 'build_init'):
    if hasattr(assembler, cand):
        fn = getattr(assembler, cand)
        break
if fn is None:
    # 退化：直接找出哪个函数引用了 tutorialSteps
    import inspect
    for name, obj in vars(assembler).items():
        if callable(obj) and getattr(obj, '__module__', '') == 'assembler':
            try:
                src = inspect.getsource(obj)
            except Exception:
                continue
            if 'tutorialSteps' in src or 'DONE_TUTORIAL_STEPS' in src:
                fn = obj
                print('candidate containing tutorialSteps:', name)
                break

if fn is None:
    print('!! 没找到 gameInit 组装函数')
    sys.exit(1)

import inspect
print('calling', fn.__name__, inspect.signature(fn))
try:
    out = fn(db, pid) if len(inspect.signature(fn).parameters) >= 2 else fn(db)
    print('OK, keys =', len(out) if hasattr(out, '__len__') else type(out))
    if isinstance(out, dict) and 'sharkUserExtend' in out:
        print('tutorialSteps sample =',
              out['sharkUserExtend'].get('tutorialSteps', [])[:3])
except Exception:
    traceback.print_exc()
