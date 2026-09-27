#!/usr/bin/env python3
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import zipfile, zlib
KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack_signed.apk")
hits = [n for n in z.namelist() if "LoadingScene." in n and n.endswith(".lua")]
blob = z.read(hits[0])
plain = zlib.decompress(unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16))
print(hits[0])
for i, line in enumerate(plain.splitlines()[:12], 1):
    print("%2d| %s" % (i, line.decode("utf-8", "replace")))
assert b'require "canon.panel.CanonMessageBox"' in plain
print("PRELOAD OK")
# artfont
hits2 = [n for n in z.namelist() if "BaseUIScene." in n and n.endswith(".lua")]
blob2 = z.read(hits2[0])
plain2 = zlib.decompress(unpad(AES.new(KEY, AES.MODE_CBC, blob2[:16]).decrypt(blob2[16:]), 16))
assert b"useArtLabelTTF = false" in plain2
print("ARTFONT OFF OK")
mans = [n for n in z.namelist() if n.startswith("assets/static_config.")]
print("manifest", mans[0])
