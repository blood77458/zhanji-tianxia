"""从全量审计结果里分出：已注册但返回空壳的接口（这批同样是「点了就报错」）。"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server'
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.path.insert(0, os.path.join(ROOT, 'server', 'tests'))
os.chdir(os.path.join(ROOT, 'server'))
from api import load_handlers                                   # noqa: E402
from test_missing import client_endpoints, SKIP_SOLO_ONLY        # noqa: E402

reg = set(load_handlers())
missing = client_endpoints() - reg - SKIP_SOLO_ONLY

txt = open(os.path.join(ROOT, 'work', 'audit_all.txt'), encoding='utf-8').read()
shells = re.findall(r'\[SHELL\]\s+(\w+)', txt)
reg_shells = sorted(set(s for s in shells if s not in missing))
print('审计里 SHELL 共 %d 个；其中「已注册但空壳」%d 个：'
      % (len(set(shells)), len(reg_shells)))
for i in range(0, len(reg_shells), 3):
    print('   ' + '  '.join('%-32s' % x for x in reg_shells[i:i + 3]))
