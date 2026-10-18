#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 schema.sql 里「十、军团」整段替换成 _guild_section.sql 的内容。"""
import io, os, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
SCHEMA = os.path.abspath(os.path.join(HERE, '..', '..', 'server', 'schema.sql'))
NEW = os.path.join(HERE, '_guild_section.sql')

lines = open(SCHEMA, encoding='utf-8').read().split('\n')
i1 = next(i for i, l in enumerate(lines) if l.startswith('--  十、军团'))
i2 = next(i for i, l in enumerate(lines) if l.startswith('--  十一、竞技'))
start = i1 - 1                      # 上面那行 '-- ===='
end = i2 - 1                        # 十一 标题上面那行 '-- ===='

new_block = open(NEW, encoding='utf-8').read().split('\n')
# 保证段末留一个空行再接 '-- ===='
while new_block and new_block[-1].strip() == '':
    new_block.pop()

out = lines[:start] + new_block + [''] + lines[end:]
open(SCHEMA, 'w', encoding='utf-8').write('\n'.join(out))
print('替换第 %d..%d 行 -> %d 行（净增 %d）'
      % (start + 1, end, len(new_block), len(new_block) - (end - start)))
