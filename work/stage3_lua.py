#!/usr/bin/env python3
"""Extract assets/src (Lua game logic) and key config files; then show protocol entry points."""
import zipfile, os, re, json

APK = "zjtianxia_11.0.61_oem5500058.apk"
OUT = "extract"
z = zipfile.ZipFile(APK)
names = set(z.namelist())

# ---- extract all of assets/src + selected config files ----
todo = [n for n in z.namelist() if n.startswith("assets/src/")]
for extra in ("assets/StartupConfig.plist", "assets/bundleVersion", "assets/apk_uuid",
              "assets/data.bin", "assets/make_static.430f6dfd93ae801e3503ec9540f2f055.xml"):
    if extra in names:
        todo.append(extra)
# also the static_config xml (big, 1.3MB) - include it, it's the master data table
todo += [n for n in z.namelist() if n.startswith("assets/static_config")]

print(f"extracting {len(todo)} files ...")
for n in todo:
    dest = os.path.join(OUT, n.replace("/", os.sep))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as f:
        f.write(z.read(n))
print("done\n")

# ---- how are the Lua files stored? source or bytecode? ----
srcdir = os.path.join(OUT, "assets", "src")
sample = []
for root, _, files in os.walk(srcdir):
    for fn in files:
        sample.append(os.path.join(root, fn))

sig = {"lua-source": 0, "lua-bytecode(51)": 0, "lua-bytecode(52)": 0,
       "luajit-bytecode": 0, "other": 0}
for p in sample:
    with open(p, "rb") as f:
        head = f.read(4)
    if head[:1] == b"\x1b":
        if head[1:2] == b"L":
            v = head[3:4]
            if v == b"Q": sig["luajit-bytecode"] += 1
            elif v == b"R": sig["lua-bytecode(52)"] += 1
            else: sig["lua-bytecode(51)"] += 1
        else:
            sig["other"] += 1
    else:
        sig["lua-source"] += 1
print("LUA FILE FORMAT CENSUS:", sig, f"total={len(sample)}\n")

# ---- list the request layer ----
print("=" * 78)
print("REQUEST LAYER  (assets/src/canon/request/)")
print("=" * 78)
reqdir = os.path.join(srcdir, "canon", "request")
reqs = sorted(os.listdir(reqdir)) if os.path.isdir(reqdir) else []
print(f"{len(reqs)} entries")
for r in reqs:
    p = os.path.join(reqdir, r)
    print(f"   {r:<72} {os.path.getsize(p):>7d}")
