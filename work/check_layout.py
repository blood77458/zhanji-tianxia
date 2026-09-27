import zipfile, re, json, collections

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()

# locate the main menu layout json
cands = [n for n in names if "mainmenu_scene" in n and n.endswith(".json")]
print("mainmenu layout json candidates:")
for c in cands:
    print("   ", c, z.getinfo(c).file_size)

if not cands:
    raise SystemExit("no layout json found")

for c in cands:
    raw = z.read(c)
    try:
        txt = raw.decode("utf-8")
    except Exception:
        txt = raw.decode("utf-8", "replace")
    try:
        cfg = json.loads(txt)
    except Exception as e:
        print("  parse fail", c, e)
        continue
    groups = cfg.get("groups", {})
    print("\n=== %s : %d groups ===" % (c, len(groups)))
    nine = []
    allimg = set()
    for gname, items in groups.items():
        for it in items:
            t = it.get("type")
            img = it.get("image")
            if img:
                allimg.add(img)
            if it.get("scalingGrid") is True:
                nine.append((gname, img))
    print("  total distinct images:", len(allimg))
    print("  nine-slice (scalingGrid) entries:", len(nine))
    for gname, img in nine[:40]:
        print("     %-28s %s" % (gname, img))
    break
