"""量化单机端 hecore/rpc.lua 里内联（build-time 打包）了哪些模块、各占多少行。"""
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
SOLO = r'E:\deepseek_projects\app_server\work\lua_cmp\solo_hecore_rpc'
OURS = r'E:\deepseek_projects\app_server\work\lua_cmp\ours_hecore_rpc'

RE = re.compile(r'package\.preload\["([\w\.]+)"\]\s*=\s*function')


def blocks(path):
    lines = open(path, 'rb').read().decode('utf-8', 'replace').split('\n')
    idx = [(i, m.group(1)) for i, l in enumerate(lines)
           for m in [RE.match(l)] if m]
    out = []
    for k, (i, name) in enumerate(idx):
        end = idx[k + 1][0] if k + 1 < len(idx) else len(lines)
        out.append((name, end - i, i))
    return lines, out


for tag, path in (('单机端', SOLO), ('我们', OURS)):
    lines, bl = blocks(path)
    print('===== %s  hecore/rpc.lua  共 %d 行 =====' % (tag, len(lines)))
    head = bl[0][2] if bl else len(lines)
    print('  文件头裸代码: %d 行   内联模块: %d 个' % (head, len(bl)))
    for name, n, i in bl:
        print('    %-56s %7d 行' % (name, n))
    print()
