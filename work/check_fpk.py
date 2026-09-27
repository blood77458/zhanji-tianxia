import zipfile, re, json

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()
man = [n for n in names if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")
vals = re.findall(r'value="([^"]+)"', txt)

print("=== how many .fpk entries in manifest? ===")
fpk = [v for v in vals if v.endswith(".fpk")]
print(len(fpk), fpk[:10])

print("\n=== any plist/fpk referencing mainmenu_scene frames? ===")
# check every plist we can read for a frame the layout needs
need = ["mainmenu_scene_home_main", "mainmenu_scene_home_icons",
        "mainmenu_scene_txt_home_lv", "txt_heroword", "dialogue_halfBlack9_pic"]
for n in [x for x in names if x.endswith(".plist")]:
    t = z.read(n).decode("utf-8", "replace")
    hit = [k for k in need if k in t]
    if hit:
        print("  %-90s %s" % (n, hit))

print("\n=== mainmenu-related .fpk / plist present in APK ===")
for n in names:
    if ("mainmenu" in n and (n.endswith(".fpk") or n.endswith(".plist"))):
        print("   ", n)

print("\n=== does the manifest list a ui_res/mainmenu_scene_new/<name>.png for the missing ones? ===")
miss = ["mainmenu_scene_home_main", "txt_heroword", "dialogue_halfBlack9_pic",
        "btn/mainmenu_scene_btn_1", "mainmenu_scene_home_icons"]
for m in miss:
    cand = [v for v in vals if m in v]
    print("  %-34s -> %s" % (m, cand[:3] if cand else "NOT IN MANIFEST"))
