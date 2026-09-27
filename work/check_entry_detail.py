import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
t = z.read(man).decode("utf-8", "replace")
names = z.namelist()

def cat_entries(cat, base):
    tag = '<category value="resource/%s">' % cat
    i = t.find(tag)
    if i < 0:
        return []
    j = t.find("</category>", i)
    body = t[i:j]
    return [m.group(0).strip() for m in
            re.finditer(r'<file[^>]*value="%s"[^>]*/>' % re.escape(base), body)]

for cat, base in [("ui_res/shouye_new", "shouye_bg_home_common_sb.png"),
                  ("ui_res/shouye_new", "space.png"),
                  ("ui_res/mainmenu_scene_new", "dialogue_halfBlack9_pic.png"),
                  ("ui_res/login_new", "btn_gold_yellow.png")]:
    print("=== %s / %s ===" % (cat, base))
    for e in cat_entries(cat, base):
        print("   ", e)
        rm = re.search(r'md5="([0-9a-f]{32})"', e)
        if rm:
            md5 = rm.group(1)
            # what physical name would the engine derive, and does it exist?
            for cand in ("assets/resource/%s/%s.%s.png" % (cat, base[:-4], md5),
                         "assets/%s/%s.%s.png" % (cat, base[:-4], md5)):
                print("      candidate %-95s exists=%s" % (cand, cand in names))
    print()
