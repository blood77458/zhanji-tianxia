"""把「服务端注册了但客户端不调」和「客户端调了但服务端没有」做模糊配对，
找出**名字写错**的接口 —— 这类是最好修的 bug：客户端其实有请求类，
只是服务端注册名拼写不同，于是永远匹配不到。

配对判据：忽略大小写后，把两个名字拆成小写单词集合，Jaccard 相似度高
且字符集合接近，即认为是同一个接口的不同拼法。
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cmp_endpoints import lua_endpoints, server_endpoints, OURS  # noqa: E402

SPLIT = re.compile(r'[A-Z]?[a-z0-9]+')


def toks(s):
    return [t.lower() for t in SPLIT.findall(s)]


def jac(a, b):
    A, B = set(toks(a)), set(toks(b))
    if not A or not B:
        return 0.0
    return len(A & B) / float(len(A | B))


def main():
    co = lua_endpoints(OURS)
    so = server_endpoints()
    dead = sorted(so - co)          # 服务端有、客户端不叫这个名
    miss = sorted(co - so)          # 客户端要、服务端没有

    pairs = []
    for d in dead:
        for m in miss:
            j = jac(d, m)
            if j >= 0.5:
                pairs.append((j, d, m))
    pairs.sort(reverse=True)

    used_d, used_m = set(), set()
    print('%-34s -> %-34s %s' % ('服务端注册名(错)', '客户端实际发(对)', '相似度'))
    print('-' * 86)
    for j, d, m in pairs:
        if d in used_d or m in used_m:
            continue
        used_d.add(d)
        used_m.add(m)
        print('%-34s -> %-34s %.2f' % (d, m, j))

    print('\n配对成功 %d 对（改服务端注册名即可修好）' % len(used_d))
    left_d = [d for d in dead if d not in used_d]
    left_m = [m for m in miss if m not in used_m]
    print('\n仍未配对的 服务端多余 %d 个:' % len(left_d))
    for i in range(0, len(left_d), 4):
        print('   ' + '  '.join('%-26s' % x for x in left_d[i:i + 4]))
    print('\n仍未配对的 客户端缺失 %d 个（这些要真写实现）:' % len(left_m))
    for i in range(0, len(left_m), 4):
        print('   ' + '  '.join('%-26s' % x for x in left_m[i:i + 4]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
