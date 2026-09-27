#!/usr/bin/env python3
"""Extract strings from libhegame.so and hunt for the Lua-asset AES key and protocol clues."""
import re, collections, sys, os

SO = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
data = open(SO, "rb").read()
print(f"libhegame.so size = {len(data)} bytes")

# ---------- generic printable-string extraction ----------
def strings_ascii(b, minlen=4):
    return re.findall(rb"[\x20-\x7e]{%d,}" % minlen, b)

asc = strings_ascii(data, 4)
print(f"ASCII strings (>=4): {len(asc)}")

uni = re.findall(rb"(?:[\x20-\x7e]\x00){4,}", data)
print(f"UTF-16LE strings (>=4): {len(uni)}")

blob = b"\n".join(asc)
text = blob.decode("latin-1")

# ---------- 1. crypto-related identifiers ----------
print("\n" + "="*78)
print("1) CRYPTO / CIPHER IDENTIFIERS")
print("="*78)
crypto_pat = re.compile(r"(?i)\b(aes|des|rc4|rc2|blowfish|xxtea|tea|chacha|salsa|"
                        r"evp_|cipher|encrypt|decrypt|pkcs7|padding|cbc|ecb|ctr|gcm|"
                        r"md5|sha1|sha256|hmac|crc32|base64|xxtea_)\w*")
c = collections.Counter(m.group(0) for m in crypto_pat.finditer(text))
for k, v in c.most_common(60):
    print(f"   {k:<40} {v}")

# ---------- 2. lua-asset loading ----------
print("\n" + "="*78)
print("2) LUA ASSET LOADING")
print("="*78)
lua_pat = re.compile(r"(?i)[\w./\\-]*(lua|luac|loadstring|luaL_|lua_|bytecode|\.lua)[\w./\\-]*")
c = collections.Counter(m.group(0) for m in lua_pat.finditer(text))
for k, v in c.most_common(50):
    print(f"   {k:<60} {v}")

# ---------- 3. candidate keys near crypto words ----------
print("\n" + "="*78)
print("3) PRINTABLE STRINGS OF EXACTLY 16 / 24 / 32 BYTES  (AES key candidates)")
print("="*78)
seen = set()
cands = []
for s in asc:
    if len(s) in (16, 24, 32):
        # must look key-ish: mixed, no long spaces, high variety
        if b" " in s.strip() and s.count(b" ") > 2:
            continue
        if s in seen:
            continue
        seen.add(s)
        cands.append(s)
print(f"   {len(cands)} length-16/24/32 ASCII strings")
for s in cands[:120]:
    print(f"   [{len(s):>2}] {s.decode('latin-1')}")

# ---------- 4. strings mentioning key/iv/secret ----------
print("\n" + "="*78)
print("4) LINES MENTIONING key / iv / secret / salt")
print("="*78)
kw = re.compile(r"(?i)^.*(key|secret|salt|\biv\b|password|passwd|token).*$")
sel = [l for l in text.split("\n") if kw.match(l) and 3 < len(l) < 90]
seen = set()
n = 0
for l in sel:
    if l in seen: continue
    seen.add(l)
    n += 1
    if n > 90: break
    print(f"   {l}")

# ---------- 5. URLs / hosts / paths in the engine ----------
print("\n" + "="*78)
print("5) URLS / HOSTS IN ENGINE")
print("="*78)
for pat, label in ((rb"https?://[\x20-\x7e]{4,140}", "url"),
                   (rb"(?:[a-z0-9][a-z0-9-]{1,40}\.)+(?:com|cn|net|org|io)\b", "host")):
    found = collections.Counter(m.group(0).decode("latin-1") for m in re.finditer(pat, data))
    print(f"   --- {label} ({len(found)}) ---")
    for k, v in found.most_common(40):
        print(f"      {k}")

# ---------- 6. protocol-ish identifiers ----------
print("\n" + "="*78)
print("6) PROTOCOL / RPC IDENTIFIERS")
print("="*78)
proto = re.compile(r"(?i)\b(socket|packet|protocol|protobuf|msgpack|serialize|deserialize|"
                   r"handshake|heartbeat|reconnect|gateway|zone|session|uid|sid|"
                   r"http|https|tcp|udp|kcp|websocket|json|xml)\w*")
c = collections.Counter(m.group(0) for m in proto.finditer(text))
for k, v in c.most_common(50):
    print(f"   {k:<40} {v}")

# ---------- 7. interesting format strings ----------
print("\n" + "="*78)
print("7) FORMAT / ERROR STRINGS (sample)")
print("="*78)
for l in text.split("\n"):
    if re.search(r"(?i)(error|fail|invalid|mismatch|corrupt|cannot|unable)", l) and 8 < len(l) < 110:
        print(f"   {l}")
