#!/usr/bin/env python3
"""
Probe the hedebug protocol on :8172.

The client connects and then waits, so the IDE talks first. Try a battery of
plausible handshakes/commands and record any response. Each candidate gets a
fresh connection + short read timeout.
"""
import socket, time, sys

HOST, PORT = "0.0.0.0", 8172
TARGET_TIMEOUT = 1.2

CANDIDATES = [
    b"LUADEBUGGER",
    b"LUADEBUGGER\n",
    b"LUADEBUGGER\r\n",
    b"hedebug",
    b"hedebug\n",
    b"HEDEBUG\n",
    b"START\n",
    b"START",
    b"RUN\n",
    b"PAUSE\n",
    b"STOP\n",
    b"GETFILE\n",
    b"EXEC\n",
    b"\n",
    b"{}",
    b"{}\n",
    b'{"cmd":"start"}\n',
    b'{"cmd":"getfile"}\n',
    b'{"type":"start"}\n',
    b'{"action":"start"}\n',
    b'{"event":"start"}\n',
    b'{"m":"start"}\n',
    b'{"method":"start"}\n',
    b"start\n",
    b"getfile\n",
    b"connect\n",
    b"1\n",
]


def probe(payload):
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((HOST, PORT))
    srv.listen(1)
    srv.settimeout(12.0)
    try:
        conn, addr = srv.accept()
    except socket.timeout:
        srv.close()
        return None, None, "no client connected"
    conn.settimeout(TARGET_TIMEOUT)
    got = b""
    # first: see if the client says anything unprompted
    try:
        got += conn.recv(4096)
    except socket.timeout:
        pass
    except Exception:
        pass
    if payload is not None:
        try:
            conn.sendall(payload)
        except Exception as e:
            conn.close(); srv.close()
            return got, None, f"send failed: {e}"
        time.sleep(0.15)
        try:
            while True:
                d = conn.recv(65536)
                if not d:
                    break
                got += d
                if len(got) > 65536:
                    break
        except socket.timeout:
            pass
        except Exception:
            pass
    try:
        conn.close()
    except Exception:
        pass
    srv.close()
    return got, addr, "ok"


if __name__ == "__main__":
    banner, addr, st = probe(None)
    print(f"[banner probe] status={st} addr={addr} bytes={len(banner) if banner else 0}"
          f" data={banner!r}" if banner else f"[banner probe] status={st} addr={addr} no data", flush=True)
    for c in CANDIDATES:
        got, addr, st = probe(c)
        desc = repr(got[:400]) if got else "(nothing)"
        print(f"  send={c!r:<32} -> {desc}", flush=True)
        if got:
            print("       !!! RESPONSE FOUND !!!", flush=True)
