#!/usr/bin/env python3
"""Locate HeMemDataHolder::decrypt in libhegame.so and dump nearby bytes."""
import struct, os

SO = r"E:\deepseek_projects\app_server\work\extract\libhegame.so"
data = open(SO, "rb").read()

# Minimal ELF32 parse
assert data[:4] == b"\x7fELF"
e_phoff = struct.unpack_from("<I", data, 28)[0]
e_phentsize = struct.unpack_from("<H", data, 42)[0]
e_phnum = struct.unpack_from("<H", data, 44)[0]
# load segments: file offset -> vaddr
loads = []
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack_from("<IIIIIIII", data, off)
    if p_type == 1:  # PT_LOAD
        loads.append((p_offset, p_vaddr, p_filesz))

def va_to_off(va):
    for po, pv, pf in loads:
        if pv <= va < pv + pf:
            return po + (va - pv)
    return None

# Find dynsym via dynamic section
e_shoff = struct.unpack_from("<I", data, 32)[0]
e_shentsize = struct.unpack_from("<H", data, 46)[0]
e_shnum = struct.unpack_from("<H", data, 48)[0]
e_shstrndx = struct.unpack_from("<H", data, 50)[0]
shstr = e_shoff + e_shstrndx * e_shentsize
shstr_off = struct.unpack_from("<I", data, shstr + 16)[0]

def sh_name(i):
    sh = e_shoff + i * e_shentsize
    name_off = struct.unpack_from("<I", data, sh)[0]
    end = data.index(b"\x00", shstr_off + name_off)
    return data[shstr_off + name_off:end].decode()

dynsym = dynstr = None
for i in range(e_shnum):
    name = sh_name(i)
    sh = e_shoff + i * e_shentsize
    sh_offset = struct.unpack_from("<I", data, sh + 16)[0]
    sh_size = struct.unpack_from("<I", data, sh + 20)[0]
    if name == ".dynsym":
        dynsym = (sh_offset, sh_size)
    if name == ".dynstr":
        dynstr = (sh_offset, sh_size)

print("dynsym", dynsym, "dynstr", dynstr)
ds_off, ds_sz = dynsym
dstr_off, _ = dynstr
# ELF32_Sym: name(4) value(4) size(4) info(1) other(1) shndx(2) = 16
targets = []
for i in range(0, ds_sz, 16):
    st_name, st_value, st_size, st_info, st_other, st_shndx = struct.unpack_from("<IIIBBH", data, ds_off + i)
    if not st_name or not st_value:
        continue
    end = data.index(b"\x00", dstr_off + st_name)
    name = data[dstr_off + st_name:end].decode(errors="replace")
    if "HeMemDataHolder" in name and "decrypt" in name:
        print(f"{name} va=0x{st_value:x} size={st_size}")
        targets.append((name, st_value, st_size))
    if "HQCE" in name or "hqce" in name.lower():
        print("name hit", name, hex(st_value))

# Also find string HQCE and look for ADR-like refs (hard). Dump decrypt funcs.
out_dir = r"E:\deepseek_projects\app_server\work\hqce_dump"
os.makedirs(out_dir, exist_ok=True)
for name, va, sz in targets:
    off = va_to_off(va)
    print(name, "fileoff", hex(off) if off else None)
    if off is None:
        continue
    blob = data[off:off + max(sz, 0x400)]
    open(os.path.join(out_dir, name.replace(":", "_") + ".bin"), "wb").write(blob)
    print("  dumped", len(blob), "bytes head", blob[:32].hex())
