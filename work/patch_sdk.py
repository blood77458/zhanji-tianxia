#!/usr/bin/env python3
"""
Bypass the dead Baidu/Duoku channel SDK.

The client picks its login backend purely from the package-name suffix
(canon/data/ThirdPlatformLogin.lua): "...canon.baiduDK" -> platFormId = baiduDK
-> isDKAndroid() -> loginDK() -> com.baidu.platformsdk.LoginActivity, whose
servers are long gone.

We flip two predicates so LoginScene falls through to:

    elseif isOfficalAccountPlatform() then guestLogin(accountGetBoundMapping)

which talks to our own server via {domain}/loginAccount/* .

Asset format (reverse-engineered):
    file = IV(16) || AES-128-CBC( zlib(lua_source) )   [PKCS#7]
    physical name = <name>.<md5(encrypted file)>.lua
    static_config.xml <file value=.. md5=.. size=../> carries that md5+size

So patching one Lua file means: re-encrypt, rename, and update the manifest.
"""
import os, re, zlib, hashlib, zipfile, shutil, sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
SRC_APK = r"E:\deepseek_projects\app_server\work\zjt_arm_aligned.apk"
OUT_APK = r"E:\deepseek_projects\app_server\work\zjt_bypass.apk"
TARGET_VIRTUAL = "canon/data/ThirdPlatformLogin.lua"
MANIFEST_ENTRY = "assets/static_config.0b608cebad1fc9c8ae2b5272bae229ff.xml"


def decrypt(blob):
    iv, ct = blob[:16], blob[16:]
    from Crypto.Util.Padding import unpad
    return zlib.decompress(unpad(AES.new(KEY, AES.MODE_CBC, iv).decrypt(ct), 16))


def encrypt(src: bytes) -> bytes:
    iv = os.urandom(16)
    ct = AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(zlib.compress(src, 9), 16))
    return iv + ct


BLOCK_OPEN = (b"function", b"if", b"for", b"while", b"do")
BLOCK_END = b"end"


def lua_balance(src: bytes):
    """
    Cheap Lua block-keyword balance check (ignores strings and comments).
    Returns (opens, ends).  Well-formed chunks have opens == ends, because
    `if/for/while/function` each consume exactly one `end` (a `for ... do`
    shares its `end` with the `for`, which is why bare `do` is counted only
    when not already preceded by for/while -- we approximate by counting
    `for`/`while` and NOT their `do`).
    """
    i, n = 0, len(src)
    opens = ends = 0
    while i < n:
        c = src[i]
        # comments
        if src.startswith(b"--[[", i):
            j = src.find(b"]]", i + 4)
            i = (j + 2) if j >= 0 else n
            continue
        if src.startswith(b"--", i):
            j = src.find(b"\n", i)
            i = (j + 1) if j >= 0 else n
            continue
        # strings
        if c in (0x22, 0x27):  # " or '
            q = c
            i += 1
            while i < n and src[i] != q:
                if src[i] == 0x5C:
                    i += 1
                i += 1
            i += 1
            continue
        if src.startswith(b"[[", i):
            j = src.find(b"]]", i + 2)
            i = (j + 2) if j >= 0 else n
            continue
        # identifiers
        if (65 <= c <= 90) or (97 <= c <= 122) or c == 0x5F:
            j = i
            while j < n and ((65 <= src[j] <= 90) or (97 <= src[j] <= 122) or
                             (48 <= src[j] <= 57) or src[j] == 0x5F):
                j += 1
            word = src[i:j]
            if word in BLOCK_OPEN:
                # `do` that belongs to for/while does not add a block
                if word == b"do":
                    k = src.rfind(b"\n", 0, i)
                    head = src[k + 1:i]
                    if b"for" not in head and b"while" not in head:
                        opens += 1
                else:
                    opens += 1
            elif word == BLOCK_END:
                ends += 1
            elif word == b"repeat":
                opens += 1
                # until closes it; count 'until' as an end below
            elif word == b"until":
                ends += 1
            i = j
            continue
        i += 1
    return opens, ends


def patch_lua(src: bytes):
    """
    Replace isDKAndroid -> false and isPlatformAndroid -> true.

    Careful: the bodies contain indented `if/else ... end`, so we must match up
    to an `end` at the START OF A LINE (the function's own terminator), not the
    first `end` token -- that would swallow only the inner block and leave a
    stray `end` behind, producing an invalid chunk.
    """
    before = lua_balance(src)
    out = src
    n = 0
    for fname, ret in ((b"isDKAndroid", b"false"), (b"isPlatformAndroid", b"true")):
        pat = re.compile(rb"function\s+" + fname + rb"\s*\(\s*\)\s*.*?\nend\b", re.S)
        m = pat.search(out)
        if not m:
            raise SystemExit(f"{fname.decode()}() not found / unmatched")
        removed = m.group(0)
        ro, re_ = lua_balance(removed)
        if ro != re_:
            raise SystemExit(f"refusing: matched text for {fname.decode()} "
                             f"is not balanced ({ro} opens vs {re_} ends)")
        repl = b"function " + fname + b"()\n    return " + ret + b"\nend"
        out = out[:m.start()] + repl + out[m.end():]
        n += 1
    after = lua_balance(out)
    print(f"  lua balance: before(opens={before[0]},ends={before[1]}) "
          f"after(opens={after[0]},ends={after[1]})")
    if after[0] != after[1]:
        raise SystemExit(f"patched chunk is NOT balanced: {after}")
    if before[0] != before[1]:
        print("  note: original was already unbalanced by this metric; "
              "relying on the delta instead")
        if (before[0] - before[1]) != (after[0] - after[1]):
            raise SystemExit("balance delta changed -> patch likely broke syntax")
    return out, n


def main():
    zin = zipfile.ZipFile(SRC_APK, "r")
    names = zin.namelist()

    # locate the physical (hashed) asset
    prefix = "assets/src/" + TARGET_VIRTUAL.rsplit(".", 1)[0] + "."
    old_names = [x for x in names if x.startswith(prefix) and x.endswith(".lua")]
    if len(old_names) != 1:
        raise SystemExit(f"expected 1 match, got {old_names}")
    old_name = old_names[0]
    old_blob = zin.read(old_name)
    old_md5 = hashlib.md5(old_blob).hexdigest()
    print(f"old asset : {old_name}")
    print(f"  size={len(old_blob)} md5={old_md5}")

    plain = decrypt(old_blob)
    print(f"  decrypted {len(plain)} bytes")

    patched, n = patch_lua(plain)
    print(f"  patched {n} function(s), new plain size {len(patched)}")
    if patched == plain:
        raise SystemExit("patch had no effect!")

    new_blob = encrypt(patched)
    new_md5 = hashlib.md5(new_blob).hexdigest()
    new_name = old_name.replace(old_md5, new_md5)
    print(f"new asset : {new_name}")
    print(f"  size={len(new_blob)} md5={new_md5}")

    # sanity: round-trip
    assert decrypt(new_blob) == patched, "round-trip failed"
    print("  round-trip OK")

    # ---- rebuild the APK ----
    print("\nrebuilding APK ...")

    # The engine globs "static_config.*.xml", takes the md5 FROM THE FILENAME,
    # then verifies the file content against it (log lines fileMd5/realMd5 and
    # abort on mismatch).  So the manifest must be RENAMED to its new md5.
    # build patched manifest content first
    old_manifest = zin.read(MANIFEST_ENTRY)
    rx = re.compile(
        rb'(value="ThirdPlatformLogin\.lua"\s+md5=")' + old_md5.encode() +
        rb'("\s+size=")\d+(")')
    manifest_txt, cnt = rx.subn(
        rb'\g<1>' + new_md5.encode() + rb'\g<2>' + str(len(new_blob)).encode() + rb'\g<3>',
        old_manifest)
    if cnt != 1:
        raise SystemExit(f"manifest patch failed (matches={cnt})")
    man_md5 = hashlib.md5(manifest_txt).hexdigest()
    man_name = re.sub(rb"static_config\.[0-9a-f]{32}\.xml",
                      ("static_config.%s.xml" % man_md5).encode(),
                      MANIFEST_ENTRY.encode()).decode()
    print(f"  manifest md5 {MANIFEST_ENTRY.split('.')[1]} -> {man_md5}")
    print(f"  manifest renamed to {man_name}")

    zout = zipfile.ZipFile(OUT_APK, "w", zipfile.ZIP_DEFLATED)
    replaced_entry = False
    seen_manifest = False
    for item in zin.infolist():
        if item.filename == old_name:
            zout.writestr(new_name, new_blob)
            replaced_entry = True
            continue
        if item.filename == MANIFEST_ENTRY:
            zout.writestr(man_name, manifest_txt)
            seen_manifest = True
            continue
        zout.writestr(item, zin.read(item.filename))
    zout.close()

    if not replaced_entry:
        raise SystemExit("target entry never written")
    if not seen_manifest:
        raise SystemExit("manifest entry never seen")

    z = zipfile.ZipFile(OUT_APK)
    got = z.read(new_name)
    assert hashlib.md5(got).hexdigest() == new_md5
    gm = z.read(man_name)
    assert hashlib.md5(gm).hexdigest() == man_md5, "manifest md5 mismatch after write"
    assert MANIFEST_ENTRY not in z.namelist(), "old manifest still present"
    print(f"\nDONE -> {OUT_APK}")
    print(f"  {os.path.getsize(OUT_APK)/1024/1024:.1f} MB")
    print(f"  asset    : {new_name}")
    print(f"  manifest : {man_name}")
    print(f"  entries  : {len(z.namelist())}")


if __name__ == "__main__":
    main()
