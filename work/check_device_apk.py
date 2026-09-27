#!/usr/bin/env python3
import zipfile
z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\from_device.apk")
mans = [n for n in z.namelist() if n.startswith("assets/static_config.")]
print("device manifest:", mans)
m = z.read(mans[0]).decode()
i = m.find('<category value="resource/ui_res/login_new">')
j = m.find("</category>", i)
block = m[i:j]
print("btn_gold_yellow in login_new:", block.count("btn_gold_yellow.png"))
for line in block.splitlines():
    if "btn_gold_yellow.png" in line and "disable" not in line:
        print(" ", line.strip()[:200])
for line in m.splitlines():
    if "CocosObject.lua" in line:
        print("CocosObject entry:", line.strip())
hits = [n for n in z.namelist() if "CocosObject." in n and n.endswith(".lua")]
print("phys:", hits)
# LoadingScene preload?
hits2 = [n for n in z.namelist() if "LoadingScene." in n and n.endswith(".lua")]
print("LoadingScene:", hits2)
