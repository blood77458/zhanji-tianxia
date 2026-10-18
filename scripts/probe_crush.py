# -*- coding: utf-8 -*-
"""查客户端 card_meta 里某个 metaId 的 figureId，并检查 card/crush/<x>_0.png 是否存在。

用来判断「我方主角卡有没有破碎立绘」，决定战败时能不能播爆衣。
"""
import io
import os
import re
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CFG = os.path.join(ROOT, 'work', 'luasrc', 'canon', 'configs',
                   'card_meta.3461228a0516eb5739e9118a1c1fe618.lua')
APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')

MIDS = [int(x) for x in sys.argv[1:]] or [102061, 101754, 102111, 104201, 104071]


def crush_names():
    z = zipfile.ZipFile(APK)
    out = set()
    for n in z.namelist():
        if '/card/crush/' in n and n.endswith('.png'):
            out.add(os.path.basename(n).split('.')[0])
            # 物理名带 md5：xxx_0.<md5>.png
    return out


def main():
    src = io.open(CFG, encoding='utf-8', errors='replace').read()
    crush = crush_names()
    print('crush 立绘文件: %d 个' % len(crush))
    for mid in MIDS:
        i = src.find('[%d]' % mid)
        if i < 0:
            i = src.find('%d = {' % mid)
        seg = src[i:i + 900] if i >= 0 else ''
        m = re.search(r"figureId\s*=\s*['\"]([^'\"]*)", seg)
        fig = m.group(1) if m else None
        crush_id = ''
        if fig:
            parts = fig.split('_')
            parts[-1] = '0'
            crush_id = '_'.join(parts)
        ok = crush_id in crush if crush_id else False
        print('meta=%-7s figureId=%-16r crush=%-16r 存在=%s'
              % (mid, fig, crush_id, ok))
    return 0


if __name__ == '__main__':
    sys.exit(main())
