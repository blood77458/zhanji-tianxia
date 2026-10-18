"""列出我们客户端里「请求类文件名 -> 实际 endpoint 字符串」的对照，
用来核对服务端是否注册了同一串。"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
EP = re.compile(r'endpoint\s*=\s*"([\w]+)"')
ROOT = r'E:\deepseek_projects\app_server\work\luasrc'

hits = []
for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        try:
            txt = open(os.path.join(dp, f), 'rb').read().decode('utf-8', 'replace')
        except Exception:
            continue
        m = EP.search(txt)
        if m:
            hits.append((f, m.group(1)))

print('请求类总数: %d\n' % len(hits))
for pat in ('SkyTower', 'Email', 'Union', 'Friend', 'Elite'):
    print('--- 文件名含 %s ---' % pat)
    for f, e in sorted(hits):
        if pat.lower() in f.lower():
            print('   %-50s %s' % (f[:50], e))
    print()
