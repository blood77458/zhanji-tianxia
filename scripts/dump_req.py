"""打印指定 endpoint 对应的客户端请求类源码（参数名 + 期望回包字段的线索）。"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server\work\luasrc'
EP = re.compile(r'endpoint\s*=\s*"(\w+)"')

targets = set(sys.argv[1:])
if not targets:
    print('usage: dump_req.py <endpoint> [endpoint...]')
    sys.exit(1)

found = {}
for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(dp, f)
        try:
            txt = open(p, 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        for m in EP.finditer(txt):
            if m.group(1) in targets:
                found.setdefault(m.group(1), []).append((p, txt))

for t in sorted(targets):
    hits = found.get(t) or []
    print('=' * 76)
    print('### %s   (%d 个定义处)' % (t, len(hits)))
    for p, txt in hits[:1]:
        print('    file:', os.path.relpath(p, ROOT))
        lines = txt.split('\n')
        start = next((i for i, l in enumerate(lines) if 'endpoint' in l and t in l), 0)
        lo = max(0, start - 8)
        print('\n'.join(lines[lo:start + 16]))
    print()
