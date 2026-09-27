import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
plists = [n for n in z.namelist() if n.endswith(".plist")]
print("plist files in APK:", len(plists))

needles = ["countryCircle", "card_xing", "sdandard.png", "head.png", "guanping"]
hitmap = {n: [] for n in needles}

for n in plists:
    try:
        t = z.read(n).decode("utf-8", "replace")
    except Exception:
        continue
    for nd in needles:
        if nd in t:
            hitmap[nd].append(n)

for nd in needles:
    hits = hitmap[nd]
    print("\n%-16s -> %d plist(s)" % (nd, len(hits)))
    for h in hits[:6]:
        print("     ", h)
    # show the actual frame names found
    if nd == "countryCircle":
        for h in hits[:3]:
            t = z.read(h).decode("utf-8", "replace")
            print("     frames:", sorted(set(re.findall(r"countryCircle[\w\.]*", t)))[:20])
