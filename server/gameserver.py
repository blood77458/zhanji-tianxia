#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""新的 DB 后端服务端入口。

    python gameserver.py                 # HTTP :80 + TCP :9700
    python gameserver.py --port 8080     # 换端口（模拟器 hosts 也要跟着改）
    python gameserver.py --db x.db

与旧的 canon_server.py 的区别：
  * 数据落 SQLite（88 张表），不再是单个 user_state.json
  * 端点用注册表分发（api/handlers*.py），不再是两条 if/elif 长链
  * REST 与 RPC 的响应格式严格按 API.md §2 区分（裸 AMF3 / 纯文本 / JSON）

旧的 canon_server.py 仍然可以跑，用来对照。
"""
import argparse
import json
import os
import re
import socket
import socketserver
import struct
import sys
import threading
import time
import zlib
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs, unquote

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import protocol as P                                        # noqa: E402
from db import Database                                     # noqa: E402
from services import Services                               # noqa: E402
import api as API                                           # noqa: E402

ROOT = os.path.dirname(os.path.abspath(__file__))
LOG_PATH = os.path.join(ROOT, "gameserver.log")
MANIFEST_DIR = os.path.join(ROOT, 'static')

CTX = None          # Services
CFG = {}


def log(*a):
    line = time.strftime('[%H:%M:%S] ') + ' '.join(str(x) for x in a)
    try:
        print(line, flush=True)
    except UnicodeEncodeError:
        print(line.encode(sys.stdout.encoding or 'utf-8', errors='replace').decode(sys.stdout.encoding or 'utf-8'), flush=True)
    try:
        with open(LOG_PATH, 'a', encoding='utf-8') as f:
            f.write(line + '\n')
    except Exception:
        pass


def _png_bytes(w, h, rgb=(90, 140, 200)):
    """最小 stdlib PNG 编码器，给广告位占位。"""
    import struct
    raw = b"".join(b"\x00" + bytes(rgb) * w for _ in range(h))

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "nginx"
    sys_version = ""

    def log_message(self, *a):
        pass

    # ---------------------------------------------------------------- 基础
    # 单机版要用「抓包回放」替这些直连 HTTP 端点，所以把它们第一次的响应字节落盘。
    # 这些端点返回 AMF3+zlib+XOR 信封，在 Lua 里重写编码器不划算；
    # 它们的应答与请求基本无关、是常量，直接原样回放最省事。
    _CAPTURE_PREFIXES = ('/systemInfo', '/sessionKey/init', '/check/',
                         '/mappingAccount', '/loginAccount/')

    def _capture(self, body):
        try:
            from urllib.parse import urlparse as _up
            p = _up(self.path).path
            if not any(p == w or p.startswith(w) for w in self._CAPTURE_PREFIXES):
                return
            d = os.path.join(os.path.dirname(os.path.dirname(
                os.path.abspath(__file__))), 'work', 'http_capture')
            os.makedirs(d, exist_ok=True)
            key = p.strip('/').replace('/', '_') or 'root'
            fn = os.path.join(d, key + '.bin')
            if not os.path.exists(fn):
                open(fn, 'wb').write(body)
                print('[CAPTURE] %s -> %s (%d 字节)'
                      % (p, key + '.bin', len(body)), flush=True)
        except Exception:
            pass

    def _send(self, code, body, ctype="text/plain; charset=utf-8"):
        if isinstance(body, str):
            body = body.encode('utf-8')
        self._capture(body)
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        try:
            self.wfile.write(body)
        except Exception:
            pass

    def _json(self, obj, code=200):
        self._send(code, json.dumps(obj, ensure_ascii=False).encode('utf-8'),
                   "application/json; charset=utf-8")

    def _body(self):
        n = int(self.headers.get('Content-Length') or 0)
        return self.rfile.read(n) if n else b""

    @staticmethod
    def _form(raw):
        out = {}
        for kv in (raw or b'').decode('utf-8', 'replace').split('&'):
            if '=' in kv:
                k, v = kv.split('=', 1)
                out[unquote(k)] = unquote(v)
        return out

    # ---------------------------------------------------------------- GET
    def do_GET(self):
        u = urlparse(self.path)
        path, q = u.path, parse_qs(u.query)
        # 静态资源/版本检查打点：单机版要照着这些 URL 回包
        print('[GET ] %s' % self.path[:160], flush=True)
        try:
            if path == '/staticVersion':
                return self.static_version()
            if path.startswith('/static/ad/'):
                return self._send(200, _png_bytes(64, 64), "image/png")
            if path.startswith('/static/'):
                return self.static_file(path[len('/static/'):])
            if path == '/getLoginServer':
                return self.get_login_server(q)
            if path.startswith('/check/'):
                return self.check_platform(q, get=True)
            if path == '/restapi.php':
                return self._json({})
            if path == '/health':
                return self._json({'ok': True, 'endpoints': len(API.REGISTRY),
                                   'time': int(time.time())})
            return self._send(404, 'not found')
        except Exception as e:
            import traceback
            traceback.print_exc()
            return self._send(500, 'error: %s' % e)

    # ---------------------------------------------------------------- POST
    def do_POST(self):
        u = urlparse(self.path)
        path = u.path
        raw = self._body()
        try:
            if path == '/protocol':
                return self.rpc(raw)
            if path == '/systemInfo':
                return self.system_info()
            if path == '/sessionKey/init':
                return self.session_key(raw)
            if path.startswith('/check/'):
                return self.check_platform(self._form(raw))
            if path == '/mappingAccount':
                return self.mapping_account(self._form(raw))
            if path == '/loginAccount/hasVisitorAccount':
                return self.has_visitor_account(self._form(raw))
            if path.startswith('/loginAccount/'):
                return self.login_account(path, self._form(raw))
            if path == '/restapi.php':
                return self._json({})
            return self._send(404, 'not found')
        except Exception as e:
            import traceback
            traceback.print_exc()
            return self._send(500, 'error: %s' % e)

    # ================================================================ REST
    def static_version(self):
        """资源清单版本。config_md5 必须等于 APK 内 static_config.<md5>.xml 的 md5。"""
        self._json({
            'static_url_root': 'http://%s/static/' % self.headers.get('Host', 'localhost'),
            'config_md5': CFG.get('manifest_md5', ''),
            'need_download': False,
            'can_download': False,
            'download_url': '',
            'langs': ['zh_CN'],
            'resolutions': ['1280x720'],
            'ref': 0,
        })

    def static_file(self, name):
        """资源文件下载（引擎在「检查资源更新 / 修复」阶段会来要）。

        1) 优先从 `server/static/` 取（清单，或临时覆盖文件）；
        2) 取不到就回落到 **APK 的 assets/**：引擎要的 `src/canon/xxx.<md5>.lua`
           在 APK 里本来就有（`assets/src/...`）。以前这里直接 404，客户端修复
           失败就会一直弹「网络不好，请换一个信号更好的地方试试吧」，
           卡在「正在检查资源更新」进不去。
        """
        base = os.path.basename(name)
        p = os.path.join(MANIFEST_DIR, base)
        if os.path.exists(p):
            return self._send(200, open(p, 'rb').read(), "application/xml")

        entry = 'assets/' + name.replace('\\', '/').lstrip('/')
        if '..' in entry.split('/'):
            return self._send(404, 'not found')
        for apk in _apk_candidates():
            try:
                with zipfile.ZipFile(apk) as z:
                    if entry in z.namelist():
                        return self._send(200, z.read(entry),
                                          "application/octet-stream")
            except Exception:
                continue
        return self._send(404, 'not found')

    def system_info(self):
        """⚠️ 响应是**裸 AMF3**：不 zlib、不 headercvt。

        客户端必需字段（缺一个就会 Lua 报错 -> 引擎 SIGKILL）：
          LoginScene.lua:628  systemInfo.systemConf.serverMergeConfig
          LoginScene.lua:776  systemInfo.systemConf.maintenanceFeatures (list, pairs 遍历)
          LoginScene.lua:718  systemInfo.cleanVersion
        另外 LoginScene 用 serverPartitionConfig.runningServers / serverStatuses 渲染选服列表。
        """
        info = {
            'ts': int(time.time()),
            'cleanVersion': False,
            'systemConf': {
                'serverMergeConfig': {'enable': False, 'gameDomain': '', 'serverOffset': 0},
                'maintenanceFeatures': [],
            },
            'serverPartitionConfig': CTX.meta_payload()['serverPartitionConfig'],
            'serverStatuses': [{'serverId': 1, 'amount': 1}],
        }
        body = P.amf3_encode(info)
        self._send(200, body, "application/octet-stream")

    def session_key(self, raw):
        """⚠️ 响应是**纯文本** `uid,uuid,sessionKey`，客户端 :split(",")。"""
        f = self._form(raw)
        uid = f.get('uid') or '-1'
        try:
            acc = int(uid)
        except ValueError:
            acc = -1
        if acc <= 0:
            # 新设备：建账号
            dev = f.get('udid') or f.get('android_id') or f.get('uniqid') or 'unknown'
            acc = CTX.account.find_or_create_by_device(dev)
        u, uuid_v, sk = CTX.account.init_session(
            acc, uuid=f.get('uuid'), udid=f.get('udid'),
            ip=self.client_address[0] if self.client_address else None)
        log('  sessionKey -> uid=%s sk=%s' % (u, sk))
        self._send(200, '%s,%s,%s' % (u, uuid_v, sk))

    def get_login_server(self, q):
        """⚠️ 响应是**纯文本**逗号分隔的 serverId 列表。"""
        try:
            acc = int((q.get('accountId') or ['0'])[0])
        except ValueError:
            acc = 0
        if acc <= 0:
            return self._send(200, '0')
        self._send(200, CTX.account.logined_servers(acc) or '0')

    def check_platform(self, f, get=False):
        """`/check/<platform>?` → JSON {code:1, loginAccountId}"""
        platform_id = urlparse(self.path).path.rsplit('/', 1)[-1] or 'android'
        dev = f.get('udid') or f.get('deviceId') or f.get('platformUid') or 'unknown'
        acc = CTX.account.find_or_create_by_platform(platform_id, dev, device_id=dev)
        if f.get('seconds'):
            CTX.repos.player.set_binding_sid(platform_id, dev, f.get('seconds'))
        self._json({'code': 1, 'loginAccountId': acc, 'accountId': acc,
                    'uid': acc, 'token': 'local', 'new': False})

    def mapping_account(self, f):
        """JSON {code:1, accountId, token}。accountId 必须能 tonumber 且 > 0。"""
        platform_id = f.get('platformId') or 'android'
        puid = f.get('platformUid') or f.get('deviceId') or 'unknown'
        acc = CTX.account.find_or_create_by_platform(platform_id, puid, device_id=puid)
        self._json({'code': 1, 'accountId': acc, 'token': 'local-token'})

    def has_visitor_account(self, f):
        dev = f.get('deviceId') or f.get('udid') or ''
        acc = CTX.repos.player.account_by_device(dev) if dev else None
        self._json({'code': 1, 'hasVisitorAccount': 1 if acc else 0, 'deviceId': dev})

    def login_account(self, path, f):
        name = f.get('account') or ''
        pwd = f.get('password') or ''
        if path.endswith('/register'):
            code, acc, _ = CTX.account.register(name, pwd, f.get('email'))
            if code != 1:
                return self._json({'code': code})
            return self._json({'code': 1, 'accountId': acc, 'token': 'local-token'})
        acc = CTX.account.check_password(name, pwd) if name else None
        if acc is None:
            return self._json({'code': -5 if name else 1, 'accountId': 0})
        self._json({'code': 1, 'accountId': int(acc['account_id']), 'token': 'local-token'})

    # ================================================================ RPC
    def _proto_capture(self, method, resp):
        """单机版要把 /protocol 的响应做成静态快照，所以按方法名落盘一份。"""
        try:
            d = os.path.join(os.path.dirname(os.path.dirname(
                os.path.abspath(__file__))), 'work', 'proto_capture')
            os.makedirs(d, exist_ok=True)
            fn = os.path.join(d, method + '.json')
            if os.path.exists(fn):
                return
            with open(fn, 'w', encoding='utf-8') as f:
                json.dump(resp, f, ensure_ascii=False)
            print('[PROTO] %s -> %s (%d bytes)'
                  % (method, method + '.json', os.path.getsize(fn)), flush=True)
        except Exception as e:
            print('[PROTO] capture failed %s: %r' % (method, e), flush=True)

    def rpc(self, raw):
        q = parse_qs(urlparse(self.path).query)
        session_key = (q.get('uid') or [None])[0]
        if not raw:
            return self._send(200, P.encode_rpc_response([], err_code=0),
                              "application/octet-stream")
        try:
            header, reqs = P.decode_rpc_request(raw)
        except Exception as e:
            log('  ! rpc decode failed: %s' % e)
            return self._send(200, P.encode_rpc_response([], err_code=0),
                              "application/octet-stream")

        # 会话：URL 上的 uid 是 accountId，真正的会话靠 header.sk
        sk = header.get('sk') or session_key
        s = CTX.repos.player.session(sk) if sk else None
        if s and not int(s['revoked']) and not s['player_id']:
            # 第一次 RPC：把账号下的角色绑到会话（多服时取该账号第一个角色）
            players = CTX.repos.player.players_of_account(int(s['account_id']))
            if players:
                CTX.repos.player.touch_session(sk, int(players[0]['player_id']))

        responses = []
        for it in reqs:
            if not isinstance(it, dict):
                continue
            method = it.get('method')
            if not method:
                continue
            params = {k: v for k, v in it.items() if k != 'method'}
            resp = API.dispatch(CTX, sk, method, params, header)
            resp['method'] = method
            self._proto_capture(method, resp)
            responses.append(resp)
            if method not in ('getServerTimeStamp',):
                log('    %-28s -> retCode=%s' % (method, resp.get('retCode')))

        body = P.encode_rpc_response(responses, err_code=0, ts=int(time.time()))
        self._send(200, body, "application/octet-stream")


# ================================================================ TCP 实时通道
REALTIME_PORT = int(os.environ.get('CANON_REALTIME_PORT', '9700'))
FRAME_HDR_TAIL = 10


def tcp_encode(obj):
    """帧 = uint32BE 长度(剩余头10 + 载荷) ‖ 10 字节 0x00 ‖ AMF3(object)"""
    w = P.AMF3Writer()
    w.w_object(obj)
    payload = w.bytes()
    return struct.pack('>I', len(payload) + FRAME_HDR_TAIL) + b'\x00' * FRAME_HDR_TAIL + payload


class RealtimeHandler(socketserver.BaseRequestHandler):
    def handle(self):
        peer = self.client_address
        log('  [tcp] connection from %s' % (peer,))
        self.request.settimeout(600)
        buf = bytearray()
        try:
            while True:
                try:
                    data = self.request.recv(4096)
                except socket.timeout:
                    break
                if not data:
                    break
                buf += data
                while True:
                    if len(buf) < 14:
                        break
                    (length,) = P.struct.unpack('>I', bytes(buf[:4]))
                    if length + 4 > len(buf):
                        break
                    payload = bytes(buf[14:4 + length])
                    del buf[:4 + length]
                    try:
                        msg = P.amf3_decode(payload)
                    except Exception as e:
                        log('  [tcp] decode failed: %s' % e)
                        continue
                    if not isinstance(msg, dict):
                        continue
                    m = msg.get('method')
                    log('  [tcp] recv method=%s' % m)
                    # ⚠️ login 的 retCode 必须 0，否则客户端每 11 秒重连
                    self.request.sendall(tcp_encode({'method': m, 'retCode': 0}))
        except Exception as e:
            log('  [tcp] error: %r' % e)
        finally:
            log('  [tcp] closed %s' % (peer,))


class RealtimeServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def start_realtime():
    try:
        srv = RealtimeServer(('0.0.0.0', REALTIME_PORT), RealtimeHandler)
    except OSError as e:
        log('  ! realtime bind :%d failed: %s (继续跑 HTTP)' % (REALTIME_PORT, e))
        return None
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    log('  TCP 实时通道监听 :%d' % REALTIME_PORT)
    return srv


# ================================================================ 启动
def _apk_candidates():
    """候选 APK：client/ 与 work/ 下的所有 apk，按 mtime 从新到旧。"""
    base = os.path.dirname(ROOT)
    cands = []
    for d in (os.path.join(base, 'client'), os.path.join(base, 'work')):
        if os.path.isdir(d):
            for fn in os.listdir(d):
                if fn.lower().endswith('.apk'):
                    cands.append(os.path.join(d, fn))
    cands.sort(key=lambda p: os.path.getmtime(p), reverse=True)
    return cands


def find_manifest_md5():
    """定位客户端资源清单，并把 XML 释放到 server/static/ 供 /static/ 下载。

    优先级：
      1) 环境变量 CANON_MANIFEST_MD5（start_gameserver.bat 会设）
      2) 已解包目录 work/apk_extract/assets/
      3) 直接扫描 client/*.apk、work/*.apk（取 mtime 最新且 md5 匹配的）

    ⚠️ 之前这里只扫 work/apk_extract/assets/（该目录并不存在），而且完全没读
    CANON_MANIFEST_MD5，导致 /staticVersion 下发空 config_md5，客户端走
    dynamicUpdate 报错。
    """
    env = (os.environ.get('CANON_MANIFEST_MD5') or '').strip().lower()

    def _publish(name, blob):
        os.makedirs(MANIFEST_DIR, exist_ok=True)
        dst = os.path.join(MANIFEST_DIR, name)
        try:
            if not os.path.exists(dst) or open(dst, 'rb').read() != blob:
                with open(dst, 'wb') as f:
                    f.write(blob)
        except Exception as e:
            log('  ⚠ 写出 manifest 失败: %r' % (e,))
        return name[len('static_config.'):-len('.xml')]

    # 1) 已解包目录
    d = os.path.join(os.path.dirname(ROOT), 'work', 'apk_extract', 'assets')
    if os.path.isdir(d):
        for fn in sorted(os.listdir(d)):
            if fn.startswith('static_config.') and fn.endswith('.xml'):
                md5 = fn[len('static_config.'):-len('.xml')].lower()
                if env and md5 != env:
                    continue
                log('  manifest 来自 work/apk_extract/assets/')
                return _publish(fn, open(os.path.join(d, fn), 'rb').read())

    # 2) 扫 APK
    for p in _apk_candidates():
        try:
            with zipfile.ZipFile(p) as z:
                for n in z.namelist():
                    m = re.fullmatch(r'assets/(static_config\.[0-9a-f]{32}\.xml)', n)
                    if not m:
                        continue
                    name = m.group(1)
                    md5 = name[len('static_config.'):-len('.xml')].lower()
                    if env and md5 != env:
                        continue
                    log('  manifest 来自 %s' % os.path.basename(p))
                    return _publish(name, z.read(n))
        except Exception:
            continue

    # 3) 只给了环境变量、但找不到内容（仍下发 md5，至少不会 dynamicUpdate）
    if env:
        log('  ⚠ 未找到 manifest 内容，仅按环境变量下发 md5=%s' % env)
        return env
    return ''


def main():
    global CTX, CFG
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', type=int, default=int(os.environ.get('CANON_HTTP_PORT', 80)))
    ap.add_argument('--db', default=os.path.join(ROOT, 'canon.db'))
    ap.add_argument('--host', default='0.0.0.0')
    args = ap.parse_args()

    db = Database(args.db)
    if not db.is_initialized():
        db.init_schema()
    migrated = db.migrate()
    if migrated:
        log('  已迁移列: %s' % ', '.join(migrated))
    CTX = Services(db)
    CFG['manifest_md5'] = find_manifest_md5()

    os.makedirs(MANIFEST_DIR, exist_ok=True)
    API.load_handlers()

    log('=' * 70)
    log('canon gameserver (sqlite=%s)' % os.path.abspath(args.db))
    log('  已注册 endpoint: %d 个' % len(API.REGISTRY))
    log('  manifest md5   : %s' % (CFG['manifest_md5'] or '(未找到)'))
    try:
        srv = ThreadingHTTPServer((args.host, args.port), Handler)
    except OSError as e:
        log('ABORT: 无法绑定 :%d -> %s' % (args.port, e))
        return 1
    srv.daemon_threads = True
    log('  HTTP 监听 :%d' % args.port)
    start_realtime()
    log('=' * 70)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        log('bye')
    return 0


if __name__ == '__main__':
    sys.exit(main())
