#!/usr/bin/env python3
"""
apk_recon.py -- offline reconnaissance of an APK without running it.
Reports structure, engine fingerprint, packer/protector fingerprint,
native libs, asset types, and high-signal string hits (URLs / hosts / keys).
"""
import sys, os, zipfile, re, collections, hashlib, json

PACKERS = [
    ("360 jiagu",        [r"libjiagu", r"libjiagu_art", r"libjiagu_x86", r"libprotectClass"]),
    ("Tencent Legu",     [r"libshella", r"libshellx", r"libtxgame", r"tosprotection"]),
    ("Tencent Yushan",   [r"libyusanso", r"libyushan"]),
    ("Bangcle",          [r"libDexHelper", r"libsecexe", r"libsecmain", r"libSecShell"]),
    ("Ijiami",           [r"libexec\.so", r"libexecmain", r"libijiami", r"libmobisec"]),
    ("Nagain/Chaos",     [r"libchaosvmp", r"libddog", r"libedog"]),
    ("Alibaba",          [r"libmobisec", r"libsgmain", r"libsgsecuritybody"]),
    ("NetEase Yidun",    [r"libnesec", r"libnqshield"]),
    ("KiwiSec",          [r"libkiwi"]),
    ("Unicorn/unknown",  [r"libapktoolplus"]),
]

ENGINES = [
    ("Cocos2d-x (C++)",  [r"libcocos2dcpp\.so", r"libcocos2d\.so", r"cocos2d"]),
    ("Cocos2d-x (Lua)",  [r"libcocos2dlua\.so", r"libluajit\.so"]),
    ("Cocos Creator JS", [r"libcocos2djs\.so", r"assets/.*project\.json", r"src/settings\.json"]),
    ("Unity (il2cpp)",   [r"libil2cpp\.so", r"libunity\.so"]),
    ("Unity (mono)",     [r"libmonobdwgc", r"libmono\.so"]),
    ("Egret/LayaBox",    [r"libegret", r"layabox"]),
    ("libGDX",           [r"libgdx\.so"]),
    ("Flutter",          [r"libflutter\.so"]),
    ("Weex/RN",          [r"libreactnativejni", r"libweexjsc"]),
]

NETLIBS = ["libcurl", "libssl", "libcrypto", "libcrypto_mt", "libmbedtls", "libwebsockets",
           "libevent", "libuv", "libnet", "libprotobuf", "libflatbuffers", "libpomelo",
           "libkcp", "libenet", "libsqlite", "liblua", "libluajit", "libquickjs", "libv8"]

DEX_HTTP = [
    ("okhttp",      [r"okhttp3?/", r"com/squareup/okhttp"]),
    ("Volley",      [r"com/android/volley"]),
    ("Retrofit",    [r"retrofit2?/"]),
    ("Netty",       [r"io/netty/"]),
    ("Apache HTTP", [r"org/apache/http"]),
    ("ksoap",       [r"org/ksoap2"]),
    ("Mina",        [r"org/apache/mina"]),
    ("protobuf-java",[r"com/google/protobuf"]),
    ("gson/fastjson",[r"com/google/gson", r"com/alibaba/fastjson"]),
    ("EventBus",    [r"org/greenrobot/eventbus"]),
    ("xUtils",      [r"org/xutils"]),
    ("Baidu SDK",   [r"com/baidu/"]),
    ("Tencent SDK", [r"com/tencent/"]),
    ("360 SDK",     [r"com/qihoo/"]),
    ("UC SDK",      [r"cn/uc/"]),
    ("Xiaomi SDK",  [r"com/xiaomi/"]),
    ("WeChat SDK",  [r"com/tencent/mm/opensdk"]),
    ("Alipay SDK",  [r"com/alipay/"]),
]

STR_PATTERNS = {
    "urls":     re.compile(rb"https?://[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]{4,200}"),
    "hosts":    re.compile(rb"\b(?:[a-z0-9][a-z0-9-]{1,60}\.)+(?:com|cn|net|org|io|tv|cc|xyz|top|info|biz|me|vip|game|mobi|asia)\b"),
    "ips":      re.compile(rb"\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b"),
    "keys":     re.compile(rb"(?i)\b(?:app[_\-]?key|app[_\-]?secret|secret[_\-]?key|api[_\-]?key|access[_\-]?key|sign[_\-]?key|md5[_\-]?key|aes[_\-]?key|des[_\-]?key|hmac)\b\s*[:=]\s*[\"']?([A-Za-z0-9+/=_\-]{8,80})"),
    "authpath": re.compile(rb"(?i)[\"']/(?:login|auth|user|role|player|account|server|gate|gateway|api|game|zone|notice|patch|update|version|verify)[A-Za-z0-9_/]{0,60}[\"']"),
}

def humansize(n):
    for u in ("B", "KB", "MB", "GB"):
        if n < 1024: return f"{n:.1f}{u}"
        n /= 1024
    return f"{n:.1f}TB"

def main(apk):
    print(f"### APK: {apk}")
    size = os.path.getsize(apk)
    print(f"### size: {size} bytes ({humansize(size)})")
    with open(apk, "rb") as f:
        print(f"### md5:    {hashlib.md5(f.read()).hexdigest()}")
    with open(apk, "rb") as f:
        f.seek(0); print(f"### sha256: {hashlib.sha256(f.read()).hexdigest()}")

    z = zipfile.ZipFile(apk)
    infos = z.infolist()
    print(f"\n### entries: {len(infos)}")

    # ---- top-level structure ----
    print("\n## top-level structure")
    top = collections.Counter()
    for i in infos:
        parts = i.filename.split("/")
        top[parts[0] if len(parts) > 1 else "(file) "+i.filename] += i.file_size
    for k, v in top.most_common(40):
        print(f"   {k:<40} {humansize(v)}")

    names = [i.filename for i in infos]
    allnames = "\n".join(names).lower()

    # ---- dex ----
    dexes = [i for i in infos if re.match(r"^classes\d*\.dex$", i.filename)]
    print(f"\n## dex files: {len(dexes)}")
    for d in sorted(dexes, key=lambda x: x.filename):
        print(f"   {d.filename:<20} {humansize(d.file_size)}")

    # ---- native libs by ABI ----
    print("\n## native libraries")
    libs = collections.defaultdict(list)
    for i in infos:
        m = re.match(r"^lib/([^/]+)/(.+\.so)$", i.filename)
        if m:
            libs[m.group(1)].append((m.group(2), i.file_size))
    for abi in sorted(libs):
        tot = sum(s for _, s in libs[abi])
        print(f"   [{abi}] {len(libs[abi])} libs, {humansize(tot)}")
        for n, s in sorted(libs[abi], key=lambda x: -x[1]):
            print(f"        {n:<40} {humansize(s)}")

    # ---- packer fingerprint ----
    print("\n## packer / protector fingerprint")
    hits = []
    for label, pats in PACKERS:
        for p in pats:
            if re.search(p.lower(), allnames):
                hits.append((label, p)); break
    if hits:
        for l, p in hits: print(f"   !! {l}  (matched {p})")
    else:
        print("   (none detected by name)")

    # ---- engine fingerprint ----
    print("\n## engine fingerprint")
    eng = []
    for label, pats in ENGINES:
        for p in pats:
            if re.search(p.lower(), allnames):
                eng.append((label, p)); break
    if eng:
        for l, p in eng: print(f"   -> {l}  (matched {p})")
    else:
        print("   (no known engine signature found)")

    # ---- key native libs of interest ----
    print("\n## network / scripting libs present")
    for n in NETLIBS:
        m = [x for x in names if re.search(rf"/{n}[^/]*\.so$", x, re.I)]
        if m: print(f"   {n:<16} {', '.join(os.path.basename(x) for x in m)}")

    # ---- dex content hints (scan raw dex for class paths) ----
    print("\n## dex library hints")
    dexblob = b""
    for d in dexes:
        try: dexblob += z.read(d.filename)
        except Exception: pass
    if dexblob:
        for label, pats in DEX_HTTP:
            for p in pats:
                if p.encode() in dexblob:
                    print(f"   {label}"); break

    # ---- string mining ----
    print("\n## string mining (assets + dex + so)")
    targets = [i for i in infos if i.file_size < 60*1024*1024 and (
        i.filename.endswith((".dex", ".so", ".json", ".xml", ".txt", ".lua", ".luac",
                             ".cfg", ".ini", ".properties", ".dat", ".bin", ".plist"))
        or i.filename.startswith("assets/"))]
    print(f"   scanning {len(targets)} entries...")
    found = {k: collections.Counter() for k in STR_PATTERNS}
    for i in targets:
        try: blob = z.read(i.filename)
        except Exception: continue
        for k, rx in STR_PATTERNS.items():
            for m in rx.findall(blob):
                if k == "keys":
                    g = m if isinstance(m, bytes) else (m[1] if isinstance(m, tuple) else m)
                    found[k][(g[:80], os.path.basename(i.filename))] += 1
                else:
                    v = m if isinstance(m, bytes) else m[0]
                    found[k][v.decode("utf-8", "replace")[:200]] += 1

    for k in ("urls", "hosts", "ips", "authpath"):
        c = found[k]
        print(f"\n   --- {k}: {len(c)} unique ---")
        for v, n in c.most_common(70):
            print(f"      {v}")

    print(f"\n   --- possible keys: {len(found['keys'])} ---")
    for (v, src), n in found["keys"].most_common(40):
        print(f"      {v}   [{src}]")

if __name__ == "__main__":
    main(sys.argv[1])
