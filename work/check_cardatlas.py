import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()

print("=== APK entries under assets/resource/card/card/guanping_2/ ===")
for n in names:
    if "card/card/guanping_2/" in n:
        print("   %-90s %d bytes" % (n, z.getinfo(n).file_size))

print("\n=== APK entries under assets/resource/card/card/ (first 20 names) ===")
cc = sorted(set(n.split("/")[4] for n in names
                if n.startswith("assets/resource/card/card/") and len(n.split("/")) > 5))
print("   sub-entries:", len(cc))
for c in cc[:20]:
    print("     ", c)

man = [n for n in names if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")
vals = re.findall(r'value="([^"]+)"', txt)
print("\n=== manifest values for card/card/guanping_2 ===")
for v in vals:
    if "guanping_2" in v:
        print("   ", v)

print("\n=== does any .json/.plist describe card frames? ===")
for pat in ("card_plist", "card/card/guanping_2", "sdandard"):
    sel = [n for n in names if pat in n]
    print("  %-24s -> %d  e.g. %s" % (pat, len(sel), sel[:3]))
