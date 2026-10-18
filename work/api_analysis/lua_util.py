#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lua 源码的轻量扫描工具：注释剥离、括号匹配、表字面量解析。

不追求完整语法，只覆盖本工程 Lua 代码里实际出现的写法（表构造、函数定义、赋值）。
"""
import re

# ---------------------------------------------------------------- 基础扫描

def read_text(path):
    with open(path, 'rb') as f:
        b = f.read()
    for enc in ('utf-8-sig', 'utf-8', 'gb18030', 'latin-1'):
        try:
            return b.decode(enc)
        except Exception:
            pass
    return b.decode('latin-1')


def skip_string(s, i):
    """s[i] 是引号或 [ 起始，返回字符串结束后的下标。"""
    if s.startswith('[[', i) or s.startswith('[=[', i):
        m = re.compile(r'\[(=*)\[').match(s, i)
        if m:
            close = ']' + m.group(1) + ']'
            j = s.find(close, m.end())
            return len(s) if j < 0 else j + len(close)
    q = s[i]
    if q in '"\'':
        j = i + 1
        while j < len(s):
            c = s[j]
            if c == '\\':
                j += 2
                continue
            if c == q:
                return j + 1
            if c == '\n':          # 未闭合，容错
                return j
            j += 1
        return len(s)
    return i + 1


def strip_comments(s):
    """把注释替换成等长空白，保持下标不变。"""
    out = []
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c == '-' and s.startswith('--', i):
            if s.startswith('--[[', i) or re.match(r'--\[=', s[i:]):
                m = re.compile(r'--\[(=*)\[').match(s, i)
                close = ']' + m.group(1) + ']'
                j = s.find(close, m.end())
                j = n if j < 0 else j + len(close)
                out.append(re.sub(r'[^\n]', ' ', s[i:j]))
                i = j
            else:
                j = s.find('\n', i)
                j = n if j < 0 else j
                out.append(re.sub(r'[^\n]', ' ', s[i:j]))
                i = j
            continue
        if c in '"\'' or (c == '[' and (s.startswith('[[', i) or re.match(r'\[=', s[i:]))):
            j = skip_string(s, i)
            out.append(s[i:j])
            i = j
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def match_bracket(s, i):
    """s[i] 是 ({[ 之一，返回配对的 )}] 下标（未找到返回 -1）。"""
    pairs = {'(': ')', '{': '}', '[': ']'}
    open_c = s[i]
    close_c = pairs[open_c]
    depth = 0
    j = i
    n = len(s)
    while j < n:
        c = s[j]
        if c in '"\'' or (c == '[' and (s.startswith('[[', j) or re.match(r'\[=', s[j:]))):
            j = skip_string(s, j)
            continue
        if c in '({[':
            depth += 1
        elif c in ')}]':
            depth -= 1
            if depth == 0:
                return j
        j += 1
    return -1


def split_args(s):
    """把 "a, b, {c=1}" 拆成顶层参数列表。"""
    parts = []
    depth = 0
    start = 0
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c in '"\'' or (c == '[' and (s.startswith('[[', i) or re.match(r'\[=', s[i:]))):
            i = skip_string(s, i)
            continue
        if c in '({[':
            depth += 1
        elif c in ')}]':
            depth -= 1
        elif c == ',' and depth == 0:
            parts.append(s[start:i].strip())
            start = i + 1
        i += 1
    tail = s[start:].strip()
    if tail or parts:
        parts.append(tail)
    return parts


ID_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')


def parse_table_fields(s, i):
    """s[i]=='{'，返回 [(key, key_kind, value_text)]，key_kind ∈ name/expr/pos。"""
    end = match_bracket(s, i)
    if end < 0:
        return []
    body = s[i + 1:end]
    fields = []
    depth = 0
    start = 0
    k = 0
    n = len(body)
    while k <= n:
        c = body[k] if k < n else ','
        if k < n and (c in '"\'' or (c == '[' and (body.startswith('[[', k) or re.match(r'\[=', body[k:])))):
            k = skip_string(body, k)
            continue
        if k < n and c in '({[':
            depth += 1
        elif k < n and c in ')}]':
            depth -= 1
        elif c == ',' and depth == 0:
            item = body[start:k].strip()
            start = k + 1
            if item:
                m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', item, re.S)
                if m:
                    fields.append((m.group(1), 'name', m.group(2).strip()))
                else:
                    m2 = re.match(r'^\[(.+?)\]\s*=\s*(.*)$', item, re.S)
                    if m2:
                        fields.append((m2.group(1).strip(), 'expr', m2.group(2).strip()))
                    else:
                        fields.append((None, 'pos', item))
        k += 1
    return fields


BLOCK_RE = re.compile(r'\b(function|if|do|repeat|end|until)\b')


def find_block_end(s, i):
    """从函数体起始位置找到配对 end。

    Lua 块开启符按 function / if / do / repeat 计（for、while 后必跟 do，
    故不重复计数）；end 关闭前四者中的 function/if/do，until 关闭 repeat。
    """
    depth = 1
    for m in BLOCK_RE.finditer(s, i):
        w = m.group(1)
        if w in ('function', 'if', 'do', 'repeat'):
            depth += 1
        else:  # end / until
            depth -= 1
            if depth == 0:
                return m.start() if w == 'end' else m.end()
    return len(s)
