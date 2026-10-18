"""给每个「缺失接口」在**完整注册表**里找最相近的已实现接口。

相似度够高（>=0.5）的多半是同一功能的不同拼写/近义词，可以直接别名或薄封装；
相似度低的才是真的要从头写。
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server'
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.path.insert(0, os.path.join(ROOT, 'server', 'tests'))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
os.chdir(os.path.join(ROOT, 'server'))
from api import load_handlers                       # noqa: E402
from test_missing import client_endpoints, SKIP_SOLO_ONLY   # noqa: E402

SPLIT = re.compile(r'[A-Z]?[a-z0-9]+')


def toks(s):
    return set(t.lower() for t in SPLIT.findall(s))


def jac(a, b):
    A, B = toks(a), toks(b)
    return len(A & B) / float(len(A | B)) if A and B else 0.0


def main():
    reg = load_handlers()
    miss = sorted(client_endpoints() - set(reg) - SKIP_SOLO_ONLY)
    print('缺失 %d 个\n' % len(miss))
    hi, mid, low = [], [], []
    for m in miss:
        best = max(((jac(m, r), r) for r in reg), key=lambda x: x[0])
        (hi if best[0] >= 0.6 else mid if best[0] >= 0.4 else low).append((m, best[1], best[0]))
    for title, group in (('可直接别名/薄封装 (>=0.60)', hi),
                         ('需要确认 (0.40-0.60)', mid),
                         ('真的要写 (<0.40)', low)):
        print('=' * 78)
        print('%s   共 %d' % (title, len(group)))
        print('=' * 78)
        for m, r, s in group:
            print('  %-38s ~ %-34s %.2f' % (m, r, s))
        print()
    return 0


if __name__ == '__main__':
    sys.exit(main())
