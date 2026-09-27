#!/usr/bin/env python3
"""Build card_dict.json: metaId -> name / figureId / head image path."""
import json
import os
import re

ROOT = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.join(os.path.dirname(ROOT), "work")
META = os.path.join(WORK, "luasrc", "canon", "configs")
STRINGS = os.path.join(
    WORK, "decoded", "assets", "resource", "text", "zh_CN",
    "Card_configure.bd2f0e9fb80b7c8ce8221707586755d9.strings")
HEAD_DIR = os.path.join(WORK, "decoded", "assets", "resource", "card", "head")
OUT = os.path.join(ROOT, "card_dict.json")

COUNTRY = {1: "魏", 2: "蜀", 3: "吴", 4: "群", 5: "神"}


def load_names():
    names = {}
    if not os.path.isfile(STRINGS):
        return names
    text = open(STRINGS, encoding="utf-8", errors="replace").read()
    for m in re.finditer(r'"Card_(\d+)_name"\s*=\s*"([^"]*)"', text):
        names[int(m.group(1))] = m.group(2)
    return names


def index_heads():
    """figureId -> absolute path of head png (content-hashed filenames)."""
    out = {}
    if not os.path.isdir(HEAD_DIR):
        return out
    for fn in os.listdir(HEAD_DIR):
        if not fn.endswith(".png"):
            continue
        # ahuinan_1_head.22e712....png
        if "_head." not in fn:
            continue
        figure = fn.split("_head.", 1)[0]
        out[figure] = os.path.join(HEAD_DIR, fn)
    return out


def load_meta(names, heads):
    cards = []
    if not os.path.isdir(META):
        return cards
    meta_file = None
    for fn in os.listdir(META):
        if fn.startswith("card_meta."):
            meta_file = os.path.join(META, fn)
            break
    if not meta_file:
        return cards
    text = open(meta_file, encoding="utf-8", errors="replace").read()
    for m in re.finditer(r"\[(\d+)\]=\{([^}]*)\}", text):
        mid = int(m.group(1))
        body = m.group(2)

        def _i(name, default=0):
            mm = re.search(rf"{name}=(\d+)", body)
            return int(mm.group(1)) if mm else default

        def _s(name, default=""):
            mm = re.search(rf'{name}="([^"]*)"', body)
            return mm.group(1) if mm else default

        figure = _s("figureId")
        read = _s("readName")
        # Prefer localization display name; fall back to readName base
        name = names.get(mid) or (read.rsplit("_", 1)[0] if read else str(mid))
        country = _i("country")
        cards.append({
            "metaId": mid,
            "name": name,
            "readName": read,
            "figureId": figure,
            "rare": _i("rare"),
            "country": country,
            "countryName": COUNTRY.get(country, str(country)),
            "evolutionLevel": _i("evolutionLevel", 1),
            "cardGroupId": _i("cardGroupId"),
            "head": f"/admin/cardimg/{figure}" if figure else "",
            "hasHead": figure in heads,
        })
    cards.sort(key=lambda c: (c["country"], -c["rare"], c["metaId"]))
    return cards


def main():
    names = load_names()
    heads = index_heads()
    cards = load_meta(names, heads)
    payload = {
        "count": len(cards),
        "headsIndexed": len(heads),
        "cards": cards,
        # flat dict for quick lookup
        "byMetaId": {str(c["metaId"]): {
            "name": c["name"],
            "figureId": c["figureId"],
            "rare": c["rare"],
            "country": c["country"],
            "countryName": c["countryName"],
            "head": c["head"],
        } for c in cards},
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"wrote {OUT}: {len(cards)} cards, {len(heads)} heads, {len(names)} names")


if __name__ == "__main__":
    main()
