#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从解密的 APK Lua 源码中抽取 RPC 接口清单、请求参数与客户端消费的响应字段。

产出 endpoints.raw.json（结构见 README 注释）。
"""
import os, re, json, sys, collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_util import (read_text, strip_comments, match_bracket, split_args,
                      parse_table_fields, ID_RE, find_block_end, skip_string)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', 'apk_luasrc'))

RE_METHOD_CONST = re.compile(r'^\s*(METHOD_[A-Z0-9_]+)\s*=\s*"([^"]*)"', re.M)
RE_CLASS_DEF = re.compile(r'^[ \t]*([A-Za-z_][A-Za-z0-9_]*Request)\s*=\s*class\s*\(', re.M)
RE_ENDPOINT = re.compile(r'self\.endpoint\s*=\s*([^\n]+)')
RE_EVENTNAME = re.compile(r'self\.(succeedEventName|failedEventName)\s*=\s*([^\n]+)')
RE_FUNC_DEF = re.compile(r'\bfunction\s+([A-Za-z_][A-Za-z0-9_.:]*)\s*\(([^)]*)\)')
RE_ASSIGN_FIELD = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^\n]+)')
RE_TABLE_ASSIGN = re.compile(r'\b(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{')
RE_CALL = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*Request)\s*([.:])\s*(new|sendRequest[A-Za-z]*)\s*\(')
RE_NOTIFY = re.compile(r'RequestNotifyEnum\.([A-Za-z0-9_]+)')
RE_DISPATCH = re.compile(r'dispatchEvent\s*\(\s*Event\.new\s*\(\s*(?:RequestNotifyEnum\.)?([A-Za-z0-9_"]+)')

# ------------------------------------------------------------------ 载入
print('scanning %s ...' % ROOT)
FILES = {}
for r, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(r, f)
        rel = os.path.relpath(p, ROOT)
        raw = read_text(p)
        FILES[rel] = {'raw': raw, 'nc': strip_comments(raw), 'base': f.split('.')[0]}
print('  files: %d' % len(FILES))

CONSTS = {}
for F in FILES.values():
    for m in RE_METHOD_CONST.finditer(F['nc']):
        CONSTS[m.group(1)] = m.group(2)


def split_concat(e):
    parts, depth, start, i = [], 0, 0, 0
    while i < len(e):
        c = e[i]
        if c in '"\'':
            i = skip_string(e, i)
            continue
        if c in '([':
            depth += 1
        elif c in ')]':
            depth -= 1
        elif e.startswith('..', i) and depth == 0:
            parts.append(e[start:i].strip())
            i += 2
            start = i
            continue
        i += 1
    parts.append(e[start:].strip())
    return parts


def resolve_expr(expr, depth=0):
    e = expr.strip().rstrip(',')
    if depth > 6:
        return None
    m = re.fullmatch(r'"([^"]*)"', e) or re.fullmatch(r"'([^']*)'", e)
    if m:
        return m.group(1)
    if e in CONSTS:
        return CONSTS[e]
    if '..' in e:
        vals = [resolve_expr(p, depth + 1) for p in split_concat(e)]
        return None if any(v is None for v in vals) else ''.join(vals)
    return None


# ------------------------------------------------------------------ 参数表构建器
def make_param_builder(name, funcs, methods):
    """返回 build_params(funcname, call_args) -> (kv, table_expr)。

    沿 `sendRequestDefalut -> sendRequest`、`wrapper -> new(...)` 的委派链，
    把参数表的 key/value 还原出来；`table_expr` 非空表示整张表由调用方给出。
    """
    def simplify(expr):
        """把 `{a=1,b=2}.b` 化简成 `2`。"""
        m = re.match(r'^\{.*\}\s*\.\s*([A-Za-z_][A-Za-z0-9_]*)\s*$', expr, re.S)
        if not m:
            return expr
        key = m.group(1)
        i = expr.index('{')
        for k, kk, v in parse_table_fields(expr, i):
            if k == key:
                return v
        return expr

    def subst(expr, args, call_args):
        val = expr
        for j, a in enumerate(args):
            if j < len(call_args) and re.search(r'\b' + re.escape(a) + r'\b', val):
                val = re.sub(r'\b' + re.escape(a) + r'\b', call_args[j].strip(), val)
        return simplify(val)

    def build_params(funcname, call_args, seen=None):
        seen = seen or set()
        sf = funcs.get(funcname)
        if sf is None or funcname in seen:
            return {}, None
        seen = seen | {funcname}
        ps = sf['params_source']
        if ps and ps['kind'] == 'table':
            kv = {}
            for k, v in ps.get('fields', []):
                if k:
                    kv[k] = subst(v, sf['args'], call_args)
            for k in sf.get('extra_keys', []):
                kv.setdefault(k, '')
            return kv, None
        if ps and ps['kind'] == 'arg':
            i = ps['index']
            return ({}, call_args[i].strip()) if i < len(call_args) else ({}, None)
        body = ''
        for m in methods:
            if m['name'] == funcname and m['file'] == sf['file']:
                body = m['body']
                break
        args = sf['args']
        dm = re.search(re.escape(name) + r'\s*\.\s*(sendRequest[A-Za-z]*)\s*\(', body)
        if dm:
            oi = dm.end() - 1
            ci = match_bracket(body, oi)
            if ci > 0:
                kv, te = build_params(dm.group(1), split_args(body[oi + 1:ci]), seen)
                kv = {k: subst(v, args, call_args) for k, v in kv.items()}
                return kv, te
        nm = re.search(re.escape(name) + r'\s*\.\s*new\s*\(', body)
        if nm:
            oi = nm.end() - 1
            ci = match_bracket(body, oi)
            if ci > 0:
                first = split_args(body[oi + 1:ci])[0].strip()
                k = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*(?:or\s+\{\}\s*)?$', first)
                if k and k.group(1) in args:
                    j = args.index(k.group(1))
                    return ({}, call_args[j].strip()) if j < len(call_args) else ({}, '{}')
        for j, a in enumerate(args):
            if a.lower() in ('params', 'param', 'data', 'p') and j < len(call_args):
                return {}, call_args[j].strip()
        return {}, None

    return build_params


# ------------------------------------------------------------------ 类索引
# 一个文件里可能连续定义多个请求类（如 RewardRequest.lua），因此不能按
# “类定义之间的区间”切分，必须按 `function <Cls>:<method>` 的函数体定位。
classes = {}
for rel, F in FILES.items():
    nc = F['nc']
    names = [m.group(1) for m in RE_CLASS_DEF.finditer(nc)]
    if not names:
        continue
    for name in names:
        info = classes.setdefault(name, {'files': [], 'methods': []})
        if rel not in info['files']:
            info['files'].append(rel)
        pat = re.compile(r'\bfunction\s+' + re.escape(name) + r'\s*([.:])\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)')
        for fm in pat.finditer(nc):
            sep, meth, arglist = fm.group(1), fm.group(2), fm.group(3)
            b0 = fm.end()
            b1 = find_block_end(nc, b0)
            info['methods'].append({
                'name': meth, 'sep': sep,
                'args': [a.strip() for a in split_args(arglist)] if arglist.strip() else [],
                'body': nc[b0:b1], 'file': rel, 'line': nc[:fm.start()].count('\n') + 1,
            })

for name, info in classes.items():
    info['file'] = info['files'][0]

    # --- 中文说明：类定义/ctor 上方的注释，或文件头的标题注释 ---
    def near_comments(text, idx, maxlines=8):
        head = text[:idx].split('\n')
        got = []
        for ln in reversed(head[-maxlines:]):
            s = ln.strip()
            if not s:
                if got:
                    break
                continue
            if s.startswith('--'):
                s = s.strip('-').strip()
                if s and not s.startswith('<') and not s.startswith('<<'):
                    got.insert(0, s)
                continue
            break
        return got

    desc = []
    f0 = info['files'][0]
    nc0, raw0 = FILES[f0]['nc'], FILES[f0]['raw']
    for meth in info['methods']:
        if meth['name'] == 'ctor':
            desc += near_comments(nc0, nc0.find('function ' + name + ':ctor'))
            break
    if not desc:
        cd = RE_CLASS_DEF.search(nc0)
        if cd:
            desc += near_comments(nc0, cd.start())
    if not desc:
        for ln in raw0.split('\n')[:14]:
            s = ln.strip()
            if not s.startswith('--'):
                continue
            body = s.strip('-').strip()
            if not body or body.lower().endswith('.lua'):
                body = body.split('--')[-1].strip()
            if body and 'author' not in body.lower() and 'date' not in body.lower():
                desc.append(body)
    seen, uniq = set(), []
    for x in desc:
        x = x.split('--')[-1].strip() if '--' in x else x
        x = x.strip(' <>')
        if not x or x in seen:
            continue
        if re.search(r'[()"=\[\]]|\bfunction\b|\bprint\b|\bhe_log\b', x):
            continue        # 看起来是代码而非说明
        seen.add(x)
        uniq.append(x)
    cjk = [x for x in uniq if re.search(r'[\u4e00-\u9fff]', x)]
    info['desc'] = ' / '.join(cjk or uniq)[:120]

    def first_in(pred, key):
        for meth in sorted(info['methods'], key=lambda m: (m['name'] != 'ctor', m['line'])):
            if key in meth['body']:
                return meth
        return None

    ep_expr = ep = None
    for meth in sorted(info['methods'], key=lambda m: (m['name'] != 'ctor', m['line'])):
        m = RE_ENDPOINT.search(meth['body'])
        if m:
            ep_expr = m.group(1).strip()
            ep = resolve_expr(m.group(1))
            if ep:
                break
    info['endpoint_expr'] = ep_expr
    info['endpoint'] = ep

    succeed = failed = None
    for meth in info['methods']:
        for m in RE_EVENTNAME.finditer(meth['body']):
            v = resolve_expr(m.group(2))
            if m.group(1) == 'succeedEventName' and succeed is None:
                succeed = v
            if m.group(1) == 'failedEventName' and failed is None:
                failed = v
    info['succeed_event'] = succeed
    info['failed_event'] = failed

    evs = []
    for meth in info['methods']:
        if meth['name'] not in ('onSuccess', 'onError'):
            continue
        for dm in RE_DISPATCH.finditer(meth['body']):
            evs.append((meth['name'], dm.group(1).strip('"')))
    info['success_events'] = sorted(set(t for k, t in evs if k == 'onSuccess'))
    info['error_events'] = sorted(set(t for k, t in evs if k == 'onError'))
    # dispatchEvent(Event.new(self.succeedEventName ...))
    for meth in info['methods']:
        if meth['name'] == 'onSuccess' and 'self.succeedEventName' in meth['body'] and succeed:
            info['success_events'] = sorted(set(info['success_events']) | {succeed})

    funcs = {}
    for meth in info['methods']:
        if not meth['name'].startswith('sendRequest'):
            continue
        body, args = meth['body'], meth['args']
        src = None
        pm = re.search(r'local\s+params\s*=\s*', body)
        if pm:
            rest = body[pm.end():]
            lead = len(rest) - len(rest.lstrip())
            off = pm.end() + lead
            if body[off:off + 1] == '{':
                flds = parse_table_fields(body, off)      # 支持跨多行的表字面量
                src = {'kind': 'table', 'fields': [(k, v) for k, kk, v in flds],
                       'keys': [k for k, kk, v in flds if k]}
            else:
                expr = rest.lstrip().split('\n')[0].strip()
                if ID_RE.match(expr):
                    idx = args.index(expr) if expr in args else 0
                    src = {'kind': 'arg', 'index': idx, 'argname': expr}
                else:
                    mbase = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s+or\s+\{\}\s*$', expr)
                    if mbase and mbase.group(1) in args:
                        src = {'kind': 'arg', 'index': args.index(mbase.group(1)),
                               'argname': mbase.group(1)}
                    else:
                        src = {'kind': 'expr', 'expr': expr}
        extra = sorted(set(re.findall(r'\bparams\.([A-Za-z_][A-Za-z0-9_]*)\s*=', body)))
        extra += sorted(set(re.findall(r'\bself\.params\.([A-Za-z_][A-Za-z0-9_]*)\s*=', body)))
        funcs[meth['name']] = {'args': args, 'params_source': src,
                               'extra_keys': sorted(set(extra)),
                               'line': meth['line'], 'file': meth['file']}
    info['send_funcs'] = funcs

    # ctor 里显式构造的参数表
    extra, ctor_fields = [], []
    for meth in info['methods']:
        if meth['name'] != 'ctor':
            continue
        extra += re.findall(r'self\.params\.([A-Za-z_][A-Za-z0-9_]*)\s*=', meth['body'])
        for m in re.finditer(r'self\.params\s*=\s*\{', meth['body']):
            flds = parse_table_fields(meth['body'], m.end() - 1)
            ctor_fields += [(k, v) for k, kk, v in flds]
    info['ctor_extra_keys'] = sorted(set(extra))
    info['ctor_fields'] = ctor_fields

    info['build_params'] = make_param_builder(name, funcs, info['methods'])


print('  request-like classes: %d' % len(classes))
print('  with endpoint       : %d' % sum(1 for c in classes.values() if c['endpoint']))
print('  duplicated names    : %d' % sum(1 for c in classes.values() if len(c['files']) > 1))

# ------------------------------------------------------------------ 调用点
def collect_local_tables(nc):
    out = []
    for m in RE_TABLE_ASSIGN.finditer(nc):
        if m.group(1) in ('else',):
            continue
        line = nc[:m.start()].count('\n') + 1
        flds = parse_table_fields(nc, m.end() - 1)
        out.append((m.group(1), line, m.start(), [k for k, kk, v in flds if k], flds))
    return out


def collect_field_assigns(nc):
    out = []
    for m in RE_ASSIGN_FIELD.finditer(nc):
        line = nc[:m.start()].count('\n') + 1
        out.append((m.group(1), m.group(2), m.group(3).strip(), line, m.start()))
    return out


def collect_func_ranges(nc):
    """所有 function 体的 [start, end) 区间，用于按作用域解析局部变量。"""
    out = []
    for m in re.finditer(r'\bfunction\b', nc):
        end = find_block_end(nc, m.end())
        out.append((m.start(), end))
    return out


endpoints = {}
unknown = collections.Counter()


def ent(ep):
    return endpoints.setdefault(ep, {'classes': set(), 'params': {}, 'callsites': []})


def note(e, key, value, src):
    p = e['params'].setdefault(key, {'evidence': [], 'values': []})
    if src not in p['evidence'] and len(p['evidence']) < 12:
        p['evidence'].append(src)
    if value:
        v = ' '.join(value.split())[:120]
        if v not in p['values'] and len(p['values']) < 8:
            p['values'].append(v)


for rel, F in FILES.items():
    nc = F['nc']
    tabs = collect_local_tables(nc)
    flds = collect_field_assigns(nc)
    franges = collect_func_ranges(nc)

    def resolve_var(name, off, line):
        """在包含 off 的函数作用域内（逐层向外）找 name 的表定义并收集其追加赋值。"""
        scopes = [r for r in franges if r[0] < off < r[1]]
        scopes.sort(key=lambda r: r[0], reverse=True)      # 由内向外
        scopes.append((0, len(nc)))
        for (s, e2) in scopes:
            best = None
            for t in tabs:
                vn, vline, vpos = t[0], t[1], t[2]
                if vn != name or vpos > off or vpos < s or vline > line:
                    continue
                if best is None or vpos > best[2]:
                    best = t
            if best:
                keys, ff = list(best[3]), list(best[4])
                extra = [(x[1], x[2]) for x in flds
                         if x[0] == name and best[2] <= x[4] <= off]
                field_vals = {}
                for x in ff:
                    if x[0]:
                        field_vals.setdefault(x[0], x[2])   # (key, kind, value)
                return {'keys': keys, 'fields': ff, 'extra': extra,
                        'field_vals': field_vals, 'line': best[1]}
        return None

    for m in RE_CALL.finditer(nc):
        cls, verb = m.group(1), m.group(3)
        oi = m.end() - 1
        ci = match_bracket(nc, oi)
        if ci < 0:
            continue
        args = split_args(nc[oi + 1:ci])
        line = nc[:m.start()].count('\n') + 1
        cinfo = classes.get(cls)
        if cinfo is None or not cinfo['endpoint']:
            unknown[cls] += 1
            continue
        if rel in cinfo['files']:
            continue        # 类自身文件内的 new/包装调用，不是外部调用点
        ep = cinfo['endpoint']
        e = ent(ep)
        e['classes'].add(cls)
        tag = '%s:%d' % (rel.replace('\\', '/'), line)
        e['callsites'].append({'file': rel, 'line': line, 'class': cls, 'verb': verb,
                               'argc': len(args)})
        if verb == 'new':
            builder = None
            kv, table_expr = {}, (args[0].strip() if args else None)
        else:
            builder = cinfo.get('build_params')
            if builder is None:
                continue
            kv, table_expr = builder(verb, args)

        for k, v in cinfo.get('ctor_fields', []):
            note(e, k, v, cinfo['file'])
        for k in cinfo.get('ctor_extra_keys', []):
            note(e, k, '', tag)
        for k, v in kv.items():
            note(e, k, v, cinfo['file'])

        if table_expr is not None:
            a = table_expr
            if a in ('nil', '{}', '', 'nil '):
                pass                      # 显式无参数
            elif a.startswith('{'):
                for k, kk, v in parse_table_fields(a, 0):
                    note(e, k if k else '(位置参数)', v, tag)
            elif ID_RE.match(a):
                rv = resolve_var(a, m.start(), line)
                if rv:
                    for k in rv['keys']:
                        note(e, k, rv.get('field_vals', {}).get(k, ''), tag)
                    for k, v in rv['extra']:
                        note(e, k, v, tag)
                else:
                    note(e, '*dynamic*', a, tag)
            else:
                note(e, '*dynamic*', a, tag)

# 直接走 transponder 的裸接口
for rel, F in FILES.items():
    for m in re.finditer(r'transponder:call\s*\(\s*"([^"]+)"', F['nc']):
        line = F['nc'][:m.start()].count('\n') + 1
        e = ent(m.group(1))
        e['classes'].add('(direct)')
        e['callsites'].append({'file': rel, 'line': line, 'class': '(direct)',
                               'verb': 'transponder:call', 'argc': 0})

print('\n  endpoints: %d' % len(endpoints))

# ------------------------------------------------------------------ 响应字段
RE_ADD_LISTENER = re.compile(r'addEventListener\s*\(\s*(?:RequestNotifyEnum\.|")?([A-Za-z0-9_]+)"?\s*,')
all_events = {}
for name, info in classes.items():
    for ev in info['success_events']:
        all_events.setdefault(ev, set()).add(name)

resp_by_class = collections.defaultdict(collections.Counter)
debug_by_class = collections.defaultdict(collections.Counter)


def paths_from_body(body, pnames):
    """从处理函数体里抽 event.data.a.b 形式的响应字段路径。"""
    c = collections.Counter()
    if not pnames:
        return c
    alt = '|'.join(re.escape(p) for p in pnames)
    for m in re.finditer(r'\b(?:' + alt + r')\.data\.([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)', body):
        path = m.group(1)
        c[path] += 1
        if '.' in path:
            c[path.split('.')[0]] += 1
    # local d = event.data  ->  d.field
    for m in re.finditer(r'\blocal\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:' + alt + r')\.data\b', body):
        alias = m.group(1)
        for mm in re.finditer(r'\b' + re.escape(alias) + r'\.([A-Za-z_][A-Za-z0-9_]*)', body):
            c[mm.group(1)] += 1
    return c


def params_of(functext):
    m = re.search(r'function\s*[A-Za-z0-9_.:]*\s*\(([^)]*)\)', functext)
    return [a.strip() for a in split_args(m.group(1))] if m else []


def body_of(functext):
    m = re.search(r'function\s*[A-Za-z0-9_.:]*\s*\(([^)]*)\)', functext)
    if not m:
        return ''
    return functext[m.end():find_block_end(functext, m.end())]


def handler_bodies(nc, ev):
    """所有监听 ev 的处理函数文本。"""
    out = []
    for m in RE_ADD_LISTENER.finditer(nc):
        if m.group(1) != ev:
            continue
        rest = nc[m.end():].lstrip()
        if rest.startswith('function'):
            b = find_block_end(rest, rest.index(')') + 1)
            out.append(rest[:b])
        else:
            hm = re.match(r'([A-Za-z_][A-Za-z0-9_]*)', rest)
            if hm:
                fd = re.search(r'\bfunction\s+' + re.escape(hm.group(1)) + r'\s*\(([^)]*)\)', nc)
                if fd:
                    b = find_block_end(nc, fd.end())
                    out.append(nc[fd.start():b])
    return out


# (1) 事件监听器
for rel, F in FILES.items():
    nc = F['nc']
    for ev, clsnames in all_events.items():
        if ev not in nc:
            continue
        for body in handler_bodies(nc, ev):
            cnt = paths_from_body(body, params_of(body))
            if cnt:
                for c in clsnames:
                    resp_by_class[c].update(cnt)

# (2) 请求类自身的 onSucceedDefault / getDebugDatas
for name, info in classes.items():
    for meth in info['methods']:
        if meth['name'] in ('onSucceedDefault', 'onSuccess'):
            resp_by_class[name].update(paths_from_body(meth['body'], params_of(
                'function (' + ','.join(meth['args']) + ')')))
        if meth['name'].startswith('getDebug') or meth['name'].startswith('getTest'):
            for m in re.finditer(r'\.data\.([A-Za-z_][A-Za-z0-9_.]*)', meth['body']):
                debug_by_class[name][m.group(1)] += 1

# (3) 调用点内联回调
for rel, F in FILES.items():
    nc = F['nc']
    locfns = {}
    for m in re.finditer(r'\blocal\s+function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', nc):
        b = find_block_end(nc, m.end())
        locfns[m.group(1)] = nc[m.start():b]
    for m in RE_CALL.finditer(nc):
        cls = m.group(1)
        if cls not in classes or not classes[cls]['endpoint']:
            continue
        oi = m.end() - 1
        ci = match_bracket(nc, oi)
        if ci < 0:
            continue
        for a in split_args(nc[oi + 1:ci]):
            txt = None
            if a.lstrip().startswith('function'):
                txt = a
            elif ID_RE.match(a) and a in locfns:
                txt = locfns[a]
            if txt:
                cnt = paths_from_body(body_of(txt), params_of(txt))
                if cnt:
                    resp_by_class[cls].update(cnt)

for name, info in classes.items():
    info['response_fields'] = dict(resp_by_class.get(name, {}))
    info['debug_fields'] = dict(debug_by_class.get(name, {}))

# ------------------------------------------------------------------ 输出
out = {
    'endpoints': {k: {'classes': sorted(v['classes']),
                      'params': v['params'],
                      'callsites': v['callsites']}
                  for k, v in sorted(endpoints.items())},
    'classes': {k: {'file': v['file'], 'files': v['files'], 'desc': v.get('desc', ''),
                    'endpoint': v['endpoint'], 'endpoint_expr': v['endpoint_expr'],
                    'success_events': v['success_events'],
                    'error_events': v['error_events'],
                    'send_funcs': v['send_funcs'],
                    'ctor_extra_keys': v['ctor_extra_keys'],
                    'ctor_fields': v['ctor_fields'],
                    'response_fields': v.get('response_fields', {}),
                    'debug_fields': v.get('debug_fields', {})}
                for k, v in sorted(classes.items())},
    'unknown_classes': dict(unknown.most_common()),
    'consts': CONSTS,
}
dst = os.path.join(HERE, 'endpoints.raw.json')
with open(dst, 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
print('wrote %s' % dst)
