"""解密两个 APK 里的全部 Lua，按「逻辑路径」(去掉 .<md5>) 对齐后逐文件对比。

纯单机端 vs 我们的联网端 —— 直接回答「功能差多少」。
"""
import hashlib
import os
import re
import sys
import zipfile
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import unpad              # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
SOLO = r'C:\Users\Administrator\Downloads\base.apk.1'
OURS = r'E:\deepseek_projects\app_server\client\zjt_pack_enablefix_signed.apk'
OUT = r'E:\deepseek_projects\app_server\work\lua_cmp'
PAT = re.compile(r'^(.*)\.([0-9a-f]{32})\.lua$')


def decrypt(blob):
    """IV(16) || AES-128-CBC(PKCS#7(zlib(源码)))"""
    if len(blob) < 32 or (len(blob) - 16) % 16:
        raise ValueError('bad len %d' % len(blob))
    pt = AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:])
    pt = unpad(pt, 16)
    try:
        return zlib.decompress(pt)
    except Exception:
        return pt


def load(apk, tag):
    z = zipfile.ZipFile(apk)
    out, bad = {}, []
    for n in z.namelist():
        if not n.startswith('assets/src/') or not n.endswith('.lua'):
            continue
        base = n.rsplit('/', 1)[-1]
        m = PAT.match(base)
        logical = (n.rsplit('/', 1)[0] + '/' + (m.group(1) if m else base))
        try:
            out[logical] = decrypt(z.read(n))
        except Exception as e:
            bad.append((logical, str(e)))
    print('[%s] 解密成功 %d / 失败 %d' % (tag, len(out), len(bad)))
    for b in bad[:5]:
        print('    FAIL %s : %s' % b)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    a = load(SOLO, '单机端')
    b = load(OURS, '联网端')

    only_a = sorted(set(a) - set(b))
    only_b = sorted(set(b) - set(a))
    both = sorted(set(a) & set(b))
    diff = [p for p in both if hashlib.md5(a[p]).digest() != hashlib.md5(b[p]).digest()]

    print('\n==== 结论 ====')
    print('  仅单机端有 : %d' % len(only_a))
    print('  仅联网端有 : %d' % len(only_b))
    print('  两边都有   : %d' % len(both))
    print('  内容不同   : %d' % len(diff))

    if only_a:
        print('\n--- 仅单机端有（我们缺的代码）---')
        for p in only_a:
            print('   + %s' % p)
    if only_b:
        print('\n--- 仅联网端有（单机端没有 / 我们改过的）---')
        for p in only_b[:60]:
            print('   - %s' % p)
    if diff:
        print('\n--- 内容不同 ---')
        for p in diff:
            rel = p.replace('assets/src/', '').replace('/', '_')
            open(os.path.join(OUT, 'solo_' + rel), 'wb').write(a[p])
            open(os.path.join(OUT, 'ours_' + rel), 'wb').write(b[p])
            print('   ~ %-70s solo=%d ours=%d' % (p.replace('assets/src/', ''),
                                                 len(a[p]), len(b[p])))
        print('\n  差异文件已落到 %s (solo_* / ours_*)' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
