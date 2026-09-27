import zipfile, re, hashlib
z = zipfile.ZipFile("zjt_pack_signed.apk")
mans = [n for n in z.namelist() if n.startswith("assets/static_config.")]
print("manifests", mans)
man = mans[0]
blob = z.read(man)
print("manifest md5 match", hashlib.md5(blob).hexdigest() in man)
text = blob.decode("utf-8", errors="replace")
hits = [line.strip() for line in text.splitlines() if "CocosObject" in line]
print("manifest CocosObject lines:", len(hits))
for h in hits[:5]:
    print(" ", h[:180])
coc = [n for n in z.namelist() if "CocosObject" in n]
print("apk CocosObject files:", coc)
for n in coc:
    b = z.read(n)
    md5 = hashlib.md5(b).hexdigest()
    print(" ", n.split("/")[-1], "content_md5", md5, "name_ok", md5 in n)
cq = [n for n in z.namelist() if "CardQueueScene" in n]
print("CardQueueScene:", cq)
# CanonMessageBox
cm = [n for n in z.namelist() if "CanonMessageBox" in n]
print("CanonMessageBox files:", cm)
cmh = [line.strip() for line in text.splitlines() if "CanonMessageBox" in line]
print("manifest CanonMessageBox:", cmh[:3])
