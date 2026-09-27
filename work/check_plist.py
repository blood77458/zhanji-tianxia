import zipfile, re, zlib

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()

for want in ("city_map", "map_others", "card_plist"):
    hits = [n for n in names if want in n]
    print("%-12s -> %s" % (want, hits[:3]))

print()
# try to read the city_map / map_others plists and search for countryCircle
for want in ("city_map", "map_others"):
    for n in [x for x in names if want in x]:
        b = z.read(n)
        head = b[:64]
        print("=== %s (%d bytes) ===" % (n, len(b)))
        print("   head:", head[:48])
        plain = None
        if b[:2] == b"\x78\x9c":
            try:
                plain = zlib.decompress(b)
            except Exception:
                pass
        if plain is None:
            # maybe IV||AES like lua assets
            plain = b
        try:
            t = plain.decode("utf-8", "replace")
        except Exception:
            t = ""
        print("   'countryCircle' in content:", "countryCircle" in t)
        m = re.findall(r"countryCircle[^<\"]*", t)
        print("   matches:", m[:10])
        print()
