#!/usr/bin/env python3
"""
Inject the 20 missing UI images into the APK as a hand-made "resource pack".

Background: the probe build (LayoutBuilder IMG_REQ/IMG_OBJ) showed the client
requests exactly these 20 paths and that they are absent from the APK *and* from
assets/static_config.*.xml.  The engine still hands back a valid (non-NULL)
object for them, so a Lua pointer check cannot see the problem -- but the object
has no texture, and CCSprite::draw() on a textureless sprite is the classic
GLThread SIGSEGV (fault addr 0x0).

Asset conventions (verified):
    physical name = assets/<ref>, where ref = "<logical dir>/<base>.<md5(content)>.<ext>"
    manifest node = <category value="resource/ui_res/<dir>">
                       <file value="<base>.png" md5="<md5>" size="<n>"
                             required="1" ref="<ref>" />
    manifest file itself is named static_config.<md5(manifest)>.xml

So we can add entries exactly the way the packager did.
"""
import os, io, re, sys, zlib, struct, hashlib, zipfile

SRC_APK = r"E:\deepseek_projects\app_server\work\zjt_run.apk"
OUT_APK = r"E:\deepseek_projects\app_server\work\zjt_pack.apk"

# --- the 20 paths the client actually asked for and that are absent ---------
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


def png(w, h, pixel):
    """RGBA PNG built with stdlib only. pixel(x,y) -> (r,g,b,a)."""
    raw = bytearray()
    for y in range(h):
        raw.append(0)                      # filter type 0
        for x in range(w):
            raw += bytes(pixel(x, y))

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)   # 8-bit RGBA
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def placeholder(logical_path):
    """A plausible-looking stand-in so the screen is readable, not a black hole."""
    base = logical_path.rsplit("/", 1)[1]

    if base == "space.png":
        # a spacer must be invisible
        return png(1, 1, lambda x, y: (0, 0, 0, 0))

    nine = base.endswith("_sb.png") or "9_panel" in base or "halfBlack9" in base
    if nine:
        # nine-slice panel: translucent dark fill with a light 1px border
        W = H = 48
        def px(x, y):
            if x in (0, W - 1) or y in (0, H - 1):
                return (235, 225, 190, 255)
            return (28, 30, 44, 205)
        return png(W, H, px)

    # generic button / icon placeholder: distinct colour per name, opaque
    pal = ((214, 178, 84), (92, 146, 214), (150, 110, 200), (100, 180, 120),
           (210, 120, 110), (120, 190, 190), (190, 160, 120))
    r, g, b = pal[sum(base.encode()) % len(pal)]
    W = H = 64
    def px2(x, y):
        if x in (0, W - 1) or y in (0, H - 1):
            return (255, 255, 255, 255)
        return (r, g, b, 255)
    return png(W, H, px2)


def main():
    zin = zipfile.ZipFile(SRC_APK)
    names = zin.namelist()
    man_old = [n for n in names
               if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)]
    if len(man_old) != 1:
        raise SystemExit(f"expected 1 manifest, got {man_old}")
    man_old = man_old[0]
    man_txt = zin.read(man_old).decode("utf-8")
    print("source   :", SRC_APK)
    print("manifest :", man_old)

    # group the missing files by their ui_res sub-directory
    by_dir = {}
    for p in MISSING:
        d = p.rsplit("/", 1)[0]              # ui_res/login_new
        by_dir.setdefault(d, []).append(p.rsplit("/", 1)[1])

    added_entries = []                       # (zip name, bytes)
    added_xml = []                           # (category, xml line)

    # IMPORTANT: many of the "missing" logical paths are ALREADY registered in
    # static_config under the same category, with a cross-folder `ref` pointing
    # at a shared texture that lives elsewhere (e.g. login_new/btn_gold_yellow
    # -> resource/ui_res/Gvg/btn_gold_yellow.<md5>.png).  Re-inserting them
    # produces `static config error, file ... repeat`, which breaks
    # ResManager:initStaticConfig() and makes subsequent `require` fall through
    # to the default filesystem searcher ("module 'hecore.display.CocosObject'
    # not found").  Skip any value that is already present in its category.
    skipped = 0
    for d, bases in sorted(by_dir.items()):
        cat = "resource/" + d                # resource/ui_res/login_new
        tag = '<category value="%s">' % cat
        i = man_txt.find(tag)
        if i < 0:
            raise SystemExit("category not found: " + cat)
        j = man_txt.find("</category>", i)
        block = man_txt[i:j]
        for base in sorted(bases):
            if ('value="%s"' % base) in block:
                print("  = skip (already in %s): %s" % (cat, base))
                skipped += 1
                continue
            blob = placeholder(d + "/" + base)
            md5 = hashlib.md5(blob).hexdigest()
            # NOTE: the ref (and hence the physical zip path) must carry the
            # leading "resource/" — existing entries look like
            #   ref="resource/ui_res/mainmenu_scene_new/btn_chat.<md5>.png"
            # and the zip entry is assets/<ref>.
            ref = "resource/%s/%s.%s.png" % (d, base[:-4], md5)
            zipname = "assets/" + ref
            if zipname in names:
                raise SystemExit("already present: " + zipname)
            added_entries.append((zipname, blob))
            added_xml.append((cat,
                              '         <file  value="%s"  md5="%s"  size="%d"  '
                              'required="1"  ref="%s" />'
                              % (base, md5, len(blob), ref)))
            print("  + %-64s %5d B" % (ref, len(blob)))

    # ---- splice the <file> lines into the matching <category> --------------
    for cat, xml in added_xml:
        tag = '<category value="%s">' % cat
        i = man_txt.find(tag)
        if i < 0:
            raise SystemExit("category not found: " + cat)
        # insert right after the category open tag
        ins = man_txt.index("\n", i) + 1
        man_txt = man_txt[:ins] + xml + "\n" + man_txt[ins:]

    if not added_entries and skipped:
        # Nothing new to inject — just copy zjt_run through so the pipeline
        # still produces zjt_pack.apk with an identical (valid) manifest.
        print("\nno new assets to inject (%d already present); copying APK" % skipped)
        import shutil
        shutil.copy2(SRC_APK, OUT_APK)
        print("DONE -> %s  (%.1f MB, copy of %s)"
              % (OUT_APK, os.path.getsize(OUT_APK) / 1024 / 1024, SRC_APK))
        return

    man_md5 = hashlib.md5(man_txt.encode("utf-8")).hexdigest()
    man_new = "assets/static_config.%s.xml" % man_md5
    print("\nmanifest md5 %s -> %s" % (man_old.split(".")[1], man_md5))

    print("\nrebuilding APK ...")
    zout = zipfile.ZipFile(OUT_APK, "w", zipfile.ZIP_DEFLATED)
    for item in zin.infolist():
        if item.filename == man_old:
            zout.writestr(man_new, man_txt)
        else:
            zout.writestr(item, zin.read(item.filename))
    for zn, blob in added_entries:
        zout.writestr(zn, blob)
    zout.close()

    z = zipfile.ZipFile(OUT_APK)
    for zn, blob in added_entries:
        got = z.read(zn)
        assert got == blob, zn
        assert hashlib.md5(got).hexdigest() in zn, zn
    assert hashlib.md5(z.read(man_new)).hexdigest() == man_md5
    assert man_old not in z.namelist()
    print("DONE -> %s  (%.1f MB, %d entries)"
          % (OUT_APK, os.path.getsize(OUT_APK) / 1024 / 1024, len(z.namelist())))
    print("injected %d files (skipped %d), NEW MANIFEST: %s"
          % (len(added_entries), skipped, man_new))


if __name__ == "__main__":
    main()
