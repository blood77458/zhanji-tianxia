#!/usr/bin/env python3
"""
1) verify the literal-pool words load_lua uses
2) full-binary scan for the 'ldr rX,[pc,#imm] ; add rX,pc' idiom resolving to the
   global object at 0x6BB004, so we can find who WRITES the AES key at 0x6BB02C
"""
import struct, bisect
from elftools.elf.elffile import ELFFile
from capstone import *
from capstone.arm import *

P = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
D = open(P, "rb").read()
E = ELFFile(open(P, "rb"))

SEGS = []
for s in E.iter_segments():
    if s["p_type"] == "PT_LOAD":
        SEGS.append((s["p_vaddr"], s["p_vaddr"] + s["p_memsz"],
                     s["p_offset"], s["p_filesz"], s["p_flags"]))
SEGS.sort()

def v2o(v):
    for lo, hi, off, fsz, fl in SEGS:
        if lo <= v < lo + fsz:
            return off + (v - lo)
    return None

print("=== 1) literal words used by load_lua ===")
for lit_addr, desc in ((0x2ef5c4, "sb base literal"), (0x2ef5c8, "key base literal")):
    o = v2o(lit_addr)
    val = struct.unpack_from("<I", D, o)[0]
    print(f"  [0x{lit_addr:x}] = 0x{val:08x}   ({desc})")

addsb_addr = 0x2ef1ec
addr0_addr = 0x2ef200
target_sb = 0x003cbe14 + addsb_addr + 4
target_r0 = 0x003cbe00 + addr0_addr + 4
print(f"\n  sb = 0x003cbe14 + 0x{addsb_addr+4:x} = 0x{target_sb:08x}")
print(f"  r0 = 0x003cbe00 + 0x{addr0_addr+4:x} = 0x{target_r0:08x}")
print(f"  flag @ +0x24 = 0x{target_r0+0x24:08x}")
print(f"  KEY  @ +0x28 = 0x{target_r0+0x28:08x}")

GOAL_LO, GOAL_HI = 0x6BB000, 0x6BB080

print(f"\n=== 2) scanning whole binary for PC-relative refs into 0x{GOAL_LO:x}-0x{GOAL_HI:x} ===")
ex_lo, ex_hi = SEGS[0][0], SEGS[0][1]
off_lo = v2o(ex_lo)
code = D[off_lo: off_lo + (ex_hi - ex_lo)]

md = Cs(CS_ARCH_ARM, CS_MODE_THUMB)
md.detail = True
md.skipdata = True

last_lit = {}   # reg -> (literal value, addr of the ldr)
refs = []
count = 0
for ins in md.disasm(code, ex_lo):
    count += 1
    # remember literal loads
    if ins.id == ARM_INS_LDR and len(ins.operands) >= 2:
        ops = ins.operands
        if ops[1].type == ARM_OP_MEM and ops[1].mem.base == ARM_REG_PC:
            pc = (ins.address + 4) & ~3
            lit = pc + ops[1].mem.disp
            o = v2o(lit)
            if o is not None and o + 4 <= len(D):
                val = struct.unpack_from("<I", D, o)[0]
                if ops[0].type == ARM_OP_REG:
                    last_lit[ins.reg_name(ops[0].reg)] = (val, ins.address)
    # detect add rX, pc
    if ins.id == ARM_INS_ADD and len(ins.operands) == 2:
        ops = ins.operands
        if (ops[0].type == ARM_OP_REG and ops[1].type == ARM_OP_REG
                and ops[1].reg == ARM_REG_PC):
            rn = ins.reg_name(ops[0].reg)
            if rn in last_lit:
                val, ldr_addr = last_lit[rn]
                tgt = val + ins.address + 4
                if GOAL_LO <= tgt < GOAL_HI:
                    refs.append((ins.address, rn, val, ldr_addr, tgt))
    # also direct literal load whose value lands in the window
print(f"  scanned {count} instructions")
print(f"  refs found: {len(refs)}")
for addr, rn, val, ldr_addr, tgt in refs:
    delta = tgt - 0x6BB004
    print(f"   0x{addr:08x}  add {rn}, pc  (lit 0x{val:08x} from 0x{ldr_addr:x})"
          f"  -> 0x{tgt:08x}  [base{delta:+#x}]")

# --- also look for the bare literal value appearing anywhere (static copy of the key) ---
print("\n=== 3) does the literal value 0x003cbe00/-14-family appear repeatedly? ===")
for val in (0x003cbe00, 0x003cbe14):
    pos = []
    start = 0
    while True:
        i = D.find(struct.pack("<I", val), start)
        if i < 0: break
        pos.append(i); start = i + 1
    print(f"  0x{val:08x}: {len(pos)} occurrences -> {[hex(x) for x in pos[:10]]}")
