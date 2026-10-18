"""扫描战斗 Flash 资源（.fpk / _png.plist）里的可读字符串，找动画标签与可疑贴图名。

.fpk 是 Flash(FlasCC) 导出的动画包，里面的 timeline 标签名通常是明文，
列出来就能确定「有没有一档爆衣/破损动画」。
"""
import os
import re
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')
APK = r'E:\deepseek_projects\app_server\client\zjt_pack_enablefix_signed.apk'
TARGETS = ['CardbattleXX3', 'Cardbattle_lasthit', 'Cardbattle_png']
SUSPECT = re.compile(r'(baoyi|poyi|break|crack|torn|naked|strip|damage|hurt|blood|'
                     r'dead|die|lose|down|fail|no_?cloth|nu_?de|爆|衣)', re.I)

PRINTABLE = re.compile(rb'[\x20-\x7e]{6,}')


def scan(name, blob):
    strs = []
    for m in PRINTABLE.finditer(blob):
        s = m.group(0).decode('latin-1').strip()
        if s:
            strs.append(s)
    # 去重保序
    seen, out = set(), []
    for s in strs:
        if s not in seen:
            seen.add(s)
            out.append(s)
    return out


def main():
    z = zipfile.ZipFile(APK)
    for t in TARGETS:
        for n in z.namelist():
            if t not in n or n.endswith('/'):
                continue
            blob = z.read(n)
            strs = scan(n, blob)
            base = n.split('/')[-1]
            print('==== %s (%d bytes) 可读串 %d 条 ====' % (base, len(blob), len(strs)))
            hits = [s for s in strs if SUSPECT.search(s)]
            if hits:
                print('  可疑:')
                for s in hits[:25]:
                    print('     ', s[:100])
            # 动画标签通常是短标识符，挑长度<=24 且首字母大写的
            labels = [s for s in strs if len(s) <= 24 and re.match(r'^[A-Z][A-Za-z0-9_]*$', s)]
            if labels:
                print('  疑似标签: %s' % ', '.join(dict.fromkeys(labels))[:400])
            print()
    return 0


if __name__ == '__main__':
    sys.exit(main())
