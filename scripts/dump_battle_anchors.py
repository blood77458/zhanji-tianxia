# -*- coding: utf-8 -*-
"""打印 BattleScene 明文里若干补丁锚点的原始文本（repr），方便写精确的替换串。

只在打补丁前跑一次，确认 CRLF / 缩进 / 空格完全一致。
"""
import os
import sys
import zipfile
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import unpad              # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')

MARKERS = [
    'self.data.qte = false',
    'CCFileUtils:sharedFileUtils():setPopupNotify(true)',
    'changeAnimation(BattleAnimEnum.Lose)',
    'FightDeath then',
    'addChangeInstance("card2crash"',
]


def main():
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith('assets/src/canon/scene/')
             and n.split('/')[-1].startswith('BattleScene.')][0]
    pt = unpad(AES.new(KEY, AES.MODE_CBC, z.read(entry)[:16]).decrypt(z.read(entry)[16:]), 16)
    if pt[:1] == b'\x78':
        pt = zlib.decompress(pt)
    src = pt.decode('utf-8')
    print('条目 %s  %d 字节' % (entry, len(pt)))
    for mk in MARKERS:
        i = src.find(mk)
        print('\n=== %s  (idx=%d) ===' % (mk, i))
        if i >= 0:
            print(repr(src[max(0, i - 90):i + 130]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
