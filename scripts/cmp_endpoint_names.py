"""检查服务端「注册了但客户端不调用」的 55 个里，有多少其实是**名字写错了**。

判据：忽略大小写后与客户端某个 endpoint 相同 -> 几乎可以肯定是注册名错误
（客户端实际发的是另一个拼写，服务端永远匹配不到，表现为「点了没反应/报错」）。
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cmp_endpoints import lua_endpoints, server_endpoints, OURS  # noqa: E402


def main():
    co = lua_endpoints(OURS)
    so = server_endpoints()
    low = {x.lower(): x for x in co}
    dead = sorted(so - co)

    print('服务端注册但客户端不调用: %d 个\n' % len(dead))
    same = []
    for d in dead:
        hit = low.get(d.lower())
        if hit:
            same.append((d, hit))
    print('--- 忽略大小写后能对上（极可能是拼写/大小写 bug）: %d ---' % len(same))
    for d, hit in same:
        print('   服务端 %-30s <-> 客户端 %s' % (d, hit))

    rest = [d for d in dead if d.lower() not in low]
    print('\n--- 确实客户端不调用的: %d ---' % len(rest))
    for i in range(0, len(rest), 4):
        print('   ' + '  '.join('%-26s' % x for x in rest[i:i + 4]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
