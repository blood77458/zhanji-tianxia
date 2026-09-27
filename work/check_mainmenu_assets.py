import zipfile, re, json

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()

print("=== all APK entries containing 'mainmenu_scene' ===")
for n in sorted(names):
    if "mainmenu_scene" in n:
        print("   %-96s %d" % (n, z.getinfo(n).file_size))

print("\n=== entries containing 'dialogue_halfBlack9' ===")
for n in names:
    if "dialogue_halfBlack9" in n:
        print("   ", n)

print("\n=== search every .plist for frame 'dialogue_halfBlack9_pic' and 'mainmenu_scene_home_main' ===")
for n in [x for x in names if x.endswith(".plist")]:
    t = z.read(n).decode("utf-8", "replace")
    if "dialogue_halfBlack9_pic" in t or "mainmenu_scene_home_main" in t:
        print("   HIT:", n)
        for f in ("dialogue_halfBlack9_pic", "mainmenu_scene_home_main"):
            print("        %-32s %s" % (f, f in t))
