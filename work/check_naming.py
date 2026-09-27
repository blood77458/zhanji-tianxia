import zipfile, re, hashlib

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")

tests = ["mainmenu_scene_bbg", "mainmenu_scene_sdandard",
         "shouye_bg_home_upper", "txt_heroword"]
print("=== does physical hash == md5(content)? ===")
for base in tests:
    hits = [n for n in z.namelist()
            if re.search(r"/%s\.[0-9a-f]{16,40}\.png$" % re.escape(base), n)]
    for h in hits[:1]:
        b = z.read(h)
        name_hash = re.search(r"\.([0-9a-f]{16,40})\.png$", h).group(1)
        for label, val in (("md5(content)", hashlib.md5(b).hexdigest()),
                           ("sha1", hashlib.sha1(b).hexdigest())):
            print("  %-34s namehash=%-34s %s=%s  %s"
                  % (base, name_hash, label, val, "MATCH" if val.startswith(name_hash) else "no"))

print("\n=== manifest entry format for a ui_res png ===")
m = re.search(r"<file[^>]*mainmenu_scene_bbg[^>]*/>", txt)
print("  ", m.group(0) if m else "not found")
m2 = re.search(r"<file[^>]*value=\"ui_res[^\"]*\"[^>]*/>", txt)
print("  ", m2.group(0) if m2 else "no ui_res value= entry")

print("\n=== how are ui_res files referenced in the manifest? (sample) ===")
for mm in list(re.finditer(r'value="([^"]*ui_res[^"]*)"', txt))[:5]:
    print("   ", mm.group(0))
print("   total ui_res values:", len(re.findall(r'value="[^"]*ui_res[^"]*"', txt)))

print("\n=== first 400 chars of manifest (structure) ===")
print(txt[:400])
