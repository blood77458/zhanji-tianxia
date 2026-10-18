# -*- coding: utf-8 -*-
"""检查客户端 manifest 里 card/crush/*.png 的条目，确认我方主角卡的破碎立绘能被解析。

逻辑名形如 `card/crush/zhugeliang_0.png`，物理名带 md5。
`BattleScene` 用的是 `fullPathForFilename("card/crush/<id>.png")`，
所以 manifest 里必须有这条逻辑名，否则 createSpriteFrame 会返回 nil。
"""
import glob
import io
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

NAMES = ['diaochan_0', 'zhugeliang_0', 'zhurong_0', 'daqiao_0', 'caiwenji_0']


def main():
    cands = []
    for pat in ('work/decoded/assets/static_config*.xml',
                'work/decoded/**/static_config*.xml'):
        cands += glob.glob(os.path.join(ROOT, pat), recursive=True)
    cands = sorted(set(cands))
    print('manifest 候选: %s' % cands[:3])
    if not cands:
        print('!! 没找到 manifest')
        return 1
    for path in cands[:1]:
        s = io.open(path, encoding='utf-8', errors='replace').read()
        hits = re.findall(r'card/crush/[^"\' <>\r\n]+', s)
        print('%s: crush 条目 %d 条' % (os.path.basename(path), len(hits)))
        for k in NAMES:
            got = [h for h in hits if k in h]
            print('  %-14s %s' % (k, got[:1] or 'MISSING'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
