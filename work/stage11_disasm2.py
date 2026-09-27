#!/usr/bin/env python3
"""Disassemble the functions that reference the global object 0x6BB004."""
import struct, bisect, re
from elftools.elf.elffile import ELFFile
from capstone import *
from capstone.arm import *

P = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
D = open(P, "rb").read()
E = ELFFile(open(P, "rb"))

SEGS = []
for s in E.iter_segments():
    if s["p_type"] == "PT_LOAD":
        SEGS.append((s["p_vaddr"], s["p_vaddr"] + s["p_memsz"], s["p_offset"], s["p_filesz"]))
SEGS.sort()

def v2o(v):
    for lo, hi, off, fsz in SEGS:
        if lo <= v < lo + fsz:
            return off + (v - lo)
    return None

SYMS = []
for s in E.get_section_by_name(".dynsym").iter_symbols():
    if s.name and s["st_info"]["type"] == "STT_FUNC" and s["st_value"]:
        SYMS.append((s["st_value"] & ~1, s["st_value"] & 1, s["st_size"], s.name))
SYMS.sort()
ADDRS = [a for a, _, _, _ in SYMS]

def containing(a):
    i = bisect.bisect_right(ADDRS, a) - 1
    if i < 0: return None
    base, thumb, size, name = SYMS[i]
    exact = bool(size) and a < base + size
    return name if exact else name + " (approx)", base, size, thumb

def dem(n):
    m = re.match(r"^_ZN(.+?)E$", n)
    if not m: return n
    b, parts, i = m.group(1), [], 0
    while i < len(b):
        m2 = re.match(r"(\d+)", b[i:])
        if not m2: break
        ln = int(m2.group(1)); i += len(m2.group(1))
        parts.append(b[i:i+ln]); i += ln
    return "::".join(parts) if parts else n

def sym_at(a):
    i = bisect.bisect_right(ADDRS, a) - 1
    if i >= 0 and a - ADDRS[i] < 0x600:
        return SYMS[i][3]
    return None

def disasm(va, n=90, title=""):
    thumb = bool(va & 1)
    va &= ~1
    o = v2o(va)
    if o is None:
        print(f"  cannot map 0x{va:x}"); return
    md = Cs(CS_ARCH_ARM, CS_MODE_THUMB if thumb else CS_MODE_ARM)
    md.detail = True
    print("=" * 92)
    print(f"{title}  @0x{va:08x} {'THUMB' if thumb else 'ARM'}")
    print("=" * 92)
    for ins in md.disasm(D[o:o + n * 4], va):
        ann = ""
        if ins.id in (ARM_INS_BL, ARM_INS_BLX, ARM_INS_B):
            for op in ins.operands:
                if op.type == ARM_OP_IMM:
                    t = op.imm & ~1
                    s = sym_at(t)
                    ann = f"   -> 0x{t:x}" + (f"  {dem(s)}" if s else "")
        elif ins.id in (ARM_INS_LDR, ARM_INS_LDRB, ARM_INS_LDRH, ARM_INS_STR, ARM_INS_STRB, ARM_INS_STRH):
            ops = ins.operands
            if len(ops) >= 2 and ops[-1].type == ARM_OP_MEM and ops[-1].mem.base == ARM_REG_PC:
                pc = (ins.address + 4) & ~3
                lit = pc + ops[-1].mem.disp
                oo = v2o(lit)
                if oo is not None and oo + 4 <= len(D):
                    val = struct.unpack_from("<I", D, oo)[0]
                    ann = f"   ; [0x{lit:x}] = 0x{val:08x}"
                    raw = D[oo:oo + 16]
                    if all(32 <= c < 127 for c in raw[:4]):
                        ann += f" = {raw[:4]!r}"
                    s = sym_at(val)
                    if s: ann += f"  ({dem(s)})"
        elif ins.id == ARM_INS_ADD and len(ins.operands) == 2 and ins.operands[1].type == ARM_OP_REG \
                and ins.operands[1].reg == ARM_REG_PC:
            ann = "   ; <pc-relative address build>"
        print(f"  0x{ins.address:08x}  {ins.mnemonic:<9} {ins.op_str}{ann}")

for ref, lbl in ((0x002ef0d4, "HeLuaLoader::init  (ref base+0)"),
                 (0x002ff644, "ref base+0x38 (a)"),
                 (0x00301c24, "ref base+0x38 (b)"),
                 (0x00303894, "ref base+0x74")):
    c = containing(ref)
    if c:
        name, base, size, thumb = c
        print(f"\n##### ref 0x{ref:08x}  in  {dem(name)}   (base 0x{base:x} size {size} thumb={thumb})")
        disasm(base | thumb, 70, dem(name))
    else:
        print(f"\n##### ref 0x{ref:08x}  (no preceding symbol)")
