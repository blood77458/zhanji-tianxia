import re, collections, zipfile, json, os

LOG = r"E:\deepseek_projects\app_server\work\logcat_probe.txt"
raw = open(LOG, "rb").read().decode("utf-8", "replace")

req = re.findall(r"!!!IMG_REQ\s+(\S+)\s+(\S+)", raw)
groups = re.findall(r"!!!BUILD_GROUP\s+(\S+)\s+folder=(\S+)", raw)
objs = re.findall(r"!!!IMG_OBJ\s+(\S+)\s+n=(\d+)\s+raw=(.*)", raw)
nullptr = re.findall(r"!!!IMG_NULLPTR(?:_9SLICE)?\s+(\S+)", raw)

print("!!!IMG_REQ      count:", len(req))
print("!!!BUILD_GROUP  count:", len(groups))
print("!!!IMG_OBJ      count:", len(objs))
print("!!!IMG_NULLPTR  count:", len(nullptr))
print()

print("=== distinct BUILD_GROUP folders ===")
print(sorted(set(f for _, f in groups)))
print("=== distinct groups ===")
for g in sorted(set(g for g, _ in groups)):
    print("   ", g)
print()

print("=== n=0 (Lua nil) vs n=1 (userdata) for IMG_OBJ ===")
c = collections.Counter(n for _, n, _ in objs)
print(dict(c))
print()

if nullptr:
    print("=== NULL POINTERS DETECTED ===")
    for p in sorted(set(nullptr)):
        print("   ", p)
else:
    print("=== no NULL pointer detected ===")

# raw values seen for n=1 - look for 0x0
raws = collections.Counter(r.split("]")[-1].strip() for _, n, r in objs if n == "1")
print("\n=== sample 'raw' pointer strings (n=1) ===")
for k, v in list(raws.items())[:8]:
    print("   %-40s x%d" % (k[:40], v))
print("   ... total distinct:", len(raws))

# which requested images are in the known-missing set?
print("\n=== requested images, split by whether the file exists in the APK ===")
z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = set(z.namelist())

def exists(path):   # path like ui_res/mainmenu_scene_new/foo.png
    d, _, b = path.rpartition("/")
    base = b[:-4] if b.endswith(".png") else b
    pat = re.compile(r"^assets/resource/%s/%s\.([0-9a-f]{16,40})\.png$"
                     % (re.escape(d), re.escape(base)))
    return any(pat.match(n) for n in names)

seen = {}
for tag, p in req:
    seen[p] = exists(p)

miss = sorted(p for p, e in seen.items() if not e)
ok = sorted(p for p, e in seen.items() if e)
print("requested & PRESENT :", len(ok))
print("requested & MISSING :", len(miss))
print()
for m in miss:
    print("   MISSING:", m)
