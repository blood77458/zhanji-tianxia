#!/usr/bin/env python3
"""Patch only ActivityPanelScene.enable() with pcall onto zjt_pack_signed.apk."""
import os, re, sys, zlib, hashlib, zipfile
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
SRC = r"E:\deepseek_projects\app_server\work\zjt_pack_signed.apk"
OUT = r"E:\deepseek_projects\app_server\work\zjt_pack_enablefix.apk"


def decrypt(blob):
    iv, ct = blob[:16], blob[16:]
    pt = unpad(AES.new(KEY, AES.MODE_CBC, iv).decrypt(ct), 16)
    return zlib.decompress(pt)


def encrypt(plain):
    iv = os.urandom(16)
    ct = AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(zlib.compress(plain, 9), 16))
    return iv + ct


def main():
    zin = zipfile.ZipFile(SRC)
    names = zin.namelist()
    man = [n for n in names if n.startswith("assets/static_config.") and n.endswith(".xml")][0]
    manifest = zin.read(man)
    virt = "canon/scene/ActivityPanelScene.lua"
    prefix = "assets/src/" + virt.rsplit(".", 1)[0] + "."
    hits = [x for x in names if x.startswith(prefix) and x.endswith(".lua")]
    assert len(hits) == 1, hits
    old_name = hits[0]
    old_blob = zin.read(old_name)
    old_md5 = hashlib.md5(old_blob).hexdigest()
    plain = decrypt(old_blob)

    if b"pcall(function() return value.panel.enable()" in plain:
        print("already patched")
        return

    old = (
        b"function ActivityPanelScene:initEnabledPanels()\r\n"
        b"  for _, value in ipairs(DICT_PANEL) do\r\n"
        b"    if value.panel then\r\n"
        b"      local enable = value.panel.enable()\r\n"
    )
    new = (
        b"function ActivityPanelScene:initEnabledPanels()\r\n"
        b"  for _, value in ipairs(DICT_PANEL) do\r\n"
        b"    if value.panel then\r\n"
        b"      -- [patched] pcall enable so nil-config tabs don't SIGKILL\r\n"
        b"      local ok, enable = pcall(function() return value.panel.enable() end)\r\n"
        b"      if not ok then enable = false end\r\n"
    )
    if plain.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
        new = new.replace(b"\r\n", b"\n")
    if plain.count(old) != 1:
        raise SystemExit(f"enable match={plain.count(old)}")

    # Also harden LevelRace displayTypes indexing
    old2 = (
        b"          for _, aDisplayType in pairs(DataManager.GameMetaData.activityLevelRaceConfig.displayTypes) do\r\n"
        b"            if aDisplayType.id == DataManager.getServerid() then\r\n"
        b"              rewardType = aDisplayType.type\r\n"
        b"            end\r\n"
        b"            if aDisplayType.id == 0 then\r\n"
        b"              defaultRewardType = aDisplayType.type\r\n"
        b"            end\r\n"
        b"          end\r\n"
    )
    new2 = (
        b"          local dts = DataManager.GameMetaData.activityLevelRaceConfig.displayTypes or {}\r\n"
        b"          for _, aDisplayType in pairs(dts) do\r\n"
        b"            if type(aDisplayType) == \"table\" then\r\n"
        b"              if aDisplayType.id == DataManager.getServerid() then\r\n"
        b"                rewardType = aDisplayType.type\r\n"
        b"              end\r\n"
        b"              if aDisplayType.id == 0 then\r\n"
        b"                defaultRewardType = aDisplayType.type\r\n"
        b"              end\r\n"
        b"            end\r\n"
        b"          end\r\n"
        b"          rewardType = rewardType or defaultRewardType or 0\r\n"
    )
    if plain.count(old2) != 1:
        old2 = old2.replace(b"\r\n", b"\n")
        new2 = new2.replace(b"\r\n", b"\n")
    if plain.count(old2) != 1:
        raise SystemExit(f"displayTypes match={plain.count(old2)}")

    new_plain = plain.replace(old, new, 1).replace(old2, new2, 1)
    new_blob = encrypt(new_plain)
    new_md5 = hashlib.md5(new_blob).hexdigest()
    new_name = old_name.replace(old_md5, new_md5)

    rx = re.compile(
        rb'(value="ActivityPanelScene\.lua"\s+md5=")'
        + old_md5.encode()
        + rb'("\s+size=")\d+(")'
    )
    new_manifest, c = rx.subn(
        rb"\g<1>" + new_md5.encode() + rb"\g<2>" + str(len(new_blob)).encode() + rb"\g<3>",
        manifest,
    )
    if c != 1:
        raise SystemExit(f"manifest matches={c}")
    man_md5 = hashlib.md5(new_manifest).hexdigest()
    man_new = "assets/static_config.%s.xml" % man_md5
    print(f"ActivityPanel {old_md5} -> {new_md5}")
    print(f"manifest {man.split('.')[1]} -> {man_md5}")

    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            fn = item.filename
            if fn == old_name:
                zout.writestr(new_name, new_blob)
            elif fn == man:
                zout.writestr(man_new, new_manifest)
            else:
                zout.writestr(item, zin.read(fn))
    print(f"DONE -> {OUT} ({os.path.getsize(OUT)/1024/1024:.1f} MB)")


if __name__ == "__main__":
    main()
