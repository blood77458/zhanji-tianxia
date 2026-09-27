p = "patch_lua.py"
t = open(p, encoding="utf-8").read()
t2 = t.replace("\u2192", "->")
open(p, "w", encoding="utf-8", newline="\n").write(t2)
print("replaced arrows", t.count("\u2192"))
import patch_lua
print("ok", hasattr(patch_lua, "P_local_pay"))
