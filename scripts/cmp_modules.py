"""把「单机端」和「我们」的功能模块清单拉平对比。

单机端把额外 Lua 以 package.preload["canon.xxx.Yyy"] = function() ... end
的形式塞进了 hecore/rpc.lua（build-time 内联），所以要看它的 preload 键，
而不是只看 zip 里的 .lua 文件。
"""
import os
import re
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import unpad              # noqa: E402
import zlib                                        # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
SOLO = r'C:\Users\Administrator\Downloads\base.apk.1'
OURS = r'E:\deepseek_projects\app_server\client\zjt_pack_enablefix_signed.apk'
PAT = re.compile(r'^(.*)\.([0-9a-f]{32})\.lua$')


def decrypt(blob):
    pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
    try:
        return zlib.decompress(pt)
    except Exception:
        return pt


def lua_map(apk):
    z = zipfile.ZipFile(apk)
    out = {}
    for n in z.namelist():
        if not n.startswith('assets/src/') or not n.endswith('.lua'):
            continue
        base = n.rsplit('/', 1)[-1]
        m = PAT.match(base)
        logical = n.replace('assets/src/', '').rsplit('/', 1)[0] + '/' + \
            (m.group(1) if m else base)
        out[logical.lstrip('/')] = decrypt(z.read(n))
    return out


def main():
    a = lua_map(SOLO)
    b = lua_map(OURS)

    def modules(m):
        """逻辑模块名集合：文件本身 + preload 里内联的模块。"""
        s = set()
        for k, v in m.items():
            s.add(k.replace('/', '.').replace('.lua', ''))
            try:
                txt = v.decode('utf-8', 'replace')
            except Exception:
                continue
            for name in re.findall(r'package\.preload\["([\w\.]+)"\]', txt):
                s.add(name)
        return s

    ma, mb = modules(a), modules(b)
    only_a = sorted(ma - mb)
    only_b = sorted(mb - ma)
    print('单机端模块 %d   我们模块 %d' % (len(ma), len(mb)))
    print('\n===== 单机端有、我们没有的模块 (%d) =====' % len(only_a))
    for n in only_a:
        print('  + %s' % n)
    print('\n===== 我们有、单机端没有的模块 (%d) =====' % len(only_b))
    for n in only_b:
        print('  - %s' % n)

    # 服务端接口对比：从 Lua 里挖 endpoint 名
    def endpoints(m):
        s = set()
        for v in m.values():
            txt = v.decode('utf-8', 'replace')
            s |= set(re.findall(r'endpoint\s*=\s*"(\w+)"', txt))
        return s

    ea, eb = endpoints(a), endpoints(b)
    print('\n单机端引用 endpoint %d 个 / 我们 %d 个' % (len(ea), len(eb)))
    diff = sorted(ea - eb)
    print('单机端引用了、我们客户端没引用的 endpoint: %d' % len(diff))
    for n in diff[:120]:
        print('  ? %s' % n)
    if len(diff) > 120:
        print('  ...(共 %d)' % len(diff))
    return 0


if __name__ == '__main__':
    sys.exit(main())
