#!/usr/bin/env python3
"""Disassemble ResConfig::parseStaticSettingsJson/Xml and ResManager getters to learn
the exact static-settings schema the client expects."""
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
    if s.name and s["st_value"]:
        SYMS.append((s["st_value"] & ~1, s["st_value"] & 1, s["st_size"], s["st_name"]))
SYMS.sort()
ADDRS = [a for a, _, _, _ in SYMS]


def name_at(a):
    i = bisect.bisect_right(ADDRS, a) - 1
    if i >= 0 and a - ADDRS[i] < 0x800:
        return SYMS[i][3]
    return None


def cstr(va):
    o = v2o(va)
    if o is None:
        return None
    end = D.find(b"\x00", o, o + 200)
    if end < 0:
        return None
    return D[o:end].decode("latin-1", "replace")


def disasm(vaddr, n, title):
    thumb = bool(vaddr & 1)
    va = vaddr & ~1
    o = v2o(va)
    if o is None:
        print("cannot map", hex(va)); return
    md = Cs(CS_ARCH_ARM, CS_MODE_THUMB if thumb else CS_MODE_ARM)
    md.detail = True
    print("=" * 96)
    mode = "THUMB" if thumb else "ARM"
    print(f"{title}   @0x{va:08x}  ({mode})")
    print("=" * 96)
    for ins in md.disasm(D[o:o + n * 4], va):
        ann = ""
        if ins.id in (ARM_INS_BL, ARM_INS_BLX, ARM_INS_B):
            for op in ins.operands:
                if op.type == ARM_OP_IMM:
                    t = op.imm & ~1
                    s = name_at(t)
                    ann = f"  -> 0x{t:x}" + (f" {s}" if s else "")
        elif ins.id == ARM_INS_LDR:
            ops = ins.operands
            if len(ops) >= 2 and ops[1].type == ARM_OP_MEM and ops[1].mem.base == ARM_REG_PC:
                pc = (ins.address + 4) & ~3 if thumb else ins.address + 8
                lit = pc + ops[1].mem.disp
                lo = v2o(lit)
                if lo is not None and lo + 4 <= len(D):
                    val = struct.unpack_from("<I", D, lo)[0]
                    ann = f"  ; [0x{lit:x}]=0x{val:08x}"
                    # if it looks like a pc-relative string pointer target
                    s = cstr(val + 0)
                    if s and all(32 <= ord(c) < 127 for c in s) and len(s) > 1:
                        ann += f'  "{s}"'
                    else:
                        nm = name_at(val)
                        if nm:
                            ann += f"  {nm}"
        print(f"  0x{ins.address:08x}  {ins.mnemonic:<9} {ins.op_str}{ann}")


disasm(0x00314169, 100, "ResConfig::parseStaticSettingsJson")
print()
disasm(0x003144e1, 130, "ResConfig::parseStaticSettingsXml")
print()
# the ResManager getters that name the fields
for a in (0x00316f81, 0x00316fa1, 0x00316f21, 0x00316f71, 0x00316f91, 0x00316fb1, 0x00316f61):
    disasm(a, 12, name_at(a) or hex(a))
