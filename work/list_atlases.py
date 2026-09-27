import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")
vals = re.findall(r'value="([^"]+)"', txt)
print("total values:", len(vals))

# All .plist atlas entries (these name the sprite-frame atlases)
plists = sorted(set(v for v in vals if v.endswith(".plist")))
print("\n=== all %d .plist entries ===" % len(plists))
for p in plists:
    print("   ", p)

print("\n=== entries mentioning 'main' or 'home' or 'ui' ===")
sel = sorted(set(v for v in vals if re.search(r"main|home|^ui|_ui|common", v, re.I)))
for v in sel[:60]:
    print("   ", v)
