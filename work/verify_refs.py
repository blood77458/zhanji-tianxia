import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
t = z.read(man).decode("utf-8", "replace")
names = set(z.namelist())

MISSING = [
    ("ui_res/login_new", "btn_gold_yellow.png"),
    ("ui_res/login_new", "btn_long_blue.png"),
    ("ui_res/login_new", "btu_FBid.png"),
    ("ui_res/login_new", "login_btn_yellow_long.png"),
    ("ui_res/login_new", "other2_gray9_panel_new.png"),
    ("ui_res/login_new", "other_gray9_panel_l.png"),
    ("ui_res/login_new", "other_solid_gray9_panel.png"),
    ("ui_res/login_new", "space.png"),
    ("ui_res/login_new", "white9_panel.png"),
    ("ui_res/mainmenu_scene_new", "dialogue_halfBlack9_pic.png"),
    ("ui_res/mainmenu_scene_new", "mainmenu_scene_icon_home_cardEnhance_sb.png"),
    ("ui_res/mainmenu_scene_new", "mainmenu_scene_tips_big.png"),
    ("ui_res/mainmenu_scene_new", "mainmenu_scene_tips_little.png"),
    ("ui_res/shouye_new", "shouye_bg_home_baseBroadcast_sb.png"),
    ("ui_res/shouye_new", "shouye_bg_home_common_sb.png"),
    ("ui_res/shouye_new", "shouye_bg_home_menu_title_sb.png"),
    ("ui_res/shouye_new", "shouye_btn_home_back_sb.png"),
    ("ui_res/shouye_new", "shouye_icon_cionEvent_sb.png"),
    ("ui_res/shouye_new", "shouye_icon_silverCoin_sb.png"),
    ("ui_res/shouye_new", "space.png"),
]

def find_entry(cat, base):
    tag = '<category value="resource/%s">' % cat
    i = t.find(tag)
    if i < 0:
        return None
    j = t.find("</category>", i)
    for m in re.finditer(r'<file[^>]*value="%s"[^>]*/>' % re.escape(base), t[i:j]):
        return m.group(0)
    return None

ok = miss = 0
for cat, base in MISSING:
    e = find_entry(cat, base)
    if not e:
        print("%-42s NO ENTRY" % base); miss += 1; continue
    rm = re.search(r'ref="([^"]+)"', e)
    if not rm:
        print("%-42s entry has NO ref -> physical truly needed" % base); miss += 1; continue
    phys = "assets/" + rm.group(1)
    ex = phys in names
    ok += 1 if ex else 0
    miss += 0 if ex else 1
    print("%-42s ref -> %-70s exists=%s" % (base, rm.group(1)[:70], ex))

print()
print("ref targets PRESENT : %d / %d" % (ok, len(MISSING)))
print("still unresolved    : %d" % miss)
