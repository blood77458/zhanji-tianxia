# -*- coding: utf-8 -*-
"""Admin API helpers for account / card management."""
from __future__ import annotations

import json
import os
import re
import threading

import features as _feat

ROOT = os.path.dirname(os.path.abspath(__file__))
CARD_DICT_PATH = os.path.join(ROOT, "card_dict.json")
HEAD_DIR = os.path.join(
    os.path.dirname(ROOT), "work", "decoded", "assets", "resource", "card", "head")
CARD_DIR = os.path.join(
    os.path.dirname(ROOT), "work", "decoded", "assets", "resource", "card", "card")
AVATAR_CACHE = os.path.join(ROOT, "admin_avatars")
ADMIN_HTML = os.path.join(ROOT, "admin.html")
_FONT = r"C:\Windows\Fonts\msyh.ttc"

_COUNTRY_COLOR = {
    "魏": (74, 122, 181),
    "蜀": (181, 74, 74),
    "吴": (74, 155, 106),
    "群": (155, 138, 74),
    "神": (140, 100, 180),
}

_lock = threading.Lock()
_catalog = None
_heads = None
_figure_info = None  # figureId -> {name, countryName, rare}


def _ensure_catalog():
    global _catalog, _figure_info
    with _lock:
        if _catalog is not None:
            return _catalog
        if not os.path.isfile(CARD_DICT_PATH):
            from build_card_dict import main as build
            build()
        with open(CARD_DICT_PATH, encoding="utf-8") as f:
            _catalog = json.load(f)
        _figure_info = {}
        for c in _catalog.get("cards") or []:
            fig = c.get("figureId") or ""
            if fig and fig not in _figure_info:
                _figure_info[fig] = {
                    "name": c.get("name") or fig,
                    "countryName": c.get("countryName") or "",
                    "rare": c.get("rare") or 0,
                    "metaId": c.get("metaId"),
                }
        return _catalog


def _ensure_heads():
    global _heads
    with _lock:
        if _heads is not None:
            return _heads
        _heads = {}
        if os.path.isdir(HEAD_DIR):
            for fn in os.listdir(HEAD_DIR):
                if "_head." in fn and fn.endswith(".png"):
                    figure = fn.split("_head.", 1)[0]
                    _heads[figure] = os.path.join(HEAD_DIR, fn)
        return _heads


def _find_real_portrait(figure_id):
    """Rare plain-PNG portraits (e.g. youguanyu sdandard.temp)."""
    d = os.path.join(CARD_DIR, figure_id)
    if not os.path.isdir(d):
        return None
    for fn in os.listdir(d):
        p = os.path.join(d, fn)
        if not os.path.isfile(p):
            continue
        try:
            with open(p, "rb") as f:
                magic = f.read(4)
        except OSError:
            continue
        if magic == b"\x89PNG":
            return p
    return None


def _make_avatar_png(figure_id, name, country_name, rare=0):
    """Synthesize a round avatar — game heads are HQCE-encrypted, not viewable."""
    from PIL import Image, ImageDraw, ImageFont

    os.makedirs(AVATAR_CACHE, exist_ok=True)
    safe = re.sub(r"[^\w\-]+", "_", figure_id)[:80]
    out = os.path.join(AVATAR_CACHE, f"{safe}.png")
    if os.path.isfile(out) and os.path.getsize(out) > 100:
        return out

    size = 128
    rgb = _COUNTRY_COLOR.get(country_name, (90, 80, 70))
    # darken for depth
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # outer ring by rarity
    ring = (232, 160, 90) if int(rare or 0) >= 5 else (180, 160, 130)
    draw.ellipse((2, 2, size - 3, size - 3), fill=ring)
    draw.ellipse((8, 8, size - 9, size - 9), fill=rgb + (255,))

    # pick display glyph: first CJK char, else first char
    glyph = "?"
    for ch in (name or figure_id or "?"):
        if "\u4e00" <= ch <= "\u9fff":
            glyph = ch
            break
        if ch.isalnum():
            glyph = ch.upper()
            break

    try:
        font_big = ImageFont.truetype(_FONT, 52, index=0)
        font_sm = ImageFont.truetype(_FONT, 14, index=0)
    except Exception:
        font_big = ImageFont.load_default()
        font_sm = font_big

    # center glyph
    bbox = draw.textbbox((0, 0), glyph, font=font_big)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((size - tw) / 2 - bbox[0], (size - th) / 2 - bbox[1] - 6),
              glyph, font=font_big, fill=(255, 255, 255, 240))

    # name under (clipped)
    label = (name or "")[:6]
    if label:
        bbox = draw.textbbox((0, 0), label, font=font_sm)
        tw = bbox[2] - bbox[0]
        draw.text(((size - tw) / 2 - bbox[0], size - 28),
                  label, font=font_sm, fill=(255, 255, 255, 210))

    img.save(out, "PNG", optimize=True)
    return out


def head_bytes(figure_id):
    """
    Return (png_bytes, 'image/png') for admin UI.
    Prefer rare plaintext portraits; otherwise synthesize from name.
    (APK card/head/*.png are HQCE-encrypted and cannot be shown in a browser.)
    """
    figure_id = (figure_id or "").strip()
    if not figure_id:
        return None, None

    real = _find_real_portrait(figure_id)
    if real:
        with open(real, "rb") as f:
            return f.read(), "image/png"

    _ensure_catalog()
    info = (_figure_info or {}).get(figure_id) or {}
    name = info.get("name") or figure_id
    country = info.get("countryName") or ""
    rare = info.get("rare") or 0
    path = _make_avatar_png(figure_id, name, country, rare)
    with open(path, "rb") as f:
        return f.read(), "image/png"


def head_path(figure_id):
    """On-disk avatar path (generated or rare real PNG)."""
    _ensure_catalog()
    info = (_figure_info or {}).get(figure_id) or {}
    real = _find_real_portrait(figure_id)
    if real:
        return real
    return _make_avatar_png(
        figure_id,
        info.get("name") or figure_id,
        info.get("countryName") or "",
        info.get("rare") or 0,
    )


def get_catalog(q="", country=None, rare=None, stage1_only=True):
    cat = _ensure_catalog()
    q = (q or "").strip().lower()
    out = []
    for c in cat["cards"]:
        if stage1_only and int(c.get("evolutionLevel") or 1) != 1:
            continue
        if country is not None and int(c.get("country") or 0) != int(country):
            continue
        if rare is not None and int(c.get("rare") or 0) != int(rare):
            continue
        if q:
            hay = f"{c['metaId']} {c['name']} {c.get('figureId','')}".lower()
            if q not in hay:
                continue
        out.append(c)
    return {"count": len(out), "total": cat["count"], "cards": out}


def lookup_name(meta_id):
    cat = _ensure_catalog()
    info = cat.get("byMetaId", {}).get(str(int(meta_id)))
    if info:
        return info.get("name") or str(meta_id)
    return str(meta_id)


def lookup_figure(meta_id):
    cat = _ensure_catalog()
    info = cat.get("byMetaId", {}).get(str(int(meta_id)))
    return (info or {}).get("figureId") or ""


def state_snapshot(st):
    cat = _ensure_catalog()
    by = cat.get("byMetaId", {})
    cards = []
    for c in st.cards:
        mid = int(c.get("metaId") or 0)
        info = by.get(str(mid), {})
        cards.append({
            "cardId": int(c.get("cardId") or 0),
            "metaId": mid,
            "name": info.get("name") or lookup_name(mid),
            "figureId": info.get("figureId") or "",
            "head": info.get("head") or "",
            "level": int(c.get("level") or 1),
            "exp": int(c.get("exp") or 0),
            "rare": info.get("rare"),
            "countryName": info.get("countryName"),
            "lock": bool(c.get("lock")),
        })
    cards.sort(key=lambda x: (-(x.get("rare") or 0), x["metaId"], x["cardId"]))
    props = [{"metaId": int(p.get("metaId") or 0),
              "amount": int(p.get("amount") or 0)} for p in (st.props or [])]
    return {
        "uid": str(st.uid),
        "nickname": st.pending_nickname or "",
        "level": int(st.level),
        "exp": int(st.exp),
        "coins": int(st.coins),
        "gems": int(getattr(st, "gems", 0) or 0),
        "rechargeGems": int(st.recharge_gems),
        "energy": int(st.energy),
        "generalExp": int(getattr(st, "general_exp", 0) or 0),
        "mainCardId": int(getattr(st, "main_card_id", 0) or 0),
        "additionalCardIds": _feat.normalize_additional_card_ids(
            getattr(st, "additional_card_ids", "")),
        "cardCount": len(cards),
        "cards": cards,
        "props": props,
        "missionId": int((st.mission_context or {}).get("missionId") or 0),
        "maxFinishedMissionId": int(
            (st.scene_process or {}).get("maxFinishedMissionId") or 0),
        "gainedChargeMoneyRewardList": list(st.gained_charge_money_reward_list or []),
    }


def update_state(st, body: dict):
    with st._lock:
        if "nickname" in body:
            st.pending_nickname = str(body["nickname"] or "")[:16]
        for key, attr in (
            ("level", "level"),
            ("exp", "exp"),
            ("coins", "coins"),
            ("gems", "gems"),
            ("rechargeGems", "recharge_gems"),
            ("energy", "energy"),
            ("generalExp", "general_exp"),
        ):
            if key in body and body[key] is not None:
                setattr(st, attr, int(body[key]))
        st.save()
    return state_snapshot(st)


def add_cards(st, meta_ids, level=1, count=1):
    """Add one or more cards. meta_ids: list[int]. Returns added list."""
    added = []
    level = max(1, int(level or 1))
    count = max(1, min(99, int(count or 1)))
    with st._lock:
        for mid in meta_ids:
            mid = int(mid)
            if not _feat.card_meta_exists(mid):
                continue
            for _ in range(count):
                st.next_card_id += 1
                cid = st.next_card_id
                card = _feat.make_card(cid, mid, level=level, exp=0)
                st.cards.append(card)
                added.append({
                    "cardId": cid,
                    "metaId": mid,
                    "name": lookup_name(mid),
                    "level": level,
                })
        st.save()
    return added


def remove_card(st, card_id):
    card_id = int(card_id)
    with st._lock:
        before = len(st.cards)
        st.cards = [c for c in st.cards if int(c.get("cardId") or 0) != card_id]
        if int(getattr(st, "main_card_id", 0) or 0) == card_id:
            st.main_card_id = 0
        adds = _feat.normalize_additional_card_ids(
            getattr(st, "additional_card_ids", ""))
        st.additional_card_ids = ",".join(
            str(x) for x in adds if int(x) != card_id)
        st.save()
        return before - len(st.cards)


def set_card_level(st, card_id, level):
    card_id = int(card_id)
    level = max(1, min(200, int(level)))
    with st._lock:
        for c in st.cards:
            if int(c.get("cardId") or 0) == card_id:
                c["level"] = level
                st.save()
                return True
    return False


def admin_html_bytes():
    with open(ADMIN_HTML, "rb") as f:
        return f.read()
