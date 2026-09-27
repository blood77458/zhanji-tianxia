import sys, zipfile, re
sys.path.insert(0, r"E:\deepseek_projects\app_server\work")
import patch_lua as pl

z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack.apk")

def grab(prefix):
    hits = [n for n in z.namelist() if n.startswith(prefix) and n.endswith(".lua")]
    return hits[0] if hits else None

checks = {
    "canon/scene/BaseUIScene.":      [b"useArtLabelTTF = false", b"useArtLabelTTF = true"],
    "hecore/ui/LayoutBuilder.":      [b"!!!IMG_REQ", b"!!!BUILD_GROUP"],
    "hecore/display/CocosObject.":   [b"!!!NULL_COCOS_OBJECT"],
    "hecore/display/Sprite.":        [b"_safeSprite", b"!!!TEXTURELESS_SPRITE"],
    "canon/canonUtils.":             [b"full.png", b"NO_CARD_FRAME"],
    "canon/scene/CreateCharacterScene.": [b"[patched] 6-point"],
}
for pre, needles in checks.items():
    a = grab("assets/src/" + pre)
    print("=== %s ===" % pre)
    if not a:
        print("    NOT FOUND")
        continue
    blob = z.read(a)
    try:
        plain = pl.decrypt(blob)
    except Exception as e:
        print("    decrypt failed:", e)
        continue
    for nd in needles:
        print("    %-32s %s" % (nd.decode('utf-8', 'replace'), nd in plain))
