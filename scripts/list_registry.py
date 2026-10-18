"""列出服务端已注册 endpoint，按动作前缀归类 —— 用来给缺失接口找「同类参照」。"""
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server\server'
sys.path.insert(0, ROOT)
os.chdir(ROOT)
from api import load_handlers                          # noqa: E402

reg = load_handlers()
names = sorted(reg)

groups = {}
for n in names:
    for pre in ('get', 'gain', 'buy', 'sell', 'refresh', 'exchange', 'apply',
                'cancel', 'challenge', 'upgrade', 'evolve', 'split', 'reset',
                'set', 'modify', 'use', 'record', 'read', 'batchDelete',
                'pickUp', 'inspire', 'send', 'accept', 'reject', 'quit',
                'construct', 'summon', 'distribute', 'impeach', 'appoint',
                'bind', 'rebirth', 'sacrifice', 'synthetize', 'lock',
                'potential', 'setup', 'test', 'clear', 'invite', 'guess',
                'upload', 'rob', 'default', 'recharge', 'start', 'answer',
                'change', 'delete', 'add', 'query', 'create', 'gain'):
        if n.startswith(pre) and len(n) > len(pre) and n[len(pre)].isupper():
            groups.setdefault(pre, []).append(n)
            break
    else:
        groups.setdefault('*', []).append(n)

for k in sorted(groups, key=lambda x: (x != '*', -len(groups[x]))):
    print('--- %s (%d) ---' % (k, len(groups[k])))
    for i in range(0, len(groups[k]), 3):
        print('   ' + '  '.join('%-30s' % x for x in groups[k][i:i + 3]))
print('\n总计 %d 个 endpoint' % len(names))
