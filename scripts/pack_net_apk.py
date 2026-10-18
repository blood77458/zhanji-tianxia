# -*- coding: utf-8 -*-
"""打一个「模拟器直连本机服务端」的 APK —— 不需要改 hosts。

原理：
    assets/StartupConfig.plist 里两行域名决定客户端所有网络请求的去向：
        gameDomain        -> Lua 层所有接口（/protocol 等）
        StaticSettingsUrl -> native 层的资源检查（/staticVersion）
    把它们改成 `http://10.0.2.2`（MuMu / AVD 里代表宿主机 127.0.0.1 的固定地址），
    客户端就会直接打到本机的 gameserver（80 端口），完全不用动 /etc/hosts。

注意：
  * 这是「联网版」：**不包含**单机层（offline/ 里的 Lua 服务端），
    需要宿主机上跑着 `python server/gameserver.py`。
  * 真机不能用 10.0.2.2 —— 用 --host 换成你电脑的局域网 IP。

用法:
    python scripts/pack_net_apk.py                       # 默认 10.0.2.2:80
    python scripts/pack_net_apk.py --host 192.168.1.7    # 真机/局域网
    python scripts/pack_net_apk.py --install             # 打完顺手装进模拟器
"""
import argparse
import os
import subprocess
import sys
import zipfile

sys.stdout.reconfigure(encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')
OUT_DIR = os.path.join(ROOT, 'work', 'out')
UNSIGNED = os.path.join(OUT_DIR, 'canon_net_unsigned.apk')
ALIGNED = os.path.join(OUT_DIR, 'canon_net_aligned.apk')
SIGNED = os.path.join(OUT_DIR, 'canon_net.apk')
PLIST = 'assets/StartupConfig.plist'
ORIGINAL_DOMAIN = 'http://android1.canon.happyelements.cn'

SDK = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk')
BUILD_TOOLS = os.path.join(SDK, 'build-tools', '36.0.0')
APKSIGNER = os.path.join(BUILD_TOOLS, 'apksigner.bat')
ZIPALIGN = os.path.join(BUILD_TOOLS, 'zipalign.exe')
ADB = os.path.join(SDK, 'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
KEYSTORE = os.path.join(ROOT, 'work', 'canon.keystore')


def patch_plist(raw, base_url):
    text = raw.decode('utf-8')
    out = text.replace(ORIGINAL_DOMAIN, base_url)
    # 分析/日志上报的域名保持原样（失败也不影响进游戏）
    return out.encode('utf-8')


def build(base_url):
    os.makedirs(OUT_DIR, exist_ok=True)
    zin = zipfile.ZipFile(SRC_APK)
    if PLIST not in zin.namelist():
        print('!! APK 里没有 %s' % PLIST)
        return False
    new_plist = patch_plist(zin.read(PLIST), base_url)
    with zipfile.ZipFile(UNSIGNED, 'w', zipfile.ZIP_DEFLATED, allowZip64=True) as zout:
        for info in zin.infolist():
            data = new_plist if info.filename == PLIST else zin.read(info.filename)
            zi = zipfile.ZipInfo(info.filename, date_time=info.date_time)
            zi.compress_type = info.compress_type
            zi.external_attr = info.external_attr
            zout.writestr(zi, data)
    zin.close()
    print('plist 域名 -> %s' % base_url)
    print('已生成 -> %s (%.1f MB)' % (UNSIGNED,
                                      os.path.getsize(UNSIGNED) / 1024 / 1024))
    return True


def sign(do_install):
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
    print('apksigner rc=%s' % r.returncode)
    if r.returncode != 0:
        print((r.stderr or b'').decode('utf-8', 'replace')[:300])
        return False
    v = subprocess.run([APKSIGNER, 'verify', '--verbose', SIGNED], capture_output=True)
    print('verify rc=%s' % v.returncode)
    print('签名完成 -> %s (%.1f MB)' % (SIGNED, os.path.getsize(SIGNED) / 1024 / 1024))
    if do_install:
        subprocess.run([ADB, '-s', DEV, 'uninstall',
                        'com.happyelements.canon.baiduDK'], capture_output=True)
        r = subprocess.run([ADB, '-s', DEV, 'install', SIGNED], capture_output=True)
        out = ((r.stdout or b'') + (r.stderr or b'')).decode('utf-8', 'replace')
        print('install rc=%s: %s' % (r.returncode, out.strip()[:200]))
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--host', default='10.0.2.2',
                    help='宿主机地址；模拟器用 10.0.2.2，真机用局域网 IP')
    ap.add_argument('--port', default='80')
    ap.add_argument('--install', action='store_true')
    a = ap.parse_args()
    base = 'http://%s' % a.host if str(a.port) == '80' else \
           'http://%s:%s' % (a.host, a.port)
    if not build(base):
        return 1
    return 0 if sign(a.install) else 1


if __name__ == '__main__':
    sys.exit(main())
