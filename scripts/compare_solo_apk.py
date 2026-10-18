"""对比「纯单机端」（Downloads/base.apk.1）与我们手上的联网端 APK。

只读 zip 目录，不解压全部，先把结构差异摸清楚。
"""
import os
import re
import sys
import zipfile
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

SOLO = r'C:\Users\Administrator\Downloads\base.apk.1'
OURS = r'E:\deepseek_projects\app_server\client\zjt_pack_enablefix_signed.apk'


def summarize(path, tag):
    z = zipfile.ZipFile(path)
    names = z.namelist()
    print('==== %s ====' % tag)
    print('  文件数 : %d' % len(names))
    # 顶层目录分布
    top = Counter()
    for n in names:
        parts = n.split('/')
        top['/'.join(parts[:2]) if len(parts) > 1 else parts[0]] += 1
    for k, v in top.most_common(18):
        print('   %-42s %5d' % (k, v))
    # static_config 清单
    man = [n for n in names if 'static_config' in n]
    print('  manifest: %s' % (man[:2] or '无'))
    # lua 文件
    luas = [n for n in names if n.endswith('.lua')]
    print('  .lua    : %d 个' % len(luas))
    if luas[:3]:
        for n in luas[:3]:
            print('     e.g. %s' % n)
    # 引擎 so
    sos = [n for n in names if n.endswith('.so')]
    print('  .so     :')
    for n in sos[:12]:
        print('     %-60s %10d' % (n, z.getinfo(n).file_size))
    # AndroidManifest / dex
    for key in ('AndroidManifest.xml',):
        if key in names:
            print('  %s: %d bytes' % (key, z.getinfo(key).file_size))
    dex = [n for n in names if n.endswith('.dex')]
    print('  dex     : %s' % ', '.join('%s(%d)' % (n, z.getinfo(n).file_size) for n in dex))
    return names, z


n1, z1 = summarize(SOLO, '纯单机端 base.apk.1')
n2, z2 = summarize(OURS, '我们的联网端 zjt_pack_enablefix_signed.apk')

s1, s2 = set(n1), set(n2)
print('\n==== 结构差异 ====')
print('  单机端独有 : %d 个' % len(s1 - s2))
for n in sorted(s1 - s2)[:40]:
    print('     + %s' % n)
print('  我们独有   : %d 个' % len(s2 - s1))
for n in sorted(s2 - s1)[:40]:
    print('     - %s' % n)
