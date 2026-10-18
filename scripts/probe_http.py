# -*- coding: utf-8 -*-
"""探针 HTTP 服务：只用来确认客户端到底连的是哪个地址。

监听 18099，收到任何请求都打印“方法 + 路径 + 头”，并回一个 200 空体。
配合 `adb reverse tcp:18099 tcp:18099`，把 plist 的 domain 指到这里：
如果这里收到了请求，就证明客户端确实读了 plist 的 gameDomain。
"""
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

sys.stdout.reconfigure(encoding='utf-8')


class H(BaseHTTPRequestHandler):
    def _log(self, method):
        print('[PROBE] %s %s  UA=%s' % (method, self.path,
                                        self.headers.get('User-Agent', '')[:60]),
              flush=True)
        body = b''
        self.send_response(200)
        self.send_header('Content-Type', 'application/octet-stream')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self._log('GET')

    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        if n:
            self.rfile.read(n)
        self._log('POST')

    def log_message(self, *a):
        pass


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 18099
    print('probe listening on %d' % port, flush=True)
    HTTPServer(('0.0.0.0', port), H).serve_forever()
