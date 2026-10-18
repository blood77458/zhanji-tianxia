#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""通用 Lua 配置表解析器。

`work/luasrc/canon/configs/*.lua` 是 106 个纯数据文件，形如：

    local arena_rank_reward={
        {rank=10000,itemMetaId=400010,itemType=7,amount=50,desc="..."},
        ...
    };
    return arena_rank_reward;

它们是原厂策划表的直接导出，是整个复现工程**最值钱的数据源**。这个模块
负责把它们读成 Python dict/list。

设计取舍
--------
* 不做完整 Lua 语法分析，只认「表字面量 + 字面量值」这个子集 —— 配置文件
  里不会出现函数、运算、require。
* 数组/字典的区分沿用 Lua 语义：位置元素进 list，`[k]=`/`name=` 进 dict。
  两者混用时（少见）以 dict 为准并保留数组部分在 `__array` 键下。
* 认不出的标识符（例如 `ResourceEnum.GEMS`）不报错，保留成原始字符串，
  由调用方决定怎么解释。这样单个怪值不会让整张表读不出来。
"""
import os
import re

_WS = ' \t\r\n'
_NUM_RE = re.compile(r'[-+]?(?:0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+)')


class LuaConfError(Exception):
    pass


def _skip_ws(s, i):
    n = len(s)
    while i < n:
        c = s[i]
        if c in _WS:
            i += 1
            continue
        if c == '-' and s.startswith('--', i):
            if s.startswith('--[[', i) or re.match(r'--\[=', s[i:]):
                m = re.compile(r'--\[(=*)\[').match(s, i)
                close = ']' + m.group(1) + ']'
                j = s.find(close, m.end())
                i = n if j < 0 else j + len(close)
            else:
                j = s.find('\n', i)
                i = n if j < 0 else j
            continue
        break
    return i


def _read_string(s, i):
    if s.startswith('[[', i) or re.match(r'\[=', s[i:]):
        m = re.compile(r'\[(=*)\[').match(s, i)
        close = ']' + m.group(1) + ']'
        j = s.find(close, m.end())
        if j < 0:
            raise LuaConfError('unterminated long string at %d' % i)
        return s[m.end():j], j + len(close)
    q = s[i]
    i += 1
    out = []
    while i < len(s):
        c = s[i]
        if c == '\\':
            nxt = s[i + 1] if i + 1 < len(s) else ''
            out.append({'n': '\n', 't': '\t', 'r': '\r', '\\': '\\',
                        '"': '"', "'": "'", '0': '\0'}.get(nxt, nxt))
            i += 2
            continue
        if c == q:
            return ''.join(out), i + 1
        out.append(c)
        i += 1
    raise LuaConfError('unterminated string at %d' % i)


def _read_number(s, i):
    m = _NUM_RE.match(s, i)
    if not m:
        raise LuaConfError('bad number at %d: %r' % (i, s[i:i + 20]))
    txt = m.group(0)
    if txt.lower().startswith(('0x', '-0x', '+0x')):
        val = int(txt, 16)
    elif '.' in txt or 'e' in txt.lower():
        val = float(txt)
    else:
        val = int(txt)
    return val, m.end()


def _read_name(s, i):
    m = re.match(r'[A-Za-z_][A-Za-z0-9_]*', s[i:])
    if not m:
        raise LuaConfError('bad name at %d' % i)
    return m.group(0), i + len(m.group(0))


def parse_value(s, i, consts=None):
    """解析一个值，返回 (value, next_index)。"""
    i = _skip_ws(s, i)
    if i >= len(s):
        raise LuaConfError('unexpected end of input')
    c = s[i]
    if c == '{':
        return parse_table(s, i, consts)
    if c in '"\'' or (c == '[' and (s.startswith('[[', i) or re.match(r'\[=', s[i:]))):
        return _read_string(s, i)
    if c.isdigit() or c == '.' or (c in '+-' and i + 1 < len(s) and
                                   (s[i + 1].isdigit() or s[i + 1] == '.')):
        return _read_number(s, i)
    name, j = _read_name(s, i)
    if name == 'true':
        return True, j
    if name == 'false':
        return False, j
    if name == 'nil':
        return None, j
    # 可能是 Enum.Xxx 之类的常量引用
    k = j
    full = name
    while k < len(s) and s[k] == '.':
        sub, k2 = _read_name(s, k + 1)
        full += '.' + sub
        k = k2
    if consts and full in consts:
        return consts[full], k
    return full, k          # 认不出就原样保留字符串


def parse_table(s, i, consts=None):
    """s[i] == '{'，返回 (dict|list, next_index)。"""
    i = _skip_ws(s, i)
    assert s[i] == '{'
    i += 1
    arr = []
    obj = {}
    has_keyed = False
    has_array = False
    while True:
        i = _skip_ws(s, i)
        if i >= len(s):
            raise LuaConfError('unterminated table')
        if s[i] == '}':
            i += 1
            break
        # --- 键 ---
        if s[i] == '[':
            save = i
            i += 1
            key, i = parse_value(s, i, consts)
            i = _skip_ws(s, i)
            if i < len(s) and s[i] == ']':
                i += 1
                i = _skip_ws(s, i)
                if i < len(s) and s[i] == '=':
                    i += 1
                    val, i = parse_value(s, i, consts)
                    obj[key] = val
                    has_keyed = True
                    i = _sep(s, i)
                    continue
            i = save            # 不是 [k]= 形式，当作位置元素
        else:
            m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*', s[i:])
            if m and not s.startswith('==', i + len(m.group(1))):
                name = m.group(1)
                i += m.end()
                val, i = parse_value(s, i, consts)
                obj[name] = val
                has_keyed = True
                i = _sep(s, i)
                continue
        # --- 位置元素 ---
        val, i = parse_value(s, i, consts)
        arr.append(val)
        has_array = True
        i = _sep(s, i)
    if has_keyed and has_array:
        obj['__array'] = arr
        return obj, i
    if has_keyed:
        return obj, i
    return arr, i


def _sep(s, i):
    i = _skip_ws(s, i)
    if i < len(s) and s[i] in ',;':
        i += 1
    return i


def parse_assignments(text, consts=None):
    """解析整个文件里的顶层赋值，返回 {名字: 值}。

    同时处理 `local X = {...}` 与 `X = {...}`，以及结尾的 `return X`。
    """
    out = {}
    i = 0
    n = len(text)
    while True:
        i = _skip_ws(s=text, i=i)
        if i >= n:
            break
        m = re.match(r'local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*', text[i:])
        if not m:
            m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*', text[i:])
            if not m:
                # return / 其它语句，跳到下一个分号或行尾
                j = text.find('\n', i)
                i = n if j < 0 else j + 1
                continue
        name = m.group(1)
        i += m.end()
        i2 = _skip_ws(text, i)
        if i2 >= n or text[i2] != '{':
            j = text.find('\n', i)
            i = n if j < 0 else j + 1
            continue
        val, i = parse_table(text, i2, consts)
        out[name] = val
    return out


# ------------------------------------------------------------------ 文件级
ROOT = os.path.dirname(os.path.abspath(__file__))
CONF_DIR = os.path.join(os.path.dirname(ROOT), 'work', 'luasrc', 'canon', 'configs')

_cache = {}


def find(name):
    """按前缀找配置文件（文件名带 md5 后缀）。"""
    if not os.path.isdir(CONF_DIR):
        return None
    for f in os.listdir(CONF_DIR):
        if f.startswith(name + '.'):
            return os.path.join(CONF_DIR, f)
    return None


def load(name, consts=None, use_cache=True):
    """加载一个配置表。返回表本身（文件里的主变量）。

    找不到或解析失败返回 None，并打印一次告警 —— 上层应把 None 当「无此配置」。
    """
    if use_cache and name in _cache:
        return _cache[name]
    path = find(name)
    if not path:
        _cache[name] = None
        return None
    text = open(path, encoding='utf-8', errors='replace').read()
    try:
        tables = parse_assignments(text, consts)
    except LuaConfError as e:
        print('[luaconf] %s 解析失败: %s' % (name, e))
        _cache[name] = None
        return None
    # 优先取与文件名同名的变量，否则取第一个
    val = tables.get(name)
    if val is None and tables:
        val = next(iter(tables.values()))
    if use_cache:
        _cache[name] = val
    return val


def load_all(use_cache=True):
    """把 configs 目录全部读进来，返回 {base_name: value}。用于批量自检。"""
    out = {}
    if not os.path.isdir(CONF_DIR):
        return out
    for f in sorted(os.listdir(CONF_DIR)):
        if f.endswith('.lua'):
            base = f.split('.')[0]
            out[base] = load(base, use_cache=use_cache)
    return out


def as_list(v):
    """把配置读成 list（兼容 __array 混合形态）。"""
    if v is None:
        return []
    if isinstance(v, list):
        return v
    if isinstance(v, dict):
        if '__array' in v:
            return v['__array']
        if not v:
            return []
        if all(isinstance(k, int) for k in v):
            return [v[k] for k in sorted(v)]
        return [v]
    return [v]


if __name__ == '__main__':
    import io
    import sys
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    res = load_all()
    ok = [k for k, v in res.items() if v is not None]
    bad = [k for k, v in res.items() if v is None]
    print('配置总数 %d   解析成功 %d   失败 %d' % (len(res), len(ok), len(bad)))
    if bad:
        print('失败: %s' % ', '.join(bad))
    for k in ('arena_rank_reward', 'cow_stage', 'sky_tower_setting',
              'activity_question_bank', 'world_boss_level', 'card_meta'):
        v = res.get(k)
        n = len(as_list(v)) if not isinstance(v, dict) or '__array' in v or \
            all(isinstance(x, int) for x in v) else len(v)
        print('  %-26s %s 条目=%d' % (k, type(v).__name__, n))
