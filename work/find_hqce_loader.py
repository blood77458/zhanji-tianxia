#!/usr/bin/env python3
"""Find callers of decryptBlock and HQCE loader; hunt for TEA key."""
from capstone import Cs, CS_ARCH_ARM, CS_MODE_THUMB
import struct

SO = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
data = open(SO, "rb").read()

# Find bl to 0x2e86e1 (decryptBlock) - Thumb BL encoding is messy.
# Search for immediate that encodes branch to 0x2e86e1
target = 0x2e86e0  # even

# Also search string "HQCE" refs - ARM PC-relative LDR of the string address
hqce_va = None
# Need VA of HQCE string. File offset of HQCE:
hqce_off = data.find(b"HQCE\x00")
print("hqce file off", hex(hqce_off))

# ELF loads
e_phoff = struct.unpack_from("<I", data, 28)[0]
e_phentsize = struct.unpack_from("<H", data, 42)[0]
e_phnum = struct.unpack_from("<H", data, 44)[0]
loads = []
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, p_offset, p_vaddr, _, p_filesz, _, _, _ = struct.unpack_from("<IIIIIIII", data, off)
    if p_type == 1:
        loads.append((p_offset, p_vaddr, p_filesz))

def off_to_va(o):
    for po, pv, pf in loads:
        if po <= o < po + pf:
            return pv + (o - po)
    return None

def va_to_off(va):
    for po, pv, pf in loads:
        if pv <= va < pv + pf:
            return po + (va - pv)
    return None

hqce_va = off_to_va(hqce_off)
print("hqce va", hex(hqce_va))

# Scan thumb code for LDR that materializes hqce_va
# Common: ldr rX, [pc, #imm]; then that literal pool contains hqce_va
md = Cs(CS_ARCH_ARM, CS_MODE_THUMB)
refs = []
# scan executable load
for po, pv, pf in loads:
    # only text-ish: first load usually
    if pf < 0x10000:
        continue
    chunk = data[po:po+pf]
    # find literal = hqce_va
    needle = struct.pack("<I", hqce_va)
    start = 0
    while True:
        i = chunk.find(needle, start)
        if i < 0:
            break
        va = pv + i
        refs.append((va, po + i))
        start = i + 4

print("literal pool refs to HQCE:", len(refs))
for va, fo in refs[:20]:
    print(" ", hex(va), "file", hex(fo))
    # disasm 0x40 bytes before this literal (function using it)
    # find nearby code - look back for function prolog
    code_off = fo - 0x80
    if code_off < 0:
        code_off = fo - 0x40
    print("--- context ---")
    for insn in md.disasm(data[code_off:fo], (off_to_va(code_off) or 0) | 1):
        print(f"  0x{insn.address:x}: {insn.mnemonic} {insn.op_str}")

# Search for decryptBlock bl: encoding of BL to 0x2e86e1 from various sites
# Brute: for each 4-byte aligned thumb BL in range
decrypt_block = 0x2e86e0
callers = []
text_po, text_pv, text_pf = loads[0]
# Prefer the RX segment with decrypt itself
for po, pv, pf in loads:
    if not (pv <= decrypt_block < pv + pf):
        continue
    text_po, text_pv, text_pf = po, pv, pf
    break

code = data[text_po:text_po + text_pf]
# Scan for BL (32-bit thumb): 0xF000xxxx 0xF800xxxx pattern
i = 0
while i < len(code) - 4:
    w0 = struct.unpack_from("<H", code, i)[0]
    w1 = struct.unpack_from("<H", code, i + 2)[0]
    if (w0 & 0xF800) == 0xF000 and (w1 & 0xD000) == 0xD000:
        # BL
        s = (w0 >> 10) & 1
        imm10 = w0 & 0x3FF
        j1 = (w1 >> 13) & 1
        j2 = (w1 >> 11) & 1
        imm11 = w1 & 0x7FF
        I1 = 1 - (j1 ^ s)
        I2 = 1 - (j2 ^ s)
        imm = (s << 24) | (I1 << 23) | (I2 << 22) | (imm10 << 12) | (imm11 << 1)
        if s:
            imm |= ~((1 << 25) - 1)  # sign extend from bit 24
            imm = imm & 0xFFFFFFFF
            if imm & 0x80000000:
                imm = imm - 0x100000000
        pc = text_pv + i + 4
        dest = (pc + imm) & 0xFFFFFFFF
        if dest == decrypt_block or dest == (decrypt_block | 1) or dest == decrypt_block + 1:
            callers.append(text_pv + i)
        # also decrypt itself
        if dest == 0x2e8688 or dest == 0x2e8689:
            pass
    i += 2

print("callers of decryptBlock:", [hex(c) for c in callers[:30]], "count", len(callers))
for c in callers[:10]:
    fo = va_to_off(c)
    print("caller", hex(c))
    for insn in md.disasm(data[fo - 0x40:fo + 0x20], (c - 0x40) | 1):
        mark = " <<<" if insn.address == c else ""
        print(f"  0x{insn.address:x}: {insn.mnemonic} {insn.op_str}{mark}")
