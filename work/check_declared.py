import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
t = z.read(man).decode("utf-8", "replace")

# For each of the 20 paths the client requested but which have no physical file,
# is there already a logical <file> entry in the *right* category?
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

print("%-30s %-42s %s" % ("category", "file", "already declared in THAT category?"))
print("-" * 100)
for cat, base in MISSING:
    tag = '<category value="resource/%s">' % cat
    i = t.find(tag)
    declared = False
    if i >= 0:
        j = t.find("</category>", i)
        body = t[i:j]
        declared = ('value="%s"' % base) in body
    print("%-30s %-42s %s" % (cat, base, "YES" if declared else "no"))
