"""功能覆盖对照：客户端引用的 endpoint vs 我们服务端真正实现的 endpoint。

三个集合：
  C_ours  = 我们客户端 Lua 里出现的 endpoint
  C_solo  = 单机端客户端 Lua 里出现的 endpoint
  S_ours  = 我们 Python 服务端注册的 endpoint

关键指标：
  C_ours - S_ours  -> 客户端会调、我们没实现（点了就报错的就是这些）
  C_solo - C_ours  -> 单机端有、我们客户端还没有的功能入口
"""
import os
import re
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')
import zlib                                        # noqa: E402
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import unpad              # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ROOT = r'E:\deepseek_projects\app_server'
SOLO = r'C:\Users\Administrator\Downloads\base.apk.1'
OURS = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')
PAT = re.compile(r'^(.*)\.([0-9a-f]{32})\.lua$')
EP = re.compile(r'endpoint\s*=\s*"(\w+)"')
DEC = re.compile(r'@endpoint\(([^)]*)\)')


def lua_endpoints(apk):
    z = zipfile.ZipFile(apk)
    s = set()
    for n in z.namelist():
        if not n.startswith('assets/src/') or not n.endswith('.lua'):
            continue
        blob = z.read(n)
        try:
            pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
            try:
                pt = zlib.decompress(pt)
            except Exception:
                pass
            txt = pt.decode('utf-8', 'replace')
        except Exception:
            continue
        s |= set(EP.findall(txt))
    return s


def server_endpoints():
    s = set()
    srv = os.path.join(ROOT, 'server')
    for dp, _, fs in os.walk(srv):
        for f in fs:
            if not f.endswith('.py'):
                continue
            try:
                txt = open(os.path.join(dp, f), encoding='utf-8', errors='replace').read()
            except Exception:
                continue
            for args in DEC.findall(txt):
                for m in re.findall(r"'([\w]+)'", args):
                    s.add(m)
    return s


def main():
    co = lua_endpoints(OURS)
    cs = lua_endpoints(SOLO)
    so = server_endpoints()
    print('客户端引用 endpoint:  我们 %d   单机端 %d' % (len(co), len(cs)))
    print('服务端注册 endpoint:  我们 %d' % len(so))

    miss = sorted(co - so)
    print('\n[!] 我们客户端会调用、但服务端没实现: %d 个' % len(miss))
    for i in range(0, len(miss), 4):
        print('   ' + '  '.join('%-26s' % x for x in miss[i:i + 4]))

    extra = sorted(cs - co)
    print('\n[+] 单机端客户端多出来的 endpoint: %d 个' % len(extra))
    for x in extra:
        print('   %s' % x)

    print('\n[=] 服务端已实现、但客户端目前不调用: %d 个' % len(so - co))
    dead = sorted(so - co)
    for i in range(0, len(dead), 6):
        print('   ' + '  '.join('%-24s' % x for x in dead[i:i + 6]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
