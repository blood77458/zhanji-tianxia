import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
t = z.read(man).decode("utf-8", "replace")
names = set(z.namelist())

bases = ["CocosObject.lua", "Sprite.lua", "LayoutBuilder.lua",
         "canonUtils.lua", "BaseUIScene.lua", "CreateCharacterScene.lua",
         "ThirdPlatformLogin.lua"]
for base in bases:
    m = re.search(r'<file[^>]*value="%s"[^>]*/>' % re.escape(base), t)
    print("%-28s %s" % (base, m.group(0).strip() if m else "NOT FOUND"))
    if m:
        rm = re.search(r'ref="([^"]+)"', m.group(0))
        if rm:
            phys = "assets/" + rm.group(1)
            print("%-28s   ref present -> exists in zip: %s" % ("", phys in names))
        else:
            print("%-28s   (no ref attribute)" % "")

print()
print("=== physical CocosObject/Sprite files actually in the APK ===")
for n in sorted(names):
    if re.search(r"(CocosObject|Sprite|LayoutBuilder|canonUtils|BaseUIScene)\.[0-9a-f]{16,40}\.lua$", n):
        print("   ", n)
