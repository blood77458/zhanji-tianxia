"""给定 endpoint，自动挖出客户端「期望的回包字段」。

思路：
  1. 在 request/*.lua 里找到 endpoint = "xxx" 的类，取它 dispatch 的 Success 事件名
     （形如 RequestNotifyEnum.FooSucceed）。
  2. 全库搜这个事件名，找到 addEventListener(..., 回调名) 的注册点。
  3. 把回调函数体（或紧随其后的本地函数）里所有 `x.y` 形式的字段访问抓出来，
     x 取 data / responseData / e / evt / result 这类形参名。

用法: python scripts/req_fields.py exchangeItem sellProps ...
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server\work\luasrc'
EP = re.compile(r'endpoint\s*=\s*"(\w+)"')
SUCC = re.compile(r'RequestNotifyEnum\.(\w+)')
FIELD = re.compile(r'\b(%s)\.([A-Za-z_]\w*)')


def walk():
    for dp, _, fs in os.walk(ROOT):
        for f in fs:
            if f.endswith('.lua'):
                p = os.path.join(dp, f)
                try:
                    yield p, open(p, 'rb').read().decode('utf-8', 'replace')
                except Exception:
                    continue


def find_request(endpoint):
    """返回 (文件, Success 事件名)。"""
    for p, txt in walk():
        m = EP.search(txt)
        if not m or m.group(1) != endpoint:
            continue
        for s in SUCC.findall(txt):
            if 'Succeed' in s or 'Success' in s:
                return p, s
        return p, None
    return None, None


def callback_body(txt, cb):
    """粗取 function cb(...) ... end 的正文。"""
    m = re.search(r'function\s+([\w\.:]*%s)\s*\(([^)]*)\)' % re.escape(cb), txt)
    if not m:
        return '', ''
    params = m.group(2)
    i = txt.find('\n', m.end())
    depth = 1
    j = i
    while j < len(txt) and depth > 0:
        nl = txt.find('\n', j + 1)
        if nl < 0:
            break
        line = txt[j:nl]
        depth += len(re.findall(r'\b(function|if|for|while|do)\b', line))
        depth -= len(re.findall(r'\bend\b', line))
        depth -= line.count('}')
        if re.match(r'\s*\}\)?\s*$', line) and depth <= 0:
            break
        j = nl
    return params, txt[i:j]


def main():
    targets = sys.argv[1:]
    if not targets:
        print('usage: req_fields.py <endpoint> [...]')
        return 1
    # 预扫：事件名 -> [(file, text)]
    files = list(walk())
    for ep in targets:
        reqfile, ev = find_request(ep)
        print('=' * 78)
        print('### %s' % ep)
        if not reqfile:
            print('    (没有请求类引用这个 endpoint)')
            continue
        print('    请求类: %s' % os.path.relpath(reqfile, ROOT))
        if not ev:
            print('    (没找到 Success 事件名)')
            continue
        print('    事件  : %s' % ev)
        hits = [(p, t) for p, t in files if ev in t and not p.endswith(reqfile.split(os.sep)[-1])]
        if not hits:
            print('    (没有监听者 —— 可能只在 RequestNotifyEnum 里声明过)')
            continue
        for p, t in hits[:4]:
            for m in re.finditer(r'addEventListener\(\s*RequestNotifyEnum\.%s\s*,\s*([\w\.]+)' % ev, t):
                cbname = m.group(1).split('.')[-1]
                params, body = callback_body(t, cbname)
                names = tuple(set([params.strip()] + ['data', 'e', 'evt', 'responseData',
                                                       'result', 'msg', 'event']))
                flds = FIELD.findall(body)
                seen, out = set(), []
                for var, f in flds:
                    if var in names and f not in seen:
                        seen.add(f)
                        out.append(f)
                print('    <- %s :: %s()' % (os.path.relpath(p, ROOT).split(os.sep)[-1], cbname))
                if out:
                    print('       字段: %s' % ', '.join(sorted(out)))
                else:
                    print('       (回调里没直接取字段，可能是转交给面板)')
    print()
    return 0


if __name__ == '__main__':
    sys.exit(main())
