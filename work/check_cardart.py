import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")
vals = re.findall(r'value="([^"]+)"', txt)

print("=== manifest entries mentioning guanping_2 ===")
for v in vals:
    if "guanping_2" in v:
        print("   ", v)

print("\n=== APK file entries mentioning guanping_2 ===")
names = [n for n in z.namelist() if "guanping_2" in n]
for n in names:
    print("   %-80s %d bytes" % (n, z.getinfo(n).file_size))
print("count:", len(names))

print("\n=== card/card directory listing in manifest ===")
cc = sorted(set(v for v in vals if v.startswith("card/card")))
print("entries starting 'card/card':", len(cc))
for v in cc[:20]:
    print("   ", v)

print("\n=== manifest entries for meta 101022 (fallback card) ===")
for v in vals:
    if "101022" in v:
        print("   ", v)
