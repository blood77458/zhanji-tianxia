# -*- coding: utf-8 -*-
"""确认 Caches/src 里热补丁文件的命名规则（文件名里的 md5 到底是哪一段算的）。

结论用于 patch_flow_guard.py 决定输出文件名。
"""
import hashlib
import os
import subprocess
import sys
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import unpad              # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
PKG = 'com.happyelements.canon.baiduDK'
LOCAL = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                     'work', 'patch_out')


def pull(remote, local):
    subprocess.run([ADB, '-s', DEV, 'pull', remote, local],
                   capture_output=True, timeout=120)


def decrypt(blob):
    pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
    if pt[:1] == b'\x78':
        try:
            pt = zlib.decompress(pt)
        except Exception:
            pass
    return pt


def main():
    os.makedirs(LOCAL, exist_ok=True)
    name = 'ChapterMapScene'
    rc = subprocess.run([ADB, '-s', DEV, 'shell',
                         'ls /data/data/%s/Caches/src/canon/scene/%s.*.lua'
                         % (PKG, name)], capture_output=True, timeout=60)
    remote = rc.stdout.decode().split()[0].strip()
    src_name_md5 = remote.split('.')[-2]
    local = os.path.join(LOCAL, '_probe_%s.enc.lua' % name)
    pull(remote, local)
    blob = open(local, 'rb').read()
    pt = decrypt(blob)
    print('远程文件      :', remote)
    print('名字里的 md5  :', src_name_md5)
    print('md5(密文)     :', hashlib.md5(blob).hexdigest())
    print('md5(明文)     :', hashlib.md5(pt).hexdigest())
    print('明文长度      :', len(pt))
    return 0


if __name__ == '__main__':
    sys.exit(main())
