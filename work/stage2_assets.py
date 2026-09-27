#!/usr/bin/env python3
"""Stage-2: targeted extraction. assets layout, config files, engine .so strings."""
import zipfile, re, os, sys, collections

APK = "zjtianxia_11.0.61_oem5500058.apk"
OUT = "extract"
os.makedirs(OUT, exist_ok=True)
z = zipfile.ZipFile(APK)

infos = z.infolist()
names = [i.filename for i in infos]

print("=" * 70)
print("ASSETS TOP-LEVEL LAYOUT")
print("=" * 70)
agg = collections.Counter()
cnt = collections.Counter()
for i in infos:
    if not i.filename.startswith("assets/"):
        continue
    rest = i.filename[len("assets/"):]
    parts = rest.split("/")
    if len(parts) == 1:
        key = f"(file) {rest}"
    else:
        key = parts[0] + "/"
    agg[key] += i.file_size
    cnt[key] += 1
for k, v in agg.most_common(60):
    print(f"  {k:<45} {v/1024/1024:9.2f} MB   {cnt[k]:5d} files")

print()
print("=" * 70)
print("CONFIG-ISH FILES IN ASSETS (small, text/structured)")
print("=" * 70)
cfg_ext = (".json", ".xml", ".txt", ".cfg", ".ini", ".properties", ".plist",
           ".lua", ".luac", ".csv", ".dat", ".bin", ".bytes", ".plist", ".yaml", ".yml")
cands = []
for i in infos:
    if not i.filename.startswith("assets/"):
        continue
    low = i.filename.lower()
    if low.endswith(cfg_ext) and i.file_size < 3 * 1024 * 1024:
        cands.append(i)
cands.sort(key=lambda x: x.file_size)
print(f"  {len(cands)} candidates (showing <=400KB, name-filtered for config keywords)")
key_names = []
for i in cands:
    b = os.path.basename(i.filename).lower()
    if any(k in b for k in ("config", "cfg", "setting", "server", "version", "url", "host",
                            "channel", "global", "const", "define", "app", "manifest",
                            "platform", "sdk", "login", "net", "proto")):
        key_names.append(i)
for i in key_names[:80]:
    print(f"    {i.filename:<70} {i.file_size:>9d}")
if not key_names:
    print("    (none matched keywords; showing smallest 60 structured files)")
    for i in cands[:60]:
        print(f"    {i.filename:<70} {i.file_size:>9d}")

# ---- extract the engine ----
print()
print("=" * 70)
print("ENGINE EXTRACTION")
print("=" * 70)
for target in ("lib/armeabi-v7a/libhegame.so",
               "lib/armeabi/libhegame.so",
               "lib/x86/libhegame.so",
               "classes.dex",
               "AndroidManifest.xml"):
    if target in names:
        data = z.read(target)
        fn = os.path.join(OUT, os.path.basename(target))
        with open(fn, "wb") as f:
            f.write(data)
        print(f"  extracted {target:<40} -> {fn}  ({len(data)} bytes)")
    else:
        print(f"  NOT PRESENT: {target}")
