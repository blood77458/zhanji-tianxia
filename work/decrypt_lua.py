#!/usr/bin/env python3
"""
Decrypt all encrypted Lua assets with the key recovered from the live process:
    key = e9 74 7d 92 cc 32 2e 7d 11 2e 7c 34 51 d7 b3 6a
Format (deduced, now provable):
    file = IV(16) || AES-128-CBC(PKCS#7(plaintext))
"""
import os, sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
SRC = r"E:\deepseek_projects\app_server\work\extract\assets\src"
DST = r"E:\deepseek_projects\app_server\work\luasrc"


def decrypt(blob):
    iv, ct = blob[:16], blob[16:]
    if len(ct) == 0 or len(ct) % 16:
        raise ValueError(f"bad length {len(blob)}")
    pt = AES.new(KEY, AES.MODE_CBC, iv).decrypt(ct)
    return unpad(pt, 16)


def main():
    # 1) oracle check on the two known-empty files
    print("=== ORACLE CHECK (files whose plaintext should be empty) ===")
    for p in (r"canon\models\LocalUserDataModel.8142fa8be5a96cba9c1482dde82dcb4b.lua",
              r"canon\scene\BattleEffect.f42c5620ce4b7fa7f2ca91906d77e2c5.lua"):
        f = os.path.join(SRC, p)
        blob = open(f, "rb").read()
        try:
            pt = decrypt(blob)
            print(f"  {os.path.basename(f):<60} -> {len(pt)} bytes  {pt[:40]!r}")
        except Exception as e:
            print(f"  {os.path.basename(f):<60} -> FAILED: {e}")

    # 2) decrypt everything
    print("\n=== DECRYPTING ALL ===")
    ok = fail = 0
    failures = []
    for root, _, fns in os.walk(SRC):
        for fn in fns:
            if not fn.endswith(".lua"):
                continue
            src = os.path.join(root, fn)
            rel = os.path.relpath(src, SRC)
            out = os.path.join(DST, os.path.splitext(rel)[0] + ".lua")
            os.makedirs(os.path.dirname(out), exist_ok=True)
            blob = open(src, "rb").read()
            try:
                pt = decrypt(blob)
                with open(out, "wb") as g:
                    g.write(pt)
                ok += 1
            except Exception as e:
                fail += 1
                failures.append((rel, str(e)))
    print(f"  decrypted OK : {ok}")
    print(f"  failed       : {fail}")
    for rel, e in failures[:15]:
        print(f"     {rel}  -> {e}")

    # 3) sanity: show one decrypted request definition
    print("\n=== SAMPLE: canon/request/CommParamConstants ===")
    for root, _, fns in os.walk(DST):
        for fn in fns:
            if "CommParamConstants" in fn:
                print(open(os.path.join(root, fn), encoding="utf-8", errors="replace").read()[:1500])
                return


if __name__ == "__main__":
    main()
