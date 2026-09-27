import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")

# find the resource node for ui_res/shouye_new and show its structure
for key in ("resource/ui_res/shouye_new", "resource/ui_res/login_new",
            "resource/ui_res/mainmenu_scene_new"):
    i = txt.find('path="%s"' % key)
    print("=== %s (index %d) ===" % (key, i))
    if i >= 0:
        print(txt[i - 60:i + 700].replace("\r\n", "\n"))
    print()

print("=== a nested category/resource sample: how deep does the tree go? ===")
# show indentation levels
for line in txt.split("\r\n")[:40]:
    if line.strip():
        print(repr(line[:150]))
