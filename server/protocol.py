#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《战姬天下》(canon) 客户端协议编解码。

从 canon_server.py 抽出，去掉对旧 State 的依赖，成为新服务端的协议基座。

管线（详见 API.md §1.2）：

    HTTP body = headercvt( zlib( amf3( payload ) ) )

    headercvt 客户端→服务端:  00 64 ‖ MD5(C16‖X) ‖ X    X = payload ^ 0xC3
    headercvt 服务端→客户端:  00 64 ‖ MD5(C16‖X) ‖ X    X = payload ^ 0x71

    payload = [ header, [ {method=..., ...}, ... ] ]
    响应    = [ subHeader, [ {method=..., retCode=200, ...} ], [events] ]

⚠️ 两个方向的 XOR 密钥不同。用 0xC3 编码响应，客户端会报 zlib checksum failed。
"""
import hashlib
import struct
import zlib

# ---------------------------------------------------------------- headercvt
HDRCVT_MAGIC = b"\x00\x64"
HDRCVT_XOR_REQ = 0xC3       # client -> server
HDRCVT_XOR_RESP = 0x71      # server -> client
HDRCVT_C16 = bytes.fromhex("255e262a4051306a6533356937717039")


def _xor(data: bytes, key: int) -> bytes:
    return bytes(c ^ key for c in data)


def _framed(x: bytes) -> bytes:
    return HDRCVT_MAGIC + hashlib.md5(HDRCVT_C16 + x).digest() + x


# ---- 服务端方向 ----
def headercvt_wrap(data: bytes) -> bytes:
    """服务端 → 客户端（XOR 0x71）。"""
    return _framed(_xor(data, HDRCVT_XOR_RESP))


def headercvt_unwrap(body: bytes) -> bytes:
    """客户端 → 服务端（XOR 0xC3）。"""
    if len(body) <= 18:
        raise ValueError("headercvt: body too short (%d)" % len(body))
    return _xor(body[18:], HDRCVT_XOR_REQ)


# ---- 客户端方向（写测试客户端用；两个方向的密钥是反的）----
def headercvt_wrap_req(data: bytes) -> bytes:
    """客户端 → 服务端：编码请求体。"""
    return _framed(_xor(data, HDRCVT_XOR_REQ))


def headercvt_unwrap_resp(body: bytes) -> bytes:
    """服务端 → 客户端：解开响应体。"""
    if len(body) <= 18:
        raise ValueError("headercvt: body too short (%d)" % len(body))
    return _xor(body[18:], HDRCVT_XOR_RESP)


# ---------------------------------------------------------------- AMF3 常量
AMF3_UNDEFINED = 0x00
AMF3_NULL = 0x01
AMF3_FALSE = 0x02
AMF3_TRUE = 0x03
AMF3_INTEGER = 0x04
AMF3_DOUBLE = 0x05
AMF3_STRING = 0x06
AMF3_XMLDOC = 0x07
AMF3_DATE = 0x08
AMF3_ARRAY = 0x09
AMF3_OBJECT = 0x0A
AMF3_XML = 0x0B
AMF3_BYTEARRAY = 0x0C

AMF3_MIN_INT = -268435456
AMF3_MAX_INT = 268435455


class AMF3Reader:
    """对应 lua-amf3 1.0.2 amf3_decode.c。"""

    def __init__(self, data):
        self.d = data
        self.i = 0
        self.sref = []      # 字符串引用表
        self.oref = []      # 对象/数组引用表
        self.classes = []   # traits 定义

    def u8(self):
        v = self.d[self.i]
        self.i += 1
        return v

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
        idx = pfx >> 1
        return table[idx] if idx < len(table) else None

    def read_string(self):
        v = self._ref(self.sref)
        if v is None or isinstance(v, str):
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
            v = struct.unpack_from(">d", self.d, self.i)[0]
            self.i += 8
            return v
        if t == AMF3_STRING:
            return self.read_string()
        if t in (AMF3_XML, AMF3_XMLDOC, AMF3_BYTEARRAY):
            return self.read_string()
        if t == AMF3_DATE:
            self._ref(self.oref)
            v = struct.unpack_from(">d", self.d, self.i)[0]
            self.i += 8
            self.oref.append(v)
            return v
        if t == AMF3_ARRAY:
            v = self._ref(self.oref)
            if v is not None and not isinstance(v, int):
                return v
            ln = v if v is not None else 0
            out = {}
            self.oref.append(out)
            while True:                      # 关联部分
                k = self.read_string()
                if not k:
                    break
                out[k] = self.read_value()
            for n in range(1, ln + 1):       # 密集部分
                out[n] = self.read_value()
            return out
        if t == AMF3_OBJECT:
            # U29O 位布局（对客户端真实请求逐字节验证过）：
            #   bit0 = inline（0 → 对象引用）
            #   bit1 = 1 新类定义 / 0 引用已有类
            #   新类时 bit2 = externalizable, bit3 = dynamic, bits4+ = 成员数
            #   引用时 traits 索引 = u29 >> 2
            u = self.u29()
            if not (u & 1):
                idx = u >> 1
                return self.oref[idx] if idx < len(self.oref) else None
            if (u >> 1) & 1:
                f = u >> 2
                ext = f & 1
                dynamic = (f >> 1) & 1
                count = f >> 2
                cls = self.read_string()
                keys = [self.read_string() for _ in range(count)]
                traits = (cls, keys, dynamic, ext)
                self.classes.append(traits)
            else:
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
    """对应 lua-amf3 1.0.2 amf3_encode.c。

    dict → 关联数组（0x09 + 字符串键值对 + 0x01 结束）
    list → 密集数组（0x09 + u29 长度 + 0x01 空关联部分 + 元素）
    """

    def __init__(self):
        self.out = bytearray()

    def u8(self, v):
        self.out.append(v & 0xFF)

    def u29(self, val):
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
                self.u8(AMF3_INTEGER)
                self.u29(v)
            else:
                self.u8(AMF3_DOUBLE)
                self.out += struct.pack(">d", float(v))
        elif isinstance(v, float):
            i = int(v)
            if float(i) == v and AMF3_MIN_INT <= i <= AMF3_MAX_INT:
                self.u8(AMF3_INTEGER)
                self.u29(i)
            else:
                self.u8(AMF3_DOUBLE)
                self.out += struct.pack(">d", v)
        elif isinstance(v, str):
            self.u8(AMF3_STRING)
            self.w_string(v)
        elif isinstance(v, (list, tuple)):
            self.u8(AMF3_ARRAY)
            self.u29((len(v) << 1) | 1)
            self.u8(0x01)
            for x in v:
                self.w_value(x)
        elif isinstance(v, dict):
            self.u8(AMF3_ARRAY)
            self.u8(0x01)
            for k, val in v.items():
                self.w_string(str(k))
                self.w_value(val)
            self.u8(0x01)
        else:
            self.u8(AMF3_UNDEFINED)

    def w_object(self, d):
        """AMF3 object（0x0A），TCP 实时通道用（客户端自己的编码器就是这个形状）。"""
        self.u8(AMF3_OBJECT)
        f = 0 | (1 << 1) | (0 << 2)
        self.u29(1 | (1 << 1) | (f << 2))
        self.w_string("")
        for k, v in d.items():
            self.w_string(str(k))
            self.w_value(v)
        self.w_string("")

    def bytes(self):
        return bytes(self.out)


# ---------------------------------------------------------------- 便捷函数
def amf3_encode(obj) -> bytes:
    w = AMF3Writer()
    w.w_value(obj)
    return w.bytes()


def amf3_decode(data: bytes):
    return AMF3Reader(data).read_value()


def try_decode_body(raw: bytes):
    """尽量剥掉 framing + zlib，返回 (amf3_bytes, note)。"""
    for off in (0, 4, 8, 16):
        cand = raw[off:]
        if len(cand) > 2 and cand[0] == 0x78:
            try:
                return zlib.decompress(cand), "zlib at +%d" % off
            except Exception:
                pass
    for off in range(0, min(64, len(raw))):
        if raw[off] == 0x78:
            try:
                return zlib.decompress(raw[off:]), "zlib at +%d" % off
            except Exception:
                pass
    return raw, "raw (no zlib found)"


def encode_body(amf3_bytes: bytes) -> bytes:
    return zlib.compress(amf3_bytes)


def decode_rpc_request(body: bytes):
    """HTTP body → (header, [req, ...])。失败抛异常。"""
    payload, _note = try_decode_body(headercvt_unwrap(body))
    req = amf3_decode(payload)
    if not isinstance(req, dict):
        raise ValueError("payload is not a table: %r" % type(req))
    header = req.get(1) or {}
    items = req.get(2) or {}
    reqs = [items[k] for k in sorted(k for k in items if isinstance(k, int))]
    return header, reqs


def encode_rpc_response(responses, err_code=0, ts=None, uk=None, st=None, events=None):
    """构造并封装 /protocol 的响应体。

    ⚠️ subHeader.errCode 必须 ≤ 0，成功用 0；>0 会被客户端当全局错误。
    ⚠️ 每个 response 的 retCode 必须 = 200 才算成功。
    """
    import time
    sub = {"errCode": int(err_code), "ts": int(ts if ts is not None else time.time()),
           "others": {}}
    if uk is not None:
        sub["uk"] = uk
    if st is not None:
        sub["st"] = int(st)
    body = amf3_encode([sub, list(responses), list(events or [])])
    return headercvt_wrap(encode_body(body))
