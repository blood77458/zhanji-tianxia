#!/usr/bin/env python3
"""
Because the SDK patch forces isPlatformAndroid() to true, code gated on it now
runs for the first time.  Find every identifier that is CALLED but never DEFINED
anywhere in the Lua tree -- those are latent `attempt to call a nil value`
crashes that the engine turns into SIGKILL.
"""
import os, re, collections

D = r"E:\deepseek_projects\app_server\work\luasrc"

FILES = []
for root, _, fns in os.walk(D):
    for fn in fns:
        p = os.path.join(root, fn)
        b = open(p, "rb").read()
        for e in ("utf-8", "gb18030"):
            try:
                t = b.decode(e)
                break
            except Exception:
                continue
        else:
            t = b.decode("latin-1")
        FILES.append((os.path.relpath(p, D), t))

print("files:", len(FILES))

# --- every method name that is ever defined, as a bare name -----------------
def RE(*a):
    return re.compile(*a)

PAT_FUNC   = RE(r"function\s+[\w.:]*?([A-Za-z_]\w*)\s*\(")      # function a.b:c(  / function c(
PAT_ASSIGN = RE(r"[\w.:]\s*([A-Za-z_]\w*)\s*=\s*function")       # a.b = function / b = function
PAT_FIELD  = RE(r"([A-Za-z_]\w*)\s*=\s*\{")                      # b = {   (table -> has members)

defined_methods = set()
defined_tables  = set()
for _, t in FILES:
    for m in PAT_FUNC.finditer(t):
        defined_methods.add(m.group(1))
    for m in PAT_ASSIGN.finditer(t):
        defined_methods.add(m.group(1))
    for m in PAT_FIELD.finditer(t):
        defined_tables.add(m.group(1))
    for m in re.finditer(r"^\s*local\s+([A-Za-z_]\w*)\s*=", t, re.M):
        defined_tables.add(m.group(1))

# --- every method that is ever CALLED --------------------------------------
SKIP_RECV = {"string","table","math","os","io","cc","json","cjson","_G",
             "coroutine","debug","tolua","self","ngx","socket"}
PAT_CALL = RE(r"\b([A-Za-z_]\w*)\s*[.:]\s*([A-Za-z_]\w*)\s*\(")

calls = collections.defaultdict(set)
for rel, t in FILES:
    for m in PAT_CALL.finditer(t):
        recv, meth = m.group(1), m.group(2)
        if recv in SKIP_RECV:
            continue
        calls[meth].add(rel)

missing = [(meth, sorted(w)) for meth, w in calls.items() if meth not in defined_methods]
missing.sort()
print("\n=== called-but-never-defined method names: %d ===" % len(missing))
for meth, w in missing:
    print("  %-40s (%d files) e.g. %s" % (meth, len(w), w[0]))

# --- isPlatformAndroid-gated lines -----------------------------------------
print("\n=== lines mentioning isPlatformAndroid() ===")
n = 0
for rel, t in FILES:
    for i, l in enumerate(t.split("\n")):
        if "isPlatformAndroid" in l:
            n += 1
            print("  %-50s %5d| %s" % (rel[:50], i + 1, l.strip()[:110]))
print("total:", n)
