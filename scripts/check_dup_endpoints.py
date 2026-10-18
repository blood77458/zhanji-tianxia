"""检测 endpoint 重名：同一个名字被多个 handlers 模块注册时，最后导入的会把
前面的实现**覆盖**掉 —— 新补的模块可能无意中踩坏原有功能。

做法：不依赖运行期注册表（它只保留最后一个），而是静态扫描所有 handlers_*.py
里出现的 @endpoint('name')，统计每个名字出现在哪些文件。
"""
import os
import re
import sys
from collections import defaultdict

sys.stdout.reconfigure(encoding='utf-8')
API = r'E:\deepseek_projects\app_server\server\api'
DEC = re.compile(r'@endpoint\(\s*([^)]*)\)')
NAME = re.compile(r"'([\w]+)'")


def main():
    owners = defaultdict(list)
    for fn in sorted(os.listdir(API)):
        if not (fn.startswith('handlers') and fn.endswith('.py')):
            continue
        try:
            txt = open(os.path.join(API, fn), encoding='utf-8').read()
        except Exception:
            continue
        for args in DEC.findall(txt):
            for name in NAME.findall(args):
                owners[name].append(fn)

    dup = {k: v for k, v in owners.items() if len(v) > 1}
    print('注册 endpoint 总数 %d，重名 %d 个' % (len(owners), len(dup)))
    if not dup:
        return 0

    # 已知的「故意覆盖」：基础模块里的占位实现被后面的真实现盖掉
    base = {'handlers.py', 'handlers_more.py', 'handlers_activity.py',
            'handlers_union.py', 'handlers_activity_online.py'}
    suspicious = []
    for k, v in sorted(dup.items()):
        later = [f for f in v if f not in base]
        mark = ''
        if later and any(f in base for f in v):
            mark = '  <== 基础模块被新模块覆盖'
            suspicious.append((k, v))
        print('  %-40s %s%s' % (k, ' , '.join(v), mark))
    print('\n其中「新模块覆盖基础模块」%d 个（需要逐个确认是故意的）'
          % len(suspicious))
    return 0


if __name__ == '__main__':
    sys.exit(main())
