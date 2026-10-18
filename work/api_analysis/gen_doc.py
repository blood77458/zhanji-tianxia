#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""由 endpoints.raw.json / dsl.json / 服务端源码 生成接口文档。

产出：
  API.md                     —— 主接口文档（中文）
  work/api_analysis/api_endpoints.json  —— 机器可读清单
  work/api_analysis/api_endpoints.csv   —— 便于表格筛选
"""
import os, re, io, sys, json, csv, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
APKSRC = os.path.abspath(os.path.join(HERE, '..', 'apk_luasrc'))

RAW = json.load(open(os.path.join(HERE, 'endpoints.raw.json'), encoding='utf-8'))
DSL = json.load(open(os.path.join(HERE, 'dsl.json'), encoding='utf-8'))
EPS, CLS = RAW['endpoints'], RAW['classes']

# ---------------------------------------------------------------- 服务端实现状态
# 精确解析 canon_server.py / features.py 里 /protocol 的 if/elif 分发链，
# 抓出真正被具名处理的 method（而不是靠字符串是否出现过）。
def server_methods():
    got = {}
    for p in ('server/canon_server.py', 'server/features.py'):
        fp = os.path.join(REPO, p)
        if not os.path.exists(fp):
            continue
        t = open(fp, encoding='utf-8', errors='replace').read()
        for m in re.finditer(r'\bmethod\s*==\s*["\']([A-Za-z0-9_]+)["\']', t):
            got.setdefault(m.group(1), set()).add(os.path.basename(p))
        for m in re.finditer(r'\bmethod\s+in\s*\(([^)]*)\)', t, re.S):
            for s in re.findall(r'["\']([A-Za-z0-9_]+)["\']', m.group(1)):
                got.setdefault(s, set()).add(os.path.basename(p))
    return got


SERVER_METHODS = server_methods()
print('服务端具名 method: %d' % len(SERVER_METHODS))


# ---------------------------------------------------------------- 错误码
ERR = []
for r, _, fs in os.walk(APKSRC):
    for f in fs:
        if not f.startswith('CommErrorCodes'):
            continue
        t = open(os.path.join(r, f), encoding='utf-8', errors='replace').read()
        base = 710000
        m = re.search(r'SHARK_ERROCODE_ORIGH\s*=\s*(\d+)', t)
        if m:
            base = int(m.group(1))
        for m in re.finditer(r'CommErrorCodes\.([A-Za-z0-9_]+)\s*=\s*\{([^}]*)\}', t):
            body = m.group(2)
            c = re.search(r'code\s*=\s*([A-Za-z0-9_]+)\s*\+\s*(\d+)', body)
            code = (base + int(c.group(2))) if c else None
            tk = re.search(r'textKey\s*=\s*"([^"]*)"', body)
            line = t[:m.start()].count('\n') + 1
            # 行尾注释
            tail = t[m.end():t.find('\n', m.end())]
            cm = re.search(r'--\s*(.+)$', tail)
            ERR.append({'name': m.group(1), 'code': code,
                        'textKey': tk.group(1) if tk else '',
                        'note': cm.group(1).strip() if cm else '',
                        'file': os.path.basename(f), 'line': line})

# ---------------------------------------------------------------- 分类
RULES = [
    (r'features[\\/]crossArena|features[\\/]crossUnionPk|features[\\/]unionPk', '跨服 / 军团战'),
    (r'crossgvg|crosspk|crossboss|crosspvp|crossgacha|gvg|Cross', '跨服'),
    (r'union', '军团'),
    (r'spirit', '元神'),
    (r'treasure', '宝物'),
    (r'enchant', '装备附灵'),
    (r'matrix', '矩阵'),
    (r'beast|beastcompose|rob', '夺宝 / 神兽'),
    (r'email|notice', '邮件'),
    (r'friend|invitation|freegift|chat|praise', '好友社交'),
    (r'arena|destiny|contend|\bpk\b|pkget|pkchallenge|pkgain', '竞技场 / PK'),
    (r'babel|skytower|climb|tower', '通天塔'),
    (r'worldboss|multiplayerboss|wanted', 'Boss / 通缉'),
    (r'gacha|synthetize|compose', '抽卡 / 合成'),
    (r'task|achievement|signin|signinreward|dailyachieve|dailyactive|loginreward|countdown|reward', '任务 / 成就 / 奖励'),
    (r'card|evolve|train|split|lock|avatar|skill|upgradeuser', '卡牌养成'),
    (r'equip', '装备'),
    (r'prop|shop|goods|seckill|secret|medal|grid|sell|buy|bag|spiritpool|exchange', '道具 / 商店'),
    (r'mission|elite|chapter|battle|sweep|route|clear|wharf', '关卡 / 战斗'),
    (r'login|account|server|socket|online|offline|nickname|rename|user', '登录 / 账号 / 连接'),
    (r'activity|active|balloon|dice|fireworks|question|christmas|newyear|monday|fortune|goldgod|levelrace|phonecharge|recharge|monthcard|gem|invite|facebook|bonus|seckill|consumereward|peach|cowstage|contend|sworn|festival|treasurebox|fountain|wish|lottery', '活动'),
    (r'getmeta|gameinit|meta|announcement|maintenance', '元数据 / 初始化'),
]


def categorize(method, clsname, files):
    s = (clsname + ' ' + ' '.join(files)).lower()
    for pat, name in RULES:
        if re.search(pat, s):
            return name
    return '其他'


def short(path):
    b = os.path.basename(path.replace('/', os.sep))
    parts = b.split('.')
    return parts[0] + ('.' + parts[1][:8] + '.lua' if len(parts) > 2 else '')


# ---------------------------------------------------------------- 组装数据
records = []
for method, e in EPS.items():
    classes = e['classes']
    cats = collections.Counter()
    for c in classes:
        cats[categorize(method, c, CLS.get(c, {}).get('files', []))] += 1
    cat = cats.most_common(1)[0][0] if cats else '其他'
    descs = [CLS[c]['desc'] for c in classes if CLS.get(c, {}).get('desc')]
    resp = collections.Counter()
    dbg = collections.Counter()
    for c in classes:
        ci = CLS.get(c, {})
        resp.update(ci.get('response_fields') or {})
        dbg.update(ci.get('debug_fields') or {})
    files = e['callsites']
    records.append({
        'method': method,
        'category': cat,
        'desc': descs[0] if descs else '',
        'classes': classes,
        'files': sorted(set(c['file'] for c in files)),
        'callsites': files,
        'params': e['params'],
        'response_fields': dict(resp),
        'debug_fields': dict(dbg),
        'server_impl': method in SERVER_METHODS,
        'server_files': sorted(SERVER_METHODS.get(method, [])),
    })
records.sort(key=lambda r: (r['category'], r['method']))

# 协议 DSL 关联
dsl_by_class = collections.defaultdict(list)
for p in DSL['protocols']:
    for c in p['classes']:
        dsl_by_class[c].append(p)
for r in records:
    r['dsl'] = [p for c in r['classes'] for p in dsl_by_class.get(c, [])]

# 未被调用的接口
used = set(EPS)
unused = [c for c, v in CLS.items() if v['endpoint'] and v['endpoint'] not in used]

# ---------------------------------------------------------------- 机器可读输出
mr = []
for r in records:
    mr.append({
        'method': r['method'], 'category': r['category'], 'desc': r['desc'],
        'request_classes': r['classes'],
        'request_params': sorted(r['params'].keys() - {'*dynamic*'}),
        'has_dynamic_params': '*dynamic*' in r['params'],
        'response_fields': sorted(r['response_fields'].keys()),
        'call_site_count': len(r['callsites']),
        'server_implemented': r['server_impl'],
        'protocol_dsl': [{'desc': p['desc'], 'request': p['request'], 'response': p['response']}
                         for p in r['dsl']],
    })
json.dump({'endpoints': mr,
           'unused_endpoints': sorted(CLS[c]['endpoint'] for c in unused),
           'server_only_methods': sorted(set(SERVER_METHODS) - set(EPS)),
           'error_codes': ERR},
          open(os.path.join(HERE, 'api_endpoints.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)

with open(os.path.join(HERE, 'api_endpoints.csv'), 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.writer(f)
    w.writerow(['method', '分类', '说明', '请求类', '请求参数', '响应字段', '调用点数', '服务端已实现'])
    for r in records:
        w.writerow([r['method'], r['category'], r['desc'], '|'.join(r['classes']),
                    '|'.join(sorted(r['params'].keys() - {'*dynamic*'})),
                    '|'.join(sorted(r['response_fields'].keys())),
                    len(r['callsites']), 'Y' if r['server_impl'] else 'N'])

print('records: %d' % len(records))
print('categorize:'); 
for k, v in collections.Counter(r['category'] for r in records).most_common():
    print('   %-20s %d' % (k, v))
json.dump(records, open(os.path.join(HERE, 'records.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
