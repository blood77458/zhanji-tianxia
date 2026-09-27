#!/usr/bin/env python3
"""
Canon (战姬天下) compatible server -- protocol implementation.

Implements the client's actual wire protocol, reverse-engineered from the APK:

  HTTP:
    GET  /staticVersion        -> JSON resource settings (schema recovered from
                                  HeCore::ResConfig::parseStaticSettingsJson):
                                  static_url_root, config_md5, need_download,
                                  can_download, download_url, langs, resolutions, ref
    POST /sessionKey/init      -> session key
    POST /protocol?uid=<uid>   -> main RPC:  body = headercvt(zlib(amf3(payload)))
    *    /check/* /getLoginServer /loginAccount/* -> platform login stubs

  RPC payload (AMF3):
    request  = [ header, [ {method=<endpoint>, ...params}, ... ] ]
    response = [ {errCode, ts, uk, st, others}, [ {method, retCode, ...data} ], [events] ]

Everything unknown is logged verbatim (hex + ascii) so the remaining pieces
(headercvt framing, per-endpoint schemas) can be closed iteratively.
"""
import json, os, sys, time, zlib, struct, threading, traceback, hashlib, random, re
import socket, socketserver
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Bag / team / mail / shop / sweep feature handlers (persisted inventory).
import features as _feat
import admin_api as _admin

ROOT = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(ROOT, "server.log")
RPC_LOG = os.path.join(ROOT, "rpc_payloads.jsonl")

# The client's resource manifest is content-addressed:
#   assets/static_config.<md5>.xml   and it verifies the content against <md5>.
# If our /staticVersion advertises a different config_md5, the client tries to
# download the "new" manifest and errors out (dynamicUpdateNetError).
# So we discover the real md5 from the packaged APK at startup.
MANIFEST_MD5 = os.environ.get("CANON_MANIFEST_MD5", "")
MANIFEST_PATH = ""
_MANIFEST_ENTRY = ""

# Auto-discover from the *newest* packaged APK, so re-packing the client (which
# renames the manifest) needs no code change here.  Every repack bumps mtime.
_work = os.path.join(os.path.dirname(ROOT), "work")
_cands = []
if os.path.isdir(_work):
    for _f in os.listdir(_work):
        if _f.lower().endswith(".apk"):
            _cands.append(os.path.join(_work, _f))
_cands.sort(key=lambda p: os.path.getmtime(p), reverse=True)

import zipfile as _zip
for _p in _cands:
    try:
        with _zip.ZipFile(_p) as _z:
            for _n in _z.namelist():
                m = re.search(r"assets/static_config\.([0-9a-f]{32})\.xml$", _n)
                if m:
                    MANIFEST_MD5 = MANIFEST_MD5 or m.group(1)
                    MANIFEST_PATH = _p
                    _MANIFEST_ENTRY = _n
                    break
    except Exception:
        continue
    if MANIFEST_MD5:
        break

_lock = threading.Lock()


def log(*a):
    msg = " ".join(str(x) for x in a)
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    with _lock:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")


def hexdump(b, width=32, limit=4096):
    b = b[:limit]
    out = []
    for i in range(0, len(b), width):
        c = b[i:i + width]
        out.append(f"    {i:06x}  " + " ".join(f"{x:02x}" for x in c).ljust(width * 3)
                   + "  |" + "".join(chr(x) if 32 <= x < 127 else "." for x in c) + "|")
    return "\n".join(out)


# ----------------------------------------------------------------------------
# headercvt: the outer framing the client applies around /protocol bodies.
#
# Recovered from libhegame.so (module "headercvt", convertD @0x30edf8,
# convertU @0x30ed8c, registered in the luaL_Reg table at 0x682a80):
#
#   wrap(input)   = 00 64 || MD5(C16 || X) || X      where X = input ^ 0xC3
#   unwrap(data)  = data[18:] ^ 0xC3                 (md5 is NOT verified)
#
# C16 is a 16-byte constant read from .rodata; verified by reproducing the
# client's own request bytes exactly.
#
# NOTE the keys are ASYMMETRIC -- the client uses a different constant in each
# direction, so we must mirror each one:
#     client convertD (requests)  : eors r2, mvn(0x3c)  -> XOR 0xC3
#     client convertU (responses) : eor  r1, #0x71      -> XOR 0x71
# Verified: the client's own request body decodes with 0xC3, and it rejects a
# response encoded with 0xC3 (zlib checksum error) but accepts 0x71.
# ----------------------------------------------------------------------------

HDRCVT_MAGIC = b"\x00\x64"
HDRCVT_XOR_REQ = 0xC3      # client -> server
HDRCVT_XOR_RESP = 0x71     # server -> client
HDRCVT_C16 = bytes.fromhex("255e262a4051306a6533356937717039")


def headercvt_wrap(data: bytes) -> bytes:
    """server -> client (mirrors the client's convertU, XOR 0x71)"""
    x = bytes(c ^ HDRCVT_XOR_RESP for c in data)
    return HDRCVT_MAGIC + hashlib.md5(HDRCVT_C16 + x).digest() + x


def headercvt_unwrap(body: bytes) -> bytes:
    """client -> server (mirrors the client's convertD, XOR 0xC3)"""
    if len(body) <= 18:
        raise ValueError(f"headercvt: body too short ({len(body)})")
    return bytes(c ^ HDRCVT_XOR_REQ for c in body[18:])


# ----------------------------------------------------------------------------
# AMF3 codec.
#
# Encoding side: the client decodes our responses with a lua-amf3 build whose
# decoder accepts BOTH arrays and objects; we emit associative arrays (0x09)
# because that is unambiguous and already proven to work (systemInfo).
#
# Decoding side: the client's own encoder emits OBJECTS (0x0A) with dynamic
# traits, so the reader must handle that form too.
# ----------------------------------------------------------------------------

AMF3_UNDEFINED = 0x00
AMF3_NULL      = 0x01
AMF3_FALSE     = 0x02
AMF3_TRUE      = 0x03
AMF3_INTEGER   = 0x04
AMF3_DOUBLE    = 0x05
AMF3_STRING    = 0x06
AMF3_XMLDOC    = 0x07
AMF3_DATE      = 0x08
AMF3_ARRAY     = 0x09
AMF3_OBJECT    = 0x0A
AMF3_XML       = 0x0B
AMF3_BYTEARRAY = 0x0C

AMF3_MIN_INT = -268435456
AMF3_MAX_INT = 268435455


class AMF3Reader:
    """Mirror of lua-amf3 1.0.2 amf3_decode.c."""

    def __init__(self, data):
        self.d = data
        self.i = 0
        self.sref = []      # string refs (1-based in C, list here)
        self.oref = []      # object/array refs
        self.classes = []   # AMF3 traits (class) definitions

    def u8(self):
        v = self.d[self.i]; self.i += 1; return v

    def u29(self):
        res = 0
        for ofs in range(4):
            tmp = self.u8()
            if ofs == 3:
                res = ((res << 8) | (tmp & 0xFF)) & 0xFFFFFFFF
                break
            res = ((res << 7) | (tmp & 0x7F)) & 0xFFFFFFFF
            if not (tmp & 0x80):
                break
        return res

    def _ref(self, table):
        pfx = self.u29()
        if pfx & 1:
            return pfx >> 1
        idx = (pfx >> 1)
        return table[idx] if idx < len(table) else None

    def read_string(self):
        v = self._ref(self.sref)
        if v is None or isinstance(v, str):     # reference
            return v if v is not None else ""
        ln = v
        s = self.d[self.i:self.i + ln].decode("utf-8", "replace")
        self.i += ln
        if ln:
            self.sref.append(s)
        return s

    def read_value(self):
        t = self.u8()
        if t in (AMF3_UNDEFINED, AMF3_NULL):
            return None
        if t == AMF3_FALSE:
            return False
        if t == AMF3_TRUE:
            return True
        if t == AMF3_INTEGER:
            i = self.u29()
            if i & 0x10000000:
                i -= 0x20000000
            return i
        if t == AMF3_DOUBLE:
            v = struct.unpack_from(">d", self.d, self.i)[0]; self.i += 8
            return v
        if t == AMF3_STRING:
            return self.read_string()
        if t in (AMF3_XML, AMF3_XMLDOC, AMF3_BYTEARRAY):
            return self.read_string()
        if t == AMF3_DATE:
            self._ref(self.oref)
            v = struct.unpack_from(">d", self.d, self.i)[0]; self.i += 8
            self.oref.append(v)
            return v
        if t == AMF3_ARRAY:
            v = self._ref(self.oref)
            if v is not None and not isinstance(v, int):
                return v
            ln = v if v is not None else 0
            out = {}
            self.oref.append(out)
            while True:                     # associative portion
                k = self.read_string()
                if not k:
                    break
                out[k] = self.read_value()
            for n in range(1, ln + 1):      # dense portion
                out[n] = self.read_value()
            return out
        if t == AMF3_OBJECT:
            # U29O bit layout (verified against the client's own requests):
            #   bit0 = inline (0 -> object reference)
            #   bit1 = 1 new class definition / 0 reference to a previous class
            #   if new : bit2 = externalizable, bit3 = dynamic, bits4+ = member count
            #   if ref : traits index = (u29 >> 2)
            u = self.u29()
            if not (u & 1):
                idx = u >> 1
                return self.oref[idx] if idx < len(self.oref) else None
            if (u >> 1) & 1:                          # new class definition
                f = u >> 2
                ext = f & 1
                dynamic = (f >> 1) & 1
                count = f >> 2
                cls = self.read_string()
                keys = [self.read_string() for _ in range(count)]
                traits = (cls, keys, dynamic, ext)
                self.classes.append(traits)
            else:                                     # reuse a class
                ti = u >> 2
                if ti >= len(self.classes):
                    return None
                traits = self.classes[ti]
            cls, keys, dynamic, ext = traits
            obj = {}
            self.oref.append(obj)
            if ext:
                obj["__data"] = self.read_value()
            else:
                for k in keys:
                    obj[k] = self.read_value()
                if dynamic:
                    while True:
                        k = self.read_string()
                        if not k:
                            break
                        obj[k] = self.read_value()
            if cls:
                obj["__class"] = cls
            return obj
        return None


class AMF3Writer:
    """Mirror of lua-amf3 1.0.2 amf3_encode.c (arrays only)."""

    def __init__(self):
        self.out = bytearray()

    def u8(self, v):
        self.out.append(v & 0xFF)

    def u29(self, val):
        """Match lua-amf3 encodeU29()."""
        val &= 0x1FFFFFFF
        o = self.out
        if val <= 0x7F:
            o.append(val)
        elif val <= 0x3FFF:
            o.append(((val >> 7) & 0x7F) | 0x80)
            o.append(val & 0x7F)
        elif val <= 0x1FFFFF:
            o.append(((val >> 14) & 0x7F) | 0x80)
            o.append(((val >> 7) & 0x7F) | 0x80)
            o.append(val & 0x7F)
        else:
            o.append(((val >> 22) & 0x7F) | 0x80)
            o.append(((val >> 15) & 0x7F) | 0x80)
            o.append(((val >> 8) & 0x7F) | 0x80)
            o.append(val & 0xFF)

    def w_string(self, s):
        if s is None:
            s = ""
        data = s.encode("utf-8")
        self.u29((len(data) << 1) | 1)
        self.out += data

    def w_value(self, v):
        if v is None:
            self.u8(AMF3_NULL)
        elif v is True:
            self.u8(AMF3_TRUE)
        elif v is False:
            self.u8(AMF3_FALSE)
        elif isinstance(v, int):
            if AMF3_MIN_INT <= v <= AMF3_MAX_INT:
                self.u8(AMF3_INTEGER); self.u29(v)
            else:
                self.u8(AMF3_DOUBLE); self.out += struct.pack(">d", float(v))
        elif isinstance(v, float):
            i = int(v)
            if float(i) == v and AMF3_MIN_INT <= i <= AMF3_MAX_INT:
                self.u8(AMF3_INTEGER); self.u29(i)
            else:
                self.u8(AMF3_DOUBLE); self.out += struct.pack(">d", v)
        elif isinstance(v, str):
            self.u8(AMF3_STRING); self.w_string(v)
        elif isinstance(v, (list, tuple)):
            # dense table
            self.u8(AMF3_ARRAY)
            self.u29((len(v) << 1) | 1)
            self.u8(0x01)                    # empty associative portion
            for x in v:
                self.w_value(x)
        elif isinstance(v, dict):
            # associative table: dense length 0, then string key/value pairs
            self.u8(AMF3_ARRAY)
            self.u8(0x01)                    # dense length 0
            for k, val in v.items():
                self.w_string(str(k))
                self.w_value(val)
            self.u8(0x01)                    # terminator
        else:
            self.u8(AMF3_UNDEFINED)

    def w_object(self, d):
        """
        AMF3 *object* (marker 0x0A) as the client's own encoder emits it, used
        for the realtime/TCP channel.

        Verified byte-for-byte against a captured TCPManager login frame:
            0a                      object marker
            0b                      u29 traits: inline | new-class | dynamic, 0 sealed
            01                      class name "" (u29 (0<<1)|1)
            <key><value> ...        dynamic members
            01                      empty key terminates the member list
        """
        self.u8(AMF3_OBJECT)
        # u = inline(1) | new_class(1<<1) | (f << 2),  f = ext | dynamic<<1 | count<<2
        f = 0 | (1 << 1) | (0 << 2)          # not externalizable, dynamic, 0 sealed
        self.u29(1 | (1 << 1) | (f << 2))
        self.w_string("")                     # anonymous class
        for k, v in d.items():
            self.w_string(str(k))
            self.w_value(v)
        self.w_string("")                     # end of dynamic members

    def bytes(self):
        return bytes(self.out)


# ----------------------------------------------------------------------------
# headercvt: outer framing applied by the client's C module.
# Unknown precisely -> we log raw bodies; these helpers try the common shapes.
# ----------------------------------------------------------------------------

def try_decode_body(raw: bytes):
    """Attempt to peel framing + zlib and return (amf3_bytes, note)."""
    notes = []
    # 1) maybe zlib directly
    for off in (0, 4, 8, 16):
        cand = raw[off:]
        if len(cand) > 2 and cand[0] == 0x78:
            try:
                return zlib.decompress(cand), f"zlib at +{off}"
            except Exception:
                pass
    # 2) zlib anywhere in the first 64 bytes
    for off in range(0, min(64, len(raw))):
        if raw[off] == 0x78:
            try:
                return zlib.decompress(raw[off:]), f"zlib at +{off}"
            except Exception:
                pass
    return raw, "raw (no zlib found)"


def encode_body(amf3_bytes: bytes) -> bytes:
    return zlib.compress(amf3_bytes)


# ----------------------------------------------------------------------------
# Server state
# ----------------------------------------------------------------------------

# Persist across server restarts so guest login does not force createUser +
# opening dialogue every launch.  LoginScene.lua:349 -- uid=="1" => newbie.
_USER_STATE_PATH = os.path.join(ROOT, "user_state.json")

# ResourceEnum (RewardManager.lua) -- needed early for State.apply_reward
_RE_COIN = 1
_RE_EXP = 4
_RE_EQUIP = 6

# user_level[level].exp — amount needed to leave that level (RewardManager loop).
_USER_LEVEL_EXP = {}


def _init_user_level():
    global _USER_LEVEL_EXP
    if _USER_LEVEL_EXP:
        return
    cfg = os.path.join(os.path.dirname(ROOT), "work", "luasrc", "canon", "configs")
    if not os.path.isdir(cfg):
        return
    for fn in os.listdir(cfg):
        if not fn.startswith("user_level."):
            continue
        text = open(os.path.join(cfg, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\[(\d+)\]=\{level=\d+,exp=(\d+)", text):
            _USER_LEVEL_EXP[int(m.group(1))] = int(m.group(2))
        break


def sync_user_level(st):
    """Mirror RewardManager EXP loop: spend exp into level-ups."""
    _init_user_level()
    if not _USER_LEVEL_EXP:
        return False
    max_lv = max(_USER_LEVEL_EXP.keys())
    changed = False
    while True:
        lv = int(st.level or 1)
        need = _USER_LEVEL_EXP.get(lv)
        if need is None or lv >= max_lv:
            break
        if int(st.exp or 0) < need:
            break
        st.exp = int(st.exp) - need
        st.level = lv + 1
        changed = True
    return changed


class State(_feat.InventoryMixin):
    def __init__(self):
        _feat.InventoryMixin.__init__(self)
        self._lock = threading.RLock()
        self.session_key = "canon-local-session-%d" % random.randint(100000, 999999)
        # accountId / uid MUST be a positive decimal string: the client runs
        # tonumber(fields[1]) and rejects anything <= 0 ("-1" == new user).
        self.account_id = "100001"
        self.uid = "100001"
        self.uk = "local-uk-0001"
        self.uuid = "local-uuid-0001"
        self.token = ""
        self.platform_uid = "6249c4ae795bd679"
        self.counter = 0
        self.server_time = int(time.time())
        self.pending_nickname = ""
        # False => loginServer returns uid "1" (CreateCharacterScene).
        # True  => returns real uid; LoginScene goes straight to MainMenuScene
        #          (skips create + DialogOnce opening).
        self.user_created = False
        self.coins = 100000
        self.exp = 0
        self.level = 1
        self.energy = 100
        self.general_exp = 0
        # Chapter / 闯关 progress — CountryManager reads these from gameInit.
        self.mission_context = {
            "missionId": 100101,
            "finishedStep": 0,
            "fightLose": False,
            "routeId": 1,
        }
        self.scene_process = {
            "uid": "100001",
            "finishedCountryIds": [],
            "sceneCountries": [],
            "maxFinishedMissionId": 0,
            "lastClearTime": 0,
        }
        self.mission_completes = []
        # Charge / 充值累计钻石 + 已领累充档位 (gainChargeMoneyReward)
        self.recharge_gems = 0
        self.gained_charge_money_reward_list = []
        self._load()

    def apply_reward(self, item_type, amount):
        """Mirror RewardManager:getReward for the currencies we persist."""
        amount = int(amount)
        with self._lock:
            if item_type == _RE_COIN:
                self.coins = int(self.coins) + amount
                if self.coins < 0:
                    self.coins = 0
            elif item_type == _RE_EXP:
                self.exp = int(self.exp) + amount
                if self.exp < 0:
                    self.exp = 0
                sync_user_level(self)
            elif item_type == _feat.RE_ENERGY:
                self.energy = int(self.energy) + amount
                if self.energy < 0:
                    self.energy = 0
            elif item_type == _feat.RE_GEMS:
                self.gems = int(self.gems) + amount
                if self.gems < 0:
                    self.gems = 0
            self.save()

    def _load(self):
        try:
            with open(_USER_STATE_PATH, "r", encoding="utf-8-sig") as f:
                d = json.load(f)
            self.user_created = bool(d.get("user_created"))
            self.pending_nickname = str(d.get("nickname") or "")
            if d.get("uid"):
                self.uid = str(d["uid"])
                self.account_id = str(d.get("account_id") or d["uid"])
            if "coins" in d:
                self.coins = int(d["coins"])
            if "exp" in d:
                self.exp = int(d["exp"])
            if "level" in d:
                self.level = int(d["level"])
            if "energy" in d:
                self.energy = int(d["energy"])
            if "general_exp" in d:
                self.general_exp = int(d["general_exp"])
            elif "generalExp" in d:
                self.general_exp = int(d["generalExp"])
            # Chapter progress
            mc = d.get("mission_context") or d.get("sharkMissionContext")
            if isinstance(mc, dict) and mc.get("missionId"):
                self.mission_context = {
                    "missionId": int(mc.get("missionId") or 100101),
                    "finishedStep": int(mc.get("finishedStep") or 0),
                    "fightLose": bool(mc.get("fightLose") or False),
                    "routeId": int(mc.get("routeId") or 1),
                }
            sp = d.get("scene_process") or d.get("sharkSceneProcess")
            if isinstance(sp, dict):
                self.scene_process = {
                    "uid": str(sp.get("uid") or self.uid),
                    "finishedCountryIds": list(sp.get("finishedCountryIds") or []),
                    "sceneCountries": list(sp.get("sceneCountries") or []),
                    "maxFinishedMissionId": int(sp.get("maxFinishedMissionId") or 0),
                    "lastClearTime": int(sp.get("lastClearTime") or 0),
                }
            else:
                self.scene_process["uid"] = str(self.uid)
            mcomp = d.get("mission_completes") or d.get("missionCompletes")
            if isinstance(mcomp, list):
                self.mission_completes = list(mcomp)
            if "recharge_gems" in d:
                self.recharge_gems = int(d.get("recharge_gems") or 0)
            elif "rechargeGems" in d:
                self.recharge_gems = int(d.get("rechargeGems") or 0)
            gcm = d.get("gained_charge_money_reward_list") or d.get("gainedChargeMoneyRewardList")
            if isinstance(gcm, list):
                self.gained_charge_money_reward_list = [int(x) for x in gcm]
            self.load_inv(d)
            # Exp may have been accumulated without leveling — sync now.
            if sync_user_level(self):
                self.save()
            log(f"  loaded user_state: created={self.user_created} "
                f"nick={self.pending_nickname!r} uid={self.uid} "
                f"coins={self.coins} exp={self.exp} level={self.level} "
                f"cards={len(self.cards)} equips={len(self.equips)} "
                f"props={len(self.props)} "
                f"mission={self.mission_context.get('missionId')} "
                f"step={self.mission_context.get('finishedStep')} "
                f"maxFin={self.scene_process.get('maxFinishedMissionId')} "
                f"rechargeGems={self.recharge_gems}")
        except FileNotFoundError:
            pass
        except Exception as e:
            log(f"  user_state load failed: {e!r}")

    def save(self):
        """Atomic write so ThreadingHTTPServer / dual-process races cannot
        truncate inventory mid-write.  Callers that mutate inventory should
        hold self._lock around mutate+save; save itself is also locked."""
        try:
            with self._lock:
                data = {
                    "user_created": self.user_created,
                    "nickname": self.pending_nickname,
                    "uid": self.uid,
                    "account_id": self.account_id,
                    "coins": self.coins,
                    "exp": self.exp,
                    "level": self.level,
                    "energy": self.energy,
                    "general_exp": int(getattr(self, "general_exp", 0) or 0),
                    "mission_context": dict(self.mission_context),
                    "scene_process": dict(self.scene_process),
                    "mission_completes": list(self.mission_completes),
                    "recharge_gems": int(self.recharge_gems),
                    "gained_charge_money_reward_list": list(
                        self.gained_charge_money_reward_list),
                }
                data.update(self.dump_inv())
                tmp = _USER_STATE_PATH + ".tmp"
                with open(tmp, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                    f.flush()
                    os.fsync(f.fileno())
                os.replace(tmp, _USER_STATE_PATH)
        except Exception as e:
            log(f"  user_state save failed: {e!r}")


ST = State()


# Drop packs / battle helpers continue below — _RE_* already defined above.

# Per-tile stamina cost. Client deducts DataManager.GameMetaData.battleSettingConfig
# .missionStepEnergy locally in ChapterMapScene:showDecreaseEnergy; server must
# match so gameInit energy stays consistent after re-login.
MISSION_STEP_ENERGY = 2

# missionId -> highest step number in battle_chapter_event (for maxFinishedMissionId)
_CHAPTER_MISSION_LAST_STEP = {}


def _init_chapter_event_meta():
    global _CHAPTER_MISSION_LAST_STEP
    if _CHAPTER_MISSION_LAST_STEP:
        return
    cfg = os.path.join(os.path.dirname(ROOT), "work", "luasrc", "canon", "configs")
    if not os.path.isdir(cfg):
        return
    for fn in os.listdir(cfg):
        if not fn.startswith("battle_chapter_event."):
            continue
        text = open(os.path.join(cfg, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\{missionId=(\d+),step=(\d+),", text):
            mid, step = int(m.group(1)), int(m.group(2))
            prev = _CHAPTER_MISSION_LAST_STEP.get(mid, 0)
            if step > prev:
                _CHAPTER_MISSION_LAST_STEP[mid] = step
        break
    log(f"  chapter events: {len(_CHAPTER_MISSION_LAST_STEP)} missions indexed")


def _ensure_scene_country(st, mission_id):
    """Mirror CountryManager.moveToNextStep sceneCountries seeding (minimal)."""
    mid = int(mission_id)
    chapter_id = mid // 100
    # battle_country ids are 10/20/… (chapterId // 100), NOT 100.
    country_id = chapter_id // 100
    countries = list(st.scene_process.get("sceneCountries") or [])
    # Drop corrupt countryId==100 seeds from earlier builds.
    countries = [c for c in countries if int(c.get("countryId") or 0) != 100]
    country = None
    for c in countries:
        if int(c.get("countryId") or 0) == country_id:
            country = c
            break
    if country is None:
        country = {
            "countryId": country_id,
            "sceneChapters": [{
                "chapterId": chapter_id,
                "sceneMissions": [{
                    "missionId": mid, "star": 0, "score": 0,
                }],
                "finish": False,
                "finishReward": False,
            }],
        }
        countries.append(country)
        st.scene_process["sceneCountries"] = countries
        return
    chapters = list(country.get("sceneChapters") or [])
    chapter = None
    for ch in chapters:
        if int(ch.get("chapterId") or 0) == chapter_id:
            chapter = ch
            break
    if chapter is None:
        chapter = {
            "chapterId": chapter_id,
            "sceneMissions": [{
                "missionId": mid, "star": 0, "score": 0,
            }],
            "finish": False,
            "finishReward": False,
        }
        chapters.append(chapter)
        country["sceneChapters"] = chapters
        st.scene_process["sceneCountries"] = countries
        return
    missions = list(chapter.get("sceneMissions") or [])
    if not any(int(m.get("missionId") or 0) == mid for m in missions):
        missions.append({"missionId": mid, "star": 0, "score": 0})
        chapter["sceneMissions"] = missions
    st.scene_process["sceneCountries"] = countries


def _reconcile_chapter_progress():
    """If unlock UI (maxFinishedMissionId) is ahead of missionContext, snap
    context forward so ChapterMapScene opens at the frontier — not mission 1."""
    _init_chapter_event_meta()
    max_fin = int(ST.scene_process.get("maxFinishedMissionId") or 0)
    mid = int(ST.mission_context.get("missionId") or 100101)
    step = int(ST.mission_context.get("finishedStep") or 0)
    route = int(ST.mission_context.get("routeId") or 1)
    changed = False
    if max_fin and mid < max_fin:
        last = int(_CHAPTER_MISSION_LAST_STEP.get(max_fin) or 0)
        ST.mission_context = {
            "missionId": max_fin,
            "finishedStep": last or step,
            "fightLose": False,
            "routeId": route,
        }
        changed = True
        mid, step = max_fin, last or step
    # Normalize sceneCountries countryId
    raw = list(ST.scene_process.get("sceneCountries") or [])
    cleaned = [c for c in raw if int(c.get("countryId") or 0) != 100]
    if len(cleaned) != len(raw):
        ST.scene_process["sceneCountries"] = cleaned
        changed = True
    if mid:
        _ensure_scene_country(ST, mid)
    return changed


def _apply_chapter_step(params, deduct_energy=True):
    """Persist missionId/step/routeId from trigger*Event and deduct stamina.

    Never regress the resume pointer: maxFinishedMissionId unlock UI can stay
    high while a rewound missionContext would open the map at tile 1.
    Replays of already-cleared missions still cost energy but do not move the
    resume cursor backward.
    """
    _init_chapter_event_meta()
    mid = int(params.get("missionId")
              or ST.mission_context.get("missionId")
              or 100101)
    step = int(params.get("step") or ST.mission_context.get("finishedStep") or 0)
    route = int(params.get("routeId") or ST.mission_context.get("routeId") or 1)
    with ST._lock:
        old_mid = int(ST.mission_context.get("missionId") or 100101)
        old_step = int(ST.mission_context.get("finishedStep") or 0)
        max_fin = int(ST.scene_process.get("maxFinishedMissionId") or 0)
        # Advance resume pointer only when progress moves forward.
        advance = False
        if mid > old_mid or (mid == old_mid and step > old_step):
            advance = True
        if mid < max_fin and not (mid > old_mid or (mid == old_mid and step > old_step)):
            # Replay of an older cleared mission — keep frontier context.
            advance = False
        if mid < old_mid or (mid == old_mid and step < old_step):
            advance = False
        if advance:
            ST.mission_context = {
                "missionId": mid,
                "finishedStep": step,
                "fightLose": False,
                "routeId": route,
            }
            last = int(_CHAPTER_MISSION_LAST_STEP.get(mid) or 0)
            if last and step >= last:
                if mid > max_fin:
                    ST.scene_process["maxFinishedMissionId"] = mid
            _ensure_scene_country(ST, mid)
        ST.scene_process["uid"] = str(ST.uid)
        if deduct_energy:
            ST.energy = max(0, int(ST.energy) - MISSION_STEP_ENERGY)
        ST.save()
    log(f"  chapter progress: mission={mid} step={step} route={route} "
        f"advance={advance} ctx={ST.mission_context.get('missionId')}/"
        f"{ST.mission_context.get('finishedStep')} "
        f"energy={ST.energy} maxFin={ST.scene_process.get('maxFinishedMissionId')}")


# Chapter dropPackId 55/56/570001 live ONLY on the original game server —
# not shipped in client reward_package.lua.  Stub early-game equips so
# BattleResultPanel can show EQUIP (itemType=6) drops.
#   210011 柳叶刀  210041 蛇头戟  220011 锁子甲  230011 青鬃
_DROP_PACKS = {
    550001: [210011, 210041, 220011],
    560001: [220011, 230011, 210011],
    570001: [210041, 230011],
}
_next_equip_id = 100


def _reward(item_type, amount):
    # amount as int — RewardManager tonumber() handles both; keep int for AMF.
    return {"itemType": int(item_type), "amount": int(amount)}


def _equip_reward(meta_id):
    """RewardManager:getReward EQUIP branch needs id/metaId/level/exp."""
    ST.next_equip_id += 1
    eid = ST.next_equip_id
    return {
        "itemType": _RE_EQUIP,
        "id": eid,
        "metaId": int(meta_id),
        "level": 1,
        "exp": 0,
        "enchantLevel": 0,
        "enchantNum": 0,
        "amount": 1,
    }


def _map_event_rewards(kind="coin", chapter_id=None):
    """Chapter map tile rewards. Coin amounts follow battle_event_coin ranges.

    Card tiles MUST return ResourceEnum.CARD with metaId — ChapterMapScene
    popuoutCard indexes MetaManager.card_meta[aReward.metaId] and SIGKILLs
    if we stub with coins (no metaId).
    """
    if kind == "exp":
        amt = 20
        ST.apply_reward(_RE_EXP, amt)
        return [_reward(_RE_EXP, amt)]
    if kind == "card":
        # Prefer a low/mid rare stage-1 card the player does not already own.
        _init_gacha()
        owned = {int(c.get("metaId") or 0) for c in ST.cards}
        pool = []
        for rare in (2, 3, 4):
            for mid in _CARDS_BY_RARE.get(rare) or []:
                if mid not in owned:
                    pool.append(mid)
        if not pool:
            for rare in (2, 3, 4, 5, 6):
                pool.extend(_CARDS_BY_RARE.get(rare) or [])
        if not pool:
            pool = [STARTER_CARD_META]
        reward = _new_card_reward(random.choice(pool))
        # Persist to server inventory (client also inserts via RewardManager)
        ST.apply_rewards([reward], ST.apply_reward)
        ST.save()
        return [reward]
    # coin
    lo, hi = 5, 7
    if chapter_id and chapter_id in _BATTLE_COIN:
        lo, hi = _BATTLE_COIN[chapter_id]
    elif chapter_id:
        # fall back to chapter/100*100+chapter%100 family, e.g. 100101 -> 1001
        cid = int(chapter_id) // 100
        if cid in _BATTLE_COIN:
            lo, hi = _BATTLE_COIN[cid]
    amt = random.randint(lo, hi)
    ST.apply_reward(_RE_COIN, amt)
    return [_reward(_RE_COIN, amt)]


# ---------------------------------------------------------------------------
# Chapter-battle meta (loaded from client Lua configs)
# ---------------------------------------------------------------------------
_CONFIGS = os.path.join(os.path.dirname(ROOT), "work", "luasrc", "canon", "configs")
_BATTLE_MONSTER = {}       # id -> {cardId, reviseHP, reviseATT, reviseDEF}
_BATTLE_MONSTER_GROUP = {} # id -> [monsterId, ...]
_BATTLE_EVENT = {}         # missionId -> {monsterGroupId, monsterLevel, coin, exp, ...}
_BATTLE_COIN = {}          # chapterId -> (min, max)


def _load_lua_table_file(path, pattern):
    """Pull `{id=N, key=val, ...}` rows out of a Lua config via regex."""
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except FileNotFoundError:
        log(f"  battle meta missing: {path}")
        return
    for m in re.finditer(pattern, text):
        yield m


def _init_battle_meta():
    global _BATTLE_MONSTER, _BATTLE_MONSTER_GROUP, _BATTLE_EVENT, _BATTLE_COIN
    if _BATTLE_MONSTER:
        return
    # battle_monster
    for fn in os.listdir(_CONFIGS) if os.path.isdir(_CONFIGS) else []:
        fp = os.path.join(_CONFIGS, fn)
        if fn.startswith("battle_monster.") and "group" not in fn:
            for m in re.finditer(
                r"\[(\d+)\]=\{id=\d+,cardId=(\d+),[^}]*?"
                r"reviseHP=([\d.]+),reviseATT=([\d.]+),reviseDEF=([\d.]+)",
                open(fp, encoding="utf-8", errors="replace").read()):
                mid, cid, hp, att, deff = m.groups()
                _BATTLE_MONSTER[int(mid)] = {
                    "cardId": int(cid),
                    "reviseHP": float(hp),
                    "reviseATT": float(att),
                    "reviseDEF": float(deff),
                }
        elif fn.startswith("battle_monster_group."):
            for m in re.finditer(
                r"\[(\d+)\]=\{id=\d+,monsterIdList=\"([^\"]+)\"\}",
                open(fp, encoding="utf-8", errors="replace").read()):
                gid, lst = m.groups()
                ids = [int(x) for x in lst.split("|") if x and x != "0"]
                _BATTLE_MONSTER_GROUP[int(gid)] = ids
        elif fn.startswith("battle_event_battle."):
            raw = open(fp, encoding="utf-8", errors="replace").read()
            for m in re.finditer(
                r"\{missionId=(\d+),missionType=(\d+),monsterGroupId=(\d+),"
                r"qteHitMin=\d+,qteRewardExp=\d+,qteRewardCoin=\d+,"
                r"exp=(\d+),coin=(\d+),monsterLevel=(\d+),monsterRevise=([\d.]+),"
                r"leaderDropCardProb=([\d.]+),dropCardProb=([\d.]+),"
                r"dropPackId1=(\d+),dropPackProb1=([\d.]+),"
                r"dropPackId2=(\d+),dropPackProb2=([\d.]+),"
                r"dropPackId3=(\d+),dropPackProb3=([\d.]+),"
                r"dropPackId4=(\d+),dropPackProb4=([\d.]+)",
                raw):
                (mid, mtype, gid, exp, coin, lv, rev,
                 _ldp, _dp,
                 p1, pp1, p2, pp2, p3, pp3, p4, pp4) = m.groups()
                key = (int(mid), int(mtype))
                packs = []
                for pid, pprob in ((p1, pp1), (p2, pp2), (p3, pp3), (p4, pp4)):
                    pid, pprob = int(pid), float(pprob)
                    if pid and pprob > 0:
                        packs.append((pid, pprob))
                _BATTLE_EVENT[key] = {
                    "monsterGroupId": int(gid),
                    "exp": int(exp),
                    "coin": int(coin),
                    "monsterLevel": int(lv),
                    "monsterRevise": float(rev),
                    "dropPacks": packs,
                }
                # also index by missionId alone (first match wins = type1 combat)
                _BATTLE_EVENT.setdefault(int(mid), _BATTLE_EVENT[key])
        elif fn.startswith("battle_event_coin."):
            for m in re.finditer(
                r"\{chapterId=(\d+),coinMin=(\d+),coinMax=(\d+)\}",
                open(fp, encoding="utf-8", errors="replace").read()):
                cid, lo, hi = m.groups()
                _BATTLE_COIN[int(cid)] = (int(lo), int(hi))
    log(f"  battle meta: monsters={len(_BATTLE_MONSTER)} "
        f"groups={len(_BATTLE_MONSTER_GROUP)} events={len(_BATTLE_EVENT)} "
        f"coinChapters={len(_BATTLE_COIN)}")


def _roll_drop_packs(packs):
    """Roll chapter dropPackId/Prob pairs into EQUIP reward entries."""
    out = []
    for pid, pprob in packs or []:
        if random.random() > pprob:
            continue
        pool = _DROP_PACKS.get(pid) or _DROP_PACKS[550001]
        out.append(_equip_reward(random.choice(pool)))
    return out


def _formation_card_ids():
    """Server-authoritative battle/home queue: main + additional."""
    ids = []
    main = int(ST.main_card_id or STARTER_CARD_ID)
    ids.append(main)
    for part in str(ST.additional_card_ids or "").split(","):
        part = part.strip()
        if part.isdigit():
            cid = int(part)
            if cid not in ids:
                ids.append(cid)
    return ids[:6]


def _card_battle_stats(card):
    """Rough ATK/DEF/HP from stored level — enough for chapter auto-win flow."""
    lv = max(1, int(card.get("level") or 1))
    return {
        "hp": 1500 + lv * 80,
        "attack": 150 + lv * 12,
        "defense": 40 + lv * 4,
        "level": lv,
    }


def _build_battle_response(mission_id, battle_type=1):
    """
    Build cardInitDatas + eventFlow for a chapter battle.

    Empty eventFlow => BattleScene plays TIME UP with no combat.
    Enemy metaId must come from battle_monster (not the player card).
    Coin/exp/equipment come from missionType=2 reward rows when present.
    Player slots come from persisted formation (mainCardId + additionalCardIds).
    """
    _init_battle_meta()
    mission_id = int(mission_id or 100101)
    battle_type = int(battle_type or 1)
    combat = (_BATTLE_EVENT.get((mission_id, battle_type))
              or _BATTLE_EVENT.get((mission_id, 1))
              or _BATTLE_EVENT.get(mission_id)
              or {})
    # Type-2 rows hold the real coin/exp/dropPack tables for chapters.
    reward_ev = _BATTLE_EVENT.get((mission_id, 2)) or combat
    group_id = combat.get("monsterGroupId") or (mission_id * 100 + 1)
    monster_ids = _BATTLE_MONSTER_GROUP.get(group_id) or [1]
    level = int(combat.get("monsterLevel") or 1)
    revise = float(combat.get("monsterRevise") or 1.0)

    ST.ensure_seeded(_starter_card)
    by_id = {int(c.get("cardId") or 0): c for c in ST.cards}
    cards = []
    for i, cid in enumerate(_formation_card_ids()):
        c = by_id.get(cid) or _starter_card()
        stats = _card_battle_stats(c)
        cards.append({
            "posId": i + 1,
            "cardId": int(c.get("cardId") or cid),
            "metaId": int(c.get("metaId") or STARTER_CARD_META),
            "hp": stats["hp"],
            "level": stats["level"],
            "attack": stats["attack"],
            "defense": stats["defense"],
        })
    if not cards:
        starter = _starter_card()
        cards = [{
            "posId": 1,
            "cardId": starter["cardId"],
            "metaId": starter["metaId"],
            "hp": 2000,
            "level": 1,
            "attack": 200,
            "defense": 50,
        }]

    enemy_total_hp = 0
    for i, mid in enumerate(monster_ids[:5]):  # max 5 slots shown
        mon = _BATTLE_MONSTER.get(mid) or {
            "cardId": 101741, "reviseHP": 360, "reviseATT": 60, "reviseDEF": 0}
        # scale loosely with revise * level; keep HP in a fightable range
        ehp = max(80, int(mon["reviseHP"] * revise * (0.5 + level * 0.15)))
        eatk = max(10, int(mon["reviseATT"] * revise))
        edef = max(0, int(mon["reviseDEF"] * revise))
        cards.append({
            "posId": 10001 + i,
            "cardId": 1000 + i,          # unique runtime id
            "metaId": int(mon["cardId"]),
            "hp": ehp,
            "level": level,
            "attack": eatk,
            "defense": edef,
        })
        enemy_total_hp += ehp

    # One ACTION_SELF ATTACK that deals full enemy HP — plays a real hit anim
    # then goes to win result (not TIME UP).  posId >= 10000 => damage enemy pool.
    event_flow = [{
        "eventType": 0,          # EVENTTYPE.ATTACK
        "round": 0,
        "actionType": 0,         # ACTION_SELF
        "battleCardActs": [{
            "posId": 10001,
            "skillId": 0,
            "effectId": 0,
            "changedValue": int(enemy_total_hp),
        }],
    }]

    coin_amt = int(reward_ev.get("coin") or combat.get("coin") or 10)
    exp_amt = int(reward_ev.get("exp") or combat.get("exp") or 10)
    if coin_amt <= 0:
        coin_amt = 10
    if exp_amt <= 0:
        exp_amt = 10
    rewards = [_reward(_RE_COIN, coin_amt), _reward(_RE_EXP, exp_amt)]
    rewards.extend(_roll_drop_packs(reward_ev.get("dropPacks")))
    # Persist coin/exp/equips so backpack survives re-login.
    ST.apply_rewards(rewards, ST.apply_reward)
    ST.save()

    return {
        "win": True,
        "leftHpRate": 80,
        "rewards": rewards,
        "cardInitDatas": cards,
        "eventFlow": event_flow,
        "qte": False,
        "encounterMultiPlayerBoss": False,
        "damage": int(enemy_total_hp),
        "showQuery": False,
    }


# Actual GuideConfig values (NewUserGuide.lua) — NOT the Lua table keys.
_DONE_TUTORIAL_STEPS = [
    {"funcName": "Guide_EnterGame%d" % i, "step": 1} for i in range(1, 11)
] + [
    {"funcName": n, "step": 1} for n in (
        "Guide_EquipUpgrade", "Guide_Elite", "Guide_CardOn", "Guide_EquipQuality",
        "Guide_Arena", "Guide_Beast", "Guide_Change_Card", "Guide_CardTrain",
        "Guide_Sacrifice", "Guide_TreasureBox", "Guide_Treasure",
        "Guide_MultiLineupBox", "Guide_MultiLineup", "Guide_CrossPVP",
        "Guide_CrossPVPBox", "Guide_Matrix",
    )
]


# ---------------------------------------------------------------------------
# Gacha (抽卡) — rates from canon/configs/gacha_card.lua
# ---------------------------------------------------------------------------
# Official pack weights (至尊 id=3): R3 10000 / R4 4500 / R5 725  (~65.7/29.6/4.8%)
# 高级 id=2: R2 100 / R3 20 / R4 2  (~82/16/1.6%)
# 友情 id=1: R2 100 / R3 5  (~95/5%)
# Pool contents are expanded to ALL stage-1 cards of that rarity so every
# 武将 can appear; pack *weights* stay official.
_GACHA_CFG = {}          # gachaId -> {packs, firstDrawMin, firstTenDrawMin, maxNum}
_CARDS_BY_RARE = {}      # rare -> [metaId, ...]
_CARD_RARE = {}          # metaId -> rare
_next_card_id = 1000
_gacha_pull_count = {}   # gachaId -> times pulled (for firstDrawMin pity)


def _init_gacha():
    global _GACHA_CFG, _CARDS_BY_RARE, _CARD_RARE
    if _GACHA_CFG:
        return
    # card_meta: stage-1 only (figureId ends with _1)
    for fn in os.listdir(_CONFIGS) if os.path.isdir(_CONFIGS) else []:
        if not fn.startswith("card_meta."):
            continue
        text = open(os.path.join(_CONFIGS, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(
                r"\[(\d+)\]=\{id=\d+,name=\"Card_\d+_name\".*?rare=(\d+).*?figureId=\"([^\"]+)\"",
                text):
            mid, rare, fig = int(m.group(1)), int(m.group(2)), m.group(3)
            if not fig.endswith("_1"):
                continue
            _CARD_RARE[mid] = rare
            _CARDS_BY_RARE.setdefault(rare, []).append(mid)
        break
    # gacha_card pools
    gacha_path = None
    for fn in os.listdir(_CONFIGS) if os.path.isdir(_CONFIGS) else []:
        if fn.startswith("gacha_card."):
            gacha_path = os.path.join(_CONFIGS, fn)
            break
    if not gacha_path:
        log("  gacha: gacha_card.lua missing")
        return
    text = open(gacha_path, encoding="utf-8", errors="replace").read()
    for m in re.finditer(
            r"\{id=(\d+),maxNum=(\d+),rewardPackMin=(\d+),"
            r"firstDrawMin=(\d+),firstTenDrawMin=(\d+),desc=\"([^\"]+)\""
            r"(.*?)(?=,\s*\{id=\d+,maxNum=|,\s*--|;\s*\nreturn)",
            text, re.S):
        gid = int(m.group(1))
        body = m.group(0)
        packs = []
        for pm in re.finditer(
                r"rewardPack=\{id=(\d+),weight=(\d+),(.*?)(?=rewardPack=\{id=|\}$)",
                body, re.S):
            pid, w, pbody = int(pm.group(1)), int(pm.group(2)), pm.group(3)
            if w <= 0:
                continue
            metas = [int(x) for x in re.findall(r"metaId=(\d+)", pbody)]
            # infer pack rarity from first listed card (official table)
            rare = _CARD_RARE.get(metas[0], 3) if metas else 3
            packs.append({"id": pid, "weight": w, "rare": rare, "metas": metas})
        _GACHA_CFG[gid] = {
            "maxNum": int(m.group(2)),
            "rewardPackMin": int(m.group(3)),
            "firstDrawMin": int(m.group(4)),
            "firstTenDrawMin": int(m.group(5)),
            "desc": m.group(6),
            "packs": packs,
        }
    # Official 至尊 pool stops at R5; add a tiny R6 slice so every stage-1
    # 武将 (incl. 刘备/曹操/孙权等) can appear. Weight 50 / ~15275 ≈ 0.33%.
    if 3 in _GACHA_CFG and _CARDS_BY_RARE.get(6):
        _GACHA_CFG[3]["packs"].append(
            {"id": 6, "weight": 50, "rare": 6, "metas": list(_CARDS_BY_RARE[6])})
    log(f"  gacha: pools={len(_GACHA_CFG)} "
        f"cardsByRare={{{', '.join(f'R{k}:{len(v)}' for k,v in sorted(_CARDS_BY_RARE.items()))}}}")


def _weighted_choice(items, weight_of):
    total = sum(weight_of(x) for x in items)
    if total <= 0:
        return random.choice(items)
    r = random.uniform(0, total)
    acc = 0.0
    for x in items:
        acc += weight_of(x)
        if r <= acc:
            return x
    return items[-1]


def _new_card_reward(meta_id):
    ST.next_card_id += 1
    return {
        "itemType": 5,  # ResourceEnum.CARD
        "id": ST.next_card_id,       # generateCard(value.id, ...)
        "metaId": int(meta_id),
        "amount": 1,
        "level": 1,
        "exp": 0,
    }


def _roll_one_card(gacha_id, min_pack_id=0):
    """Roll one card using official pack weights; pool = all stage-1 of that rare."""
    _init_gacha()
    cfg = _GACHA_CFG.get(gacha_id) or _GACHA_CFG.get(3) or {}
    packs = [p for p in cfg.get("packs", []) if p["weight"] > 0]
    if min_pack_id:
        forced = [p for p in packs if p["id"] >= min_pack_id]
        if forced:
            packs = forced
    if not packs:
        return _new_card_reward(STARTER_CARD_META)
    pack = _weighted_choice(packs, lambda p: p["weight"])
    pool = list(_CARDS_BY_RARE.get(pack["rare"]) or pack["metas"] or [STARTER_CARD_META])
    return _new_card_reward(random.choice(pool))


def _gacha_rewards(gacha_id, times=1):
    """
    Build `rewards` list for gachaCard / gachaCardFree / gachaCardByRp.
    `times` 1 or 10 (client sends time=). Free pull omits time => 1.
    Pity: firstTenDrawMin forces at least one pack id >= that on a 10-pull;
    firstDrawMin applies to the very first single pull of that pool.
    """
    _init_gacha()
    gacha_id = int(gacha_id or 3)
    cfg = _GACHA_CFG.get(gacha_id) or {}
    times = int(times or 1)
    if times < 1:
        times = 1
    max_n = int(cfg.get("maxNum") or 10)
    if times > max_n:
        times = max_n

    results = []
    ten_min = int(cfg.get("firstTenDrawMin") or 0)
    first_min = int(cfg.get("firstDrawMin") or 0)
    pulled = _gacha_pull_count.get(gacha_id, 0)

    for i in range(times):
        force = 0
        if times >= 10 and ten_min and i == 0:
            force = ten_min
        elif times == 1 and first_min and pulled == 0:
            force = first_min
        results.append(_roll_one_card(gacha_id, force))

    # Ensure 10-pull actually contains a card from pack >= firstTenDrawMin
    if times >= 10 and ten_min:
        packs = {p["id"]: p for p in cfg.get("packs", [])}
        need_rare = None
        for pid in sorted(packs.keys()):
            if pid >= ten_min:
                need_rare = packs[pid]["rare"]
                break
        if need_rare is not None:
            got = any(_CARD_RARE.get(r["metaId"], 0) >= need_rare for r in results)
            if not got:
                results[-1] = _roll_one_card(gacha_id, ten_min)

    _gacha_pull_count[gacha_id] = pulled + times
    return results

# MetaManager.vip_setting spans levels 0..17 (canon/configs/vip_setting.lua).
# GameInitRequest:onSuccess walks vipLevel upwards while indexing
# vip_setting[vipLevel + 1], so we hand back the maximum level, which makes
# isCurVipMaxLevel() true and short-circuits the loop before any indexing.
VIP_MAX_LEVEL = int(os.environ.get("CANON_VIP_MAX", "17"))


def _payment_exchanges():
    """Shop charge tab packages (MetaManager.getPaymentExchangeConfig)."""
    # id used as Google/GSP sku; goldNum credits rechargeGems + freeGems.
    pkgs = [
        (60, 6, 0),
        (300, 30, 30),
        (980, 98, 100),
        (1980, 198, 200),
        (3280, 328, 400),
        (6480, 648, 800),
    ]
    out = []
    for gold, cny, gift in pkgs:
        out.append({
            "id": f"he_gold_{gold}",
            "onSale": True,
            "tag": 1 if gold == 60 else 0,
            "goldNum": gold,
            # ShopScene / GspBridge read both amount and goldNum.
            "amount": gold,
            "giftGoldNum": gift,
            "extraAmount": gift,
            "chargeAmount": gold + gift,
            "platformCoin": cny,
            "itemDescKey": "chargeMoney_price",
            "itemNameKey": "chargeMoney_name",
            "textKey": "chargeMoney_name",
        })
    return out


_CHARGE_MONEY_REWARD = {}  # id -> {requireGold, rewards:[{itemType,metaId/id,amount}]}
_CHARGE_MONEY_REWARD_LOADED = False


def _init_charge_money_reward():
    global _CHARGE_MONEY_REWARD, _CHARGE_MONEY_REWARD_LOADED
    if _CHARGE_MONEY_REWARD_LOADED:
        return
    _CHARGE_MONEY_REWARD_LOADED = True
    cfg = os.path.join(os.path.dirname(ROOT), "work", "luasrc", "canon", "configs")
    if not os.path.isdir(cfg):
        return
    for fn in os.listdir(cfg):
        if not fn.startswith("charge_money_reward."):
            continue
        text = open(os.path.join(cfg, fn), encoding="utf-8", errors="replace").read()
        for m in re.finditer(
                r"\[(\d+)\]=\{id=(\d+),requireGold=(\d+),worthGold=\d+,"
                r"backgroundCardId=\d+,describe=\"[^\"]+\","
                r"rewardType1=(\d+),rewardId1=(\d+),rewardAmount1=(\d+),"
                r"rewardType2=(\d+),rewardId2=(\d+),rewardAmount2=(\d+),"
                r"rewardType3=(\d+),rewardId3=(\d+),rewardAmount3=(\d+),"
                r"rewardType4=(\d+),rewardId4=(\d+),rewardAmount4=(\d+)\}",
                text):
            rid = int(m.group(2))
            req = int(m.group(3))
            rewards = []
            for i in range(4):
                base = 4 + i * 3
                rtype = int(m.group(base))
                rid_item = int(m.group(base + 1))
                amt = int(m.group(base + 2))
                if rtype == 0 or amt == 0:
                    continue
                if rtype == 5:  # CARD
                    rewards.append({
                        "itemType": 5, "metaId": rid_item, "amount": amt,
                        "level": 1, "exp": 0,
                    })
                elif rtype == 7:  # PROP
                    rewards.append({
                        "itemType": 7, "metaId": rid_item, "amount": amt,
                    })
                elif rtype == 2:  # GEMS
                    rewards.append({"itemType": 2, "amount": amt})
                elif rtype == 1:  # COIN
                    rewards.append({"itemType": 1, "amount": amt})
                else:
                    rewards.append({
                        "itemType": rtype, "metaId": rid_item, "amount": amt,
                    })
            _CHARGE_MONEY_REWARD[rid] = {"requireGold": req, "rewards": rewards}
        break
    log(f"  charge_money_reward: {len(_CHARGE_MONEY_REWARD)} tiers")


def _claim_charge_money_reward(reward_id):
    """Return (rewards, errCode). err 716120 = nothing to claim, 716121 = bad id."""
    _init_charge_money_reward()
    rid = int(reward_id)
    meta = _CHARGE_MONEY_REWARD.get(rid)
    if not meta:
        return None, 716121
    if rid in ST.gained_charge_money_reward_list:
        return None, 716120
    if int(ST.recharge_gems) < int(meta["requireGold"]):
        return None, 716120
    rewards = []
    with ST._lock:
        for r in meta["rewards"]:
            rr = dict(r)
            it = int(rr.get("itemType") or 0)
            if it == 5:
                ST.next_card_id += 1
                rr["id"] = ST.next_card_id
            elif it == 6:
                ST.next_equip_id += 1
                rr["id"] = ST.next_equip_id
            rewards.append(rr)
        ST.apply_rewards(rewards, ST.apply_reward)
        ST.gained_charge_money_reward_list.append(rid)
        ST.save()
    log(f"  gainChargeMoneyReward id={rid} -> {len(rewards)} items "
        f"(rechargeGems={ST.recharge_gems})")
    return rewards, None


def _shark_user(nickname="", full=False):
    """The `sharkUser` object the client expects from createUser / gameInit."""
    nick = nickname or "测试主公"
    u = {
        # MUST be a STRING, not a number.  CreateCharacterScene.lua:170 calls
        #     CanonEnvInjector:setGspGameUserId(event.data.sharkUser.uid)
        # and the Java method is `setGspGameUserId(java.lang.String)V` (verified
        # via dexdump on classes.dex).  luajava will not coerce a Lua number to
        # java.lang.String, so passing a number raises
        #     "Invalid method call. No such method."
        # and the engine's Lua error handler kills the process (SIGKILL).
        # loginServer's uid is a string for the same reason.
        "uid": "100001",
        "serverId": 1,
        # Client DataManager returns sharkUser as-is.  Lua UI reads `nickName`
        # (camel N); some older payloads used `nickname`.  Ship both.
        "nickname": nick,
        "nickName": nick,
        "level": ST.level if full else 1,
        "exp": ST.exp if full else 0,
        "gold": ST.coins if full else 100000,
        "gem": ST.gems if full else 10000,
        # consumed by the vip-level loop in GameInitRequest:onSuccess -- these
        # MUST be numbers, not strings, or the comparison raises.
        "vipLevel": VIP_MAX_LEVEL,
        "vipExp": 0,
        "rechargeGems": int(getattr(ST, "recharge_gems", 0) or 0) if full else 0,
        # CalculationManager.calcComplex_getGemsNow:
        #   rechargeGems + freeGems - usedFreeGems - usedRechargeGems
        # Missing any of these => nil arithmetic in BaseUIScene:onInit after
        # !!!BASEUI_after_build, onFinishHandle aborts before replaceScene =>
        # black screen, process alive.
        "freeGems": ST.gems if full else 10000,
        "usedFreeGems": 0,
        "usedRechargeGems": 0,
        "energy": ST.energy if full else 100,
        "actionPower": 100,
        "silver": 0,
        "createTime": int(time.time()),
    }
    if full:
        now = int(time.time())
        # fields other handlers touch after gameInit
        u.update({
            "fightCapacity": 0,
            "leadership": 0,
            "lastLoginTime": now,
            "guideStep": 0,
            # canonUtils.lua:571 -> data.sharkUser.mainCardId (guide bookkeeping)
            "mainCardId": ST.main_card_id or STARTER_CARD_ID,
            # CommonManager.getQueueData() does `UserData.additionalCardIds:split(",")`
            # so this MUST be a string, not nil and not a table.
            "additionalCardIds": ST.additional_card_ids or "",
            "vipLevel": VIP_MAX_LEVEL,
            "newGuideStep": 0,
            # BaseUIScene:onInit -> CalculationManager.calcComplex_getEnergyNow / getEPNow
            # do arithmetic on these; nil => Lua error caught by the touch-callback
            # pcall path => black screen, process survives, 0% CPU (no SIGKILL).
            "energyLastUpdateTime": now,
            "eventPoint": ST.event_point,
            "eventPointLastUpdateTime": now,
            # BaseUIScene.lua:447 setString(userData.coins) — distinct from silver/gold
            "coins": ST.coins,
            "energy": ST.energy,
            "level": ST.level,
            "exp": ST.exp,
        })
    return u


# Formal tutorial starter is 关平 (102111 / guanping_1).  This APK only ships
# `full.*` for her (no sdandard); the installed client patch falls back to
# full.png in getCardSpriteFrame, so we can use the real starter again.
# (Previously forced youguanyu_1 / 102341 solely because it had sdandard.)
STARTER_CARD_META = 102111          # guanping_1 关平
STARTER_CARD_ID = 1


def _starter_card():
    """The one card every new account owns -- MainMenuScene renders it as the
    home-screen avatar via CommonManager.getQueueData()[1]."""
    # make_card fills cardSkills from card_meta (RewardManager.generateCard parity)
    return _feat.make_card(STARTER_CARD_ID, STARTER_CARD_META, level=1, exp=0)


def _game_init_extra():
    """
    Extra top-level `gameInit` keys.

    Only `sharkCards` is dereferenced UNCONDITIONALLY:
        DataManager.getCardsData() -> getGameInitData().sharkCards.sharkCards
    so it must be present.

    Everything else must be OMITTED rather than sent as {}.  The client assigns
    the value and then builds its own default when it is falsy, e.g.
    CountryManager.lua:73-102
        self.missionContext = GameInitData.sharkMissionContext
        if not self.missionContext then
          ...derive first country/chapter/mission from battle_country/battle_chapter...
        end
    An empty table IS truthy in Lua, so sending {} suppresses that default and
    the next line (`missionContext.missionId / 100`) dies on a nil field ->
    engine SIGKILL.  Same shape for sharkSceneProcess, missionCompletes, etc.
    """
    ST.ensure_seeded(_starter_card)
    if _reconcile_chapter_progress():
        ST.save()
        log(f"  reconciled chapter -> mission="
            f"{ST.mission_context.get('missionId')} "
            f"step={ST.mission_context.get('finishedStep')} "
            f"maxFin={ST.scene_process.get('maxFinishedMissionId')}")
    dropped, repaired = ST.sanitize_cards()
    if dropped or repaired:
        log(f"  sanitize_cards dropped={dropped} skills_repaired={repaired}")
        ST.save()
    main_id = int(ST.main_card_id or STARTER_CARD_ID)
    add_ids = []
    for part in str(ST.additional_card_ids or "").split(","):
        part = part.strip()
        if part.isdigit():
            add_ids.append(int(part))
    queue = [{"cardId": main_id, "equips": [], "spirits": []}]
    for cid in add_ids[:5]:
        queue.append({"cardId": cid, "equips": [], "spirits": []})
    # Attach worn equips into queue slots
    for slot in queue:
        worn = [int(e["equipId"]) for e in ST.equips
                if int(e.get("cardId") or 0) == int(slot["cardId"])]
        slot["equips"] = worn
    def _battle_slot():
        q = []
        for slot in queue:
            q.append({
                "cardId": slot["cardId"],
                "equips": list(slot["equips"]),
                "spirits": list(slot.get("spirits") or []),
            })
        return {
            "sharkUserQueue": q,
            "sharkMatrices": {"sharkMatrices": []},
        }
    return {
        "sharkCards": {"sharkCards": list(ST.cards)},
        # BackpackScene:1084 indexes sharkUserBattleArray[1..3] without a nil
        # guard on the parent table.  Dense AMF list => Lua 1-based slots.
        # Omitting the key entirely SIGKILLs on first backpack/team touch.
        "sharkUserBattleArray": [_battle_slot(), _battle_slot(), _battle_slot()],
        "sharkSpirits": {"sharkSpirits": list(ST.spirits)},
        # RewardManager / BackpackScene expect this wrapper; omit => nil and
        # some paths assume .sharkTreasures exists.
        "sharkTreasures": {"sharkTreasures": []},
        # CountryManager.initializeData — MUST be fully populated (never {}).
        # Missing => client resets to first mission / finishedStep=0 every login.
        "sharkMissionContext": dict(ST.mission_context),
        "sharkSceneProcess": dict(ST.scene_process),
        "missionCompletes": list(ST.mission_completes),
        # DailyDataManager.init: mysterious / treasureSacrifice / exchange daily.
        # Missing parent is guarded; empty lists keep Mysterious layer alive.
        "sharkDailyDataExtend": {
            "mysteriousChallengeTimes": [],
            "mysteriousExchangeTimes": [],
            "treasureSacrificeTimes": [],
            "cardExchangeDailyInfo": {
                "cardMetaIds": [],
                "exchangeTimes": 0,
            },
        },
        # MysteryShopLayer / ActivityPanelScene write freeTimes & lastRefreshSecond
        # with no nil guard on the parent table.
        "sharkUserSecretShop": {
            "freeTimes": 5,
            "lastRefreshSecond": int(time.time()),
            "ifListFresh": False,
            "version": 1,
        },
        "sharkDailyData": {
            "_date": int(time.time()),
            "lstCowStageInfo": [],
            "lstEatPeachInfo": [],
        },
        "sharkActivity": {
            "chargeInfo": {"currVersion": 1, "gems": 0, "gainedRewardIds": []},
            "nyChagrgedGems": 0,
            "ggVersion": 1,
            "goldGodNum": 0,
        },
        "crossBossActivityStatus": True,
    }


def _png_bytes(w, h, rgb=(90, 140, 200)):
    """
    Minimal stdlib PNG encoder -- used to serve placeholder ad artwork so the
    client's ResourceLoader.loadThirdPartyRes() gets a valid texture.
    """
    import struct as _st

    raw = b"".join(b"\x00" + bytes(rgb) * w for _ in range(h))

    def chunk(tag, data):
        c = _st.pack(">I", len(data)) + tag + data
        return c + _st.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = _st.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))


def _game_setting_config():
    """
    `game_meta.gameSettingConfig` comes ONLY from the server -- the client ships
    no local fallback (MetaManager.getGameSettingConfig() -> game_meta.X or {}).

    MainMenuScene:onInit line 755 does
        ...:setString(MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel)
    so a missing field is `setString(nil)` -> Lua error.  Because onInit is
    reached from the new-user-guide COROUTINE, that error kills the coroutine
    SILENTLY (see the header comment in NewUserGuideCoroutine.lua: "cocoutine
    中发生错误会直接终止coroutine, 不会输出到控制台") -- no logcat entry, no crash
    file, no SIGKILL, just a permanently black screen while the app keeps
    rendering.  Hence every field the client touches must exist.

    Field list derived by scanning the decrypted Lua for
    `gameSettingConfig.<name>` and `getGameSettingConfig().<name>[.<sub>]`.
    Values are plausible gates; the client only compares them against level.
    """
    return {
        "babelConfig": {"babelTowerUnlockLevel": 20},
        "beastConfig": {
            "beastCombineTime": 3600,
            "beastUnlockLevel": 25,
            "goldPeaceCardGemCost": 50,
            "goldPeaceCardMetaId": 0,
            "normalPeaceCardCoinCost": 1000,
            "normalPeaceCardMetaId": 0,
        },
        # the client's own fallback literal for this one is 43
        "lineupUnlockLevel": 43,
        "arenaUnlockLevel": 15,
        "cardResolveUnlockLevel": 30,
        "clearMissionUnlockLevel": 10,
        "sacrificeUnlockLevel": 35,
        "itemSynthetizeUnlockLevel": 12,
        "matrixUnlockLevel": 40,
        "specialGroupUnlockLevel": 20,
        "magicCircleOpen": 1,
        "renamePropId": 0,
        "renameCooldown": 86400,
        "renameCardGoldCost": 100,
        "maxEnergy": 100,
        "maxEventPoint": 100,
        "energyGainedByGem": 50,
        "eventPointGainedByGem": 50,
        "energyGainedByLevelUp": 100,
        "eventPointGainedByLevelUp": 100,
        "inventoryMaxStack": 9999,
        "inventoryMaxExpandTimes": 20,
        "inventoryExtraSlotsPerPurchase": 5,
        "cardUpgradeCoinRevise": 1,
        "cardResolveCardLevel": 1,
        "enchantsLevel": 1,
        "equipSpiritValue": 1,
        "equipSpiritMaterial": 1,
        "equipSpiritSilver": 1,
        # Omit doubleChargeTime*Feature names: ShopScene.isChargeDouble ->
        # getStartTime indexes MaintenanceManager times.  Empty maintenanceItem
        # makes startAndEndTime[1] nil and SIGKILLs the moment the charge tab
        # renders.  With these nil, isChargeDouble falls back to rechargeGems<=0.
        "cardTrainConfig": {
            # CardInfoNewPanel CultivateTabView / CardTrainingScene
            "ybCost": 10,              # 元宝：高级培养
            "pydCost": 1,              # 魂石：每次培养
            "pydMetaId": 400010,       # 魂石 prop
            "normalTrainFloor": 1,
            "normalTrainCeil": 5,
            "specialTrainFloor": 3,
            "specialTrainCeil": 10,
        },
        "cardPowerConfig": {},
        "eliteConfig": {},
        "friendSystem": {},
        "secretShopConfig": {
            # ActivityPanelScene splits this on '|' and indexes [i+1].
            # A bare number (or single short interval) makes [i+1] nil → SIGKILL
            # right after 累充领取 opens ActivityPanelScene.
            "newRefreshInterval": "86400",
            "refreshGoldCost": 50,
        },
        "dailyShopConfig": {
            "newRefreshInterval": "86400",
            "refreshGoldCost": 50,
        },
        "rebirthConfig": {
            "rebirthSkillBookMaxValue": 100,
            "rebirthSkillBookReturnRate": 0.5,
            "rebirthSoulstoneReturnRate": 0.5,
        },
    }


def _battle_setting_config():
    """`game_meta.battleSettingConfig` -- same reasoning as above."""
    return {
        "victoryLevelFloor": 1,
        "victoryLevelTop": 99,
        "loseLevelFloor": 1,
        "loseLevelTop": 99,
        "missionStepEnergy": MISSION_STEP_ENERGY,
        "clearMissionConfig": {
            "coolDownTime": 300,
            "maxRounds": 3,
            "resetCoolDownFiveMinsCost": 10,
            "roundConsumeEnergy": MISSION_STEP_ENERGY,
        },
        "robSettingConfig": {"robConsumeEventPoints": 5},
        "arenaChallengeChancesPerPurchase": 5,
        "arenaBattleEventPointConsumed": 2,
        "arenaChallengeChancesGoldCost": 50,
        "arenaNormalVictoryHighRankScore": 20,
        "arenaNormalVictoryLowRankScore": 10,
        "arenaLossActiveScore": 1,
        "arenaRewardTime": 3600,
    }


def _maint(name, enable=True):
    """All-day open maintenance row. activityDate=0 => isEnable=true for the
    whole [beginTime, endTime] window (MaintenanceManager.isOpen)."""
    return {
        "name": str(name),
        "enable": bool(enable),
        "beginTime": "2013/01/01 00:00",
        "endTime": "2035/12/31 23:59",
        "activityOpen": "00:00",
        "activityDuring": 1440,
        "activityUnite": 0,
        "activityDate": 0,
    }


def _all_maintenance_items():
    """Open every activity_panel featureName plus hard-coded enable() names."""
    names = [
        # activity_panel.featureName (tab catalog)
        "activity1Rest", "worldBoss", "fountainWish", "mysterious",
        "mysteriousShop", "crossBoss", "cowStage",  # goldGod off: incomplete config crashes enable()
        "activityChargeRewardPanel", "ActivityLimitReward",
        "activityGachaXiaoyu", "activityGachaPointsPanel",
        "activityTreasureboxAll", "activityGemConsume", "activityBalloon",
        "eventNewyear", "questionDaily", "activityInvitationCode",
        "activityContendPanel", "activityWanted", "activityChallenge",
        "activityFbShare", "activity_phoneCharge", "activity_dailyCharge",
        "activityPray", "activityPraise", "gemCard", "activitySecretShop",
        "consumeRewards", "activityCardExchange", "exchangeDaily",
        "activityDayReward", "chargeReward", "chargeFeedback",
        "activitySeckill", "multiplayerBossPanel", "activityFireworks",
        "activityDoubleSilver", "fortuneNow", "activityThrowDice",
        # activityLevelRacePanel off: bad displayTypes crashes ActivityPanelScene
        "activitySwornBrothers",
        "consecutiveLogin", "consecutiveLoginNew", "calendarLogin",
        # Extra names used by layer.enable() / getMeta stubs
        "activity2Rest", "worldBoss1", "activityMysteriousExchange",
        "treasureboxPoints", "treasureboxPointsReward",
        "treasureboxPointsPanel", "activityGachaXiaoyuPoints",
        "activityGachaXiaoyuGainReward", "activityGachaPointsGainReward",
        "activityNewyearPanel", "questionReward", "limitReward",
        # activityLevelRace / GainReward kept closed (same crash family)
        "activityPhoneCharge", "activityDailyCharge",
        "multiplayerBoss", "wanted", "contend", "seckill", "dice",
        "praise", "balloon", "swornBrothers", "newyear", "levelRace",
        "activityGemConsume", "activityFireworks", "activityDoubleSilver",
        "activityThrowDice", "activitySeckill", "activityFortuneNow",
        "activityNewyearCalcPay", "activityNewyearGainReward",
        "doubleCharge_before", "doubleCharge_curr",
    ]
    # Deduplicate while preserving order
    seen, out = set(), []
    for n in names:
        if n not in seen:
            seen.add(n)
            out.append(_maint(n))
    return out


def _secret_shop_payload():
    """getSecretShopList / RefreshSecretShop fields MysteryShopLayer reads."""
    now = int(time.time())
    items = [
        {"itemType": 7, "itemId": 400010, "itemAmount": 10,
         "moneyType": 2, "moneyAmount": 10, "boughtTime": 3},
        {"itemType": 7, "itemId": 400050, "itemAmount": 1,
         "moneyType": 2, "moneyAmount": 50, "boughtTime": 1},
        {"itemType": 1, "itemId": 0, "itemAmount": 5000,
         "moneyType": 2, "moneyAmount": 5, "boughtTime": 5},
    ]
    return {
        "freeTimes": 5,
        "itemIdList": items,
        "version": 1,
        "lastRefreshSecond": now,
    }


def _activity_battle(params, mid_fallback=100101):
    """Reuse chapter battle builder for activity challenge* RPCs."""
    mid = int(params.get("missionId")
              or params.get("id")
              or params.get("cowStageId")
              or params.get("stageId")
              or mid_fallback)
    btype = int(params.get("battleType")
                or params.get("difficultyDegree")
                or 1)
    out = _build_battle_response(mid, btype)
    out["win"] = True
    out.setdefault("rewards", [_reward(1, 500), _reward(2, 10)])
    out.setdefault("qteRewards", [])
    out.setdefault("vipRewards", [])
    out.setdefault("qte", False)
    out.setdefault("leftHpRate", 1.0)
    return out


def _shark_user_extend(returning=False):
    """
    `sharkUserExtend` is dereferenced WITHOUT nil guards in several hot paths,
    e.g. canonUtils.lua:603
            for k,v in pairs(data.sharkUserExtend.tutorialSteps) do
    reached from MainMenuScene:onInit -> IsGuideExecuted.  A missing field there
    is an uncaught Lua error, which the engine turns into SIGKILL.

    Field types are taken from the client's own usage:
      * tutorialSteps / gainedChargeMoneyRewardList / lifeLimitGoods / ... are
        iterated with pairs/ipairs or table.insert'ed  -> must be LISTS
      * treasureInfo.treasureFragmentNum, signInInfo.loginDaysMonth,
        doubleChargeInfo.{doubleCharge,version}, countdownRewardInfo,
        exchangeGiftBagInfo, continuousLogin* -> DICTS
      * the remaining counters are plain numbers
    """
    steps = list(_DONE_TUTORIAL_STEPS) if returning else []
    return {
        "fightCapacity": 0,
        # --- lists ---
        "tutorialSteps": steps,         # table.insert'ed in canonUtils.ExeNewGuide
        "cardGroupInterworking": [],
        "countdownFreeGachaInfos": [],
        "gainedChargeMoneyRewardList": list(ST.gained_charge_money_reward_list),
        "lifeLimitGoods": [],
        "lstEatPeachInfo": [],
        "paidChannelNames": [],
        "vipPackages": [],
        # --- dicts ---
        "continuousLoginInfo": {},
        "continuousLoginRewardInfoV2": {},
        "countdownRewardInfo": {},
        "doubleChargeInfo": {"doubleCharge": False, "version": 0},
        "exchangeGiftBagInfo": {},
        "signInInfo": {
            # Mark already signed today so MainMenu skips 每日签到 popPanel
            # (empty calendar + close chain was crashing into EnchantGuide).
            "loginDaysMonth": max(1, int(time.strftime("%d"))),
            "getRewardTimeStamp": int(time.time()),
        },
        "treasureInfo": {"treasureFragmentNum": 0},
        # --- numbers ---
        "astralEssence": 0,
        "battleArrayId": 0,
        "boughtGridNum": ST.bought_grid_num,
        "boughtGridTimes": ST.bought_grid_times,
        "boughtSpiritPoolNum": 0,
        "friendPoint": 0,
        "generalExp": int(getattr(ST, "general_exp", 0) or 0),
        "lastRenameTimes": 0,
        "medalNum": 0,
        "renameCd": 0,
        "seniorGachaTenTimes": 0,
        # Skip EnchantGuideRewardPanel after login popups (needs enchantTotalConfig).
        "enchantStepReward": True,
    }


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "nginx"
    sys_version = ""

    def log_message(self, *a):
        pass

    # -------- helpers --------
    def _send(self, code, body: bytes, ctype="text/plain; charset=utf-8"):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        if body:
            self.wfile.write(body)
        path = self.path.split("?")[0]
        if not (path.startswith("/admin/cardimg/") or path.startswith("/admin/api/")):
            log(f"  -> {code} ({len(body)}B) {ctype}")

    def _read_body(self):
        n = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(n) if n else b""

    def _record(self, raw):
        rec = {
            "t": time.strftime("%Y-%m-%d %H:%M:%S"),
            "method": self.command, "path": self.path,
            "host": self.headers.get("Host", ""),
            "headers": dict(self.headers.items()),
            "body_len": len(raw),
            "body_hex": raw[:8192].hex(),
        }
        with _lock:
            with open(RPC_LOG, "a", encoding="utf-8") as f:
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    # -------- endpoints --------
    def do_GET(self):
        path = self.path.split("?")[0]
        quiet = path.startswith("/admin/cardimg/") or path.startswith("/admin/api/")
        if not quiet:
            log(f"GET {self.path}")
        if path in ("/admin", "/admin/"):
            return self._send(200, _admin.admin_html_bytes(),
                              "text/html; charset=utf-8")
        if path == "/admin/api/state":
            return self._send(200, json.dumps(
                {"ok": True, "state": _admin.state_snapshot(ST)},
                ensure_ascii=False).encode("utf-8"),
                "application/json; charset=utf-8")
        if path == "/admin/api/catalog":
            qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            q = (qs.get("q") or [""])[0]
            country = (qs.get("country") or [None])[0]
            rare = (qs.get("rare") or [None])[0]
            stage1 = (qs.get("stage1") or ["1"])[0] != "0"
            data = _admin.get_catalog(
                q=q,
                country=int(country) if country not in (None, "") else None,
                rare=int(rare) if rare not in (None, "") else None,
                stage1_only=stage1,
            )
            data["ok"] = True
            return self._send(200, json.dumps(data, ensure_ascii=False).encode("utf-8"),
                              "application/json; charset=utf-8")
        if path.startswith("/admin/cardimg/"):
            figure = urllib.parse.unquote(path[len("/admin/cardimg/"):].strip("/"))
            data, ctype = _admin.head_bytes(figure)
            if not data:
                return self._send(404, b"no image")
            return self._send(200, data, ctype or "image/png")
        if path == "/admin/api/card_dict":
            # Full dictionary dump (name + image path) for external use
            cat = _admin._ensure_catalog()
            return self._send(200, json.dumps(cat, ensure_ascii=False).encode("utf-8"),
                              "application/json; charset=utf-8")
        if path == "/staticVersion":
            return self.static_version()
        if path.startswith("/static/ad/"):
            # GachaScene.preloadAd / MainMenuScene advertise slots call
            # ResourceLoader.loadThirdPartyRes({url}, cb); hand back a real PNG
            # so the download succeeds instead of erroring.
            return self.ad_picture()
        if path.startswith("/static/"):
            return self.static_file()
        if path.startswith("/check/"):
            return self.check_platform(b"")
        if path == "/getLoginServer":
            return self.login_server_list()
        if path == "/restapi.php":
            # HappyElements DC analytics — return empty OK so DcSender stops
            # retrying; 404 previously flooded logs but was non-fatal.
            return self._send(200, b"{}", "application/json")
        return self._send(404, "not found")

    def do_POST(self):
        raw = self._read_body()
        path = self.path.split("?")[0]
        log(f"POST {self.path}  body={len(raw)}B")
        if path.startswith("/admin/api/"):
            return self.admin_api_post(path, raw)
        if raw:
            log("  raw head:\n" + hexdump(raw[:256]))
        if path == "/protocol":
            return self.rpc(raw)
        if path == "/systemInfo":
            return self.system_info()
        if path == "/sessionKey/init":
            return self.session_key()
        if path == "/loginAccount/hasVisitorAccount":
            return self.has_visitor_account(raw)
        if path.startswith("/check/"):
            return self.check_platform(raw)
        if path == "/mappingAccount":
            return self.mapping_account(raw)
        if path.startswith("/loginAccount/"):
            return self.login_account(raw)
        if path.startswith("/loginAccount/") or path == "/mappingAccount":
            return self.platform_check()
        if path == "/restapi.php":
            return self._send(200, b"{}", "application/json")
        self._record(raw)
        return self._send(404, "not found")

    def admin_api_post(self, path, raw):
        """JSON admin mutations: save account / add|remove|level cards."""
        try:
            body = json.loads(raw.decode("utf-8") or "{}")
        except Exception:
            return self._send(400, json.dumps(
                {"ok": False, "error": "invalid json"}).encode(),
                "application/json; charset=utf-8")
        try:
            if path == "/admin/api/state":
                state = _admin.update_state(ST, body)
                out = {"ok": True, "state": state}
            elif path == "/admin/api/card/add":
                meta_ids = body.get("metaIds") or body.get("metaId")
                if meta_ids is None:
                    raise ValueError("metaIds required")
                if not isinstance(meta_ids, list):
                    meta_ids = [meta_ids]
                added = _admin.add_cards(
                    ST, meta_ids,
                    level=body.get("level", 1),
                    count=body.get("count", 1),
                )
                out = {"ok": True, "added": added,
                       "state": _admin.state_snapshot(ST)}
            elif path == "/admin/api/card/remove":
                n = _admin.remove_card(ST, body.get("cardId"))
                out = {"ok": True, "removed": n,
                       "state": _admin.state_snapshot(ST)}
            elif path == "/admin/api/card/level":
                ok = _admin.set_card_level(
                    ST, body.get("cardId"), body.get("level", 1))
                if not ok:
                    raise ValueError("card not found")
                out = {"ok": True, "state": _admin.state_snapshot(ST)}
            else:
                return self._send(404, json.dumps(
                    {"ok": False, "error": "unknown admin api"}).encode(),
                    "application/json; charset=utf-8")
            return self._send(200, json.dumps(out, ensure_ascii=False).encode("utf-8"),
                              "application/json; charset=utf-8")
        except Exception as e:
            log(f"  admin api error: {e}")
            return self._send(400, json.dumps(
                {"ok": False, "error": str(e)}, ensure_ascii=False).encode("utf-8"),
                "application/json; charset=utf-8")

    # --- official-account login flow ------------------------------------
    # Canon/data/AccountPlatformLogin.lua + AndroidPlatformLogin.lua
    #
    #  1) checkDeviceGuestAccount -> POST /loginAccount/hasVisitorAccount
    #        platformId, deviceId                      -> JSON (any table)
    #  2) loginAccount(token,1)   -> POST /check/android?
    #        udid, seconds, sk=md5(udid..seconds.."123456"), loginType
    #                                                  -> JSON {code=1, loginAccountId}
    #  3) accountGetBoundMapping  -> POST /mappingAccount
    #        platformId, platformUid, sid              -> JSON {code=1, accountId, token}
    #  4) initSession             -> POST /sessionKey/init
    #        uid, uuid, udid, ...                      -> TEXT "uid,uuid,sessionKey"
    #  5) RPC loginServer         -> POST /protocol      -> AMF3

    def _json(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        log("  -> json " + body.decode("utf-8")[:400])
        self._send(code, body, "application/json; charset=utf-8")

    def has_visitor_account(self, raw):
        form = self._form(raw)
        log(f"  hasVisitorAccount platformId={form.get('platformId')} "
            f"deviceId={form.get('deviceId')}")
        # LoginScene treats the decoded table as a boolean-ish flag
        self._json({"code": 1, "hasVisitorAccount": 1, "deviceId": form.get("deviceId", "")})

    def check_platform(self, raw):
        form = self._form(raw)
        log(f"  check platform form={form}")
        # AccountPlatformLogin.lua: _sid = sk ; _uid = rTable.loginAccountId
        # loginAccountId must be NUMERIC: localStorage.setCurrentUser does
        # tonumber(fields[1]) and compares <= 0.
        self._json({"code": 1, "loginAccountId": ST.uid, "sid": form.get("sk", "")})

    def mapping_account(self, raw):
        form = self._form(raw)
        log(f"  mappingAccount form={form}")
        # accountId must be NUMERIC ("-1" means "new user").
        # platformUid is the device id and is kept separately.
        ST.platform_uid = form.get("platformUid") or ST.platform_uid
        if not ST.token:
            ST.token = "local-token-%d" % random.randint(100000, 999999)
        self._json({"code": 1, "accountId": ST.account_id, "token": ST.token})

    def login_account(self, raw):
        form = self._form(raw)
        log(f"  loginAccount form={form}")
        self._json({"code": 1, "accountId": ST.account_id, "token": ST.token})

    @staticmethod
    def _form(raw: bytes) -> dict:
        out = {}
        try:
            for kv in raw.decode("utf-8", "replace").split("&"):
                if "=" in kv:
                    k, v = kv.split("=", 1)
                    out[urllib.parse.unquote_plus(k)] = urllib.parse.unquote_plus(v)
        except Exception:
            pass
        return out

    # --- /staticVersion -------------------------------------------------
    def static_version(self):
        """
        Resource settings. Schema recovered from
        HeCore::ResConfig::parseStaticSettingsJson:
          static_url_root, config_md5, need_download, can_download,
          download_url, langs, resolutions, ref

        IMPORTANT: config_md5 must equal the md5 embedded in the client's
        static_config.<md5>.xml filename.  If it differs the client tries to
        download the "new" manifest and, failing, raises dynamicUpdateNetError.
        """
        cfg = {
            "static_url_root": "http://android1.canon.happyelements.cn/static",
            "config_md5": MANIFEST_MD5,
            "need_download": False,
            "can_download": False,
            "download_url": "",
            "langs": ["zh_CN"],
            "resolutions": ["720.1280"],
            "ref": 0,
        }
        body = json.dumps(cfg, ensure_ascii=False).encode("utf-8")
        log(f"  staticVersion -> config_md5={MANIFEST_MD5} " + body.decode())
        self._send(200, body, "application/json; charset=utf-8")

    # --- /static/* : serve the resource manifest if the client asks -------
    def static_file(self):
        """
        The client fetches the manifest over HTTP as
            GET /static/static_config.<md5>.xml
        right after /staticVersion, so we must serve the REAL manifest bytes
        from inside the packaged APK.

        (Previously this compared `want` against os.path.basename(MANIFEST_PATH),
        i.e. the *APK* filename -- always a mismatch -- so it always 404'd.)
        """
        want = self.path.split("?")[0].rsplit("/", 1)[-1]
        man_name = os.path.basename(_MANIFEST_ENTRY) if _MANIFEST_ENTRY else ""
        if not (MANIFEST_PATH and man_name and want == man_name):
            # the client may also ask for the manifest under its advertised md5
            if not (want.startswith("static_config.") and want.endswith(".xml")):
                log(f"  static file not available: {want}")
                return self._send(404, "not found")
        try:
            import zipfile as _zip
            with _zip.ZipFile(MANIFEST_PATH) as z:
                data = z.read(_MANIFEST_ENTRY)
        except Exception as e:
            log(f"  static file: cannot read manifest from APK: {e!r}")
            return self._send(404, "not found")
        log(f"  serving manifest {want} ({len(data)}B) from {os.path.basename(MANIFEST_PATH)}")
        self._send(200, data, "application/xml; charset=utf-8")

    def ad_picture(self):
        """Placeholder banner artwork for the client's ad slots."""
        data = _png_bytes(64, 64)
        log(f"  ad picture -> {len(data)}B PNG")
        self._send(200, data, "image/png")

    # --- /systemInfo -----------------------------------------------------
    def system_info(self):
        """
        canon/scene/LoginScene.lua:620-646 (onSystemInfoCall):
            self.systemInfo = amf3.decode(response.body)
            local ts = self.systemInfo.ts or os.time()
            local serverMergeConfig = self.systemInfo.systemConf.serverMergeConfig
            ... setInAppleReview(self.systemInfo.cleanVersion)
        Raw AMF3, no zlib / no headercvt. systemConf MUST be a table.
        """
        now = int(time.time())
        server = {
            "serverId": 1,
            "serverName": "本地测试服",
            "enable": True,
            "beginTime": "0",        # compared with tonumber(beginTime) <= ts
            "serverBusy": 100000,    # amount >= busy  -> FULL
            "serverNormal": 50000,   # amount >= normal-> CROWD
            "newServer": False,
            "whiteAccountIds": "",   # comma separated
        }
        info = {
            "ts": now,
            "cleanVersion": False,
            "systemConf": {
                "serverMergeConfig": {
                    "enable": False,
                    "gameDomain": "",
                    "serverOffset": 0,
                },
                # LoginScene.lua:776 iterates this with ipairs -> must be a list.
                # An empty list means no feature is under maintenance.
                "maintenanceFeatures": [],
            },
            "serverPartitionConfig": {
                "runningServers": [server],
                "preparedServers": [],
            },
            "serverStatuses": [
                {"serverId": 1, "amount": 1},   # low load -> NORMAL
            ],
        }
        w = AMF3Writer()
        w.w_value(info)
        body = w.bytes()
        log(f"  systemInfo -> AMF3 {len(body)}B: {json.dumps(info, ensure_ascii=False)}")
        self._send(200, body, "application/octet-stream")

    # --- /sessionKey/init ------------------------------------------------
    def session_key(self, raw=b""):
        """
        Communication:initSession reads a COMMA-SEPARATED plain-text body:
            local fiels = response.body:split(",")
            self.uid = fiels[1]; self.uuid = fiels[2]; self.sessionKey = fiels[3]
        uid "-1" is treated as an error, so always return a real uid.
        """
        form = self._form(raw) if raw else {}
        uid = form.get("uid")
        # The client does tonumber(fields[1]) and compares <= 0, so only accept
        # a positive decimal uid from the request; otherwise use our account id.
        if not uid or not uid.isdigit() or int(uid) <= 0:
            uid = ST.account_id
        ST.uid = uid
        ST.uuid = "local-uuid-%d" % random.randint(100000, 999999)
        ST.session_key = "sesskey-%d" % random.randint(1000000, 9999999)
        body = f"{uid},{ST.uuid},{ST.session_key}"
        log(f"  sessionKey -> {body}  (requested uid={form.get('uid')})")
        self._send(200, body.encode(), "text/plain; charset=utf-8")

    # --- /getLoginServer -------------------------------------------------
    def login_server_list(self):
        cfg = {
            "retCode": 200,
            "servers": [{"serverId": 1, "serverName": "本地测试服", "status": 1,
                         "recommend": True}],
        }
        body = json.dumps(cfg, ensure_ascii=False).encode()
        log("  getLoginServer -> " + body.decode())
        self._send(200, body, "application/json; charset=utf-8")

    # --- /check/<platform> ? ---------------------------------------------
    def platform_check(self):
        body = self.path.split("?", 1)[1] if "?" in self.path else ""
        cfg = {"retCode": 200, "accountId": "local_acct_1", "uid": ST.uid,
               "token": "local-token", "new": False}
        out = json.dumps(cfg).encode()
        log("  platform check -> " + out.decode())
        self._send(200, out, "application/json; charset=utf-8")

    # --- /protocol : the main RPC ---------------------------------------
    def rpc(self, raw):
        """
        Full /protocol pipeline (reverse-engineered and verified):

            client ->  headercvt_wrap( zlib( amf3( [header, [req..], ] ) ) )
            server ->  headercvt_wrap( zlib( amf3( [subHeader,[resp..],[ev]] ) ) )
        """
        if not raw:
            return self._send(200, headercvt_wrap(zlib.compress(AMF3Writer().bytes())),
                              "application/octet-stream")
        self._record(raw)
        log(f"  /protocol body {len(raw)}B  magic={raw[:2].hex()}")

        # 1) headercvt: strip 18-byte header, XOR 0xC3
        try:
            z = headercvt_unwrap(raw)
            log(f"  headercvt ok -> {len(z)}B, zlib magic={z[:2].hex()}")
        except Exception as e:
            log(f"  headercvt FAILED ({e}); assuming raw")
            z = raw
        # 2) zlib
        try:
            amf3 = zlib.decompress(z)
            log(f"  zlib ok -> {len(amf3)}B amf3")
        except Exception as e:
            log(f"  zlib FAILED ({e}); assuming raw")
            amf3 = z
        # 3) AMF3
        req = None
        try:
            req = AMF3Reader(amf3).read_value()
            log("  decoded request: " + json.dumps(req, ensure_ascii=False, default=str)[:1500])
        except Exception as e:
            log(f"  AMF3 decode failed: {e}")

        # pull header + requested methods (our reader keys dense arrays 1..n)
        header_in, items = {}, []
        if isinstance(req, dict):
            header_in = req.get(1) or {}
            items = req.get(2) or []
            if not isinstance(header_in, dict):
                header_in = {}
        elif isinstance(req, list) and len(req) >= 2:
            header_in, items = req[0], req[1]
        if isinstance(items, dict):
            items = [items[k] for k in sorted(items.keys(), key=lambda x: int(x))]

        methods = []
        method_items = []
        for it in items or []:
            if isinstance(it, dict) and "method" in it:
                methods.append(it["method"])
                method_items.append(it)
                # remember the player's chosen name so createUser / gameInit
                # echo it back instead of a placeholder
                if it["method"] == "createUser" and it.get("nickName"):
                    ST.pending_nickname = str(it["nickName"])
                log(f"    endpoint: {it['method']}  params={json.dumps({k: v for k, v in it.items() if k != 'method'}, ensure_ascii=False, default=str)[:300]}")
        log(f"  request header: {json.dumps(header_in, ensure_ascii=False, default=str)[:400]}")
        if isinstance(header_in, dict) and header_in.get("uk"):
            ST.uk = str(header_in["uk"])

        # AssembleConvertor:convertU does:
        #     local code = tonumber(subHeader.errCode)
        #     code = code and code > 0 and code or nil
        # so errCode MUST NOT be > 0 on success -- 0 means "no error".
        sub_header = {
            "errCode": 0,
            "ts": int(time.time()),
            "uk": ST.uk,
            "st": ST.counter,
            "others": {},
        }
        ST.counter += 1

        # Per-endpoint response payloads, derived from the Lua handlers:
        #   LoginScene.lua:344 afterLoginServer  -> data.uid (REQUIRED),
        #                                           data.accountReturnRewards
        #       uid == "1"  => new player (goes to character creation)
        #   CreateCharacterScene.lua:147         -> data.sharkUser.uid / .serverId
        #   GetServerTimeStampRequest            -> data.ts
        resp_list = []
        for it in method_items:
            resp_list.append(self._endpoint_response(it["method"], it))
        w = AMF3Writer()
        w.w_value([sub_header, resp_list, []])
        out = headercvt_wrap(zlib.compress(w.bytes()))
        log(f"  rpc reply for {methods} -> {len(out)}B (amf3 {len(w.bytes())})")
        log("     " + json.dumps(resp_list, ensure_ascii=False, default=str)[:600])
        self._send(200, out, "application/octet-stream")

    def _endpoint_response(self, method, params=None):
        params = params or {}
        now = int(time.time())
        base = {"method": method, "retCode": 200}
        if method == "login":
            return base
        if method == "loginServer":
            # uid "1" marks a brand-new player -> client goes to createUser
            # Returning guests get the real uid and skip create + DialogOnce.
            # Do NOT send accountReturnRewards at all.  An empty {} is truthy in
            # Lua (OldUserComeBackPanel:shouldPop) and pops a blank 主公归来 panel
            # that blocks 闯关.  Omitted/nil => shouldPop is falsy.
            if ST.user_created:
                base.update({"uid": ST.uid, "serverId": 1})
            else:
                base.update({"uid": "1", "serverId": 1})
            return base
        if method == "getServerTimeStamp":
            base.update({"ts": now})
            return base
        if method == "getServerStatus":
            base.update({"serverId": 1, "status": 1, "amount": 1})
            return base
        if method == "getSocketServer":
            # client then dials this address:port for the realtime channel
            base.update({"serverAddress": "10.0.2.2", "serverPort": 9700,
                         "token": ST.token or "local-token"})
            return base
        if method == "geneNickname":
            base.update({"nickname": "主公%d" % random.randint(1000, 9999)})
            return base
        if method == "createUser":
            # CreateCharacterScene.lua:147 reads only sharkUser.uid / .serverId
            ST.user_created = True
            ST.save()
            base.update({"sharkUser": _shark_user(nickname=ST.pending_nickname)})
            return base
        if method == "gameInit":
            # GameInitRequest:onSuccess is the heavyweight handler:
            #   * data.sharkEquips / data.sharkProps are defaulted, then
            #   * it LOOPS on data.sharkUser.vipLevel indexing
            #     MetaManager.vip_setting[vipLevel + 1].requireGold
            #     -> we hand back the MAX vip level so the `while` short-circuits
            #        (isCurVipMaxLevel is true => `not ...` false => no indexing),
            #   * DataManager.setGameInitData(data) makes getCurrUser() return
            #     data.sharkUser (used by the speak-limit callback),
            #   * DataManager.getShowFightCapacity() later dereferences
            #     sharkUserExtend.fightCapacity with no nil guard.
            nick = ST.pending_nickname or "测试主公"
            returning = ST.user_created
            # Returning users: mark 7-day login rewards fully claimed so the
            # New_UserContinueLoginShowPanel does not pop every launch.
            extend_more = {
                "medalNum": 0,
                "battleArrayId": 1,  # CardQueueScene / BackpackScene index this
                "treasureInfo": {"treasureFragmentNum": 0},
                "doubleChargeInfo": {"doubleCharge": False, "version": 0},
                "continuousLoginRewardInfoV2": {
                    "gainRewardDays": 99999,
                    "gainedContinuousLoginRewards": [0, 1, 2, 3, 4, 5, 6],
                } if returning else {},
            }
            base.update({
                "sharkUser": _shark_user(nickname=nick, full=True),
                "sharkUserExtend": _shark_user_extend(returning=returning),
                "sharkUserExtendMore": extend_more,
                "sharkEquips": {"sharkEquips": list(ST.equips)},
                "sharkProps": {"sharkProps": list(ST.props)},
            })
            base.update(_game_init_extra())
            return base
        # Chapter map tile events (ChapterMapScene.lua).  Missing `rewards`
        # => doRandomCoinEventAction indexes nil => SIGKILL.
        if method == "triggerCoinEvent":
            mid = int(params.get("missionId") or 100101)
            chapter_id = mid // 100
            _apply_chapter_step(params)
            base.update({
                "rewards": _map_event_rewards("coin", chapter_id),
                "encounterMultiPlayerBoss": False,
            })
            return base
        if method == "triggerExpEvent":
            _apply_chapter_step(params)
            base.update({
                "rewards": _map_event_rewards("exp"),
                "encounterMultiPlayerBoss": False,
            })
            return base
        if method == "triggerEmptyEvent":
            _apply_chapter_step(params)
            base.update({"encounterMultiPlayerBoss": False})
            return base
        if method == "triggerCardEvent":
            _apply_chapter_step(params)
            base.update({
                "rewards": _map_event_rewards("card"),
                "encounterMultiPlayerBoss": False,
            })
            return base
        if method == "triggerRandomEvent":
            # eventType 3 = coin path (doRandomCoinEventAction)
            mid = int(params.get("missionId") or 100101)
            _apply_chapter_step(params)
            base.update({
                "eventType": 3,
                "rewards": _map_event_rewards("coin", mid // 100),
                "encounterMultiPlayerBoss": False,
            })
            return base
        if method == "triggerBattleEvent":
            mid = int(params.get("missionId") or 100101)
            btype = int(params.get("battleType") or 1)
            _apply_chapter_step(params)
            base.update(_build_battle_response(mid, btype))
            return base
        if method == "getMissionCompleteInfo":
            base.update({"missionCompletes": list(ST.mission_completes)})
            return base
        if method == "validatePaymentOrder":
            # Local / bypassed IAP: grant gold from productId or goldNum.
            pid = str(params.get("productId")
                      or params.get("orderId")
                      or "")
            gold = int(params.get("goldNum") or params.get("amount") or 0)
            if gold <= 0:
                # Parse common ids like he_60 / gold_60 / item_60
                m = re.search(r"(\d+)", pid)
                gold = int(m.group(1)) if m else 60
            if gold < 1:
                gold = 60
            with ST._lock:
                ST.recharge_gems = int(ST.recharge_gems) + gold
                ST.gems = int(ST.gems) + gold
                ST.save()
            log(f"  validatePaymentOrder: +{gold} gems -> "
                f"recharge={ST.recharge_gems} free={ST.gems}")
            base.update({
                "succ": True,
                "productId": pid or f"local_{gold}",
                "rechargeGems": gold,
                "freeGems": 0,
            })
            return base
        if method == "gainChargeMoneyReward":
            # Activity_ChargeRewardLayer — tier 1 gives 诸葛亮 (102061).
            rid = int(params.get("id") or params.get("rewardId") or 1)
            rewards, err = _claim_charge_money_reward(rid)
            if err:
                base["retCode"] = err
                return base
            base["rewards"] = rewards
            return base
        if method == "recordTutorialStep":
            return base
        if method == "getGachaBroadcast":
            base.update({"broadcasts": []})
            return base
        if method in ("gachaCardFree", "gachaCard", "gachaCardByRp"):
            # GachaScene.lua: params gachaId + time (1 or 10); free omits time.
            # Rates from gacha_card.lua; pools expanded to all stage-1 of that rare.
            # Persist under ST._lock so concurrent ThreadingHTTPServer requests
            # (and a second server process racing the same file) cannot wipe
            # newly rolled cards on the next save().
            gid = int(params.get("gachaId") or params.get("gachaType") or 3)
            times = 1 if method == "gachaCardFree" else int(params.get("time") or 1)
            with ST._lock:
                rewards = _gacha_rewards(gid, times)
                # apply_reward saves per currency hit; pass None and save once.
                # Gems/props/cards/equips apply in-place; coin/energy/exp need
                # the outer State fields (InventoryMixin only owns gems).
                ST.apply_rewards(rewards, None)
                for r in rewards:
                    it = int(r.get("itemType") or 0)
                    amt = int(r.get("amount") or 0)
                    if it == _RE_COIN:
                        ST.coins = max(0, int(ST.coins) + amt)
                    elif it == _feat.RE_ENERGY:
                        ST.energy = max(0, int(ST.energy) + amt)
                    elif it == _RE_EXP:
                        ST.exp = max(0, int(ST.exp) + amt)
                        sync_user_level(ST)
                ST.save()
                n_cards = len(ST.cards)
            log(f"  gacha persist: +{len(rewards)} rewards -> cards={n_cards} "
                f"next_card_id={ST.next_card_id}")
            base.update({
                "rewards": rewards,
                "free": method == "gachaCardFree",
                "countdownFreeGachaInfos": [],
            })
            return base
        if method == "getRewardList":
            # RewardScene:509 — sharkRewardList nil is OK (skips UI fill), but an
            # empty list is the correct shape and avoids soft-ack-only confusion.
            base.update({"sharkRewardList": []})
            return base
        if method == "getHomeInfo":
            # MainMenuScene:1818-1820 — unionMonsterEscapeSeconds must be a
            # number (nil => UnionManager.setColosseumMonsterRunTime SIGKILL).
            now = int(time.time())
            _init_charge_money_reward()
            charge_status = False
            rg = int(ST.recharge_gems or 0)
            gained = set(ST.gained_charge_money_reward_list or [])
            for rid, meta in _CHARGE_MONEY_REWARD.items():
                if rid not in gained and rg >= int(meta.get("requireGold") or 0):
                    charge_status = True
                    break
            base.update({
                "unionMonsterHp": 0,
                "unionMonsterEscapeSeconds": now + 86400,
                "consumeRewardRecharges": 0,
                "consumeRewards": [],
                "unreadMessageNum": 0,
                "rewardNum": 0,
                "invitedNum": 0,
                "enableGainDailyActiveRewardNum": 0,
                "enableGainDailyAchieveRewardNum": 0,
                "eatPeachStatus": True,
                "cowStageStatus": True,
                "freeSpiritRefreshNum": 0,
                "chargeRewardStatus": charge_status,
                "freeGachaStatus": 0,
            })
            return base
        if method == "getAnnouncementInfo":
            base.update({"announcements": []})
            return base
        if method == "gainContinuousLoginRewardV2":
            base.update({"rewards": [_reward(_RE_COIN, 1000)]})
            return base
        if method == "getUserUnionInfo":
            # Returning empty/no-union is fine; just don't explode on missing keys.
            base.update({"hasUnion": False})
            return base
        if method == "getMaintenanceMeta":
            # ActivityPanelScene tabs call layer.enable() → isActivityOpen(name).
            # Empty list hides almost every activity.
            items = _all_maintenance_items()
            base.update({"maintenanceItem": items})
            log(f"  getMaintenanceMeta -> {len(items)} activities open")
            return base
        # Activity battles (cow / mysterious / wanted / worldBoss / ...)
        if method in (
            "challengeCowStage", "challengeMysterious", "challengeWanted",
            "challengeWorldBoss", "challengeMultiplayerBoss", "challengeChrist",
            "challengeContend", "challengeBabel", "challengeArena",
            "challengeCrossBoss", "challengeElite", "challengePkUser",
            "challengeUnionMonster",
        ):
            base.update(_activity_battle(params))
            log(f"  {method} -> battle stub win=True")
            return base
        if method in ("getCowStageInfo", "getWantedInfo", "getWorldBossInfo",
                      "getEatPeachInfo", "getBabelInfo"):
            if method == "getCowStageInfo":
                base.update({"cowStageInfos": []})
            elif method == "getWantedInfo":
                base.update({"wantedInfos": [], "wantedTasks": [],
                             "refreshTimes": 5})
            elif method == "getWorldBossInfo":
                base.update({
                    "worldBossHp": 1000000,
                    "worldBossMaxHp": 1000000,
                    "inspireTimes": 0,
                    "damage": 0,
                    "rank": 0,
                    "autoChallenge": False,
                    "rewards": [],
                })
            elif method == "getEatPeachInfo":
                base.update({"eatPeachInfos": [], "eatPeachStatus": True})
            elif method == "getBabelInfo":
                base.update({"babelInfo": {"floor": 1, "maxFloor": 50}})
            return base
        if method in ("eatPeach", "inspireInWorldBoss", "gainWorldBossRewards",
                      "setAutoWorldBoss", "refreshWanted", "exchangeItem",
                      "exchangeMysteriousItem", "RefreshSecretShop",
                      "refreshSecretShop"):
            if "secret" in method.lower() or method.startswith("Refresh"):
                base.update(_secret_shop_payload())
            else:
                base.update({"rewards": [_reward(1, 100)], "succ": True})
            return base
        if method == "getSecretShopList":
            base.update(_secret_shop_payload())
            base["secretShopItems"] = list(base.get("itemIdList") or [])
            return base
        if method == "getMonthlyLoginRewardMeta":
            # Omit monthlyLoginRewardItems: CalendarSignInPanel then sets
            # signInActionFinish=true and skips day-grid / signInIcon animation
            # (missing pic/activityIcons/signInIcon.png => SIGKILL on claim).
            # Empty-area close works; open from 活动 still shows a blank closable panel.
            base.update({"adNum": 0})
            return base
        if method in ("getSignInReward", "getLoginReward"):
            # Soft success for claim RPCs; do not require client animation assets.
            amt = 1000
            base.update({"rewards": [_reward(1, amt)]})
            try:
                ST.coins = int(getattr(ST, "coins", 0) or 0) + amt
                ST.save()
            except Exception:
                pass
            return base
        if method == "getEnchantStepReward":
            # EnchantGuideRewardPanel claim; grant a cheap equip stub.
            base.update({
                "rewards": [{
                    "itemType": 6, "metaId": 210011, "amount": 1,
                    "equipId": 0, "level": 1, "enchantLevel": 1,
                }],
            })
            return base
        if method == "getAchievements":
            base.update({"sharkAchievement": []})
            return base
        if method == "getUserBanInfo":
            # CreateCharacterScene.lua:198 -> user.noChatEndSeconds = data.noChatEndSeconds
            base.update({"noChatEndSeconds": 0})
            return base
        if method == "getMeta":
            # The client loads most of its data locally (require "canon.configs.X");
            # only a handful of tables come from the server.  LoginScene.lua:228
            # requires DataManager.GameMetaData.cardPictureConfig.cardPictures.
            _ad_url = "http://android1.canon.happyelements.cn/static/ad/banner.png"
            # GachaScene.preloadAd (line 1167) iterates these ids and dereferences
            # MetaManager.getAdPictureById(id).url with NO nil check -> every id
            # listed there must exist or the client SIGKILLs.
            _ad_ids = ["advacedGacha_1", "advacedGacha_2", "normalGacha_1",
                       "activityGacha_1", "activityGacha_2", "friendGacha_1",
                       "boxGacha"]
            # Activity_*:enable() / MainMenuScene icon filters dereference
            # GameMetaData.activity*Config.featureName with NO nil guard.
            def _act(name, name2=None, **extra):
                d = {"featureName": name}
                if name2:
                    d["featureName2"] = name2
                d.update(extra)
                return d

            return {
                "method": method, "retCode": 200,
                "cardPictureConfig": {"cardPictures": []},
                # read as game_meta.adPictureConfig.adPictures (MetaManager:487)
                "adPictureConfig": {
                    "adPictures": [{"id": i, "url": _ad_url, "name": i}
                                   for i in _ad_ids],
                },
                # MainMenuScene:440/1527 read game_meta.adMainUiConfig.adMainUis
                # DIRECTLY (no guard); getAdvPicByMeta handles a nil entry, so an
                # empty list degrades to the built-in default banner.
                "adMainUiConfig": {"adMainUis": []},
                "skyTowerSettingConfig": {},
                # SpiritManager.isUserLevelEnough compares unlockLevel with NO
                # nil guard (unlike TreasureManager). Empty {} => SIGKILL when
                # MainMenu scrolls past SpiritBackPack.
                "spiritSettingConfig": {
                    "unlockLevel": 60,
                    "spiritPoolInitSize": 50,
                    "spiritPoolExtraSizePerPurchase": 10,
                    "spiritPoolMaxExpandTimes": 20,
                    "spiritPoolExpandCost": 50,
                    "lockedRefreshMultiplier": 2,
                    "unlockPrice": 100,
                    "refreshPropId": 0,
                },
                "activityEventChristmasConfig": _act("eventNewyear"),
                "activityGachaXiaoyuConfig": _act(
                    "activityGachaXiaoyu",
                    crossGachaServerGroups=[{"serverIds": [1]}]),
                "activityCowStageConfig": {
                    "featureNamesList": ["cowStage"],
                },
                "activityFountainWishConfig": _act(
                    "fountainWish", requiredLevel=1),
                "activityWorldBossConfig": _act(
                    "worldBoss", "worldBoss1",
                    prepareTime=1800, dantengTime=12, rankProcessTime=3600,
                    rankingRange=100, inspireLimit=10),
                "activityWantedConfig": _act("activityWanted", completeNum=0,
                                              newRefreshPrice="0", refreshPrice="0"),
                "activityGoldGodConfig": _act(
                    "goldGod",
                    version=2,
                    goldGodMaxTimes=0,
                    goldGodRewardItems=[]),
                "activityTreasureboxPointsConfig": _act(
                    "treasureboxPoints",
                    featureNameTreasureboxPoints="treasureboxPoints",
                    featureNameGainReward="treasureboxPointsReward",
                    featureNamePanel="treasureboxPointsPanel",
                    rankRewardMetas=[], pointRewardMetas=[]),
                "activitySwornBrothersConfig": _act(
                    "activitySwornBrothers", swornBrothersRewardItems=[]),
                "activitySeckillConfig": _act("activitySeckill"),
                "activityDiceConfig": _act("activityThrowDice", maxThrowDiceCount=10,
                                            freeChangeLuckCount=3,
                                            baseCoinThrowDice=100,
                                            diceCoinMultipleItems=[],
                                            diceGoldConsumeItems=[]),
                "activityPraiseConfig": _act("activityPraise"),
                "activityMultiplayerBossConfig": _act("multiplayerBossPanel"),
                "activityNewYearConfig": _act(
                    "newyear",
                    featureNamePanel="activityChargeRewardPanel",
                    featureNameCalcPay="activityNewyearCalcPay",
                    featureNameGainReward="activityNewyearGainReward",
                    version=1),
                "activityBalloonConfig": _act("activityBalloon"),
                # LotteryFortuneLayer.getTipNum / shouldShowParticle read
                # fortuneFreeTime with no nil guard. Missing field => SIGKILL
                # when MainMenu refreshes tip badges after closing 每日签到.
                "activityFortuneNowConfig": _act(
                    "fortuneNow",
                    fortuneFreeTime=0,
                    fortuneTimeMax=10,
                    fortuneCost=20,
                    fortuneRewardItems=[]),
                "activityContendConfig": _act(
                    "contend",
                    panelFeatureName="activityContendPanel",
                    featureNameList=["activityContendPanel"],
                    levelLimit=1),
                "activityLevelRaceConfig": _act(
                    "activityLevelRacePanel",
                    # Client expects [{id, type}, ...]; numbers crash ActivityPanelScene:207
                    displayTypes=[{"id": 0, "type": 0}],
                    levelRewardItems=[],
                    winnerNickname="0"),
                "activityGemConsumeConfig": _act("activityGemConsume"),
                "activityDayRewardConfig": _act("activityDayReward", dayRewards={}),
                "activityConsumeRewardConfig": _act("consumeRewards"),
                "multiplicityRewardConfig": _act("activityDoubleSilver"),
                "exchangeDailyConfig": _act("exchangeDaily"),
                "activityCardExchangeConfig": _act(
                    "activityCardExchange", cardExchangeMeta=[]),
                "prayConfig": _act("activityPray"),
                "fbShareConfig": _act("activityFbShare"),
                "activitySettingConfig": {
                    "gemCardConfig": {
                        "featureName": "gemCard",
                        "gemCardNum": 100,
                        "gemCardLastTime": 30,
                        "gemCardBuyConditionGem": 0,
                        "gemCardBuyConditionTime": 0,
                        "gemCardGemCost": 60,
                    },
                    "phoneChargeConfig": {
                        "featureName": "activity_phoneCharge",
                        "minPayment": 0,
                        "chargeAmounts": [],
                    },
                },
                # Activity_ChallengeMysteriousLayer:setData always reads
                # eventMysteriousConfig.eventLimit (even when all nodes are off).
                # Nil config => SIGKILL on opening 活动.
                "eventMysteriousConfig": {
                    "eventLimit": 99,
                    "energyCost": 2,
                },
                # Shop tab gates on featureName; keep closed via empty maintenance.
                "activityMysteriousExchangeConfig": _act(
                    "mysteriousShop",
                    exchangeMetas=[]),
                # Activity_rechargeLayer.getTipNum -> getUnreceievedRewardsNum
                # compares recharge[i] >= limitRewards[stepId].rewardDetail; missing
                # entries leave limitMoney nil => SIGKILL on main-menu tip badges.
                "activityLimitRewardConfig": {
                    "featureName": "ActivityLimitReward",
                    "limitRewards": [
                        {"stepId": 1, "rewardDetail": 999999, "limitTime": 7,
                         "reward": []},
                        {"stepId": 2, "rewardDetail": 999999, "limitTime": 7,
                         "reward": []},
                        {"stepId": 3, "rewardDetail": 999999, "limitTime": 7,
                         "reward": []},
                    ],
                    "finalReward": [],
                },
                # CountDownRewardNewPanel:147 indexes .rewards — nil => SIGKILL
                # when the 限时奖励 tile/panel opens mid-chapter.
                "countdownRewardConfig": {
                    "rewards": [
                        {"id": 1, "seconds": 60, "reward": [
                            {"itemType": 1, "amount": 100}]},
                        {"id": 2, "seconds": 300, "reward": [
                            {"itemType": 1, "amount": 200}]},
                        {"id": 3, "seconds": 600, "reward": [
                            {"itemType": 1, "amount": 500}]},
                    ],
                },
                "crossArenaRewardConfig": {},
                "destinyBattleConfig": {},
                "spiritConcentrateCostConfig": {},
                # EnchantGuideRewardPanel / Enchant.enabled read this with no nil
                # guard. Missing after closing 每日签到 (level>=35) => SIGKILL.
                "enchantTotalConfig": {
                    "equipMetaId": 210011,
                    "enchantLevel": 1,
                    "atk": 1,
                    "def": 1,
                    "hp": 1,
                    "quality3": 100,
                    "quality4": 100,
                    "quality5": 100,
                    "quality6": 100,
                    "quality7": 100,
                },
                "gameSettingConfig": _game_setting_config(),
                "battleSettingConfig": _battle_setting_config(),
                "paymentExchangeConfig": {
                    # MetaManager.getPaymentExchangeConfig reads .paymentExchanges
                    "paymentExchanges": _payment_exchanges(),
                },
                "serverPartitionConfig": {
                    "runningServers": [{"serverId": 1, "serverName": "本地测试服",
                                        "enable": True, "beginTime": "0",
                                        "serverBusy": 100000, "serverNormal": 50000,
                                        "newServer": False, "whiteAccountIds": ""}],
                    "preparedServers": [],
                },
                "metaVersion": {"meta_version": "0.0.0", "maintenance_version": "0.0.0",
                                "methods": []},
            }
        # Bag / team / mail / friends / beasts / shop / sweep + soft stubs.
        if _feat.handle(method, params, base, ST, _starter_card):
            return base
        return base


# ----------------------------------------------------------------------------
# Realtime channel (plain TCP).
#
# TCPManager.lua: after /protocol getSocketServer it dials serverAddress:serverPort
# and, on connect, sends {serverAddress, serverPort, token, uid, method="login"}.
# TCPManager:dataReceived treats `method == "login" and retCode ~= 0` as failure
# and immediately reconnects -- which is exactly the 11s SOCKET_TCP_CONNECT_FAILURE
# loop that stopped MainMenuScene from ever rendering.  So we must answer the
# login with retCode == 0.
#
# Frame = 4-byte big-endian length | 10 bytes | AMF3 payload, where the length
# field counts the 10 trailing header bytes plus the payload.  Derived from a
# captured client frame (104 bytes total = 14 header + 90 AMF3) and verified by
# re-encoding that frame byte-for-byte with AMF3Writer.w_object().
# ----------------------------------------------------------------------------

REALTIME_PORT = int(os.environ.get("CANON_REALTIME_PORT", "9700"))
FRAME_HDR_TAIL = 10


def frame_encode(amf3: bytes) -> bytes:
    return struct.pack(">I", FRAME_HDR_TAIL + len(amf3)) + b"\x00" * FRAME_HDR_TAIL + amf3


def frame_decode(buf: bytearray):
    """Return (amf3_payload, consumed) or (None, 0) if incomplete."""
    if len(buf) < 14:
        return None, 0
    total = struct.unpack(">I", bytes(buf[:4]))[0]
    plen = total - FRAME_HDR_TAIL
    if plen < 0 or len(buf) < 14 + plen:
        return None, 0
    return bytes(buf[14:14 + plen]), 14 + plen


class RealtimeHandler(socketserver.BaseRequestHandler):
    def handle(self):
        peer = self.client_address
        log(f"[tcp] connection from {peer}")
        self.request.settimeout(600)
        buf = bytearray()
        try:
            while True:
                try:
                    chunk = self.request.recv(4096)
                except socket.timeout:
                    log(f"[tcp] {peer} idle timeout")
                    break
                if not chunk:
                    break
                buf += chunk
                while True:
                    payload, used = frame_decode(buf)
                    if payload is None:
                        break
                    del buf[:used]
                    try:
                        msg = AMF3Reader(payload).read_value()
                    except Exception as e:
                        log(f"[tcp] decode error: {e!r}  raw={payload[:64]!r}")
                        continue
                    log(f"[tcp] <- {json.dumps(msg, ensure_ascii=False, default=str)[:400]}")
                    if isinstance(msg, dict):
                        m = msg.get("method")
                        if m == "login":
                            # retCode MUST be 0; anything else => client reconnects
                            w = AMF3Writer()
                            w.w_object({"method": "login", "retCode": 0})
                            self.request.sendall(frame_encode(w.bytes()))
                            log("[tcp] -> login retCode=0")
                        elif m:
                            # echo a benign ack so the client never treats the
                            # channel as dead
                            w = AMF3Writer()
                            w.w_object({"method": m, "retCode": 0})
                            self.request.sendall(frame_encode(w.bytes()))
                            log(f"[tcp] -> {m} retCode=0 (ack)")
        except Exception as e:
            log(f"[tcp] handler error: {e!r}")
        finally:
            log(f"[tcp] {peer} disconnected")


class RealtimeServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def start_realtime():
    try:
        srv = RealtimeServer(("0.0.0.0", REALTIME_PORT), RealtimeHandler)
    except OSError as e:
        log(f"[tcp] could not bind :{REALTIME_PORT} -> {e}")
        return None
    t = threading.Thread(target=srv.serve_forever, name="realtime", daemon=True)
    t.start()
    log(f"[tcp] realtime channel listening on :{REALTIME_PORT}")
    return srv


_PID_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "canon_server.pid")


def _acquire_singleton():
    """Refuse to start a second copy — dual processes race user_state.json and
    wipe gacha cards / inventory on the next save from the stale process."""
    if os.path.exists(_PID_PATH):
        try:
            old = int(open(_PID_PATH, encoding="utf-8").read().strip())
        except Exception:
            old = 0
        alive = False
        if old > 0:
            try:
                os.kill(old, 0)
                alive = True
            except OSError:
                alive = False
            except Exception:
                # Windows: os.kill may raise PermissionError if alive
                alive = True
        if alive and old != os.getpid():
            log(f"ABORT: another canon_server already running (pid={old}). "
                f"Kill it before starting a second copy — dual writers wipe "
                f"gacha cards from user_state.json.")
            raise SystemExit(1)
    with open(_PID_PATH, "w", encoding="utf-8") as f:
        f.write(str(os.getpid()))


def main():
    _acquire_singleton()
    try:
        srv = ThreadingHTTPServer(("0.0.0.0", 80), Handler)
    except OSError as e:
        log(f"ABORT: cannot bind :80 -> {e} (another server still holding the port?)")
        raise SystemExit(1)
    srv.daemon_threads = True
    log("=" * 70)
    log(f"Canon compatible server listening on :80  pid={os.getpid()}")
    log(f"  uid={ST.uid}  uk={ST.uk}  sessionKey={ST.session_key} "
        f"cards={len(ST.cards)}")
    start_realtime()
    log("=" * 70)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        log("bye")
    finally:
        try:
            if os.path.exists(_PID_PATH):
                cur = open(_PID_PATH, encoding="utf-8").read().strip()
                if cur == str(os.getpid()):
                    os.remove(_PID_PATH)
        except Exception:
            pass


if __name__ == "__main__":
    main()
