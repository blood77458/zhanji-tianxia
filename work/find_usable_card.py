import zipfile, re, collections

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()

# group card art by figureId directory
per = collections.defaultdict(dict)
for n in names:
    m = re.match(r"assets/resource/card/card/([^/]+)/([^./]+)\.", n)
    if m:
        per[m.group(1)][m.group(2)] = n

print("card figure dirs with art:", len(per))
have_std = sorted(k for k, v in per.items() if "sdandard" in v)
have_full = sorted(k for k, v in per.items() if "full" in v)
print("dirs with full    :", len(have_full))
print("dirs with sdandard:", len(have_std))
print("sample with sdandard:", have_std[:15])

# name the files present for a few
for k in have_std[:3]:
    print("  %-24s -> %s" % (k, sorted(per[k])))

# Now map figureId -> metaId using the decrypted card_meta config
import os
cfgdir = r"E:\deepseek_projects\app_server\work\luasrc\canon\configs"
cf = [f for f in os.listdir(cfgdir) if f.startswith("card_meta.")][0]
txt = open(os.path.join(cfgdir, cf), "rb").read().decode("utf-8", "replace")
pairs = re.findall(r'\[(\d+)\]=\{id=\1,name="[^"]*".*?figureId="([^"]+)"', txt)
print("\ncard_meta entries parsed:", len(pairs))
by_fig = {}
for mid, fig in pairs:
    by_fig.setdefault(fig, []).append(int(mid))

usable = []
for fig in have_std:
    if fig in by_fig:
        usable.append((fig, by_fig[fig][0]))
print("\nmetaIds whose figureId has sdandard art:", len(usable))
for fig, mid in usable[:20]:
    print("   figureId=%-24s metaId=%d" % (fig, mid))
