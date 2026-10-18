"""逐个说明单机端内联的 11 个模块：注释头 + endpoint + 规模。"""
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
SRC = r'E:\deepseek_projects\app_server\work\lua_cmp\solo_hecore_rpc'
RE = re.compile(r'package\.preload\["([\w\.]+)"\]\s*=\s*function')
EP = re.compile(r'endpoint\s*=\s*"(\w+)"')

lines = open(SRC, 'rb').read().decode('utf-8', 'replace').split('\n')
idx = [(i, m.group(1)) for i, l in enumerate(lines)
       for m in [RE.match(l)] if m]

for k, (i, name) in enumerate(idx):
    end = idx[k + 1][0] if k + 1 < len(idx) else len(lines)
    body = '\n'.join(lines[i:end])
    head = []
    for l in lines[i:i + 14]:
        s = l.strip()
        if s.startswith('--') and not s.startswith('----'):
            head.append(s)
        if len(head) >= 4:
            break
    eps = sorted(set(EP.findall(body)))
    print('### %s   (%d 行)' % (name, end - i))
    for h in head:
        print('    ' + h[:150])
    if eps:
        print('    endpoint: ' + ', '.join(eps))
    if name == 'hecore.offline_activities':
        keys = sorted(set(re.findall(r'\["(\w+Config\w*|\w+Meta\w*)"\]\s*=', body)))
        print('    内含配置块: %d 个' % len(keys))
        print('    ' + ', '.join(keys[:26]))
    print()
