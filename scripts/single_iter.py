# -*- coding: utf-8 -*-
"""S1 自动迭代器：反复「启动客户端 → 收集 unhandled → 补进快照 → 重部署」，
直到客户端不再要新方法为止。

用法:
    python scripts/single_iter.py              # 最多 6 轮
    python scripts/single_iter.py --rounds 10
    python scripts/single_iter.py --wait 30

机制：
  * 新方法写进 `work/proto_methods.txt`（一行一个），`gen_proto_snapshot.py` 会读它；
  * 每轮：single_boot（重启 + 点游客登录）→ 从 logcat 抓 `unhandled X`
    → 追加 → 重新生成 proto_capture / proto_data.lua → deploy_single --lua；
  * 没有任何 unhandled 就停下（说明这一层齐了）。
"""
import os
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
METHODS_FILE = os.path.join(ROOT, 'work', 'proto_methods.txt')
PY = sys.executable


def run(args, timeout=600):
    r = subprocess.run([PY] + args, cwd=ROOT, capture_output=True, timeout=timeout)
    return (r.stdout or b'').decode('utf-8', 'replace') + \
           (r.stderr or b'').decode('utf-8', 'replace')


def boot(wait=32):
    out = run(['scripts/single_boot.py', '--wait', str(wait)])
    unhandled = re.findall(r'unhandled ([A-Za-z_0-9]+)', out)
    return sorted(set(unhandled)), out


def load_methods():
    if not os.path.exists(METHODS_FILE):
        return []
    return [l.strip() for l in open(METHODS_FILE, encoding='utf-8')
            if l.strip() and not l.startswith('#')]


def save_methods(names):
    seen = []
    for n in names:
        if n not in seen:
            seen.append(n)
    open(METHODS_FILE, 'w', encoding='utf-8').write('\n'.join(seen) + '\n')
    return seen


def main():
    rounds = 6
    wait = 32
    if '--rounds' in sys.argv:
        rounds = int(sys.argv[sys.argv.index('--rounds') + 1])
    if '--wait' in sys.argv:
        wait = int(sys.argv[sys.argv.index('--wait') + 1])

    methods = load_methods()
    print('已知附加方法 %d 个' % len(methods), flush=True)

    for i in range(1, rounds + 1):
        print('\n================ 第 %d 轮 ================' % i, flush=True)
        unhandled, out = boot(wait)
        if not unhandled:
            print('没有新的 unhandled，这一层齐了。')
            tail = [l for l in out.split('\n') if 'SINGLE' in l][-6:]
            for l in tail:
                print('  ' + l.strip()[:130])
            return 0
        print('新方法: %s' % ' '.join(unhandled))
        methods = save_methods(methods + unhandled)
        print('重新生成快照…', flush=True)
        print(run(['scripts/gen_proto_snapshot.py']).split('\n')[-2])
        print(run(['scripts/gen_proto_lua.py']).split('\n')[-2])
        print(run(['scripts/deploy_single.py', '--lua']).split('\n')[-2])
    print('\n达到轮数上限，仍未收敛；继续跑一次 --rounds 看剩余清单。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
