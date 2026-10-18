# -*- coding: utf-8 -*-
"""把单机版 Lua（offline/lua/**）加密后推到模拟器的 Caches/src，并给 rpc.lua 打拦截补丁。

为什么走 Caches/src 而不是重打包：引擎**优先**加载
`/data/data/<pkg>/Caches/src/<逻辑路径>`，所以迭代期间不用反复打包大 APK。

用法:
    python scripts/deploy_single.py            # 只部署 single/ 下的文件
    python scripts/deploy_single.py --rpc      # 同时打 rpc.lua 拦截补丁
    python scripts/deploy_single.py --all      # 两者都做（默认就是这个）
"""
import hashlib
import os
import subprocess
import sys
import zipfile
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import pad, unpad         # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')
SRC = os.path.join(ROOT, 'offline', 'lua')
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
PKG = 'com.happyelements.canon.baiduDK'
CACHE = '/data/data/%s/Caches' % PKG

LAUNCHER_HEAD = '''-- [SINGLE] 先起本地 HTTP：native 的资源检查在 launcher 之后不久就会发出，
-- 必须赶在 ResourceLoader.init() 之前把 127.0.0.1:18080 挂上。
pcall(function()
    local http = require("canon.single.httpserver")
    if http and http.start then
        http.start(18080)
    end
end)
'''


def patch_launcher():
    """在 launcher.lua 最前面起本地 HTTP 服务。"""
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith('assets/src/') and n.count('/') == 2 and
             n.split('/')[-1].startswith('launcher.')]
    if not entry:
        print('!! APK 里找不到 launcher.lua')
        return False
    entry = entry[0]
    pt, zipped = decrypt(z.read(entry))
    src = pt.decode('utf-8', 'replace')
    nl = '\r\n' if '\r\n' in src else '\n'
    if 'canon.single.httpserver' in src:
        print('launcher.lua: 已打过补丁，跳过')
    else:
        src = LAUNCHER_HEAD.replace('\n', nl) + src
        print('launcher.lua: 已插入本地 HTTP 启动')
    enc = encrypt(src.encode('utf-8'), zipped)
    name = os.path.basename(entry)
    local = os.path.join(ROOT, 'work', 'patch_out', 'launcher.patched.enc.lua')
    os.makedirs(os.path.dirname(local), exist_ok=True)
    open(local, 'wb').write(enc)
    open(os.path.join(ROOT, 'work', 'patch_out', 'launcher.patched.lua'),
         'wb').write(src.encode('utf-8'))
    return push(local, '%s/src/%s' % (CACHE, name))


COMMUNICATION_OLD = 'function Communication:request(endpoint, params, callback, priority, retry)'
COMMUNICATION_NEW = '''function Communication:request(endpoint, params, callback, priority, retry)
    do
        if not _G.__CANON_SINGLE_PROBE then
            _G.__CANON_SINGLE_PROBE = true
            print("[SINGLE] Communication divert active")
            local pok, perr = pcall(require, "canon.single.main")
            print("[SINGLE] require main -> " .. tostring(pok) .. " " .. tostring(perr))
        end
        local ok, single = pcall(require, "canon.single.main")
        if ok and type(single) == "table" and single.enabled then
            single.call(self, endpoint, params, callback, priority, retry)
            return
        end
    end'''


LOGIN_OLD_DECODE = 'self.systemInfo = amf3.decode(response.body)'
LOGIN_NEW_DECODE = ('self.systemInfo = response.__prebuilt or amf3.decode(response.body)')

LOGIN_OLD_CALL = '    SystemInfoCall.getData(onSystemInfoCall)\n  end \n  scheduler'
LOGIN_NEW_CALL = '''    do
      local ok2, single = pcall(require, 'canon.single.main')
      if not ok2 then single = nil end
      if single and single.enabled and single.system_info then
        -- 单机版：跳过 /systemInfo 的 HTTP 请求（那是二进制 AMF3 响应，
        -- 这个 LuaJ 发不出二进制 body），直接本地合成结构喂给回调。
        onSystemInfoCall({errorCode = 0, httpCode = 200,
                          __prebuilt = single.system_info()})
        return
      end
    end
    SystemInfoCall.getData(onSystemInfoCall)
  end 
  scheduler'''


def patch_login_scene():
    """让 LoginScene 跳过 /systemInfo 的 HTTP 请求，改用本地合成的结构。"""
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith('assets/src/canon/scene/') and
             n.split('/')[-1].startswith('LoginScene.')]
    if not entry:
        print('!! APK 里找不到 LoginScene.lua')
        return False
    entry = entry[0]
    pt, zipped = decrypt(z.read(entry))
    src = pt.decode('utf-8', 'replace')
    nl = '\r\n' if '\r\n' in src else '\n'
    if 'response.__prebuilt' in src:
        print('LoginScene.lua: 已打过补丁，跳过')
    else:
        o1 = LOGIN_OLD_DECODE + nl
        n1 = LOGIN_NEW_DECODE + nl
        if o1 not in src:
            print('!! LoginScene 找不到 amf3.decode 锚点')
            return False
        src = src.replace(o1, n1, 1)
        o2 = LOGIN_OLD_CALL.replace('\n', nl)
        n2 = LOGIN_NEW_CALL.replace('\n', nl)
        if o2 not in src:
            print('!! LoginScene 找不到 getData 调用锚点')
            return False
        src = src.replace(o2, n2, 1)
        print('LoginScene.lua: 已改为本地 systemInfo（跳过 HTTP）')
    enc = encrypt(src.encode('utf-8'), zipped)
    name = os.path.basename(entry)
    local = os.path.join(ROOT, 'work', 'patch_out', 'LoginScene.patched.enc.lua')
    os.makedirs(os.path.dirname(local), exist_ok=True)
    open(local, 'wb').write(enc)
    open(os.path.join(ROOT, 'work', 'patch_out', 'LoginScene.patched.lua'),
         'wb').write(src.encode('utf-8'))
    return push(local, '%s/src/canon/scene/%s' % (CACHE, name))


COMM_DBG_ANCHORS = [
    'function Communication:initSession(p_uid,p_uuid,callbackFunc)',
    'function Communication:initTransponder()',
    'function Communication:login()',
    'function Communication:init()',
    'function Communication:communicationInitSessionCallback(event)',
    'function Communication:communicationLoginCallback(event)',
]


def _dbg_line(fn_header, nl):
    """给 Communication 的关键步骤加打点，定位登录链路断在哪。"""
    name = fn_header.split('Communication:')[1].split('(')[0]
    return fn_header + nl + '    print("[SINGLE-DBG] ' + name + '")' + nl


def patch_communication():
    """把 Communication:request（所有业务请求的汇聚点）改成走本地。"""
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith('assets/src/canon/request/') and
             n.split('/')[-1].startswith('Communication.')]
    if not entry:
        print('!! APK 里找不到 canon/request/Communication.lua')
        return False
    entry = entry[0]
    pt, zipped = decrypt(z.read(entry))
    src = pt.decode('utf-8', 'replace')
    nl = '\r\n' if '\r\n' in src else '\n'
    old = COMMUNICATION_OLD + nl
    if 'canon.single.main' in src:
        print('Communication.lua: 已打过补丁，跳过')
    else:
        if old not in src:
            print('!! Communication.lua 找不到锚点 %r' % COMMUNICATION_OLD[:60])
            return False
        src = src.replace(old, COMMUNICATION_NEW.replace('\n', nl) + nl, 1)
        print('Communication.lua: 已插入本地拦截')
    # 顶层打点：确认这个文件到底有没有从 Caches/src 被加载
    probe = 'print("[SINGLE] Communication loaded from overlay")' + nl
    if probe not in src:
        src = probe + src
    # 关键步骤打点（只加一次）
    if '[SINGLE-DBG]' not in src:
        for h in COMM_DBG_ANCHORS:
            old_h = h + nl
            if old_h in src:
                src = src.replace(old_h, _dbg_line(h, nl), 1)
        print('Communication.lua: 已插入流程打点')
    enc = encrypt(src.encode('utf-8'), zipped)
    name = os.path.basename(entry)
    local = os.path.join(ROOT, 'work', 'patch_out', 'Communication.patched.enc.lua')
    os.makedirs(os.path.dirname(local), exist_ok=True)
    open(local, 'wb').write(enc)
    open(os.path.join(ROOT, 'work', 'patch_out', 'Communication.patched.lua'),
         'wb').write(src.encode('utf-8'))
    return push(local, '%s/src/canon/request/%s' % (CACHE, name))


DIVERT = '''    do
        if not _G.__CANON_SINGLE_PROBE then
            _G.__CANON_SINGLE_PROBE = true
            print("[SINGLE] rpc divert active")
            local pok, perr = pcall(require, "canon.single.main")
            print("[SINGLE] require main -> " .. tostring(pok) .. " " .. tostring(perr))
        end
        local ok, single = pcall(require, "canon.single.main")
        if ok and type(single) == "table" and single.enabled then
            single.call(self, endpoint, data, handler)
            return
        end
    end
'''


def decrypt(blob):
    pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
    zipped = False
    if pt[:1] == b'\x78':
        try:
            pt = zlib.decompress(pt)
            zipped = True
        except Exception:
            pass
    return pt, zipped


def encrypt(pt, zipped=True):
    if zipped:
        pt = zlib.compress(pt, 9)
    iv = os.urandom(16)
    return iv + AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(pt, 16))


def adb(*args, timeout=120):
    r = subprocess.run([ADB, '-s', DEV] + list(args), capture_output=True,
                       timeout=timeout)
    return r.returncode, (r.stdout or b'').decode('utf-8', 'replace').strip()


def push(local, remote):
    adb('shell', 'mkdir -p %s' % os.path.dirname(remote))
    rc, out = adb('push', local, remote)
    print('  push %-52s rc=%s' % (os.path.basename(remote), rc))
    return rc == 0


def deploy_single():
    """offline/lua/canon/single/*.lua -> Caches/src/canon/single/*.lua"""
    base = os.path.join(SRC, 'canon', 'single')
    files = sorted(f for f in os.listdir(base) if f.endswith('.lua'))
    print('部署单机服务端 Lua（%d 个文件）:' % len(files))
    tmp = os.path.join(ROOT, 'work', 'patch_out', 'single')
    os.makedirs(tmp, exist_ok=True)
    ok = True
    for f in files:
        pt = open(os.path.join(base, f), 'rb').read()
        enc = encrypt(pt, True)
        local = os.path.join(tmp, f)
        open(local, 'wb').write(enc)
        remote = '%s/src/canon/single/%s' % (CACHE, f)
        ok = push(local, remote) and ok
    return ok


def patch_rpc():
    """给 hecore/rpc.<md5>.lua 的 call / callOutOfBand 加拦截。"""
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith('assets/src/hecore/') and
             n.split('/')[-1].startswith('rpc.')]
    if not entry:
        print('!! APK 里找不到 hecore/rpc.lua')
        return False
    entry = entry[0]
    pt, zipped = decrypt(z.read(entry))
    src = pt.decode('utf-8', 'replace')
    nl = '\r\n' if '\r\n' in src else '\n'
    if 'canon.single.main' in src:
        print('rpc.lua: 已打过补丁，跳过')
    else:
        anchors = [
            ('function RpcTransponder:call(endpoint, data, handler, priority, isLogin)' + nl,
             'function RpcTransponder:call(endpoint, data, handler, priority, isLogin)' + nl + DIVERT),
            ('function RpcTransponder:callOutOfBand(endpoint, data, handler)' + nl,
             'function RpcTransponder:callOutOfBand(endpoint, data, handler)' + nl + DIVERT),
        ]
        for old, new in anchors:
            if old not in src:
                print('!! rpc.lua 找不到锚点: %r' % old.strip()[:60])
                return False
            src = src.replace(old, new, 1)
        print('rpc.lua: 已插入本地拦截（call / callOutOfBand）')
    enc = encrypt(src.encode('utf-8'), zipped)
    name = os.path.basename(entry)
    local = os.path.join(ROOT, 'work', 'patch_out', 'rpc.patched.enc.lua')
    os.makedirs(os.path.dirname(local), exist_ok=True)
    open(local, 'wb').write(enc)
    open(os.path.join(ROOT, 'work', 'patch_out', 'rpc.patched.lua'),
         'wb').write(src.encode('utf-8'))
    print('  rpc.lua 改写 %d 字节 -> %s' % (len(src), name))
    return push(local, '%s/src/hecore/%s' % (CACHE, name))


def main():
    do_all = '--all' in sys.argv or len(sys.argv) == 1
    ok = True
    if do_all or '--rpc' in sys.argv:
        ok = patch_rpc() and ok
    if do_all or '--comm' in sys.argv:
        ok = patch_communication() and ok
    if do_all or '--launcher' in sys.argv:
        ok = patch_launcher() and ok
    if do_all or '--login' in sys.argv:
        ok = patch_login_scene() and ok
    if do_all or '--lua' in sys.argv:
        ok = deploy_single() and ok
    if not ok:
        print('!! 有步骤失败')
        return 1
    adb('shell', 'rm -f %s/static_config.md5' % CACHE)
    print('已清理 Caches/static_config.md5（下次启动重新扫描）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
