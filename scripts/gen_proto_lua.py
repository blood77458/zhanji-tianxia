# -*- coding: utf-8 -*-
"""把 work/proto_capture/*.json 生成成 Lua 数据文件（单机版 S1 的静态快照）。

输出：offline/lua/canon/single/proto_data.lua

约定：
  * JSON array  -> Lua 序列表 {a, b, c}（客户端用 ipairs 遍历，必须是序列）
  * JSON object -> Lua 键表 {['k']=v}
  * JSON null   -> 不写这个键（Lua 里 nil 会丢，写了也没用）
  * 空对象/空数组 -> {}
"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAP = os.path.join(ROOT, 'work', 'proto_capture')
OUT = os.path.join(ROOT, 'offline', 'lua', 'canon', 'single', 'proto_data.lua')

LUA_KEYWORDS = {'and', 'break', 'do', 'else', 'elseif', 'end', 'for', 'function',
                'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return',
                'then', 'until', 'while'}


def lua_str(s):
    out = []
    for ch in s:
        if ch in ('\\', '"'):
            out.append('\\' + ch)
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\r':
            out.append('\\r')
        elif ch == '\t':
            out.append('\\t')
        elif ord(ch) < 0x20:
            out.append('\\%03d' % ord(ch))
        else:
            out.append(ch)
    return '"' + ''.join(out) + '"'


def lua_key(k):
    if isinstance(k, str) and k.isdigit():
        return '[' + k + ']'
    if isinstance(k, str) and (k.isidentifier() and k not in LUA_KEYWORDS):
        return None                     # 用 ['k'] 形式更保险，统一走下面
    return None


def conv(obj, indent=0, buf=None):
    if buf is None:
        buf = []
    pad = '  ' * indent
    if obj is None:
        buf.append('nil')
    elif isinstance(obj, bool):
        buf.append('true' if obj else 'false')
    elif isinstance(obj, (int, float)):
        if isinstance(obj, float) and obj == int(obj) and abs(obj) < 1e15:
            buf.append('%d' % int(obj))
        elif isinstance(obj, float):
            buf.append(repr(obj))
        else:
            buf.append(str(obj))
    elif isinstance(obj, str):
        buf.append(lua_str(obj))
    elif isinstance(obj, list):
        if not obj:
            buf.append('{}')
        else:
            buf.append('{\n')
            for v in obj:
                buf.append(pad + '  ')
                conv(v, indent + 1, buf)
                buf.append(',\n')
            buf.append(pad + '}')
    elif isinstance(obj, dict):
        items = [(k, v) for k, v in obj.items() if v is not None]
        if not items:
            buf.append('{}')
        else:
            buf.append('{\n')
            for k, v in items:
                buf.append(pad + '  [%s] = ' % lua_str(str(k)))
                conv(v, indent + 1, buf)
                buf.append(',\n')
            buf.append(pad + '}')
    else:
        buf.append('nil')
    return buf


def main():
    files = sorted(f for f in os.listdir(CAP) if f.endswith('.json')) \
        if os.path.isdir(CAP) else []
    if not files:
        print('!! work/proto_capture 里没有 json，先跑 gen_proto_snapshot.py')
        return 1
    lines = [
        '-- 自动生成，勿手改：scripts/gen_proto_lua.py',
        '-- 单机版 S1 的静态快照：角色登录时客户端会拿到的 /protocol 响应，',
        '-- 按方法名冻结在这里。S2 再换成「按操作变更」。',
        'return {',
    ]
    total = 0
    for f in files:
        name = f[:-5]
        obj = json.load(open(os.path.join(CAP, f), encoding='utf-8'))
        body = ''.join(conv(obj, 2))
        lines.append("  ['%s'] = %s," % (name, body))
        size = len(body)
        total += size
        print('  %-26s %8d 字符' % (name, size))
    lines.append('}')
    open(OUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('共 %d 个方法 / %d 字符 -> %s' % (len(files), total, OUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
