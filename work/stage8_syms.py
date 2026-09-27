#!/usr/bin/env python3
"""Enumerate interesting dynamic symbols in libhegame.so."""
import re
from elftools.elf.elffile import ELFFile

P = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
f = open(P, "rb")
e = ELFFile(f)
dyn = e.get_section_by_name(".dynsym")

syms = []
for s in dyn.iter_symbols():
    if s.name:
        syms.append((s.name, s["st_value"], s["st_size"], s["st_info"]["type"]))
print(f"named dynsyms: {len(syms)}")

GROUPS = {
    "AES / crypto": r"(?i)aes|encrypt|decrypt|cipher|crypto|xxtea|\brc4\b|blowfish|secret",
    "lua load / file": r"(?i)load.*lua|lua.*load|readfile|getfiledata|loadasset|asset.*load|decrypt.*file|file.*decrypt",
    "lua vm": r"(?i)^lua|luaL_|lua_|tolua_",
    "socket/net": r"(?i)socket|GameSocket|packet|connect|send|recv|http",
}

for label, pat in GROUPS.items():
    rx = re.compile(pat)
    hits = [s for s in syms if rx.search(s[0])]
    print("\n" + "=" * 78)
    print(f"{label}   ({len(hits)} hits)")
    print("=" * 78)
    for name, addr, size, typ in sorted(hits, key=lambda x: x[1]):
        if "tolua" in name and label == "lua vm":
            continue
        print(f"   0x{addr:08x}  size={size:<7} {typ:<6} {name[:110]}")
    if label == "lua vm":
        n = sum(1 for s in hits if "tolua" in s[0])
        print(f"   ... plus {n} tolua_* bindings (suppressed)")
