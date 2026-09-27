import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")
print("manifest:", man)
print("entries:", txt.count("<file "))
print()

for probe in ("guanping_2", "card/card", "sdandard", "card_meta"):
    print("%-12s occurrences: %d" % (probe, txt.count(probe)))
print()

vals = re.findall(r'value="([^"]+)"', txt)
print("total value= entries:", len(vals))
cardish = [v for v in vals if "card" in v.lower()]
print("entries containing 'card':", len(cardish))
for v in cardish[:20]:
    print("   ", v)
print()
print("first 20 values overall:")
for v in vals[:20]:
    print("   ", v)
