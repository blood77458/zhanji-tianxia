#!/usr/bin/env python3
import zipfile, re, collections
z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack_signed.apk")
mans = [n for n in z.namelist() if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)]
print("manifests:", mans)
m = z.read(mans[0]).decode("utf-8", errors="replace")
vals = re.findall(r'value="([^"]+)"', m)
c = collections.Counter(vals)
dups = [(k, v) for k, v in c.items() if v > 1]
print("dup count:", len(dups))
for k, v in sorted(dups, key=lambda x: -x[1])[:40]:
    print(v, k)
print("--- btn_gold / CocosObject lines ---")
for line in m.splitlines():
    if "btn_gold_yellow" in line or "CocosObject" in line:
        print(line[:240])
