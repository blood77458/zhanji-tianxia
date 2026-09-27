#!/usr/bin/env python3
"""
Interactive hedebug protocol prober.

Accepts ONE client connection (the game's debugger) and then, on that same
connection, tries a battery of candidate commands, watching for any response.
Also supports a 'chat' mode where you can type payloads by hand.

Usage:
    python hedebug_probe2.py            # automated battery
    python hedebug_probe2.py --chat     # interactive
"""
import socket, time, sys, threading, os

PORT = 8172

CANDIDATES = [
    b"LUADEBUGGER", b"LUADEBUGGER\n", b"LUADEBUGGER\r\n",
    b"hedebug\n", b"HEDEBUG\n", b"HE\n",
    b"START\n", b"RUN\n", b"PAUSE\n", b"STOP\n", b"BREAK\n",
    b"GETFILE\n", b"LOADB\n", b"SETB\n", b"GETB\n", b"DELB\n", b"DONE\n",
    b"EXEC\n", b"LIST\n", b"FILES\n", b"SRC\n",
    b"\n", b"{}", b"{}\n",
    b'{"cmd":"start"}\n', b'{"cmd":"getfile"}\n', b'{"cmd":"list"}\n',
    b'{"type":"start"}\n', b'{"action":"start"}\n', b'{"event":"start"}\n',
    b'{"m":"start"}\n', b'{"method":"start"}\n', b'{"op":"start"}\n',
    b'{"command":"start"}\n',
    b'["start"]\n', b'["getfile"]\n',
    b"start\n", b"getfile\n", b"list\n",
    b"1\n", b"0\n",
]


def rd(conn, t):
    conn.settimeout(t)
    out = b""
    try:
        while True:
            d = conn.recv(65536)
            if not d:
                break
            out += d
            if len(out) > 200000:
                break
    except socket.timeout:
        pass
    except Exception:
        pass
    return out


def main():
    chat = "--chat" in sys.argv
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", PORT))
    srv.listen(1)
    print(f"listening :{PORT} -- waiting for the game's debugger to connect...", flush=True)
    srv.settimeout(300)
    conn, addr = srv.accept()
    print(f"CONNECTED {addr}", flush=True)

    banner = rd(conn, 2.0)
    print(f"unsolicited banner: {banner!r}", flush=True)

    if chat:
        print("chat mode: type payload (use \\n for newline, \\x.. for hex). 'quit' to exit.", flush=True)
        while True:
            try:
                line = input("send> ")
            except EOFError:
                break
            if line.strip() == "quit":
                break
            payload = line.encode().decode("unicode_escape").encode("latin-1")
            try:
                conn.sendall(payload)
            except Exception as e:
                print("send failed:", e); break
            r = rd(conn, 3.0)
            print(f"recv({len(r)}): {r!r}", flush=True)
            if r:
                try:
                    print("   text:", r.decode("utf-8", "replace")[:1000], flush=True)
                except Exception:
                    pass
    else:
        for c in CANDIDATES:
            try:
                conn.sendall(c)
            except Exception as e:
                print(f"send failed on {c!r}: {e}", flush=True)
                break
            r = rd(conn, 1.0)
            print(f"  send={c!r:<30} recv({len(r)})= {r[:300]!r}", flush=True)
            if r:
                try:
                    print("      text:", r.decode("utf-8", "replace")[:600], flush=True)
                except Exception:
                    pass

    try:
        conn.close()
    except Exception:
        pass
    srv.close()
    print("done", flush=True)


if __name__ == "__main__":
    main()
