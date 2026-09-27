#!/usr/bin/env python3
"""
Find the AES key for the encrypted Lua assets.

Oracle: LocalUserDataModel.lua is 32 bytes = IV(16) || AES-CBC(PKCS#7(empty))
        A correct key yields exactly 16 bytes of 0x10 padding.
Also cross-checks against a second empty file (BattleEffect.lua).
"""
import os, hashlib, itertools, re
from Crypto.Cipher import AES

BASE = r"E:\deepseek_projects\app_server\work\extract\assets\src"
ORACLES = [
    os.path.join(BASE, r"canon\models\LocalUserDataModel.8142fa8be5a96cba9c1482dde82dcb4b.lua"),
    os.path.join(BASE, r"canon\scene\BattleEffect.f42c5620ce4b7fa7f2ca91906d77e2c5.lua"),
]

def load_empty(p):
    b = open(p, "rb").read()
    assert len(b) == 32, (p, len(b))
    return b[:16], b[16:]

PAIRS = [load_empty(p) for p in ORACLES]

def try_key(key):
    """Return True if key decrypts ALL oracles to pure PKCS#7 padding."""
    if len(key) not in (16, 24, 32):
        return None
    outs = []
    for iv, ct in PAIRS:
        try:
            pt = AES.new(key, AES.MODE_CBC, iv).decrypt(ct)
        except Exception:
            return None
        outs.append(pt)
    # all must be valid padding
    for pt in outs:
        pad = pt[-1]
        if pad < 1 or pad > 16:
            return None
        if pt[-pad:] != bytes([pad]) * pad:
            return None
    return outs

# ---------------- candidate key material ----------------
SEEDS = [
    # from StartupConfig.plist / package / channel
    "canon_androidlongyuan_prod", "canon_androidlongyuan", "canon_longyuan_prod",
    "canon_android_prod", "canon_android", "canon_prod", "canon",
    "canon_androidlongyuan_dev", "canon_androidlongyuan_test",
    "androidlongyuan_prod", "longyuan_prod", "longyuan",
    "canon_ioslongyuan_prod", "canon_ios_prod",
    "canon_androidbaidu_prod", "canon_androidbaidudk_prod",
    # company / project
    "happyelements", "HappyElements", "happyelementscanon", "canonhappyelements",
    "hegame", "HeCore", "hecore", "libhegame",
    # engine-ish
    "cocos2d-x", "cocos2dx",
    # channel ids seen in the apk
    "baiduDK", "baidu", "oem_5500058", "5500058",
    # versions
    "11.0.61", "11.0", "11061",
    # very common lazy keys
    "1234567890123456", "0123456789abcdef", "abcdefghijklmnop",
    "0000000000000000", "aaaaaaaaaaaaaaaa", "1234567890abcdef",
    "happyelements2014", "happyelements2015", "happyelements2016",
]
# add content-addressed names / uuids
SEEDS += ["87D769CAC03C4AA0BEE84AB43E75E069", "87d769cac03c4aa0bee84ab43e75e069",
          "0424dbd8527d1fa0d43e3ed6ba67413b"]
# add doubled / repeated forms
extra = []
for s in list(SEEDS):
    extra += [s.upper(), s.lower(), s[::-1], s + s]
SEEDS += extra

def derive(seed):
    """All plausible key derivations of a seed string."""
    sb = seed.encode("utf-8", "ignore")
    out = []
    # raw, padded/truncated to 16/24/32
    for n in (16, 24, 32):
        if len(sb) >= n:
            out.append((f"raw[{n}]", sb[:n]))
        out.append((f"pad0[{n}]", sb.ljust(n, b"\x00")))
        out.append((f"padsp[{n}]", sb.ljust(n, b" ")))
    # hashes
    m = hashlib.md5(sb).digest()
    out.append(("md5", m))
    out.append(("md5hex[:16]", hashlib.md5(sb).hexdigest()[:16].encode()))
    out.append(("md5hex[:32]", hashlib.md5(sb).hexdigest()[:32].encode()))
    out.append(("md5+md5", m + m))
    s1 = hashlib.sha1(sb).digest()
    out.append(("sha1[:16]", s1[:16]))
    s256 = hashlib.sha256(sb).digest()
    out.append(("sha256", s256))
    out.append(("sha256[:16]", s256[:16]))
    out.append(("sha256hex[:32]", hashlib.sha256(sb).hexdigest()[:32].encode()))
    out.append(("sha512[:32]", hashlib.sha512(sb).digest()[:32]))
    return out

print(f"oracles: {len(PAIRS)} (each 32 bytes = IV16 + one AES block)")
print(f"seeds: {len(SEEDS)}")

hits = []
tested = 0
for seed in SEEDS:
    for label, key in derive(seed):
        tested += 1
        r = try_key(key)
        if r:
            hits.append((seed, label, key, r))
            print("\n*** HIT ***")
            print(f"  seed={seed!r}  derivation={label}")
            print(f"  key={key!r}  (hex {key.hex()})")
            for pt in r:
                print(f"  plaintext={pt.hex()}  (={pt!r})")

print(f"\ntested {tested} key candidates, hits={len(hits)}")

# ---------------- if no hit: hunt for key material inside the binary ----------------
if not hits:
    print("\n" + "="*78)
    print("NO HIT from seeds. Scanning binaries for suspicious key-like constants.")
    print("="*78)
    binpath = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
    data = open(binpath, "rb").read()
    # high-entropy 16/32-byte blobs are everywhere; instead look for ASCII
    # strings of length 16/24/32 that mix cases/digits (typical passphrases)
    pat = re.compile(rb"[A-Za-z0-9_\-@#!\.]{16,32}")
    cands = set()
    for m in pat.finditer(data):
        s = m.group(0)
        if len(s) in (16, 24, 32):
            # require at least one digit and one letter, no long runs
            if re.search(rb"[0-9]", s) and re.search(rb"[A-Za-z]", s):
                cands.add(s)
            # or very key-ish words
            if re.search(rb"(?i)(key|secret|pass|canon|happy|aes)", s):
                cands.add(s)
    print(f"  {len(cands)} raw candidates from libhegame.so; testing...")
    n = 0
    for s in cands:
        n += 1
        for label, key in derive(s.decode("latin-1")):
            r = try_key(key)
            if r:
                print("\n*** HIT (from binary string) ***")
                print(f"  string={s!r} derivation={label} key={key.hex()}")
                hits.append((s, label, key, r))
    print(f"  tested {n} strings")
    print(f"  total hits: {len(hits)}")
