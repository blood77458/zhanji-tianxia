import zipfile, re

def man_of(path):
    z = zipfile.ZipFile(path)
    m = [n for n in z.namelist()
         if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
    return z, m, z.read(m).decode("utf-8", "replace")

z0, m0, t0 = man_of(r"E:\deepseek_projects\app_server\work\zjt_run.apk")
z1, m1, t1 = man_of(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")
print("zjt_run  manifest:", m0)
print("zjt_pack manifest:", m1)
print()

for probe in ("shouye_bg_home_common_sb.png", "shouye_icon_silverCoin_sb.png",
              "btn_gold_yellow.png"):
    print("=== %s ===" % probe)
    for label, t in (("run ", t0), ("pack", t1)):
        for m in re.finditer(r'<file[^>]*value="%s"[^>]*/>' % re.escape(probe), t):
            print("   %s | %s" % (label, m.group(0).strip()))
    print()

print("=== do my d08ea88 / 4bf322 / c4a2b8 markers exist in pack? ===")
for tag in ("d08ea88ca145c6e57514d263ce8983da", "4bf3228848d0e4021cb02bd06bef4679",
            "c4a2b870062c2bb98c500bc1526c0498"):
    print("   %s : run=%d pack=%d" % (tag, t0.count(tag), t1.count(tag)))

print("\n=== physical injected files present? ===")
for zn in ("assets/resource/ui_res/shouye_new/shouye_bg_home_common_sb.d08ea88ca145c6e57514d263ce8983da.png",
           "assets/resource/ui_res/login_new/space.c4a2b870062c2bb98c500bc1526c0498.png"):
    print("   %-100s run=%s pack=%s" % (zn.split("/")[-1][:60], zn in z0.namelist(), zn in z1.namelist()))
