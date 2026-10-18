# -*- coding: utf-8 -*-
"""一键引导：从你自己的 APK 里解出运行所需的配置，然后初始化数据库。

仓库里**故意不包含**原游戏的解包产物（它们是乐元素的版权物，不适合随仓库分发），
所以第一次运行前要先跑这个脚本。它会做三件事：

  1. 从 APK 的 `assets/src/` 里解开所有 Lua（AES-128-CBC + zlib）到 `work/luasrc/`；
     只解 `canon/configs/*`、`canon/scene/*`、`canon/models/*` 等运行需要的部分，
     美术资源不动（服务端用不到）。
  2. 生成 `server/card_dict.json`（build_card_dict 会从配置里推导）。
  3. 初始化 `server/canon.db`（建表）。

用法:
    python scripts/bootstrap.py                     # 自动找 client/*.apk
    python scripts/bootstrap.py --apk D:\\path\\to.apk
    python scripts/bootstrap.py --force             # 强制重新解包

依赖: pycryptodome (`pip install -r requirements.txt`)
"""
import argparse
import glob
import os
import subprocess
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')

from Crypto.Cipher import AES                        # noqa: E402
from Crypto.Util.Padding import unpad                # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUASRC = os.path.join(ROOT, 'work', 'luasrc')
SERVER = os.path.join(ROOT, 'server')

# 只解这些子目录（服务端只需要配置和少量逻辑参考）
WANTED = ('assets/src/canon/configs/', 'assets/src/canon/models/',
          'assets/src/canon/data/', 'assets/src/canon/scene/',
          'assets/src/hecore/')


def decrypt(blob):
    pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
    if pt[:1] == b'\x78':                 # zlib magic
        import zlib
        try:
            pt = zlib.decompress(pt)
        except Exception:
            pass
    return pt


def find_apk(explicit):
    if explicit:
        return explicit
    cands = sorted(glob.glob(os.path.join(ROOT, 'client', '*.apk')))
    if not cands:
        cands = sorted(glob.glob(os.path.join(ROOT, 'work', '*.apk')))
    return cands[0] if cands else None


def extract(apk, force=False):
    have = glob.glob(os.path.join(LUASRC, 'canon', 'configs', '*.lua'))
    if have and not force:
        print('work/luasrc 已存在 %d 个配置文件，跳过解包（--force 可强制）'
              % len(have))
        return True
    print('从 APK 解包: %s' % apk)
    z = zipfile.ZipFile(apk)
    n = 0
    for name in z.namelist():
        if not name.endswith('.lua') or not name.startswith(WANTED):
            continue
        try:
            pt = decrypt(z.read(name))
        except Exception as e:
            print('  ! %s: %r' % (name, e))
            continue
        dst = os.path.join(LUASRC, *name[len('assets/src/'):].split('/'))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(pt)
        n += 1
    z.close()
    print('解出 %d 个 Lua -> %s' % (n, LUASRC))
    return n > 0


def build_card_dict():
    path = os.path.join(SERVER, 'card_dict.json')
    if os.path.exists(path):
        print('server/card_dict.json 已存在，跳过')
        return True
    print('生成 card_dict.json …')
    r = subprocess.run([sys.executable, 'build_card_dict.py'], cwd=SERVER)
    return r.returncode == 0


def init_db():
    db = os.path.join(SERVER, 'canon.db')
    if os.path.exists(db):
        print('server/canon.db 已存在，跳过初始化')
        return True
    print('初始化数据库 …')
    r = subprocess.run([sys.executable, 'init_db.py'], cwd=SERVER)
    return r.returncode == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apk')
    ap.add_argument('--force', action='store_true')
    a = ap.parse_args()

    apk = find_apk(a.apk)
    if not apk or not os.path.exists(apk):
        print('!! 找不到 APK。把你的 APK 放到 client/ 下，或用 --apk 指定路径。')
        print('   （仓库不包含 APK，需自行从自己持有的安装包获取）')
        return 1
    if not extract(apk, a.force):
        print('!! 解包失败')
        return 1
    if not build_card_dict():
        print('!! card_dict 生成失败')
        return 1
    if not init_db():
        print('!! 数据库初始化失败')
        return 1
    print('\n引导完成。启动服务端：')
    print('  set CANON_MANIFEST_MD5=<你的 APK 里 assets/static_config.<md5>.xml 的 md5>')
    print('  cd server && python -u gameserver.py')
    return 0


if __name__ == '__main__':
    sys.exit(main())
