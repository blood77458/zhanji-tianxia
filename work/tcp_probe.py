#!/usr/bin/env python3
"""
Probe the canon realtime channel.

TCPManager (canon/manager/TCPManager.lua) does:
    getSocketServer (HTTP RPC) -> {serverAddress, serverPort, token}
    SocketTCP:connect()
    on EVENT_CONNECTED -> sendData{serverAddress, serverPort, token,
                                   uid = tonumber(uid), method = METHOD_LOGIN}

The wire framing lives in the NATIVE class `SocketTCPData`
(SocketTCPData:constructSendData / getPieceOfData), so this listens on the
advertised port and hexdumps whatever arrives, which reveals the frame header
(length / compressed flag) directly.
"""
import socket, sys, time, binascii

HOST, PORT = "0.0.0.0", 9700


def hexdump(b, base=0, width=16):
    out = []
    for off in range(0, len(b), width):
        chunk = b[off:off + width]
        hx = " ".join("%02x" % c for c in chunk)
        asc = "".join(chr(c) if 32 <= c < 127 else "." for c in chunk)
        out.append("%08x  %-*s  |%s|" % (base + off, width * 3 - 1, hx, asc))
    return "\n".join(out)


def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((HOST, PORT))
    srv.listen(8)
    print(f"[probe] listening on {HOST}:{PORT}", flush=True)
    n = 0
    while True:
        conn, addr = srv.accept()
        n += 1
        print(f"\n===== connection #{n} from {addr} at {time.strftime('%H:%M:%S')} =====",
              flush=True)
        conn.settimeout(20)
        total = b""
        try:
            while True:
                data = conn.recv(4096)
                if not data:
                    print("[probe] peer closed", flush=True)
                    break
                total += data
                print(f"[probe] recv {len(data)} bytes (total {len(total)}):", flush=True)
                print(hexdump(data), flush=True)
                # do NOT reply yet -- we want to see the client's frame first
        except socket.timeout:
            print("[probe] timeout waiting for more data", flush=True)
        except Exception as e:
            print(f"[probe] error: {e!r}", flush=True)
        finally:
            try:
                conn.close()
            except Exception:
                pass
        print(f"[probe] connection #{n} closed, {len(total)} bytes total", flush=True)
        sys.stdout.flush()


if __name__ == "__main__":
    main()
