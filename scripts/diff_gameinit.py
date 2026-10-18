#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对比旧服务端 canon_server.py 与新服务端 assembler.py 的 gameInit 字段集合。

旧服务端（JSON 存档）是「已验证可玩」的参照；新服务端（SQLite 分层）如果漏字段，
客户端就会出现 `attempt to compare/index ... nil` 之类的崩溃。
本脚本用 ast 找出各自最大的 dict 字面量，比较键集合，输出疑似漏掉的字段。
"""
import ast
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def big_dicts(path):
    src = open(path, encoding='utf-8', errors='replace').read()
    tree = ast.parse(src)
    out = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Dict):
            keys = [k.value for k in node.keys
                    if isinstance(k, ast.Constant) and isinstance(k.value, str)]
            if len(keys) >= 8:
                out.append((node.lineno, keys))
    out.sort(key=lambda x: -len(x[1]))
    return out


def dicts_with(path, needle):
    """返回所有含指定键的 dict 字面量 (lineno, keys)。"""
    src = open(path, encoding='utf-8', errors='replace').read()
    tree = ast.parse(src)
    out = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Dict):
            keys = [k.value for k in node.keys
                    if isinstance(k, ast.Constant) and isinstance(k.value, str)]
            if needle in keys:
                out.append((node.lineno, keys))
    out.sort(key=lambda x: -len(x[1]))
    return out


def main():
    old = os.path.join(ROOT, 'server', 'canon_server.py')
    new = os.path.join(ROOT, 'server', 'assembler.py')

    # gameInit 根 = 含 'sharkUser' 的 dict
    o = dicts_with(old, 'sharkUser')
    n = dicts_with(new, 'sharkUser')
    if not o or not n:
        print('未找到 gameInit 根（含 sharkUser 的 dict）'); return 1

    print('旧 canon_server.py 里含 sharkUser 的 dict:', [(l, len(k)) for l, k in o])
    print('新 assembler.py    里含 sharkUser 的 dict:', [(l, len(k)) for l, k in n])
    print()

    ol, ok = o[0]
    nl, nk = n[0]
    so, sn = set(ok), set(nk)
    print('=== gameInit 根字段对比 ===')
    print('旧 L%-5d keys=%d' % (ol, len(so)))
    print('新 L%-5d keys=%d' % (nl, len(sn)))
    print()
    only_old = sorted(so - sn)
    only_new = sorted(sn - so)
    print('--- 旧有新无（疑似漏下发）: %d ---' % len(only_old))
    for k in only_old:
        print('   -', k)
    print()
    print('--- 新有旧无: %d ---' % len(only_new))
    for k in only_new:
        print('   +', k)
    print()
    print('--- 共有: %d ---' % len(so & sn))

    # 再比 sharkUserExtend（含 tutorialSteps 的 dict）
    print()
    oe = dicts_with(old, 'tutorialSteps')
    ne = dicts_with(new, 'tutorialSteps')
    if oe and ne:
        se_o, se_n = set(oe[0][1]), set(ne[0][1])
        print('=== sharkUserExtend 对比 (旧 %d / 新 %d) ==='
              % (len(se_o), len(se_n)))
        miss = sorted(se_o - se_n)
        print('旧有新无: %s' % (miss or '（无）'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
