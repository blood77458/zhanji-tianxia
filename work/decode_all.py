#!/usr/bin/env python3
"""
Full asset decode pipeline for the Canon client:

    file = IV(16) || AES-128-CBC( zlib( lua_source ) ) with PKCS#7 padding

Key recovered from the live process (.bss + 0x6BB02C):
    e9 74 7d 92 cc 32 2e 7d 11 2e 7c 34 51 d7 b3 6a
"""
import os, zlib, sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
SRC = r"E:\deepseek_projects\app_server\work\extract\assets\src"
DST = r"E:\deepseek_projects\app_server\work\luasrc"


def decode(blob):
    iv, ct = blob[:16], blob[16:]
    pt = unpad(AES.new(KEY, AES.MODE_CBC, iv).decrypt(ct), 16)
    return zlib.decompress(pt)


def main():
    ok = fail = 0
    failures = []
    total = 0
    for root, _, fns in os.walk(SRC):
        for fn in fns:
            if not fn.endswith(".lua"):
                continue
            src = os.path.join(root, fn)
            rel = os.path.relpath(src, SRC)
            out = os.path.join(DST, os.path.splitext(rel)[0] + ".lua")
            os.makedirs(os.path.dirname(out), exist_ok=True)
            try:
                data = decode(open(src, "rb").read())
                with open(out, "wb") as g:
                    g.write(data)
                ok += 1
                total += len(data)
            except Exception as e:
                fail += 1
                failures.append((rel, str(e)))
    print(f"decoded OK : {ok}  ({total/1024/1024:.2f} MB of Lua source)")
    print(f"failed     : {fail}")
    for rel, e in failures[:10]:
        print("   ", rel, "->", e)

    # show a protocol-relevant file
    for name in ("CommParamConstants", "GetServerStatusRequest", "LoginServerRequest",
                 "GetSocketServerRequest", "CommMethodConstants"):
        for root, _, fns in os.walk(DST):
            for fn in fns:
                if fn.startswith(name):
                    p = os.path.join(root, fn)
                    print("\n" + "=" * 74)
                    print("FILE:", os.path.relpath(p, DST))
                    print("=" * 74)
                    txt = open(p, encoding="utf-8", errors="replace").read()
                    print(txt[:1200])
                    break
            else:
                continue
            break


if __name__ == "__main__":
    main()
