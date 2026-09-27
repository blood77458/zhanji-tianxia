#!/usr/bin/env python3
"""Check which inject MISSING paths already exist in original bypass manifest."""
import zipfile, re

MISSING = [
    "ui_res/login_new/btn_gold_yellow.png",
    "ui_res/login_new/btn_long_blue.png",
    "ui_res/login_new/btu_FBid.png",
    "ui_res/login_new/login_btn_yellow_long.png",
    "ui_res/login_new/other2_gray9_panel_new.png",
    "ui_res/login_new/other_gray9_panel_l.png",
    "ui_res/login_new/other_solid_gray9_panel.png",
    "ui_res/login_new/space.png",
    "ui_res/login_new/white9_panel.png",
    "ui_res/mainmenu_scene_new/dialogue_halfBlack9_pic.png",
    "ui_res/mainmenu_scene_new/mainmenu_scene_icon_home_cardEnhance_sb.png",
    "ui_res/mainmenu_scene_new/mainmenu_scene_tips_big.png",
    "ui_res/mainmenu_scene_new/mainmenu_scene_tips_little.png",
    "ui_res/shouye_new/shouye_bg_home_baseBroadcast_sb.png",
    "ui_res/shouye_new/shouye_bg_home_common_sb.png",
    "ui_res/shouye_new/shouye_bg_home_menu_title_sb.png",
    "ui_res/shouye_new/shouye_btn_home_back_sb.png",
    "ui_res/shouye_new/shouye_icon_cionEvent_sb.png",
    "ui_res/shouye_new/shouye_icon_silverCoin_sb.png",
    "ui_res/shouye_new/space.png",
]

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_bypass.apk")
mans = [n for n in z.namelist() if n.startswith("assets/static_config.")]
m = z.read(mans[0]).decode()

for p in MISSING:
    d, base = p.rsplit("/", 1)
    cat = "resource/" + d
    i = m.find('<category value="%s">' % cat)
    j = m.find("</category>", i)
    block = m[i:j] if i >= 0 else ""
    hits = [ln.strip() for ln in block.splitlines() if 'value="%s"' % base in ln]
    # also check physical file presence by basename pattern
    phys = [n for n in z.namelist() if n.endswith("/" + base.replace(".png", "")) or
            ("/" + base[:-4] + ".") in n and n.endswith(".png") and d in n]
    # simpler physical check
    phys2 = [n for n in z.namelist() if n.startswith("assets/resource/" + d + "/" + base[:-4] + ".") and n.endswith(".png")]
    status = "IN_CAT" if hits else "NOT_IN_CAT"
    print("%s  %s  phys=%d  entries=%d" % (status, p, len(phys2), len(hits)))
    for h in hits:
        print("   ", h[:180])
