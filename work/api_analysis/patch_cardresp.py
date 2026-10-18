#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""卡牌操作响应统一包成 {'sharkCard': {...}}（客户端契约要求）。"""
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
P = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server',
                                 'services', 'asset.py'))
t = open(P, encoding='utf-8').read()

# 1) 在 _card_payload 后面加一个包装版
anchor = ("    def _card_payload(self, player_id, card_id):")
helper = '''    def _card_resp(self, player_id, card_id):
        """卡牌操作接口的响应：客户端读的是 `sharkCard` 这个键。"""
        return {'sharkCard': self._card_payload(player_id, card_id)}

'''
if '_card_resp' not in t:
    t = t.replace(anchor, helper + anchor, 1)

# 2) 这些方法改返回包装版
WRAP_METHODS = ('upgrade_card', 'upgrade_card_by_general_exp', 'evolve_card',
                'save_card_train', 'give_up_card_train')
out, cur = [], None
for line in t.split('\n'):
    m = None
    for name in WRAP_METHODS:
        if line.startswith('    def %s(' % name):
            m = name
            break
    if m:
        cur = m
    elif line.startswith('    def ') and not line.startswith('    def _'):
        cur = None
    if cur and 'return OK, self._card_payload(player_id, card_id)' in line:
        line = line.replace('self._card_payload(player_id, card_id)',
                            'self._card_resp(player_id, card_id)')
    out.append(line)
t = '\n'.join(out)
open(P, 'w', encoding='utf-8').write(t)
print('_card_resp 已加入:', '_card_resp(self, player_id, card_id)' in t)
print('包装后的返回处:', t.count('self._card_resp(player_id, card_id)'))
