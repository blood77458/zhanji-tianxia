#!/usr/bin/env python3
"""
Targeted ARM/Thumb disassembler for libhegame.so.
- maps vaddr -> file offset via program headers
- disassembles a function
- annotates BL/BLX targets with the nearest dynamic symbol
- resolves PC-relative literal loads (LDR Rd,[pc,#imm]) and prints the raw
  constant words, which is where hardcoded AES keys / S-boxes live
"""
import sys, struct, bisect, re
from elftools.elf.elffile import ELFFile
from capstone import *
from capstone.arm import *

P = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
_f = open(P, "rb")
_e = ELFFile(_f)
_data = open(P, "rb").read()

# --- build vaddr -> file offset mapping from PT_LOAD segments ---
SEGS = []
for seg in _e.iter_segments():
    if seg["p_type"] == "PT_LOAD":
        SEGS.append((seg["p_vaddr"], seg["p_vaddr"] + seg["p_filesz"], seg["p_offset"]))
SEGS.sort()

def v2o(v):
    for lo, hi, off in SEGS:
        if lo <= v < hi:
            return off + (v - lo)
    return None

# --- symbol table ---
SYMS = []
for s in _e.get_section_by_name(".dynsym").iter_symbols():
    if s.name and s["st_info"]["type"] == "STT_FUNC" and s["st_value"]:
        SYMS.append((s["st_value"] & ~1, s.name))
SYMS.sort()
SYM_ADDRS = [a for a, _ in SYMS]

def sym_at(a):
    i = bisect.bisect_right(SYM_ADDRS, a) - 1
    if i >= 0 and a - SYM_ADDRS[i] < 0x400:
        return SYMS[i][1]
    return None

def demangle(n):
    """Very small Itanium demangler for the patterns we care about."""
    m = re.match(r"^_ZN(.+?)E$", n)
    if not m: return n
    body = m.group(1)
    parts, i = [], 0
    while i < len(body):
        m2 = re.match(r"(\d+)", body[i:])
        if not m2: break
        ln = int(m2.group(1)); i += len(m2.group(1))
        parts.append(body[i:i+ln]); i += ln
    if not parts: return n
    return "::".join(parts)

def disasm(vaddr, count=400, label=""):
    off = v2o(vaddr)
    if off is None:
        print(f"  !! cannot map vaddr 0x{vaddr:x}")
        return
    thumb = bool(vaddr & 1)
    va = vaddr & ~1
    off = v2o(va)
    md = Cs(CS_ARCH_ARM, CS_MODE_THUMB if thumb else CS_MODE_ARM)
    md.detail = True
    code = _data[off: off + count * 4]
    print("=" * 96)
    print(f"{label or ''}  vaddr=0x{va:08x}  fileoff=0x{off:x}  mode={'THUMB' if thumb else 'ARM'}")
    print("=" * 96)
    n = 0
    for ins in md.disasm(code, va):
        ann = ""
        # resolve branch targets
        if ins.id in (ARM_INS_BL, ARM_INS_BLX, ARM_INS_B, ARM_INS_BX, ARM_INS_CBZ, ARM_INS_CBNZ):
            for op in ins.operands:
                if op.type == ARM_OP_IMM:
                    t = op.imm & ~1
                    s = sym_at(t)
                    ann = f"   -> 0x{t:x}" + (f"  {demangle(s)}" if s else "")
        # resolve pc-relative literal loads
        if ins.id == ARM_INS_LDR:
            try:
                ops = ins.operands
                if len(ops) >= 2 and ops[1].type == ARM_OP_MEM:
                    mem = ops[1].mem
                    if mem.base == ARM_REG_PC:
                        pc = (ins.address + 4) & ~3 if thumb else ins.address + 8
                        lit = pc + mem.disp
                        lo = v2o(lit)
                        val = None
                        if lo is not None and lo + 4 <= len(_data):
                            val = struct.unpack_from("<I", _data, lo)[0]
                        s = sym_at(val) if val else None
                        ann = f"   ; [0x{lit:x}] = 0x{val:08x}" if val is not None else f"   ; [0x{lit:x}]"
                        if val is not None:
                            raw = _data[lo:lo+16]
                            printable = all(32 <= c < 127 for c in raw[:4])
                            if printable:
                                ann += f"  = {raw[:4]!r}"
                            if s:
                                ann += f"  ({demangle(s)})"
            except Exception:
                pass
        try:
            print(f"  0x{ins.address:08x}  {ins.mnemonic:<8} {ins.op_str}{ann}")
        except Exception:
            print(f"  0x{ins.address:08x}  {ins.mnemonic} {ins.op_str}{ann}")
        n += 1
        if n >= count:
            break

if __name__ == "__main__":
    targets = [
        (0x002ef125, 320, "HeCore Lua loader  ->  load_lua"),
        (0x002ef0b5, 40,  "HeCore::HeLuaLoader::init"),
        (0x0030f8cd, 60,  "HeCore::HeResFileLocator::getFileData"),
        (0x002e8365, 70,  "HeCore::HeMathUtils::aesDecrypt"),
        (0x002e8459, 70,  "HeCore::HeMathUtils::aesEncrypt"),
    ]
    for va, cnt, lbl in targets:
        disasm(va, cnt, lbl)
        print()
