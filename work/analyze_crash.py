import re

LOG = r"E:\deepseek_projects\app_server\work\logcat_probe.txt"
lines = open(LOG, "rb").read().decode("utf-8", "replace").splitlines()

# index of the fatal signal
fi = None
for i, l in enumerate(lines):
    if "Fatal signal" in l and "SIGSEGV" in l:
        fi = i
        break
print("Fatal signal at log line:", fi, "of", len(lines))
print()

if fi is None:
    print("no SIGSEGV found")
else:
    print("=== 60 lines before the crash (probe + lua prints only) ===")
    show = []
    for l in lines[max(0, fi - 400):fi]:
        if "!!!IMG_REQ" in l or "!!!BUILD_GROUP" in l:
            show.append(l)
    for l in show[-45:]:
        print("   ", re.sub(r"^.*?cocos2d-x debug info: ", "", l)[:150])

    print("\n=== all non-probe lines in the last 40 before crash ===")
    for l in lines[max(0, fi - 40):fi]:
        if "!!!IMG" in l or "!!!BUILD" in l or "!!!NULL" in l or "!!!TEXTURELESS" in l:
            continue
        print("   ", re.sub(r"^\S+\s+\S+\s+\S+\s+\S\s+", "", l)[:170])

print("\n=== any lua errors anywhere? ===")
for pat in ("handler_lua_error", "attempt to", "bad argument", "NULL_SPRITE", "TEXTURELESS_SPRITE", "NO_CARD_FRAME"):
    n = sum(1 for l in lines if pat in l)
    print("   %-22s %d" % (pat, n))
