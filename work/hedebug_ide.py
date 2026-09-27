#!/usr/bin/env python3
"""
Listener for the Canon/HeCore Lua debugger (hedebug) on TCP :8172.

The client (libhegame.so, running in the emulator) connects OUT to the IDE.
This side is the IDE. First job: accept a connection and record exactly what
the client sends, so we can learn the handshake/protocol.

Verbose hex+ascii logging; also writes raw stream to debug_session.bin.
"""
import socket, sys, time, threading, os, binascii

PORT = 8172
LOGRAW = os.path.join(os.path.dirname(os.path.abspath(__file__)), "debug_session.bin")


def hexdump(b, width=32):
    out = []
    for i in range(0, len(b), width):
        chunk = b[i:i + width]
        h = " ".join(f"{c:02x}" for c in chunk)
        a = "".join(chr(c) if 32 <= c < 127 else "." for c in chunk)
        out.append(f"    {i:06x}  {h:<{width*3}}  |{a}|")
    return "\n".join(out)


def handle(conn, addr):
    print(f"\n=== CONNECTED from {addr} ===", flush=True)
    conn.settimeout(None)
    total = b""
    t0 = time.time()
    try:
        while True:
            data = conn.recv(65536)
            if not data:
                print(f"\n=== peer closed after {len(total)} bytes ===", flush=True)
                break
            total += data
            print(f"\n[{time.time()-t0:7.3f}s] RECV {len(data)} bytes:", flush=True)
            print(hexdump(data), flush=True)
            try:
                print("    ASCII:", data.decode("utf-8", "replace")[:400], flush=True)
            except Exception:
                pass
            with open(LOGRAW, "ab") as f:
                f.write(data)
    except Exception as e:
        print(f"recv error: {e}", flush=True)
    finally:
        try:
            conn.close()
        except Exception:
            pass
        print(f"=== session ended, {len(total)} bytes total ===", flush=True)


def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", PORT))
    srv.listen(5)
    print(f"hedebug IDE listening on 0.0.0.0:{PORT}", flush=True)
    while True:
        conn, addr = srv.accept()
        threading.Thread(target=handle, args=(conn, addr), daemon=True).start()


if __name__ == "__main__":
    main()
