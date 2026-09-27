import zipfile

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = [n for n in z.namelist() if n.startswith("assets/src/")]
print("assets/src entries:", len(names))

needles = [b"countryCircle", b"card_xing", b"guanping_2", b"sdandard"]
found = {n: [] for n in needles}

scanned = 0
for n in names:
    # only scan small/medium files; plists are small
    try:
        info = z.getinfo(n)
    except KeyError:
        continue
    if info.file_size > 4_000_000:
        continue
    try:
        b = z.read(n)
    except Exception:
        continue
    scanned += 1
    for nd in needles:
        if nd in b:
            found[nd].append((n, len(b)))

print("scanned", scanned, "files")
for nd in needles:
    hits = found[nd]
    print("\n%s -> %d hit(s)" % (nd.decode(), len(hits)))
    for n, sz in hits[:8]:
        print("    %-70s %d bytes" % (n, sz))
