import zipfile, zlib, hashlib
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
z = zipfile.ZipFile(r"E:\deepseek_projects\app_server\work\zjt_pack_signed.apk")
name = [n for n in z.namelist() if "CocosObject." in n and n.endswith(".lua")][0]
blob = z.read(name)
plain = zlib.decompress(unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16))
print("decrypt ok", len(plain), "bytes")
print(plain[:200])
print("---")
print("patched?" , b"[patched]" in plain or b"NULL" in plain[:500])
# show require graph of DynamicUpdateScene
dn = [n for n in z.namelist() if "DynamicUpdateScene." in n][0]
db = z.read(dn)
dp = zlib.decompress(unpad(AES.new(KEY, AES.MODE_CBC, db[:16]).decrypt(db[16:]), 16))
print("DynamicUpdateScene head:")
print(dp[:400])
