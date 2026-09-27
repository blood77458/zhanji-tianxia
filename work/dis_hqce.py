#!/usr/bin/env python3
from capstone import Cs, CS_ARCH_ARM, CS_MODE_THUMB
import struct

SO = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
data = open(SO, "rb").read()

# decrypt @ 0x2e8689 (thumb), decryptBlock @ 0x2e86e1
funcs = [
    ("decrypt", 0x2e8688),  # even for thumb base
    ("decryptBlock", 0x2e86e0),
]

md = Cs(CS_ARCH_ARM, CS_MODE_THUMB)
md.detail = True

for name, off in funcs:
    print("=" * 60, name)
    code = data[off:off + 0x120]
    for insn in md.disasm(code, off | 1):
        print(f"  0x{insn.address:x}:\t{insn.mnemonic}\t{insn.op_str}")
        if insn.mnemonic in ("bx", "pop") and "pc" in insn.op_str:
            # might be end; keep going a bit
            pass
        if insn.address > off + 0x100:
            break

# Also search for plaintext key constants near these funcs
region = data[0x2e8000:0x2e9000]
# look for 16-byte aligned high-entropy? or ASCII keys
for s in [b"happyelements", b"HappyElements", b"canon", b"HQCE", b"hegame"]:
    i = data.find(s)
    print("str", s, hex(i) if i>=0 else None)

# Dump literals pools around decrypt
print("pool", data[0x2e8710:0x2e8780].hex())
