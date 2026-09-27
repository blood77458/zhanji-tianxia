#!/usr/bin/env python3
"""
Probe the hedebug HTTP-over-reverse-socket protocol.

Discovery: the client, which connects OUT to :8172, parses whatever we send as
an HTTP request and answers with an HTTP response ('400 Bad Request').

So: we are the client, the game is the server. Enumerate endpoints.
"""
import socket, sys, time

PORT = 8172

REQS = []
paths = [
    "/", "/list", "/files", "/file", "/scripts", "/script", "/source", "/src",
    "/exec", "/run", "/eval", "/lua", "/lua/exec", "/cmd", "/command",
    "/debug", "/hedebug", "/he_snapshot", "/snapshot", "/status", "/info",
    "/breakpoint", "/breakpoints", "/bp", "/stack", "/locals", "/globals",
    "/load", "/reload", "/require", "/index", "/api", "/api/list",
]
for p in paths:
    REQS.append((f"GET {p} HTTP/1.1", f"GET {p} HTTP/1.1\r\nHost: 10.0.2.2\r\n\r\n".encode()))

# a couple of POSTs too
for p in ("/exec", "/eval", "/lua", "/cmd"):
    body = b"return 1+1"
    REQS.append((f"POST {p} (return 1+1)",
                 f"POST {p} HTTP/1.1\r\nHost: 10.0.2.2\r\nContent-Length: {len(body)}\r\n\r\n".encode() + body))


def rd(conn, t):
    conn.settimeout(t)
    out = b""
    try:
        while True:
            d = conn.recv(65536)
            if not d:
                break
            out += d
            if len(out) > 300000:
                break
    except socket.timeout:
        pass
    except Exception:
        pass
    return out


def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", PORT))
    srv.listen(1)
    print(f"listening :{PORT} ...", flush=True)
    srv.settimeout(300)
    conn, addr = srv.accept()
    print(f"CONNECTED {addr}", flush=True)
    print(f"banner: {rd(conn, 2.0)!r}", flush=True)

    for label, payload in REQS:
        try:
            conn.sendall(payload)
        except Exception as e:
            print(f"send failed: {e}", flush=True)
            break
        r = rd(conn, 1.5)
        txt = r.decode("utf-8", "replace")
        first = txt.split("\r\n")[0] if txt else "(no response)"
        print(f"  {label:<32} -> {first}", flush=True)
        if r and "400" not in first:
            print("     FULL:", repr(r[:800]), flush=True)

    try:
        conn.close()
    except Exception:
        pass
    srv.close()
    print("done", flush=True)


if __name__ == "__main__":
    main()
