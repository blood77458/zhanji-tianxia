import zipfile, re

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_run_signed.apk")
man = [n for n in z.namelist()
       if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)][0]
txt = z.read(man).decode("utf-8", "replace")
vals = re.findall(r'value="([^"]+)"', txt)

# frames the client asks for by name in MainMenuScene:onInit
probes = [
    "countryCircle_2.png", "countryCircle_1.png", "countryCircle_3.png",
    "card_xing.png", "main_ad_world_boss.png", "main_ad_happyfish_invitecode.png",
    "bg_home_bg.png",
]
for p in probes:
    hits = [v for v in vals if p in v]
    print("%-34s %s" % (p, ("FOUND: " + ", ".join(hits[:3])) if hits else "*** MISSING ***"))

print()
# what plists define sprite frames?
plists = [v for v in vals if v.endswith(".plist")]
print("total .plist entries:", len(plists))
for pat in ("country", "card", "home", "main_ad"):
    sel = [v for v in plists if pat in v.lower()]
    print("  plists containing '%s': %d   e.g. %s" % (pat, len(sel), sel[:4]))
