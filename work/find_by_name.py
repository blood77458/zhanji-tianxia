import zipfile

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
names = z.namelist()
print("total entries:", len(names))

needles = ["mainmenu_scene_home_main", "txt_heroword", "mainmenu_scene_btn_1",
           "mainmenu_scene_home_icons", "dialogue_halfBlack9_pic",
           "mainmenu_scene_icon_home_arena", "mainmenu_scene_tips_big",
           "bg_mainmenu_tiao_kanbanMusume"]
for nd in needles:
    hits = [n for n in names if nd in n]
    print("\n%-34s -> %d hit(s)" % (nd, len(hits)))
    for h in hits[:6]:
        print("     ", h)

print("\n=== all ui_res subdirectories ===")
subs = sorted(set(n.split("/")[3] for n in names
                  if n.startswith("assets/resource/ui_res/") and len(n.split("/")) > 4))
print(len(subs))
for s in subs[:80]:
    print("   ", s)
