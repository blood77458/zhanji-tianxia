import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
t = z.read(man).decode("utf-8", "replace")

# The ORIGINAL (pre-injection) manifest is inside zjt_run.apk
z0 = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run.apk")
man0 = [n for n in z0.namelist()
        if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
t0 = z0.read(man0).decode("utf-8", "replace")

probe = "btn_gold_yellow.png"
for label, txt in (("ORIGINAL zjt_run", t0), ("INJECTED zjt_pack", t)):
    hits = re.findall(r'<file[^>]*value="%s"[^>]*/>' % re.escape(probe), txt)
    print("%-18s entries for %-24s : %d" % (label, probe, len(hits)))
    for h in hits:
        print("      ", h.strip())

print()
print("=== how many of my 20 injected names ALREADY existed in the original manifest? ===")
mine = ["btn_gold_yellow.png", "btn_long_blue.png", "btu_FBid.png",
        "login_btn_yellow_long.png", "other2_gray9_panel_new.png",
        "other_gray9_panel_l.png", "other_solid_gray9_panel.png", "space.png",
        "white9_panel.png", "dialogue_halfBlack9_pic.png",
        "mainmenu_scene_icon_home_cardEnhance_sb.png", "mainmenu_scene_tips_big.png",
        "mainmenu_scene_tips_little.png", "shouye_bg_home_baseBroadcast_sb.png",
        "shouye_bg_home_common_sb.png", "shouye_bg_home_menu_title_sb.png",
        "shouye_btn_home_back_sb.png", "shouye_icon_cionEvent_sb.png",
        "shouye_icon_silverCoin_sb.png"]
for base in mine:
    n0 = len(re.findall(r'value="%s"' % re.escape(base), t0))
    n1 = len(re.findall(r'value="%s"' % re.escape(base), t))
    # is a physical file present in the ORIGINAL apk?
    phys = any(re.search(r"/%s\.[0-9a-f]{16,40}\.png$" % re.escape(base[:-4]), x)
               for x in z0.namelist())
    print("  %-46s orig_mf=%d  new_mf=%d  orig_physical=%s"
          % (base, n0, n1, phys))
