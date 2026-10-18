# -*- coding: utf-8 -*-
"""查 luaconf 解析配置表时为什么丢行。

现象：skill_status 的 lua 文件里有 1860 条 `[id]={...}`，
但 luaconf.load('skill_status') 只拿到 1850 条，且缺的正好是技能引用的
(630501 等) 那些 —— 直接影响战斗技能/状态的计算。
"""
import glob
import io
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))

import luaconf  # noqa: E402


def main(name='skill_status'):
    path = glob.glob(os.path.join(ROOT, 'work', 'luasrc', 'canon', 'configs',
                                  name + '.*.lua'))[0]
    src = io.open(path, encoding='utf-8').read()
    ids = [int(x) for x in re.findall(r'\[(\d+)\]\s*=\s*\{', src)]
    tab = luaconf.load(name)
    keys = set()
    if isinstance(tab, dict):
        for k in tab:
            try:
                keys.add(int(k))
            except (TypeError, ValueError):
                pass
    elif isinstance(tab, list):
        for r in tab:
            if isinstance(r, dict):
                keys.add(int(r.get('id') or r.get('statusId') or 0))
    print('%s: 文件里 %d 条，解析出 %d 条' % (name, len(ids), len(keys)))
    miss = [i for i in ids if i not in keys]
    print('缺失 %d 条: %s%s' % (len(miss), miss[:20], ' ...' if len(miss) > 20 else ''))
    if miss:
        # 找出第一条缺失记录的原文，看是不是格式特殊
        m = re.search(r'\n\s*\[%d\]\s*=\s*\{' % miss[0], src)
        if m:
            seg = src[m.start():m.start() + 300]
            print('\n第一条缺失记录原文:\n%s' % seg)
        else:
            print('（原文里搜不到，说明是被后续覆盖或被解析成别的键）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
