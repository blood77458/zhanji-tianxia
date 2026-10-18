"""用服务端**真实注册表**（不是正则扫描）算接口覆盖率。

输出：客户端引用数 / 服务端注册数 / 缺失清单 + 按领域分组统计。
"""
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server'
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))

from cmp_endpoints import lua_endpoints, OURS       # noqa: E402

os.chdir(os.path.join(ROOT, 'server'))
from api import load_handlers                        # noqa: E402

GROUPS = [
    ('军团/军团战', ('Union', 'union', 'Gvg', 'GVG', 'union', 'battlefield', 'Bonus', 'impeach')),
    ('跨服', ('Cross', 'cross', 'Cros', 'Match')),
    ('宝物', ('Treasure', 'treasure')),
    ('神兽/元神', ('Spirit', 'spirit', 'Beast')),
    ('背包装备', ('Item', 'Prop', 'Card', 'Equip', 'Skill', 'SubAttribute', 'synthet')),
    ('邮件/领奖', ('Email', 'email', 'Reward', 'reward', 'PickUp', 'pickUp')),
    ('活动', ('Activity', 'activity', 'Christ', 'NewYear', 'Countdown', 'Achieve', 'Charge', 'Mission', 'Energy', 'Event')),
    ('商店', ('Shop', 'shop', 'Seckill', 'seckill', 'Exchange', 'exchange', 'Recharge', 'recharge')),
]


def group_of(name):
    for g, keys in GROUPS:
        if any(k in name for k in keys):
            return g
    return '其他'


def main():
    reg = load_handlers()
    server = set(reg)
    client = lua_endpoints(OURS)

    miss = sorted(client - server)
    print('\n客户端引用 endpoint : %d' % len(client))
    print('服务端注册 endpoint : %d' % len(server))
    print('缺失                : %d' % len(miss))

    buckets = {}
    for m in miss:
        buckets.setdefault(group_of(m), []).append(m)
    print('\n--- 缺失按领域 ---')
    for g, items in sorted(buckets.items(), key=lambda kv: -len(kv[1])):
        print('  %-14s %3d 个' % (g, len(items)))
    print()
    for g, items in sorted(buckets.items(), key=lambda kv: -len(kv[1])):
        print('[%s] %d' % (g, len(items)))
        for i in range(0, len(items), 4):
            print('   ' + '  '.join('%-24s' % x for x in items[i:i + 4]))
        print()
    return 0


if __name__ == '__main__':
    sys.exit(main())
