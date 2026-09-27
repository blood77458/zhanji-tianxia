import zipfile, re, json

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = set(z.namelist())

cfg = json.loads(z.read(
    "assets/resource/ui_json/mainmenu_scene_new.c3b175c3a6617d5553c1c2da708914fa.json"
).decode("utf-8"))

SCENE_FOLDERS = ["mainmenu_scene_new"]

def exists(virtual_png):
    """physical name is <dir>/<base>.<32hex>.<ext>, so match by regex."""
    d, _, base = virtual_png.rpartition("/")
    pat = re.compile(r"^assets/resource/ui_res/%s/%s\.([0-9a-f]{16,40})\.png$"
                     % (re.escape(d), re.escape(base)))
    return any(pat.match(n) for n in names)

imgs = {}
nine = []
for gname, items in cfg.get("groups", {}).items():
    for it in items:
        img = it.get("image")
        if img:
            imgs.setdefault(img, []).append(gname)
            if it.get("scalingGrid") is True:
                nine.append((gname, img))

print("distinct images referenced by mainmenu_scene_new.json:", len(imgs))
missing, present = [], []
for img in sorted(imgs):
    vp = "mainmenu_scene_new/%s" % img      # note: no extension here
    (present if exists(vp) else missing).append(img)

print("PRESENT in APK :", len(present))
print("MISSING        :", len(missing))
print()
print("=== missing ===")
for m in missing:
    print("   ", m)

print()
print("=== nine-slice ===")
for g, img in nine:
    print("   %-24s %-40s present=%s" % (g, img, exists("mainmenu_scene_new/%s" % img)))
