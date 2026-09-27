import zipfile, re, json

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()

cfg = json.loads(z.read(
    "assets/resource/ui_json/mainmenu_scene_new.c3b175c3a6617d5553c1c2da708914fa.json"
).decode("utf-8"))

ui_res = "assets/resource/ui_res/mainmenu_scene_new/"
present = set()
for n in names:
    if n.startswith(ui_res):
        base = n[len(ui_res):].split(".")[0]
        present.add(base)

print("files present in %s : %d" % (ui_res, len(present)))

imgs = set()
nine = []
for gname, items in cfg.get("groups", {}).items():
    for it in items:
        img = it.get("image")
        if img:
            imgs.add(img)
            if it.get("scalingGrid") is True:
                nine.append((gname, img))

missing = sorted(i for i in imgs if i not in present)
print("distinct images referenced:", len(imgs))
print("MISSING from APK        :", len(missing))
for m in missing:
    print("   ", m)

print("\nnine-slice entries:")
for gname, img in nine:
    print("   %-28s %-40s present=%s" % (gname, img, img in present))
