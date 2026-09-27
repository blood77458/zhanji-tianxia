#!/usr/bin/env python3
import zipfile, re, hashlib
z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack_signed.apk")
mans = [n for n in z.namelist() if n.startswith("assets/static_config.")]
m = z.read(mans[0]).decode()
for line in m.splitlines():
    if "CocosObject.lua" in line:
        print("MAN:", line.strip())
hits = [n for n in z.namelist() if "CocosObject." in n and n.endswith(".lua")]
print("PHYS:", hits)
for h in hits:
    blob = z.read(h)
    print("  md5", hashlib.md5(blob).hexdigest(), "size", len(blob), "name", h.split("/")[-1])

i = m.find('<category value="resource/ui_res/login_new">')
j = m.find("</category>", i)
block = m[i:j]
print("--- login_new btn_gold_yellow (non-disable) ---")
for line in block.splitlines():
    if "btn_gold_yellow.png" in line and "disable" not in line:
        print(line.strip())

# Also check: does original bypass already have btn_gold_yellow in login_new?
z2 = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_bypass.apk")
mans2 = [n for n in z2.namelist() if n.startswith("assets/static_config.")]
m2 = z2.read(mans2[0]).decode()
i2 = m2.find('<category value="resource/ui_res/login_new">')
j2 = m2.find("</category>", i2)
block2 = m2[i2:j2]
print("--- ORIGINAL bypass login_new btn_gold_yellow ---")
for line in block2.splitlines():
    if "btn_gold_yellow.png" in line and "disable" not in line:
        print(line.strip())
