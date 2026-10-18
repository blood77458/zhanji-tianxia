# -*- coding: utf-8 -*-
"""重打包 APK：替换 assets/StartupConfig.plist，再 zipalign + apksigner 签名。

为什么只改这一个文件就够单机化：
    assets/StartupConfig.plist 是纯文本 plist，里面有
        gameDomain        = http://android1.canon.happyelements.cn
        StaticSettingsUrl = http://android1.canon.happyelements.cn/staticVersion
    前者决定 Lua 层所有请求地址（DataManager 的 domainUrl），
    后者就是 native 层「检查资源更新」请求的那个 URL。
    两处都指向 127.0.0.1 后，客户端的所有网络流量都会回到自己身上，
    由 APK 内的单机服务应答 —— 不需要 root、不需要改 hosts。

用法:
    python scripts/repack_apk.py                 # 产出 work/out/canon_single_test.apk
    python scripts/repack_apk.py --install       # 顺便装到模拟器
    python scripts/repack_apk.py --no-sign       # 只改包不签名（调试用）
"""
import os
import shutil
import subprocess
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')
OUT_DIR = os.path.join(ROOT, 'work', 'out')
UNSIGNED = os.path.join(OUT_DIR, 'canon_single_unsigned.apk')
ALIGNED = os.path.join(OUT_DIR, 'canon_single_aligned.apk')
SIGNED = os.path.join(OUT_DIR, 'canon_single.apk')
PLIST = 'assets/StartupConfig.plist'

LOCAL_DOMAIN = 'http://127.0.0.1:18080'

SDK = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk')
BUILD_TOOLS = os.path.join(SDK, 'build-tools', '36.0.0')
APKSIGNER = os.path.join(BUILD_TOOLS, 'apksigner.bat')
ZIPALIGN = os.path.join(BUILD_TOOLS, 'zipalign.exe')
ADB = os.path.join(SDK, 'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
KEYSTORE = os.path.join(ROOT, 'work', 'canon.keystore')
KS_PASS = '123456'
KS_ALIAS = 'canon'


def build_plist(src_text):
    """把域名指到本机；顺手打开 FPS 显示，用来一眼确认 plist 真的被读取。"""
    out = src_text
    out = out.replace('http://android1.canon.happyelements.cn', LOCAL_DOMAIN)
    if '<key>DisplayFps</key>' in out:
        out = out.replace('<key>DisplayFps</key>\n<false/>',
                          '<key>DisplayFps</key>\n<true/>')
        out = out.replace('<key>DisplayFps</key>\r\n<false/>',
                          '<key>DisplayFps</key>\r\n<true/>')
    return out


def repack():
    os.makedirs(OUT_DIR, exist_ok=True)
    zin = zipfile.ZipFile(SRC_APK)
    plist_src = zin.read(PLIST).decode('utf-8')
    plist_new = build_plist(plist_src)
    if plist_new == plist_src:
        print('!! plist 没有被改动，检查域名是否还在原处')
    changed = [(a, b) for a, b in zip(plist_src.split('\n'), plist_new.split('\n'))
               if a != b]
    print('plist 改动:')
    for a, b in changed:
        print('   - %s' % a.strip())
        print('   + %s' % b.strip())

    with zipfile.ZipFile(UNSIGNED, 'w', zipfile.ZIP_DEFLATED, allowZip64=True) as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            if info.filename == PLIST:
                data = plist_new.encode('utf-8')
            # 保留原始压缩方式/时间，避免签名后体积暴涨
            zi = zipfile.ZipInfo(info.filename, date_time=info.date_time)
            zi.compress_type = info.compress_type
            zi.external_attr = info.external_attr
            zout.writestr(zi, data)
    zin.close()
    size = os.path.getsize(UNSIGNED) / 1024 / 1024
    print('已生成 -> %s (%.1f MB)' % (UNSIGNED, size))
    return True


def align():
    if os.path.exists(ALIGNED):
        os.remove(ALIGNED)
    r = subprocess.run([ZIPALIGN, '-p', '4', UNSIGNED, ALIGNED],
                       capture_output=True)
    print('zipalign rc=%s %s' % (r.returncode,
                                 (r.stdout or b'').decode('utf-8', 'replace').strip()))
    return r.returncode == 0


def sign():
    if os.path.exists(SIGNED):
        os.remove(SIGNED)
    shutil.copy2(ALIGNED, SIGNED)
    cmd = [APKSIGNER, 'sign', '--ks', KEYSTORE, '--ks-pass', 'pass:' + KS_PASS,
           '--ks-key-alias', KS_ALIAS, '--v1-signing-enabled', 'true',
           '--v2-signing-enabled', 'true', SIGNED]
    r = subprocess.run(cmd, capture_output=True)
    out = (r.stdout or b'').decode('utf-8', 'replace').strip()
    err = (r.stderr or b'').decode('utf-8', 'replace').strip()
    print('apksigner rc=%s %s %s' % (r.returncode, out, err))
    if r.returncode != 0:
        return False
    v = subprocess.run([APKSIGNER, 'verify', '--verbose', SIGNED],
                       capture_output=True)
    print((v.stdout or b'').decode('utf-8', 'replace').strip()[:400])
    return v.returncode == 0


def install():
    r = subprocess.run([ADB, '-s', DEV, 'install', '-r', SIGNED],
                       capture_output=True)
    out = ((r.stdout or b'') + (r.stderr or b'')).decode('utf-8', 'replace')
    print('adb install rc=%s: %s' % (r.returncode, out.strip()[:400]))
    return r.returncode == 0


def main():
    args = sys.argv[1:]
    if not repack():
        return 1
    if '--no-sign' in args:
        return 0
    if not align():
        return 1
    if not sign():
        return 1
    size = os.path.getsize(SIGNED) / 1024 / 1024
    print('签名完成 -> %s (%.1f MB)' % (SIGNED, size))
    if '--install' in args:
        if not install():
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
