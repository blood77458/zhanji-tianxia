# -*- coding: utf-8 -*-
"""把单机层打进 APK（S4 的第一版）。

做四件事：
  1. 替换 `assets/StartupConfig.plist`：域名指向 127.0.0.1:18080；
  2. **新增** `assets/src/canon/single/*.lua`：单机服务端（加密成和 APK 内其它 Lua 同样格式）；
  3. **替换** 打补丁的 launcher / Communication / LoginScene / rpc（用原 APK 的物理文件名）；
  4. zipalign + apksigner 签名。

产物：`work/out/canon_single.apk`

用法:
    python scripts/pack_single_apk.py            # 打包 + 签名
    python scripts/pack_single_apk.py --install  # 顺带安装
"""
import os
import subprocess
import sys
import zipfile
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import pad                # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')
OUT_DIR = os.path.join(ROOT, 'work', 'out')
UNSIGNED = os.path.join(OUT_DIR, 'canon_single_unsigned.apk')
ALIGNED = os.path.join(OUT_DIR, 'canon_single_aligned.apk')
SIGNED = os.path.join(OUT_DIR, 'canon_single.apk')
PATCH_OUT = os.path.join(ROOT, 'work', 'patch_out')
SINGLE_LUA = os.path.join(ROOT, 'offline', 'lua', 'canon', 'single')

LOCAL_DOMAIN = 'http://127.0.0.1:18080'
SDK = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk')
BUILD_TOOLS = os.path.join(SDK, 'build-tools', '36.0.0')
APKSIGNER = os.path.join(BUILD_TOOLS, 'apksigner.bat')
ZIPALIGN = os.path.join(BUILD_TOOLS, 'zipalign.exe')
ADB = os.path.join(SDK, 'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
KEYSTORE = os.path.join(ROOT, 'work', 'canon.keystore')

# 打过补丁的明文 -> 要替换的 APK 条目前缀
PATCHED = {
    'launcher.patched.lua': 'assets/src/launcher.',
    'Communication.patched.lua': 'assets/src/canon/request/Communication.',
    'LoginScene.patched.lua': 'assets/src/canon/scene/LoginScene.',
    'rpc.patched.lua': 'assets/src/hecore/rpc.',
}


def encrypt(pt):
    """和 APK 内 Lua 同格式：IV(16) ‖ AES-128-CBC(PKCS#7(zlib(明文)))"""
    z = zlib.compress(pt, 9)
    iv = os.urandom(16)
    return iv + AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(z, 16))


def fixed_plist(raw):
    text = raw.decode('utf-8')
    out = text.replace('http://android1.canon.happyelements.cn', LOCAL_DOMAIN)
    return out.encode('utf-8')


def build_replacements(zin):
    """返回 {apk 条目名: 新字节}"""
    rep = {}
    names = zin.namelist()

    # 1) plist
    rep['assets/StartupConfig.plist'] = fixed_plist(
        zin.read('assets/StartupConfig.plist'))

    # 2) 单机层 Lua（新增条目）
    count = 0
    for f in sorted(os.listdir(SINGLE_LUA)):
        if not f.endswith('.lua'):
            continue
        pt = open(os.path.join(SINGLE_LUA, f), 'rb').read()
        rep['assets/src/canon/single/' + f] = encrypt(pt)
        count += 1
    print('  单机层 Lua: %d 个' % count)

    # 3) 补丁文件（替换原条目）
    for plain, prefix in PATCHED.items():
        path = os.path.join(PATCH_OUT, plain)
        if not os.path.exists(path):
            print('  !! 缺少 %s（先跑 deploy_single.py --all 生成）' % plain)
            continue
        target = [n for n in names if n.startswith(prefix)]
        if not target:
            print('  !! APK 里找不到 %s* 条目' % prefix)
            continue
        pt = open(path, 'rb').read()
        rep[target[0]] = encrypt(pt)
        print('  替换 %-52s <- %s' % (target[0].split('/')[-1], plain))

    return rep


def build():
    os.makedirs(OUT_DIR, exist_ok=True)
    zin = zipfile.ZipFile(SRC_APK)
    rep = build_replacements(zin)
    with zipfile.ZipFile(UNSIGNED, 'w', zipfile.ZIP_DEFLATED, allowZip64=True) as zout:
        for info in zin.infolist():
            data = rep.get(info.filename)
            if data is None:
                data = zin.read(info.filename)
            zi = zipfile.ZipInfo(info.filename, date_time=info.date_time)
            zi.compress_type = info.compress_type
            zi.external_attr = info.external_attr
            zout.writestr(zi, data)
        # 新增条目
        for name, data in rep.items():
            if name in zin.namelist():
                continue
            zi = zipfile.ZipInfo(name, date_time=(2026, 10, 18, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_DEFLATED
            zout.writestr(zi, data)
            print('  新增 %s' % name)
    zin.close()
    print('已生成 -> %s (%.1f MB)' % (UNSIGNED,
                                      os.path.getsize(UNSIGNED) / 1024 / 1024))


def sign_install(do_install):
    if os.path.exists(ALIGNED):
        os.remove(ALIGNED)
    r = subprocess.run([ZIPALIGN, '-p', '4', UNSIGNED, ALIGNED], capture_output=True)
    print('zipalign rc=%s' % r.returncode)
    if r.returncode != 0:
        return False
    if os.path.exists(SIGNED):
        os.remove(SIGNED)
    subprocess.run(['cmd', '/c', 'copy', ALIGNED, SIGNED], capture_output=True)
    r = subprocess.run([APKSIGNER, 'sign', '--ks', KEYSTORE,
                        '--ks-pass', 'pass:123456', '--ks-key-alias', 'canon',
                        '--v1-signing-enabled', 'true', '--v2-signing-enabled', 'true',
                        SIGNED], capture_output=True)
    print('apksigner rc=%s %s' % (r.returncode,
                                  (r.stderr or b'').decode('utf-8', 'replace')[:200]))
    if r.returncode != 0:
        return False
    v = subprocess.run([APKSIGNER, 'verify', '--verbose', SIGNED], capture_output=True)
    print('verify rc=%s' % v.returncode)
    if do_install:
        subprocess.run([ADB, '-s', DEV, 'uninstall',
                        'com.happyelements.canon.baiduDK'], capture_output=True)
        r = subprocess.run([ADB, '-s', DEV, 'install', SIGNED], capture_output=True)
        out = ((r.stdout or b'') + (r.stderr or b'')).decode('utf-8', 'replace')
        print('install rc=%s: %s' % (r.returncode, out.strip()[:200]))
    print('签名完成 -> %s (%.1f MB)' % (SIGNED, os.path.getsize(SIGNED) / 1024 / 1024))
    return True


def main():
    print('打包单机版 APK:')
    build()
    ok = sign_install('--install' in sys.argv)
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
