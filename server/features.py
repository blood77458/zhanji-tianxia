"""Inventory persistence + feature RPC handlers for canon_server.

Imported by canon_server; mutates the shared ST state and returns AMF response
dicts for bag / team / mail / friends / beasts / shop / sweep endpoints.
"""
from __future__ import annotations

import os
import random
import re

# ResourceEnum (RewardManager.lua)
RE_COIN = 1
RE_GEMS = 2
RE_ENERGY = 3
RE_EXP = 4
RE_CARD = 5
RE_EQUIP = 6
RE_PROP = 7
RE_GRID = 9
RE_EVENTPOINT = 11

_PROP_META = {}       # metaId -> {sellPrice, effectType, effectValue, canSell}
_SHOP_META = {}       # goodsId -> {itemType, metaId, amount, moneyType, discountPrice}
_PROP_META_LOADED = False
_SHOP_META_LOADED = False

_CONFIGS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "work", "luasrc", "canon", "configs")

# Starter bag contents so 背包 is not empty on first open.
_STARTER_PROPS = [
    {"metaId": 400001, "amount": 20},  # 经验球
    {"metaId": 400002, "amount": 20},  # 体力药水
    {"metaId": 400003, "amount": 20},  # 精力药水
    {"metaId": 400004, "amount": 10},  # 经验球（中）
    {"metaId": 400005, "amount": 10},  # 体力药水（中）
    {"metaId": 400010, "amount": 9999},  # 魂石（培养）
    {"metaId": 400016, "amount": 3},   # 铜宝箱
    {"metaId": 400017, "amount": 2},   # 银宝箱
    {"metaId": 400019, "amount": 1},   # 金宝箱
]
_STARTER_EQUIP_METAS = [210011, 220011, 230011]  # 柳叶刀 / 锁子甲 / 青鬃


def _load_prop_meta():
    global _PROP_META, _PROP_META_LOADED
    if _PROP_META_LOADED:
        return
    _PROP_META_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("prop_meta."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(
            r"\[(\d+)\]=\{id=\d+,[^}]*?canSell=(\w+),sellPrice=(\d+)[^}]*?"
            r"effectType=(\d+)[^}]*?effectValue=([\d.]+)",
            text,
        ):
            mid, can, price, et, ev = m.groups()
            _PROP_META[int(mid)] = {
                "canSell": can == "true",
                "sellPrice": int(price),
                "effectType": int(et),
                "effectValue": float(ev),
            }
        break


def _load_shop_meta():
    global _SHOP_META, _SHOP_META_LOADED
    if _SHOP_META_LOADED:
        return
    _SHOP_META_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("shop_meta."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(
            r"\[(\d+)\]=\{id=\d+,itemType=(\d+),metaId=(\d+),amount=(\d+),"
            r"moneyType=(\d+),price=\d+,discountPrice=(\d+)",
            text,
        ):
            gid, it, mid, amt, mt, dp = m.groups()
            _SHOP_META[int(gid)] = {
                "itemType": int(it),
                "metaId": int(mid),
                "amount": int(amt),
                "moneyType": int(mt),
                "discountPrice": int(dp),
            }
        break


def reward_coin(amount):
    return {"itemType": RE_COIN, "amount": int(amount)}


def reward_gems(amount):
    return {"itemType": RE_GEMS, "amount": int(amount)}


def reward_energy(amount):
    return {"itemType": RE_ENERGY, "amount": int(amount)}


def reward_exp(amount):
    return {"itemType": RE_EXP, "amount": int(amount)}


def reward_prop(meta_id, amount):
    return {"itemType": RE_PROP, "metaId": int(meta_id), "amount": int(amount)}


def reward_grid(amount):
    return {"itemType": RE_GRID, "amount": int(amount)}


_CARD_META = {}          # metaId -> {cardGroupId, skill, mainSkill, groupSkills..., basicExp, evolutionLevel}
_CARD_META_LOADED = False
_SKILL_META = {}         # skillId -> {skillType, quality, level}
_SKILL_META_LOADED = False
_SPECIAL_GROUP_SKILL = {}  # cardGroupId -> list of country-group skills
_SPECIAL_GROUP_SKILL_LOADED = False
_CARD_LEVEL = {}         # level -> {exp, totalExp, expConvertCoefficient}
_CARD_LEVEL_LOADED = False
_CARD_EVOLVE = {}        # evolutionLevel -> maxCardLevel
_CARD_EVOLVE_LOADED = False


def _load_card_meta():
    global _CARD_META, _CARD_META_LOADED
    if _CARD_META_LOADED:
        return
    _CARD_META_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("card_meta."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\[(\d+)\]=\{([^}]*)\}", text):
            body = m.group(2)

            def _i(name, default=0, _b=body):
                mm = re.search(rf"{name}=(\d+)", _b)
                return int(mm.group(1)) if mm else default

            def _s(name, default="0", _b=body):
                mm = re.search(rf'{name}="([^"]*)"', _b)
                return mm.group(1) if mm else default

            _CARD_META[int(m.group(1))] = {
                "cardGroupId": _i("cardGroupId"),
                "skill": _i("skill"),
                "mainSkill": _i("mainSkill"),
                "groupSkill1": _i("groupSkill1"),
                "group1": _s("group1"),
                "groupSkill2": _i("groupSkill2"),
                "group2": _s("group2"),
                "groupSkill3": _i("groupSkill3"),
                "group3": _s("group3"),
                "groupSkill4": _i("groupSkill4"),
                "group4": _s("group4"),
                "groupSkill5": _i("groupSkill5"),
                "group5": _s("group5"),
                "basicExp": _i("basicExp", 100),
                "evolutionLevel": _i("evolutionLevel", 1),
                "evolutionCardId": _i("evolutionCardId", 0),
                "maxEvolvedLevel": _i("maxEvolvedLevel", 1),
            }
        break


def _load_card_level():
    global _CARD_LEVEL, _CARD_LEVEL_LOADED
    if _CARD_LEVEL_LOADED:
        return
    _CARD_LEVEL_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("card_level."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(
                r"\[(\d+)\]=\{level=\d+,exp=(\d+),levelCoefficient=\d+,"
                r"priceCoefficient=\d+,totalExp=(\d+),upgradeCoin=\d+,"
                r"expConvertCoefficient=([0-9.]+)",
                text):
            _CARD_LEVEL[int(m.group(1))] = {
                "exp": int(m.group(2)),
                "totalExp": int(m.group(3)),
                "expConvertCoefficient": float(m.group(4)),
            }
        break


def _load_card_evolve():
    global _CARD_EVOLVE, _CARD_EVOLVE_LOADED
    if _CARD_EVOLVE_LOADED:
        return
    _CARD_EVOLVE_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("card_evolve."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\[(\d+)\]=\{evolutionLevel=\d+,maxCardLevel=(\d+)", text):
            _CARD_EVOLVE[int(m.group(1))] = int(m.group(2))
        break


def _card_level_row(level):
    _load_card_level()
    return _CARD_LEVEL.get(int(level)) or {"exp": 100, "totalExp": 0, "expConvertCoefficient": 1.0}


def _card_max_level(meta_id):
    _load_card_meta()
    _load_card_evolve()
    info = _CARD_META.get(int(meta_id or 0)) or {}
    evo = int(info.get("evolutionLevel") or 1)
    return int(_CARD_EVOLVE.get(evo) or 70)


def _matter_provide_exp(card):
    """Client CardComposeScene:getComposeExp matter contribution."""
    lvl = int(card.get("level") or 1)
    exp = int(card.get("exp") or 0)
    mid = int(card.get("metaId") or 0)
    row = _card_level_row(lvl)
    _load_card_meta()
    basic = int((_CARD_META.get(mid) or {}).get("basicExp") or 100)
    matter_total = int(row["totalExp"]) + exp
    return int(basic + matter_total * float(row["expConvertCoefficient"]))


def _apply_card_total_exp(card, total_exp):
    """Set card.level / card.exp from absolute total experience (client formula)."""
    _load_card_level()
    max_lv = _card_max_level(card.get("metaId"))
    total_exp = int(total_exp or 0)
    new_lv = 1
    for lv in sorted(_CARD_LEVEL.keys()):
        if lv > max_lv:
            break
        if total_exp >= int(_CARD_LEVEL[lv]["totalExp"]):
            new_lv = lv
        else:
            break
    new_lv = min(int(new_lv), int(max_lv))
    row = _card_level_row(new_lv)
    leftover = max(0, total_exp - int(row["totalExp"]))
    need = int(row.get("exp") or 0)
    if new_lv >= max_lv:
        leftover = 0
    elif need > 0:
        leftover = min(leftover, need - 1)
    card["level"] = new_lv
    card["exp"] = leftover


def _normalize_id_list(raw):
    """AMF slaveIds may be list / dict{\"1\":id,...} / single int."""
    if raw is None:
        return []
    if isinstance(raw, dict):
        keys = sorted(raw.keys(), key=lambda k: int(k) if str(k).isdigit() else 999)
        return [int(raw[k]) for k in keys if raw[k] is not None]
    if isinstance(raw, (list, tuple)):
        return [int(x) for x in raw if x is not None]
    if isinstance(raw, (int, float)):
        return [int(raw)]
    s = str(raw).strip()
    if not s:
        return []
    return [int(p) for p in s.replace(";", ",").split(",") if p.strip().isdigit()]


def _load_skill_meta():
    global _SKILL_META, _SKILL_META_LOADED
    if _SKILL_META_LOADED:
        return
    _SKILL_META_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("skill_meta."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(
                r"\[(\d+)\]=\{id=\d+,.*?skillType=(\d+),.*?quality=(\d+),.*?level=(\d+)",
                text):
            _SKILL_META[int(m.group(1))] = {
                "skillType": int(m.group(2)),
                "quality": int(m.group(3)),
                "level": int(m.group(4)),
            }
        break


def _load_special_group_skill():
    global _SPECIAL_GROUP_SKILL, _SPECIAL_GROUP_SKILL_LOADED
    if _SPECIAL_GROUP_SKILL_LOADED:
        return
    _SPECIAL_GROUP_SKILL_LOADED = True
    if not os.path.isdir(_CONFIGS):
        return
    for fn in os.listdir(_CONFIGS):
        if not fn.startswith("special_group_skill."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\[(\d+)\]=\{([^}]*)\}", text):
            body = m.group(2)
            entries = []
            for i in range(1, 4):
                mm = re.search(rf"groupSkill{i}=(\d+)", body)
                if not mm or int(mm.group(1)) == 0:
                    break
                g = re.search(rf"group{i}=(\d+)", body)
                n = re.search(rf"groupNum{i}=(\d+)", body)
                entries.append({
                    "skillId": int(mm.group(1)),
                    "countryGroupId": int(g.group(1)) if g else 0,
                    "countryGroupNum": int(n.group(1)) if n else 0,
                })
            if entries:
                _SPECIAL_GROUP_SKILL[int(m.group(1))] = entries
        break


def build_card_skills(meta_id):
    """Mirror RewardManager.generateCard cardSkills construction.

    QueueCardPanel / CardQueueScene index skill_meta[cardSkills[i].skillId]
    and crash (SIGKILL) when cardSkills is empty but card_meta.skill ~= 0.
    """
    _load_card_meta()
    _load_skill_meta()
    _load_special_group_skill()
    info = _CARD_META.get(int(meta_id))
    if not info:
        return []
    pending = []  # {skillId, groupIds|None, countryGroupId?, countryGroupNum?}
    if info["skill"]:
        pending.append({"skillId": info["skill"], "groupIds": None})
    if info["mainSkill"]:
        pending.append({"skillId": info["mainSkill"], "groupIds": None})
    for i in range(1, 6):
        sid = info.get(f"groupSkill{i}") or 0
        if sid:
            pending.append({
                "skillId": sid,
                "groupIds": str(info.get(f"group{i}") or "0"),
            })
    cgid = int(info["cardGroupId"] or 0)
    for sp in _SPECIAL_GROUP_SKILL.get(cgid) or []:
        pending.append({
            "skillId": sp["skillId"],
            "groupIds": None,
            "countryGroupId": sp["countryGroupId"],
            "countryGroupNum": sp["countryGroupNum"],
        })
    out = []
    for a in pending:
        sm = _SKILL_META.get(int(a["skillId"]))
        if not sm:
            continue
        group_ids = []
        raw = a.get("groupIds")
        if raw:
            for part in str(raw).split("|"):
                part = part.strip()
                if part.isdigit():
                    group_ids.append(int(part))
        skill_type = int(sm["skillType"])
        out.append({
            "skillType": skill_type,
            "skillId": int(a["skillId"]),
            "currQuality": int(sm["quality"]),
            "cardGroupIds": group_ids,
            "countryGroupId": int(a["countryGroupId"]) if skill_type == 4 else 0,
            "countryGroupNum": int(a["countryGroupNum"]) if skill_type == 4 else 0,
        })
    return out


def card_meta_exists(meta_id):
    _load_card_meta()
    return int(meta_id) in _CARD_META


def card_group_id(meta_id):
    _load_card_meta()
    info = _CARD_META.get(int(meta_id))
    if info:
        return int(info["cardGroupId"])
    # last-resort guess; prefer never reaching here
    return int(meta_id) // 100 % 1000 if meta_id else 0


def normalize_additional_card_ids(add):
    """AMF may send additionalCardIds as list, comma-string, or 1-based object
    like {"1": 1043, "2": 1050}. Always return a flat list of ints."""
    if add is None:
        return []
    if isinstance(add, dict):
        # Prefer numeric keys in order 1..N
        keys = sorted(add.keys(), key=lambda k: int(k) if str(k).isdigit() else 999)
        vals = [add[k] for k in keys]
    elif isinstance(add, (list, tuple)):
        vals = list(add)
    elif isinstance(add, (int, float)):
        vals = [add]
    else:
        s = str(add).strip()
        if not s:
            return []
        vals = [p for p in s.replace(";", ",").split(",") if p.strip()]
    out = []
    for x in vals:
        try:
            out.append(int(x))
        except (TypeError, ValueError):
            continue
    return out


def apply_team_formation(st, main_card_id, additional_card_ids):
    """Persist main + additional formation slots to user_state."""
    main = int(main_card_id or st.main_card_id or 1)
    add_ids = normalize_additional_card_ids(additional_card_ids)
    # Drop duplicates / main from additional; keep order
    seen = {main}
    cleaned = []
    for cid in add_ids:
        if cid in seen:
            continue
        seen.add(cid)
        cleaned.append(cid)
    st.main_card_id = main
    st.additional_card_ids = ",".join(str(x) for x in cleaned)
    st.save()
    return main, cleaned


def make_card(card_id, meta_id, level=1, exp=0):
    mid = int(meta_id)
    return {
        "cardId": int(card_id),
        "metaId": mid,
        "avatarMetaId": 0,
        "level": int(level),
        "exp": int(exp),
        # CardQueueScene:336 indexes MetaManager.card_meta[metaId].cardGroupId
        # — stored group must match card_meta or UI is wrong; missing metaId
        # crashes the scene entirely.
        "cardGroupId": card_group_id(mid),
        "fightCapacity": 0,
        "equipIds": [],
        "skillLevels": [],
        # Must mirror RewardManager.generateCard — empty list + meta.skill~=0
        # → QueueCardPanel:387 indexes nil aSkill → SIGKILL on boot/编队.
        "cardSkills": build_card_skills(mid),
        "attTrainValue": 0,
        "defTrainValue": 0,
        "hpTrainValue": 0,
        "attEvolveValue": 0,
        "defEvolveValue": 0,
        "hpEvolveValue": 0,
        "cardSpirits": [],
        # CommonManager: if treasureId ~= 0 then lookup — nil ~= 0 is true in Lua!
        "treasureId": 0,
        # BackpackScene:2576 arithmetic on usedPotential
        "usedPotential": 0,
        "lock": False,
    }


def make_equip(equip_id, meta_id, level=1, exp=0, card_id=0):
    return {
        "equipId": int(equip_id),
        "metaId": int(meta_id),
        "level": int(level),
        "exp": int(exp),
        "cardId": int(card_id or 0),
        "enchantLevel": 0,
        "enchantNum": 0,
    }


def _find_equip(st, equip_id):
    eid = int(equip_id)
    for e in st.equips:
        if int(e.get("equipId") or 0) == eid:
            return e
    return None


def _find_card(st, card_id):
    cid = int(card_id)
    for c in st.cards:
        if int(c.get("cardId") or 0) == cid:
            return c
    return None


def _copy_equip(e):
    return {
        "equipId": int(e.get("equipId") or 0),
        "metaId": int(e.get("metaId") or 0),
        "level": int(e.get("level") or 1),
        "exp": int(e.get("exp") or 0),
        "cardId": int(e.get("cardId") or 0),
        "enchantLevel": int(e.get("enchantLevel") or 0),
        "enchantNum": int(e.get("enchantNum") or 0),
    }


def _copy_card(c):
    out = dict(c)
    # ensure crash-prone fields always present
    out.setdefault("treasureId", 0)
    out.setdefault("usedPotential", 0)
    out.setdefault("equipIds", list(c.get("equipIds") or []))
    out.setdefault("skillLevels", list(c.get("skillLevels") or []))
    out.setdefault("cardSpirits", list(c.get("cardSpirits") or []))
    skills = out.get("cardSkills")
    if not isinstance(skills, list) or not skills:
        out["cardSkills"] = build_card_skills(int(out.get("metaId") or 0))
    out.setdefault("lock", False)
    for k in ("attTrainValue", "defTrainValue", "hpTrainValue",
              "attEvolveValue", "defEvolveValue", "hpEvolveValue"):
        out.setdefault(k, int(c.get(k) or 0))
    return out


def _user_level_cap(st):
    return max(1, min(99, int(getattr(st, "level", 1) or 1)))


def _bump_equip_level(st, equip, levels=1):
    cap = _user_level_cap(st)
    cur = int(equip.get("level") or 1)
    equip["level"] = min(cur + max(1, int(levels)), cap)
    equip["exp"] = int(equip.get("exp") or 0)
    return _copy_equip(equip)


def _evolve_equip_meta(equip):
    """Next stage = metaId + 1 within the same prefix family (…11 -> …12)."""
    mid = int(equip.get("metaId") or 0)
    if mid <= 0:
        return _copy_equip(equip)
    # Only bump last digit of evolve stage if not already max (…x5)
    if mid % 10 < 5:
        equip["metaId"] = mid + 1
    return _copy_equip(equip)



def card_from_reward(r):
    return make_card(r.get("id") or r.get("cardId"), r["metaId"],
                     r.get("level", 1), r.get("exp", 0))


def equip_from_reward(r):
    return make_equip(r.get("id") or r.get("equipId"), r["metaId"],
                      r.get("level", 1), r.get("exp", 0))


class InventoryMixin:
    """Methods mixed into canon_server.State via composition (ST.inv_*)."""

    def __init__(self):
        self.gems = 10000
        self.cards = []          # list of card dicts
        self.equips = []         # list of equip dicts
        self.props = []          # list of {metaId, amount}
        self.spirits = []
        self.bought_grid_num = 0
        self.bought_grid_times = 0
        self.main_card_id = 1
        self.additional_card_ids = ""  # comma-separated string
        self.next_card_id = 1000
        self.next_equip_id = 100
        self.inventory_seeded = False
        self.event_point = 100

    def load_inv(self, d):
        self.gems = int(d.get("gems", self.gems))
        self.cards = list(d.get("cards") or [])
        self.equips = list(d.get("equips") or [])
        self.props = list(d.get("props") or [])
        self.spirits = list(d.get("spirits") or [])
        self.bought_grid_num = int(d.get("bought_grid_num", 0))
        self.bought_grid_times = int(d.get("bought_grid_times", 0))
        self.main_card_id = int(d.get("main_card_id", 1))
        self.additional_card_ids = str(d.get("additional_card_ids") or "")
        self.next_card_id = int(d.get("next_card_id", 1000))
        self.next_equip_id = int(d.get("next_equip_id", 100))
        self.inventory_seeded = bool(d.get("inventory_seeded", False))
        self.event_point = int(d.get("event_point", 100))
        # Drop / repair cards whose metaId is missing from card_meta — otherwise
        # CardQueueScene/BackpackScene index nil and SIGKILL.
        self.sanitize_cards()
        # bump id counters past any existing ids
        for c in self.cards:
            cid = int(c.get("cardId") or 0)
            if cid >= self.next_card_id:
                self.next_card_id = cid + 1
        for e in self.equips:
            eid = int(e.get("equipId") or 0)
            if eid >= self.next_equip_id:
                self.next_equip_id = eid + 1

    def sanitize_cards(self):
        """Remove unknown metaIds; refresh cardGroupId / crash-prone fields."""
        _load_card_meta()
        kept = []
        dropped = 0
        repaired = 0
        for c in self.cards:
            mid = int(c.get("metaId") or 0)
            if mid not in _CARD_META:
                dropped += 1
                continue
            c["cardGroupId"] = card_group_id(mid)
            c.setdefault("treasureId", 0)
            c.setdefault("usedPotential", 0)
            c.setdefault("equipIds", list(c.get("equipIds") or []))
            c.setdefault("skillLevels", list(c.get("skillLevels") or []))
            # Must mirror generateCard — empty + meta.skill~=0 → QueueCardPanel SIGKILL.
            skills = c.get("cardSkills")
            if not isinstance(skills, list) or not skills:
                c["cardSkills"] = build_card_skills(mid)
                repaired += 1
            c.setdefault("cardSpirits", list(c.get("cardSpirits") or []))
            c.setdefault("lock", False)
            for k in ("attTrainValue", "defTrainValue", "hpTrainValue",
                      "attEvolveValue", "defEvolveValue", "hpEvolveValue"):
                c.setdefault(k, 0)
            kept.append(c)
        self.cards = kept
        self._cards_dropped = dropped
        self._cards_skills_repaired = repaired
        return dropped, repaired

    def dump_inv(self):
        return {
            "gems": self.gems,
            "cards": self.cards,
            "equips": self.equips,
            "props": self.props,
            "spirits": self.spirits,
            "bought_grid_num": self.bought_grid_num,
            "bought_grid_times": self.bought_grid_times,
            "main_card_id": self.main_card_id,
            "additional_card_ids": self.additional_card_ids,
            "next_card_id": self.next_card_id,
            "next_equip_id": self.next_equip_id,
            "inventory_seeded": self.inventory_seeded,
            "event_point": self.event_point,
        }

    def ensure_seeded(self, starter_card_fn):
        """Ensure starter card + sample bag contents exist."""
        if not self.cards:
            c = starter_card_fn()
            self.cards = [c]
            self.main_card_id = int(c["cardId"])
        if not self.inventory_seeded:
            if not self.props:
                self.props = [dict(p) for p in _STARTER_PROPS]
            if not self.equips:
                for mid in _STARTER_EQUIP_METAS:
                    self.next_equip_id += 1
                    self.equips.append(make_equip(self.next_equip_id, mid))
            self.inventory_seeded = True

    def add_prop(self, meta_id, amount):
        meta_id, amount = int(meta_id), int(amount)
        for p in self.props:
            if int(p["metaId"]) == meta_id:
                p["amount"] = int(p["amount"]) + amount
                if p["amount"] <= 0:
                    self.props = [x for x in self.props if int(x["metaId"]) != meta_id]
                return
        if amount > 0:
            self.props.append({"metaId": meta_id, "amount": amount})

    def take_prop(self, meta_id, amount):
        meta_id, amount = int(meta_id), int(amount)
        for p in self.props:
            if int(p["metaId"]) == meta_id:
                have = int(p["amount"])
                if have < amount:
                    return False
                p["amount"] = have - amount
                if p["amount"] <= 0:
                    self.props = [x for x in self.props if int(x["metaId"]) != meta_id]
                return True
        return False

    def add_card_from_reward(self, r):
        mid = int(r.get("metaId") or 0)
        if mid and not card_meta_exists(mid):
            # Refuse unknown cards — prevents bag/team SIGKILL on next open.
            return r
        self.next_card_id = max(self.next_card_id, int(r.get("id") or 0) + 1)
        if not r.get("id"):
            self.next_card_id += 1
            r = dict(r)
            r["id"] = self.next_card_id
        self.cards.append(card_from_reward(r))
        return r

    def add_equip_from_reward(self, r):
        eid = int(r.get("id") or r.get("equipId") or 0)
        if not eid:
            self.next_equip_id += 1
            eid = self.next_equip_id
            r = dict(r)
            r["id"] = eid
        else:
            self.next_equip_id = max(self.next_equip_id, eid + 1)
        self.equips.append(equip_from_reward(r))
        return r

    def apply_reward_item(self, r, st_coins_apply=None):
        """Apply one reward dict into inventory + currencies on `self` /
        optional coin/exp callback for the outer State."""
        it = int(r.get("itemType") or 0)
        amt = int(r.get("amount") or 0)
        if it == RE_COIN and st_coins_apply:
            st_coins_apply(RE_COIN, amt)
        elif it == RE_GEMS:
            self.gems = max(0, int(self.gems) + amt)
        elif it == RE_ENERGY and st_coins_apply:
            # energy lives on outer State
            st_coins_apply(RE_ENERGY, amt)
        elif it == RE_EXP and st_coins_apply:
            st_coins_apply(RE_EXP, amt)
        elif it == RE_CARD:
            self.add_card_from_reward(r)
        elif it == RE_EQUIP:
            self.add_equip_from_reward(r)
        elif it == RE_PROP:
            self.add_prop(r.get("metaId"), amt)
        elif it == RE_GRID:
            self.bought_grid_num = int(self.bought_grid_num) + amt
        elif it == RE_EVENTPOINT:
            self.event_point = max(0, int(self.event_point) + amt)

    def apply_rewards(self, rewards, st_coins_apply=None):
        for r in rewards or []:
            self.apply_reward_item(r, st_coins_apply)


def handle(method, params, base, st, starter_card_fn):
    """
    Handle feature RPCs. Returns True if handled.
    `st` is the canon_server.State instance (with InventoryMixin fields).
    """
    params = params or {}

    if method == "getProps":
        base["sharkProps"] = {"sharkProps": list(st.props)}
        return True

    if method == "getEquips":
        base["sharkEquips"] = {"sharkEquips": list(st.equips)}
        return True

    if method == "sellProps":
        _load_prop_meta()
        requisite = params.get("requisite") or []
        if isinstance(requisite, dict):
            requisite = [requisite]
        total = 0
        for item in requisite:
            mid = int(item.get("metaId") or 0)
            amt = int(item.get("amount") or 1)
            meta = _PROP_META.get(mid) or {"sellPrice": 100}
            if st.take_prop(mid, amt):
                total += int(meta.get("sellPrice") or 100) * amt
        rewards = [reward_coin(total)] if total else [reward_coin(0)]
        st.apply_rewards(rewards, st.apply_reward)
        st.save()
        base["rewards"] = rewards
        return True

    if method == "sellEquips":
        ids = params.get("equipIds") or []
        if isinstance(ids, (int, float, str)):
            ids = [ids]
        ids = {int(x) for x in ids}
        total = 0
        kept = []
        for e in st.equips:
            if int(e.get("equipId") or 0) in ids:
                # rough sell price
                total += 200 * int(e.get("level") or 1)
            else:
                kept.append(e)
        st.equips = kept
        rewards = [reward_coin(total)] if total else [reward_coin(0)]
        st.apply_rewards(rewards, st.apply_reward)
        st.save()
        base["rewards"] = rewards
        return True

    if method == "sellCards":
        ids = params.get("cardIds") or []
        if isinstance(ids, (int, float, str)):
            ids = [ids]
        ids = {int(x) for x in ids}
        # never sell main / queued cards
        protected = {int(st.main_card_id)}
        for part in str(st.additional_card_ids or "").split(","):
            part = part.strip()
            if part.isdigit():
                protected.add(int(part))
        total = 0
        kept = []
        for c in st.cards:
            cid = int(c.get("cardId") or 0)
            if cid in ids and cid not in protected:
                total += 500 * int(c.get("level") or 1)
            else:
                kept.append(c)
        st.cards = kept
        rewards = [reward_coin(total)] if total else [reward_coin(0)]
        st.apply_rewards(rewards, st.apply_reward)
        st.save()
        base["rewards"] = rewards
        return True

    if method == "useProp":
        _load_prop_meta()
        prop_id = int(params.get("propId") or params.get("metaId") or 0)
        amount = int(params.get("amount") or 1)
        meta = _PROP_META.get(prop_id) or {"effectType": 0, "effectValue": 100}
        if not st.take_prop(prop_id, amount):
            base["retCode"] = 712301  # not enough
            return True
        et = int(meta.get("effectType") or 0)
        ev = float(meta.get("effectValue") or 0)
        rewards = []
        if et == 0:  # EXP ball
            rewards = [reward_exp(int(ev) * amount)]
        elif et == 1:  # ENERGY
            rewards = [reward_energy(int(ev) * amount)]
        elif et == 2:  # EVENT POINT
            rewards = [{"itemType": RE_EVENTPOINT, "amount": int(ev) * amount}]
        else:
            # boxes / misc — give mixed loot
            for _ in range(amount):
                roll = random.random()
                if roll < 0.35:
                    rewards.append(reward_coin(random.randint(200, 800)))
                elif roll < 0.55:
                    rewards.append(reward_prop(400001, random.randint(1, 3)))
                elif roll < 0.75:
                    st.next_equip_id += 1
                    mid = random.choice(_STARTER_EQUIP_METAS)
                    rewards.append({
                        "itemType": RE_EQUIP,
                        "id": st.next_equip_id,
                        "metaId": mid,
                        "level": 1,
                        "exp": 0,
                        "enchantLevel": 0,
                        "enchantNum": 0,
                        "amount": 1,
                    })
                else:
                    rewards.append(reward_coin(random.randint(100, 400)))
        st.apply_rewards(rewards, st.apply_reward)
        st.save()
        base["rewards"] = rewards
        return True

    if method == "buyGrid":
        # inventoryExpandCost is typically gem-based; use a flat 50 gems / +5 grids
        cost = 50
        grids = 5
        if st.gems < cost:
            base["retCode"] = 710513
            return True
        if st.bought_grid_times >= 50:
            base["retCode"] = 713301
            return True
        st.bought_grid_times += 1
        rewards = [reward_grid(grids)]
        st.apply_rewards(rewards, st.apply_reward)
        st.gems = max(0, st.gems - cost)
        st.save()
        base["rewards"] = rewards
        base["requisite"] = {"itemType": RE_GEMS, "amount": cost, "metaId": 0, "id": 0}
        return True

    if method == "setupEquip":
        card_id = int(params.get("cardId") or 0)
        equip_id = int(params.get("equipId") or 0)
        # unequip from any previous card, then attach
        for e in st.equips:
            if int(e.get("equipId") or 0) == equip_id:
                # clear same-slot? keep simple: just set cardId
                old = int(e.get("cardId") or 0)
                e["cardId"] = card_id
                # update card.equipIds lists
                for c in st.cards:
                    cids = list(c.get("equipIds") or [])
                    cids = [x for x in cids if int(x) != equip_id]
                    if int(c.get("cardId") or 0) == card_id:
                        cids.append(equip_id)
                    c["equipIds"] = cids
                break
        st.save()
        return True

    if method in ("adjustTeam", "replaceCard"):
        main = params.get("mainCardId")
        add = params.get("additionalCardIds")
        m, cleaned = apply_team_formation(st, main, add)
        base["mainCardId"] = m
        base["additionalCardIds"] = ",".join(str(x) for x in cleaned)
        return True

    if method == "getUserEmails":
        base.update({
            "sysEmails": [],
            "rewardEmails": [],
            "sysNotices": [],
            "userEmails": [],
            "sysEmailMeta": {},
        })
        return True

    if method == "getFriends":
        base["sharkFriends"] = []
        return True

    if method == "getSharkBeasts":
        base["sharkBeasts"] = []
        return True

    if method == "getSharkBeastFragments":
        base["sharkBeastFragments"] = []
        return True

    if method == "buyGoods":
        _load_shop_meta()
        gid = int(params.get("goodsId") or params.get("id") or 0)
        goods = _SHOP_META.get(gid)
        if not goods:
            # soft success with a cheap prop so UI doesn't hang
            goods = {"itemType": RE_PROP, "metaId": 400001, "amount": 1,
                     "moneyType": RE_GEMS, "discountPrice": 0}
        cost = int(goods.get("discountPrice") or 0)
        money = int(goods.get("moneyType") or RE_GEMS)
        if money == RE_GEMS and st.gems < cost:
            base["retCode"] = 710513
            return True
        if money == RE_COIN and st.coins < cost:
            base["retCode"] = 710513
            return True
        it = int(goods["itemType"])
        mid = int(goods["metaId"])
        amt = int(goods["amount"])
        if it == RE_PROP:
            reward = [reward_prop(mid, amt)]
        elif it == RE_CARD:
            st.next_card_id += 1
            reward = [{
                "itemType": RE_CARD, "id": st.next_card_id, "metaId": mid,
                "amount": 1, "level": 1, "exp": 0,
            }]
        elif it == RE_EQUIP:
            st.next_equip_id += 1
            reward = [{
                "itemType": RE_EQUIP, "id": st.next_equip_id, "metaId": mid,
                "level": 1, "exp": 0, "enchantLevel": 0, "enchantNum": 0,
                "amount": 1,
            }]
        else:
            reward = [reward_prop(mid, amt)]
        st.apply_rewards(reward, st.apply_reward)
        # client also deducts cost; keep server in sync
        if money == RE_GEMS:
            st.gems = max(0, st.gems - cost)
        elif money == RE_COIN:
            st.apply_reward(RE_COIN, -cost)
        st.save()
        base["reward"] = reward
        return True

    if method == "clearMission":
        rounds = int(params.get("clearRounds") or 1)
        mid = int(params.get("missionId") or 100101)
        clear_list = []
        all_rewards = []
        for i in range(max(1, rounds)):
            coin = random.randint(20, 60)
            exp = random.randint(10, 30)
            rr = [reward_coin(coin), reward_exp(exp)]
            if random.random() < 0.25:
                st.next_equip_id += 1
                rr.append({
                    "itemType": RE_EQUIP,
                    "id": st.next_equip_id,
                    "metaId": random.choice(_STARTER_EQUIP_METAS),
                    "level": 1, "exp": 0, "enchantLevel": 0, "enchantNum": 0,
                    "amount": 1,
                })
            clear_list.append({"round": i + 1, "rewards": rr})
            all_rewards.extend(rr)
        # energy cost applied client-side; still apply loot
        st.apply_rewards(all_rewards, st.apply_reward)
        energy_cost = rounds * 2  # match battleSettingConfig.roundConsumeEnergy / missionStepEnergy
        st.energy = max(0, int(st.energy) - energy_cost)
        st.save()
        base["clearMissionRewards"] = clear_list
        return True

    # ----- Equip strengthen / evolve / enchant -----
    if method == "upgradeEquip":
        eid = int(params.get("equipId") or 0)
        eq = _find_equip(st, eid)
        if not eq:
            base["retCode"] = 712501
            return True
        if int(eq.get("level") or 1) >= _user_level_cap(st):
            base["retCode"] = 712509
            return True
        cost = 50 + int(eq.get("level") or 1) * 20
        if st.coins < cost:
            base["retCode"] = 710512
            return True
        st.apply_reward(RE_COIN, -cost)
        base["sharkEquip"] = _bump_equip_level(st, eq, 1)
        st.save()
        return True

    if method == "quickUpgradeEquip":
        eid = int(params.get("equipId") or 0)
        eq = _find_equip(st, eid)
        if not eq:
            base["retCode"] = 712501
            return True
        cap = _user_level_cap(st)
        cur = int(eq.get("level") or 1)
        if cur >= cap:
            base["retCode"] = 712509
            return True
        steps = max(1, cap - cur)
        cost = sum(50 + (cur + i) * 20 for i in range(steps))
        if st.coins < cost:
            # upgrade as many levels as coins allow
            steps = 0
            spent = 0
            while cur + steps < cap:
                step_cost = 50 + (cur + steps) * 20
                if spent + step_cost > st.coins:
                    break
                spent += step_cost
                steps += 1
            if steps <= 0:
                base["retCode"] = 710512
                return True
            cost = spent
        st.apply_reward(RE_COIN, -cost)
        base["sharkEquip"] = _bump_equip_level(st, eq, steps)
        st.save()
        return True

    if method == "upgradeEquipForOneCard":
        ids = params.get("equipIds") or params.get("equipId") or []
        if isinstance(ids, (int, float, str)):
            ids = [ids]
        out = []
        for eid in ids:
            eq = _find_equip(st, eid)
            if not eq:
                continue
            cap = _user_level_cap(st)
            cur = int(eq.get("level") or 1)
            if cur < cap:
                out.append(_bump_equip_level(st, eq, max(1, min(5, cap - cur))))
            else:
                out.append(_copy_equip(eq))
        st.save()
        base["sharkEquips"] = out
        return True

    if method == "evolveEquip":
        eid = int(params.get("equipId") or 0)
        eq = _find_equip(st, eid)
        if not eq:
            base["retCode"] = 712501
            return True
        mid = int(eq.get("metaId") or 0)
        if mid % 10 >= 5:
            base["retCode"] = 712510
            return True
        # client also deducts materials; keep server state in sync cheaply
        base["sharkEquip"] = _evolve_equip_meta(eq)
        st.save()
        return True

    if method in ("equipEnchant", "enchantEquip"):
        eid = int(params.get("equipId") or 0)
        eq = _find_equip(st, eid)
        if not eq:
            base["retCode"] = 712501
            return True
        eq["enchantLevel"] = int(eq.get("enchantLevel") or 0) + 1
        eq["enchantNum"] = int(eq.get("enchantNum") or 0) + 1
        base["sharkEquip"] = _copy_equip(eq)
        st.save()
        return True

    # ----- Card upgrade / train / evolve -----
    if method == "upgradeCard":
        # Client CardComposeRequest: {masterId, slaveIds} — NOT cardId/level.
        # Old stub always +1 level; recompute from material basicExp + converted
        # level exp (mirrors CardComposeScene:getComposeExp).
        cid = int(params.get("masterId") or params.get("cardId")
                  or params.get("id") or st.main_card_id or 1)
        card = _find_card(st, cid)
        if not card:
            base["retCode"] = 712401
            return True
        slave_ids = _normalize_id_list(params.get("slaveIds"))
        main_row = _card_level_row(card.get("level") or 1)
        total_exp = int(main_row["totalExp"]) + int(card.get("exp") or 0)
        coin_cost = 0
        revise = 1  # gameSettingConfig.cardUpgradeCoinRevise default
        eaten = set()
        for sid in slave_ids:
            sid = int(sid)
            if sid == cid or sid in eaten:
                continue
            slave = _find_card(st, sid)
            if not slave:
                continue
            gained = _matter_provide_exp(slave)
            total_exp += gained
            coin_cost += int(gained * revise)
            eaten.add(sid)
        _apply_card_total_exp(card, total_exp)
        if eaten:
            st.cards = [c for c in st.cards
                        if int(c.get("cardId") or 0) not in eaten]
            if int(getattr(st, "main_card_id", 0) or 0) in eaten:
                st.main_card_id = cid
            add_raw = str(getattr(st, "additional_card_ids", "") or "")
            kept = []
            for part in add_raw.split(","):
                part = part.strip()
                if not part:
                    continue
                try:
                    if int(part) not in eaten:
                        kept.append(part)
                except ValueError:
                    kept.append(part)
            st.additional_card_ids = ",".join(kept)
        if coin_cost > 0:
            st.coins = max(0, int(getattr(st, "coins", 0) or 0) - coin_cost)
        base["sharkCard"] = _copy_card(card)
        st.save()
        return True

    if method == "upgradeCardByGeneralExp":
        # {masterId, targetLevel} — spend generalExp to reach target level.
        cid = int(params.get("masterId") or params.get("cardId")
                  or st.main_card_id or 1)
        card = _find_card(st, cid)
        if not card:
            base["retCode"] = 712401
            return True
        target = int(params.get("targetLevel") or 0)
        max_lv = _card_max_level(card.get("metaId"))
        cur = int(card.get("level") or 1)
        if target <= cur:
            target = min(max_lv, cur + 1)
        target = min(target, max_lv)
        main_row = _card_level_row(cur)
        cur_total = int(main_row["totalExp"]) + int(card.get("exp") or 0)
        tgt_row = _card_level_row(target)
        need = max(0, int(tgt_row["totalExp"]) - cur_total)
        # Local revive: don't block on generalExp shortage.
        if hasattr(st, "general_exp"):
            st.general_exp = max(0, int(getattr(st, "general_exp", 0) or 0) - need)
        _apply_card_total_exp(card, cur_total + need)
        base["sharkCard"] = _copy_card(card)
        st.save()
        return True

    if method == "evolveCard":
        cid = int(params.get("cardId") or params.get("masterId")
                  or st.main_card_id or 1)
        slave_id = int(params.get("slaveId") or 0)
        card = _find_card(st, cid)
        if not card:
            base["retCode"] = 712401
            return True
        _load_card_meta()
        mid = int(card.get("metaId") or 0)
        info = _CARD_META.get(mid) or {}
        next_mid = int(info.get("evolutionCardId") or 0)
        # Fallback: metaId+1 when next stage exists in meta table
        if not next_mid and card_meta_exists(mid + 1):
            next_mid = mid + 1
        if not next_mid or not card_meta_exists(next_mid):
            # Already MAX / no further evolution — return current card unchanged
            base["sharkCard"] = _copy_card(card)
            return True
        card["metaId"] = next_mid
        card["cardGroupId"] = card_group_id(next_mid)
        card["cardSkills"] = build_card_skills(next_mid)
        card["level"] = 1
        card["exp"] = 0
        # Consume material card (client also drops it locally)
        if slave_id and slave_id != cid:
            st.cards = [c for c in st.cards
                        if int(c.get("cardId") or 0) != slave_id]
            adds = normalize_additional_card_ids(
                getattr(st, "additional_card_ids", ""))
            st.additional_card_ids = ",".join(
                str(x) for x in adds if int(x) != slave_id)
        base["sharkCard"] = _copy_card(card)
        st.save()
        return True

    if method == "trainCard":
        # response is top-level train deltas (not nested)
        base["attTrainValue"] = random.randint(1, 5)
        base["defTrainValue"] = random.randint(1, 5)
        base["hpTrainValue"] = random.randint(1, 5)
        return True

    if method in ("saveCardTrain", "giveUpCardTrain"):
        cid = int(params.get("cardId") or st.main_card_id or 1)
        card = _find_card(st, cid)
        if not card:
            base["retCode"] = 712401
            return True
        if method == "saveCardTrain":
            card["attTrainValue"] = int(card.get("attTrainValue") or 0) + int(
                params.get("attTrainValue") or random.randint(1, 5))
            card["defTrainValue"] = int(card.get("defTrainValue") or 0) + int(
                params.get("defTrainValue") or random.randint(1, 5))
            card["hpTrainValue"] = int(card.get("hpTrainValue") or 0) + int(
                params.get("hpTrainValue") or random.randint(1, 5))
            card["usedPotential"] = int(card.get("usedPotential") or 0) + 1
        base["sharkCard"] = _copy_card(card)
        st.save()
        return True

    if method in ("splitCard", "synthetizeCard", "cardOn"):
        if method == "splitCard":
            cid = int(params.get("cardId") or 0)
            card = _find_card(st, cid)
            if card and int(cid) != int(st.main_card_id):
                st.cards = [c for c in st.cards if int(c.get("cardId") or 0) != cid]
            base["rewards"] = [reward_coin(500), reward_prop(400001, 2)]
            st.apply_rewards(base["rewards"], st.apply_reward)
            st.save()
        elif method == "synthetizeCard":
            base["rewards"] = [reward_coin(100)]
            st.apply_rewards(base["rewards"], st.apply_reward)
            st.save()
        return True

    # ----- Soft-ack (safe empty payloads only) -----
    if method in ("deleteUserEmails", "deleteSysEmails", "deleteSysNotices",
                  "readSysEmail", "readSysNotice", "readUserEmail",
                  "EmailReadRewardEmail", "readRewardEmail",
                  "batchDeleteEmails", "sendUserEmail",
                  "equipSpirit", "unequipSpirit", "upgradeSpirit", "sellSpirit",
                  "spiritConcentrate", "buySpiritPool",
                  "getEliteInfo", "challengeElite",
                  "getSecretShopList", "exchangeSecretShop",
                  "getPlayerTeamInfo", "getAnnouncementInfo",
                  "getBabelInfo", "lockCard",
                  "upgradeTreasure", "evolveTreasure", "lockTreasure",
                  "getCardBook", "getCardFragments", "getEquipFragments"):
        if method == "getEliteInfo":
            base["eliteInfos"] = []
        if method == "getSecretShopList":
            base["secretShopItems"] = []
            # Prefer canon_server handler; this is a soft fallback only.
            base.setdefault("freeTimes", 5)
            base.setdefault("itemIdList", [])
            base.setdefault("version", 1)
            base.setdefault("lastRefreshSecond", 0)
        if method == "getPlayerTeamInfo":
            base["sharkCards"] = {"sharkCards": list(st.cards)}
            base["sharkEquips"] = {"sharkEquips": list(st.equips)}
            base["sharkTreasures"] = {"sharkTreasures": []}
            base["sharkUserBattleArray"] = []
        if method == "getBabelInfo":
            base["babelInfo"] = {"floor": 1, "maxFloor": 50}
        if method == "getCardBook":
            base["sharkCardBook"] = {
                "cardMetaIds": [int(c.get("metaId") or 0) for c in st.cards],
                "equipMetaIds": [int(e.get("metaId") or 0) for e in st.equips],
            }
            base["cardBookAchievement"] = []
        if method in ("getCardFragments", "getEquipFragments"):
            base["fragments"] = []
            base["sharkCardFragments"] = []
            base["sharkEquipFragments"] = []
        if method in ("upgradeTreasure", "evolveTreasure") and params.get("treasureId"):
            # avoid nil sharkTreasure crash if panel opened
            base["sharkTreasure"] = {
                "treasureId": int(params.get("treasureId") or 1),
                "metaId": int(params.get("metaId") or 281012),
                "level": 1, "cardId": 0,
                "addPotential": 0, "addGemPotential": 0,
                "usedPotential": 0, "lock": False,
            }
        return True

    # Catch-all for remaining *Equip / *Card methods that clients assume return
    # an entity: pick the matching inventory row by *Id and echo it back.
    low = method.lower()
    if "equip" in low and ("upgrade" in low or "evolve" in low or "enchant" in low
                           or "setup" in low or "quick" in low):
        eid = params.get("equipId") or params.get("id")
        ids = params.get("equipIds")
        if ids:
            if isinstance(ids, (int, float, str)):
                ids = [ids]
            arr = []
            for i in ids:
                eq = _find_equip(st, i)
                if eq:
                    arr.append(_copy_equip(eq))
            base["sharkEquips"] = arr
            if len(arr) == 1:
                base["sharkEquip"] = arr[0]
            return True
        if eid is not None:
            eq = _find_equip(st, eid)
            if eq:
                base["sharkEquip"] = _copy_equip(eq)
                return True
    if "card" in low and ("upgrade" in low or "evolve" in low or "train" in low
                         or "save" in low or "compose" in low):
        cid = params.get("cardId") or params.get("id") or st.main_card_id
        card = _find_card(st, cid) if cid is not None else None
        if card:
            base["sharkCard"] = _copy_card(card)
            return True

    return False
