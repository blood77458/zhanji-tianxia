#!/usr/bin/env python3
"""
Canon API capture server.

Listens on :80 and :443(half) and records every request the game client makes,
so we can reconstruct the real server API. Responses are driven by a small
JSON rules file (rules.json) that can be edited without restarting:
    {
      "/staticVersion": {"status":200, "ctype":"application/xml", "body_file":"..."},
      "default":        {"status":404, "ctype":"text/plain", "body":""}
    }

Logs to capture.jsonl (one JSON object per request) and to stdout.
"""
import json, os, sys, threading, time, traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(ROOT, "capture.jsonl")
RULES = os.path.join(ROOT, "rules.json")
_lock = threading.Lock()


def load_rules():
    try:
        with open(RULES, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "nginx"
    sys_version = ""

    def log_message(self, *a):
        pass  # we do our own logging

    def _record(self, body: bytes):
        try:
            rules = load_rules()
        except Exception:
            rules = {}
        path = self.path
        key = path.split("?")[0]
        rule = rules.get(key) or rules.get(path) or rules.get("default") or {}
        status = int(rule.get("status", 404))
        ctype = rule.get("ctype", "text/plain; charset=utf-8")
        if "body_file" in rule:
            try:
                with open(os.path.join(ROOT, rule["body_file"]), "rb") as f:
                    payload = f.read()
            except Exception as e:
                payload = f"rule body_file error: {e}".encode()
        else:
            payload = str(rule.get("body", "")).encode("utf-8")

        rec = {
            "t": time.strftime("%Y-%m-%d %H:%M:%S"),
            "ts": time.time(),
            "method": self.command,
            "path": path,
            "host": self.headers.get("Host", ""),
            "headers": {k: v for k, v in self.headers.items()},
            "body_len": len(body),
            "body": body.decode("utf-8", "replace")[:20000],
            "-> status": status,
        }
        line = json.dumps(rec, ensure_ascii=False)
        with _lock:
            with open(LOG, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        print(f"[{rec['t']}] {self.command} {rec['host']}{path}  body={len(body)}B -> {status}", flush=True)
        if body:
            try:
                print("    BODY: " + body.decode("utf-8", "replace")[:2000], flush=True)
            except Exception:
                print("    BODY(hex): " + body[:200].hex(), flush=True)

        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Connection", "close")
        self.end_headers()
        if payload:
            self.wfile.write(payload)

    def do_GET(self):
        self._record(b"")

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(n) if n else b""
        self._record(body)

    def do_HEAD(self):
        self._record(b"")

    def do_PUT(self):
        n = int(self.headers.get("Content-Length") or 0)
        self._record(self.rfile.read(n) if n else b"")


def serve(port):
    srv = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    srv.daemon_threads = True
    print(f"listening on :{port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    if not os.path.exists(RULES):
        with open(RULES, "w", encoding="utf-8") as f:
            json.dump({"default": {"status": 404, "ctype": "text/plain", "body": "not found"}}, f, indent=2)
    print(f"CANON CAPTURE SERVER  root={ROOT}")
    ts = [threading.Thread(target=serve, args=(p,), daemon=True) for p in (80,)]
    for t in ts:
        t.start()
    try:
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        print("bye")
