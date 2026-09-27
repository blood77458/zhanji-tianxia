#!/usr/bin/env python3
"""Disassemble headercvt (the outer framing the client applies to /protocol)."""
import struct, bisect
from elftools.elf.elffile import ELFFile
from capstone import *
from capstone.arm import *

P = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
D = open(P, "rb").read()
E = ELFFile(open(P, "rb"))
segs = [(s["p_vaddr"], s["p_vaddr"] + s["p_memsz"], s["p_offset"], s["p_filesz"])
        for s in E.iter_segments() if s["p_type"] == "PT_LOAD"]
segs.sort()


def v2o(v):
    for lo, hi, off, fsz in segs:
        if lo <= v < lo + fsz:
            return off + (v - lo)
    return None


SYMS = []
for s in E.get_section_by_name(".dynsym").iter_symbols():
    if s.name and s["st_value"]:
        SYMS.append((s["st_value"] & ~1, s["st_value"] & 1, s["st_size"], s.name))
SYMS.sort()
AD = [a for a, _, _, _ in SYMS]


def nm(a):
    i = bisect.bisect_right(AD, a) - 1
    if i >= 0 and a - AD[i] < 0x400:
        return SYMS[i][3]
    return None


def cstr(va, n=90):
    o = v2o(va)
    if o is None:
        return None
    b = D[o:o + n]
    z = b.find(b"\x00")
    return b[:z if z >= 0 else n].decode("latin-1", "replace")


def dis(va, n, title):
    th = bool(va & 1)
    a = va & ~1
    o = v2o(a)
    md = Cs(CS_ARCH_ARM, CS_MODE_THUMB if th else CS_MODE_ARM)
    md.detail = True
    print("=" * 88)
    print("%s @0x%08x %s" % (title, a, "THUMB" if th else "ARM"))
    print("=" * 88)
    for ins in md.disasm(D[o:o + n * 4], a):
        ann = ""
        if ins.id in (ARM_INS_BL, ARM_INS_BLX, ARM_INS_B):
            for op in ins.operands:
                if op.type == ARM_OP_IMM:
                    t = op.imm & ~1
                    s = nm(t)
                    ann = "  -> 0x%x" % t + (" %s" % s if s else "")
        elif ins.id == ARM_INS_LDR:
            ops = ins.operands
            if len(ops) >= 2 and ops[1].type == ARM_OP_MEM and ops[1].mem.base == ARM_REG_PC:
                pc = (ins.address + 4) & ~3 if th else ins.address + 8
                lit = pc + ops[1].mem.disp
                lo = v2o(lit)
                if lo is not None and lo + 4 <= len(D):
                    val = struct.unpack_from("<I", D, lo)[0]
                    ann = "  ; [0x%x]=0x%08x" % (lit, val)
                    s = cstr(val)
                    if s and len(s) > 1 and all(32 <= ord(c) < 127 for c in s):
                        ann += '  "%s"' % s[:60]
                    else:
                        q = nm(val)
                        if q:
                            ann += "  %s" % q
        print("  0x%08x  %-9s %s%s" % (ins.address, ins.mnemonic, ins.op_str, ann))


if __name__ == "__main__":
    import sys
    dis(0x0030ecd1, 30, "luaopen_headercvt")
    print()
    # the registered convertD/convertU closures start right after luaopen
    dis(0x0030eceb, 120, "headercvt closure (convertD/convertU)")
    print()
    print("=== string/data literals referenced ===")
    for va in (0x005bd218, 0x005bd210, 0x005bd220, 0x005bd200):
        print("  0x%08x = %r" % (va, cstr(va, 80)))
    # resolve the pc-relative globals used by the closure
    for lit, pcv, lbl in ((0x30ed80, 0x30ed38, "r4 global"),
                          (0x30ed84, 0x30ed3e, "r6 fmt")):
        val = struct.unpack_from("<I", D, v2o(lit))[0]
        addr = val + pcv
        print("  %s: lit=0x%08x -> 0x%08x  str=%r" % (lbl, val, addr, cstr(addr, 60)))
